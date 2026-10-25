import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/otp_input.dart';
import '../../providers/auth_provider.dart';

enum _ResetStep { email, code, password }

/// Three-step password reset: enter email -> enter emailed code -> choose new password.
class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _otpKey = GlobalKey<OtpInputState>();

  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  _ResetStep _step = _ResetStep.email;
  String _email = '';
  String _code = '';
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  String? _info;

  Timer? _timer;
  int _countdown = 0;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String _clean(Object e) => e.toString().replaceAll('Exception: ', '');

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        t.cancel();
      }
    });
  }

  // ---- Step 1: request code -------------------------------------------------
  Future<void> _requestCode({bool isResend = false}) async {
    if (!isResend && !_emailFormKey.currentState!.validate()) return;
    if (_busy) return;

    final email = isResend ? _email : _emailController.text.trim();
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });

    try {
      final msg = await context.read<AuthProvider>().requestPasswordReset(email);
      if (!mounted) return;
      setState(() {
        _email = email;
        _step = _ResetStep.code;
        _info = msg;
        _busy = false;
      });
      _otpKey.currentState?.clear();
      _code = '';
      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _clean(e);
        _busy = false;
      });
    }
  }

  // ---- Step 2: verify code --------------------------------------------------
  Future<void> _verifyCode() async {
    if (_code.length != 6 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });

    try {
      await context.read<AuthProvider>().verifyResetCode(_email, _code);
      if (!mounted) return;
      setState(() {
        _step = _ResetStep.password;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _clean(e);
        _busy = false;
        _code = '';
      });
      _otpKey.currentState?.clear();
    }
  }

  // ---- Step 3: set new password --------------------------------------------
  Future<void> _resetPassword() async {
    if (!_passwordFormKey.currentState!.validate() || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final msg = await context.read<AuthProvider>().resetPassword(
        email: _email,
        code: _code,
        newPassword: _passwordController.text,
      );
      if (!mounted) return;

      // Grab the messenger first: this screen is about to be popped.
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
        ),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/login');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _clean(e);
        _busy = false;
      });
    }
  }

  void _goBack() {
    setState(() {
      _error = null;
      _info = null;
    });
    switch (_step) {
      case _ResetStep.email:
        context.canPop() ? context.pop() : context.go('/login');
        break;
      case _ResetStep.code:
        setState(() => _step = _ResetStep.email);
        break;
      case _ResetStep.password:
      // The code was already checked; ask for it again rather than keep it around.
        _code = '';
        setState(() => _step = _ResetStep.code);
        break;
    }
  }

  // ---- UI -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _busy ? null : _goBack,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      if (_step == _ResetStep.email) _buildEmailStep(),
                      if (_step == _ResetStep.code) _buildCodeStep(),
                      if (_step == _ResetStep.password) _buildPasswordStep(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final (IconData icon, String title, Widget subtitle) = switch (_step) {
      _ResetStep.email => (
      Icons.lock_reset,
      'Forgot Password?',
      const Text(
        "Enter the email address on your account and we'll send you a 6-digit reset code.",
        textAlign: TextAlign.center,
      ),
      ),
      _ResetStep.code => (
      Icons.mark_email_read_outlined,
      'Enter Reset Code',
      RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          children: [
            const TextSpan(text: 'If an account exists for\n'),
            TextSpan(
              text: _email,
              style: TextStyle(fontWeight: FontWeight.bold, color: context.brand),
            ),
            const TextSpan(text: ',\na code is on its way.'),
          ],
        ),
      ),
      ),
      _ResetStep.password => (
      Icons.password_outlined,
      'Create New Password',
      const Text(
        'Choose a new password of at least 8 characters.',
        textAlign: TextAlign.center,
      ),
      ),
    };

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.brand.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 48, color: context.brand),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.darkNavy,
          ),
        ),
        const SizedBox(height: 10),
        DefaultTextStyle.merge(
          style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          child: subtitle,
        ),
      ],
    );
  }

  Widget _banner(String message, {required bool isError}) {
    final base = isError ? Colors.red : Colors.green;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: base.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: base.shade200),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
              color: base.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: base.shade800, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _spinner() => const SizedBox(
    height: 20,
    width: 20,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
    ),
  );

  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) _banner(_error!, isError: true),
          TextFormField(
            controller: _emailController,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _requestCode(),
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _busy ? null : _requestCode,
              child: _busy
                  ? _spinner()
                  : const Text('Send Reset Code',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OtpInput(
          key: _otpKey,
          enabled: !_busy,
          onChanged: (value) => setState(() {
            _code = value;
            _error = null;
          }),
        ),
        const SizedBox(height: 20),
        if (_error != null) _banner(_error!, isError: true),
        if (_info != null && _error == null) _banner(_info!, isError: false),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: (_code.length == 6 && !_busy) ? _verifyCode : null,
            child: _busy
                ? _spinner()
                : const Text('Verify Code',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Didn't receive the code? "),
            if (_countdown > 0)
              Text('Resend in ${_countdown}s',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))
            else
              TextButton(
                onPressed: _busy ? null : () => _requestCode(isResend: true),
                child: const Text('Resend Code',
                    style: TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) _banner(_error!, isError: true),
          TextFormField(
            controller: _passwordController,
            enabled: !_busy,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: Validators.validatePassword,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmController,
            enabled: !_busy,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _resetPassword(),
            decoration: const InputDecoration(
              labelText: 'Confirm New Password',
              prefixIcon: Icon(Icons.lock_reset_outlined),
            ),
            validator: (v) => Validators.validateConfirmPassword(v, _passwordController.text),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _busy ? null : _resetPassword,
              child: _busy
                  ? _spinner()
                  : const Text('Reset Password',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
