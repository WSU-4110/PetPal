import 'package:flutter/material.dart';

void main() {
  runApp(const PetPalApp());
}

class PetPalApp extends StatelessWidget {
  const PetPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetPal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

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
      appBar: AppBar(
        title: const Text('PetPal Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to PetPal',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Role:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _role,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _role = value;
                    });
                  },
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
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _login,
                child: const Text('Login'),
              ),
            ),
          ],
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
      return const [
        Center(child: Text('Unknown role')),
      ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(_title),
      ),
      drawer: const AppDrawer(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: widget.role == 'owner'
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
                color: Colors.teal,
              ),
              child: Text(
                'PetPal Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
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
