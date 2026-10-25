import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/hearing_provider.dart';
import '../../../config/app_theme.dart';
import 'hearing_details_dialog.dart';

class MyHearingsView extends StatefulWidget {
  const MyHearingsView({super.key});

  @override
  State<MyHearingsView> createState() => _MyHearingsViewState();
}

class _MyHearingsViewState extends State<MyHearingsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HearingProvider>().fetchHearings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hearingProvider = context.watch<HearingProvider>();
    final hearings = hearingProvider.hearings;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Hearing Schedules', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Hearings',
                onPressed: () => context.read<HearingProvider>().fetchHearings(),
              ),
            ],
          ),
          const Text('Stay updated with your upcoming sessions at the Barangay Hall.'),
          const SizedBox(height: 32),
          Expanded(
            child: hearingProvider.isLoading && hearings.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : hearingProvider.error != null && hearings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error: ${hearingProvider.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context.read<HearingProvider>().fetchHearings(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => context.read<HearingProvider>().fetchHearings(),
                        child: hearings.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(
                                    height: 300,
                                    child: Center(
                                      child: Text('No hearings scheduled.'),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: hearings.length,
                                itemBuilder: (context, index) {
                                  final h = hearings[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: InkWell(
                                      onTap: () => HearingDetailsDialog.show(context, h),
                                      borderRadius: BorderRadius.circular(16),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(16),
                                        leading: Container(
                                          width: 60,
                                          decoration: BoxDecoration(
                                            color: context.brand.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(DateFormat('MMM').format(h.hearingDate).toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.brand)),
                                              Text(DateFormat('dd').format(h.hearingDate), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.brand)),
                                            ],
                                          ),
                                        ),
                                        title: Text('Case #${h.caseNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text('${h.hearingTime} @ ${h.venue}'),
                                        trailing: const Icon(Icons.chevron_right),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}
