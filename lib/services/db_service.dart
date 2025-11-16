import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:bcrypt/bcrypt.dart';
import '../models/pet.dart';
import '../models/reminder.dart';
import '../models/medical_record.dart';
import '../models/exercise_log.dart';
import '../models/groom_log.dart';
import '../models/notification.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  Database? _db;
  static const int _dbVersion = 10; // Bump to 10 for safe upgrade

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'petpal.db');

    return await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createAllTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Ensure tables and columns are present after upgrade
        await _createAllTables(db);

        // safe add columns to users
        try {
          final columns = await db.rawQuery("PRAGMA table_info(users);");
          final columnNames = columns.map((c) => c['name'].toString()).toList();
          if (!columnNames.contains('salt')) {
            await db.execute("ALTER TABLE users ADD COLUMN salt TEXT;");
          }
          if (!columnNames.contains('role')) {
            await db.execute("ALTER TABLE users ADD COLUMN role TEXT;");
          }
        } catch (_) {}

        // safe add pet columns
        try {
          final petColumns = await db.rawQuery("PRAGMA table_info(pets);");
          final petColumnNames = petColumns.map((c) => c['name'].toString()).toList();
          if (!petColumnNames.contains('image')) {
            await db.execute("ALTER TABLE pets ADD COLUMN image TEXT;");
          }
          if (!petColumnNames.contains('birthdate')) {
            await db.execute("ALTER TABLE pets ADD COLUMN birthdate TEXT;");
          }
        } catch (_) {}
        
        // indexes (idempotent)
        try {
          await db.execute('CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_reminders_petId ON reminders(petId);');
        } catch (_) {}
      },
    );
  }

  Future<void> _createAllTables(Database db) async {
    // pets table includes image and birthdate so fresh installs have full schema
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        gender TEXT NOT NULL,
        species TEXT NOT NULL,
        breed TEXT NOT NULL,
        age INTEGER NOT NULL,
        image TEXT,
        birthdate TEXT
      );
    ''');

    // defensive additions if older table is present
    try {
      final petColumns = await db.rawQuery("PRAGMA table_info(pets);");
      final petColumnNames = petColumns.map((c) => c['name'].toString()).toList();
      if (!petColumnNames.contains('image')) {
        await db.execute("ALTER TABLE pets ADD COLUMN image TEXT;");
      }
      if (!petColumnNames.contains('birthdate')) {
        await db.execute("ALTER TABLE pets ADD COLUMN birthdate TEXT;");
      }
    } catch (_) {}

    await db.execute('''
      CREATE TABLE IF NOT EXISTS reminders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        petId INTEGER NOT NULL,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        scheduledAt TEXT NOT NULL,
        done INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        preference TEXT,
        role TEXT,
        salt TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS medical_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        petId INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        vetName TEXT,
        FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE
      );
    ''');

    // --- Exercise logs table ---
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exercise_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        petId INTEGER NOT NULL,
        length TEXT NOT NULL,
        activity TEXT NOT NULL,
        observations TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE
      );
    ''');

    // --- Groomer logs table ---
    await db.execute('''
      CREATE TABLE IF NOT EXISTS groom_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        petId INTEGER NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        maintenance TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications(
        id INTEGER,
        title TEXT NOT NULL,
        body TEXT,
        scheduledAt TEXT,
        deliveredAt TEXT
      );
    ''');

    // --- Indexes ---
    await db.execute('CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_reminders_petId ON reminders(petId);');
  }

  // ---------------- Helpers ----------------
  String _legacyHash(String password) => sha256.convert(utf8.encode(password)).toString();

  String hashPassword(String password) {
    try {
      return BCrypt.hashpw(password, BCrypt.gensalt());
    } catch (e) {
      return _legacyHash(password);
    }
  }

  bool verifyPassword(String password, String storedHash) {
    try {
      if (storedHash.startsWith(r'$2')) return BCrypt.checkpw(password, storedHash);
      return _legacyHash(password) == storedHash;
    } catch (e) {
      return _legacyHash(password) == storedHash;
    }
  }

  bool isPasswordStrong(String password) {
    final regexUpper = RegExp(r'[A-Z]');
    final regexLower = RegExp(r'[a-z]');
    final regexDigit = RegExp(r'\d');
    final regexSymbol = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
    return password.length >= 8 &&
        regexUpper.hasMatch(password) &&
        regexLower.hasMatch(password) &&
        regexDigit.hasMatch(password) &&
        regexSymbol.hasMatch(password);
  }

  int passwordStrengthScore(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    return score;
  }

  // ---------------- Users ----------------
  Future<int> registerUser(
    String firstName,
    String lastName,
    String email,
    String password,
    String preference,
    String role,
  ) async {
    final db = await database;
    final hashed = hashPassword(password);

    return await db.transaction<int>((txn) async {
      try {
        return await txn.insert('users', {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': hashed,
          'preference': preference,
          'role': role,
        });
      } on DatabaseException catch (err) {
        if (err.toString().toLowerCase().contains('unique')) {
          throw Exception('email already registered');
        }
        rethrow;
      }
    });
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      columns: ['id', 'email', 'password', 'role', 'preference', 'firstName', 'lastName'],
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await database;
    final user = await getUserByEmail(email);
    if (user == null) return null;

    final storedPwd = user['password'] as String;

    if (storedPwd.startsWith(r'$2')) {
      return BCrypt.checkpw(password, storedPwd) ? user : null;
    } else if (_legacyHash(password) == storedPwd) {
      // upgrade to bcrypt
      try {
        final newHash = BCrypt.hashpw(password, BCrypt.gensalt());
        await db.update('users', {'password': newHash}, where: 'id = ?', whereArgs: [user['id']]);
        final upgraded = Map<String, dynamic>.from(user);
        upgraded['password'] = newHash;
        return upgraded;
      } catch (_) {
        return user;
      }
    }
    return null;
  }

  Future<void> updateUserPassword(int userId, String newPassword) async {
    final db = await database;
    final hashed = hashPassword(newPassword);
    await db.update(
      'users',
      {'password': hashed},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> deleteUser(int userId) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }

  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    final db = await database;
    return await db.query(
      'users',
      where: 'role = ?',
      whereArgs: [role],
      orderBy: 'firstName ASC, lastName ASC',
    );
  }

  // ---------------- Pets ----------------
  /// Insert pet with a safe retry if DB lacks birthdate column.
  Future<int> insertPet(Pet pet) async {
    final db = await database;
    try {
      return await db.insert('pets', pet.toMap());
    } on DatabaseException catch (e) {
      final msg = e.toString().toLowerCase();
      // if missing column, attempt to add and retry once
      if (msg.contains('no column named') && (msg.contains('birthdate') || msg.contains('image'))) {
        try {
          // try to add both, safe no-op if exist
          await db.execute("ALTER TABLE pets ADD COLUMN image TEXT;");
        } catch (_) {}
        try {
          await db.execute("ALTER TABLE pets ADD COLUMN birthdate TEXT;");
        } catch (_) {}
        // retry once
        return await db.insert('pets', pet.toMap());
      }
      rethrow;
    }
  }

  Future<List<Pet>> getPets() async =>
      (await database).query('pets', orderBy: 'name ASC').then((m) => m.map(Pet.fromMap).toList());

  Future<int> updatePet(Pet pet) async =>
      (await database).update('pets', pet.toMap(), where: 'id = ?', whereArgs: [pet.id]);

  Future<int> deletePet(int id) async =>
      (await database).delete('pets', where: 'id = ?', whereArgs: [id]);

  // ---------------- Reminders ----------------
  Future<int> insertReminder(Reminder r) async => (await database).insert('reminders', r.toMap());
  Future<List<Reminder>> getRemindersForPet(int petId) async =>
      (await database).query('reminders', where: 'petId = ?', whereArgs: [petId], orderBy: 'scheduledAt DESC').then((m) => m.map(Reminder.fromMap).toList());
  Future<List<Reminder>> getAllReminders() async =>
      (await database).query('reminders', orderBy: 'scheduledAt DESC').then((m) => m.map(Reminder.fromMap).toList());
  Future<int> updateReminder(Reminder r) async => (await database).update('reminders', r.toMap(), where: 'id = ?', whereArgs: [r.id]);
  Future<int> deleteReminder(int id) async => (await database).delete('reminders', where: 'id = ?', whereArgs: [id]);

  // ---------------- Medical Records ----------------
  Future<int> insertMedicalRecord(MedicalRecord r) async => (await database).insert('medical_records', r.toMap());
  Future<List<MedicalRecord>> getMedicalRecordsForPet(int petId) async =>
      (await database).query('medical_records', where: 'petId = ?', whereArgs: [petId], orderBy: 'date DESC').then((m) => m.map(MedicalRecord.fromMap).toList());
  Future<int> updateMedicalRecord(MedicalRecord r) async => (await database).update('medical_records', r.toMap(), where: 'id = ?', whereArgs: [r.id]);
  Future<int> deleteMedicalRecord(int id) async => (await database).delete('medical_records', where: 'id = ?', whereArgs: [id]);

  // ---------------- Exercise Logs ----------------
  Future<int> insertExerciseLog(ExerciseLog r) async => (await database).insert('exercise_logs', r.toMap());
  Future<List<ExerciseLog>> getExerciseLog(int petId) async =>
      (await database).query('exercise_logs', where: 'petId = ?', whereArgs: [petId], orderBy: 'date DESC').then((m) => m.map(ExerciseLog.fromMap).toList());
  Future<int> updateExerciseLog(ExerciseLog r) async => (await database).update('exercise_logs', r.toMap(), where: 'id = ?', whereArgs: [r.id]);
  Future<int> deleteExerciseLog(int id) async => (await database).delete('exercise_logs', where: 'id = ?', whereArgs: [id]);

  // ---------------- Groom Logs ----------------
  Future<int> insertGroomLog(GroomLog r) async => (await database).insert('groom_logs', r.toMap());
  Future<List<GroomLog>> getGroomLog(int petId) async => (await database).query('groom_logs', where: 'petId = ?', whereArgs: [petId], orderBy: 'date DESC').then((m) => m.map(GroomLog.fromMap).toList());
  Future<int> updateGroomLog(GroomLog r) async => (await database).update('groom_logs', r.toMap(), where: 'id = ?', whereArgs: [r.id]);
  Future<int> deleteGroomLog(int id) async => (await database).delete('groom_logs', where: 'id = ?', whereArgs: [id]);

  // ---------------- Notifications ----------------
  Future<int> insertNotification(AppNotification n) async => (await database).insert('notifications', n.toMap());
  Future<List<AppNotification>> getAllNotifications() async => (await database).query('notifications', orderBy: 'scheduledAt DESC').then((rows) => rows.map(AppNotification.fromMap).toList());
  Future<int> updateNotification(AppNotification n) async => (await database).update('notifications', n.toMap(), where: 'id = ?', whereArgs: [n.id]);
  Future<int> deleteNotification(int id) async => (await database).delete('notifications', where: 'id = ?', whereArgs: [id]);
  Future<void> deleteNotificationsForReminder(int id) async {
    final db = await database;
    await db.delete('notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }



  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}