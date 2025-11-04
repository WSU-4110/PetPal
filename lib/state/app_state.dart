// lib/state/app_state.dart
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/pet.dart';
import '../models/reminder.dart';
import '../models/medical_record.dart';
import '../services/db_service.dart';
import '../models/exercise_log.dart';

class AppState extends ChangeNotifier {
  final DBService _db = DBService();

  List<Pet> pets = [];
  List<Reminder> reminders = [];
  List<MedicalRecord> medicalRecords = [];
  List<ExerciseLog> exerciseLogs = [];

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
  /// Throws Exception("invalid email") or Exception("invalid password")
  Future<Map<String, dynamic>> login(String email, String password) async {
    // Try using DBService loginUser (your teammates may have updated this)
    final user = await _db.loginUser(email, password);

    if (user == null) {
      // fallback check: see if email exists
      final byEmail = await _db.getUserByEmail(email);
      if (byEmail == null) {
        throw Exception("invalid email");
      } else {
        throw Exception("invalid password");
      }
    }

    currentUser = user;
    notifyListeners();
    return user;
  }

  /// Registers a new user
  /// Throws Exception if email exists or password is weak
  Future<void> register(
      String firstName,
      String lastName,
      String email,
      String password,
      String preference,
      String role) async {
    if (await isEmailRegistered(email)) {
      throw Exception("email is already registered");
    }
    if (!isPasswordStrong(password)) {
      throw Exception("password is not strong enough");
    }

    // Store with DBService.registerUser
    await _db.registerUser(firstName, lastName, email, password, preference, role);
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
  bool isPasswordStrong(String password) {
    final checks = passwordChecks(password);
    return checks.every((c) => c);
  }

  int passwordStrengthScore(String password) {
    final checks = passwordChecks(password);
    return checks.where((c) => c).length;
  }

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

  // ---------------- Exercise Logs ----------------

  Future<void> addExerciseLog(ExerciseLog record) async {
    await _db.insertExerciseLog(record);
    exerciseLogs = await _db.getExerciseLog(record.petId);
    notifyListeners();
  }

  Future<void> loadExerciseLog(int petId) async {
    exerciseLogs = await _db.getExerciseLog(petId);
    notifyListeners();
  }

  Future<void> updateExerciseLog(ExerciseLog record) async {
    await _db.updateExerciseLog(record);
    exerciseLogs = await _db.getExerciseLog(record.petId);
    notifyListeners();
  }

  Future<void> deleteExerciseLog(int id, int petId) async {
    await _db.deleteExerciseLog(id);
    exerciseLogs = await _db.getExerciseLog(petId);
    notifyListeners();
  }
}
