// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ui/home_screen.dart';
import 'ui/pet_list_screen.dart';
import 'ui/reminder_list_screen.dart';
import 'ui/exercise_screen.dart';
import 'ui/groom_screen.dart';
import 'ui/app_drawer.dart'; // AppDrawer import
import 'ui/login_page.dart';
import 'ui/medical_records.dart';
import 'state/app_state.dart' as app_state; // aliased to avoid ambiguity
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

class MainNavigation extends StatefulWidget {
  final String role;
  const MainNavigation({super.key, required this.role});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  List<Widget> get _pages {
    if (widget.role == 'owner') {
      return [
        HomeScreen(),
        PetListScreen(),
        ReminderListScreen(),
        HealthScreen(),
        ExerciseScreen(),
        GroomScreen(),
      ];
    } else if (widget.role == 'vet') {
      return [
        HealthScreen(),
      ];
    } else if (widget.role == 'trainer') {
      return [
        ExerciseScreen(),
      ];
    } else if (widget.role == 'groomer') {
      return [
        GroomScreen(),
      ];
    } else {
      return [Center(child: Text("Unknown role"))];
      return const [
        HomeScreen(),
        PetListScreen(),
        ReminderListScreen(),
        ExerciseScreen(),
      ];
    } else if (widget.role == 'vet') {
      return const [
        HomeScreen(),
        Center(child: Text('Vet Appointments')),
      ];
    } else if (widget.role == 'trainer') {
      return const [
        HomeScreen(),
        ExerciseScreen(),
      ];
    } else {
      return const [Center(child: Text("Unknown role"))];
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
      default:
        return 'Dashboard';
    }
  }

  List<BottomNavigationBarItem> _getBottomNavItems() {
    if (widget.role == 'owner') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Pets'),
        BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Reminders'),
        BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: 'Exercise'),
      ];
    } else if (widget.role == 'vet') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Health'),
      ];
    } else if (widget.role == 'trainer') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: 'Exercise'),
      ];
    } else {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(() {
          switch (widget.role){
          case 'owner':
            return 'Owner Dashboard';
          case 'vet':
            return 'Vetereinarian Dashboard';
          case 'trainer':
            return 'Trainer Dashboard';
          case 'groomer':
            return 'Grooming Dashboard';
          default:
            return 'Dash';
    }
  }()),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: () {
          switch (widget.role) {
            case 'owner':
              return const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Pets'),
                BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Reminders'),
                BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Health'),
                BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: 'Exercise'),
                BottomNavigationBarItem(icon: Icon(Icons.cut), label: 'Grooming'),
              ];
            case 'vet':
              return const [
                BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Health'),
              ];
            case 'trainer':
              return const [
                BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: 'Exercise'),
              ];
            case 'groomer':
              return const [
                BottomNavigationBarItem(icon: Icon(Icons.cut), label: 'Grooming'),
              ];
              default:
                return const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              ];
          }
        }(),
        items: _getBottomNavItems(),
      ),
    );
  }
}
