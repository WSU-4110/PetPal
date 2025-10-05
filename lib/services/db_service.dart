import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../models/pet.dart';
import '../models/reminder.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  Database? _db;

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
      version: 2, // bump version to recreate if needed
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        // Drop all tables for demo purposes
        await db.execute("DROP TABLE IF EXISTS users;");
        await db.execute("DROP TABLE IF EXISTS pets;");
        await db.execute("DROP TABLE IF EXISTS reminders;");
        await _onCreate(db, newVersion);
      },
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        gender TEXT NOT NULL,
        species TEXT NOT NULL,
        breed TEXT NOT NULL,
        age INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE reminders(
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
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        preference TEXT
      );
    ''');
  }

  // --- Password Utilities ---
  String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
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

  // --- Users ---
  Future<int> registerUser(
      String firstName, String lastName, String email, String password, String preference) async {
    final db = await database;
    return await db.insert('users', {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': hashPassword(password), // store hashed password
      'preference': preference,
    });
  }

  // Get user by email only
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  // Login: only succeeds if both email exists and password matches
  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, hashPassword(password)],
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  // --- Pets ---
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

  // --- Reminders ---
  Future<int> insertReminder(Reminder reminder) async {
    final db = await database;
    return await db.insert('reminders', reminder.toMap());
  }

  Future<List<Reminder>> getRemindersForPet(int petId) async {
    final db = await database;
    final maps = await db.query('reminders', where: 'petId = ?', whereArgs: [petId], orderBy: 'scheduledAt DESC');
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

  Future close() async {
    final db = await database;
    db.close();
  }
}
