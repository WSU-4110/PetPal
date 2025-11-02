import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:petpal/ui/edit_medical_record_dialog.dart';
import 'package:petpal/models/medical_record.dart';
import 'package:petpal/models/pet.dart';

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
  late MedicalRecord original2;
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
        date: '2025-10-31',
        vetName: 'Vet Clinic 101',
      );

      original2 = MedicalRecord(
      id: 101,
      petId: pet.id!,
      title: 'Yearly Checkup',
      description: 'Yearly Checkup and Shot Updates',
      date: 'No Date Found',
      vetName: 'Vet Clinic 101',
  );

});

  tearDown(() {
      //Tears down after each test
  });

  testWidgets('1. Dialog opens and renders', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: EditMedicalRecordDialog(medicalrecord: original, pets: [pet]),
    ));
    
    expect(find.text('Edit Medical Record'), findsOneWidget);
  });

  testWidgets('2. Title field shows original value', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: EditMedicalRecordDialog(medicalrecord: original, pets: [pet]),
  ));

  expect(find.text('Yearly Checkup'), findsOneWidget);
});

testWidgets('3. Correct date picked', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: EditMedicalRecordDialog(medicalrecord: original, pets: [pet])
  ));

    expect(find.text('2025-10-31'), findsOneWidget);
  
});

testWidgets('4. ElevatedButton Expansion', (tester) async {

  //test variable
  MedicalRecord? returned;

  //rebuild for a test mechanism
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => ElevatedButton(
        onPressed: () async {
          returned = await showDialog<MedicalRecord>(
            context: context,
            builder: (_) => EditMedicalRecordDialog(medicalrecord: original, pets: [pet])
          );
        },
        child: const Text('Open'),
      ),
    ),
  ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    //change description and save after
    await tester.enterText(find.bySemanticsLabel('Description'), 'Hello I am a Test.');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    //test id description change matches
    expect(returned?.description, 'Hello I am a Test.');
  
});

testWidgets('5. Cancel Button Test', (tester) async {

  //test variable
  MedicalRecord? returned;

  //rebuild for a test mechanism
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () async {
          returned = await showDialog<MedicalRecord>(
            context: context,
            builder: (_) => EditMedicalRecordDialog(medicalrecord: original, pets: [pet])
          );
        },
        child: const Text('Open'),
      ),
    ),
  ));

    //open and cancel
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(returned, isNull);
});

testWidgets('6. Date Error Catch in initState', (tester) async {

  await tester.pumpWidget(MaterialApp(
    home: EditMedicalRecordDialog(medicalrecord: original2, pets: [pet])
  ));

  expect(find.text('Edit Medical Record'), findsOneWidget);

  final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
  expect(find.text(now), findsOneWidget);
});

}