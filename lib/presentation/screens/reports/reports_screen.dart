import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/reports_provider.dart';
import '../../../config/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReportsProvider>().fetchReports();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reportsProvider = context.watch<ReportsProvider>();
    final data = reportsProvider.reportData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => reportsProvider.fetchReports(),
          ),
        ],
      ),
      body: reportsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : reportsProvider.error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text('Error: ${reportsProvider.error}', textAlign: TextAlign.center),
                ))
              : data == null
                  ? const Center(child: Text('No report data available.'))
                  : RefreshIndicator(
                      onRefresh: () => reportsProvider.fetchReports(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryGrid(data, theme),
                            const SizedBox(height: 32),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: _buildCasesByStatus(data, theme)),
                                const SizedBox(width: 24),
                                Expanded(flex: 2, child: _buildHearingsSummary(data, theme)),
                              ],
                            ),
                            const SizedBox(height: 32),
                            _buildTrendChart(data, theme),
                            const SizedBox(height: 32),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildComplaintsByCategory(data, theme)),
                                const SizedBox(width: 24),
                                Expanded(child: _buildResidentsByZone(data, theme)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildSummaryGrid(Map<String, dynamic> data, ThemeData theme) {
    final totals = data['totals'] as Map<String, dynamic>? ?? {};
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2,
      children: [
        _statCard(theme, 'Total Residents', '${totals['residents'] ?? 0}', Icons.people, Colors.teal),
        _statCard(theme, 'Total Cases', '${totals['cases'] ?? 0}', Icons.folder, Colors.blue),
        _statCard(theme, 'Cases (Month)', '${data['cases_this_month'] ?? 0}', Icons.trending_up, Colors.orange),
        _statCard(theme, 'Complaints (Month)', '${data['complaints_this_month'] ?? 0}', Icons.assignment_late_outlined, Colors.redAccent),
      ],
    );
  }

  Widget _statCard(ThemeData theme, String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  Text(title, style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCasesByStatus(Map<String, dynamic> data, ThemeData theme) {
    final rawList = data['cases_by_status'];
    final list = rawList is List ? rawList : [];
    
    final Map<String, Color> colors = {
      'Pending': Colors.orange,
      'Under Investigation': Colors.purple,
      'Settled': Colors.green,
      'Closed': Colors.blueGrey,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cases by Current Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 32),
            if (list.isEmpty)
              const SizedBox(height: 200, child: Center(child: Text('No case data yet.')))
            else
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 40,
                    sections: list.map((item) {
                      final status = (item['status'] as String?) ?? 'Unknown';
                      final count = (item['count'] as num?)?.toDouble() ?? 0.0;
                      return PieChartSectionData(
                        color: colors[status] ?? Colors.grey,
                        value: count > 0 ? count : 0.1, // Prevent 0-value crashes in some fl_chart versions
                        title: '${count.toInt()}',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: list.map((item) {
                final status = (item['status'] as String?) ?? 'Unknown';
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, color: colors[status] ?? Colors.grey),
                    const SizedBox(width: 8),
                    Text(status, style: const TextStyle(fontSize: 12)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHearingsSummary(Map<String, dynamic> data, ThemeData theme) {
    final rawList = data['hearings_by_status'];
    final list = rawList is List ? rawList : [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hearing Health', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No scheduled hearings.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              )
            else
              ...list.map((item) {
                final status = (item['status'] as String?) ?? 'Unspecified';
                final count = (item['count'] as num?) ?? 0;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(status, style: const TextStyle(fontSize: 14)),
                  trailing: Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
                  dense: true,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart(Map<String, dynamic> data, ThemeData theme) {
    final rawTrend = data['cases_by_month'];
    final trend = rawTrend is List ? rawTrend : [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Case Filing Trend (Last 6 Months)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 40),
            if (trend.isEmpty)
              const SizedBox(height: 200, child: Center(child: Text('Insufficient trend data.')))
            else
              SizedBox(
                height: 250,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index < 0 || index >= trend.length) return const SizedBox();
                            final monthData = trend[index];
                            final dateStr = (monthData['month'] as String?) ?? '';
                            if (dateStr.isEmpty) return const SizedBox();
                            
                            String label = dateStr;
                            if (dateStr.contains('-')) {
                              label = dateStr.split('-')[1];
                            }
                            
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(label, style: const TextStyle(fontSize: 10)),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        preventCurveOverShooting: true,
                        curveSmoothness: 0.15,
                        color: theme.colorScheme.primary,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(show: true, color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                        spots: trend.asMap().entries.map((e) {
                          final count = (e.value['count'] as num?)?.toDouble() ?? 0.0;
                          return FlSpot(e.key.toDouble(), count);
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintsByCategory(Map<String, dynamic> data, ThemeData theme) {
    final rawList = data['complaints_by_category'];
    final list = rawList is List ? rawList : [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Complaints by Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 24),
            if (list.isEmpty)
              const Text('No categories recorded.', style: TextStyle(color: Colors.grey, fontSize: 13))
            else
              ...list.take(5).map((item) {
                final typeName = (item['type_name'] as String?) ?? 'Unknown Category';
                final count = (item['count'] as num?) ?? 0;
                final firstItem = list.first;
                final maxCount = firstItem != null ? ((firstItem['count'] as num?)?.toDouble() ?? 1.0) : 1.0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(typeName, style: const TextStyle(fontSize: 12)),
                          Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: count / (maxCount > 0 ? maxCount : 1),
                        backgroundColor: theme.dividerColor,
                        color: Colors.blueAccent,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildResidentsByZone(Map<String, dynamic> data, ThemeData theme) {
    final rawList = data['residents_by_zone'];
    final list = rawList is List ? rawList : [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Residents by Zone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 24),
            if (list.isEmpty)
              const SizedBox(height: 200, child: Center(child: Text('No zone data available.')))
            else
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index < 0 || index >= list.length) return const SizedBox();
                            final zone = (list[index]['zone'] as String?) ?? '?';
                            return Text('Z$zone', style: const TextStyle(fontSize: 10));
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: list.asMap().entries.map((e) {
                      final count = (e.value['count'] as num?)?.toDouble() ?? 0.0;
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: count,
                            color: Colors.teal,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          )
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
