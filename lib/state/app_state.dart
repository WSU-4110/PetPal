// lib/state/app_state.dart
import 'dart:math';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet.dart';
import '../models/reminder.dart';
import '../models/medical_record.dart';
import '../models/appointment.dart';
import '../models/exercise_log.dart';
import '../models/groom_log.dart';
import '../models/notification.dart';
import '../services/db_service.dart';

class AppState extends ChangeNotifier {
  final DBService _db = DBService();
  DBService get db => _db;

  // Primary data
  List<Pet> pets = [];
  List<Pet> accessiblePets = [];
  List<Reminder> reminders = [];
  List<MedicalRecord> medicalRecords = [];
  List<ExerciseLog> exerciseLogs = [];
  List<GroomLog> groomLogs = [];
  List<Appointment> appointments = [];
  List<Map<String, dynamic>> groomingAppointments = [];
  List<Map<String, dynamic>> trainingAppointments = [];
  List<AppNotification> notifications = [];

  Map<String, dynamic>? currentUser;
  Map<int, List<int>> petAccessMap = {};
  final Map<int, Map<String, dynamic>> _petHealthInfo = {};

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
    await loadAppointments();
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

  bool get isDarkMode => _darkMode;
  String? get profileImagePath => _profileImagePath;
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

  // Login/Register
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

