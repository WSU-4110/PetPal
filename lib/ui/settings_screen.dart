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
      await Provider.of<AppState>(context, listen: false).setProfileImage(picked.path);
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile image updated')));
      }
    } catch (e) {
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image pick failed: $e')));
      }
    }
  }

  Widget _profileAvatar(AppState appState) {
    final path = appState.profileImagePath;
    ImageProvider? provider;

    if (path == null || path.isEmpty) {
      // Placeholder icon
      provider = null;
    } else if (path.startsWith('http')) {
      provider = NetworkImage(path);
    } else if (path.startsWith('/')) {
      provider = FileImage(File(path));
    } else {
      provider = AssetImage(path);
    }

    return Stack(
      children: [
        CircleAvatar(
          radius: 46,
          backgroundColor: Colors.white24,
          backgroundImage: provider,
          child: provider == null
              ? const Icon(Icons.person, size: 46, color: Colors.white70)
              : null,
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
                  color: Colors.white.withValues(alpha: 0.12),
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
      backgroundColor: Colors.transparent,
      builder: (c) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text('Remove picture'),
              onTap: () {
                Navigator.pop(context);
                _removeProfileImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeProfileImage() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.setProfileImage(null);
    if (!mounted) return;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture removed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB892F7), Color(0xFFFAC4F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Profile row
                        Row(
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
                        const SizedBox(height: 16),

                        // Display name editing
                        Card(
                          color: Colors.white.withValues(alpha: 0.04),
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
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Display name saved')));
                                              }
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

                        const SizedBox(height: 12),

                        // Account actions
                        Card(
                          color: Colors.white.withValues(alpha: 0.04),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.lock_outline, color: Colors.white70),
                                title: const Text('Change password',
                                    style: TextStyle(color: Colors.white)),
                                subtitle: const Text('Opens password change flow',
                                    style: TextStyle(color: Colors.white60)),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Change password (TODO)')));
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.delete_outline, color: Colors.white70),
                                title: const Text('Delete account',
                                    style: TextStyle(color: Colors.white)),
                                subtitle: const Text('Permanently delete your account and data',
                                    style: TextStyle(color: Colors.white60)),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Delete account (TODO)')));
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Text('Support: support@PetPal.com', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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