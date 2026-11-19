import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../presentation/screens/main_shell.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/pending_approval_screen.dart';
import '../../presentation/screens/auth/otp_verification_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/portal/portal_pages.dart';
import '../../presentation/screens/calendar/calendar_screen.dart';
import '../../presentation/screens/dashboard/dashboard_view.dart';
import '../../presentation/screens/dashboard/user_dashboard_view.dart';
import '../../presentation/screens/cases/case_list_screen.dart';
import '../../presentation/screens/cases/case_detail_screen.dart';
import '../../presentation/screens/residents/residents_list_screen.dart';
import '../../presentation/screens/residents/resident_detail_screen.dart';
import '../../presentation/screens/residents/resident_form_screen.dart';
import '../../presentation/screens/hearings/hearings_management_screen.dart';
import '../../presentation/screens/reports/reports_screen.dart';
import '../../presentation/screens/incident_map/incident_map_screen.dart';
import '../../presentation/screens/users/user_management_screen.dart';
import '../../presentation/screens/settings/settings_view.dart';
import '../../presentation/screens/complaints/file_complaint_screen.dart';
import '../../presentation/screens/complaints/my_complaints_view.dart';
import '../../presentation/screens/complaints/complaints_inbox_screen.dart';
import '../../presentation/screens/hearings/my_hearings_view.dart';
import '../../presentation/screens/documents/my_documents_view.dart';
import '../../presentation/screens/notifications/notifications_view.dart';
import '../../presentation/screens/announcements/announcements_view.dart';
import '../../presentation/screens/profile/profile_editor_view.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/locale_provider.dart';
import '../../presentation/screens/offline/offline_mode_screen.dart';
import '../../presentation/screens/offline/offline_drafts_screen.dart';

class AppRouter {
  // Stable notifiers for router refreshes & role guards
  static final authNotifier = ValueNotifier<AuthStatus>(AuthStatus.unauthenticated);
  static final roleNotifier = ValueNotifier<String?>(null);
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final ValueNotifier<bool> offlineNotifier = ValueNotifier<bool>(false);
  static bool get userChoseOffline => offlineNotifier.value;
  static set userChoseOffline(bool value) => offlineNotifier.value = value;
  static bool _isShowingOfflineDialog = false;

