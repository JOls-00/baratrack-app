import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/documents_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/locale_provider.dart';

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
    final isFil = context.watch<LocaleProvider>().isFilipino;

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
            Text(isFil ? 'Mga Dokumento Ko' : 'My Documents', style: theme.textTheme.headlineLarge),
            Text(
              isFil ? 'Tingnan at i-download ang mga opisyal na rekord at sertipiko.' : 'View and download official records and certificates.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            
            // Section 1: Official Documents
            _buildSectionHeader(isFil ? 'Opisyal na mga Sertipiko' : 'Official Certificates'),
            const SizedBox(height: 16),
            if (docsProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (docsProvider.error != null)
              _buildEmptyPlaceholder(docsProvider.error!)
            else if (docsProvider.documents.isEmpty)
              _buildEmptyPlaceholder(isFil ? 'Wala pang opisyal na dokumentong naibigay sa iyo.' : 'No official documents issued to you yet.')
            else
              _buildDocumentList(docsProvider.documents),

            const SizedBox(height: 48),

            // Section 2: Case Evidence
            _buildSectionHeader(isFil ? 'Ebidensya ng Kaso' : 'Case Evidence'),
            const SizedBox(height: 16),
            if (complaintProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (complaintProvider.error != null)
              _buildEmptyPlaceholder(complaintProvider.error!)
            else
              _buildEvidenceSection(complaintProvider.myComplaints, isFil),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
  }

  Widget _buildEmptyPlaceholder(String message) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildDocumentList(List<Map<String, dynamic>> documents) {
    return Column(
      children: documents.map((doc) {
        final rawDate = doc['issued_at'] ?? doc['created_at'];
        final parsed = rawDate != null ? DateTime.tryParse(rawDate.toString()) : null;
        final issuedStr = parsed != null ? DateFormat('MMM dd, yyyy').format(parsed) : 'N/A';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.verified_outlined, size: 20)),
            title: Text(doc['type'] ?? 'Official Document', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Issued: $issuedStr • ${doc['status'] ?? 'Active'}'),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _viewFile(doc['file_path']),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEvidenceSection(List complaints, bool isFil) {
    final convertedComplaints = complaints.where((c) => c.caseId != null).toList();
    
    if (convertedComplaints.isEmpty) {
      return _buildEmptyPlaceholder(isFil ? 'Dito lalabas ang ebidensya ng iyong mga opisyal na kaso.' : 'Evidence will appear here for your official cases.');
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
                  Text(
                    isFil
                        ? 'Paalala: Maaaring tingnan at pamahalaan ang mga ebidensya sa "Mga Reklamo Ko".'
                        : 'Note: Evidence is viewed and managed via the "My Filed Complaints" details dialog.',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => context.go('/my-complaints'),
                    icon: const Icon(Icons.arrow_right_alt),
                    label: Text(isFil ? 'Pamahalaan ang Ebidensya' : 'Manage Evidence in My Complaints'),
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
