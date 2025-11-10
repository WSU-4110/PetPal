import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pet.dart';
import '../models/reminder.dart';
import '../models/medical_record.dart';
import '../services/db_service.dart';
import '../models/exercise_log.dart';
import '../models/groom_log.dart';

class AppState extends ChangeNotifier {
  final DBService _db = DBService();

  // Make DB service accessible to other classes
  DBService get db => _db;

  // Primary data
  List<Pet> pets = [];
  List<Reminder> reminders = [];
  List<MedicalRecord> medicalRecords = [];
  List<ExerciseLog> exerciseLogs = [];
  List<GroomLog> groomLogs = [];

  Map<String, dynamic>? currentUser;

  // App settings
  bool _darkMode = false;
  String? _profileImagePath;
  String? _displayName;

  static const String _kDarkModeKey = 'petpal_dark_mode';
  static const String _kProfileImageKey = 'petpal_profile_image';
  static const String _kDisplayNameKey = 'petpal_display_name';

  Future<void> init() async {
    await _loadInitialData();
    await _loadSettings();
  }

  Future<void> _loadInitialData() async {
    pets = await _db.getPets();
    reminders = await _db.getAllReminders();
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _darkMode = prefs.getBool(_kDarkModeKey) ?? false;
      _profileImagePath = prefs.getString(_kProfileImageKey);
      _displayName = prefs.getString(_kDisplayNameKey);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _saveBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
  }

  Future<void> _saveString(String key, String? value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value == null) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, value);
      }
    } catch (_) {}
  }

  // Settings getters / setters
  bool get isDarkMode => _darkMode;
  String? get profileImagePath => _profileImagePath;

  /// Compatibility: expose `user` getter so older widgets expecting `appState.user` keep working.
  Map<String, dynamic>? get user => currentUser;

  String get displayName {
    if (_displayName != null && _displayName!.trim().isNotEmpty) return _displayName!;
    if (currentUser != null) {
      final f = (currentUser!['firstName'] ?? '').toString();
      final l = (currentUser!['lastName'] ?? '').toString();
      final combined = ('$f $l').trim();
      if (combined.isNotEmpty) return combined;
    }
    return 'PetPal User';
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    await _saveBool(_kDarkModeKey, value);
    notifyListeners();
  }

  Future<void> setProfileImage(String? path) async {
    _profileImagePath = path;
    await _saveString(_kProfileImageKey, path);
    if (currentUser != null) currentUser!['profileImage'] = path;
    notifyListeners();
  }

  Future<void> setDisplayName(String? name) async {
    _displayName = (name == null || name.trim().isEmpty) ? null : name.trim();
    await _saveString(_kDisplayNameKey, _displayName);
    notifyListeners();
  }

  // ---------------- LOGIN / REGISTER ----------------
  Future<Map<String, dynamic>> login(String email, String password) async {
    final user = await _db.loginUser(email, password);

    if (user == null) {
      final byEmail = await _db.getUserByEmail(email);
      if (byEmail == null) throw Exception("invalid email");
      throw Exception("invalid password");
    }

    currentUser = user;
    if (_profileImagePath != null) currentUser!['profileImage'] = _profileImagePath;
    notifyListeners();
    return user;
  }

  Future<void> register(
      String firstName,
      String lastName,
      String email,
      String password,
      String preference,
      String role) async {
    if (await isEmailRegistered(email)) throw Exception("email is already registered");
    if (!isPasswordStrong(password)) throw Exception("password is not strong enough");
    await _db.registerUser(firstName, lastName, email, password, preference, role);
  }

  Future<bool> isEmailRegistered(String email) async {
    final user = await getUserByEmail(email);
    return user != null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    return await _db.getUserByEmail(email);
  }

  Future<void> logout() async {
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

  Pet? getPetById(int? id) {
    if (id == null) return null;
    try {
      return pets.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
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
  bool isPasswordStrong(String password) => passwordChecks(password).every((c) => c);

  int passwordStrengthScore(String password) =>
      passwordChecks(password).where((c) => c).length;

  List<bool> passwordChecks(String password) => [
        password.length >= 8,
        RegExp(r'[A-Z]').hasMatch(password),
        RegExp(r'[a-z]').hasMatch(password),
        RegExp(r'\d').hasMatch(password),
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password),
      ];

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

  // ---------------- Groom Logs ----------------
  Future<void> addGroomLog(GroomLog record) async {
    await _db.insertGroomLog(record);
    groomLogs = await _db.getGroomLog(record.petId);
    notifyListeners();
  }

  Future<void> loadGroomLog(int petId) async {
    groomLogs = await _db.getGroomLog(petId);
    notifyListeners();
  }

  Future<void> updateGroomLog(GroomLog record) async {
    await _db.updateGroomLog(record);
    groomLogs = await _db.getGroomLog(record.petId);
    notifyListeners();
  }

  Future<void> deleteGroomLog(int id, int petId) async {
    await _db.deleteGroomLog(id);
    groomLogs = await _db.getGroomLog(petId);
    notifyListeners();
  }

  // ---------------- Veterinarians ----------------
  Future<List<Map<String, dynamic>>> getVeterinarians() async {
    return await _db.getUsersByRole('vet');
  }

  Future<Map<String, dynamic>?> getVeterinarianById(int vetId) async {
    final vets = await getVeterinarians();
    try {
      return vets.firstWhere((v) => v['id'] == vetId);
    } catch (_) {
      return null;
    }
  }

  // ---------------- Search helpers ----------------
  List<Pet> searchPets({
    String? query,
    String? species,
    String? breed,
    int? minAge,
    int? maxAge,
  }) {
    final q = (query ?? '').trim().toLowerCase();
    return pets.where((p) {
      if (q.isNotEmpty) {
        final combined = '${p.name} ${p.species} ${p.breed}'.toLowerCase();
        if (!combined.contains(q)) return false;
      }
      if (species != null && species.isNotEmpty) {
        if (p.species.toLowerCase() != species.toLowerCase()) return false;
      }
      if (breed != null && breed.isNotEmpty && breed != 'Other') {
        if (p.breed.toLowerCase() != breed.toLowerCase()) return false;
      }
      if (minAge != null && p.age < minAge) return false;
      if (maxAge != null && p.age > maxAge) return false;
      return true;
    }).toList();
  }

  // ---------------- Home visuals / tips ----------------
  String getRandomPetImage() {
    if (pets.isEmpty) return Pet.imageFor('', '');
    if (pets.length == 1) {
      final p = pets.first;
      return p.image ?? Pet.imageFor(p.species, p.breed);
    }
    final rnd = Random();
    final p = pets[rnd.nextInt(pets.length)];
    return p.image ?? Pet.imageFor(p.species, p.breed);
  }

  List<String> getTips({int max = 6}) {
    final List<String> tips = [
      'Make sure fresh water is always available.',
      'Schedule regular vet checkups — prevention beats cure.',
      'Use positive reinforcement during training.',
    ];

    final speciesSet = pets.map((p) => p.species.toLowerCase()).toSet();
    if (speciesSet.contains('cat')) {
      tips.addAll([
        'Cats need daily play — try short interactive sessions.',
        'Keep the litter box clean and in a quiet place.',
      ]);
    }
    if (speciesSet.contains('dog')) {
      tips.addAll([
        'Dogs benefit from daily walks and socialization.',
        'Rotate toys to keep playtime interesting.',
      ]);
    }
    if (speciesSet.contains('rabbit')) {
      tips.addAll(['Rabbits need chewing toys and safe space to hop.']);
    }

    tips.shuffle();
    return tips.take(max).toList();
  }

  Future<void> close() async => await _db.close();
}