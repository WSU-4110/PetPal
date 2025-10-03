import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../state/app_state.dart';

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

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    _isRegisterMode ? "Create Account 🐾" : "Welcome to PetPal 🐾",
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple[800]),
                  ),
                ),
                const SizedBox(height: 30),

                // --- Registration Fields ---
                if (_isRegisterMode)
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                        labelText: "First Name", prefixIcon: Icon(Icons.person)),
                    validator: (value) =>
                        value!.isEmpty ? "Enter your first name" : null,
                  ),
                if (_isRegisterMode) const SizedBox(height: 16),

                if (_isRegisterMode)
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                        labelText: "Last Name", prefixIcon: Icon(Icons.person_outline)),
                    validator: (value) =>
                        value!.isEmpty ? "Enter your last name" : null,
                  ),
                if (_isRegisterMode) const SizedBox(height: 16),

                if (_isRegisterMode)
                  DropdownButtonFormField<String>(
                    value: _selectedPreference,
                    decoration: const InputDecoration(
                        labelText: "Tail Tag", prefixIcon: Icon(Icons.pets)),
                    items: _preferences
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPreference = value;
                        if (value != "Custom") _customCaptionController.clear();
                      });
                    },
                    validator: (value) =>
                        value == null || value.isEmpty ? "Select a preference" : null,
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
                      labelText: "Email", prefixIcon: Icon(Icons.email)),
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
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ),
                if (_isRegisterMode && _isEmailTaken)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Padding(
                      padding: EdgeInsets.only(top: 4.0, left: 8.0),
                      child: Text("This email is already registered",
                          style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ),
                const SizedBox(height: 16),

                // --- Password Field ---
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  onChanged: (value) {
                    if (_isRegisterMode) {
                      _passwordChecksNotifier.value = appState.passwordChecks(value);
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
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // --- Password Strength Checks ---
                if (_isRegisterMode)
                  ValueListenableBuilder<List<bool>>(
                    valueListenable: _passwordChecksNotifier,
                    builder: (context, checks, _) {
                      if (_passwordController.text.isEmpty) return const SizedBox();
                      double progressValue = checks.where((c) => c).length / checks.length;
                      Color progressColor;
                      if (checks.where((c) => c).length <= 2) {
                        progressColor = Colors.red;
                      } else if (checks.where((c) => c).length <= 4) {
                        progressColor = Colors.orange;
                      } else {
                        progressColor = Colors.green;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: progressValue,
                            color: progressColor,
                            backgroundColor: Colors.grey[300],
                            minHeight: 5,
                          ),
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
                                style: TextStyle(
                                  color: checks[i] ? Colors.green : Colors.red,
                                  fontSize: 12,
                                ),
                                child: Text(labels[i]),
                              );
                            }),
                          )
                        ],
                      );
                    },
                  ),

                const SizedBox(height: 25),

                // --- Login / Register Button ---
                ValueListenableBuilder<bool>(
                  valueListenable: _buttonPressedNotifier,
                  builder: (context, pressed, _) {
                    return GestureDetector(
                      onTapDown: (_) => _buttonPressedNotifier.value = true,
                      onTapUp: (_) => _buttonPressedNotifier.value = false,
                      onTapCancel: () => _buttonPressedNotifier.value = false,
                      onTap: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isEmailTaken = false;
                            loginErrorEmail = null;
                            loginErrorPassword = null;
                          });
                          try {
                            if (_isRegisterMode) {
                              await appState.register(
                                _firstNameController.text,
                                _lastNameController.text,
                                _emailController.text,
                                _passwordController.text,
                                _selectedPreference == "Custom"
                                    ? _customCaptionController.text
                                    : _selectedPreference ?? "Pet lover",
                              );

                              // Auto-login after register
                              await appState.login(
                                  _emailController.text, _passwordController.text);
                            } else {
                              await appState.login(
                                  _emailController.text, _passwordController.text);
                            }

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const MainNavigation()),
                            );
                          } catch (e) {
                            String err = e.toString().toLowerCase();
                            setState(() {
                              if (err.contains("invalid email")) {
                                loginErrorEmail = "Please enter a valid email";
                              }
                              if (err.contains("invalid password")) {
                                loginErrorPassword = "Incorrect password";
                              }
                              if (err.contains("email is already registered")) {
                                _isEmailTaken = true;
                              }
                            });
                          }
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeInOut,
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: pressed
                              ? Colors.deepPurple.shade700
                              : Colors.deepPurple,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          _isRegisterMode ? "Register" : "Login",
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    );
                  },
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
                              decoration: TextDecoration.underline),
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
        ),
      ),
    );
  }
}
