// lib/services/db_service.dart
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

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  Database? _db;
  static const int _dbVersion = 5; // bump to 5 for safe upgrade

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
        // Ensure all tables exist safely
        await _createAllTables(db);

        // Add missing columns safely for users
        final columns = await db.rawQuery("PRAGMA table_info(users);");
        final columnNames = columns.map((c) => c['name'].toString()).toList();

        if (!columnNames.contains('salt')) {
          try {
            await db.execute("ALTER TABLE users ADD COLUMN salt TEXT;");
          } catch (_) {}
        }

        if (!columnNames.contains('role')) {
          try {
            await db.execute("ALTER TABLE users ADD COLUMN role TEXT;");
          } catch (_) {}
        }

        // Ensure indexes exist
        await db.execute('CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_reminders_petId ON reminders(petId);');

        // Add 'image' column to pets if missing
        final petColumns = await db.rawQuery("PRAGMA table_info(pets);");
        final petColumnNames = petColumns.map((c) => c['name'].toString()).toList();
        if (!petColumnNames.contains('image')) {
          await db.execute("ALTER TABLE pets ADD COLUMN image TEXT;");
        }
      },
    );
  }

  Future<void> _createAllTables(Database db) async {
    // --- Pets table ---
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

    // Add 'image' column if missing
    final petColumns = await db.rawQuery("PRAGMA table_info(pets);");
    final petColumnNames = petColumns.map((c) => c['name'].toString()).toList();
    if (!petColumnNames.contains('image')) {
      await db.execute("ALTER TABLE pets ADD COLUMN image TEXT;");
    }

    // --- Reminders table ---
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

    // --- Users table ---
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

    // --- Medical Records table ---
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

  // ---------------- Pets ----------------
  Future<int> insertPet(Pet pet) async => (await database).insert('pets', pet.toMap());
  Future<List<Pet>> getPets() async => (await database).query('pets', orderBy: 'name ASC').then((m) => m.map(Pet.fromMap).toList());
  Future<int> updatePet(Pet pet) async => (await database).update('pets', pet.toMap(), where: 'id = ?', whereArgs: [pet.id]);
  Future<int> deletePet(int id) async => (await database).delete('pets', where: 'id = ?', whereArgs: [id]);

  // ---------------- Reminders ----------------
  Future<int> insertReminder(Reminder r) async => (await database).insert('reminders', r.toMap());
  Future<List<Reminder>> getRemindersForPet(int petId) async => (await database).query('reminders', where: 'petId = ?', whereArgs: [petId], orderBy: 'scheduledAt DESC').then((m) => m.map(Reminder.fromMap).toList());
  Future<List<Reminder>> getAllReminders() async => (await database).query('reminders', orderBy: 'scheduledAt DESC').then((m) => m.map(Reminder.fromMap).toList());
  Future<int> updateReminder(Reminder r) async => (await database).update('reminders', r.toMap(), where: 'id = ?', whereArgs: [r.id]);
  Future<int> deleteReminder(int id) async => (await database).delete('reminders', where: 'id = ?', whereArgs: [id]);

  // ---------------- Medical Records ----------------
  Future<int> insertMedicalRecord(MedicalRecord r) async => (await database).insert('medical_records', r.toMap());
  Future<List<MedicalRecord>> getMedicalRecordsForPet(int petId) async => (await database).query('medical_records', where: 'petId = ?', whereArgs: [petId], orderBy: 'date DESC').then((m) => m.map(MedicalRecord.fromMap).toList());
  Future<int> updateMedicalRecord(MedicalRecord r) async => (await database).update('medical_records', r.toMap(), where: 'id = ?', whereArgs: [r.id]);
  Future<int> deleteMedicalRecord(int id) async => (await database).delete('medical_records', where: 'id = ?', whereArgs: [id]);

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