  static CustomTransitionPage<void> _smoothPage(GoRouterState state, Widget child) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 240),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.025),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static void promptOfflineMode() {
    if (userChoseOffline) return;
    final context = navigatorKey.currentContext;
    if (context == null || _isShowingOfflineDialog) return;

    bool isFil = true;
    try {
      isFil = context.read<LocaleProvider>().isFilipino;
    } catch (_) {}

    _isShowingOfflineDialog = true;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded, color: Colors.amber.shade900, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isFil ? 'Walang Koneksyon' : 'No Connection',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          isFil
              ? 'Hindi maabot ang internet o server. Nais mo bang lumipat sa Offline Mode para ma-access ang iyong mga naka-save na reklamo at iskedyul?'
              : 'Unable to reach the internet or server. Switch to Offline Mode to access your saved complaints and schedules?',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _isShowingOfflineDialog = false;
              Navigator.pop(ctx);
            },
            child: Text(isFil ? 'Kanselahin' : 'Cancel', style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD61314),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.offline_pin_rounded, size: 18),
            label: Text(
              isFil ? 'Lumipat sa Offline Mode' : 'Switch to Offline Mode',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              _isShowingOfflineDialog = false;
              userChoseOffline = true;
              Navigator.pop(ctx);
              router.go('/offline');
            },
          ),
        ],
      ),
    ).then((_) => _isShowingOfflineDialog = false);
  }

  static void exitOfflineMode() {
    userChoseOffline = false;
    final status = authNotifier.value;
    if (status == AuthStatus.authenticated) {
      router.go('/');
    } else {
      router.go(kIsWeb ? '/welcome' : '/login');
    }
  }

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final path = state.uri.path;
      if (path == '/offline') {
        return null;
      }
      final isUnauthRoute = path == '/pending-approval' ||
          path == '/otp-verification' ||
          path == '/forgot-password' ||
          PortalRoutes.isPublic(path);
      final status = authNotifier.value;

      if (status != AuthStatus.authenticated) {
        // Website visitors see the landing page; the phone app goes straight to login.
        return isUnauthRoute ? null : (kIsWeb ? '/welcome' : '/login');
      }

      if (isUnauthRoute) {
        return '/';
      }

      // Role-based route guards
      final role = roleNotifier.value;
      const staffPaths = [
        '/complaints-inbox',
        '/cases',
        '/residents',
        '/hearings-mgmt',
        '/reports',
        '/incident-map',
      ];
      if (role == 'Resident' &&
          (path == '/users' || staffPaths.any((p) => path == p || path.startsWith('$p/')))) {
        return '/';
      }
      if (role != null && role != 'Admin' && path == '/users') {
        return '/';
      }

      return null;
    },
    routes: [
      ...PortalRoutes.routes,
      GoRoute(
        path: '/offline',
        builder: (context, state) => const OfflineModeScreen(),
      ),
      GoRoute(
        path: '/offline-drafts',
        pageBuilder: (context, state) => _smoothPage(state, const OfflineDraftsScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) {
          final extra = state.extra;
          final email = extra is Map && extra['email'] is String ? extra['email'] as String : null;
          return ForgotPasswordScreen(initialEmail: email);
        },
      ),
      GoRoute(
        path: '/pending-approval',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PendingApprovalScreen(
            message: extra?['message'] ?? 'Your account is awaiting administrator approval.',
          );
        },
      ),
      GoRoute(
        path: '/otp-verification',
        builder: (context, state) {
          final extra = state.extra;
          String? email;
          if (extra is Map && extra['email'] is String) {
            email = extra['email'] as String;
          }
          if (email == null || email.trim().isEmpty) {
            return const LoginScreen();
          }
          return OtpVerificationScreen(
            email: email,
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) {
              final user = context.read<AuthProvider>().user;
              final view = user?.role == 'Resident' ? const UserDashboardView() : const DashboardView();
              return _smoothPage(state, view);
            },
          ),
          GoRoute(path: '/calendar', pageBuilder: (context, state) => _smoothPage(state, const CalendarScreen())),
          // Admin Routes
          GoRoute(path: '/complaints-inbox', pageBuilder: (context, state) => _smoothPage(state, const ComplaintsInboxScreen())),
          GoRoute(
            path: '/cases',
            pageBuilder: (context, state) => _smoothPage(
              state,
              CaseListScreen(statusFilter: state.uri.queryParameters['status']),
            ),
          ),
          GoRoute(
            path: '/cases/:id',
            pageBuilder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              if (id == null) {
                return _smoothPage(state, const CaseListScreen());
              }
              return _smoothPage(state, CaseDetailScreen(caseId: id));
            },
          ),
          GoRoute(
              path: '/residents',
              pageBuilder: (context, state) => _smoothPage(state, const ResidentsListScreen()),
              routes: [
                GoRoute(
                  path: 'new',
                  pageBuilder: (context, state) => _smoothPage(state, const ResidentFormScreen()),
                ),
                GoRoute(
                  path: ':id',
                  pageBuilder: (context, state) {
                    final id = int.tryParse(state.pathParameters['id'] ?? '');
                    if (id == null) {
                      return _smoothPage(state, const ResidentsListScreen());
                    }
                    return _smoothPage(state, ResidentDetailScreen(residentId: id));
                  },
                ),
              ]),
          GoRoute(path: '/hearings-mgmt', pageBuilder: (context, state) => _smoothPage(state, const HearingsManagementScreen())),
          GoRoute(path: '/reports', pageBuilder: (context, state) => _smoothPage(state, const ReportsScreen())),
          GoRoute(path: '/incident-map', pageBuilder: (context, state) => _smoothPage(state, const IncidentMapScreen())),
          GoRoute(path: '/users', pageBuilder: (context, state) => _smoothPage(state, const UserManagementScreen())),

          // Resident Routes
          GoRoute(path: '/my-complaints', pageBuilder: (context, state) => _smoothPage(state, const MyComplaintsView())),
          GoRoute(path: '/my-hearings', pageBuilder: (context, state) => _smoothPage(state, const MyHearingsView())),
          GoRoute(path: '/my-documents', pageBuilder: (context, state) => _smoothPage(state, const MyDocumentsView())),
          GoRoute(path: '/notifications', pageBuilder: (context, state) => _smoothPage(state, const NotificationsView())),
          GoRoute(path: '/app-announcements', pageBuilder: (context, state) => _smoothPage(state, const AnnouncementsView())),
          GoRoute(path: '/profile', pageBuilder: (context, state) => _smoothPage(state, const ProfileEditorView())),

          // Shared Routes
          GoRoute(path: '/settings', pageBuilder: (context, state) => _smoothPage(state, const SettingsView())),
          GoRoute(path: '/file-complaint', pageBuilder: (context, state) => _smoothPage(state, const FileComplaintScreen())),
        ],
      ),
    ],
  );
}
