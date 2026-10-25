import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../complaints/file_complaint_screen.dart';
import '../../../data/models/case_model.dart';

class UserDashboardView extends StatefulWidget {
  const UserDashboardView({super.key});

  @override
  State<UserDashboardView> createState() => _UserDashboardViewState();
}

class _UserDashboardViewState extends State<UserDashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ComplaintProvider>().fetchMyComplaints();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final theme = Theme.of(context);
    final complaintProvider = context.watch<ComplaintProvider>();
    final complaints = complaintProvider.myComplaints;
    
    // Find the most recent active case if one exists, handling empty/null cases safely
    ComplaintModel? activeComplaint;
    if (complaints.isNotEmpty) {
      try {
        activeComplaint = complaints.firstWhere(
          (c) => c.caseId != null && c.status != 'Settled' && c.status != 'Closed',
        );
      } catch (_) {
        // If no active case, just show the most recent complaint regardless of status
        activeComplaint = complaints.first;
      }
    }

    return RefreshIndicator(
      onRefresh: () => context.read<ComplaintProvider>().fetchMyComplaints(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroHeader(context, theme, user?.name ?? 'Resident'),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      if (activeComplaint != null)
                        _buildTimelineCard(theme, activeComplaint)
                      else
                        _buildNoActiveCaseCard(theme),
                      const SizedBox(height: 24),
                      _buildDocumentsPreview(theme),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      _buildEmergencyContacts(theme),
                      const SizedBox(height: 24),
                      _buildProfileCompleteness(theme, user?.residentId != null),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, ThemeData theme, String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.primary, AppTheme.deepen(theme.colorScheme.primary, 0.3)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 12))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mabuhay, $name!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.onColor(theme.colorScheme.primary))),
                const SizedBox(height: 8),
                Text('Welcome to your Barangay Resident Portal.', style: TextStyle(color: AppTheme.onColor(theme.colorScheme.primary).withValues(alpha: 0.85), fontSize: 16)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FileComplaintScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.onColor(theme.colorScheme.primary),
              foregroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            ),
            child: const Text('File New Complaint', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoActiveCaseCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            const Text('No Active Cases', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Text('You have no ongoing legal proceedings at this time.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard(ThemeData theme, ComplaintModel complaint) {
    final isCase = complaint.caseId != null;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCase ? 'Active Case Timeline: #${complaint.caseNumber}' : 'Complaint Status: #${complaint.id}', 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
            ),
            const SizedBox(height: 32),
            _timelineStep(theme, 'Complaint Filed', DateFormat('MMM dd, yyyy').format(complaint.dateFiled), true, true),
            _timelineStep(theme, isCase ? 'Case Opened' : 'Under Review', isCase ? 'Official blotter created' : 'Waiting for Admin review', isCase, true),
            _timelineStep(theme, 'Mediation Hearing', 'Status: ${complaint.status}', complaint.status == 'Settled' || complaint.status == 'Closed', true),
            _timelineStep(theme, 'Resolution / Closed', '--', complaint.status == 'Settled' || complaint.status == 'Closed', false),
          ],
        ),
      ),
    );
  }

  Widget _timelineStep(ThemeData theme, String l, String d, bool done, bool line) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? theme.colorScheme.primary : Colors.grey),
              if (line) Expanded(child: Container(width: 2, color: done ? theme.colorScheme.primary : Colors.grey.withValues(alpha: 0.2))),
            ],
          ),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l, style: TextStyle(fontWeight: done ? FontWeight.bold : FontWeight.normal, color: done ? theme.colorScheme.onSurface : Colors.grey)),
                Text(d, style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmergencyContacts(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🆘 Emergency Hotlines', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            _contactItem(Icons.local_police_outlined, 'Police', '911', Colors.blue),
            _contactItem(Icons.local_fire_department_outlined, 'Fire', '123-456', Colors.orange),
            _contactItem(Icons.medical_services_outlined, 'Health', '555-0987', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _contactItem(IconData i, String n, String p, Color c) => ListTile(
    leading: Icon(i, color: c, size: 20),
    title: Text(n, style: const TextStyle(fontSize: 14)),
    trailing: Text(p, style: const TextStyle(fontWeight: FontWeight.bold)),
    contentPadding: EdgeInsets.zero,
  );

  Widget _buildProfileCompleteness(ThemeData theme, bool isRegistered) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Legal Verification', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Icon(isRegistered ? Icons.verified : Icons.error_outline, size: 64, color: isRegistered ? Colors.green : Colors.orange),
            const SizedBox(height: 16),
            Text(isRegistered ? 'Verified Resident' : 'Unverified', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            Text(isRegistered ? 'Linked to Barangay Registry' : 'Action Required to file reports', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (!isRegistered) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FileComplaintScreen())), child: const Text('Register Now')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsPreview(ThemeData theme) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.all(24), child: Text('📄 My Latest Evidence', style: theme.textTheme.titleMedium)),
          const ListTile(
            title: Text('No evidence uploaded recently.'),
            subtitle: Text('Upload files via "My Filed Complaints" once a case is opened.'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
