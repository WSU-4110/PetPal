import 'package:flutter/material.dart';

void main() {
  runApp(const PetPalApp());
}

/// Some purplish theme colors
const Color kPrimaryPurple = Color(0xFF7C4DFF);
const Color kDarkPurple = Color(0xFF4A2C82);
const Color kLightLavender = Color(0xFFF5ECFF);
const Color kDeepPurple = Color(0xFF512DA8);

class PetPalApp extends StatelessWidget {
  const PetPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetPal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryPurple,
          primary: kPrimaryPurple,
          secondary: kDeepPurple,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: kLightLavender,
        appBarTheme: const AppBarTheme(
          backgroundColor: kPrimaryPurple,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      home: const StartPage(),
    );
  }
}

//
// -------------------- START / WELCOME PAGE --------------------
//

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kDarkPurple, kPrimaryPurple],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // top paw icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pets,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 32),
                // big title
                const Text(
                  'Find Your\nBest Pet!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Now you can keep track of all your pets\nand their care in one place.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                // rounded top card-ish shape like the reference
                Container(
                  width: double.infinity,
                  height: size.height * 0.30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ready to get started?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Create an account or log in to manage\nreminders, health, and more.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//
// -------------------- LOGIN PAGE --------------------
//

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _role = 'owner';

  void _login() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainNavigation(role: _role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightLavender,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: Column(
              children: [
                // Paw icon + title area
                const SizedBox(height: 8),
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: kPrimaryPurple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pets,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kDarkPurple,
                  ),
                ),
                const SizedBox(height: 24),
                // Card with fields (similar to the mockup)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Log in to your account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kDarkPurple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: kLightLavender.withOpacity(0.7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          filled: true,
                          fillColor: kLightLavender.withOpacity(0.7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(color: kDeepPurple),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Role picker
                      Row(
                        children: [
                          const Text(
                            'Role:',
                            style: TextStyle(color: kDarkPurple),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _role,
                            items: const [
                              DropdownMenuItem(
                                value: 'owner',
                                child: Text('Owner'),
                              ),
                              DropdownMenuItem(
                                value: 'vet',
                                child: Text('Vet'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _role = value);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _login,
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          '—  or continue with  —',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.g_mobiledata, size: 28),
                        label: const Text('Log in with Google'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.apple, size: 22),
                        label: const Text('Log in with Apple'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//
// -------------------- MAIN NAV + DRAWER + PAGES --------------------
//

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
      return const [
        HomeScreen(),
        PetsScreen(),
        RemindersScreen(),
        HealthScreen(),
      ];
    } else if (widget.role == 'vet') {
      return const [
        HomeScreen(),
        AppointmentsScreen(),
        HealthScreen(),
      ];
    } else {
      return const [Center(child: Text('Unknown role'))];
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  String get _title {
    if (widget.role == 'owner') {
      switch (_selectedIndex) {
        case 0:
          return 'Owner Home';
        case 1:
          return 'My Pets';
        case 2:
          return 'Reminders';
        case 3:
          return 'Health';
      }
    } else if (widget.role == 'vet') {
      switch (_selectedIndex) {
        case 0:
          return 'Vet Home';
        case 1:
          return 'Appointments';
        case 2:
          return 'Health';
      }
    }
    return 'PetPal';
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.role == 'owner';

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kPrimaryPurple,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: isOwner
            ? const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.pets), label: 'Pets'),
          BottomNavigationBarItem(
              icon: Icon(Icons.alarm), label: 'Reminders'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: 'Health'),
        ]
            : const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.alarm), label: 'Appointments'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: 'Health'),
        ],
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: kPrimaryPurple,
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'PetPal Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Simple placeholder screens for each tab.
// You can replace these with your real pages later.

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Home',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

class PetsScreen extends StatelessWidget {
  const PetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'My Pets',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Reminders',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Health',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Appointments',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
