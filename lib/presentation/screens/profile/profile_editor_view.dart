import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../../config/app_theme.dart';
import '../../../core/utils/validators.dart';

class ProfileEditorView extends StatefulWidget {
  const ProfileEditorView({super.key});

  @override
  State<ProfileEditorView> createState() => _ProfileEditorViewState();
}

class _ProfileEditorViewState extends State<ProfileEditorView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  DateTime? _selectedBirthDate;
  bool _isInitialLoad = true;
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name);
    _emailController = TextEditingController(text: user?.email);
    _phoneController = TextEditingController(text: user?.contactNumber);
    _addressController = TextEditingController(text: user?.address);
    _selectedBirthDate = user?.birthDate;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await context.read<AuthProvider>().refreshProfile();
        _updateControllers();
        setState(() => _isInitialLoad = false);
      }
    });
  }

  void _updateControllers() {
    final user = context.read<AuthProvider>().user;
    _nameController.text = user?.name ?? '';
    _emailController.text = user?.email ?? '';
    _phoneController.text = user?.contactNumber ?? '';
    _addressController.text = user?.address ?? '';
    setState(() {
      _selectedBirthDate = user?.birthDate;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
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
              const Text('Change Profile Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.primary),
                ),
                title: const Text('Take a photo with Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.photo_library, color: Theme.of(context).colorScheme.primary),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await _picker.pickImage(source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85);
      if (image != null) {
        setState(() {
          _pickedImage = image;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context, rootNavigator: true);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

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
          birthDate: _selectedBirthDate,
          avatarBase64: avatarBase64,
        );
        
        if (mounted) {
          navigator.pop(); // Close loader
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'), 
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          navigator.pop(); // Close loader
          messenger.showSnackBar(
            SnackBar(
              content: Text('Error: $e'), 
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final narrow = MediaQuery.of(context).size.width < 600;

    if (_isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(narrow ? 12.0 : 32.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Profile Editor', style: theme.textTheme.headlineLarge),
              const Text('Update your personal information to keep your records accurate.'),
              const SizedBox(height: 32),
              
              Card(
                child: Padding(
                  padding: EdgeInsets.all(narrow ? 16.0 : 32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildAvatarSection(theme),
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
                          Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Date of Birth', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => _selectDate(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: theme.dividerColor),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                                          const SizedBox(width: 12),
                                          Text(
                                            _selectedBirthDate != null 
                                                ? DateFormat('MMMM dd, yyyy').format(_selectedBirthDate!)
                                                : 'Select Birthday',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        ),
                        const SizedBox(height: 24),
                        _buildTextField('Home Address / Barangay Info', _addressController, Icons.location_on_outlined, (v) => Validators.validateRequired(v, 'Address')),
                        const SizedBox(height: 40),
                        const Divider(),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _saveChanges,
                              child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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

  Widget _buildAvatarSection(ThemeData theme) {
    final user = context.watch<AuthProvider>().user;
    ImageProvider? avatarImage;
    if (_pickedImage != null) {
      avatarImage = kIsWeb ? NetworkImage(_pickedImage!.path) : FileImage(File(_pickedImage!.path)) as ImageProvider;
    } else if (user?.profilePicture != null && user!.profilePicture!.isNotEmpty) {
      avatarImage = NetworkImage(user.profilePicture!);
    }

    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                backgroundImage: avatarImage,
                child: avatarImage == null
                    ? Text(
                        _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'U',
                        style: TextStyle(fontSize: 48, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              _pickedImage != null ? 'Tap to change selected photo' : 'Tap to upload profile photo',
              style: TextStyle(fontSize: 13, color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, String? Function(String?)? validator) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
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
