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
    final sideMargin = AppTheme.sideMargin(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(sideMargin, 16, sideMargin, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My Filed Complaints', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('History of all blotter reports you have submitted.', style: TextStyle(color: AppTheme.textSecondaryLight)),
          const SizedBox(height: 16),
          Expanded(
            child: complaintProvider.isLoading && complaints.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : complaints.isEmpty
                    ? const Center(child: Text('No complaints found.'))
                    : RefreshIndicator(
                        onRefresh: () => context.read<ComplaintProvider>().fetchMyComplaints(),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: complaints.length,
                          itemBuilder: (context, index) {
                            final c = complaints[index];
                            final displayId = c.caseNumber ?? "CMP-${c.id.toString().padLeft(3, '0')}";
                            final isCase = c.caseId != null;
                            final canAttach = c.status != 'Settled' && c.status != 'Closed' && c.status != 'Dismissed';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () => ComplaintDetailsDialog.show(context, c),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top Header: Identifier Pill (Expanded + ellipsis) & Status Badge
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: context.brand.withValues(alpha: 0.12),
                                            child: Icon(isCase ? Icons.folder : Icons.assignment, size: 15, color: context.brand),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              isCase ? 'Case #$displayId' : 'Complaint #$displayId',
                                              style: TextStyle(
                                                fontFamily: 'monospace',
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12,
                                                color: context.brand,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _buildStatusBadge(c.status),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // Full-Width Category Title (Never squeezed)
                                      Text(
                                        c.typeName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Metadata details wrapped safely
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 6,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.calendar_today, size: 13, color: AppTheme.textSecondaryLight),
                                              const SizedBox(width: 5),
                                              Text(
                                                'Filed: ${DateFormat('MMM dd, yyyy').format(c.dateFiled)}',
                                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.person_outline, size: 14, color: AppTheme.textSecondaryLight),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Resp: ${c.respondent?.fullName ?? 'Unidentified'}',
                                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      if (canAttach) ...[
                                        const SizedBox(height: 12),
                                        const Divider(height: 1),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          alignment: WrapAlignment.spaceBetween,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            Text(
                                              'I-tap para sa buong detalye →',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            OutlinedButton.icon(
                                              onPressed: () {
                                                if (c.caseId != null) {
                                                  _pickAndUploadEvidence(context, caseId: c.caseId);
                                                } else {
                                                  _pickAndUploadEvidence(context, complaintId: c.id);
                                                }
                                              },
                                              icon: const Icon(Icons.attach_file, size: 16),
                                              label: const Text('Attach Evidence', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                              style: OutlinedButton.styleFrom(
                                                minimumSize: const Size(44, 38),
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
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

  Widget _buildStatusBadge(String status) {
    Color color = AppTheme.textHintLight;
    IconData icon = Icons.info_outline;

    if (status == 'Settled' || status == 'Closed') {
      color = AppTheme.success;
      icon = Icons.check_circle_outline;
    } else if (status == 'Under Investigation' || status == 'In Investigation' || status == 'Mediation') {
      color = AppTheme.warning;
      icon = Icons.pending_outlined;
    } else if (status == 'Pending') {
      color = AppTheme.brand500;
      icon = Icons.hourglass_empty;
    } else if (status == 'Dismissed') {
      color = AppTheme.error;
      icon = Icons.cancel_outlined;
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
