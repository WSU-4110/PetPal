// lib/ui/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../ui/calendar_screen.dart';
import '../ui/search_screen.dart';
import '../ui/settings_screen.dart';
import '../ui/help_screen.dart';
import 'login_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    // Attempt to read user safely
    final dynamic maybeUser =
        (appState as dynamic).currentUser ?? (appState as dynamic).user;
    final Map<String, dynamic>? user =
        (maybeUser is Map) ? Map<String, dynamic>.from(maybeUser) : null;
    final ValueNotifier<bool> logoutPressedNotifier = ValueNotifier(false);

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gradient banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB892F7), Color(0xFFFAC4F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    backgroundImage: user != null &&
                            (user['avatar'] ?? '').toString().isNotEmpty
                        ? (user['avatar'].toString().startsWith('http')
                            ? NetworkImage(user['avatar'])
                            : AssetImage(user['avatar']) as ImageProvider)
                        : null,
                    child: user == null ||
                            (user['avatar'] ?? '').toString().isEmpty
                        ? const Icon(Icons.person,
                            size: 40, color: Colors.white70)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user != null
                              ? "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}"
                                      .trim()
                                      .isEmpty
                                  ? "Your Name"
                                  : "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}"
                              : "Your Name",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user != null &&
                            (user['preference'] ?? "").toString().isNotEmpty)
                          Text(
                            user['preference'],
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 2),
                        Text(
                          user != null
                              ? (user['email'] ?? "youremail@example.com")
                              : "youremail@example.com",
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.search),
            title: const Text("Search & Filter"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()));
            },
          ),

          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Calendar'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CalendarScreen()));
            },
          ),

          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text("Notifications"),
            onTap: () => Navigator.pop(context),
          ),

          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text("Help"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HelpScreen()));
            },
          ),

          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),

          const Spacer(flex: 2),
          const Divider(height: 1),

          ValueListenableBuilder<bool>(
            valueListenable: logoutPressedNotifier,
            builder: (context, pressed, _) {
              return GestureDetector(
                onTapDown: (_) => logoutPressedNotifier.value = true,
                onTapUp: (_) => logoutPressedNotifier.value = false,
                onTapCancel: () => logoutPressedNotifier.value = false,
                onTap: () async {
                  // call AppState.logout if exists
                  try {
                    final asDyn =
                        Provider.of<AppState>(context, listen: false) as dynamic;
                    if (asDyn.logout is Function) {
                      await asDyn.logout();
                    }
                  } catch (_) {}
                  if (context.mounted) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()));
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  color: pressed ? Colors.grey.shade300 : Colors.transparent,
                  child: const ListTile(
                    leading: Icon(Icons.logout),
                    title: Text("Log Out"),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}