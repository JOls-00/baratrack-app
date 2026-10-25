import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../providers/branding_provider.dart';
import 'package:provider/provider.dart';
import '../portal/landing_sections.dart';
import '../portal/portal_shell.dart' show ClockChip;

/// Colourful two-panel layout for the login and registration pages:
/// a branded panel on the left (top on phones) and the form on the right.
class AuthShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final double formWidth;

  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.formWidth = 440,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.watch<BrandingProvider>().info;
    final primary = brand.primary;

    Widget formArea() => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: formWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(height: 12),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, height: 1.4)),
                  const SizedBox(height: 24),
                  child,
                ],
              ),
            ),
          ),
        );

    return Scaffold(
      body: Stack(
        children: [
          LayoutBuilder(builder: (context, c) {
            if (c.maxWidth >= 900) {
              return Row(
                children: [
                  Expanded(flex: 5, child: _BrandPanel(brandName: brand.name, city: brand.city, primary: primary)),
                  Expanded(flex: 6, child: formArea()),
                ],
              );
            }
            return SingleChildScrollView(
              child: Column(
                children: [
                  _CompactHeader(brandName: brand.name, city: brand.city, primary: primary),
                  formArea(),
                ],
              ),
            );
          }),
          // Live date and time lives here (sign-in / registration), not in the public nav bar.
          const Positioned(top: 14, right: 16, child: ClockChip(background: Colors.white)),
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  final String brandName;
  final String city;
  final Color primary;
  const _BrandPanel({required this.brandName, required this.city, required this.primary});

  @override
  Widget build(BuildContext context) {
    final features = [
      (Icons.edit_note, 'File complaints online', 'Kahit anong oras, nasaan ka man.'),
      (Icons.track_changes, 'Track every step', 'Alamin ang status at petsa ng hearing.'),
      (Icons.notifications_active_outlined, 'Stay informed', 'Mga abiso at announcement mula sa barangay.'),
    ];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [shadeColor(primary, -0.3), primary],
        ),
      ),
      child: Stack(
        children: [
          // decorative circles
          Positioned(top: -90, right: -90, child: _circle(300, 0.07)),
          Positioned(bottom: -120, left: -80, child: _circle(340, 0.06)),
          Positioned(bottom: 120, right: 40, child: _circle(120, 0.08)),
          Padding(
            padding: const EdgeInsets.fromLTRB(48, 28, 48, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () => context.go('/welcome'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back to home'),
                ),
                const Spacer(),
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: AppTheme.sunYellow, width: 4),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 10))],
                  ),
                  child: const ClipOval(child: BrandLogo(size: 104)),
                ),
                const SizedBox(height: 24),
                const Text('BaraTrack',
                    style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1)),
                const SizedBox(height: 4),
                Text('$brandName · $city'.toUpperCase(),
                    style: const TextStyle(color: AppTheme.sunYellow, fontSize: 12, letterSpacing: 1.8)),
                const SizedBox(height: 18),
                Text('Serbisyong mabilis, malinaw at para sa lahat.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 17, height: 1.4)),
                const SizedBox(height: 28),
                for (final f in features)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withValues(alpha: 0.16),
                          child: Icon(f.$1, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.$2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              Text(f.$3, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(flex: 2),
                SizedBox(
                  height: 5,
                  child: Row(
                    children: [
                      AppTheme.burstBlue,
                      AppTheme.burstTeal,
                      AppTheme.burstOrange,
                      Colors.white,
                      AppTheme.sunYellow,
                      AppTheme.laurelGreen,
                    ].map((col) => Expanded(child: Container(color: col))).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)),
      );
}

class _CompactHeader extends StatelessWidget {
  final String brandName;
  final String city;
  final Color primary;
  const _CompactHeader({required this.brandName, required this.city, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [shadeColor(primary, -0.3), primary]),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => context.go('/welcome'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back to home'),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: AppTheme.sunYellow, width: 3),
                    ),
                    child: const ClipOval(child: BrandLogo(size: 58)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('BaraTrack',
                            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                        Text('$brandName · $city'.toUpperCase(),
                            style: const TextStyle(color: AppTheme.sunYellow, fontSize: 10.5, letterSpacing: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
