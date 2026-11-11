import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          if (_caseDetails != null) ...[
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              tooltip: 'Kopyahin ang Case Number',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _caseDetails!.caseNumber));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kopyado na sa clipboard ang Case Number!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: StatusBadge(status: _caseDetails!.status),
            ),
          ],
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
          const SizedBox(height: 24),
          _buildStatusTimeline(theme),
          const SizedBox(height: 24),
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

  Widget _buildStatusTimeline(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final status = _caseDetails?.status ?? 'Pending';

    // 0: Filed, 1: Under Review (Pending), 2: Mediation (Under Investigation), 3: Settled/Closed
    int currentStep = 1;
    if (status == 'Pending') {
      currentStep = 1;
    } else if (status == 'Under Investigation' || status == 'Hearing Scheduled') {
      currentStep = 2;
    } else if (status == 'Settled' || status == 'Closed') {
      currentStep = 3;
    }

    String nextExplanation;
    switch (currentStep) {
      case 1:
        nextExplanation = 'Susunod: Isasagawa ng Lupon ang paunang pagsusuri ng reklamo at magpapadala ng opisyal na paanyaya/summon para sa mediation.';
        break;
      case 2:
        nextExplanation = 'Susunod: Pagtatagpo ng nagrereklamo at inirereklamo sa Barangay Hall kasama ang Lupon para sa mapayapang pag-aayos (Katarungang Pambarangay).';
        break;
      case 3:
        if (status == 'Closed') {
          nextExplanation = 'Naisara na ang kasong ito. Maaaring kumuha ng Certificate to File Action kung kinakailangang idulog sa hukuman.';
        } else {
          nextExplanation = 'Matagumpay nang naayos ang sigalot at nilagdaan na ang Kasunduan sa Pag-aayos (Amicable Settlement).';
        }
        break;
      default:
        nextExplanation = 'Kasalukuyang pinoproseso sa Barangay Registry.';
    }

    final steps = [
      ('Naihain', 'Filed', Icons.assignment_turned_in_outlined),
      ('Sinusuri', 'Under Review', Icons.search_outlined),
      ('Paghaharap', 'Mediation', Icons.gavel_outlined),
      ('Naayos', 'Settled', Icons.verified_outlined),
    ];

    final activeColor = isDark ? AppTheme.crimsonDarkAccent : AppTheme.brand500;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline_rounded, color: activeColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Case Status Tracker',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 20),

          // Timeline Step Nodes
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 3,
                              color: i == 0
                                  ? Colors.transparent
                                  : (i <= currentStep
                                      ? activeColor
                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i <= currentStep
                                  ? activeColor
                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                              border: Border.all(
                                color: i <= currentStep
                                    ? activeColor
                                    : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              i < currentStep
                                  ? Icons.check
                                  : (i == currentStep ? steps[i].$3 : Icons.circle),
                              size: i < currentStep ? 16 : 14,
                              color: i <= currentStep
                                  ? Colors.white
                                  : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 3,
                              color: i == steps.length - 1
                                  ? Colors.transparent
                                  : (i < currentStep
                                      ? activeColor
                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        steps[i].$1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: i == currentStep ? FontWeight.w800 : FontWeight.w600,
                          color: i == currentStep
                              ? activeColor
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // "What happens next" box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: activeColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: activeColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ano ang susunod (What happens next):',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: activeColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nextExplanation,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
