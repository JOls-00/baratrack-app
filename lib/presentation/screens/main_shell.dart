import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import 'dashboard/dashboard_view.dart';
import 'dashboard/user_dashboard_view.dart';
import 'complaints/my_complaints_view.dart';
import 'complaints/complaints_inbox_screen.dart';
import 'hearings/my_hearings_view.dart';
import 'documents/my_documents_view.dart';
import 'notifications/notifications_view.dart';
import 'announcements/announcements_view.dart';
import 'profile/profile_editor_view.dart';
import 'settings/settings_view.dart';
import 'cases/case_list_screen.dart';
import 'complaints/file_complaint_screen.dart';
import 'residents/residents_list_screen.dart';
import 'hearings/hearings_management_screen.dart';
import 'reports/reports_screen.dart';
import 'users/user_management_screen.dart';
import '../../core/widgets/brand_logo.dart';

class MainShell extends StatefulWidget {
  final Widget? child;
  const MainShell({super.key, this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationProvider>().load();
    });
    // Pick up new notifications every minute while the app is open.
    _notificationTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) context.read<NotificationProvider>().load();
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  int _getSelectedIndex(BuildContext context, bool isResident) {
    final location = GoRouterState.of(context).uri.path;

    if (isResident) {
      if (location == '/') return 0;
      if (location.startsWith('/my-complaints')) return 1;
      if (location.startsWith('/my-hearings')) return 2;
      if (location.startsWith('/my-documents')) return 3;
      if (location.startsWith('/notifications')) return 4;
      if (location.startsWith('/app-announcements')) return 5;
      if (location.startsWith('/profile')) return 6;
      if (location.startsWith('/settings')) return 7;
      return 0;
    }

    if (location == '/') return 0;
    if (location.startsWith('/complaints-inbox')) return 1;
    if (location.startsWith('/cases')) return 2;
    if (location.startsWith('/residents')) return 3;
    if (location.startsWith('/hearings-mgmt')) return 4;
    if (location.startsWith('/app-announcements')) return 5;
    if (location.startsWith('/reports')) return 6;
    if (location.startsWith('/incident-map')) return 7;
    if (location.startsWith('/users')) return 8;
    if (location.startsWith('/settings')) return 9;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, bool isResident) {
    if (isResident) {
      switch (index) {
        case 0: context.go('/'); break;
        case 1: context.go('/my-complaints'); break;
        case 2: context.go('/my-hearings'); break;
        case 3: context.go('/my-documents'); break;
        case 4: context.go('/notifications'); break;
        case 5: context.go('/app-announcements'); break;
        case 6: context.go('/profile'); break;
        case 7: context.go('/settings'); break;
      }
    } else {
      switch (index) {
        case 0: context.go('/'); break;
        case 1: context.go('/complaints-inbox'); break;
        case 2: context.go('/cases'); break;
        case 3: context.go('/residents'); break;
        case 4: context.go('/hearings-mgmt'); break;
        case 5: context.go('/app-announcements'); break;
        case 6: context.go('/reports'); break;
        case 7: context.go('/incident-map'); break;
        case 8: context.go('/users'); break;
        case 9: context.go('/settings'); break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isResident = user?.role == 'Resident';
    final isMobile = MediaQuery.of(context).size.width < 1000;
    final theme = Theme.of(context);
    final selectedIndex = _getSelectedIndex(context, isResident);

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile ? _buildNavDrawer(context, isResident, selectedIndex) : null,
      endDrawer: _buildNotificationDrawer(context, isResident),
      body: Row(
        children: [
          if (!isMobile)
          // Scrollable so every menu item stays reachable on shorter windows.
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: NavigationRail(
                      extended: MediaQuery.of(context).size.width > 1350,
                      selectedIndex: selectedIndex,
                      onDestinationSelected: (i) => _onItemTapped(i, context, isResident),
                      leading: _buildSidebarLogo(theme),
                      destinations: isResident ? _buildResidentDestinations() : _buildAdminDestinations(),
                    ),
                  ),
                ),
              ),
            ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, user, isMobile),
                Expanded(
                  child: widget.child ?? const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, user, bool isMobile) {
    final theme = Theme.of(context);
    final isResident = user?.role == 'Resident';

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          if (isMobile) IconButton(icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
          Text(
              'BaraTrack',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: theme.colorScheme.primary, letterSpacing: -0.5)
          ),
          const SizedBox(width: 48),

          if (isResident)
            ElevatedButton.icon(
              onPressed: () => context.push('/file-complaint'),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('New Complaint', style: TextStyle(fontWeight: FontWeight.bold)),
            ),

          const Spacer(),
          Builder(builder: (context) {
            final unread = context.watch<NotificationProvider>().unreadCount;
            return IconButton(
              tooltip: 'Notifications',
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text(unread > 99 ? '99+' : '$unread'),
                child: Icon(Icons.notifications_none, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
              onPressed: () {
                context.read<NotificationProvider>().load();
                _scaffoldKey.currentState?.openEndDrawer();
              },
            );
          }),
          const SizedBox(width: 16),
          _buildUserMenu(context, user),
        ],
      ),
    );
  }

  Widget _buildUserMenu(BuildContext context, user) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          radius: 18,
          child: Text(user?.name[0] ?? 'U', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        if (MediaQuery.of(context).size.width > 700) ...[
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.name ?? 'User', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Text(user?.role ?? 'Role', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11)),
            ],
          ),
          const SizedBox(width: 4),
          PopupMenuButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 20),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('My Profile'),
                onTap: () => context.go(user?.role == 'Resident' ? '/profile' : '/settings'),
              ),
              PopupMenuItem(child: const Text('Logout'), onTap: () => context.read<AuthProvider>().logout()),
            ],
          ),
        ]
      ],
    );
  }

  Widget _buildNotificationDrawer(BuildContext context, bool isResident) {
    final theme = Theme.of(context);
    return Drawer(
      width: 400,
      child: SafeArea(
        child: Consumer<NotificationProvider>(
          builder: (context, provider, _) {
            final items = provider.notifications;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 16, 12),
                  child: Row(
                    children: [
                      Expanded(child: Text('Notifications', style: theme.textTheme.headlineMedium)),
                      TextButton(
                        onPressed: provider.unreadCount == 0 ? null : provider.markAllAsRead,
                        child: const Text('Mark all read'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: items.isEmpty
                      ? const Center(child: Text('No notifications yet.'))
                      : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final n = items[index];
                      return ListTile(
                        tileColor: n.isRead ? null : theme.colorScheme.primary.withValues(alpha: 0.05),
                        contentPadding: const EdgeInsets.only(left: 20, right: 8, top: 6, bottom: 6),
                        leading: CircleAvatar(
                          backgroundColor: n.color.withValues(alpha: 0.1),
                          child: Icon(n.icon, color: n.color, size: 20),
                        ),
                        title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                        subtitle: Text(n.message, maxLines: 3, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => provider.remove(n.id),
                        ),
                        onTap: () {
                          provider.markAsRead(n.id);
                          _scaffoldKey.currentState?.closeEndDrawer();
                          context.go(n.routeFor(isStaff: !isResident));
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: items.isEmpty ? null : provider.clearAll,
                      child: const Text('Clear all notifications'),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Menu for narrow windows / phones, where the side rail is hidden.
  Widget _buildNavDrawer(BuildContext context, bool isResident, int selectedIndex) {
    final destinations = isResident ? _buildResidentDestinations() : _buildAdminDestinations();
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const BrandLogo(size: 40),
                  const SizedBox(width: 12),
                  Text('BaraTrack',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Theme.of(context).colorScheme.primary)),
                ],
              ),
            ),
            const Divider(),
            for (var i = 0; i < destinations.length; i++)
              ListTile(
                leading: i == selectedIndex ? (destinations[i].selectedIcon ?? destinations[i].icon) : destinations[i].icon,
                title: destinations[i].label,
                selected: i == selectedIndex,
                onTap: () {
                  Navigator.of(context).pop();
                  _onItemTapped(i, context, isResident);
                },
              ),
          ],
        ),
      ),
    );
  }

  List<NavigationRailDestination> _buildResidentDestinations() => const [
    NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
    NavigationRailDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: Text('My Complaints')),
    NavigationRailDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: Text('My Hearings')),
    NavigationRailDestination(icon: Icon(Icons.file_present_outlined), selectedIcon: Icon(Icons.file_present), label: Text('My Documents')),
    NavigationRailDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: Text('Notifications')),
    NavigationRailDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: Text('Announcements')),
    NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('My Profile')),
    NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
  ];

  List<NavigationRailDestination> _buildAdminDestinations() => const [
    NavigationRailDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: Text('Dashboard')),
    NavigationRailDestination(icon: Icon(Icons.inbox_outlined), selectedIcon: Icon(Icons.inbox), label: Text('Complaints Inbox')),
    NavigationRailDestination(icon: Icon(Icons.folder_shared_outlined), selectedIcon: Icon(Icons.folder_shared), label: Text('Blotter Records')),
    NavigationRailDestination(icon: Icon(Icons.people_outlined), selectedIcon: Icon(Icons.people), label: Text('Residents')),
    NavigationRailDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: Text('Hearings')),
    NavigationRailDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: Text('Announcements')),
    NavigationRailDestination(icon: Icon(Icons.summarize_outlined), selectedIcon: Icon(Icons.summarize), label: Text('Reports')),
    NavigationRailDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: Text('Incident Map')),
    NavigationRailDestination(icon: Icon(Icons.manage_accounts_outlined), selectedIcon: Icon(Icons.manage_accounts), label: Text('Users')),
    NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
  ];

  Widget _buildSidebarLogo(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: const BrandLogo(size: 48),
    );
  }
}
