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

  // Notification settings
  bool _notificationsEnabled = true;
  bool _reminderNotifications = true;
  bool _veterinaryReminders = true;
  bool _appointmentReminders = true;

  @override
  void initState() {
    super.initState();
    // It's safe to use context in initState for Provider.of when listen: false
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

      // Check mounted before using context to access provider
      if (!mounted) return;
      final appState = Provider.of<AppState>(context, listen: false);

      // Get the path and directly set it in AppState
      final imagePath = picked.path;

      // Set the profile image
      await appState.setProfileImage(imagePath);

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
          provider = FileImage(File(path.replaceFirst('file://', '')));
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
          // FIX: Replaced withOpacity with withAlpha
          backgroundColor: Colors.white.withAlpha((0.24 * 255).round()),
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
                  // FIX: Replaced withOpacity with withAlpha
                  color: Colors.white.withAlpha((0.12 * 255).round()),
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
                  // FIX: Replaced withOpacity with withAlpha
                  color: Colors.white.withAlpha((0.08 * 255).round()),
                  borderRadius: BorderRadius.circular(16),
                  // FIX: Replaced withOpacity with withAlpha
                  border: Border.all(color: Colors.white.withAlpha((0.08 * 255).round())),
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
    // Check mounted before accessing provider
    if (!mounted) return;
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
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB892F7), Color(0xFFFAC4F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
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
                                  // FIX: Replaced withOpacity with withAlpha
                                  color: Colors.white.withAlpha((0.2 * 255).round()),
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
                              // FIX: Replaced withOpacity with withAlpha
                              color: Colors.white.withAlpha((0.9 * 255).round()),
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
                                      // Context check inside Dialog, before async gap
                                      if (!dialogContext.mounted) return;
                                      
                                      if (currentPasswordController.text.isEmpty ||
                                          newPasswordController.text.isEmpty ||
                                          confirmPasswordController.text.isEmpty) {
                                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                                          const SnackBar(content: Text('Please fill all password fields')));
                                        return;
                                      }
                                      if (newPasswordController.text != confirmPasswordController.text) {
                                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                                          const SnackBar(content: Text('New passwords do not match')));
                                        return;
                                      }
                                      
                                      setDialogState(() => changingPassword = true);

                                      // Check mounted before accessing provider/context
                                      if (!context.mounted) return; 
                                      final appState = Provider.of<AppState>(context, listen: false);
                                      final email = appState.currentUser?['email'] as String?;

                                      if (email == null) {
                                        if (!dialogContext.mounted) return;
                                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                                          const SnackBar(content: Text('User information not available')));
                                        setDialogState(() => changingPassword = false);
                                        return;
                                      }
                                      
                                      try {
                                        final dbService = appState.db;
                                        final user = await dbService.getUserByEmail(email);
                                        
                                        // Context check before showing error SnackBar
                                        if (!dialogContext.mounted) return;
                                        
                                        if (user == null ||
                                            !dbService.verifyPassword(currentPasswordController.text, user['password'])) {
                                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                                            const SnackBar(content: Text('Current password is incorrect')));
                                          setDialogState(() => changingPassword = false);
                                          return;
                                        }

                                        await dbService.updateUserPassword(user['id'], newPasswordController.text);
                                        
                                        // Context check before pop and success SnackBar
                                        if (!dialogContext.mounted) return;
                                        Navigator.pop(dialogContext);

                                        // Ensure main context is still mounted after dialog pop
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Password changed successfully')));
                                          
                                      } catch (e) {
                                        if (!dialogContext.mounted) return;
                                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                                          SnackBar(content: Text('Failed to change password: $e')));
                                      } finally {
                                        if (dialogContext.mounted) {
                                          setDialogState(() => changingPassword = false);
                                        }
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
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.red, Colors.redAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
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
                                  // FIX: Replaced withOpacity with withAlpha
                                  color: Colors.white.withAlpha((0.2 * 255).round()),
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
                          const SizedBox(height:8),
                          Text(
                            'This action cannot be undone',
                            style: TextStyle(
                              // FIX: Replaced withOpacity with withAlpha
                              color: Colors.white.withAlpha((0.9 * 255).round()),
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
                                      // Context check inside Dialog, before async gap
                                      if (!dialogContext.mounted) return;

                                      if (passwordController.text.isEmpty) {
                                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                                          const SnackBar(content: Text('Please enter your password')));
                                        return;
                                      }
                                      setDialogState(() => deletingAccount = true);

                                      // Check mounted before accessing provider/context
                                      if (!context.mounted) return;
                                      final appState = Provider.of<AppState>(context, listen: false);
                                      final email = appState.currentUser?['email'] as String?;
                                      
                                      if (email == null) {
                                        if (!dialogContext.mounted) return;
                                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                                          const SnackBar(content: Text('User information not available')));
                                        setDialogState(() => deletingAccount = false);
                                        return;
                                      }
                                      
                                      try {
                                        final dbService = appState.db;
                                        final user = await dbService.getUserByEmail(email);

                                        // Context check before showing error SnackBar
                                        if (!dialogContext.mounted) return;
                                        
                                        if (user == null ||
                                            !dbService.verifyPassword(passwordController.text, user['password'])) {
                                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                                            const SnackBar(content: Text('Password is incorrect')));
                                          setDialogState(() => deletingAccount = false);
                                          return;
                                        }

                                        for (final pet in appState.pets) {
                                          await dbService.deletePet(pet.id!);
                                        }
                                        await dbService.deleteUser(user['id']);
                                        await appState.logout();
                                        
                                        // Context check before pop, navigation, and success SnackBar
                                        if (!dialogContext.mounted) return;
                                        
                                        // Note: Navigating after deleting the account will usually go to a login/home page
                                        // The original code uses context here.
                                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                                        
                                        // Ensure main context is still mounted (though usually redundant after nav)
                                        if (!mounted) return; 
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Account deleted successfully')));
                                          
                                      } catch (e) {
                                        if (!dialogContext.mounted) return;
                                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                                          SnackBar(content: Text('Failed to delete account: $e')));
                                      } finally {
                                        if (dialogContext.mounted) {
                                          setDialogState(() => deletingAccount = false);
                                        }
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
                        // FIX: Replaced withOpacity with withAlpha
                        color: Colors.white.withAlpha((0.04 * 255).round()),
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
                                  const SizedBox(width:8),
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
                        // FIX: Replaced withOpacity with withAlpha
                        color: Colors.white.withAlpha((0.04 * 255).round()),
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
                      // Security Section
                      const Text('SECURITY', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Card(
                        // FIX: Replaced withOpacity with withAlpha
                        color: Colors.white.withAlpha((0.04 * 255).round()),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.lock_outline, color: Colors.white70),
                              title: const Text('Change password', style: TextStyle(color: Colors.white)),
                              subtitle: const Text('Update your account password', style: TextStyle(color: Colors.white60)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                              onTap: _showChangePasswordDialog,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // About Section
                      const Text('ABOUT', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Card(
                        // FIX: Replaced withOpacity with withAlpha
                        color: Colors.white.withAlpha((0.04 * 255).round()),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.info_outline, color: Colors.white70),
                              title: const Text('App Version', style: TextStyle(color: Colors.white)),
                              subtitle: const Text('1.0.0', style: TextStyle(color: Colors.white60)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Account Actions Section
                      const Text('ACCOUNT', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Card(
                        // FIX: Replaced withOpacity with withAlpha
                        color: Colors.white.withAlpha((0.04 * 255).round()),
                        child: Column(
                          children: [
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