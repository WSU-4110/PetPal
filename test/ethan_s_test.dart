import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petpal/state/app_state.dart';
import 'package:petpal/ui/add_medical_record_dialog.dart';
import 'package:petpal/ui/edit_medical_record_dialog.dart';
import 'package:petpal/models/medical_record.dart';
import 'package:petpal/models/pet.dart';
import 'package:petpal/ui/add_groom_log_dialog.dart';
import 'package:petpal/ui/add_exercise_log_dialog.dart';

/*Pet({
    this.id,
    required this.name,
    required this.gender,
    required this.species,
    required this.breed,
    required this.age,
  });
*/
void main() {
  late Pet pet;
  late MedicalRecord original;

  /*
    MedicalRecord({
    this.id,
    required this.petId,
    required this.title,
    required this.description,
    required this.date,
    required this.vetName,
  });
*/

  setUp(() {
      pet = Pet(
        id: 1, 
        name: 'Daisy', 
        gender: 'female',
        species: 'dog', 
        breed: 'German Shephard', 
        age: 3);

      original = MedicalRecord(
        id: 101,
        petId: pet.id!,
        title: 'Yearly Checkup',
        description: 'Yearly Checkup and Shot Updates',
        date: DateTime(2025, 10, 31),
        vetName: 'Vet Clinic 101',
      );

});

  tearDown(() {
      //Tears down after each test
  });

testWidgets('1. Dialog opens and renders', (tester) async {
    await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: EditMedicalRecordDialog(
        medicalrecord: original,
        pets: [pet],
      ),
    ),
  ));

  expect(find.text('Appointment Title'), findsOneWidget);
});

  testWidgets('2. Title field shows original value', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: EditMedicalRecordDialog(
        medicalrecord: original,
        pets: [pet],
      ),
    ),
  ));

  expect(find.text('Yearly Checkup'), findsOneWidget);
});

testWidgets('3. AddMedicalRecordDialog shows description field', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: AddMedicalRecordDialog(petId: 1),
    ),
  ));

  // find description
  expect(find.text('Description'), findsOneWidget);

  // enter text
  await tester.enterText(find.byType(TextFormField).last, 'Test description');

  // verify
  expect(find.text('Test description'), findsOneWidget);
});


testWidgets('4. AddGroomLogDialog shows Add Grooming Log', (tester) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>(
      create: (_) => AppState(),
      child: const MaterialApp(
        home: Scaffold(
          body: AddGroomLogDialog(petId: 1),
        ),
      ),
    ),
  );

  await tester.pump();

  //verify
  expect(find.text('Add Grooming Log'), findsOneWidget);
});

testWidgets('5. AddExerciseLogDialog allows entering activity text', (tester) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>(
      create: (_) => AppState(),
      child: const MaterialApp(
        home: Scaffold(
          body: AddExerciseLogDialog(petId: 1),
        ),
      ),
    ),
  );

  await tester.pump();

  // find activity completed and enter text
  await tester.enterText(find.byType(TextFormField).first, 'Morning Run');

  // verify the text
  expect(find.text('Morning Run'), findsOneWidget);
});

}