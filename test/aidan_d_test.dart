import 'package:flutter_test/flutter_test.dart';
import 'package:petpal/models/reminder.dart';
import 'package:petpal/models/pet.dart';
import 'package:flutter/foundation.dart';
import 'package:petpal/services/db_service.dart';


class FakeAppState extends ChangeNotifier {
  List<Reminder> reminders = [];
  List<Pet> pets = [];

  Future<void> addReminder(Reminder r) async {
    reminders.add(r);
    notifyListeners();
  }

  Future<void> updateReminder(Reminder r) async {
    reminders = reminders.map((rem) => rem.id == r.id ? r : rem).toList();
    notifyListeners();
  }

  Future<void> deleteReminder(int id) async {
    reminders.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}

void main() {
  group('FakeAppState logic', () {
    late FakeAppState state;
    late Reminder reminder;

    setUp(() {
      state = FakeAppState();
      reminder = Reminder(
        id: 1,
        petId: 1,
        title: 'Walk the dog',
        category: 'Exercise',
        scheduledAt: DateTime(2024, 1, 1, 9, 0),
        done: false,
      );
    });

    test('addReminder adds a reminder', () async {
      await state.addReminder(reminder);
      expect(state.reminders.length, 1);
      expect(state.reminders.first.title, 'Walk the dog');
    });

    test('updateReminder updates an existing reminder', () async {
      await state.addReminder(reminder);
      final updated = Reminder(
        id: 1,
        petId: 1,
        title: 'Evening walk',
        category: 'Exercise',
        scheduledAt: reminder.scheduledAt,
        done: true,
      );

      await state.updateReminder(updated);

      expect(state.reminders.length, 1);
      expect(state.reminders.first.title, 'Evening walk');
      expect(state.reminders.first.done, isTrue);
    });

    test('deleteReminder removes a reminder', () async {
      await state.addReminder(reminder);
      expect(state.reminders.length, 1);

      await state.deleteReminder(1);

      expect(state.reminders, isEmpty);
    });
  });

  final db = DBService();

  group('Password hashing and verification', () {
    test('hashPassword produces a non-empty hash', () {
      const password = 'MyStrongPass123!';
      final hash = db.hashPassword(password);

      expect(hash, isNotEmpty);
      expect(hash, isA<String>());
    });

    test('verifyPassword succeeds with correct password', () {
      const password = 'AnotherStrong1!';
      final hash = db.hashPassword(password);

      expect(db.verifyPassword(password, hash), isTrue);
    });

    test('verifyPassword fails with wrong password', () {
      const password = 'CorrectPass1!';
      final hash = db.hashPassword(password);

      expect(db.verifyPassword('WrongPass!', hash), isFalse);
    });
  });

}