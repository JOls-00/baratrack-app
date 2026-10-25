import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/evidence_provider.dart';
import '../../../config/app_theme.dart';
import 'complaint_details_dialog.dart';

class MyComplaintsView extends StatefulWidget {
  const MyComplaintsView({super.key});

  @override
  State<MyComplaintsView> createState() => _MyComplaintsViewState();
}

class _MyComplaintsViewState extends State<MyComplaintsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ComplaintProvider>().fetchMyComplaints();
      }
    });
  }

  Future<void> _pickAndUploadEvidence(BuildContext context, {int? caseId, int? complaintId}) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'mp4', 'doc', 'docx'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final evidenceProvider = context.read<EvidenceProvider>();
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const Center(child: CircularProgressIndicator()),
      );

      int uploadedCount = 0;
      final failedFiles = <String>[];

      for (final f in result.files) {
        try {
          await evidenceProvider.uploadEvidence(
            caseId: caseId,
            complaintId: complaintId,
            file: f,
          );
          uploadedCount++;
        } catch (_) {
          failedFiles.add(f.name);
        }
      }

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        if (failedFiles.isEmpty) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('$uploadedCount evidence file(s) uploaded.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Uploaded $uploadedCount file(s). Failed to upload: ${failedFiles.join(', ')}.'),
              backgroundColor: Colors.orange[800],
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaintProvider = context.watch<ComplaintProvider>();
    final complaints = complaintProvider.myComplaints;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My Filed Complaints', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const Text('History of all blotter reports you have submitted.'),
          const SizedBox(height: 32),
          Expanded(
            child: complaintProvider.isLoading && complaints.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : complaints.isEmpty
                    ? const Center(child: Text('No complaints found.'))
                    : RefreshIndicator(
                        onRefresh: () => context.read<ComplaintProvider>().fetchMyComplaints(),
                        child: ListView.builder(
                          itemCount: complaints.length,
                          itemBuilder: (context, index) {
                            final c = complaints[index];
                            final displayId = c.caseNumber ?? "CMP-${c.id.toString().padLeft(3, '0')}";
                            final isCase = c.caseId != null;
                            final canAttach = c.status != 'Settled' && c.status != 'Closed' && c.status != 'Dismissed';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      ComplaintDetailsDialog.show(context, c);
                                    },
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: context.brand.withValues(alpha: 0.1),
                                            child: Icon(isCase ? Icons.folder : Icons.assignment, color: context.brand),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  isCase ? 'Case #$displayId: ${c.typeName}' : 'Complaint #$displayId: ${c.typeName}', 
                                                  style: const TextStyle(fontWeight: FontWeight.bold)
                                                ),
                                                Text('Filed on: ${DateFormat('MMM dd, yyyy').format(c.dateFiled)}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                                Text('Respondent: ${c.respondent?.fullName ?? 'Unidentified'}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                              ],
                                            ),
                                          ),
                                          _buildStatusBadge(c.status),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (canAttach)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                                      child: Row(
                                        children: [
                                          const Spacer(),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              if (c.caseId != null) {
                                                _pickAndUploadEvidence(context, caseId: c.caseId);
                                              } else {
                                                _pickAndUploadEvidence(context, complaintId: c.id);
                                              }
                                            },
                                            icon: const Icon(Icons.attach_file, size: 18),
                                            label: const Text('Attach Evidence'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blueGrey[50],
                                              foregroundColor: Colors.blueGrey[800],
                                              elevation: 0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
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

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'Settled') color = Colors.green;
    if (status == 'Under Investigation' || status == 'In Investigation') color = AppTheme.accentOrange;
    if (status == 'Pending') color = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
