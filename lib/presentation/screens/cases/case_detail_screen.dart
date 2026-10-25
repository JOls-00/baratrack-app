import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/case_provider.dart';
import '../../providers/evidence_provider.dart';
import '../../../data/repositories/evidence_repository.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_constants.dart';
import '../../../data/models/case_model.dart';
import '../hearings/hearing_form_modal.dart';

class CaseDetailScreen extends StatefulWidget {
  final int caseId;
  const CaseDetailScreen({super.key, required this.caseId});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  CaseModel? _caseDetails;
  List<Map<String, dynamic>> _evidence = [];
  bool _isLoading = true;
  bool _isEvidenceLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final caseProvider = context.read<CaseProvider>();
      final details = await caseProvider.fetchCaseDetails(widget.caseId);
      
      setState(() {
        _caseDetails = details;
        _isLoading = false;
      });

      _fetchEvidence();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchEvidence() async {
    setState(() => _isEvidenceLoading = true);
    try {
      final results = await context.read<EvidenceRepository>().getEvidenceForCase(widget.caseId);
      setState(() {
        _evidence = results;
      });
    } catch (e) {
      debugPrint("Error fetching evidence: $e");
    } finally {
      setState(() => _isEvidenceLoading = false);
    }
  }

  Future<void> _openEvidenceFile(String relativePath) async {
    // Construct base URL by removing the /api-path from baseUrl if present
    // Since AppConstants.baseUrl is "http://127.0.0.1/barangay_api"
    // and the file_path is "uploads/evidence/ev_xxx.png"
    // we should strip everything after the root domain to handle the path correctly.
    
    final uri = Uri.parse(AppConstants.baseUrl);
    final domain = "${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}";
    
    // Ensure we join the path correctly. 
    // Usually backend assets are served from the app root, not the /api subfolder.
    // However, if your PHP serves it from /barangay_api/uploads, we use that.
    
    final fullUrl = "${AppConstants.baseUrl}/$relativePath";
    
    final fileUri = Uri.parse(fullUrl);
    if (await canLaunchUrl(fileUri)) {
      await launchUrl(fileUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file URL'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_caseDetails == null) return;
    
    final remarksController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update status to $newStatus?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add any remarks or notes for this status change:'),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                hintText: 'Remarks...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Update')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<CaseProvider>().updateStatus(
          widget.caseId, 
          newStatus, 
          remarksController.text.trim(),
        );
        _fetchDetails(); // Refresh all
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status updated to $newStatus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_caseDetails?.caseNumber ?? 'Case Details'),
        actions: [
          if (_caseDetails != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: StatusBadge(status: _caseDetails!.status),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _caseDetails == null
                  ? const Center(child: Text('Case not found'))
                  : _buildContent(theme),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final complaint = _caseDetails!.complaint;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeader(theme, complaint),
              ElevatedButton.icon(
                onPressed: () => HearingFormModal.show(context, prefilledCase: _caseDetails),
                icon: const Icon(Icons.add_alarm),
                label: const Text('Schedule Hearing'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildStatusPicker(theme),
          const SizedBox(height: 32),
          _buildDetailSection(theme, complaint),
          const SizedBox(height: 32),
          _buildNarrative(theme, complaint),
          const SizedBox(height: 32),
          _buildEvidenceSection(theme),
          const SizedBox(height: 32),
          _buildRemarks(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ComplaintModel? complaint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(complaint?.typeName ?? 'General Blotter', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        const SizedBox(height: 8),
        Text('Opened on: ${DateFormat('MMMM dd, yyyy').format(_caseDetails!.updatedAt)}', style: TextStyle(color: theme.hintColor)),
      ],
    );
  }

  Widget _buildStatusPicker(ThemeData theme) {
    final statuses = ['Pending', 'Under Investigation', 'Settled', 'Closed'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Manage Case Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: statuses.map((s) {
            final isSelected = _caseDetails?.status == s;
            return ChoiceChip(
              label: Text(s),
              selected: isSelected,
              onSelected: (selected) {
                if (selected && !isSelected) _updateStatus(s);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDetailSection(ThemeData theme, ComplaintModel? complaint) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _detailRow(Icons.person_outline, 'Complainant', complaint?.complainant?.fullName ?? 'Anonymous'),
            const Divider(height: 24),
            _detailRow(Icons.person_pin_outlined, 'Respondent', complaint?.respondent?.fullName ?? 'Unidentified / Unknown'),
            const Divider(height: 24),
            _detailRow(Icons.location_on_outlined, 'Incident Location', complaint?.incidentLocation ?? 'Not specified'),
            const Divider(height: 24),
            _detailRow(Icons.calendar_today, 'Incident Date', complaint != null ? DateFormat('MMM dd, yyyy').format(complaint.incidentDate) : 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        )
      ],
    );
  }

  Widget _buildNarrative(ThemeData theme, ComplaintModel? complaint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Incident Narrative', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Text(complaint?.details ?? 'No details provided.', style: const TextStyle(height: 1.5)),
        ),
      ],
    );
  }

  Widget _buildEvidenceSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Evidence & Attachments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        if (_isEvidenceLoading)
          const Center(child: CircularProgressIndicator())
        else if (_evidence.isEmpty)
          const Text('No evidence files uploaded for this case.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 3),
            itemCount: _evidence.length,
            itemBuilder: (context, i) {
              final file = _evidence[i];
              return Card(
                color: theme.colorScheme.surfaceContainerHighest,
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(file['original_filename'] ?? 'File', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                  onTap: () {
                    if (file['file_path'] != null) {
                      _openEvidenceFile(file['file_path']);
                    }
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildRemarks(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Administrative Remarks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Text(_caseDetails?.remarks ?? 'No remarks added yet.', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
      ],
    );
  }
}
