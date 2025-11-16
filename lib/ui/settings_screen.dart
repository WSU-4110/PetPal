// lib/ui/settings_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ImagePicker _picker = ImagePicker();
  late TextEditingController _nameController;
  bool _saving = false;
  
  // New settings state
  bool _notificationsEnabled = true;
  bool _reminderNotifications = true;
  bool _veterinaryReminders = true;
  bool _appointmentReminders = true;
  bool _darkModeEnabled = false;
  bool _biometricEnabled = false;
  String _selectedLanguage = 'English';
  String _selectedDateFormat = 'MM/DD/YYYY';
  String _selectedWeightUnit = 'lbs';
  bool _autoBackup = true;
  bool _analyticsEnabled = true;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _nameController = TextEditingController(text: appState.displayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (picked == null) return;
      if (!mounted) return;
      
      // Get the path and verify it exists
      final imagePath = picked.path;
      final imageFile = File(imagePath);
      
      if (!await imageFile.exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image file not found'))
        );
        return;
      }
      
      // Set the profile image
      await Provider.of<AppState>(context, listen: false).setProfileImage(imagePath);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated'))
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e'))
      );
    }
  }

  Widget _profileAvatar(AppState appState) {
    final path = appState.profileImagePath;
    Widget avatarChild;

    if (path == null || path.isEmpty) {
      avatarChild = const Icon(Icons.person, size: 46, color: Colors.white70);
    } else {
      ImageProvider? provider;
      
      try {
        if (path.startsWith('http')) {
          provider = NetworkImage(path);
        } else if (path.startsWith('/') || path.startsWith('file://')) {
          final file = File(path.replaceFirst('file://', ''));
          if (file.existsSync()) {
            provider = FileImage(file);
          }
        } else {
          provider = AssetImage(path);
        }
      } catch (e) {
        debugPrint('Error loading profile image: $e');
        provider = null;
      }

      if (provider != null) {
        avatarChild = Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: provider,
              fit: BoxFit.cover,
            ),
          ),
        );
      } else {
        avatarChild = const Icon(Icons.person, size: 46, color: Colors.white70);
      }
    }

    return Stack(
      children: [
        CircleAvatar(
          radius: 46,
          backgroundColor: Colors.white.withOpacity(0.24),
          child: avatarChild,
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _showPickOptions,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.camera_alt, size: 18, color: Colors.white70),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPickOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) {
        return GestureDetector(
          onTap: () => Navigator.of(c).pop(),
          behavior: HitTestBehavior.opaque,
          child: DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.25,
            maxChildSize: 0.5,
            builder: (_, controller) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const Text(
                      'Choose Photo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        controller: controller,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              leading: const Icon(Icons.photo_library, color: Colors.white70),
                              title: const Text(
                                'Choose from gallery',
                                style: TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.gallery);
                              },
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              leading: const Icon(Icons.camera_alt, color: Colors.white70),
                              title: const Text(
                                'Take a photo',
                                style: TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.camera);
                              },
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              leading: const Icon(Icons.delete_forever, color: Colors.white70),
                              title: const Text(
                                'Remove picture',
                                style: TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _removeProfileImage();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _removeProfileImage() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.setProfileImage(null);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile picture removed'))
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool changingPassword = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFB892F7), Color(0xFFFAC4F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.lock_outline,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  'Change Password',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                icon: const Icon(Icons.close, color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Update your account password',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: currentPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Current password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: newPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'New password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: confirmPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Confirm new password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: changingPassword
                                  ? null
                                  : () async {
                                      if (currentPasswordController.text.isEmpty ||
                                          newPasswordController.text.isEmpty ||
                                          confirmPasswordController.text.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Please fill all password fields')));
                                        return;
                                      }

                                      if (newPasswordController.text != confirmPasswordController.text) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('New passwords do not match')));
                                        return;
                                      }

                                      setDialogState(() => changingPassword = true);

                                      final appState = Provider.of<AppState>(context, listen: false);
                                      final email = appState.currentUser?['email'] as String?;

                                      if (email == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('User information not available')));
                                        setDialogState(() => changingPassword = false);
                                        return;
                                      }

                                      try {
                                        final dbService = appState.db;
                                        final user = await dbService.getUserByEmail(email);

                                        if (user == null ||
                                            !dbService.verifyPassword(currentPasswordController.text, user['password'])) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Current password is incorrect')));
                                          setDialogState(() => changingPassword = false);
                                          return;
                                        }

                                        await dbService.updateUserPassword(user['id'], newPasswordController.text);

                                        Navigator.pop(dialogContext);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Password changed successfully')));
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to change password: $e')));
                                      } finally {
                                        setDialogState(() => changingPassword = false);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB892F7),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: changingPassword
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Change Password'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();
    bool deletingAccount = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red, Colors.redAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.warning_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  'Delete Account',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                icon: const Icon(Icons.close, color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This action cannot be undone',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'This will permanently delete your account and all associated data including pets, reminders, and medical records.',
                            style: TextStyle(color: Colors.black87),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Enter your password to confirm',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: deletingAccount
                                  ? null
                                  : () async {
                                      if (passwordController.text.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Please enter your password')));
                                        return;
                                      }

                                      setDialogState(() => deletingAccount = true);

                                      final appState = Provider.of<AppState>(context, listen: false);
                                      final email = appState.currentUser?['email'] as String?;

                                      if (email == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('User information not available')));
                                        setDialogState(() => deletingAccount = false);
                                        return;
                                      }

                                      try {
                                        final dbService = appState.db;
                                        final user = await dbService.getUserByEmail(email);

                                        if (user == null ||
                                            !dbService.verifyPassword(passwordController.text, user['password'])) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Password is incorrect')));
                                          setDialogState(() => deletingAccount = false);
                                          return;
                                        }

                                        for (final pet in appState.pets) {
                                          await dbService.deletePet(pet.id!);
                                        }

                                        await dbService.deleteUser(user['id']);
                                        await appState.logout();

                                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Account deleted successfully')));
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to delete account: $e')));
                                      } finally {
                                        setDialogState(() => deletingAccount = false);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: deletingAccount
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Delete Account'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLanguageDialog() {
    final languages = ['English', 'Spanish', 'French', 'German', 'Italian', 'Portuguese', 'Chinese', 'Japanese'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) => RadioListTile<String>(
            title: Text(lang),
            value: lang,
            groupValue: _selectedLanguage,
            onChanged: (value) {
              setState(() => _selectedLanguage = value!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Language changed to $value'))
              );
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showDateFormatDialog() {
    final formats = ['MM/DD/YYYY', 'DD/MM/YYYY', 'YYYY-MM-DD'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Date Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: formats.map((format) => RadioListTile<String>(
            title: Text(format),
            value: format,
            groupValue: _selectedDateFormat,
            onChanged: (value) {
              setState(() => _selectedDateFormat = value!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Date format changed to $value'))
              );
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showWeightUnitDialog() {
    final units = ['lbs', 'kg'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Weight Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: units.map((unit) => RadioListTile<String>(
            title: Text(unit),
            value: unit,
            groupValue: _selectedWeightUnit,
            onChanged: (value) {
              setState(() => _selectedWeightUnit = value!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Weight unit changed to $value'))
              );
            },
          )).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Add search functionality if needed
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB892F7), Color(0xFFFAC4F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _profileAvatar(appState),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(appState.displayName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(currentUserEmailForDisplay(appState),
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Section
                      const Text('PROFILE', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.white.withOpacity(0.04),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                    labelText: 'Display name',
                                    border: InputBorder.none,
                                    hintText: 'Your name'),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: _saving
                                        ? null
                                        : () async {
                                            setState(() => _saving = true);
                                            await appState.setDisplayName(_nameController.text);
                                            setState(() => _saving = false);
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Display name saved')));
                                          },
                                    child: _saving
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2))
                                        : const Text('Save'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () {
                                      _nameController.text = appState.displayName;
                                    },
                                    child: const Text('Reset'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Notifications Section
                      const Text('NOTIFICATIONS', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.white.withOpacity(0.04),
                        child: Column(
                          children: [
                            SwitchListTile(
                              secondary: const Icon(Icons.notifications_outlined, color: Colors.white70),
                              title: const Text('Push Notifications', style: TextStyle(color: Colors.white)),
                              subtitle: const Text('Receive push notifications', style: TextStyle(color: Colors.white60)),
                              value: _notificationsEnabled,
                              onChanged: (value) {
                                setState(() => _notificationsEnabled = value);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Push notifications ${value ? 'enabled' : 'disabled'}'))
                                );
                              },
                            ),
                            SwitchListTile(
                              secondary: const Icon(Icons.alarm, color: Colors.white70),
                              title: const Text('Reminder Notifications', style: TextStyle(color: Colors.white)),
                              subtitle: const Text('Get notified about pet care reminders', style: TextStyle(color: Colors.white60)),
                              value: _reminderNotifications,
                              onChanged: (value) {
                                setState(() => _reminderNotifications = value);
                              },
                            ),
                            SwitchListTile(
                              secondary: const Icon(Icons.local_hospital_outlined, color: Colors.white70),
                              title: const Text('Veterinary Reminders', style: TextStyle(color: Colors.white)),
                              subtitle: const Text('Reminders for vet appointments', style: TextStyle(color: Colors.white60)),
                              value: _veterinaryReminders,
                              onChanged: (value) {
                                setState(() => _veterinaryReminders = value);
                              },
                            ),
                            SwitchListTile(
                              secondary: const Icon(Icons.event, color: Colors.white70),
                              title: const Text('Appointment Reminders', style: TextStyle(color: Colors.white)),
                              subtitle: const Text('Get notified about upcoming appointments', style: TextStyle(color: Colors.white60)),
                              value: _appointmentReminders,
                              onChanged: (value) {
                                setState(() => _appointmentReminders = value);
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Appearance Section
                      const Text('APPEARANCE', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.white.withOpacity(0.04),
                        child: Column(
                          children: [
                            SwitchListTile(
                              secondary: const Icon(Icons.dark_mode_outlined, color: Colors.white70),
                              title: const Text('Dark Mode', style: TextStyle(color: Colors.white)),
                              subtitle: const Text('Use dark theme', style: TextStyle(color: Colors.white60)),
                              value: _darkModeEnabled,
                              onChanged: (value) {
                                setState(() => _darkModeEnabled = value);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Dark mode ${value ? 'enabled' : 'disabled'}'))
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.language, color: Colors.white70),
                              title: const Text('Language', style: TextStyle(color: Colors.white)),
                              subtitle: Text(_selectedLanguage, style: const TextStyle(color: Colors.white60)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                              onTap: _showLanguageDialog,
                            ),
                            ListTile(
                              leading: const Icon(Icons.calendar_today, color: Colors.white70),
                              title: const Text('Date Format', style: TextStyle(color: Colors.white)),
                              subtitle: Text(_selectedDateFormat, style: const TextStyle(color: Colors.white60)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                              onTap: _showDateFormatDialog,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Preferences Section
                      const Text('PREFERENCES', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.white.withOpacity(0.04),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.monitor_weight_outlined, color: Colors.white70),
                              title: const Text('Weight Unit', style: TextStyle(color: Colors.white)),
                              subtitle: Text(_selectedWeightUnit, style: const TextStyle(color: Colors.white60)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                              onTap: _showWeightUnitDialog,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Security Section
                      const Text('SECURITY', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.white.withOpacity(0.04),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.lock_outline, color: Colors.white70),
                              title: const Text('Change password', style: TextStyle(color: Colors.white)),
                              subtitle: const Text('Update your account password', style: TextStyle(color: Colors.white60)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                              onTap: _showChangePasswordDialog,
                            ),
                            SwitchListTile(
                              secondary: const Icon(Icons.fingerprint, color: Colors.white70),
                              title: const Text('Biometric Authentication', style: TextStyle(color: Colors.white)),
                              subtitle: const Text('Use fingerprint or face ID', style: TextStyle(color: Colors.white60)),
                              value: _biometricEnabled,
                              onChanged: (value) {
                                setState(() => _biometricEnabled = value);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Biometric authentication ${value ? 'enabled' : 'disabled'}'))
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Data & Privacy Section
                      const Text('DATA & PRIVACY', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.white.withOpacity(0.04),
                        child: Column(
                          children: [
                            SwitchListTile(
                              secondary: const Icon(Icons.backup_outlined, color: Colors.white70),
                              title: const Text('Auto Backup', style: TextStyle(color: Colors.white)),
                              subtitle: const Text('Automatically backup your data', style: TextStyle(color: Colors.white60)),
                              value: _autoBackup,
                              onChanged: (value) {
                                setState(() => _autoBackup = value);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Auto backup ${value ? 'enabled' : 'disabled'}'))
                                );
                              },
                            ),
                            SwitchListTile(
                              secondary: const Icon(Icons.analytics_outlined, color: Colors.white70),
                              title: const Text('Analytics', style: TextStyle(color: Colors.white)),
                              subtitle: const Text('Help improve the app with usage data', style: TextStyle(color: Colors.white60)),
                              value: _analyticsEnabled,
                              onChanged: (value) {
                                setState(() => _analyticsEnabled = value);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Analytics ${value ? 'enabled' : 'disabled'}'))
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.file_download_outlined, color: Colors.white70),
                              title: const Text('Export Data', style: TextStyle(color: Colors.white)),
                              subtitle: const Text('Download all your data', style: TextStyle(color: Colors.white60)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Exporting data...'))
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.privacy_tip_outlined, color: Colors.white70),
                              title: const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
                              subtitle: const Text('View our privacy policy', style: TextStyle(color: Colors.white60)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Opening privacy policy...'))
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.description_outlined, color: Colors.white70),
                              title: const Text('Terms of Service', style: TextStyle(color: Colors.white)),
                              subtitle: const Text('View terms of service', style: TextStyle(color: Colors.white60)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Opening terms of service...'))
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // About Section
                      const Text('ABOUT', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.white.withOpacity(0.04),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.info_outline, color: Colors.white70),
                              title: const Text('App Version', style: TextStyle(color: Colors.white)),
                              subtitle: const Text('1.0.0', style: TextStyle(color: Colors.white60)),
                            ),
                            ListTile(
                              leading: const Icon(Icons.help_outline, color: Colors.white70),
                              title: const Text('Help & Support', style: TextStyle(color: Colors.white)),
                              subtitle: const Text('Get help with the app', style: TextStyle(color: Colors.white60)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Opening help center...'))
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.rate_review_outlined, color: Colors.white70),
                              title: const Text('Rate App', style: TextStyle(color: Colors.white)),
                              subtitle: const Text('Rate us on the app store', style: TextStyle(color: Colors.white60)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Opening app store...'))
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.share_outlined, color: Colors.white70),
                              title: const Text('Share App', style: TextStyle(color: Colors.white)),
                              subtitle: const Text('Share with friends', style: TextStyle(color: Colors.white60)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Opening share options...'))
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Account Actions Section
                      const Text('ACCOUNT', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.white.withOpacity(0.04),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.logout, color: Colors.white70),
                              title: const Text('Logout', style: TextStyle(color: Colors.white)),
                              subtitle: const Text('Sign out of your account', style: TextStyle(color: Colors.white60)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                              onTap: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Logout'),
                                    content: const Text('Are you sure you want to logout?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Logout'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true && mounted) {
                                  await appState.logout();
                                  if (mounted) {
                                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                                  }
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete_outline, color: Colors.white70),
                              title: const Text('Delete account', style: TextStyle(color: Colors.white)),
                              subtitle: const Text('Permanently delete your account and data', style: TextStyle(color: Colors.white60)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                              onTap: _showDeleteAccountDialog,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Text('Support: support@PetPal.com', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String currentUserEmailForDisplay(AppState appState) {
    final user = appState.currentUser;
    if (user == null) return 'Not signed in';
    return (user['email'] ?? '').toString();
  }
}