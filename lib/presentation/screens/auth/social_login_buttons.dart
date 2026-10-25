import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

/// "Continue with Google / Facebook" for residents. Only the providers the server has
/// set up are shown; if neither is set up, nothing is shown at all.
class SocialLoginButtons extends StatefulWidget {
  /// Shown above the buttons, e.g. "or continue with".
  final String label;
  const SocialLoginButtons({super.key, this.label = 'O mag-continue gamit ang'});

  @override
  State<SocialLoginButtons> createState() => _SocialLoginButtonsState();
}

class _SocialLoginButtonsState extends State<SocialLoginButtons> {
  Map<String, dynamic>? _cfg;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cfg = await context.read<AuthProvider>().socialConfig();
      if (mounted) setState(() => _cfg = cfg);
    } catch (_) {
      // Server not updated yet: simply show no quick sign-in buttons.
    }
  }

  Future<void> _google() async {
    final auth = context.read<AuthProvider>();
    final id = _cfg?['google_client_id']?.toString();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final gs = GoogleSignIn(
        scopes: const ['email', 'profile'],
        clientId: kIsWeb ? id : null,
        serverClientId: kIsWeb ? null : id,
      );
      final acc = await gs.signIn();
      if (acc == null) return; // closed by the user
      final a = await acc.authentication;
      final ok = await auth.socialLogin('google', idToken: a.idToken, accessToken: a.accessToken);
      if (!ok && mounted) setState(() => _error = auth.error ?? 'Hindi nakapag-sign in gamit ang Google.');
    } catch (_) {
      if (mounted) setState(() => _error = 'Hindi nakapag-sign in gamit ang Google. Subukan ulit.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _facebook() async {
    final auth = context.read<AuthProvider>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (kIsWeb) {
        await FacebookAuth.i.webAndDesktopInitialize(
          appId: _cfg?['facebook_app_id']?.toString() ?? '',
          cookie: true,
          xfbml: true,
          version: 'v19.0',
        );
      }
      final res = await FacebookAuth.instance.login(permissions: const ['email', 'public_profile']);
      if (res.status != LoginStatus.success || res.accessToken == null) return; // cancelled or failed
      final ok = await auth.socialLogin('facebook', accessToken: res.accessToken!.tokenString);
      if (!ok && mounted) setState(() => _error = auth.error ?? 'Hindi nakapag-sign in gamit ang Facebook.');
    } catch (_) {
      if (mounted) setState(() => _error = 'Hindi nakapag-sign in gamit ang Facebook. Subukan ulit.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final google = _cfg?['google'] == true;
    final facebook = _cfg?['facebook'] == true;
    if (!google && !facebook) return const SizedBox.shrink();

    Widget button({required Widget icon, required String text, required VoidCallback? onTap}) => SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: icon,
            label: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(widget.label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          const Expanded(child: Divider()),
        ]),
        const SizedBox(height: 14),
        if (google)
          button(
            icon: const Text('G', style: TextStyle(color: Color(0xFFDB4437), fontSize: 20, fontWeight: FontWeight.w900)),
            text: 'Continue with Google',
            onTap: _busy ? null : _google,
          ),
        if (google && facebook) const SizedBox(height: 10),
        if (facebook)
          button(
            icon: const Icon(Icons.facebook, color: Color(0xFF1877F2)),
            text: 'Continue with Facebook',
            onTap: _busy ? null : _facebook,
          ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
        ],
        const SizedBox(height: 8),
        Text('Para sa mga residente lamang. Sa pag-continue, sumasang-ayon ka sa Terms of Use.',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
      ],
    );
  }
}
