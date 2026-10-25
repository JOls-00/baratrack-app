import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/documents_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_constants.dart';

class MyDocumentsView extends StatefulWidget {
  const MyDocumentsView({super.key});

  @override
  State<MyDocumentsView> createState() => _MyDocumentsViewState();
}

class _MyDocumentsViewState extends State<MyDocumentsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DocumentsProvider>().fetchDocuments();
        context.read<ComplaintProvider>().fetchMyComplaints();
      }
    });
  }

  Future<void> _viewFile(String? relativePath) async {
    if (relativePath == null) return;
    final fullUrl = "${AppConstants.baseUrl}/$relativePath";
    final uri = Uri.parse(fullUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final docsProvider = context.watch<DocumentsProvider>();
    final complaintProvider = context.watch<ComplaintProvider>();

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          context.read<DocumentsProvider>().fetchDocuments(),
          context.read<ComplaintProvider>().fetchMyComplaints(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Documents', style: theme.textTheme.headlineLarge),
            const Text('View and download official records and certificates.', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 32),
            
            // Section 1: Official Documents
            _buildSectionHeader('Official Certificates'),
            const SizedBox(height: 16),
            if (docsProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (docsProvider.documents.isEmpty)
              _buildEmptyPlaceholder('No official documents issued to you yet.')
            else
              _buildDocumentList(docsProvider.documents),

            const SizedBox(height: 48),

            // Section 2: Case Evidence
            _buildSectionHeader('Case Evidence'),
            const SizedBox(height: 16),
            if (complaintProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              _buildEvidenceSection(complaintProvider.myComplaints),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
  }

  Widget _buildEmptyPlaceholder(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(child: Text(message, style: const TextStyle(color: Colors.grey))),
    );
  }

  Widget _buildDocumentList(List<Map<String, dynamic>> documents) {
    return Column(
      children: documents.map((doc) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.verified_outlined, size: 20)),
          title: Text(doc['type'] ?? 'Official Document', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Issued: ${doc['created_at'] != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(doc['created_at'])) : 'N/A'} • ${doc['status'] ?? 'Active'}'),
          trailing: IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _viewFile(doc['file_path']),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildEvidenceSection(List complaints) {
    final convertedComplaints = complaints.where((c) => c.caseId != null).toList();
    
    if (convertedComplaints.isEmpty) {
      return _buildEmptyPlaceholder('Evidence will appear here for your official cases.');
    }

    return Column(
      children: convertedComplaints.map((c) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ExpansionTile(
          leading: const Icon(Icons.folder_open, color: Colors.orange),
          title: Text('Case #${c.caseNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(c.typeName),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Note: Evidence is currently viewed via the "My Filed Complaints" details dialog.', 
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {}, // Handled by standard flow
                    icon: const Icon(Icons.arrow_right_alt),
                    label: const Text('Manage Evidence in My Complaints'),
                  ),
                ],
              ),
            )
          ],
        ),
      )).toList(),
    );
  }
}
