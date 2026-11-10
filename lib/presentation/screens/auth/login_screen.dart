import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import 'auth_shell.dart';
import 'pending_approval_screen.dart';
import 'social_login_buttons.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Registration Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _captchaAnswerController = TextEditingController();

  // Resident ID Verification
  final _idNumberController = TextEditingController();
  String _selectedIdType = 'Barangay Resident ID';
  XFile? _validIdFile;
  String? _validIdBase64;
  final ImagePicker _picker = ImagePicker();

  static const List<String> _idTypeList = [
    'Barangay Resident ID',
    'PhilSys / National ID',
    'Driver\'s License',
    'Voter\'s ID / Certification',
    'UMID / SSS / GSIS',
    'Student / School ID',
    'Postal ID',
    'Passport',
    'Other Valid Government ID',
  ];

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final String _selectedRole = 'Resident'; // Only residents can create an account online

  // Terms & Privacy
  bool _acceptedTerms = false;

  // Security Verification (CAPTCHA)
  String? _captchaId;
  String? _captchaQuestion;
  bool _isLoadingCaptcha = false;

  // Top Form Error Banner
  String? _topFormError;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchCaptcha());
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _scrollController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _mobileController.dispose();
    _captchaAnswerController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickIdPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _validIdFile = picked;
        _validIdBase64 = base64Encode(bytes);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _showIdPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Upload Valid ID / Barangay ID',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo with camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickIdPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickIdPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  Future<void> _fetchCaptcha() async {
    setState(() {
      _isLoadingCaptcha = true;
      _captchaAnswerController.clear();
    });
    try {
      final authProvider = context.read<AuthProvider>();
      final res = await authProvider.fetchCaptcha();
      if (mounted) {
        setState(() {
          _captchaId = res['captcha_id'];
          _captchaQuestion = res['question'];
          _isLoadingCaptcha = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCaptcha = false;
        });
      }
    }
  }

  void _showTermsDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(fontSize: 14, height: 1.4)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _topFormError = null);

    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    // Clean mobile number (strip spaces)
    final rawMobile = _mobileController.text.replaceAll(' ', '').trim();

    if (_captchaId == null || _captchaAnswerController.text.trim().isEmpty) {
      const err = 'Please answer the security verification question.';
      setState(() => _topFormError = err);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(err),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
        ),
      );
      return;
    }

    if (!_acceptedTerms) {
      const err = 'You must agree to the Terms of Service and Privacy Policy.';
      setState(() => _topFormError = err);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(err),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
        ),
      );
      return;
    }

    // Split the single "Full Name" box: first word = first name, the rest = last name.
    final nameParts = _fullNameController.text.trim().split(RegExp(r'\s+'));
    final res = await authProvider.register(
      firstName: nameParts.first,
      middleName: null,
      lastName: nameParts.skip(1).join(' '),
      role: _selectedRole,
      idNumber: _idNumberController.text.trim().isEmpty ? null : _idNumberController.text.trim(),
      idType: _selectedIdType,
      validIdBase64: _validIdBase64,
      email: _emailController.text.trim(),
      mobile: rawMobile,
      username: '', // the server creates it from the first name
      password: _passwordController.text,
      captchaId: _captchaId ?? '',
      captchaAnswer: _captchaAnswerController.text.trim(),
      acceptedTerms: _acceptedTerms,
    );

    if (!mounted) return;

    if (res['otpRequired'] == true) {
      context.push('/otp-verification', extra: {'email': res['email']});
    } else if (res['isPending'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PendingApprovalScreen(
            message: res['message'] ?? 'Your account is awaiting administrator approval.',
          ),
        ),
      );
    } else if (res['success'] == false) {
      final errorMsg = res['error'] ?? authProvider.error ?? 'Registration failed';

      // Auto-fetch a fresh CAPTCHA challenge on failed attempt
      _fetchCaptcha();

      setState(() {
        _topFormError = errorMsg;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
        ),
      );

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  // Password Checklist Helpers
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasDigit => RegExp(r'\d').hasMatch(_passwordController.text);
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _hasSymbol => RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(_passwordController.text);

  int get _strengthScore {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasDigit) score++;
    if (_hasUppercase) score++;
    if (_hasSymbol) score++;
    return score;
  }

  String get _strengthLabel {
    final score = _strengthScore;
    if (score <= 1) return 'Weak';
    if (score == 2) return 'Fair';
    if (score == 3) return 'Good';
    return 'Strong';
  }

  Color get _strengthColor {
    final score = _strengthScore;
    if (score <= 1) return Colors.red;
    if (score == 2) return Colors.orange;
    if (score == 3) return Colors.amber.shade800;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = context.watch<AuthProvider>().status;
    final isLoading = authStatus == AuthStatus.authenticating;

    return AuthShell(
      title: 'Create your account',
      subtitle: 'Gumawa ng account para makapag-file ng reklamo at makatanggap ng abiso.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Error Banner
            if (_topFormError != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _topFormError!,
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Residents only: barangay staff accounts are issued by the administrator.
            Text(
              'Para sa mga residente ang online registration. Ang mga account ng barangay staff ay ginagawa ng administrator.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            const SocialLoginButtons(label: 'Mabilis na sign-up gamit ang'),
            const SizedBox(height: 16),

            // Full Name (one field; the first name becomes the username automatically)
            TextFormField(
              controller: _fullNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
                helperText: 'First and last name, e.g. Juan Dela Cruz',
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return 'Full name is required';
                if (!RegExp(r"^[\p{L}\s\-\.']+$", unicode: true).hasMatch(t)) {
                  return 'Use letters, spaces, hyphens, periods or apostrophes only';
                }
                final words = t.split(RegExp(r'\s+'));
                if (words.length < 2 || words.first.length < 2 || words.last.length < 2) {
                  return 'Please enter your first and last name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Mobile Number
            TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Number (09XXXXXXXXX)',
                prefixIcon: Icon(Icons.phone_android),
              ),
              validator: (v) {
                final clean = (v ?? '').replaceAll(' ', '').trim();
                if (clean.isEmpty) {
                  return 'Mobile number is required';
                }
                if (!RegExp(r'^09\d{9}$').hasMatch(clean)) {
                  return 'Mobile number must start with 09 and contain 11 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email Address
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 16),

            // Password
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
              validator: Validators.validateNewPassword,
            ),
            const SizedBox(height: 10),

            // Live Password Rules Checklist & Strength Meter
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Password Strength:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(_strengthLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _strengthColor)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(4, (index) {
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: index < 3 ? 4.0 : 0.0),
                          decoration: BoxDecoration(
                            color: index < _strengthScore ? _strengthColor : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  _ruleCheckRow('At least 8 characters', _hasMinLength),
                  _ruleCheckRow('At least 1 number', _hasDigit),
                  _ruleCheckRow('At least 1 uppercase letter', _hasUppercase),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Confirm Password
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              obscureText: _obscureConfirmPassword,
              validator: (v) => Validators.validateConfirmPassword(v, _passwordController.text),
            ),
            const SizedBox(height: 20),

            // Resident Identity Verification (Option C)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.brand.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.badge_outlined, color: context.brand, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Resident ID Verification',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkNavy),
                            ),
                            Text(
                              'Patunay ng pagiging residente ng barangay',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ID Type Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedIdType,
                    decoration: const InputDecoration(
                      labelText: 'Select Valid ID Type',
                      prefixIcon: Icon(Icons.credit_card_outlined),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: _idTypeList.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontSize: 14)));
                    }).toList(),
                    onChanged: isLoading ? null : (v) => setState(() => _selectedIdType = v ?? _selectedIdType),
                  ),
                  const SizedBox(height: 12),

                  // ID Number Field
                  TextFormField(
                    controller: _idNumberController,
                    decoration: const InputDecoration(
                      labelText: 'ID / Document Number',
                      prefixIcon: Icon(Icons.numbers_outlined),
                      hintText: 'e.g. 1234-5678-9012 or Resident #',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Valid ID Photo Upload Box
                  Text(
                    'Upload Valid ID Photo',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  if (_validIdFile != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb
                                ? Image.network(_validIdFile!.path, width: 64, height: 48, fit: BoxFit.cover)
                                : Image.file(File(_validIdFile!.path), width: 64, height: 48, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                                    const SizedBox(width: 4),
                                    Text('ID Photo Attached',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green.shade800)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(_selectedIdType, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 1),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.black54),
                            tooltip: 'Retake photo',
                            onPressed: isLoading ? null : _showIdPhotoSourceSheet,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            tooltip: 'Remove',
                            onPressed: isLoading
                                ? null
                                : () => setState(() {
                                      _validIdFile = null;
                                      _validIdBase64 = null;
                                    }),
                          ),
                        ],
                      ),
                    )
                  else
                    InkWell(
                      onTap: isLoading ? null : _showIdPhotoSourceSheet,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 32, color: context.brand),
                            const SizedBox(height: 6),
                            Text(
                              'Tap to upload or photograph your ID',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: context.brand),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Camera or Gallery (JPEG, PNG, WebP up to 5MB)',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // CAPTCHA Challenge Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.brand.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.brand.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Security Verification',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkNavy),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: _isLoadingCaptcha
                              ? const Center(child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                              : Text(
                                  _captchaQuestion ?? "Couldn't load security check. Tap refresh.",
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.brand),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.refresh, color: context.brand),
                        onPressed: isLoading || _isLoadingCaptcha ? null : _fetchCaptcha,
                        tooltip: 'Refresh Security Challenge',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _captchaAnswerController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Enter Answer',
                      prefixIcon: Icon(Icons.shield_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please answer the security verification question';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Terms & Privacy Checkbox
            FormField<bool>(
              initialValue: _acceptedTerms,
              validator: (v) {
                if (_acceptedTerms != true) {
                  return 'You must agree to the Terms & Privacy Policy to register';
                }
                return null;
              },
              builder: (formState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptedTerms,
                          onChanged: isLoading
                              ? null
                              : (val) {
                                  setState(() => _acceptedTerms = val ?? false);
                                  formState.didChange(val);
                                },
                        ),
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text('I agree to the ', style: TextStyle(fontSize: 13)),
                              GestureDetector(
                                onTap: () => _showTermsDialog(
                                  'Terms of Service',
                                  'Welcome to BaraTrack. By using this service, you agree to submit truthful information when registering and submitting barangay complaints, reports, or document requests.',
                                ),
                                child: Text('Terms of Service', style: TextStyle(fontSize: 13, color: context.brand, fontWeight: FontWeight.bold)),
                              ),
                              const Text(' and ', style: TextStyle(fontSize: 13)),
                              GestureDetector(
                                onTap: () => _showTermsDialog(
                                  'Privacy Policy',
                                  'BaraTrack protects your personal data in accordance with RA 10173 (Data Privacy Act of 2012). Your details are strictly used for barangay record-keeping and case resolution.',
                                ),
                                child: Text('Privacy Policy', style: TextStyle(fontSize: 13, color: context.brand, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (formState.hasError)
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                        child: Text(
                          formState.errorText!,
                          style: TextStyle(color: Colors.red[700], fontSize: 12),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: (isLoading || !_acceptedTerms) ? null : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Create Resident Account',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account?'),
                TextButton(
                  onPressed: isLoading ? null : () => context.go('/login'),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      color: AppTheme.accentOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ruleCheckRow(String label, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: isMet ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isMet ? Colors.black87 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
