import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'core/network/api_client.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/case_repository.dart';
import 'data/repositories/resident_repository.dart';
import 'data/repositories/hearing_repository.dart';
import 'data/repositories/user_repository.dart';
import 'data/repositories/complaint_repository.dart';
import 'data/repositories/reports_repository.dart';
import 'data/repositories/evidence_repository.dart';
import 'data/repositories/documents_repository.dart';
import 'data/repositories/portal_repository.dart';
import 'data/repositories/branding_repository.dart';
import 'data/repositories/content_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/case_provider.dart';
import 'presentation/providers/resident_provider.dart';
import 'presentation/providers/complaint_provider.dart';
import 'presentation/providers/hearing_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/providers/reports_provider.dart';
import 'presentation/providers/evidence_provider.dart';
import 'presentation/providers/documents_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/navigation_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/providers/announcement_provider.dart';
import 'presentation/providers/portal_provider.dart';
import 'presentation/providers/branding_provider.dart';
import 'core/router/app_router.dart';
import 'core/widgets/session_reset_binder.dart';

void main() {
  final apiClient = ApiClient();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ProxyProvider<ApiClient, AuthRepository>(
          update: (_, client, __) => AuthRepository(client),
        ),
        ProxyProvider<ApiClient, CaseRepository>(
          update: (_, client, __) => CaseRepository(client),
        ),
        ProxyProvider<ApiClient, ResidentRepository>(
          update: (_, client, __) => ResidentRepository(client),
        ),
        ProxyProvider<ApiClient, HearingRepository>(
          update: (_, client, __) => HearingRepository(client),
        ),
        ProxyProvider<ApiClient, UserRepository>(
          update: (_, client, __) => UserRepository(client),
        ),
        ProxyProvider<ApiClient, ComplaintRepository>(
          update: (_, client, __) => ComplaintRepository(client),
        ),
        ProxyProvider<ApiClient, ReportsRepository>(
          update: (_, client, __) => ReportsRepository(client),
        ),
        ProxyProvider<ApiClient, EvidenceRepository>(
          update: (_, client, __) => EvidenceRepository(client),
        ),
        ProxyProvider<ApiClient, DocumentsRepository>(
          update: (_, client, __) => DocumentsRepository(client),
        ),
        ProxyProvider<ApiClient, PortalRepository>(
          update: (_, client, __) => PortalRepository(client),
        ),
        ProxyProvider<ApiClient, BrandingRepository>(
          update: (_, client, __) => BrandingRepository(client),
        ),
        ProxyProvider<ApiClient, ContentRepository>(
          update: (_, client, __) => ContentRepository(client),
        ),
        ProxyProvider<ApiClient, NotificationRepository>(
          update: (_, client, __) => NotificationRepository(client),
        ),
        ChangeNotifierProxyProvider3<AuthRepository, ResidentRepository, UserRepository, AuthProvider>(
          create: (context) => AuthProvider(
            context.read<AuthRepository>(),
            context.read<ResidentRepository>(),
            context.read<UserRepository>(),
          ),
          update: (_, authRepo, resRepo, userRepo, previous) =>
          previous ?? AuthProvider(authRepo, resRepo, userRepo),
        ),
        ChangeNotifierProvider(
          create: (context) => CaseProvider(context.read<CaseRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ResidentProvider(context.read<ResidentRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => HearingProvider(context.read<HearingRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => UserProvider(context.read<UserRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ComplaintProvider(context.read<ComplaintRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ReportsProvider(context.read<ReportsRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => EvidenceProvider(context.read<EvidenceRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => DocumentsProvider(context.read<DocumentsRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => NavigationProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => NotificationProvider(context.read<NotificationRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => AnnouncementProvider(
            context.read<PortalRepository>(),
            context.read<ContentRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => PortalProvider(context.read<PortalRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => BrandingProvider(context.read<BrandingRepository>())..load(),
        ),
      ],
      child: const BarangayApp(),
    ),
  );
}

class BarangayApp extends StatelessWidget {
  const BarangayApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final brandPrimary = context.watch<BrandingProvider>().info.primary;
    final isLoggedIn = context.watch<AuthProvider>().status == AuthStatus.authenticated;

    // The public pages (landing, login, FAQs, password reset) are designed for the
    // official Barangay Rosario look. A user's personal theme only applies while
    // they are signed in, so it never "leaks" onto the pages shown after logout.
    final activeCombo = isLoggedIn ? themeProvider.themeCombo : ThemeCombo.barangayRosario;
    final activeMode = isLoggedIn ? themeProvider.themeMode : ThemeMode.light;

    return MaterialApp.router(
      title: 'BaraTrack',
      theme: AppTheme.getTheme(activeCombo, primaryOverride: brandPrimary),
      themeMode: activeMode,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        return SessionResetBinder(
          child: AnimatedTheme(
            data: AppTheme.getTheme(activeCombo, primaryOverride: brandPrimary),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: child!,
          ),
        );
      },
    );
  }
}
