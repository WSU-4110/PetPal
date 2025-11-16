// lib/ui/app_drawer.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../ui/calendar_screen.dart';
import '../ui/settings_screen.dart';
import '../ui/help_screen.dart';
import '../ui/weekly_report.dart';
import 'login_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gradient banner with profile info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB892F7), Color(0xFFFAC4F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Consumer<AppState>(
                builder: (context, appState, _) {
                  final user = appState.currentUser;
                  ImageProvider? avatarImage;

                  if (appState.profileImagePath?.isNotEmpty ?? false) {
                    final path = appState.profileImagePath!;
                    if (path.startsWith('http')) {
                      avatarImage = NetworkImage(path);
                    } else {
                      avatarImage = FileImage(File(path));
                    }
                  } else if (user != null && (user['avatar'] ?? '').toString().isNotEmpty) {
                    final path = user['avatar'].toString();
                    avatarImage = path.startsWith('http')
                        ? NetworkImage(path)
                        : AssetImage(path) as ImageProvider;
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white24,
                          backgroundImage: avatarImage,
                          child: avatarImage == null
                              ? const Icon(Icons.person, size: 40, color: Colors.white70)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user != null
                                      ? "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}".trim().isEmpty
                                          ? "Your Name"
                                          : "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}"
                                      : "Your Name",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (user != null && (user['preference'] ?? "").toString().isNotEmpty)
                              Text(
                                user['preference'],
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 2),
                            Text(
                              user != null ? (user['email'] ?? "youremail@example.com") : "youremail@example.com",
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 10),

          // -----------------------
          // SEARCH BUTTON REMOVED
          // -----------------------

          _DrawerItem(
            icon: Icons.calendar_today,
            title: 'Calendar',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalendarScreen()),
              );
            },
          ),

          _DrawerItem(
            icon: Icons.notifications,
            title: "Weekly Report",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WeeklyReportScreen()),
              );
            },
          ),

          _DrawerItem(
            icon: Icons.help_outline,
            title: "Help",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpScreen()),
              );
            },
          ),

          _DrawerItem(
            icon: Icons.settings,
            title: "Settings",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),

          const Spacer(flex: 2),
          const Divider(height: 1),

          _DrawerItem(
            icon: Icons.logout,
            title: "Log Out",
            onTap: () async {
              try {
                final asDyn = Provider.of<AppState>(context, listen: false) as dynamic;
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
            isLogout: true,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLogout;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  State<_DrawerItem> createState() => _DrawerItemState();
}

class _DrawerItemState extends State<_DrawerItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: widget.isLogout ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: _colorAnimation.value,
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.isLogout
                        ? Colors.red.withOpacity(0.1)
                        : Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.isLogout
                        ? Colors.red
                        : Theme.of(context).primaryColor,
                  ),
                ),
                title: Text(
                  widget.title,
                  style: TextStyle(
                    color: widget.isLogout ? Colors.red : null,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
