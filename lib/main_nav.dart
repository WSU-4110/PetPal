import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/owner_home_screen.dart';
import 'ui/pet_list_screen.dart';
import 'ui/reminder_list_screen.dart';
import 'ui/exercise_logs.dart';
import 'ui/groom_logs.dart';
import 'ui/app_drawer.dart';
import 'ui/vet_home_screen.dart';
import 'ui/groomer_home_screen.dart';
import 'ui/trainer_home_screen.dart';
import 'ui/pet_form_screen.dart';
import 'ui/add_reminder_dialog.dart';
import 'ui/add_groom_log_dialog.dart';
import 'ui/add_exercise_log_dialog.dart';
import 'ui/search_screen.dart';
import 'dashboards/trainerdash.dart';
import 'dashboards/groomdash.dart';
import 'state/app_state.dart' as app_state;

class MainNavigation extends StatefulWidget {
  final String role;
  const MainNavigation({super.key, required this.role});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  AnimationController? _animationController; // Make it nullable

  @override
  void initState() {
    super.initState();
    // Initialize with a delay to ensure the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _animationController = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 300),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  List<Widget> get _pages {
    switch (widget.role) {
      case 'owner':
        return [
          const OwnerHomeScreen(),
          const PetListScreen(),
          const ReminderListScreen(),
          ExerciseLogs(petId: 1),
          GroomLogs(petId: 1),
        ];
      case 'vet':
        return [
          const VetHomeScreen(), // Only one screen for vets
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
    
    // Only use the animation controller if it's initialized
    if (_animationController != null) {
      _animationController!.forward().then((_) {
        _animationController!.reverse();
      });
    }
  }

  List<BottomNavigationBarItem> _getBottomNavItems() {
    switch (widget.role) {
      case 'owner':
        return [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.pets),
            label: 'Pets',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.alarm),
            label: 'Reminders',
            // Use a smaller font size to prevent truncation
            tooltip: 'Reminders',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.directions_run),
            label: 'Exercise',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.cut),
            label: 'Grooming',
          ),
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

  void _onFabPressed() {
    // owner role has more tabs; adjust by index
    if (widget.role == 'owner') {
      if (_selectedIndex == 1) {
        // Pets tab -> open PetFormScreen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PetFormScreen()),
        );
        return;
      } else if (_selectedIndex == 2) {
        // Reminders -> open AddReminderDialog
        final appState = Provider.of<app_state.AppState>(context, listen: false);
        showDialog(
          context: context,
          builder: (_) => AddReminderDialog(pets: appState.pets),
        ).then((result) {
          if (result != null) {
            // Handle the result from the dialog
            if (result is List) {
              // Multiple reminders (recurring)
              for (final reminder in result) {
                appState.addReminder(reminder);
              }
            } else {
              // Single reminder
              appState.addReminder(result);
            }
          }
        });
        return;
      } else if (_selectedIndex == 3) {
        // Exercise tab -> open AddExerciseLogDialog
        showDialog(
          context: context,
          builder: (_) => const AddExerciseLogDialog(petId: 1),
        );
        return;
      } else if (_selectedIndex == 4) {
        // Grooming tab -> open AddGroomLogDialog
        showDialog(
          context: context,
          builder: (_) => const AddGroomLogDialog(petId: 1),
        );
        return;
      }
    }

    // Fallback behavior for other roles or tabs
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Action not implemented for this tab yet.')),
    );
  }

  // Determine if FAB should be shown based on role and selected index
  bool get _showFab {
    // Don't show FAB on home screens for any role
    if (_selectedIndex == 0) return false;
    
    // Only show FAB for owner role on specific tabs
    if (widget.role == 'owner') {
      return [1, 2, 3, 4].contains(_selectedIndex);
    }
    
    return false;
  }

  // Determine if bottom nav should be shown
  bool get _showBottomNav {
    // Don't show bottom nav for vet role
    if (widget.role == 'vet') return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Let body go behind app bar and behind the bottom nav (so both overlay)
      extendBodyBehindAppBar: true,
      extendBody: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        // Increased logo size (kept as you requested)
        title: Image.asset(
          'assets/images/petlogo.png',
          height: 60,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const SearchScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(0.0, -1.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);
                    
                    return SlideTransition(
                      position: offsetAnimation,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            },
          ),
        ],
      ),

      drawer: const AppDrawer(),

      /// Use an IndexedStack so each tab keeps its state and we can let pages render full-screen.
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      /// Only show FAB when needed
      floatingActionButton: _showFab ? Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB892F7), Color(0xFFFAC4F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: null, // Disable hero animation completely
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: _onFabPressed,
          child: const Icon(Icons.add, size: 30, color: Colors.white),
        ),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      /// Floating, rounded bottom nav "plate" (the oval). The BottomNavigationBar itself
      /// is transparent so the plate looks clean with no white rectangle bleeding.
      bottomNavigationBar: _showBottomNav ? Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Theme(
            // Create a custom theme to adjust the text style and indicator
            data: Theme.of(context).copyWith(
              textTheme: Theme.of(context).textTheme.copyWith(
                bodySmall: const TextStyle(fontSize: 11), // Smaller font size for labels
              ),
              // Remove the splash color and highlight color to disable the gray circle
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedItemColor: const Color(0xFFB892F7), // Purple color for selected item
              unselectedItemColor: Colors.grey.shade600,
              showUnselectedLabels: true,
              elevation: 0,
              selectedLabelStyle: const TextStyle(fontSize: 11), // Smaller font for selected
              unselectedLabelStyle: const TextStyle(fontSize: 11), // Smaller font for unselected
              // Add custom selected icon theme for smaller indicator
              selectedIconTheme: IconThemeData(
                size: 26,
                color: const Color(0xFFB892F7),
                shadows: [
                  Shadow(
                    color: const Color(0xFFB892F7).withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              unselectedIconTheme: IconThemeData(
                size: 24,
                color: Colors.grey.shade600,
              ),
              items: _getBottomNavItems(),
            ),
          ),
        ),
      ) : null,
    );
  }
}