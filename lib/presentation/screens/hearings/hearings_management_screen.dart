import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/hearing_provider.dart';
import '../../providers/case_provider.dart';
import '../../../data/models/hearing_model.dart';
import 'hearing_form_modal.dart';

class HearingsManagementScreen extends StatefulWidget {
  const HearingsManagementScreen({super.key});

  @override
  State<HearingsManagementScreen> createState() => _HearingsManagementScreenState();
}

class _HearingsManagementScreenState extends State<HearingsManagementScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Scheduled', 'Completed', 'Postponed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HearingProvider>().fetchHearings();
      context.read<CaseProvider>().fetchCases();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hearingProvider = context.watch<HearingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hearings Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => hearingProvider.fetchHearings(status: _selectedFilter),
          )
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: hearingProvider.isLoading && hearingProvider.hearings.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => hearingProvider.fetchHearings(status: _selectedFilter),
                    child: hearingProvider.hearings.isEmpty
                        ? _buildEmptyState(theme)
                        : _buildHearingsList(hearingProvider.hearings),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => HearingFormModal.show(context),
        label: const Text('Schedule Hearing'),
        icon: const Icon(Icons.add_alarm),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final filter = _filters[i];
          return ChoiceChip(
            label: Text(filter),
            selected: _selectedFilter == filter,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedFilter = filter);
                context.read<HearingProvider>().fetchHearings(status: filter);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildHearingsList(List<HearingModel> hearings) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: hearings.length,
      itemBuilder: (context, index) {
        final hearing = hearings[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => HearingFormModal.show(context, hearing: hearing),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  _buildDateBlock(hearing.hearingDate),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Case #${hearing.caseNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(hearing.hearingTime, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            const SizedBox(width: 12),
                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(hearing.venue, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(hearing.status),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateBlock(DateTime date) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('MMM').format(date).toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          Text(
            DateFormat('dd').format(date),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = Colors.blue;
    if (status == 'Completed') color = Colors.green;
    if (status == 'Cancelled') color = Colors.red;
    if (status == 'Postponed') color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy_outlined, size: 80, color: theme.disabledColor),
              const SizedBox(height: 16),
              const Text('No hearings found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Try changing your filter or schedule a new one.', style: TextStyle(color: theme.hintColor)),
            ],
          ),
        ),
      ],
    );
  }
}
