// lib/state/app_state.dart
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/pet.dart';
import '../models/reminder.dart';
import '../models/medical_record.dart';
import '../services/db_service.dart';

class AppState extends ChangeNotifier {
  final DBService _db = DBService();

  List<Pet> pets = [];
  List<Reminder> reminders = [];
  List<MedicalRecord> medicalRecords = [];

  Map<String, dynamic>? currentUser; // logged-in user

  /// Initialize app state by loading pets and reminders
  Future<void> init() async {
    await _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    pets = await _db.getPets();
    reminders = await _db.getAllReminders();
    notifyListeners();
  }

  // ---------------- LOGIN / REGISTER ----------------

  /// Logs in user with email + password
<<<<<<< HEAD
  /// Throws Exception with "invalid email" or "invalid password"
  Future<Map<String, dynamic>> login(String email, String password) async {
    final userByEmail = await getUserByEmail(email);
=======
  /// Throws Exception("invalid email") or Exception("invalid password")
  Future<void> login(String email, String password) async {
    // Use DBService.loginUser which handles bcrypt/legacy upgrade
    final user = await _db.loginUser(email, password);
>>>>>>> 1e1a4f0 (Still WIP: saved local changes before pulling)

    if (user == null) {
      // determine whether the email doesn't exist or password is wrong
      final byEmail = await _db.getUserByEmail(email);
      if (byEmail == null) {
        throw Exception("invalid email");
      } else {
        throw Exception("invalid password");
      }
    }

    // success
    currentUser = user;
    notifyListeners();
    return userByEmail;

  }

  /// Registers a new user
  /// Throws Exception if email exists or password is weak
  Future<void> register(
<<<<<<< HEAD
      String firstName, String lastName, String email, String password, String preference, String role) async {
=======
    String firstName,
    String lastName,
    String email,
    String password,
    String preference,
  ) async {
>>>>>>> 1e1a4f0 (Still WIP: saved local changes before pulling)
    if (await isEmailRegistered(email)) {
      throw Exception("email is already registered");
    }
    if (!isPasswordStrong(password)) {
      throw Exception("password is not strong enough");
    }

<<<<<<< HEAD
    // Save user to database
    await _db.registerUser(firstName, lastName, email, password, preference, role);
=======
    // Store with DBService.registerUser (DBService uses bcrypt)
    await _db.registerUser(firstName, lastName, email, password, preference);
>>>>>>> 1e1a4f0 (Still WIP: saved local changes before pulling)
  }

  /// Returns true if email is already registered
  Future<bool> isEmailRegistered(String email) async {
    final user = await getUserByEmail(email);
    return user != null;
  }

  /// Wrapper for DBService.getUserByEmail
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    return await _db.getUserByEmail(email);
  }

  /// Logs out current user
  void logout() {
    currentUser = null;
    notifyListeners();
  }

  // ---------------- PETS ----------------

  Future<void> addPet(Pet pet) async {
    await _db.insertPet(pet);
    pets = await _db.getPets();
    notifyListeners();
  }

  Future<void> updatePet(Pet pet) async {
    await _db.updatePet(pet);
    pets = await _db.getPets();
    notifyListeners();
  }

  Future<void> loadPet() async {
    pets = await _db.getPets();
    notifyListeners();
  }

  Future<void> deletePet(int id) async {
    await _db.deletePet(id);
    pets = await _db.getPets();
    reminders = await _db.getAllReminders();
    notifyListeners();
  }

  // ---------------- REMINDERS ----------------

  Future<void> addReminder(Reminder r) async {
    await _db.insertReminder(r);
    reminders = await _db.getAllReminders();
    notifyListeners();
  }

  Future<void> updateReminder(Reminder r) async {
    await _db.updateReminder(r);
    reminders = await _db.getAllReminders();
    notifyListeners();
  }

  Future<void> loadReminder() async {
    reminders = await _db.getAllReminders();
    notifyListeners();
  }

  Future<void> deleteReminder(int id) async {
    await _db.deleteReminder(id);
    reminders = await _db.getAllReminders();
    notifyListeners();
  }

  // ---------------- PASSWORD HELPERS ----------------
  // Keep these locally so UI components can call AppState.passwordChecks etc.
  bool isPasswordStrong(String password) {
    final checks = passwordChecks(password);
    return checks.every((c) => c);
  }

  /// Return strength score 0-5
  int passwordStrengthScore(String password) {
    final checks = passwordChecks(password);
    return checks.where((c) => c).length;
  }

  /// Returns a list of bools for each requirement:
  /// [minLength, hasUpper, hasLower, hasDigit, hasSymbol]
  List<bool> passwordChecks(String password) {
    return [
      password.length >= 8,
      RegExp(r'[A-Z]').hasMatch(password),
      RegExp(r'[a-z]').hasMatch(password),
      RegExp(r'\d').hasMatch(password),
      RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password),
    ];
  }

  // ---------------- Medical Records ----------------

  Future<void> addMedicalRecord(MedicalRecord record) async {
    await _db.insertMedicalRecord(record);
    medicalRecords = await _db.getMedicalRecordsForPet(record.petId);
    notifyListeners();
  }

  Future<void> loadMedicalRecords(int petId) async {
    medicalRecords = await _db.getMedicalRecordsForPet(petId);
    notifyListeners();
  }

  Future<void> updateMedicalRecord(MedicalRecord record) async {
    await _db.updateMedicalRecord(record);
    medicalRecords = await _db.getMedicalRecordsForPet(record.petId);
    notifyListeners();
  }

  Future<void> deleteMedicalRecord(int id, int petId) async {
    await _db.deleteMedicalRecord(id);
    medicalRecords = await _db.getMedicalRecordsForPet(petId);
    notifyListeners();
  }
}
