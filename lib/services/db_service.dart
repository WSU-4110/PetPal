// lib/services/db_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:bcrypt/bcrypt.dart'; // make sure bcrypt is in pubspec.yaml
import '../models/pet.dart';
import '../models/reminder.dart';
import '../models/medical_record.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  Database? _db;
  static const int _dbVersion = 4;

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
        // enable foreign key support
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createAllTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // your local destructive upgrade (demo purposes)
        await db.execute("CREATE TABLE IF NOT EXISTS pets(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, gender TEXT, species TEXT, breed TEXT, age INTEGER);");
        await db.execute("CREATE TABLE IF NOT EXISTS reminders(id INTEGER PRIMARY KEY AUTOINCREMENT, petId INTEGER, title TEXT, category TEXT, scheduledAt TEXT, done INTEGER DEFAULT 0, FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE);");
        await db.execute("CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY AUTOINCREMENT, firstName TEXT, lastName TEXT, email TEXT UNIQUE, password TEXT, preference TEXT, role TEXT);");
        await db.execute("CREATE TABLE IF NOT EXISTS medical_records(id INTEGER PRIMARY KEY AUTOINCREMENT, petId INTEGER, title TEXT, description TEXT, date TEXT, vetName TEXT, FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE);");

        // teammate's non-destructive migrations
        if (oldVersion < 2 && newVersion >= 2) {
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
        }
        if (oldVersion < 3 && newVersion >= 3) {
          try {
            await db.execute("ALTER TABLE users ADD COLUMN salt TEXT;");
          } catch (_) {}
        }
        if (oldVersion < 4 && newVersion >= 4) {
          await db.execute('CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_reminders_petId ON reminders(petId);');
        }
      },
    );
  }

  Future<void> _createAllTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        gender TEXT NOT NULL,
        species TEXT NOT NULL,
        breed TEXT NOT NULL,
        age INTEGER NOT NULL
      );
    ''');

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
        role TEXT
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

    await db.execute('CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_reminders_petId ON reminders(petId);');
  }

  // ---------------- Helpers ----------------

  String _legacyHash(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  String hashPassword(String password) {
    try {
      return BCrypt.hashpw(password, BCrypt.gensalt());
    } catch (e) {
      return _legacyHash(password);
    }
  }

  bool verifyPassword(String password, String storedHash) {
    try {
      if (storedHash.startsWith(r'$2')) {
        return BCrypt.checkpw(password, storedHash);
      } else {
        return _legacyHash(password) == storedHash;
      }
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
    String hashed = hashPassword(password);

    return await db.transaction<int>((txn) async {
      try {
        final id = await txn.insert('users', {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': hashed,
          'preference': preference,
          'role': role,
        });
        return id;
      } on DatabaseException catch (err) {
        final msg = err.toString().toLowerCase();
        if (msg.contains('unique') || msg.contains('constraint')) {
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

    try {
      if (storedPwd.startsWith(r'$2')) {
        final ok = BCrypt.checkpw(password, storedPwd);
        return ok ? user : null;
      } else {
        final legacy = _legacyHash(password);
        if (legacy == storedPwd) {
          // upgrade to bcrypt
          try {
            final newHash = BCrypt.hashpw(password, BCrypt.gensalt());
            await db.update('users', {'password': newHash}, where: 'id = ?', whereArgs: [user['id']]);
            final upgraded = Map<String, dynamic>.from(user);
            upgraded['password'] = newHash;
            return upgraded;
          } catch (e) {
            return user;
          }
        }
        return null;
      }
    } catch (e) {
      if (_legacyHash(password) == storedPwd) return user;
      return null;
    }
  }

  // ---------------- Pets ----------------

  Future<int> insertPet(Pet pet) async {
    final db = await database;
    return await db.insert('pets', pet.toMap());
  }

  Future<List<Pet>> getPets() async {
    final db = await database;
    final maps = await db.query('pets', orderBy: 'name ASC');
    return maps.map((m) => Pet.fromMap(m)).toList();
  }

  Future<int> updatePet(Pet pet) async {
    final db = await database;
    return await db.update('pets', pet.toMap(), where: 'id = ?', whereArgs: [pet.id]);
  }

  Future<int> deletePet(int id) async {
    final db = await database;
    return await db.delete('pets', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Reminders ----------------

  Future<int> insertReminder(Reminder reminder) async {
    final db = await database;
    return await db.insert('reminders', reminder.toMap());
  }

  Future<List<Reminder>> getRemindersForPet(int petId) async {
    final db = await database;
    final maps = await db.query(
      'reminders',
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'scheduledAt DESC',
    );
    return maps.map((m) => Reminder.fromMap(m)).toList();
  }

  Future<List<Reminder>> getAllReminders() async {
    final db = await database;
    final maps = await db.query('reminders', orderBy: 'scheduledAt DESC');
    return maps.map((m) => Reminder.fromMap(m)).toList();
  }

  Future<int> updateReminder(Reminder reminder) async {
    final db = await database;
    return await db.update('reminders', reminder.toMap(), where: 'id = ?', whereArgs: [reminder.id]);
  }

  Future<int> deleteReminder(int id) async {
    final db = await database;
    return await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Medical Records ----------------

  Future<int> insertMedicalRecord(MedicalRecord record) async {
    final db = await database;
    return await db.insert('medical_records', record.toMap());
  }

  Future<List<MedicalRecord>> getMedicalRecordsForPet(int petId) async {
    final db = await database;
    final maps = await db.query(
      'medical_records',
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => MedicalRecord.fromMap(m)).toList();
  }

  Future<int> updateMedicalRecord(MedicalRecord record) async {
    final db = await database;
    return await db.update(
      'medical_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteMedicalRecord(int id) async {
    final db = await database;
    return await db.delete('medical_records', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Misc ----------------

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
