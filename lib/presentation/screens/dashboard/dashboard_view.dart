import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/hearing_provider.dart';
import '../../providers/case_provider.dart';
import '../../providers/resident_provider.dart';
import '../../providers/reports_provider.dart';
import '../../../config/app_theme.dart';

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
    final caseProvider = context.watch<CaseProvider>();
    final reportsProvider = context.watch<ReportsProvider>();
    final residentProvider = context.watch<ResidentProvider>();

    final cases = caseProvider.cases;
    final hearings = context.watch<HearingProvider>().hearings;
    final residents = residentProvider.residents;
    final reportData = reportsProvider.reportData;

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
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, theme),
            const SizedBox(height: 28),
            if (caseProvider.isLoading && cases.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              _buildMetricGrid(context, theme, cases, hearings, residents),
            const SizedBox(height: 32),
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

  Widget _buildMetricGrid(BuildContext context, ThemeData theme, List cases, List hearings, List residents) {
    final pendingCount = cases.where((e) => e.status == 'Pending').length;
    final investigationCount = cases.where((e) => e.status == 'Under Investigation' || e.status == 'In Investigation').length;
    final settledCount = cases.where((e) => e.status == 'Settled').length;

    return LayoutBuilder(builder: (context, c) {
      return GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: c.maxWidth > 1400 ? 6 : (c.maxWidth > 800 ? 3 : 2),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          mainAxisExtent: 104,
        ),
        children: [
          _metric(theme, 'Total Cases', '${cases.length}', Icons.folder_outlined, AppTheme.burstBlue, () => context.go('/cases')),
          _metric(theme, 'Pending', '$pendingCount', Icons.pending_outlined, AppTheme.burstOrange, () => context.go('/cases?status=Pending')),
          _metric(theme, 'In Investigation', '$investigationCount', Icons.search, Colors.purple, () => context.go('/cases?status=Under Investigation')),
          _metric(theme, 'Settled', '$settledCount', Icons.verified_outlined, AppTheme.laurelGreen, () => context.go('/cases?status=Settled')),
          _metric(theme, 'Residents', '${residents.length}', Icons.people_outline, AppTheme.burstTeal, () => context.go('/residents')),
          _metric(theme, 'Hearings', '${hearings.length}', Icons.gavel_outlined, context.brand, () => context.go('/hearings-mgmt')),
        ],
      );
    });
  }

  Widget _metric(ThemeData t, String l, String v, IconData i, Color c, VoidCallback onTap) => Card(
    clipBehavior: Clip.antiAlias,
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(14)),
              child: Icon(i, color: AppTheme.onColor(c), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(v, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.1)),
                const SizedBox(height: 2),
                Text(l, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface.withValues(alpha: 0.6))),
              ]),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    final primary = theme.colorScheme.primary;
    final on = AppTheme.onColor(primary);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, AppTheme.deepen(primary, 0.3)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Row(
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
