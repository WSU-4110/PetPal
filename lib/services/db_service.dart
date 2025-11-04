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

  /// bump this when you add migrations
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
<<<<<<< HEAD
      version: 4, // bump version to recreate if needed
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        // Drop all tables for demo purposes
        await db.execute("DROP TABLE IF EXISTS users;");
        await db.execute("DROP TABLE IF EXISTS pets;");
        await db.execute("DROP TABLE IF EXISTS reminders;");
        await db.execute("DROP TABLE IF EXISTS medical_records;");
        await _onCreate(db, newVersion);
=======
      version: _dbVersion,
      onConfigure: (db) async {
        // enable foreign key support
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createAllTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // non-destructive migrations - add missing structures
        if (oldVersion < 2 && newVersion >= 2) {
          // medical_records added in v2
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
          // Example migration v3 (reserved)
          try {
            await db.execute("ALTER TABLE users ADD COLUMN salt TEXT;");
          } catch (_) {
            // ignoring if column exists / unsupported
          }
        }

        if (oldVersion < 4 && newVersion >= 4) {
          // v4: ensure indexes for performance
          await db.execute('CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_reminders_petId ON reminders(petId);');
        }
>>>>>>> 1e1a4f0 (Still WIP: saved local changes before pulling)
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
<<<<<<< HEAD
        preference TEXT,
        role TEXT
=======
        preference TEXT
        -- bcrypt hash stored in `password` column (starts with \$2)
>>>>>>> 1e1a4f0 (Still WIP: saved local changes before pulling)
      );
    ''');

    // medical_records (v2)
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

    // indices for performance
    await db.execute('CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_reminders_petId ON reminders(petId);');
  }

  // ---------------- Helpers for legacy hashing ----------------
  // legacy used sha256(password) (older code). We support it and upgrade to bcrypt.
  String _legacyHash(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // ---------------- Compatibility helper methods (kept for app_state) ----------------

  /// Hash password (preferred bcrypt). This is provided so existing code that calls
  /// _db.hashPassword(...) keeps compiling. Use registerUser for new registrations.
  String hashPassword(String password) {
    try {
      // bcrypt hash; BCrypt.gensalt() uses default cost
      return BCrypt.hashpw(password, BCrypt.gensalt());
    } catch (e) {
      // fallback to legacy sha256 if bcrypt not available for any reason
      return _legacyHash(password);
    }
  }

  /// Verify password against a stored hash (bcrypt or legacy sha256).
  bool verifyPassword(String password, String storedHash) {
    try {
      if (storedHash.startsWith(r'$2')) {
        return BCrypt.checkpw(password, storedHash);
      } else {
        return _legacyHash(password) == storedHash;
      }
    } catch (e) {
      // In unlikely failure, do legacy compare
      return _legacyHash(password) == storedHash;
    }
  }

  /// Password strength rules (same as before). Kept for backward compatibility.
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

  /// Returns 0..5 score representing which rules are satisfied.
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

  /// Register a new user using bcrypt. Throws Exception('email already registered') on duplicate.
  Future<int> registerUser(
<<<<<<< HEAD
      String firstName, String lastName, String email, String password, String preference, String role,) async {
    final db = await database;
    return await db.insert('users', {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': hashPassword(password), // store hashed password
      'preference': preference,
      'role': role,
=======
    String firstName,
    String lastName,
    String email,
    String password,
    String preference,
  ) async {
    final db = await database;
    String hashed;
    try {
      hashed = BCrypt.hashpw(password, BCrypt.gensalt());
    } catch (e) {
      // fallback (shouldn't normally occur if bcrypt dependency is present)
      hashed = _legacyHash(password);
    }

    return await db.transaction<int>((txn) async {
      try {
        final id = await txn.insert('users', {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': hashed,
          'preference': preference,
        });
        return id;
      } on DatabaseException catch (err) {
        final msg = err.toString().toLowerCase();
        if (msg.contains('unique') || msg.contains('constraint')) {
          throw Exception('email already registered');
        }
        rethrow;
      }
>>>>>>> 1e1a4f0 (Still WIP: saved local changes before pulling)
    });
  }

  /// Returns user row if found, otherwise null.
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
<<<<<<< HEAD
    final result = await db.query(
      'users',
      columns: ['id', 'email', 'password', 'role'], //role update
      where: 'email = ?',
      whereArgs: [email],
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  // Login: only succeeds if both email exists and password matches and fetches role
  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      columns: ['id', 'email', 'role'],
      where: 'email = ? AND password = ?',
      whereArgs: [email, hashPassword(password)],
    );
    if (result.isNotEmpty) return result.first;
    return null;
=======
    final rows = await db.query('users', where: 'email = ?', whereArgs: [email], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Login flow:
  /// - If stored password string looks like bcrypt (starts with $2), verify with bcrypt.
  /// - Else assume legacy sha256; if it matches, upgrade to bcrypt (rehash and update DB) and return user.
  /// - Returns user map on success, null on failure.
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
        // legacy sha256 comparison
        final legacy = _legacyHash(password);
        if (legacy == storedPwd) {
          // upgrade to bcrypt (best-effort)
          try {
            final newHash = BCrypt.hashpw(password, BCrypt.gensalt());
            await db.update('users', {'password': newHash}, where: 'id = ?', whereArgs: [user['id']]);
            final upgraded = Map<String, dynamic>.from(user);
            upgraded['password'] = newHash;
            return upgraded;
          } catch (e) {
            // if upgrade fails, still return success (password matched)
            return user;
          }
        }
        return null;
      }
    } catch (e) {
      // fallback: if bcrypt operations fail for some reason, check legacy sha256 as last resort
      if (_legacyHash(password) == storedPwd) return user;
      return null;
    }
>>>>>>> 1e1a4f0 (Still WIP: saved local changes before pulling)
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
