import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../auth/login_page.dart';
import '../auth/login_screen.dart';
import '../../providers/branding_provider.dart';
import '../../providers/portal_provider.dart';
import 'faq_screen.dart';
import 'landing_screen.dart';
import 'landing_sections.dart';
import 'portal_shell.dart';
import 'track_panel.dart';

/// Every public page, each with its own interface. Add `...PortalRoutes.routes` to the router.
class PortalRoutes {
  static const _paths = {
    '/welcome', '/about', '/officials', '/announcements', '/album', '/contact', '/track', '/faqs', '/login', '/register',
  };

  /// True for pages that can be opened without being logged in.
  static bool isPublic(String path) => _paths.contains(path);

  static List<GoRoute> get routes => [
        GoRoute(path: '/welcome', builder: (_, __) => const LandingScreen()),
        GoRoute(path: '/about', builder: (_, __) => const AboutPage()),
        GoRoute(path: '/officials', builder: (_, __) => const OfficialsPage()),
        GoRoute(path: '/announcements', builder: (_, __) => const AnnouncementsPage()),
        GoRoute(path: '/album', builder: (_, __) => const AlbumPage()),
        GoRoute(path: '/contact', builder: (_, __) => const ContactPage()),
        GoRoute(path: '/track', builder: (_, __) => const TrackPage()),
        GoRoute(path: '/faqs', builder: (_, __) => const FaqScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
        GoRoute(path: '/register', builder: (_, __) => const LoginScreen()),
      ];
}

class AlbumPage extends StatelessWidget {
  const AlbumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = context.watch<BrandingProvider>().info;
    return PortalShell(current: 'album', child: AlbumSection(brand: brand, showEmptyNote: true));
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = context.watch<BrandingProvider>().info;
    return PortalShell(current: 'about', child: AboutSection(brand: brand));
  }
}

class OfficialsPage extends StatelessWidget {
  const OfficialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final officials = context.watch<BrandingProvider>().officials;
    return PortalShell(
      current: 'officials',
      child: officials.isEmpty
          ? SectionFrame(
              title: 'Barangay Officials',
              subtitle: 'Ang inyong mga lingkod-bayan',
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(children: [
                    Icon(Icons.groups_outlined, color: brandPrimary(context)),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Ilalagay ang listahan ng mga opisyal ng barangay dito sa lalong madaling panahon.')),
                  ]),
                ),
              ),
            )
          : OfficialsSection(officials: officials),
    );
  }
}

class AnnouncementsPage extends StatelessWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.watch<PortalProvider>().announcements;
    return PortalShell(current: 'announcements', child: AnnouncementsSection(items: items));
  }
}

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = context.watch<BrandingProvider>().info;
    return PortalShell(
      current: 'contact',
      child: ContactSection(brand: brand, onLogin: () => context.go('/login')),
    );
  }
}

class TrackPage extends StatelessWidget {
  const TrackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PortalShell(
      current: 'track',
      child: SectionFrame(
        title: 'Track your application',
        subtitle: 'Alamin ang status ng iyong reklamo o kaso. Hindi mo kailangang mag-login.',
        child: TrackPanel(),
      ),
    );
  }
}
