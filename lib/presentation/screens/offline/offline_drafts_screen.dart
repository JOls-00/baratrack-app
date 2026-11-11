import 'dart:io';
import 'package:dio/dio.dart' show DioException;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/offline_queue_item.dart';
import '../../../data/repositories/offline_queue_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/evidence_provider.dart';
import '../complaints/file_complaint_screen.dart';
import '../profile/resident_registration_screen.dart';

class OfflineDraftsScreen extends StatefulWidget {
  const OfflineDraftsScreen({super.key});

  @override
  State<OfflineDraftsScreen> createState() => _OfflineDraftsScreenState();
}

class _OfflineDraftsScreenState extends State<OfflineDraftsScreen> {
  final Set<String> _selectedIds = {};
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isResident = user?.role == 'Resident';
    final title = isResident ? 'Offline Drafts & History' : 'Pending Sync';

    final queueRepo = context.watch<OfflineQueueRepository>();
    final allItems = queueRepo.items;
    final items = user == null
        ? allItems
        : allItems.where((i) => i.ownerId == null || i.ownerId == user.id).toList();

    final connectivity = context.watch<ConnectivityProvider>();
    final isOnline = connectivity.isOnline && !AppRouter.userChoseOffline;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: context.brand,
        foregroundColor: Colors.white,
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedIds.length == items.length) {
                    _selectedIds.clear();
                  } else {
                    _selectedIds.addAll(items.map((i) => i.id));
                  }
                });
              },
              child: Text(
                _selectedIds.length == items.length ? 'Deselect All' : 'Select All',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.drafts_outlined, size: 72, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Walang Naka-save na Draft',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ang anumang reklamo o ulat na ginawa offline ay lalabas dito para mai-sync.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = _selectedIds.contains(item.id);
                return _buildDraftCard(item, isSelected, isResident, isOnline);
              },
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_selectedIds.length} napili',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.brand,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: (_selectedIds.isEmpty || _isSyncing)
                          ? null
                          : () => _submitSelected(items.where((i) => _selectedIds.contains(i.id)).toList()),
                      icon: _isSyncing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: Text(_isSyncing ? 'Sini-sync...' : 'Submit Selected'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDraftCard(OfflineQueueItem item, bool isSelected, bool isResident, bool isOnline) {
    final payload = item.payload;
    final category = payload['category']?.toString() ?? 'Complaint';
    final narrative = payload['narrative']?.toString() ?? '';
    final location = payload['location']?.toString() ?? 'No location specified';
    final formattedDate = DateFormat('MMM d, yyyy · h:mm a').format(item.deviceTime);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected ? context.brand : Colors.grey.shade200,
          width: isSelected ? 1.8 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: isSelected,
                  activeColor: context.brand,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selectedIds.add(item.id);
                      } else {
                        _selectedIds.remove(item.id);
                      }
                    });
                  },
                ),
                _buildTypeIcon(item.type),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(formattedDate, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                _buildStateBadge(item.state),
              ],
            ),
            const Divider(height: 18),
            if (narrative.isNotEmpty) ...[
              Text(
                narrative,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, height: 1.3),
              ),
              const SizedBox(height: 8),
            ] else ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber.shade900),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Walang salaysay — I-tap ang "Edit" para lagyan ng detalye bago i-submit',
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
                if (item.evidencePaths.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attach_file, size: 12, color: Colors.blue.shade800),
                        const SizedBox(width: 2),
                        Text(
                          '${item.evidencePaths.length}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (item.lastError != null && item.lastError!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: Colors.red.shade800),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.lastError!,
                        style: TextStyle(fontSize: 11.5, color: Colors.red.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (item.type == 'complaint')
                  TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FileComplaintScreen(draftId: item.id),
                        ),
                      );
                    },
                  ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete'),
                  onPressed: () => _confirmDelete(item.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon(String type) {
    IconData icon;
    Color color;
    switch (type) {
      case 'note':
        icon = Icons.note_alt_outlined;
        color = Colors.indigo;
        break;
      case 'hearing_outcome':
        icon = Icons.gavel;
        color = Colors.purple;
        break;
      case 'status_change':
        icon = Icons.published_with_changes;
        color = Colors.teal;
        break;
      case 'complaint':
      default:
        icon = Icons.report_problem_outlined;
        color = const Color(0xFFD61314);
        break;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
      child: Icon(icon, size: 18, color: color),
    );
  }

  Widget _buildStateBadge(String state) {
    Color bg;
    Color fg;
    String label;
    switch (state) {
      case 'synced':
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        label = 'Synced';
        break;
      case 'sending':
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade900;
        label = 'Sending...';
        break;
      case 'failed':
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
        label = 'Failed';
        break;
      case 'conflict':
        bg = Colors.deepOrange.shade100;
        fg = Colors.deepOrange.shade900;
        label = 'Conflict';
        break;
      case 'draft':
      default:
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        label = 'Draft';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Draft?'),
        content: const Text('Are you sure you want to permanently delete this offline draft?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<OfflineQueueRepository>().delete(id);
      _selectedIds.remove(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft deleted.')),
        );
      }
    }
  }

  Future<void> _submitSelected(List<OfflineQueueItem> selectedItems) async {
    final connectivity = context.read<ConnectivityProvider>();
    if (!connectivity.isOnline || AppRouter.userChoseOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot sync while offline. Please connect to the internet first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user != null && user.role == 'Resident' && user.residentId == null) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Resident Profile Required'),
          content: const Text('You need to complete your resident verification profile before submitting drafts to the Barangay.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Later')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx, true);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ResidentRegistrationScreen()));
              },
              child: const Text('Complete Profile'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _isSyncing = true);
    final queueRepo = context.read<OfflineQueueRepository>();
    final complaintProvider = context.read<ComplaintProvider>();
    final evidenceProvider = context.read<EvidenceProvider>();

    int successCount = 0;
    int failureCount = 0;

    for (final item in selectedItems) {
      if (item.type == 'complaint') {
        try {
          final p = item.payload;
          final detailsText = (p['narrative']?.toString() ?? p['details']?.toString() ?? '').trim();
          final locationText = (p['location']?.toString() ?? '').trim();

          if (detailsText.isEmpty) {
            failureCount++;
            await queueRepo.updateState(
              item.id,
              'failed',
              error: 'Kulang ang salaysay (Details is required). I-tap ang "Edit" para lagyan ng detalye bago i-submit.',
            );
            continue;
          }

          if (locationText.isEmpty) {
            failureCount++;
            await queueRepo.updateState(
              item.id,
              'failed',
              error: 'Kulang ang lokasyon. I-tap ang "Edit" para lagyan ng lugar bago i-submit.',
            );
            continue;
          }

          await queueRepo.updateState(item.id, 'sending');
          final dateStr = p['incident_date']?.toString() ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
          final timeStr = p['incident_time']?.toString() ?? '12:00:00';

          final complaintId = await complaintProvider.submitComplaint(
            complainantId: user?.residentId,
            respondentId: p['respondent_id'] is int ? p['respondent_id'] as int : null,
            category: p['category']?.toString() ?? 'Others',
            location: locationText,
            latitude: (p['latitude'] as num?)?.toDouble(),
            longitude: (p['longitude'] as num?)?.toDouble(),
            date: dateStr,
            time: timeStr,
            details: detailsText,
            clientUuid: item.id,
          );

          // Upload evidence files
          for (final path in item.evidencePaths) {
            try {
              final file = File(path);
              if (await file.exists()) {
                final bytes = await file.readAsBytes();
                final pFile = PlatformFile(
                  name: file.uri.pathSegments.last,
                  size: bytes.length,
                  path: file.path,
                  bytes: bytes,
                );
                await evidenceProvider.uploadEvidence(complaintId: complaintId, file: pFile);
              }
            } catch (evErr) {
              debugPrint('[OfflineDraftsScreen] Evidence upload warning: $evErr');
            }
          }

          await queueRepo.updateState(item.id, 'synced');
          await queueRepo.delete(item.id);
          _selectedIds.remove(item.id);
          successCount++;
        } catch (e) {
          failureCount++;
          String friendlyError;
          if (e is DioException) {
            final data = e.response?.data;
            if (data is Map && data['message'] is String) {
              friendlyError = data['message'] as String;
            } else if (e.message != null && e.message!.isNotEmpty) {
              friendlyError = e.message!;
            } else {
              friendlyError = 'Network error (${e.response?.statusCode ?? 'no response'})';
            }
          } else {
            friendlyError = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
          }

          if (friendlyError.contains("'details' is required")) {
            friendlyError = 'Kulang ang salaysay (Details is required). I-tap ang "Edit" para punan bago i-submit.';
          }

          await queueRepo.updateState(item.id, 'failed', error: friendlyError);
        }
      }
    }

    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failureCount == 0
              ? 'Successfully synced $successCount item(s)!'
              : 'Synced $successCount item(s). $failureCount failed to sync.'),
          backgroundColor: failureCount == 0 ? Colors.green : Colors.orange,
        ),
      );
    }
  }
}
