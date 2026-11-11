import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/offline_queue_item.dart';
import '../../../data/repositories/offline_queue_repository.dart';
import '../../providers/auth_provider.dart';
import 'offline_drafts_screen.dart';

class AdminOfflineHome extends StatefulWidget {
  const AdminOfflineHome({super.key});

  @override
  State<AdminOfflineHome> createState() => _AdminOfflineHomeState();
}

class _AdminOfflineHomeState extends State<AdminOfflineHome> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _cachedCases = [];
  List<dynamic> _cachedHearings = [];
  DateTime _cacheTimestamp = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    final casesStr = prefs.getString('offline_cached_cases');
    final hearingsStr = prefs.getString('offline_cached_hearings');
    final cacheTimeStr = prefs.getString('offline_cache_timestamp');

    if (cacheTimeStr != null) {
      _cacheTimestamp = DateTime.tryParse(cacheTimeStr) ?? DateTime.now();
    }

    List<dynamic> loadedCases = [];
    List<dynamic> loadedHearings = [];

    if (casesStr != null && casesStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(casesStr);
        if (decoded is List) loadedCases = decoded;
      } catch (_) {}
    }

    if (hearingsStr != null && hearingsStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(hearingsStr);
        if (decoded is List) loadedHearings = decoded;
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _cachedCases = loadedCases;
        _cachedHearings = loadedHearings;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final queueRepo = context.watch<OfflineQueueRepository>();
    final pendingCount = queueRepo.draftCount;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin Offline Portal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              'As of ${DateFormat('MMM d, h:mm a').format(_cacheTimestamp)} · Desk Officer ${user?.name ?? ''}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade300),
            ),
          ],
        ),
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Bumalik sa Online Mode',
          onPressed: () => AppRouter.exitOfflineMode(),
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              child: const Icon(Icons.cloud_sync_outlined),
            ),
            tooltip: 'Pending Sync Queue',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OfflineDraftsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload cached data',
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.grey.shade400,
          tabs: [
            Tab(
              icon: const Icon(Icons.folder_shared_outlined, size: 20),
              text: 'Cases (${_cachedCases.length})',
            ),
            Tab(
              icon: const Icon(Icons.event_note_outlined, size: 20),
              text: 'Hearings (${_cachedHearings.length})',
            ),
            const Tab(
              icon: Icon(Icons.lock_clock_outlined, size: 20),
              text: 'Online Only',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD61314),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Walk-in Complaint'),
        onPressed: _showWalkInComplaintDialog,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCasesTab(),
                _buildHearingsTab(),
                _buildLockedFeaturesTab(),
              ],
            ),
    );
  }

  Widget _buildCasesTab() {
    if (_cachedCases.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Walang Naka-cache na Kaso', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Awtomatikong magka-cache ang mga kaso kapag nag-browse ka habang online.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cachedCases.length,
      itemBuilder: (context, index) {
        final c = _cachedCases[index];
        final caseNumber = c['case_number']?.toString() ?? 'CASE';
        final status = c['status']?.toString() ?? 'Pending';
        final remarks = c['remarks']?.toString() ?? '';
        final updatedAt = c['updated_at']?.toString() ?? '';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                      child: Text(caseNumber, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: status == 'Settled' ? Colors.green.shade100 : Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: status == 'Settled' ? Colors.green.shade900 : Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                if (remarks.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(remarks, style: const TextStyle(fontSize: 13)),
                ],
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.add_comment_outlined, size: 16),
                      label: const Text('Add Note'),
                      onPressed: () => _queueCaseNote(caseNumber, c['id'], updatedAt),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: () => _queueStatusChange(caseNumber, c['id'], updatedAt),
                      child: const Text('Queue Status', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHearingsTab() {
    if (_cachedHearings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Walang Naka-cache na Hearing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Ang mga hearing schedule ay naka-cache mula sa iyong huling online session.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cachedHearings.length,
      itemBuilder: (context, index) {
        final h = _cachedHearings[index];
        final caseNumber = h['case_number']?.toString() ?? 'Case';
        final venue = h['venue']?.toString() ?? 'Barangay Hall';
        final date = h['hearing_date']?.toString() ?? '';
        final time = h['hearing_time']?.toString() ?? '';
        final status = h['status']?.toString() ?? 'Scheduled';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFEE2E2),
              child: Icon(Icons.gavel, color: Color(0xFFD61314)),
            ),
            title: Text('$caseNumber · $venue', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('$date at $time · Status: $status'),
            trailing: IconButton(
              icon: const Icon(Icons.edit_note, color: Colors.indigo),
              tooltip: 'Queue Hearing Outcome',
              onPressed: () => _queueHearingOutcome(caseNumber, h['id']),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLockedFeaturesTab() {
    final lockedActions = [
      {'title': 'Close Case Permanently', 'desc': 'Requires online legal blotter audit verification'},
      {'title': 'Delete Case Record', 'desc': 'Permanent deletion disabled while offline'},
      {'title': 'Reassign Case Officer', 'desc': 'Staff directory real-time sync required'},
      {'title': 'Approve Resident Registrations', 'desc': 'Identity database cross-checking is online only'},
      {'title': 'User Management & Roles', 'desc': 'Account privileges must be verified with server'},
      {'title': 'Live Incident Heatmap', 'desc': 'Real-time GPS spatial query requires connection'},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: lockedActions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final item = lockedActions[i];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.grey.shade100,
          child: ListTile(
            leading: const Icon(Icons.lock_rounded, color: Colors.grey),
            title: Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            subtitle: Text(item['desc']!, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            trailing: Chip(
              label: const Text('Online Only', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.grey.shade300,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item['title']} is locked in offline mode. Please reconnect to the internet.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showWalkInComplaintDialog() async {
    final complainantNameCtrl = TextEditingController();
    final respondentNameCtrl = TextEditingController();
    final narrativeCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    String category = 'Physical Injury';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.person_add_alt_1, color: Color(0xFFD61314)),
              const SizedBox(width: 8),
              const Text('Walk-in Complaint', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: complainantNameCtrl,
                  decoration: const InputDecoration(labelText: 'Complainant Full Name *', prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: respondentNameCtrl,
                  decoration: const InputDecoration(labelText: 'Respondent Name (or Unknown)', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category)),
                  items: ['Physical Injury', 'Theft/Robbery', 'Threats', 'Noise Complaint', 'Property Damage', 'Others']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => category = v!),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(labelText: 'Incident Location *', prefixIcon: Icon(Icons.location_on)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: narrativeCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Narrative / Details *', alignLabelWithHint: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD61314), foregroundColor: Colors.white),
              onPressed: () async {
                if (complainantNameCtrl.text.trim().isEmpty || narrativeCtrl.text.trim().isEmpty) return;

                final queueRepo = context.read<OfflineQueueRepository>();
                final user = context.read<AuthProvider>().user;
                final item = OfflineQueueItem(
                  id: queueRepo.newUuid(),
                  type: 'complaint',
                  payload: {
                    'title': 'Walk-in: $category',
                    'category': category,
                    'complainant_name': complainantNameCtrl.text.trim(),
                    'respondent_name': respondentNameCtrl.text.trim(),
                    'narrative': narrativeCtrl.text.trim(),
                    'location': locationCtrl.text.trim(),
                    'incident_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    'incident_time': DateFormat('HH:mm:ss').format(DateTime.now()),
                    'is_walk_in': true,
                  },
                  ownerId: user?.id,
                  ownerName: user?.name,
                  deviceTime: DateTime.now(),
                  state: 'draft',
                );

                await queueRepo.save(item);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Walk-in complaint saved to pending sync queue!')),
                  );
                }
              },
              child: const Text('Queue Walk-in'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _queueCaseNote(String caseNumber, dynamic caseId, String updatedAt) async {
    final noteCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Case Note ($caseNumber)'),
        content: TextField(
          controller: noteCtrl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Enter internal notes or mediation remarks...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (noteCtrl.text.trim().isEmpty) return;
              final queueRepo = context.read<OfflineQueueRepository>();
              final user = context.read<AuthProvider>().user;
              final item = OfflineQueueItem(
                id: queueRepo.newUuid(),
                type: 'note',
                payload: {
                  'case_id': caseId,
                  'case_number': caseNumber,
                  'note': noteCtrl.text.trim(),
                },
                baseUpdatedAt: updatedAt,
                ownerId: user?.id,
                ownerName: user?.name,
                deviceTime: DateTime.now(),
                state: 'draft',
              );
              await queueRepo.save(item);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Case note queued for sync!')),
                );
              }
            },
            child: const Text('Queue Note'),
          ),
        ],
      ),
    );
  }

  Future<void> _queueStatusChange(String caseNumber, dynamic caseId, String updatedAt) async {
    String newStatus = 'Settled';
    final remarksCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Queue Status Update ($caseNumber)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: newStatus,
                decoration: const InputDecoration(labelText: 'Low-Risk Status Update'),
                items: ['Under Investigation', 'Settled']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setDialogState(() => newStatus = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: remarksCtrl,
                decoration: const InputDecoration(labelText: 'Remarks (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final queueRepo = context.read<OfflineQueueRepository>();
                final user = context.read<AuthProvider>().user;
                final item = OfflineQueueItem(
                  id: queueRepo.newUuid(),
                  type: 'status_change',
                  payload: {
                    'case_id': caseId,
                    'case_number': caseNumber,
                    'status': newStatus,
                    'remarks': remarksCtrl.text.trim(),
                  },
                  baseUpdatedAt: updatedAt,
                  ownerId: user?.id,
                  ownerName: user?.name,
                  deviceTime: DateTime.now(),
                  state: 'draft',
                );
                await queueRepo.save(item);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status update queued for sync!')),
                  );
                }
              },
              child: const Text('Queue Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _queueHearingOutcome(String caseNumber, dynamic hearingId) async {
    String outcomeStatus = 'Completed';
    final notesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Hearing Outcome ($caseNumber)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: outcomeStatus,
                decoration: const InputDecoration(labelText: 'Outcome Status'),
                items: ['Completed', 'Postponed']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setDialogState(() => outcomeStatus = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Hearing Minutes / Outcome Notes'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final queueRepo = context.read<OfflineQueueRepository>();
                final user = context.read<AuthProvider>().user;
                final item = OfflineQueueItem(
                  id: queueRepo.newUuid(),
                  type: 'hearing_outcome',
                  payload: {
                    'hearing_id': hearingId,
                    'case_number': caseNumber,
                    'status': outcomeStatus,
                    'notes': notesCtrl.text.trim(),
                  },
                  ownerId: user?.id,
                  ownerName: user?.name,
                  deviceTime: DateTime.now(),
                  state: 'draft',
                );
                await queueRepo.save(item);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hearing outcome queued for sync!')),
                  );
                }
              },
              child: const Text('Queue Outcome'),
            ),
          ],
        ),
      ),
    );
  }
}
