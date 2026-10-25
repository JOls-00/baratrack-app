import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/resident_model.dart';
import '../../../data/models/case_model.dart';
import '../../../data/repositories/case_repository.dart';
import '../../providers/resident_provider.dart';
import '../../providers/documents_provider.dart';
import '../../../config/app_constants.dart';
import 'resident_form_screen.dart';

class ResidentDetailScreen extends StatefulWidget {
  final int residentId;
  const ResidentDetailScreen({super.key, required this.residentId});

  @override
  State<ResidentDetailScreen> createState() => _ResidentDetailScreenState();
}

class _ResidentDetailScreenState extends State<ResidentDetailScreen> {
  List<CaseModel> _residentCases = [];
  bool _isLoadingCases = true;
  String? _casesError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DocumentsProvider>().fetchDocuments(residentId: widget.residentId);
        _fetchResidentCases();
      }
    });
  }

  Future<void> _fetchResidentCases() async {
    setState(() {
      _isLoadingCases = true;
      _casesError = null;
    });
    try {
      final repo = context.read<CaseRepository>();
      final cases = await repo.getCasesByResident(widget.residentId);
      if (mounted) {
        setState(() {
          _residentCases = cases;
          _isLoadingCases = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _casesError = e.toString();
          _isLoadingCases = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final residentProvider = context.watch<ResidentProvider>();
    final docsProvider = context.watch<DocumentsProvider>();
    
    final resident = residentProvider.residents.firstWhere(
      (r) => r.id == widget.residentId,
      orElse: () => ResidentModel(
        id: 0, firstName: 'Loading', lastName: '...', gender: '', 
        birthDate: DateTime.now(), contact: '', address: '', zone: '', createdAt: DateTime.now()
      ),
    );

    if (resident.id == 0) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(resident.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editResident(context, resident),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: Colors.red,
            onPressed: () => _confirmDelete(context, resident),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(theme, resident),
            const SizedBox(height: 32),
            _buildInfoGrid(theme, resident),
            const SizedBox(height: 32),
            _buildDocumentsSection(context, theme, resident, docsProvider),
            const SizedBox(height: 32),
            _buildHistorySection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, ResidentModel resident) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Text(
              resident.firstName.isNotEmpty ? resident.firstName[0] : '?', 
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)
            ),
          ),
          const SizedBox(height: 16),
          Text(resident.fullName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text('Zone ${resident.zone ?? 'N/A'} • ${resident.status}', style: TextStyle(color: theme.hintColor)),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(ThemeData theme, ResidentModel resident) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _infoRow(Icons.person_outline, 'Gender', resident.gender ?? 'N/A'),
            const Divider(),
            _infoRow(Icons.cake_outlined, 'Birth Date', resident.birthDate != null ? DateFormat('MMMM dd, yyyy').format(resident.birthDate!) : 'N/A'),
            const Divider(),
            _infoRow(Icons.phone_outlined, 'Contact', resident.contact ?? 'No contact info'),
            const Divider(),
            _infoRow(Icons.email_outlined, 'Email', resident.email != null && resident.email!.isNotEmpty ? resident.email! : 'No email address'),
            const Divider(),
            _infoRow(Icons.location_on_outlined, 'Address', resident.address ?? 'No address provided'),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsSection(BuildContext context, ThemeData theme, ResidentModel resident, DocumentsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Official Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ElevatedButton.icon(
              onPressed: () => _showIssueDocumentModal(context, resident),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Issue Document'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (provider.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (provider.documents.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('No documents issued yet.', style: TextStyle(color: Colors.grey))),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.documents.length,
            itemBuilder: (context, i) {
              final doc = provider.documents[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.description_outlined, color: Colors.blue),
                  title: Text(doc['type'] ?? 'Official Document', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Issued: ${doc['created_at'] != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(doc['created_at'])) : 'N/A'} • ${doc['status'] ?? 'Active'}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new, size: 20),
                    onPressed: () => _viewFile(doc['file_path']),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _viewFile(String? relativePath) async {
    if (relativePath == null) return;
    final fullUrl = "${AppConstants.baseUrl}/$relativePath";
    final uri = Uri.parse(fullUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showIssueDocumentModal(BuildContext context, ResidentModel resident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _IssueDocumentModal(resident: resident),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHistorySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Case History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        if (_isLoadingCases)
          const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()))
        else if (_casesError != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to load case history: $_casesError')),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchResidentCases,
                ),
              ],
            ),
          )
        else if (_residentCases.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: const Center(
              child: Text(
                'No cases on record for this resident.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _residentCases.length,
            itemBuilder: (context, index) {
              final c = _residentCases[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Row(
                    children: [
                      Text(c.caseNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      if (c.residentRole != null) ...[
                        Chip(
                          label: Text(
                            c.residentRole!,
                            style: TextStyle(
                              fontSize: 10,
                              color: c.residentRole == 'Complainant' ? Colors.blue.shade900 : Colors.orange.shade900,
                            ),
                          ),
                          backgroundColor: c.residentRole == 'Complainant' 
                              ? Colors.blue.shade50 
                              : Colors.orange.shade50,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(c.complaint?.typeName ?? 'General Complaint', style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        'Updated: ${DateFormat('MMM dd, yyyy').format(c.updatedAt)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(c.status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      c.status,
                      style: TextStyle(
                        color: _getStatusColor(c.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  onTap: () => context.push('/cases/${c.id}'),
                ),
              );
            },
          ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Settled':
      case 'Resolved':
        return Colors.green;
      case 'Closed':
      case 'Dismissed':
        return Colors.grey;
      case 'Under Investigation':
        return Colors.orange;
      case 'Pending':
      default:
        return Colors.blue;
    }
  }

  void _editResident(BuildContext context, ResidentModel resident) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResidentFormScreen(resident: resident)),
    );
  }

  void _confirmDelete(BuildContext context, ResidentModel resident) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resident Record?'),
        content: Text('Are you sure you want to delete ${resident.fullName}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<ResidentProvider>().deleteResident(resident.id);
        if (context.mounted) {
          Navigator.pop(context); // Close detail screen
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resident deleted.')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      }
    }
  }
}

class _IssueDocumentModal extends StatefulWidget {
  final ResidentModel resident;
  const _IssueDocumentModal({required this.resident});

  @override
  State<_IssueDocumentModal> createState() => _IssueDocumentModalState();
}

class _IssueDocumentModalState extends State<_IssueDocumentModal> {
  String _selectedType = 'Barangay Clearance';
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  final List<String> _types = [
    'Barangay Clearance',
    'Certificate of Residency',
    'Certificate of Indigency',
    'First Time Job Seeker',
    'Business Permit'
  ];

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'doc', 'docx'],
    );
    if (result != null) {
      setState(() => _selectedFile = result.files.single);
    }
  }

  Future<void> _submit() async {
    if (_selectedFile == null) return;
    
    setState(() => _isUploading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);

    try {
      await context.read<DocumentsProvider>().issueDocument(
        residentId: widget.resident.id,
        type: _selectedType,
        file: _selectedFile!,
      );
      
      if (mounted) {
        navigator.pop(); // Close modal
        messenger.showSnackBar(const SnackBar(content: Text('Document issued successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Issue New Document', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Issuing to: ${widget.resident.fullName}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            
            const Text('Document Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
            const SizedBox(height: 24),

            const Text('Upload Signed Document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_selectedFile == null ? Icons.upload_file : Icons.check_circle, color: _selectedFile == null ? Colors.grey : Colors.green),
                    const SizedBox(width: 12),
                    Text(_selectedFile?.name ?? 'Choose File (PDF/Image)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedFile == null || _isUploading ? null : _submit,
                child: _isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text('Issue Document'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
