import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/version_provider.dart';
import '../providers/locale_provider.dart';
import '../../config/app_constants.dart';
import '../../config/app_theme.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/hover_pop.dart';
import '../../core/network/connectivity_provider.dart';
import '../../data/repositories/offline_queue_repository.dart';
import 'emergency/emergency_hotlines_modal.dart';

class _NavItem {
  final int index;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavItem({
    required this.index,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class _NavSection {
  final String id;
  final String title;
  final List<_NavItem> items;

  const _NavSection({
    required this.id,
    required this.title,
    required this.items,
  });
}

class MainShell extends StatefulWidget {
  final Widget? child;
  const MainShell({super.key, this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _notificationTimer;
  bool _sidebarExpanded = true;
  final Set<String> _collapsedGroups = {};

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

  (_NavItem, List<_NavSection>) _navMenu(BuildContext context, bool isResident) {
    final locale = context.watch<LocaleProvider>();
    final isFil = locale.isFilipino;
    final role = context.watch<AuthProvider>().user?.role;

    if (isResident) {
      final top = _NavItem(
        index: 0,
        label: locale.tr('tab_home'),
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
      );
      final sections = [
        _NavSection(
          id: 'my_cases',
          title: isFil ? 'AKING MGA KASO' : 'MY CASES',
          items: [
            _NavItem(
              index: 2,
              label: isFil ? 'Reklamo' : 'Complaints',
              icon: Icons.assignment_outlined,
              selectedIcon: Icons.assignment_rounded,
            ),
            _NavItem(
              index: 3,
              label: locale.tr('tab_hearings'),
              icon: Icons.gavel_outlined,
              selectedIcon: Icons.gavel_rounded,
            ),
            _NavItem(
              index: 1,
              label: locale.tr('tab_calendar'),
              icon: Icons.calendar_today_outlined,
              selectedIcon: Icons.calendar_today,
            ),
            _NavItem(
              index: 4,
              label: isFil ? 'Mga Dokumento' : 'Documents',
              icon: Icons.file_present_outlined,
              selectedIcon: Icons.file_present_rounded,
            ),
          ],
        ),
        _NavSection(
          id: 'community',
          title: isFil ? 'KOMUNIDAD' : 'COMMUNITY',
          items: [
            _NavItem(
              index: 6,
              label: isFil ? 'Mga Abiso at Balita' : 'Announcements',
              icon: Icons.campaign_outlined,
              selectedIcon: Icons.campaign_rounded,
            ),
            _NavItem(
              index: 5,
              label: locale.tr('notifications'),
              icon: Icons.notifications_outlined,
              selectedIcon: Icons.notifications_rounded,
            ),
          ],
        ),
        _NavSection(
          id: 'account',
          title: isFil ? 'AKAWNT' : 'ACCOUNT',
          items: [
            _NavItem(
              index: 7,
              label: isFil ? 'Aking Profile' : 'My Profile',
              icon: Icons.person_outline,
              selectedIcon: Icons.person_rounded,
            ),
            _NavItem(
              index: 8,
              label: locale.tr('settings_title'),
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings_rounded,
            ),
          ],
        ),
      ];
      return (top, sections);
    }

    final top = _NavItem(
      index: 0,
      label: locale.tr('tab_dashboard'),
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
    );
    final sections = [
      _NavSection(
        id: 'cases_blotter',
        title: isFil ? 'MGA KASO AT BLOTTER' : 'CASES & BLOTTER',
        items: [
          _NavItem(
            index: 2,
            label: locale.tr('tab_inbox'),
            icon: Icons.inbox_outlined,
            selectedIcon: Icons.inbox_rounded,
          ),
          _NavItem(
            index: 3,
            label: locale.tr('tab_cases'),
            icon: Icons.folder_outlined,
            selectedIcon: Icons.folder_rounded,
          ),
          _NavItem(
            index: 5,
            label: locale.tr('tab_hearings'),
            icon: Icons.gavel_outlined,
            selectedIcon: Icons.gavel_rounded,
          ),
          _NavItem(
            index: 1,
            label: locale.tr('tab_calendar'),
            icon: Icons.calendar_today_outlined,
            selectedIcon: Icons.calendar_today,
          ),
        ],
      ),
      _NavSection(
        id: 'community',
        title: isFil ? 'KOMUNIDAD' : 'COMMUNITY',
        items: [
          _NavItem(
            index: 4,
            label: isFil ? 'Mga Residente' : 'Residents',
            icon: Icons.people_outline,
            selectedIcon: Icons.people_rounded,
          ),
          _NavItem(
            index: 6,
            label: isFil ? 'Mga Anunsyo' : 'Announcements',
            icon: Icons.campaign_outlined,
            selectedIcon: Icons.campaign_rounded,
          ),
          _NavItem(
            index: 8,
            label: isFil ? 'Mapa ng Insidente' : 'Incident Map',
            icon: Icons.map_outlined,
            selectedIcon: Icons.map_rounded,
          ),
        ],
      ),
      _NavSection(
        id: 'system',
        title: isFil ? 'SISTEMA' : 'SYSTEM',
        items: [
          _NavItem(
            index: 7,
            label: isFil ? 'Mga Ulat (LTIA)' : 'Reports',
            icon: Icons.bar_chart_outlined,
            selectedIcon: Icons.bar_chart_rounded,
          ),
          if (role == 'Admin')
            _NavItem(
              index: 9,
              label: isFil ? 'Mga Gumagamit' : 'Users',
              icon: Icons.manage_accounts_outlined,
              selectedIcon: Icons.manage_accounts_rounded,
            ),
          _NavItem(
            index: 10,
            label: locale.tr('settings_title'),
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings_rounded,
          ),
        ],
      ),
    ];
    return (top, sections);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isResident = user?.role == 'Resident';
    final isMobile = MediaQuery.of(context).size.width < 1000;
    final selectedIndex = _getSelectedIndex(context, isResident);

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile ? _buildNavDrawer(context, isResident, selectedIndex) : null,
      endDrawer: _buildNotificationDrawer(context, isResident),
      bottomNavigationBar: isMobile ? _buildBottomBar(context, isResident, selectedIndex) : null,
      body: Row(
        children: [
          if (!isMobile) _buildExpandableSidebar(context, isResident, selectedIndex),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, user, isMobile),
                Expanded(
                  child: SafeArea(
                    top: false,
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

  /// Desktop & wide tablet expandable grouped sidebar (matches approved design).
  Widget _buildExpandableSidebar(BuildContext context, bool isResident, int selectedIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.watch<LocaleProvider>();
    final isFil = locale.isFilipino;
    final user = context.watch<AuthProvider>().user;
    final (topItem, sections) = _navMenu(context, isResident);
    final sidebarBg = isDark ? const Color(0xFF121214) : AppTheme.surfaceLight;
    final borderColor = isDark ? const Color(0xFF24252C) : AppTheme.borderLight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: _sidebarExpanded ? 236.0 : 72.0,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            // Sidebar Brand + Expand/Collapse Chevron Toggle
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _sidebarExpanded ? 14 : 12,
                vertical: 12,
              ),
              child: Row(
                mainAxisAlignment: _sidebarExpanded
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.center,
                children: [
                  if (_sidebarExpanded)
                    Expanded(
                      child: Row(
                        children: [
                          const BrandLogo(size: 30),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'BaraTrack',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  user?.role == 'Resident'
                                      ? (isFil ? 'Residente' : 'Resident')
                                      : (isFil ? 'Kawani ng Barangay' : 'Barangay Staff'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFFA1A1AA) : AppTheme.textHintLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  HoverPop(
                    hoverScale: 1.12,
                    child: Tooltip(
                      message: _sidebarExpanded
                          ? (isFil ? 'Paliitin ang sidebar' : 'Collapse sidebar')
                          : (isFil ? 'Palawakin ang sidebar' : 'Expand sidebar'),
                      child: InkWell(
                        onTap: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? const Color(0xFF1E1F25) : const Color(0xFFF1F5F9),
                            border: Border.all(color: borderColor),
                          ),
                          child: AnimatedRotation(
                            turns: _sidebarExpanded ? 0.0 : 0.5,
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            child: Icon(
                              Icons.chevron_left_rounded,
                              size: 18,
                              color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Top Featured Item (Dashboard / Home)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: _buildSidebarNavButton(
                context: context,
                item: topItem,
                isSelected: selectedIndex == topItem.index,
                expanded: _sidebarExpanded,
                isDark: isDark,
                onTap: () => _onItemTapped(topItem.index, context, isResident),
              ),
            ),

            // Grouped Navigation Sections
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final section in sections) ...[
                      const SizedBox(height: 8),
                      _buildSectionHeader(
                        section: section,
                        expanded: _sidebarExpanded,
                        isDark: isDark,
                        borderColor: borderColor,
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        child: (!_sidebarExpanded || !_collapsedGroups.contains(section.id))
                            ? Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Column(
                                  children: [
                                    for (final item in section.items) ...[
                                      const SizedBox(height: 2),
                                      _buildSidebarNavButton(
                                        context: context,
                                        item: item,
                                        isSelected: selectedIndex == item.index,
                                        expanded: _sidebarExpanded,
                                        isDark: isDark,
                                        onTap: () => _onItemTapped(item.index, context, isResident),
                                      ),
                                    ],
                                  ],
                                ),
                              )
                            : const SizedBox(width: double.infinity, height: 0),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            Divider(height: 1, color: borderColor),

            // Bottom Pinned Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  _buildSidebarUtilityButton(
                    icon: Icons.phone_in_talk_rounded,
                    label: isFil ? 'Emergency Hotlines' : 'Emergency Hotlines',
                    badgeText: '24/7',
                    iconColor: isDark ? AppTheme.crimsonDarkAccent : AppTheme.brand500,
                    expanded: _sidebarExpanded,
                    isDark: isDark,
                    onTap: () => EmergencyHotlinesModal.show(context),
                  ),
                  const SizedBox(height: 4),
                  Consumer<OfflineQueueRepository>(
                    builder: (context, queueRepo, _) {
                      final count = queueRepo.draftCount;
                      return _buildSidebarUtilityButton(
                        icon: Icons.cloud_sync_outlined,
                        label: isResident
                            ? (isFil ? 'Mga Draft Offline' : 'Offline Drafts')
                            : (isFil ? 'Nakabinbing Sync' : 'Pending Sync'),
                        badgeText: count > 0 ? '$count' : null,
                        badgeFilled: count > 0,
                        iconColor: isDark ? AppTheme.crimsonDarkAccent : AppTheme.brand500,
                        expanded: _sidebarExpanded,
                        isDark: isDark,
                        onTap: () => context.push('/offline-drafts'),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  _buildSidebarUtilityButton(
                    icon: Icons.logout_rounded,
                    label: isFil ? 'Mag-sign Out' : 'Log out',
                    iconColor: AppTheme.error,
                    textColor: AppTheme.error,
                    expanded: _sidebarExpanded,
                    isDark: isDark,
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required _NavSection section,
    required bool expanded,
    required bool isDark,
    required Color borderColor,
  }) {
    final mutedSection = isDark ? const Color(0xFF71717A) : AppTheme.textHintLight;
    final isGroupCollapsed = _collapsedGroups.contains(section.id);

    if (!expanded) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            width: 24,
            height: 1,
            color: borderColor,
          ),
        ),
      );
    }

    return InkWell(
      onTap: () {
        setState(() {
          if (isGroupCollapsed) {
            _collapsedGroups.remove(section.id);
          } else {
            _collapsedGroups.add(section.id);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 6, 18, 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                section.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                  color: mutedSection,
                ),
              ),
            ),
            AnimatedRotation(
              turns: isGroupCollapsed ? -0.25 : 0.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: mutedSection),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarNavButton({
    required BuildContext context,
    required _NavItem item,
    required bool isSelected,
    required bool expanded,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeBorder = isDark
        ? Colors.white.withValues(alpha: 0.92)
        : AppTheme.brand700;
    final inactiveText = isDark ? const Color(0xFFD4D4D8) : AppTheme.textSecondaryLight;
    final inactiveIcon = isDark ? const Color(0xFFA1A1AA) : AppTheme.textHintLight;

    final button = HoverPop(
      hoverScale: expanded ? 1.03 : 1.08,
      slideX: expanded && !isSelected ? 0.025 : 0.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: isSelected
              ? Colors.transparent
              : (isDark ? Colors.white.withValues(alpha: 0.07) : AppTheme.brand500.withValues(alpha: 0.07)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            constraints: BoxConstraints(minHeight: isSelected ? 44 : 40),
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? 12 : 0,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.brand500 : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? activeBorder : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.brand500.withValues(alpha: isDark ? 0.42 : 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: expanded
                ? Row(
                    children: [
                      Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        size: 20,
                        color: isSelected ? Colors.white : inactiveIcon,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : inactiveText,
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Icon(
                      isSelected ? item.selectedIcon : item.icon,
                      size: 21,
                      color: isSelected ? Colors.white : inactiveIcon,
                    ),
                  ),
          ),
        ),
      ),
    );

    return expanded
        ? button
        : Tooltip(
            message: item.label,
            preferBelow: false,
            waitDuration: const Duration(milliseconds: 120),
            child: button,
          );
  }

  Widget _buildSidebarUtilityButton({
    required IconData icon,
    required String label,
    String? badgeText,
    bool badgeFilled = false,
    required Color iconColor,
    Color? textColor,
    required bool expanded,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final child = HoverPop(
      hoverScale: expanded ? 1.025 : 1.08,
      slideX: expanded ? 0.02 : 0.0,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 0, vertical: 8),
            child: expanded
                ? Row(
                    children: [
                      Icon(icon, size: 19, color: iconColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: textColor ?? (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                          ),
                        ),
                      ),
                      if (badgeText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeFilled ? AppTheme.brand500 : iconColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: badgeFilled ? Colors.white : iconColor,
                            ),
                          ),
                        ),
                    ],
                  )
                : Center(
                    child: Badge(
                      isLabelVisible: badgeFilled && badgeText != null,
                      label: Text(badgeText ?? ''),
                      child: Icon(icon, size: 20, color: iconColor),
                    ),
                  ),
          ),
        ),
      ),
    );

    return expanded
        ? child
        : Tooltip(
            message: label,
            waitDuration: const Duration(milliseconds: 120),
            child: child,
          );
  }

  /// Phone navigation: floating pill inset from edges with rounded corners and soft shadow.
  Widget _buildBottomBar(BuildContext context, bool isResident, int selectedIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.watch<LocaleProvider>();
    final items = isResident
        ? [
            (locale.tr('tab_home'), Icons.home_outlined, Icons.home),
            (locale.tr('tab_calendar'), Icons.calendar_today_outlined, Icons.calendar_today),
            (locale.isFilipino ? 'Reklamo' : 'Complaints', Icons.assignment_outlined, Icons.assignment),
            (locale.tr('tab_hearings'), Icons.gavel_outlined, Icons.gavel),
          ]
        : [
            (locale.tr('tab_dashboard'), Icons.dashboard_outlined, Icons.dashboard),
            (locale.tr('tab_calendar'), Icons.calendar_today_outlined, Icons.calendar_today),
            (locale.tr('tab_inbox'), Icons.inbox_outlined, Icons.inbox),
            (locale.tr('tab_cases'), Icons.folder_outlined, Icons.folder),
          ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: NavigationBar(
            height: 62,
            backgroundColor: Colors.transparent,
            elevation: 0,
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
              for (int idx = 0; idx < items.length; idx++)
                NavigationDestination(
                  icon: Semantics(
                    label: items[idx].$1,
                    selected: selectedIndex == idx,
                    child: Icon(items[idx].$2, size: 22),
                  ),
                  selectedIcon: Semantics(
                    label: items[idx].$1,
                    selected: true,
                    child: Icon(items[idx].$3, size: 22),
                  ),
                  label: items[idx].$1,
                ),
              NavigationDestination(
                icon: Semantics(
                  label: locale.tr('tab_more'),
                  child: const Icon(Icons.menu, size: 22),
                ),
                label: locale.tr('tab_more'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, user, bool isMobile) {
    final theme = Theme.of(context);
    final isResident = user?.role == 'Resident';
    final locale = context.watch<LocaleProvider>();
    final isFil = locale.isFilipino;
    final width = MediaQuery.of(context).size.width;
    final topInset = MediaQuery.of(context).padding.top;
    final compact = width < 600;
    final tiny = width < 400;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 70 + topInset,
      padding: EdgeInsets.fromLTRB(compact ? 4 : 24, topInset, compact ? 4 : 24, 0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          if (isMobile && !compact)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          if (compact) const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    'BaraTrack',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: compact ? 19 : 22,
                      color: theme.colorScheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                SizedBox(width: compact ? 8 : 36),
                if (isResident)
                  HoverPop(
                    hoverScale: 1.03,
                    child: tiny
                        ? IconButton.filled(
                            tooltip: isFil ? 'Bagong Reklamo' : 'New Complaint',
                            onPressed: () => context.push('/file-complaint'),
                            icon: const Icon(Icons.add),
                          )
                        : ElevatedButton.icon(
                            onPressed: () => context.push('/file-complaint'),
                            icon: const Icon(Icons.add, size: 20),
                            label: Text(
                              compact
                                  ? (isFil ? 'Bago' : 'New')
                                  : (isFil ? 'Bagong Reklamo' : 'New Complaint'),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                  ),
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
          HoverPop(
            hoverScale: 1.05,
            child: InkWell(
              onTap: () => EmergencyHotlinesModal.show(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: compact ? 2 : 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFFFF6B6E) : AppTheme.brand500).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isDark ? const Color(0xFFFF6B6E) : AppTheme.brand500).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.phone_in_talk_rounded,
                      size: 14,
                      color: isDark ? const Color(0xFFFF6B6E) : AppTheme.brand500,
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 4),
                      Text(
                        'Hotlines',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFFF6B6E) : AppTheme.brand500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Builder(builder: (context) {
            final unread = context.watch<NotificationProvider>().unreadCount;
            return HoverPop(
              hoverScale: 1.08,
              child: IconButton(
                tooltip: locale.tr('notifications'),
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text(unread > 99 ? '99+' : '$unread'),
                  child: Icon(Icons.notifications_none, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                onPressed: () {
                  context.read<NotificationProvider>().load();
                  _scaffoldKey.currentState?.openEndDrawer();
                },
              ),
            );
          }),
          SizedBox(width: compact ? 2 : 16),
          _buildUserMenu(context, user, isFil),
          SizedBox(width: compact ? 6 : 0),
        ],
      ),
    );
  }

  Widget _buildUserMenu(BuildContext context, user, bool isFil) {
    final theme = Theme.of(context);
    final String name = (user?.name as String?) ?? 'User';
    final String role = (user?.role as String?) ?? 'Role';
    final String? avatarUrl = user?.avatarUrl as String?;
    final ImageProvider? avatarProvider = (avatarUrl != null && avatarUrl.isNotEmpty)
        ? NetworkImage(avatarUrl.startsWith('http') ? avatarUrl : '${AppConstants.baseUrl}/$avatarUrl')
        : null;

    final avatar = CircleAvatar(
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
      backgroundImage: avatarProvider,
      radius: 18,
      child: avatarProvider == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
            )
          : null,
    );
    final profileRoute = role == 'Resident' ? '/profile' : '/settings';
    final profileLabel = role == 'Resident'
        ? (isFil ? 'Aking Profile' : 'My Profile')
        : context.read<LocaleProvider>().tr('settings_title');
    final logoutLabel = isFil ? 'Mag-sign Out' : 'Logout';

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
          PopupMenuItem<String>(child: Text(profileLabel), onTap: () => context.go(profileRoute)),
          PopupMenuItem<String>(child: Text(logoutLabel), onTap: () => _confirmLogout(context)),
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
            PopupMenuItem(child: Text(profileLabel), onTap: () => context.go(profileRoute)),
            PopupMenuItem(child: Text(logoutLabel), onTap: () => _confirmLogout(context)),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final queueRepo = context.read<OfflineQueueRepository>();
    final unsentCount = queueRepo.draftCount;
    final isFil = context.read<LocaleProvider>().isFilipino;

    if (unsentCount > 0) {
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
              const SizedBox(width: 8),
              Text(
                isFil ? 'Mga Draft na Hindi Naipadala' : 'Unsent Drafts',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            isFil
                ? 'Mayroon kang $unsentCount na draft na hindi pa nai-sync. Mabubura ang offline cache kung magsa-sign out.\n\nItuloy pa rin ang pag-sign out?'
                : 'You have $unsentCount unsent draft${unsentCount > 1 ? 's' : ''}. Logging out will clear your offline cache.\n\nLog out anyway?',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(isFil ? 'Kanselahin' : 'Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isFil ? 'Mag-sign Out pa rin' : 'Log out anyway'),
            ),
          ],
        ),
      );

      if (shouldLogout != true) return;
    }

    if (context.mounted) {
      await queueRepo.clearAll();
      if (context.mounted) {
        context.read<AuthProvider>().logout();
      }
    }
  }

  Widget _buildNotificationDrawer(BuildContext context, bool isResident) {
    final theme = Theme.of(context);
    final locale = context.watch<LocaleProvider>();
    final isFil = locale.isFilipino;

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
                      Expanded(child: Text(locale.tr('notifications'), style: theme.textTheme.headlineMedium)),
                      TextButton(
                        onPressed: provider.unreadCount == 0 ? null : provider.markAllAsRead,
                        child: Text(locale.tr('mark_all_read')),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: items.isEmpty
                      ? Center(child: Text(locale.tr('no_notifications')))
                      : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final n = items[index];
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 220 + (index.clamp(0, 6) * 45)),
                              curve: Curves.easeOutCubic,
                              builder: (context, t, child) => Opacity(
                                opacity: t,
                                child: Transform.translate(
                                  offset: Offset((1 - t) * 18, 0),
                                  child: child,
                                ),
                              ),
                              child: ListTile(
                                tileColor: n.isRead ? null : theme.colorScheme.primary.withValues(alpha: 0.05),
                                contentPadding: const EdgeInsets.only(left: 20, right: 8, top: 6, bottom: 6),
                                leading: CircleAvatar(
                                  backgroundColor: n.color.withValues(alpha: 0.1),
                                  child: Icon(n.icon, color: n.color, size: 20),
                                ),
                                title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                                subtitle: Text(n.message, maxLines: 3, overflow: TextOverflow.ellipsis),
                                trailing: IconButton(
                                  tooltip: isFil ? 'Alisin' : 'Remove',
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => provider.remove(n.id),
                                ),
                                onTap: () {
                                  provider.markAsRead(n.id);
                                  _scaffoldKey.currentState?.closeEndDrawer();
                                  context.go(n.routeFor(isStaff: !isResident));
                                },
                              ),
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
                      child: Text(locale.tr('clear_all')),
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

  // Mobile slide-out drawer matching the grouped sidebar layout with smooth staggered entrance.
  Widget _buildNavDrawer(BuildContext context, bool isResident, int selectedIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().user;
    final isFil = context.watch<LocaleProvider>().isFilipino;
    final (topItem, sections) = _navMenu(context, isResident);
    final drawerBg = isDark ? const Color(0xFF121214) : AppTheme.surfaceLight;
    final borderColor = isDark ? const Color(0xFF24252C) : AppTheme.borderLight;
    final accentRed = isDark ? AppTheme.crimsonDarkAccent : AppTheme.brand500;
    final roleText = user?.role == 'Resident'
        ? (isFil ? 'Residente' : 'Resident')
        : (isFil ? 'Kawani ng Barangay' : 'Barangay Staff');

    Widget animateRow(int order, Widget child) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 220 + (order.clamp(0, 10) * 28)),
        curve: Curves.easeOutCubic,
        builder: (context, t, w) => Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset((1 - t) * -14, 0), child: w),
        ),
        child: child,
      );
    }

    return Drawer(
      backgroundColor: drawerBg,
      child: SafeArea(
        child: Column(
          children: [
            // Header with Barangay logo, User's name (ellipsis), and role badge
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  const BrandLogo(size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user?.name ?? 'BaraTrack User',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1F25) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            roleText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFA1A1AA) : AppTheme.textSecondaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: borderColor),

            // Top Featured Pill + Grouped Sections
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: animateRow(
                      0,
                      _buildSidebarNavButton(
                        context: context,
                        item: topItem,
                        isSelected: selectedIndex == topItem.index,
                        expanded: true,
                        isDark: isDark,
                        onTap: () {
                          Navigator.of(context).pop();
                          _onItemTapped(topItem.index, context, isResident);
                        },
                      ),
                    ),
                  ),
                  for (int sIdx = 0; sIdx < sections.length; sIdx++) ...[
                    const SizedBox(height: 8),
                    _buildSectionHeader(
                      section: sections[sIdx],
                      expanded: true,
                      isDark: isDark,
                      borderColor: borderColor,
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      child: !_collapsedGroups.contains(sections[sIdx].id)
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Column(
                                children: [
                                  for (int iIdx = 0; iIdx < sections[sIdx].items.length; iIdx++) ...[
                                    const SizedBox(height: 2),
                                    animateRow(
                                      1 + sIdx * 3 + iIdx,
                                      _buildSidebarNavButton(
                                        context: context,
                                        item: sections[sIdx].items[iIdx],
                                        isSelected: selectedIndex == sections[sIdx].items[iIdx].index,
                                        expanded: true,
                                        isDark: isDark,
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          _onItemTapped(sections[sIdx].items[iIdx].index, context, isResident);
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : const SizedBox(width: double.infinity, height: 0),
                    ),
                  ],
                ],
              ),
            ),

            Divider(height: 1, color: borderColor),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Column(
                children: [
                  _buildSidebarUtilityButton(
                    icon: Icons.phone_in_talk_rounded,
                    label: 'Emergency Hotlines',
                    badgeText: '24/7',
                    iconColor: accentRed,
                    expanded: true,
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context).pop();
                      EmergencyHotlinesModal.show(context);
                    },
                  ),
                  const SizedBox(height: 4),
                  Consumer<OfflineQueueRepository>(
                    builder: (context, queueRepo, _) {
                      final count = queueRepo.draftCount;
                      return _buildSidebarUtilityButton(
                        icon: Icons.cloud_sync_outlined,
                        label: isResident
                            ? (isFil ? 'Mga Draft at Kasaysayan Offline' : 'Offline Drafts & History')
                            : (isFil ? 'Nakabinbing Sync' : 'Pending Sync'),
                        badgeText: count > 0 ? '$count' : null,
                        badgeFilled: count > 0,
                        iconColor: accentRed,
                        expanded: true,
                        isDark: isDark,
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/offline-drafts');
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  _buildSidebarUtilityButton(
                    icon: Icons.logout_rounded,
                    label: isFil ? 'Mag-sign Out' : 'Log out',
                    iconColor: AppTheme.error,
                    textColor: AppTheme.error,
                    expanded: true,
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context).pop();
                      _confirmLogout(context);
                    },
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
