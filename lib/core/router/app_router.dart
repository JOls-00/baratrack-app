import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../presentation/screens/main_shell.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/pending_approval_screen.dart';
import '../../presentation/screens/auth/otp_verification_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/portal/portal_pages.dart';
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

class AppRouter {
  // Stable notifier for router refreshes
  static final authNotifier = ValueNotifier<AuthStatus>(AuthStatus.unauthenticated);

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final path = state.uri.path;
      final isUnauthRoute = path == '/pending-approval' ||
          path == '/otp-verification' ||
          path == '/forgot-password' ||
          PortalRoutes.isPublic(path);
      final status = authNotifier.value;

      if (status != AuthStatus.authenticated) {
        return isUnauthRoute ? null : '/welcome';
      }

      if (isUnauthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      ...PortalRoutes.routes,
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
            builder: (context, state) {
              final user = context.read<AuthProvider>().user;
              if (user?.role == 'Resident') {
                return const UserDashboardView();
              }
              return const DashboardView();
            },
          ),
          // Admin Routes
          GoRoute(path: '/complaints-inbox', builder: (context, state) => const ComplaintsInboxScreen()),
          GoRoute(
            path: '/cases',
            builder: (context, state) => CaseListScreen(
              statusFilter: state.uri.queryParameters['status'],
            ),
          ),
          GoRoute(
            path: '/cases/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return CaseDetailScreen(caseId: id);
            },
          ),
          GoRoute(
              path: '/residents',
              builder: (context, state) => const ResidentsListScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (context, state) => const ResidentFormScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) {
                    final id = int.parse(state.pathParameters['id']!);
                    return ResidentDetailScreen(residentId: id);
                  },
                ),
              ]
          ),
          GoRoute(path: '/hearings-mgmt', builder: (context, state) => const HearingsManagementScreen()),
          GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),
          GoRoute(path: '/incident-map', builder: (context, state) => const IncidentMapScreen()),
          GoRoute(path: '/users', builder: (context, state) => const UserManagementScreen()),

          // Resident Routes
          GoRoute(path: '/my-complaints', builder: (context, state) => const MyComplaintsView()),
          GoRoute(path: '/my-hearings', builder: (context, state) => const MyHearingsView()),
          GoRoute(path: '/my-documents', builder: (context, state) => const MyDocumentsView()),
          GoRoute(path: '/notifications', builder: (context, state) => const NotificationsView()),
          GoRoute(path: '/app-announcements', builder: (context, state) => const AnnouncementsView()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfileEditorView()),

          // Shared Routes
          GoRoute(path: '/settings', builder: (context, state) => const SettingsView()),
          GoRoute(path: '/file-complaint', builder: (context, state) => const FileComplaintScreen()),
        ],
      ),
    ],
  );
}
