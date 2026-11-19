import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/version_provider.dart';
import '../../../config/app_constants.dart';
import '../../../core/widgets/hover_pop.dart';
import '../portal/landing_sections.dart';
import 'auth_shell.dart';
import 'social_login_buttons.dart';

/// Sign-in only. Creating an account lives on its own page (/register).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _qrShowApk = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<VersionProvider>().checkForUpdates(context: context);
      }
    });
  }

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    setState(() => _error = null);

    final success = await auth.login(_login.text.trim(), _password.text);
    if (!mounted || success) return; // on success the router moves to the dashboard

    if (auth.unverifiedEmail != null) {
      final email = auth.unverifiedEmail!;
      try {
        await auth.resendOtp(email);
      } catch (_) {}
      if (!mounted) return;
      context.push('/otp-verification', extra: {'email': email});
    } else {
      setState(() => _error = auth.error ?? 'Authentication failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = brandPrimary(context);
    final loading = context.watch<AuthProvider>().status == AuthStatus.authenticating;
    final isFil = context.watch<LocaleProvider>().isFilipino;

    return AuthShell(
      title: 'Welcome back',
      subtitle: isFil
          ? 'Mag-sign in para makita ang iyong mga reklamo, hearing at abiso.'
          : 'Sign in to view your complaints, hearings, and barangay notices.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade800))),
                  ],
                ),
              ),
            TextFormField(
              controller: _login,
              enabled: !loading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(labelText: 'Email or username', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your email or username' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              enabled: !loading,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Please enter your password' : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: loading
                    ? null
                    : () {
                        final typed = _login.text.trim();
                        context.push('/forgot-password', extra: {'email': typed.contains('@') ? typed : null});
                      },
                child: Text('Forgot password?', style: TextStyle(color: primary)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: loading
                    ? const SizedBox(
                        width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 22),
            const SocialLoginButtons(),
            const SizedBox(height: 22),
            Row(children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  isFil ? 'Wala pang account?' : "Don't have an account?",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
              const Expanded(child: Divider()),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: loading ? null : () => context.go('/register'),
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: Text(
                  isFil ? 'Gumawa ng account' : 'Create an account',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (kIsWeb) ...[
              const SizedBox(height: 12),
              HoverPop(
                hoverScale: 1.02,
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse('https://github.com/JOls-00/baratrack-app/releases/latest');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.android_rounded, size: 19),
                    label: Text(
                      isFil
                          ? 'I-download ang Android App (v${AppConstants.appVersion} APK)'
                          : 'Download BaraTrack Android App (v${AppConstants.appVersion} APK)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade800,
                      side: BorderSide(color: Colors.green.shade600, width: 1.4),
                      backgroundColor: Colors.green.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Builder(builder: (context) {
                const webUrl = 'https://jols-00.github.io/baratrack-app/';
                const apkUrl = 'https://github.com/JOls-00/baratrack-app/releases/latest';
                final targetUrl = _qrShowApk ? apkUrl : webUrl;
                final qrSrc =
                    'https://api.qrserver.com/v1/create-qr-code/?size=180x180&margin=8&data=${Uri.encodeComponent(targetUrl)}';
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.qr_code_2_rounded, color: primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isFil ? 'Easy-Access QR Code' : 'Easy-Access QR Code',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                            ),
                          ),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(value: false, label: Text('Web QR', style: TextStyle(fontSize: 11.5))),
                              ButtonSegment(value: true, label: Text('APK QR', style: TextStyle(fontSize: 11.5))),
                            ],
                            selected: {_qrShowApk},
                            onSelectionChanged: (s) => setState(() => _qrShowApk = s.first),
                            showSelectedIcon: false,
                            style: const ButtonStyle(visualDensity: VisualDensity.compact),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Image.network(
                          qrSrc,
                          width: 148,
                          height: 148,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            width: 148,
                            height: 148,
                            child: Center(child: Icon(Icons.qr_code_2_rounded, size: 64, color: Colors.black38)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              targetUrl,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontFamily: 'monospace'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            tooltip: isFil ? 'Kopyahin ang link' : 'Copy link',
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            visualDensity: VisualDensity.compact,
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: targetUrl));
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isFil ? 'Nakopya ang link!' : 'Link copied to clipboard!'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 28),
            Row(children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  isFil ? 'Mabilis na Serbisyo (No Login)' : 'Quick Services (No Login)',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const Expanded(child: Divider()),
            ]),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => context.push('/track'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.track_changes, color: primary, size: 26),
                          const SizedBox(height: 6),
                          const Text(
                            'Track Complaint',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Reference # check',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => context.push('/announcements'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.campaign_outlined, color: primary, size: 26),
                          const SizedBox(height: 6),
                          const Text(
                            'Announcements',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isFil ? 'Balita at abiso' : 'News & advisories',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
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
}
