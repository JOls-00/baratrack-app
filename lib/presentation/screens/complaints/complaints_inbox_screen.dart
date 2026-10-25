import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/case_provider.dart';
import 'complaint_details_dialog.dart';

class ComplaintsInboxScreen extends StatefulWidget {
  const ComplaintsInboxScreen({super.key});

  @override
  State<ComplaintsInboxScreen> createState() => _ComplaintsInboxScreenState();
}

class _ComplaintsInboxScreenState extends State<ComplaintsInboxScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint("DEBUG: ComplaintsInboxScreen.initState");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint("DEBUG: ComplaintsInboxScreen fetching complaints");
        context.read<ComplaintProvider>().fetchMyComplaints().catchError((e) {
          debugPrint("DEBUG: ComplaintsInboxScreen fetch error: $e");
        });
      }
    });
  }

  Future<void> _convertToCase(int complaintId) async {
    debugPrint("DEBUG: _convertToCase starting for ID: $complaintId");
    
    // 1. Show the loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final caseProvider = context.read<CaseProvider>();
      final complaintProvider = context.read<ComplaintProvider>();

      debugPrint("DEBUG: Calling caseProvider.convertToCase");
      await caseProvider.convertToCase(complaintId);
      debugPrint("DEBUG: caseProvider.convertToCase finished");
      
      if (!mounted) {
        debugPrint("DEBUG: ComplaintsInboxScreen no longer mounted after await");
        return;
      }

      // 2. Safely close the dialog only
      Navigator.of(context, rootNavigator: true).pop();
      debugPrint("DEBUG: Loader closed");
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully converted to Case!'), 
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // 3. Refresh the local complaints list
      debugPrint("DEBUG: Refreshing complaints list");
      await complaintProvider.fetchMyComplaints();
      debugPrint("DEBUG: Complaints list refreshed");
      
    } catch (e) {
      debugPrint("DEBUG: _convertToCase error: $e");
      if (mounted) {
        // Attempt to close only the dialog if it's still open
        Navigator.of(context, rootNavigator: true).maybePop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("DEBUG: ComplaintsInboxScreen.build");
    final theme = Theme.of(context);
    final complaintProvider = context.watch<ComplaintProvider>();
    final pendingComplaints = complaintProvider.myComplaints.where((c) => c.status == 'Pending').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => complaintProvider.fetchMyComplaints(),
          )
        ],
      ),
      body: complaintProvider.isLoading && pendingComplaints.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => complaintProvider.fetchMyComplaints(),
              child: pendingComplaints.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: pendingComplaints.length,
                      itemBuilder: (context, index) {
                        final complaint = pendingComplaints[index];
                        return Card(
                          key: ValueKey(complaint.id),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange.withValues(alpha: 0.1),
                              child: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                            ),
                            title: Text(
                              complaint.typeName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('From: ${complaint.complainant?.fullName ?? "Unknown"}'),
                                Text('Against: ${complaint.respondent?.fullName ?? "Unidentified / Unknown"}'),
                                Text(
                                  'Filed: ${DateFormat('MMM dd, yyyy').format(complaint.dateFiled)}',
                                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                                ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _convertToCase(complaint.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Convert to Case'),
                            ),
                            onTap: () => ComplaintDetailsDialog.show(context, complaint),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return ListView(
      shrinkWrap: true,
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 80, color: theme.disabledColor),
              const SizedBox(height: 16),
              const Text('No pending complaints', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('All incoming complaints have been processed.'),
            ],
          ),
        ),
      ],
    );
  }
}
