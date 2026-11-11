import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../../config/app_constants.dart';
import '../../../config/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../providers/version_provider.dart';
import 'branding_card.dart';
import 'officials_card.dart';
import 'faq_manager_card.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name);
    _emailController = TextEditingController(text: user?.email);
    _phoneController = TextEditingController(text: user?.contactNumber ?? '+63 912 345 6789');
    _addressController = TextEditingController(text: user?.address ?? 'Purok 4, Brgy. Central');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Palitan ang Profile Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.primary),
                ),
                title: const Text('Kumuha gamit ang Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.photo_library, color: Theme.of(context).colorScheme.primary),
                ),
                title: const Text('Pumili mula sa Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await _picker.pickImage(source: source, maxWidth: 600, maxHeight: 600, imageQuality: 80);
      if (image != null) {
        setState(() {
          _pickedImage = image;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final messenger = ScaffoldMessenger.of(context);

      try {
        String? avatarBase64;
        if (_pickedImage != null) {
          final bytes = await _pickedImage!.readAsBytes();
          avatarBase64 = base64Encode(bytes);
        }

        await context.read<AuthProvider>().updateProfile(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          contact: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          avatarBase64: avatarBase64,
        );
        
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Matagumpay na na-update ang profile!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Hindi na-update: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final narrow = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.all(narrow ? 12.0 : 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: Theme.of(context).textTheme.headlineLarge),
            const Text('Manage your account, theme, and app preferences.', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 32),
            
            // Barangay branding (admins only)
            if (context.watch<AuthProvider>().user?.role == 'Admin') ...[
              _buildSectionHeader('Barangay Profile & Branding'),
              const BrandingCard(),
              const SizedBox(height: 32),
              _buildSectionHeader('Barangay Officials'),
              const OfficialsCard(),
              const SizedBox(height: 32),
              _buildSectionHeader('FAQs'),
              const FaqManagerCard(),
              const SizedBox(height: 32),
            ],

            // Appearance Section
            _buildSectionHeader('Appearance & Themes'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Theme Combination', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildThemeComboButton(
                          context,
                          themeProvider,
                          ThemeCombo.barangayRosario,
                          'Barangay Rosario',
                          AppTheme.logoRed,
                        ),
                        _buildThemeComboButton(
                          context,
                          themeProvider,
                          ThemeCombo.dustyRoseWind,
                          'Dusty Rose / Wind',
                          Colors.pink[100]!,
                        ),
                        _buildThemeComboButton(
                          context,
                          themeProvider,
                          ThemeCombo.caramelWheat,
                          'Caramel / Wheat',
                          Colors.orange[200]!,
                        ),
                        _buildThemeComboButton(
                          context,
                          themeProvider,
                          ThemeCombo.blackishCaramel,
                          'Blackish / Caramel',
                          const Color(0xFF020617),
                          isDark: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Profile Section
            _buildSectionHeader('Account & Profile'),
            Card(
              child: Padding(
                padding: EdgeInsets.all(narrow ? 16.0 : 32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Builder(
                        builder: (context) {
                          final user = context.watch<AuthProvider>().user;
                          final avatarUrl = user?.avatarUrl;

                          ImageProvider? imageProvider;
                          if (_pickedImage != null) {
                            imageProvider = FileImage(File(_pickedImage!.path));
                          } else if (avatarUrl != null && avatarUrl.isNotEmpty) {
                            imageProvider = NetworkImage(
                              avatarUrl.startsWith('http') ? avatarUrl : '${AppConstants.baseUrl}/$avatarUrl',
                            );
                          }

                          return Row(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 46,
                                      backgroundColor: context.brand,
                                      backgroundImage: imageProvider,
                                      child: imageProvider == null
                                          ? Text(
                                              (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'U',
                                              style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4),
                                          ],
                                        ),
                                        child: Icon(Icons.camera_alt, size: 18, color: context.brand),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: narrow ? 16 : 32),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Profile Picture', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    const Text('PNG o JPG. Max 5MB.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                    const SizedBox(height: 10),
                                    OutlinedButton.icon(
                                      onPressed: _pickImage,
                                      icon: const Icon(Icons.upload, size: 16),
                                      label: const Text('Upload New Image'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                      _pair(
                        narrow,
                        _buildTextField('Full Name', _nameController, Icons.person_outline, (v) => Validators.validateRequired(v, 'Name')),
                        _buildTextField('Email Address', _emailController, Icons.email_outlined, Validators.validateEmail),
                      ),
                      const SizedBox(height: 24),
                      _pair(
                        narrow,
                        _buildTextField('Contact Number', _phoneController, Icons.phone_outlined, (v) => Validators.validateRequired(v, 'Phone')),
                        _buildTextField('Home Address / Barangay Info', _addressController, Icons.location_on_outlined, (v) => Validators.validateRequired(v, 'Address')),
                      ),
                      const SizedBox(height: 40),
                      const Divider(),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(onPressed: () {}, child: const Text('Cancel')),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            child: _isSaving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            _buildSectionHeader('App Version & Updates'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.system_update_alt, color: theme.colorScheme.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BaraTrack Mobile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(
                            'Version ${AppConstants.appVersion} (Build ${AppConstants.buildNumber})',
                            style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color),
                          ),
                        ],
                      ),
                    ),
                    Consumer<VersionProvider>(
                      builder: (context, vProvider, _) {
                        return ElevatedButton.icon(
                          onPressed: vProvider.isChecking
                              ? null
                              : () => vProvider.checkForUpdates(context: context, manual: true),
                          icon: vProvider.isChecking
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.refresh, size: 16),
                          label: Text(vProvider.isChecking ? 'Checking...' : 'Check Update'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 48),
            Center(
              child: TextButton.icon(
                onPressed: () => context.read<AuthProvider>().logout(),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Sign Out of BaraTrack System', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Two fields side by side on wide screens, stacked on phones.
  Widget _pair(bool narrow, Widget a, Widget b) {
    if (narrow) return Column(children: [a, const SizedBox(height: 20), b]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: a), const SizedBox(width: 24), Expanded(child: b)],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
      ),
    );
  }

  Widget _buildThemeComboButton(BuildContext context, ThemeProvider provider, ThemeCombo combo, String label, Color color, {bool isDark = false}) {
    final isSelected = provider.themeCombo == combo;
    return InkWell(
      onTap: () => provider.setThemeCombo(combo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, String? Function(String?)? validator) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(prefixIcon: Icon(icon, size: 20)),
          validator: validator,
        ),
      ],
    );
  }
}
