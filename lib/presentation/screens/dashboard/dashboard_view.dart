import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/hearing_provider.dart';
import '../../providers/case_provider.dart';
import '../../providers/resident_provider.dart';
import '../../providers/reports_provider.dart';
import '../../providers/locale_provider.dart';
import '../../../config/app_theme.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/hearing_model.dart';
import '../../../data/repositories/offline_queue_repository.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CaseProvider>().fetchCases();
        context.read<ResidentProvider>().fetchResidents();
        context.read<ReportsProvider>().fetchReports();
        context.read<HearingProvider>().fetchHearings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 700;
    final caseProvider = context.watch<CaseProvider>();
    final reportsProvider = context.watch<ReportsProvider>();
    final residentProvider = context.watch<ResidentProvider>();
    final hearingProvider = context.watch<HearingProvider>();
    final connectivity = context.watch<ConnectivityProvider>();
    final offlineQueue = context.watch<OfflineQueueRepository>();
    final localeProvider = context.watch<LocaleProvider>();

    final cases = caseProvider.cases;
    final hearings = hearingProvider.hearings;
    final residents = residentProvider.residents;
    final isOnline = connectivity.isOnline;
    final unsyncedCount = offlineQueue.draftCount;
    final lang = localeProvider.localeCode;

    final now = DateTime.now();
    final todayHearings = hearings.where((h) {
      return h.hearingDate.year == now.year &&
          h.hearingDate.month == now.month &&
          h.hearingDate.day == now.day;
    }).toList();
    final pendingCases = cases.where((c) => c.status == 'Pending').toList();

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          caseProvider.fetchCases(),
          residentProvider.fetchResidents(),
          context.read<ReportsProvider>().fetchReports(),
          context.read<HearingProvider>().fetchHearings(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, theme, isMobile),
            const SizedBox(height: AppTheme.space24),
            _buildTodaySection(
              context,
              theme,
              todayHearings,
              pendingCases.length,
              unsyncedCount,
              isOnline,
              lang,
              isMobile,
            ),
            const SizedBox(height: AppTheme.space24),
            if (caseProvider.isLoading && cases.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              _buildMetricGrid(context, theme, cases, hearings, residents),
            const SizedBox(height: 28),
            if (isMobile) ...[
              _buildUrgentActions(context, theme, cases),
              const SizedBox(height: 20),
              _buildAnalyticsShell(context, theme, reportsProvider),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildUrgentActions(context, theme, cases)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildAnalyticsShell(context, theme, reportsProvider)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySection(
    BuildContext context,
    ThemeData theme,
    List<HearingModel> todayHearings,
    int pendingCount,
    int unsyncedCount,
    bool isOnline,
    String lang,
    bool isMobile,
  ) {
    final primary = theme.colorScheme.primary;
    final isTagalog = lang == 'fil';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? AppTheme.space16 : AppTheme.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Header title + Live Connectivity Pill
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space8),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.today_rounded, color: primary, size: 20),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTagalog ? 'Mga Gawain Ngayong Araw' : "Today's Agenda & Queue",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: isMobile ? 16 : 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      DateFormat(isTagalog ? 'EEEE, d MMMM yyyy' : 'EEEE, MMMM d, yyyy')
                          .format(DateTime.now()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Live Online/Offline Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                  vertical: AppTheme.space4,
                ),
                decoration: BoxDecoration(
                  color: isOnline
                      ? AppTheme.laurelGreen.withValues(alpha: 0.12)
                      : AppTheme.burstOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOnline ? AppTheme.laurelGreen : AppTheme.burstOrange,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOnline ? AppTheme.laurelGreen : AppTheme.burstOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space4),
                    Text(
                      isOnline ? 'Online' : 'Offline Mode',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isOnline ? AppTheme.laurelGreen : AppTheme.burstOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Offline Unsynced Banner (if drafts exist)
          if (unsyncedCount > 0) ...[
            const SizedBox(height: AppTheme.space16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: AppTheme.burstOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.burstOrange.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off_rounded, color: AppTheme.accentOrange, size: 22),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Text(
                      isTagalog
                          ? 'May $unsyncedCount aksyon/draft na naghihintay ng sync sa server.'
                          : 'There are $unsyncedCount pending action(s) waiting for server sync.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  ElevatedButton(
                    onPressed: () => context.push('/offline-drafts'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(44, 44),
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      isTagalog ? 'Suriin' : 'View',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppTheme.space16),

          // Section 2: Summary Stats Pills
          Row(
            children: [
              Expanded(
                child: _todayMiniPill(
                  theme: theme,
                  icon: Icons.gavel_rounded,
                  label: isTagalog ? "Pagdinig Ngayon" : "Today's Hearings",
                  count: todayHearings.length,
                  color: primary,
                  onTap: () => context.go('/hearings-mgmt'),
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: _todayMiniPill(
                  theme: theme,
                  icon: Icons.mark_email_unread_outlined,
                  label: isTagalog ? "Nakahain / Pending" : "Pending Review",
                  count: pendingCount,
                  color: AppTheme.burstOrange,
                  onTap: () => context.go('/cases?status=Pending'),
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: _todayMiniPill(
                    theme: theme,
                    icon: Icons.sync_problem_rounded,
                    label: isTagalog ? "Offline Queue" : "Pending Sync",
                    count: unsyncedCount,
                    color: unsyncedCount > 0 ? AppTheme.burstOrange : AppTheme.laurelGreen,
                    onTap: () => context.push('/offline-drafts'),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: AppTheme.space16),

          // Section 3: Today's Hearings List or Empty Placeholder
          if (todayHearings.isNotEmpty) ...[
            Text(
              isTagalog ? 'Mga Nakatakdang Pagdinig Ngayong Araw:' : "Scheduled Hearings Today:",
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: AppTheme.space8),
            ...todayHearings.take(3).map((h) => _buildTodayHearingItem(context, theme, h, isTagalog)),
            if (todayHearings.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.space8),
                child: Center(
                  child: TextButton(
                    onPressed: () => context.go('/hearings-mgmt'),
                    style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                    child: Text(
                      isTagalog
                          ? 'Tingnan ang lahat ng ${todayHearings.length} na pagdinig →'
                          : 'View all ${todayHearings.length} hearings →',
                      style: TextStyle(fontWeight: FontWeight.w700, color: primary),
                    ),
                  ),
                ),
              ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: AppTheme.space16,
                horizontal: AppTheme.space16,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_available_rounded, color: AppTheme.laurelGreen, size: 28),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTagalog
                              ? 'Walang nakatakdang pagdinig ngayong araw'
                              : 'No hearings scheduled for today',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          isTagalog
                              ? 'Maayos at kalmado ang kalendaryo ng Lupon Tagapamayapa.'
                              : 'Lupon calendar is clear today.',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/hearings-mgmt'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      side: BorderSide(color: primary.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: Icon(Icons.add, size: 16, color: primary),
                    label: Text(
                      isTagalog ? 'Magtakda' : 'Schedule',
                      style: TextStyle(fontWeight: FontWeight.w700, color: primary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppTheme.space16),

          // Section 4: Quick Action Shortcuts (44px min touch target)
          Wrap(
            spacing: AppTheme.space8,
            runSpacing: AppTheme.space8,
            children: [
              _actionShortcutChip(
                context: context,
                icon: Icons.add_circle_outline_rounded,
                label: isTagalog ? 'Bagong Blotter' : 'New Case',
                onTap: () => context.go('/cases'),
                primary: true,
              ),
              _actionShortcutChip(
                context: context,
                icon: Icons.inbox_outlined,
                label: isTagalog ? 'Reklamo Inbox' : 'Complaints Inbox',
                onTap: () => context.go('/complaints-inbox'),
              ),
              _actionShortcutChip(
                context: context,
                icon: Icons.calendar_month_outlined,
                label: isTagalog ? 'Kalendaryo' : 'Calendar',
                onTap: () => context.go('/calendar'),
              ),
              _actionShortcutChip(
                context: context,
                icon: Icons.people_outline_rounded,
                label: isTagalog ? 'Mga Residente' : 'Residents',
                onTap: () => context.go('/residents'),
              ),
              _actionShortcutChip(
                context: context,
                icon: Icons.assessment_outlined,
                label: isTagalog ? 'Mga Ulat (LTIA)' : 'Reports',
                onTap: () {
                  if (!isOnline) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isTagalog
                              ? 'Kailangan ng koneksyon sa internet para makabuo ng pinakabagong ulat.'
                              : 'Internet connection required to generate live reports.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  context.go('/reports');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _todayMiniPill({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12, vertical: AppTheme.space12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: AppTheme.space8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayHearingItem(
    BuildContext context,
    ThemeData theme,
    HearingModel hearing,
    bool isTagalog,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space8),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space8,
              vertical: AppTheme.space4,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              hearing.hearingTime.isNotEmpty ? hearing.hearingTime : 'Oras N/A',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Case #${hearing.caseNumber}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  hearing.venue.isNotEmpty ? hearing.venue : 'Barangay Hall',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space8),
          StatusBadge(status: hearing.status),
          const SizedBox(width: AppTheme.space8),
          IconButton(
            onPressed: () => context.go('/hearings-mgmt'),
            icon: const Icon(Icons.chevron_right),
            tooltip: isTagalog ? 'Pamahalaan ang Pagdinig' : 'Manage Hearing',
          ),
        ],
      ),
    );
  }

  Widget _actionShortcutChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    final theme = Theme.of(context);
    final brand = theme.colorScheme.primary;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: primary ? brand : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12, vertical: AppTheme.space8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: primary
                    ? brand
                    : (theme.brightness == Brightness.dark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: primary ? Colors.white : theme.colorScheme.onSurface,
                ),
                const SizedBox(width: AppTheme.space8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: primary ? Colors.white : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricGrid(BuildContext context, ThemeData theme, List cases, List hearings, List residents) {
    final pendingCount = cases.where((e) => e.status == 'Pending').length;
    final investigationCount = cases.where((e) => e.status == 'Under Investigation' || e.status == 'In Investigation').length;
    final settledCount = cases.where((e) => e.status == 'Settled').length;

    return LayoutBuilder(builder: (context, c) {
      final isCompact = c.maxWidth < 600;
      return GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: c.maxWidth > 1400 ? 6 : (c.maxWidth > 800 ? 3 : 2),
          mainAxisSpacing: isCompact ? 10 : 16,
          crossAxisSpacing: isCompact ? 10 : 16,
          mainAxisExtent: isCompact ? 92 : 104,
        ),
        children: [
          _metric(theme, 'Total Cases', '${cases.length}', Icons.folder_outlined, AppTheme.burstBlue, () => context.go('/cases'), isCompact),
          _metric(theme, 'Pending', '$pendingCount', Icons.pending_outlined, AppTheme.burstOrange, () => context.go('/cases?status=Pending'), isCompact),
          _metric(theme, 'In Investigation', '$investigationCount', Icons.search, Colors.purple, () => context.go('/cases?status=Under Investigation'), isCompact),
          _metric(theme, 'Settled', '$settledCount', Icons.verified_outlined, AppTheme.laurelGreen, () => context.go('/cases?status=Settled'), isCompact),
          _metric(theme, 'Residents', '${residents.length}', Icons.people_outline, AppTheme.burstTeal, () => context.go('/residents'), isCompact),
          _metric(theme, 'Hearings', '${hearings.length}', Icons.gavel_outlined, context.brand, () => context.go('/hearings-mgmt'), isCompact),
        ],
      );
    });
  }

  Widget _metric(ThemeData t, String l, String v, IconData i, Color c, VoidCallback onTap, [bool isCompact = false]) => Card(
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isCompact ? 14 : 18)),
    child: InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [c.withValues(alpha: 0.14), c.withValues(alpha: 0.02)],
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 20),
        child: Row(
          children: [
            Container(
              width: isCompact ? 38 : 48,
              height: isCompact ? 38 : 48,
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(isCompact ? 10 : 14)),
              child: Icon(i, color: AppTheme.onColor(c), size: isCompact ? 20 : 24),
            ),
            SizedBox(width: isCompact ? 10 : 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(v, style: TextStyle(fontSize: isCompact ? 22 : 30, fontWeight: FontWeight.w800, height: 1.1)),
                const SizedBox(height: 2),
                Text(
                  l,
                  style: TextStyle(fontSize: isCompact ? 11 : 13, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface.withValues(alpha: 0.6)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ]),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildHeader(BuildContext context, ThemeData theme, [bool isMobile = false]) {
    final primary = theme.colorScheme.primary;
    final on = AppTheme.onColor(primary);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 32, vertical: isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, AppTheme.deepen(primary, 0.3)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('EEEE, MMMM d').format(DateTime.now()).toUpperCase(),
                    style: TextStyle(color: on.withValues(alpha: 0.75), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text('Command Center', style: TextStyle(color: on, fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Daily overview of barangay legal operations.', style: TextStyle(color: on.withValues(alpha: 0.85), fontSize: 13)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/cases'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Blotter Entry', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: on,
                      foregroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('EEEE, MMMM d').format(DateTime.now()).toUpperCase(),
                          style: TextStyle(color: on.withValues(alpha: 0.75), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                      const SizedBox(height: 6),
                      Text('Command Center', style: TextStyle(color: on, fontSize: 32, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('Daily overview of barangay legal operations.', style: TextStyle(color: on.withValues(alpha: 0.85), fontSize: 15)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => context.go('/cases'),
                  icon: const Icon(Icons.add),
                  label: const Text('New Blotter Entry'),
                  style: ElevatedButton.styleFrom(backgroundColor: on, foregroundColor: primary),
                ),
              ],
            ),
    );
  }

  Widget _buildUrgentActions(BuildContext context, ThemeData theme, List cases) {
    final urgentCases = cases.where((c) => c.status == 'Pending' || c.status == 'Under Investigation').toList();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.all(24), child: Text('🚨 Urgent Pending Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          const Divider(height: 1),
          if (urgentCases.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('All clear! No urgent actions.')))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: urgentCases.length > 5 ? 5 : urgentCases.length,
              itemBuilder: (context, i) {
                final item = urgentCases[i];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: (item.status == 'Pending' ? AppTheme.burstOrange : Colors.purple).withValues(alpha: 0.15),
                    child: Icon(item.status == 'Pending' ? Icons.hourglass_top : Icons.search,
                        size: 18, color: item.status == 'Pending' ? AppTheme.accentOrange : Colors.purple),
                  ),
                  title: Text('Case #${item.caseNumber} - ${item.status}'),
                  subtitle: Text(item.complaint?.typeName ?? 'Needs Review'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/cases/${item.id}'),
                );
              },
            ),
          Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                  child: TextButton(
                      onPressed: () => context.go('/cases?status=Pending'),
                      child: const Text('View Full Task List')
                  )
              )
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsShell(BuildContext context, ThemeData theme, ReportsProvider reportsProvider) {
    final data = reportsProvider.reportData;

    return Card(
      child: Container(
        height: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📈 Trend Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            if (reportsProvider.isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (data == null)
              const Expanded(child: Center(child: Text('Analytics Unavailable')))
            else ...[
                _compactTrendSummary(data),
                const SizedBox(height: 24),
                Expanded(child: _buildCompactBarChart(data, theme)),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/reports'),
                    child: const Text('Open Detailed Analytics'),
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _compactTrendSummary(Map<String, dynamic> data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _miniStat('Cases (Mo)', '${data['cases_this_month'] ?? 0}'),
        _miniStat('Complaints', '${data['complaints_this_month'] ?? 0}'),
      ],
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCompactBarChart(Map<String, dynamic> data, ThemeData theme) {
    final trend = data['cases_by_month'] as List? ?? [];
    if (trend.isEmpty) return const Center(child: Text('No data'));

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= trend.length) return const SizedBox();
                final month = trend[index]['month'].toString().split('-').last;
                return Text(month, style: const TextStyle(fontSize: 9));
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: trend.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: (e.value['count'] as num).toDouble(),
                color: theme.colorScheme.primary,
                width: 12,
                borderRadius: BorderRadius.circular(2),
              )
            ],
          );
        }).toList(),
      ),
    );
  }
}
