// lib/services/db_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:bcrypt/bcrypt.dart';
import 'dart:developer' as developer; // FIX: Import developer for logging
import '../models/pet.dart';
import '../models/reminder.dart';
import '../models/medical_record.dart';
import '../models/exercise_log.dart';
import '../models/groom_log.dart';
import '../models/pet_access.dart';
import '../models/appointment.dart';
import '../models/notification.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();
  Database? _db;
  static const int _dbVersion = 16; // Incremented version for new health info columns

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
        developer.log('Upgrading database from version $oldVersion to $newVersion'); // FIX: Replaced print
        
        // Create all tables to ensure any missing ones are added
        await _createAllTables(db);

        // Add missing columns to pet_health_info table
        await _addMissingHealthInfoColumns(db);

        // Safe add columns to users
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

        // Safe add pet columns
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

        // Indexes (idempotent)
        try {
          await db.execute('CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_reminders_petId ON reminders(petId);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_appointments_petId ON appointments(petId);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_appointments_vetId ON appointments(vetId);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_appointments_dateTime ON appointments(dateTime);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_grooming_appointments_petId ON grooming_appointments(petId);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_training_appointments_petId ON training_appointments(petId);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_pet_health_info_petId ON pet_health_info(pet_id);');
        } catch (_) {}
      },
    );
  }

  Future<void> _addMissingHealthInfoColumns(Database db) async {
    try {
      // First check if the table exists
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='pet_health_info';");
      if (tables.isEmpty) {
        // Table doesn't exist, create it with all columns
        await db.execute('''
          CREATE TABLE IF NOT EXISTS pet_health_info (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pet_id INTEGER NOT NULL,
            lastCheckup TEXT,
            vaccinationStatus TEXT,
            nextVaccinationDue TEXT,
            allergies TEXT,
            medications TEXT,
            notes TEXT,
            diet TEXT,
            weight TEXT,
            activityLevel TEXT,
            behavior TEXT,
            specialNeeds TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (pet_id) REFERENCES pets (id) ON DELETE CASCADE
          )
        ''');
        return;
      }

      // Table exists, check for missing columns
      final columns = await db.rawQuery("PRAGMA table_info(pet_health_info);");
      final columnNames = columns.map((c) => c['name'].toString()).toSet();

      // List of all expected columns
      const allFields = {
          'lastCheckup', 'vaccinationStatus', 'nextVaccinationDue',
          'allergies', 'medications', 'notes', 'diet', 'weight',
          'activityLevel', 'behavior', 'specialNeeds'
        };

      // Find missing columns by comparing expected fields with existing column names
      final missingColumns = allFields.difference(columnNames);

      // Add missing columns
      for (final column in missingColumns) {
        try {
          developer.log('Adding missing column: $column'); // FIX: Replaced print
          await db.execute("ALTER TABLE pet_health_info ADD COLUMN $column TEXT;");
        } catch (e) {
          developer.log('Error adding column $column: $e'); // FIX: Replaced print
          // Ignore errors for individual columns
        }
      }
    } catch (e) {
      developer.log('Error checking/adding columns to pet_health_info: $e'); // FIX: Replaced print
    }
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
        weight REAL,
        status TEXT,
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

    // == Access table for granting Vets/Trainers/Groomers access to add/edit user information
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pet_access (
        pet_id INT NOT NULL,
        user_id INT NOT NULL,
        PRIMARY KEY (pet_id, user_id),
        FOREIGN KEY (pet_id) REFERENCES pets(id),
        FOREIGN KEY (user_id) REFERENCES users(id)
      );
    ''');

    // --- Appointments table ---
    await db.execute('''
      CREATE TABLE IF NOT EXISTS appointments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        petId INTEGER NOT NULL,
        vetId INTEGER NOT NULL,
        vetName TEXT NOT NULL,
        clinicName TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'upcoming',
        notes TEXT,
        FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE,
        FOREIGN KEY (vetId) REFERENCES users(id) ON DELETE CASCADE
      );
    ''');

    // --- Grooming Appointments table ---
    await db.execute('''
      CREATE TABLE IF NOT EXISTS grooming_appointments(
        id TEXT PRIMARY KEY,
        petId INTEGER NOT NULL,
        groomerId INTEGER,
        groomerName TEXT NOT NULL,
        salon TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'upcoming',
        FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE,
        FOREIGN KEY (groomerId) REFERENCES users(id) ON DELETE SET NULL
      );
    ''');

    // --- Training Appointments table ---
    await db.execute('''
      CREATE TABLE IF NOT EXISTS training_appointments(
        id TEXT PRIMARY KEY,
        petId INTEGER NOT NULL,
        trainerId INTEGER,
        trainerName TEXT NOT NULL,
        facility TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'upcoming',
        FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE,
        FOREIGN KEY (trainerId) REFERENCES users(id) ON DELETE SET NULL
      );
    ''');

    // --- Pet Health Information table with all columns ---
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pet_health_info (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER NOT NULL,
        lastCheckup TEXT,
        vaccinationStatus TEXT,
        nextVaccinationDue TEXT,
        allergies TEXT,
        medications TEXT,
        notes TEXT,
        diet TEXT,
        weight TEXT,
        activityLevel TEXT,
        behavior TEXT,
        specialNeeds TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (pet_id) REFERENCES pets (id) ON DELETE CASCADE
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
    await db.execute('CREATE INDEX IF NOT EXISTS idx_appointments_petId ON appointments(petId);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_appointments_vetId ON appointments(vetId);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_appointments_dateTime ON appointments(dateTime);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_grooming_appointments_petId ON grooming_appointments(petId);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_training_appointments_petId ON training_appointments(petId);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pet_health_info_petId ON pet_health_info(pet_id);');
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
  Future<int> insertReminder(Reminder r) async =>
      (await database).insert('reminders', r.toMap());

  Future<List<Reminder>> getRemindersForPet(int petId) async =>
      (await database).query('reminders', where: 'petId = ?', whereArgs: [petId], orderBy: 'scheduledAt DESC').then((m) => m.map(Reminder.fromMap).toList());

  Future<List<Reminder>> getAllReminders() async =>
      (await database).query('reminders', orderBy: 'scheduledAt DESC').then((m) => m.map(Reminder.fromMap).toList());

  Future<int> updateReminder(Reminder r) async =>
      (await database).update('reminders', r.toMap(), where: 'id = ?', whereArgs: [r.id]);

  Future<int> deleteReminder(int id) async =>
      (await database).delete('reminders', where: 'id = ?', whereArgs: [id]);

  // ---------------- Medical Records ----------------
  Future<int> insertMedicalRecord(MedicalRecord r) async =>
      (await database).insert('medical_records', r.toMap());

  Future<List<MedicalRecord>> getMedicalRecordsForPet(int petId) async =>
      (await database).query('medical_records', where: 'petId = ?', whereArgs: [petId], orderBy: 'date DESC').then((m) => m.map(MedicalRecord.fromMap).toList());

  Future<int> updateMedicalRecord(MedicalRecord r) async =>
      (await database).update('medical_records', r.toMap(), where: 'id = ?', whereArgs: [r.id]);

  Future<int> deleteMedicalRecord(int id) async =>
      (await database).delete('medical_records', where: 'id = ?', whereArgs: [id]);

  // ---------------- Exercise Logs ----------------
  Future<int> insertExerciseLog(ExerciseLog r) async =>
      (await database).insert('exercise_logs', r.toMap());

  Future<List<ExerciseLog>> getExerciseLog(int petId) async =>
      (await database).query('exercise_logs', where: 'petId = ?', whereArgs: [petId], orderBy: 'date DESC').then((m) => m.map(ExerciseLog.fromMap).toList());

  Future<int> updateExerciseLog(ExerciseLog r) async =>
      (await database).update('exercise_logs', r.toMap(), where: 'id = ?', whereArgs: [r.id]);

  Future<int> deleteExerciseLog(int id) async =>
      (await database).delete('exercise_logs', where: 'id = ?', whereArgs: [id]);

  // ---------------- Groom Logs ----------------
  Future<int> insertGroomLog(GroomLog r) async =>
      (await database).insert('groom_logs', r.toMap());

  Future<List<GroomLog>> getGroomLog(int petId) async =>
      (await database).query('groom_logs', where: 'petId = ?', whereArgs: [petId], orderBy: 'date DESC').then((m) => m.map(GroomLog.fromMap).toList());

  Future<int> updateGroomLog(GroomLog r) async =>
      (await database).update('groom_logs', r.toMap(), where: 'id = ?', whereArgs: [r.id]);

  Future<int> deleteGroomLog(int id) async =>
      (await database).delete('groom_logs', where: 'id = ?', whereArgs: [id]);

  // ---------------- Pet Access ----------------
  Future<int> insertPetAccess(PetAccess access) async =>
      (await database).insert('pet_access', access.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);

  Future<List<PetAccess>> getPetAccess(int petId) async =>
      (await database).query('pet_access',
          where: 'pet_id = ?', whereArgs: [petId]).then(
          (rows) => rows.map(PetAccess.fromMap).toList());

  Future<int> deletePetAccess(int petId, int userId) async =>
      (await database).delete('pet_access',
          where: 'pet_id = ? AND user_id = ?', whereArgs: [petId, userId]);

  Future<void> grantAccess(int petId, int userId) async {
    await (await database).insert(
      'pet_access',
      {
        'pet_id': petId,
        'user_id': userId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<int>> getAccessiblePetIds(int vetId) async {
    final rows = await (await database).query(
      'pet_access',
      where: 'user_id = ?',
      whereArgs: [vetId],
    );
    return rows.map((r) => r['pet_id'] as int).toList();
  }

  // ---------------- Appointments ----------------
  Future<int> insertAppointment(Appointment appointment) async {
    final db = await database;
    return await db.insert('appointments', appointment.toMap());
  }

  Future<List<Appointment>> getAppointmentsForPet(int petId) async {
    final db = await database;
    final maps = await db.query(
      'appointments',
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'dateTime DESC',
    );
    return maps.map((map) => Appointment.fromMap(map)).toList();
  }

  Future<List<Appointment>> getAppointmentsForVet(int vetId) async {
    final db = await database;
    final maps = await db.query(
      'appointments',
      where: 'vetId = ?',
      whereArgs: [vetId],
      orderBy: 'dateTime DESC',
    );
    return maps.map((map) => Appointment.fromMap(map)).toList();
  }

  Future<List<Appointment>> getAllAppointments() async {
    final db = await database;
    final maps = await db.query('appointments', orderBy: 'dateTime DESC');
    return maps.map((map) => Appointment.fromMap(map)).toList();
  }

  Future<List<Appointment>> getUpcomingAppointments({int? petId, int? vetId}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    String where = 'dateTime >= ? AND status = ?';
    List<dynamic> whereArgs = [now, 'upcoming'];

    if (petId != null) {
      where += ' AND petId = ?';
      whereArgs.add(petId);
    }

    if (vetId != null) {
      where += ' AND vetId = ?';
      whereArgs.add(vetId);
    }

    final maps = await db.query(
      'appointments',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'dateTime ASC',
    );
    return maps.map((map) => Appointment.fromMap(map)).toList();
  }

  Future<int> updateAppointment(Appointment appointment) async {
    final db = await database;
    return await db.update(
      'appointments',
      appointment.toMap(),
      where: 'id = ?',
      whereArgs: [appointment.id],
    );
  }

  Future<int> deleteAppointment(int id) async {
    final db = await database;
    return await db.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Grooming Appointments ----------------
  Future<void> insertGroomingAppointment(Map<String, dynamic> appointment) async {
    final db = await database;
    await db.insert('grooming_appointments', appointment);
  }

  Future<List<Map<String, dynamic>>> getGroomingAppointmentsForPet(int petId) async {
    final db = await database;
    return await db.query(
      'grooming_appointments',
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'dateTime DESC',
    );
  }

  Future<int> updateGroomingAppointment(Map<String, dynamic> appointment) async {
    final db = await database;
    return await db.update(
      'grooming_appointments',
      appointment,
      where: 'id = ?',
      whereArgs: [appointment['id']],
    );
  }

  Future<int> deleteGroomingAppointment(String id) async {
    final db = await database;
    return await db.delete('grooming_appointments', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Training Appointments ----------------
  Future<void> insertTrainingAppointment(Map<String, dynamic> appointment) async {
    final db = await database;
    await db.insert('training_appointments', appointment);
  }

  Future<List<Map<String, dynamic>>> getTrainingAppointmentsForPet(int petId) async {
    final db = await database;
    return await db.query(
      'training_appointments',
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'dateTime DESC',
    );
  }

  Future<int> updateTrainingAppointment(Map<String, dynamic> appointment) async {
    final db = await database;
    return await db.update(
      'training_appointments',
      appointment,
      where: 'id = ?',
      whereArgs: [appointment['id']],
    );
  }

  Future<int> deleteTrainingAppointment(String id) async {
    final db = await database;
    return await db.delete('training_appointments', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Pet Health Information ----------------
  // Get pet health information
  Future<Map<String, dynamic>?> getPetHealthInfo(int petId) async {
    try {
      final db = await database;

      // First ensure the table exists with all columns
      await _ensureHealthInfoTable(db);

      final List<Map<String, dynamic>> maps = await db.query(
        'pet_health_info',
        where: 'pet_id = ?',
        whereArgs: [petId],
      );

      if (maps.isNotEmpty) {
        // Convert date strings to DateTime objects
        final healthInfo = Map<String, dynamic>.from(maps.first);

        if (healthInfo['lastCheckup'] != null) {
          healthInfo['lastCheckup'] = DateTime.parse(healthInfo['lastCheckup']);
        }

        if (healthInfo['nextVaccinationDue'] != null) {
          healthInfo['nextVaccinationDue'] = DateTime.parse(healthInfo['nextVaccinationDue']);
        }

        // Ensure all fields exist, even if they're null
        const allFields = [
          'lastCheckup', 'vaccinationStatus', 'nextVaccinationDue',
          'allergies', 'medications', 'notes', 'diet', 'weight',
          'activityLevel', 'behavior', 'specialNeeds'
        ];

        for (final field in allFields) {
          if (!healthInfo.containsKey(field)) {
            healthInfo[field] = null;
          }
        }

        return healthInfo;
      }
      return null;
    } catch (e) {
      developer.log('Error getting pet health info: $e'); // FIX: Use developer.log
      return null;
    }
  }

  // Ensure pet_health_info table exists with all columns
  Future<void> _ensureHealthInfoTable(Database db) async {
    try {
      // Check if the table exists
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='pet_health_info';");
      if (tables.isEmpty) {
        // Table doesn't exist, create it with all columns
        await db.execute('''
          CREATE TABLE IF NOT EXISTS pet_health_info (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pet_id INTEGER NOT NULL,
            lastCheckup TEXT,
            vaccinationStatus TEXT,
            nextVaccinationDue TEXT,
            allergies TEXT,
            medications TEXT,
            notes TEXT,
            diet TEXT,
            weight TEXT,
            activityLevel TEXT,
            behavior TEXT,
            specialNeeds TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (pet_id) REFERENCES pets (id) ON DELETE CASCADE
          )
        ''');
        return;
      }
      
      // Table exists, check for missing columns using _addMissingHealthInfoColumns helper
      await _addMissingHealthInfoColumns(db);

    } catch (e) {
      developer.log('Error creating pet_health_info table: $e'); // FIX: Use developer.log
    }
  }

  // Update pet health information
  Future<void> updatePetHealthInfo(int petId, Map<String, dynamic> healthInfo) async {
    try {
      final db = await database;

      // Ensure table exists with all columns
      await _ensureHealthInfoTable(db);

      // Get the current columns in the table
      final columns = await db.rawQuery("PRAGMA table_info(pet_health_info);");
      final columnNames = columns.map((c) => c['name'].toString()).toSet();

      // Convert DateTime objects to strings for storage
      final data = Map<String, dynamic>.from(healthInfo);

      if (data['lastCheckup'] is DateTime) {
        data['lastCheckup'] = (data['lastCheckup'] as DateTime).toIso8601String();
      }

      if (data['nextVaccinationDue'] is DateTime) {
        data['nextVaccinationDue'] = (data['nextVaccinationDue'] as DateTime).toIso8601String();
      }

      data['pet_id'] = petId;
      data['updated_at'] = DateTime.now().toIso8601String();

      // Check if a record already exists
      final existing = await db.query(
        'pet_health_info',
        where: 'pet_id = ?',
        whereArgs: [petId],
      );

      // Build a map with only the columns that exist in the table
      final updateData = <String, dynamic>{
        'pet_id': petId,
        'updated_at': data['updated_at']
      };
      
      // List of all expected fields (to avoid repetition and potential errors)
      const healthFields = [
        'lastCheckup', 'vaccinationStatus', 'nextVaccinationDue',
        'allergies', 'medications', 'notes', 'diet', 'weight',
        'activityLevel', 'behavior', 'specialNeeds'
      ];

      for (final field in healthFields) {
        if (columnNames.contains(field) && data.containsKey(field) && data[field] != null) {
          updateData[field] = data[field];
        } else if (columnNames.contains(field) && data.containsKey(field) && data[field] == null) {
           // Explicitly set to null if provided as null in the map, otherwise SQLite might ignore it.
           // However, SQLite UPDATE syntax often handles null fields implicitly if the key is present.
           // Setting the key to null is safer if the table was created without NOT NULL constraints.
           updateData[field] = null;
        }
      }

      if (existing.isNotEmpty) {
        // Update existing record
        await db.update(
          'pet_health_info',
          updateData,
          where: 'pet_id = ?',
          whereArgs: [petId],
        );
      } else {
        // Insert new record
        updateData['created_at'] = DateTime.now().toIso8601String();
        await db.insert('pet_health_info', updateData);
      }
    } catch (e) {
      developer.log('Error updating pet health info: $e'); // FIX: Use developer.log
      rethrow;
    }
  }

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