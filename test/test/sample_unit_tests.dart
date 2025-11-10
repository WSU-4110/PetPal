import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sample Unit Tests', () {
    test('simple math works', () {
      final sum = 2 + 3;
      expect(sum, 5);
    });

    test('string uppercase works', () {
      const original = 'petpal';
      final upper = original.toUpperCase();
      expect(upper, 'PETPAL');
    });

    test('list add and length work', () {
      final pets = <String>[];

      pets.add('Buddy');
      pets.add('Milo');

      expect(pets.length, 2);
      expect(pets.contains('Buddy'), isTrue);
      expect(pets.contains('Milo'), isTrue);
    });

    test('list remove works', () {
      final reminders = <String>['Feed', 'Walk', 'Vet'];

      reminders.remove('Walk');

      expect(reminders.length, 2);
      expect(reminders.contains('Walk'), isFalse);
      expect(reminders, ['Feed', 'Vet']);
    });

    test('map lookup and update work', () {
      final petAges = <String, int>{
        'Buddy': 3,
        'Milo': 4,
      };

      expect(petAges['Buddy'], 3);

      // update a value
      petAges['Buddy'] = 4;

      expect(petAges['Buddy'], 4);
      expect(petAges.containsKey('Milo'), isTrue);
    });

    test('filtering a list returns only matching items', () {
      final pets = <String>['Buddy', 'Milo', 'Bella', 'Max'];

      final filtered = pets.where((name) => name.startsWith('B')).toList();

      expect(filtered.length, 2);
      expect(filtered, ['Buddy', 'Bella']);
    });
  });
}
