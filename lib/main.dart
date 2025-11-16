// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/login_page.dart';
import 'ui/medical_records.dart';
import 'state/app_state.dart' as app_state;
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
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white), // force all text white
        child: MaterialApp(
          title: 'PetPal',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: false,
            scaffoldBackgroundColor: const Color.fromRGBO(184, 146, 247, 1),
            colorScheme: const ColorScheme.light(
              primary: Color.fromRGBO(184, 146, 247, 1),
              secondary: Color.fromRGBO(250, 196, 241, 1),
              surface: Color.fromRGBO(184, 146, 247, 1),
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: Colors.white,
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(color: Colors.white),
              displayMedium: TextStyle(color: Colors.white),
              displaySmall: TextStyle(color: Colors.white),
              headlineLarge: TextStyle(color: Colors.white),
              headlineMedium: TextStyle(color: Colors.white),
              headlineSmall: TextStyle(color: Colors.white),
              titleLarge: TextStyle(color: Colors.white),
              titleMedium: TextStyle(color: Colors.white),
              titleSmall: TextStyle(color: Colors.white),
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white),
              bodySmall: TextStyle(color: Colors.white),
              labelLarge: TextStyle(color: Colors.white),
              labelMedium: TextStyle(color: Colors.white),
              labelSmall: TextStyle(color: Colors.white),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.transparent,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              showUnselectedLabels: true,
            ),
            drawerTheme: const DrawerThemeData(
              backgroundColor: Color.fromRGBO(250, 196, 241, 1),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color.fromRGBO(250, 196, 241, 1),
              foregroundColor: Colors.white,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color.fromRGBO(255, 255, 255, 0.15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              labelStyle: const TextStyle(color: Colors.white),
              hintStyle: const TextStyle(color: Colors.white70),
            ),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const LoginPage(),
            '/main': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
              return MainNavigation(role: args['role'] as String);
            },
            '/medical_records': (context) {
              final pet = ModalRoute.of(context)!.settings.arguments as Pet;
              return MedicalRecordsPage(petId: pet.id!);
            },
          },
        ),
      ),
    );
  }
}