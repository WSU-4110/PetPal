import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main_nav.dart';
import '../state/app_state.dart';
import 'dart:math'; // For random pet picture

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _customCaptionController = TextEditingController();

  final List<String> _preferences = [
    "Cat lover",
    "Dog lover",
    "Crazy about paws",
    "Tail chaser",
    "Fur enthusiast",
    "Snack sharer",
    "Cuddle master",
    "Pet whisperer",
    "Custom",
  ];

  final List<String> _petImages = [
    "assets/images/daisy.png",
    "assets/images/black_cat.png",
    "assets/images/dog1.png",
    "assets/images/dog2.png",
    "assets/images/cat1.png",
    "assets/images/cat2.png",
    "assets/images/cat3.png",
    "assets/images/dog3.png",
    "assets/images/cat4.png",
    "assets/images/dog4.png",
    "assets/images/cat5.png",
    "assets/images/cat6.png",
    "assets/images/cat7.png",
    "assets/images/cat8.png",
    "assets/images/cat9.png",
    "assets/images/cat10.png",
    "assets/images/dog5.png",
    "assets/images/dog6.png",
    "assets/images/dog7.png",
    "assets/images/dog8.png",
    "assets/images/dog9.png",
    "assets/images/dog10.png",
  ];

  bool _isPasswordVisible = false;
  bool _isRegisterMode = false;
  String? _selectedPreference;
  String _selectedRole = "owner";

  final ValueNotifier<List<bool>> _passwordChecksNotifier =
      ValueNotifier(List.filled(5, false));
  final ValueNotifier<bool> _buttonPressedNotifier = ValueNotifier(false);

  String? loginErrorEmail;
  String? loginErrorPassword;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _customCaptionController.dispose();
    _passwordChecksNotifier.dispose();
    _buttonPressedNotifier.dispose();
    super.dispose();
  }

  void _resetErrorsAndFields() {
    _formKey.currentState?.reset();
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _customCaptionController.clear();
    _selectedPreference = null;
    _passwordChecksNotifier.value = List.filled(5, false);
    loginErrorEmail = null;
    loginErrorPassword = null;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final randomImage = _petImages[Random().nextInt(_petImages.length)];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromRGBO(184, 146, 247, 1),
              Color.fromRGBO(250, 196, 241, 1)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset("assets/images/petlogo.png", height: 120, width: 120),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.6),
                          blurRadius: 20,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        randomImage,
                        height: 200,
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Register fields
                  if (_isRegisterMode)
                    _roundedTextField(controller: _firstNameController, label: "First Name", icon: Icons.person),
                  if (_isRegisterMode) const SizedBox(height: 16),
                  if (_isRegisterMode)
                    _roundedTextField(controller: _lastNameController, label: "Last Name", icon: Icons.person_outline),
                  if (_isRegisterMode) const SizedBox(height: 16),

                  if (_isRegisterMode)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedPreference,
                        decoration: _dropdownDecoration(label: "Tail Tag", icon: Icons.pets),
                        dropdownColor: Colors.purple[100],
                        items: _preferences.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPreference = value;
                            if (value != "Custom") _customCaptionController.clear();
                          });
                        },
                        validator: (value) => value == null || value.isEmpty ? "Select a preference" : null,
                      ),
                    ),
                  if (_isRegisterMode && _selectedPreference == "Custom")
                    const SizedBox(height: 12),
                  if (_isRegisterMode && _selectedPreference == "Custom")
                    _roundedTextField(controller: _customCaptionController, label: "Enter your own caption", icon: Icons.edit, maxLength: 50),
                  if (_isRegisterMode) const SizedBox(height: 16),

                  // Role selection
                  if (_isRegisterMode)
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: _dropdownDecoration(label: "Role", icon: Icons.badge),
                      dropdownColor: Colors.purple[100],
                      items: const [
                        DropdownMenuItem(value: "owner", child: Text("Pet Owner")),
                        DropdownMenuItem(value: "vet", child: Text("Veterinarian")),
                        DropdownMenuItem(value: "trainer", child: Text("Trainer")),
                        DropdownMenuItem(value: "groomer", child: Text("Groomer")),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedRole = value);
                      },
                      validator: (value) => value == null || value.isEmpty ? "Select a role" : null,
                    ),
                  if (_isRegisterMode) const SizedBox(height: 16),

                  // Email
                  _roundedTextField(controller: _emailController, label: "Email", icon: Icons.email),
                  if (loginErrorEmail != null)
                    Text(loginErrorEmail!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),

                  // Password
                  _roundedTextField(
                    controller: _passwordController,
                    label: "Password",
                    icon: Icons.lock,
                    obscureText: !_isPasswordVisible,
                    suffix: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.purple[900]),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    onChanged: (value) {
                      if (_isRegisterMode) _passwordChecksNotifier.value = appState.passwordChecks(value);
                    },
                  ),
                  if (loginErrorPassword != null)
                    Text(loginErrorPassword!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),

                  // Password strength indicator
                  if (_isRegisterMode)
                    ValueListenableBuilder<List<bool>>(
                      valueListenable: _passwordChecksNotifier,
                      builder: (context, checks, _) {
                        if (_passwordController.text.isEmpty) return const SizedBox();
                        double progressValue = checks.where((c) => c).length / checks.length;
                        Color progressColor;
                        if (checks.where((c) => c).length <= 2) progressColor = Colors.redAccent;
                        else if (checks.where((c) => c).length <= 4) progressColor = Colors.orangeAccent;
                        else progressColor = Colors.greenAccent;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LinearProgressIndicator(value: progressValue, color: progressColor, backgroundColor: Colors.white30, minHeight: 5),
                            const SizedBox(height: 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(checks.length, (i) {
                                final labels = [
                                  "• At least 8 characters",
                                  "• Contains uppercase letter",
                                  "• Contains lowercase letter",
                                  "• Contains a digit",
                                  "• Contains a symbol (!@#\$%^&*)",
                                ];
                                return AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(color: checks[i] ? Colors.greenAccent : Colors.redAccent, fontSize: 12),
                                  child: Text(labels[i]),
                                );
                              }),
                            ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 24),

                  // Login/Register button
                  ValueListenableBuilder<bool>(
                    valueListenable: _buttonPressedNotifier,
                    builder: (context, pressed, _) {
                      return GestureDetector(
                        onTapDown: (_) => _buttonPressedNotifier.value = true,
                        onTapUp: (_) => _buttonPressedNotifier.value = false,
                        onTapCancel: () => _buttonPressedNotifier.value = false,
                        onTap: () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() { loginErrorEmail = null; loginErrorPassword = null; });
                            try {
                              final navigator = Navigator.of(context);
                              Map<String, dynamic>? user;

                              if (_isRegisterMode) {
                                await appState.register(
                                  _firstNameController.text.trim(),
                                  _lastNameController.text.trim(),
                                  _emailController.text.trim(),
                                  _passwordController.text.trim(),
                                  _selectedPreference == "Custom"
                                      ? _customCaptionController.text.trim()
                                      : _selectedPreference ?? "Pet lover",
                                  _selectedRole,
                                );
                                user = await appState.login(
                                  _emailController.text.trim(),
                                  _passwordController.text.trim(),
                                );
                              } else {
                                user = await appState.login(
                                  _emailController.text.trim(),
                                  _passwordController.text.trim(),
                                );
                              }

                              if (!mounted) return;
                              navigator.pushReplacement(
                                MaterialPageRoute(builder: (_) => MainNavigation(role: user!['role'])),
                              );
                            } catch (e) {
                              final err = e.toString().toLowerCase();
                              setState(() {
                                if (err.contains("invalid email")) loginErrorEmail = "Please enter a valid email";
                                if (err.contains("invalid password")) loginErrorPassword = "Incorrect password";
                              });
                            }
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeInOut,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color.fromRGBO(184, 146, 247, 1), Color.fromRGBO(250, 196, 241, 1)],
                            ),
                            boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_isRegisterMode ? "Register" : "Login", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: RichText(
                      text: TextSpan(
                        text: _isRegisterMode ? "Already have an account? " : "Don't have an account? ",
                        style: const TextStyle(color: Colors.purpleAccent),
                        children: [
                          TextSpan(
                            text: _isRegisterMode ? "Login" : "Register",
                            style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                            recognizer: TapGestureRecognizer()..onTap = () {
                              setState(() { _isRegisterMode = !_isRegisterMode; _resetErrorsAndFields(); });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color.fromRGBO(255, 255, 255, 0.15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      labelStyle: const TextStyle(color: Colors.white),
    );
  }

  Widget _roundedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    Widget? suffix,
    bool obscureText = false,
    int maxLength = 100,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.3), blurRadius: 8, spreadRadius: 1, offset: const Offset(0, 2))],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        maxLength: maxLength,
        onChanged: onChanged,
        validator: (value) => value == null || value.isEmpty ? "Enter $label" : null,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.white),
          suffixIcon: suffix,
          filled: true,
          fillColor: const Color.fromRGBO(255, 255, 255, 0.15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
          counterText: '',
        ),
      ),
    );
  }
}
