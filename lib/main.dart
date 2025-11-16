// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ui/owner_home_screen.dart';
import 'ui/pet_list_screen.dart';
import 'ui/reminder_list_screen.dart';
import 'ui/exercise_logs.dart';
import 'ui/groom_logs.dart';
import 'ui/app_drawer.dart';
import 'ui/login_page.dart';
import 'ui/medical_records.dart';
import 'ui/vet_home_screen.dart';
import 'ui/groomer_home_screen.dart';
import 'ui/trainer_home_screen.dart';
import 'dashboards/vetdash.dart';
import 'dashboards/trainerdash.dart';
import 'dashboards/groomdash.dart';
import 'state/app_state.dart' as app_state;
import 'models/pet.dart';

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

class MainNavigation extends StatefulWidget {
  final String role;
  const MainNavigation({super.key, required this.role});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  List<Widget> get _pages {
    switch (widget.role) {
      case 'owner':
        return const [
          OwnerHomeScreen(),
          PetListScreen(),
          ReminderListScreen(),
          ExerciseLogs(petId: 1),
          GroomLogs(petId: 1),
        ];
      case 'vet':
        return [
          const VetHomeScreen(),
          const VetDashboard(),
        ];
      case 'trainer':
        return [
          const TrainerHomeScreen(),
          const TrainerDashboard(),
        ];
      case 'groomer':
        return [
          const GroomerHomeScreen(),
          const GroomerDashboard(),
        ];
      default:
        return [Center(child: Text("Unknown role"))];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getAppBarTitle() {
    switch (widget.role) {
      case 'owner':
        return 'Owner Dashboard';
      case 'vet':
        return 'Veterinarian Dashboard';
      case 'trainer':
        return 'Trainer Dashboard';
      case 'groomer':
        return 'Groomer Dashboard';
      default:
        return 'Dashboard';
    }
  }

  List<BottomNavigationBarItem> _getBottomNavItems() {
    switch (widget.role) {
      case 'owner':
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Pets'),
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Reminders'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: 'Exercise'),
          BottomNavigationBarItem(icon: Icon(Icons.cut), label: 'Grooming'),
        ];
      case 'vet':
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Health'),
        ];
      case 'trainer':
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: 'Exercise'),
        ];
      case 'groomer':
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.cut), label: 'Grooming'),
        ];
      default:
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromRGBO(184, 146, 247, 1),
            Color.fromRGBO(250, 196, 241, 1),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Text(_getAppBarTitle()),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon!')),
                );
              },
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: _pages[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromRGBO(184, 146, 247, 1),
                Color.fromRGBO(250, 196, 241, 1),
              ],
            ),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            showUnselectedLabels: true,
            items: _getBottomNavItems(),
          ),
        ),
      ),
    );
  }
}
