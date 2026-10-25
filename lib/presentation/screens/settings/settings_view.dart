import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../../config/app_theme.dart';
import '../../../core/utils/validators.dart';
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

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      await context.read<AuthProvider>().updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        contact: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.all(24.0),
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
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: context.brand,
                                child: Icon(Icons.person, size: 48, color: Colors.white),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: Icon(Icons.camera_alt, size: 20, color: context.brand),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 32),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Profile Picture', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text('PNG or JPG. Max 2MB.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                SizedBox(height: 8),
                                OutlinedButton(onPressed: null, child: Text('Upload New Image')),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField('Full Name', _nameController, Icons.person_outline, (v) => Validators.validateRequired(v, 'Name')),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildTextField('Email Address', _emailController, Icons.email_outlined, Validators.validateEmail),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField('Contact Number', _phoneController, Icons.phone_outlined, (v) => Validators.validateRequired(v, 'Phone')),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildTextField('Home Address / Barangay Info', _addressController, Icons.location_on_outlined, (v) => Validators.validateRequired(v, 'Address')),
                          ),
                        ],
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
                            onPressed: _saveProfile,
                            child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
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
