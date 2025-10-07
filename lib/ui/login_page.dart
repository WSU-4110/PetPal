import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
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
  ];

  bool _isPasswordVisible = false;
  bool _isRegisterMode = false;
  bool _isEmailTaken = false;
  String? _selectedPreference;

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
    // Reset all form fields, password checks, and errors
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
    _isEmailTaken = false;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final random = Random();
    final randomImage = _petImages[random.nextInt(_petImages.length)];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
                // Pet Logo
            Image.asset(
              "assets/images/petlogo.png", //logo
              height: 200,
              width: 200,
            ),

              const SizedBox(height: 20),

              // Pet Picture
              ClipOval(
                child: Image.asset(
                  randomImage, // Randomly selected image
                  fit: BoxFit.cover,
                  height: 300,
                  width: 300,
                ),
              ),
              const SizedBox(height: 30),

              // Login Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Registration Fields ---
                    if (_isRegisterMode)
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: "First Name",
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Enter your first name" : null,
                      ),
                    if (_isRegisterMode) const SizedBox(height: 16),

                    if (_isRegisterMode)
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: "Last Name",
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Enter your last name" : null,
                      ),
                    if (_isRegisterMode) const SizedBox(height: 16),

                    if (_isRegisterMode)
                      DropdownButtonFormField<String>(
                        value: _selectedPreference,
                        decoration: const InputDecoration(
                          labelText: "Tail Tag",
                          prefixIcon: Icon(Icons.pets),
                        ),
                        items: _preferences
                            .map((p) =>
                                DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPreference = value;
                            if (value != "Custom") {
                              _customCaptionController.clear();
                            }
                          });
                        },
                        validator: (value) => value == null || value.isEmpty
                            ? "Select a preference"
                            : null,
                      ),

                    if (_isRegisterMode && _selectedPreference == "Custom")
                      const SizedBox(height: 12),
                    if (_isRegisterMode && _selectedPreference == "Custom")
                      TextFormField(
                        controller: _customCaptionController,
                        decoration: const InputDecoration(
                          labelText: "Enter your own caption",
                          prefixIcon: Icon(Icons.edit),
                        ),
                        maxLength: 50,
                      ),

                    if (_isRegisterMode) const SizedBox(height: 16),

                    // --- Email Field ---
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Enter your email" : null,
                    ),
                    if (loginErrorEmail != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                          child: Text(
                            loginErrorEmail!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ),
                    if (_isRegisterMode && _isEmailTaken)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: const Padding(
                          padding: EdgeInsets.only(top: 4.0, left: 8.0),
                          child: Text(
                            "This email is already registered",
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // --- Password Field ---
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      onChanged: (value) {
                        if (_isRegisterMode) {
                          _passwordChecksNotifier.value =
                              appState.passwordChecks(value);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Enter your password" : null,
                    ),
                    if (loginErrorPassword != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                          child: Text(
                            loginErrorPassword!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // --- Toggle Login / Register ---
                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: _isRegisterMode
                              ? "Already have an account? "
                              : "Don't have an account? ",
                          style: TextStyle(color: Colors.deepPurple[800]),
                          children: [
                            TextSpan(
                              text: _isRegisterMode ? "Login" : "Register",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  setState(() {
                                    _isRegisterMode = !_isRegisterMode;
                                    _resetErrorsAndFields();
                                  });
                                },
                            ),
                          ],
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
    );
  }
}