  Future<void> register(String firstName, String lastName, String email, String password, String preference, String role) async {
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

  // Pets
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

  // Reminders
  Future<void> addReminder(Reminder r) async {
    await _db.insertReminder(r);
    await _db.insertNotification(AppNotification(
      id: r.id,
      title: r.title,
      body: 'Reminder for ${r.category}',
      scheduledAt: r.scheduledAt,
    ));
    reminders = await _db.getAllReminders();
    //_unreadNotificationsCount++;
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
    await _db.deleteNotification(id);
    reminders = await _db.getAllReminders();
    notifyListeners();
  }

  // Appointments
  Future<void> addAppointment(Appointment appointment) async {
    try {
      final id = await _db.insertAppointment(appointment);
      final appointmentWithId = appointment.copyWith(id: id);
      appointments.add(appointmentWithId);
      appointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      notifyListeners();
    } catch (e) {
      developer.log('Error adding appointment: $e', name: 'AppState');
      notifyListeners();
    }
  }

  Future<void> loadAppointments() async {
    try {
      appointments = await _db.getAllAppointments();
      notifyListeners();
    } catch (e) {
      developer.log('Error loading appointments: $e', name: 'AppState');
      notifyListeners();
    }
  }

  Future<void> loadAppointmentsForPet(int petId) async {
    try {
      final allAppointments = await _db.getAllAppointments();
      final petAppointments = allAppointments.where((a) => a.petId == petId).toList();
      appointments.removeWhere((a) => a.petId == petId);
      appointments.addAll(petAppointments);
      appointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      notifyListeners();
    } catch (e) {
      developer.log('Error loading appointments for pet: $e', name: 'AppState');
      notifyListeners();
    }
  }

  Future<void> loadAppointmentsForVet(int vetId) async {
    try {
      final allAppointments = await _db.getAllAppointments();
      final vetAppointments = allAppointments.where((a) => a.vetId == vetId).toList();
      appointments = vetAppointments;
      appointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      notifyListeners();
    } catch (e) {
      developer.log('Error loading appointments for vet: $e', name: 'AppState');
      notifyListeners();
    }
  }

  Future<List<Appointment>> getUpcomingAppointments({int? petId, int? vetId}) async {
    try {
      final allAppointments = await _db.getAllAppointments();
      final now = DateTime.now();
      return allAppointments.where((a) {
        if (petId != null && a.petId != petId) return false;
        if (vetId != null && a.vetId != vetId) return false;
        return a.dateTime.isAfter(now) && a.status == 'upcoming';
      }).toList();
    } catch (e) {
      developer.log('Error getting upcoming appointments: $e', name: 'AppState');
      return [];
    }
  }

  Future<void> updateAppointment(Appointment appointment) async {
    try {
      await _db.updateAppointment(appointment);
      final index = appointments.indexWhere((a) => a.id == appointment.id);
      if (index != -1) {
        appointments[index] = appointment;
      }
      notifyListeners();
    } catch (e) {
      developer.log('Error updating appointment: $e', name: 'AppState');
      notifyListeners();
    }
  }

  Future<void> deleteAppointment(int id) async {
    try {
      await _db.deleteAppointment(id);
      appointments.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      developer.log('Error deleting appointment: $e', name: 'AppState');
      notifyListeners();
    }
  }

  List<Appointment> getAppointmentsForPetLocal(int petId) {
    return appointments.where((a) => a.petId == petId).toList();
  }

  // Grooming Appointments
  Future<void> addGroomingAppointment(Map<String, dynamic> appointment) async {
    try {
      await _db.insertGroomingAppointment(appointment);
      await loadGroomingAppointmentsForPet(appointment['petId']);
    } catch (e) {
      developer.log('Error adding grooming appointment: $e', name: 'AppState');
      notifyListeners();
    }
  }

  Future<void> loadGroomingAppointmentsForPet(int petId) async {
    try {
      groomingAppointments = await _db.getGroomingAppointmentsForPet(petId);
      notifyListeners();
    } catch (e) {
      developer.log('Error loading grooming appointments for pet: $e', name: 'AppState');
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> getGroomingAppointmentsForPetLocal(int petId) {
    return groomingAppointments.where((a) {
      try {
        return (a['petId'] as int) == petId;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Future<void> deleteGroomingAppointment(String id) async {
    try {
      await _db.deleteGroomingAppointment(id);
      groomingAppointments.removeWhere((a) => a['id'].toString() == id);
      notifyListeners();
    } catch (e) {
      developer.log('Error deleting grooming appointment: $e', name: 'AppState');
      notifyListeners();
    }
  }

  // Training Appointments
  Future<void> addTrainingAppointment(Map<String, dynamic> appointment) async {
    try {
      await _db.insertTrainingAppointment(appointment);
      await loadTrainingAppointmentsForPet(appointment['petId']);
    } catch (e) {
      developer.log('Error adding training appointment: $e', name: 'AppState');
      notifyListeners();
    }
  }

  Future<void> loadTrainingAppointmentsForPet(int petId) async {
    try {
      trainingAppointments = await _db.getTrainingAppointmentsForPet(petId);
      notifyListeners();
    } catch (e) {
      developer.log('Error loading training appointments for pet: $e', name: 'AppState');
      notifyListeners();
    }
  }

  Future<void> loadTrainingAppointmentsForTrainer(int trainerId) async {
    try {
      final List<Map<String, dynamic>> collected = [];
      List<int> petIds = [];
      try {
        petIds = await _db.getAccessiblePetIds(trainerId);
      } catch (_) {
        if (accessiblePets.isNotEmpty) {
          petIds = accessiblePets.map((p) => p.id!).toList();
        } else {
          final allPets = await _db.getPets();
          petIds = allPets.map((p) => p.id!).toList();
        }
      }
      for (final pid in petIds) {
        try {
          final list = await _db.getTrainingAppointmentsForPet(pid);
          if (list.isNotEmpty) {
            collected.addAll(List<Map<String, dynamic>>.from(list));
          }
        } catch (e) {
          developer.log('Error loading training appointments for pet $pid: $e', name: 'AppState');
        }
      }
      final filtered = collected.where((a) {
        try {
          final candidate = a['trainerId'] ?? a['trainer_id'] ?? a['trainer'] ?? a['assignedTo'] ?? a['assigned_trainer'];
          if (candidate == null) return false;
          if (candidate is int) return candidate == trainerId;
          if (candidate is String) return int.tryParse(candidate) == trainerId;
          return false;
        } catch (_) {
          return false;
        }
      }).toList();
      trainingAppointments = filtered;
      notifyListeners();
    } catch (e) {
      developer.log('Error loading training appointments for trainer $trainerId: $e', name: 'AppState');
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> getTrainingAppointmentsForPetLocal(int petId) {
    return trainingAppointments.where((a) {
      try {
        return (a['petId'] as int) == petId;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Future<void> deleteTrainingAppointment(String id) async {
    try {
      await _db.deleteTrainingAppointment(id);
      trainingAppointments.removeWhere((a) => a['id'].toString() == id);
      notifyListeners();
    } catch (e) {
      developer.log('Error deleting training appointment: $e', name: 'AppState');
      notifyListeners();
    }
  }

  // Password Helpers
  bool isPasswordStrong(String password) => passwordChecks(password).every((c) => c);

  int passwordStrengthScore(String password) => passwordChecks(password).where((c) => c).length;

  List<bool> passwordChecks(String password) => [
    password.length >= 8,
    RegExp(r'[A-Z]').hasMatch(password),
    RegExp(r'[a-z]').hasMatch(password),
    RegExp(r'\d').hasMatch(password),
    RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password),
  ];

  // Medical Records
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

  // Pet Health Information
  Future<Map<String, dynamic>?> getPetHealthInfo(int petId) async {
    try {
      if (_petHealthInfo.containsKey(petId)) {
        return _petHealthInfo[petId];
      }
      final healthInfo = await _db.getPetHealthInfo(petId);
      if (healthInfo != null) {
        _petHealthInfo[petId] = healthInfo;
      }
      return healthInfo;
    } catch (e) {
      developer.log('Error getting pet health info: $e', name: 'AppState');
      return null;
    }
  }

  Future<void> updatePetHealthInfo(int petId, Map<String, dynamic> healthInfo) async {
    try {
      await _db.updatePetHealthInfo(petId, healthInfo);
      _petHealthInfo[petId] = healthInfo;
      notifyListeners();
    } catch (e) {
      developer.log('Error updating pet health info: $e', name: 'AppState');
      rethrow;
    }
  }

  // Exercise Logs
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

  Future<List<Map<String, dynamic>>> getTrainers() async {
    return await _db.getUsersByRole('trainer');
  }

  // Groom Logs
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

  Future<List<Map<String, dynamic>>> getGroomers() async {
    return await _db.getUsersByRole('groomer');
  }

  // Veterinarians
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

  // Pet Access
  Future<void> grantAccess(int petId, int userId) async {
    if (petId <= 0 || userId <= 0) {
      developer.log('Error: petId or userId is invalid: $petId, $userId', name: 'AppState');
      return;
    }
    try {
      await _db.grantAccess(petId, userId);
      await fetchPetAccess(petId);
      notifyListeners();
    } catch (e) {
      developer.log('Error granting access: $e', name: 'AppState');
      notifyListeners();
    }
  }

  Future<void> revokeAccess(int petId, int userId) async {
    if (petId <= 0 || userId <= 0) {
      developer.log('Error: petId or userId is invalid: $petId, $userId', name: 'AppState');
      return;
    }
    try {
      await _db.deletePetAccess(petId, userId);
      await fetchPetAccess(petId);
      notifyListeners();
    } catch (e) {
      developer.log('Error revoking access: $e', name: 'AppState');
      notifyListeners();
    }
  }

  Future<void> fetchPetAccess(int petId) async {
    try {
      final rows = await _db.getPetAccess(petId);
      petAccessMap[petId] = rows.map((r) => r.userId).toList();
      notifyListeners();
    } catch (e) {
      developer.log('Error fetching pet access: $e', name: 'AppState');
      petAccessMap[petId] = [];
      notifyListeners();
    }
  }

  List<int> getPetAccessIds(int petId) {
    return petAccessMap[petId] ?? [];
  }

  Future<void> loadAccessiblePets(int vetId) async {
    final petIds = await _db.getAccessiblePetIds(vetId);
    accessiblePets = pets.where((p) => petIds.contains(p.id)).toList();
    notifyListeners();
  }

  // User Role Checkers
  bool get isOwner {
    if (currentUser == null) return false;
    final role = currentUser!['role']?.toString().toLowerCase();
    return role == 'owner' || role == 'pet_owner';
  }

  bool get isVet {
    if (currentUser == null) return false;
    final role = currentUser!['role']?.toString().toLowerCase();
    return role == 'vet' || role == 'veterinarian';
  }

  bool get isGroomer {
    if (currentUser == null) return false;
    final role = currentUser!['role']?.toString().toLowerCase();
    return role == 'groomer' || role == 'pet_groomer';
  }

  bool get isTrainer {
    if (currentUser == null) return false;
    final role = currentUser!['role']?.toString().toLowerCase();
    return role == 'trainer' || role == 'pet_trainer';
  }

  // Search Helpers
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

  // Home Visuals/Tips
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

  // ---------------- Notifications ----------------
  int get unreadNotificationsCount {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return notifications.where((n) =>
    n.scheduledAt != null &&
        n.scheduledAt!.isBefore(todayEnd)
    ).length;
  }

  Future<void> deleteNotification(int id) async {
    await _db.deleteNotification(id);
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