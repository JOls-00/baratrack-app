import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_constants.dart';
import '../../../data/models/case_model.dart';
import '../../../data/repositories/evidence_repository.dart';

class ComplaintDetailsDialog extends StatefulWidget {
  final ComplaintModel complaint;
  const ComplaintDetailsDialog({super.key, required this.complaint});

  static void show(BuildContext context, ComplaintModel complaint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ComplaintDetailsDialog(complaint: complaint),
    );
  }

  @override
  State<ComplaintDetailsDialog> createState() => _ComplaintDetailsDialogState();
}

class _ComplaintDetailsDialogState extends State<ComplaintDetailsDialog> {
  List<Map<String, dynamic>> _evidence = [];
  bool _isLoadingEvidence = false;

  @override
  void initState() {
    super.initState();
    _fetchEvidence();
  }

  Future<void> _fetchEvidence() async {
    setState(() => _isLoadingEvidence = true);
    try {
      final results = await context.read<EvidenceRepository>().getEvidenceForComplaint(widget.complaint.id);
      if (mounted) {
        setState(() {
          _evidence = results;
        });
      }
    } catch (e) {
      debugPrint("Error fetching evidence in dialog: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingEvidence = false);
      }
    }
  }

  Future<void> _openFile(String relativePath) async {
    final fullUrl = "${AppConstants.baseUrl}/$relativePath";
    final fileUri = Uri.parse(fullUrl);
    
    if (await canLaunchUrl(fileUri)) {
      await launchUrl(fileUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaint = widget.complaint;
    final displayId = complaint.caseNumber ?? "CMP-${complaint.id.toString().padLeft(3, '0')}";
    final isCase = complaint.caseId != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isCase ? 'Official Case #$displayId' : 'Pending Complaint #$displayId', 
                    style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                  Text(complaint.typeName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.brand)),
                ],
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const Divider(height: 40),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(context, Icons.person_outline, 'Complainant', complaint.complainant?.fullName ?? 'Anonymous'),
                  _buildDetailRow(context, Icons.person_pin_outlined, 'Respondent', complaint.respondent?.fullName ?? 'Unidentified / Unknown'),
                  _buildDetailRow(context, Icons.location_on_outlined, 'Incident Location', complaint.incidentLocation),
                  _buildDetailRow(context, Icons.calendar_today, 'Date of Incident', DateFormat('MMMM dd, yyyy').format(complaint.incidentDate)),
                  _buildDetailRow(context, Icons.access_time, 'Time of Incident', complaint.incidentTime),
                  _buildDetailRow(context, Icons.info_outline, 'Current Status', complaint.status, isStatus: true),
                  const SizedBox(height: 24),
                  const Text('Incident Narrative', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Text(
                      complaint.details, 
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Evidence & Attachments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  _buildEvidenceSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceSection() {
    if (_isLoadingEvidence) return const Center(child: CircularProgressIndicator());

    if (_evidence.isEmpty) {
      return const Text('No evidence files were attached to this complaint.',
        style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic, fontSize: 13));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _evidence.length,
      itemBuilder: (context, i) {
        final file = _evidence[i];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.insert_drive_file),
            title: Text(file['original_filename'] ?? 'File', style: const TextStyle(fontSize: 14)),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openFile(file['file_path']),
          ),
        );
      },
    );
  }

  static Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value, {bool isStatus = false}) {
    Color statusColor = Colors.grey;
    if (isStatus) {
      if (value == 'Settled') statusColor = Colors.green;
      if (value == 'Under Investigation' || value == 'In Investigation') statusColor = AppTheme.accentOrange;
      if (value == 'Pending') statusColor = Colors.blue;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: context.brand),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                isStatus 
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(value, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
                    )
                  : Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
