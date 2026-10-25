import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_constants.dart';
import '../../config/app_theme.dart';
import '../../presentation/providers/branding_provider.dart';

/// The barangay's logo. Loads the one uploaded by the admin; if there is none (or the
/// server is unreachable) it falls back to the bundled seal, then to a plain shield icon.
class BrandLogo extends StatelessWidget {
  final double size;
  final bool fallbackIcon;

  const BrandLogo({super.key, required this.size, this.fallbackIcon = true});

  @override
  Widget build(BuildContext context) {
    final info = context.watch<BrandingProvider>().info;

    Widget last() => SizedBox(
          width: size,
          height: size,
          child: fallbackIcon ? Icon(Icons.shield, size: size * 0.6, color: AppTheme.logoRed) : null,
        );

    Widget bundled() => Image.asset(
          'assets/images/seal.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => last(),
        );

    if (!info.hasLogo) return bundled();

    return Image.network(
      '${AppConstants.logoUrl}?v=${info.logoVersion}',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => bundled(),
    );
  }
}
