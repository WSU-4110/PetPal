import 'package:flutter/foundation.dart';
import '../models/pet.dart';
import '../models/reminder.dart';
import '../services/db_service.dart';
import '../models/medical_record.dart';


class AppState extends ChangeNotifier {
  final DBService _db = DBService();

  List<Pet> pets = [];
  List<Reminder> reminders = [];

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
  /// Throws Exception with "invalid email" or "invalid password"
  Future<void> login(String email, String password) async {
    final userByEmail = await getUserByEmail(email);

    if (userByEmail == null) {
      throw Exception("invalid email");
    }

    final hashedInput = _db.hashPassword(password);
    if (userByEmail['password'] != hashedInput) {
      throw Exception("invalid password");
    }

    currentUser = userByEmail;
    notifyListeners();
  }

  /// Registers a new user
  /// Throws Exception if email exists or password is weak
  Future<void> register(
      String firstName, String lastName, String email, String password, String preference) async {
    if (await isEmailRegistered(email)) {
      throw Exception("email is already registered");
    }
    if (!_db.isPasswordStrong(password)) {
      throw Exception("password is not strong enough");
    }

    // Save user to database
    await _db.registerUser(firstName, lastName, email, password, preference);
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

  Future<void> deleteReminder(int id) async {
    await _db.deleteReminder(id);
    reminders = await _db.getAllReminders();
    notifyListeners();
  }

  // ---------------- PASSWORD HELPERS ----------------

  /// Check if password meets strength requirements
  bool isPasswordStrong(String password) => _db.isPasswordStrong(password);

  /// Return strength score 0-5
  int passwordStrengthScore(String password) => _db.passwordStrengthScore(password);

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
  List<MedicalRecord> medicalRecords = [];

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
