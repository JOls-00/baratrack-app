import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/version_provider.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/network/connectivity_provider.dart';
import '../../data/repositories/offline_queue_repository.dart';

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
      if (mounted) {
        context.read<NotificationProvider>().load();
        context.read<VersionProvider>().checkForUpdates(context: context);
      }
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
      if (location.startsWith('/calendar')) return 1;
      if (location.startsWith('/my-complaints')) return 2;
      if (location.startsWith('/my-hearings')) return 3;
      if (location.startsWith('/my-documents')) return 4;
      if (location.startsWith('/notifications')) return 5;
      if (location.startsWith('/app-announcements')) return 6;
      if (location.startsWith('/profile')) return 7;
      if (location.startsWith('/settings')) return 8;
      return 0;
    }

    if (location == '/') return 0;
    if (location.startsWith('/calendar')) return 1;
    if (location.startsWith('/complaints-inbox')) return 2;
    if (location.startsWith('/cases')) return 3;
    if (location.startsWith('/residents')) return 4;
    if (location.startsWith('/hearings-mgmt')) return 5;
    if (location.startsWith('/app-announcements')) return 6;
    if (location.startsWith('/reports')) return 7;
    if (location.startsWith('/incident-map')) return 8;
    if (location.startsWith('/users')) return 9;
    if (location.startsWith('/settings')) return 10;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, bool isResident) {
    if (isResident) {
      switch (index) {
        case 0: context.go('/'); break;
        case 1: context.go('/calendar'); break;
        case 2: context.go('/my-complaints'); break;
        case 3: context.go('/my-hearings'); break;
        case 4: context.go('/my-documents'); break;
        case 5: context.go('/notifications'); break;
        case 6: context.go('/app-announcements'); break;
        case 7: context.go('/profile'); break;
        case 8: context.go('/settings'); break;
      }
    } else {
      switch (index) {
        case 0: context.go('/'); break;
        case 1: context.go('/calendar'); break;
        case 2: context.go('/complaints-inbox'); break;
        case 3: context.go('/cases'); break;
        case 4: context.go('/residents'); break;
        case 5: context.go('/hearings-mgmt'); break;
        case 6: context.go('/app-announcements'); break;
        case 7: context.go('/reports'); break;
        case 8: context.go('/incident-map'); break;
        case 9: context.go('/users'); break;
        case 10: context.go('/settings'); break;
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
      bottomNavigationBar: isMobile ? _buildBottomBar(context, isResident, selectedIndex) : null,
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
                  child: SafeArea(
                    top: false, // the top bar already handles the status bar
                    child: widget.child ?? const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Phone navigation: four main places plus "More", which opens the full menu.
  Widget _buildBottomBar(BuildContext context, bool isResident, int selectedIndex) {
    final items = isResident
        ? const [
            ('Home', Icons.home_outlined, Icons.home),
            ('Calendar', Icons.calendar_today_outlined, Icons.calendar_today),
            ('Complaints', Icons.assignment_outlined, Icons.assignment),
            ('Hearings', Icons.gavel_outlined, Icons.gavel),
          ]
        : const [
            ('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
            ('Calendar', Icons.calendar_today_outlined, Icons.calendar_today),
            ('Inbox', Icons.inbox_outlined, Icons.inbox),
            ('Cases', Icons.folder_outlined, Icons.folder),
          ];
    return NavigationBar(
      selectedIndex: selectedIndex < 4 ? selectedIndex : 4,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (i) {
        if (i < 4) {
          _onItemTapped(i, context, isResident);
        } else {
          _scaffoldKey.currentState?.openDrawer();
        }
      },
      destinations: [
        for (final it in items) NavigationDestination(icon: Icon(it.$2), selectedIcon: Icon(it.$3), label: it.$1),
        const NavigationDestination(icon: Icon(Icons.menu), label: 'More'),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, user, bool isMobile) {
    final theme = Theme.of(context);
    final isResident = user?.role == 'Resident';
    final width = MediaQuery.of(context).size.width;
    final topInset = MediaQuery.of(context).padding.top; // status bar height (phones draw edge to edge)
    final compact = width < 600;
    final tiny = width < 400;

    return Container(
      height: 70 + topInset,
      padding: EdgeInsets.fromLTRB(compact ? 4 : 24, topInset, compact ? 4 : 24, 0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          // On phones the bottom bar has a "More" button that opens the menu; tablets keep the menu icon.
          if (isMobile && !compact) IconButton(icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
          if (compact) const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    'BaraTrack',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: compact ? 19 : 22, color: theme.colorScheme.primary, letterSpacing: -0.5),
                  ),
                ),
                SizedBox(width: compact ? 8 : 48),
                if (isResident)
                  (tiny
                      ? IconButton.filled(
                          tooltip: 'New Complaint',
                          onPressed: () => context.push('/file-complaint'),
                          icon: const Icon(Icons.add),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => context.push('/file-complaint'),
                          icon: const Icon(Icons.add, size: 20),
                          label: Text(compact ? 'New' : 'New Complaint', style: const TextStyle(fontWeight: FontWeight.bold)),
                        )),
              ],
            ),
          ),
          Consumer<ConnectivityProvider>(
            builder: (context, conn, _) {
              final isOnline = conn.isOnline;
              return Container(
                margin: EdgeInsets.symmetric(horizontal: compact ? 4 : 8),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isOnline ? const Color(0x1F10B981) : Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOnline ? const Color(0x4D10B981) : Colors.amber.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isOnline ? const Color(0xFF10B981) : Colors.amber.shade800,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isOnline ? const Color(0xFF047857) : Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
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
          SizedBox(width: compact ? 2 : 16),
          _buildUserMenu(context, user),
          SizedBox(width: compact ? 6 : 0),
        ],
      ),
    );
  }

  Widget _buildUserMenu(BuildContext context, user) {
    final theme = Theme.of(context);
    final String name = (user?.name as String?) ?? 'User';
    final String role = (user?.role as String?) ?? 'Role';
    final avatar = CircleAvatar(
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      radius: 18,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
    final profileRoute = role == 'Resident' ? '/profile' : '/settings';

    // Phones and narrow windows: tapping the avatar opens the account menu.
    if (MediaQuery.of(context).size.width <= 700) {
      return PopupMenuButton<String>(
        tooltip: 'Account',
        child: Padding(padding: const EdgeInsets.all(6), child: avatar),
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                Text(role, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(child: const Text('My Profile'), onTap: () => context.go(profileRoute)),
          PopupMenuItem<String>(child: const Text('Logout'), onTap: () => _confirmLogout(context)),
        ],
      );
    }

    return Row(
      children: [
        avatar,
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Text(role, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11)),
          ],
        ),
        const SizedBox(width: 4),
        PopupMenuButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          itemBuilder: (context) => [
            PopupMenuItem(child: const Text('My Profile'), onTap: () => context.go(profileRoute)),
            PopupMenuItem(child: const Text('Logout'), onTap: () => _confirmLogout(context)),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final queueRepo = context.read<OfflineQueueRepository>();
    final unsentCount = queueRepo.draftCount;

    if (unsentCount > 0) {
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
              const SizedBox(width: 8),
              const Text('Unsent Drafts', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'You have $unsentCount unsent draft${unsentCount > 1 ? 's' : ''}. Logging out will clear your offline cache.\n\nLog out anyway?',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Log out anyway'),
            ),
          ],
        ),
      );

      if (shouldLogout != true) return;
    }

    if (context.mounted) {
      // Clear offline cache and queued drafts on confirmed logout for privacy (Task 12)
      await queueRepo.clearAll();
      if (context.mounted) {
        context.read<AuthProvider>().logout();
      }
    }
  }

  Widget _buildNotificationDrawer(BuildContext context, bool isResident) {
    final theme = Theme.of(context);
    return Drawer(
      width: (MediaQuery.of(context).size.width * 0.9).clamp(280.0, 400.0).toDouble(),
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
                leading: i == selectedIndex ? destinations[i].selectedIcon : destinations[i].icon,
                title: destinations[i].label,
                selected: i == selectedIndex,
                onTap: () {
                  Navigator.of(context).pop();
                  _onItemTapped(i, context, isResident);
                },
              ),
            const Divider(),
            Consumer<OfflineQueueRepository>(
              builder: (context, queueRepo, _) {
                final count = queueRepo.draftCount;
                return ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined, color: Color(0xFFD61314)),
                  title: Text(isResident ? 'Offline Drafts & History' : 'Pending Sync'),
                  trailing: count > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD61314),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/offline-drafts');
                  },
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.of(context).pop();
                _confirmLogout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  List<NavigationRailDestination> _buildResidentDestinations() => const [
    NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
    NavigationRailDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: Text('Calendar')),
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
    NavigationRailDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: Text('Calendar')),
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
