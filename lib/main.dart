import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/login_page.dart';
import 'ui/medical_records.dart';
import 'state/app_state.dart' as app_state; // aliased to avoid ambiguity
import 'models/pet.dart';
import 'main_nav.dart';

void main() {
  runApp(const PetPalApp());
}

class PetPalApp extends StatelessWidget {
  const PetPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final state = app_state.AppState();
        state.init(); // load initial data and settings
        return state;
      },
      child: MaterialApp(
        title: 'PetPal',
        theme: ThemeData(primarySwatch: Colors.teal),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginPage(),
          '/main': (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return MainNavigation(role: args['role'] as String);
          },
          '/medical_records': (context) {
            final pet = ModalRoute.of(context)!.settings.arguments as Pet;
            return MedicalRecordsPage(petId: pet.id!);
          },
        },
      ),
    );
  }
}