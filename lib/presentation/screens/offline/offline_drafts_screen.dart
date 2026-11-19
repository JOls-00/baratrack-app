import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../data/models/offline_queue_item.dart';
import '../../../data/repositories/offline_queue_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
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
    final isFil = context.watch<LocaleProvider>().isFilipino;
    final isResident = user?.role == 'Resident';
    final title = isResident
        ? (isFil ? 'Mga Draft at Kasaysayan Offline' : 'Offline Drafts & History')
        : (isFil ? 'Nakabinbing Pag-sync' : 'Pending Sync');

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
                _selectedIds.length == items.length
                    ? (isFil ? 'Alisin Lahat' : 'Deselect All')
                    : (isFil ? 'Piliin Lahat' : 'Select All'),
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
                      isFil ? 'Walang Naka-save na Draft' : 'No Saved Drafts',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isFil
                          ? 'Ang anumang reklamo o ulat na ginawa offline ay lalabas dito para mai-sync.'
                          : 'Any complaint or report made offline will appear here for syncing.',
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
                return _buildDraftCard(item, isSelected, isResident, isOnline, isFil);
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
                        isFil ? '${_selectedIds.length} napili' : '${_selectedIds.length} selected',
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
                      label: Text(
                        _isSyncing
                            ? (isFil ? 'Sini-sync...' : 'Syncing...')
                            : (isFil ? 'I-submit ang Napili' : 'Submit Selected'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDraftCard(OfflineQueueItem item, bool isSelected, bool isResident, bool isOnline, bool isFil) {
    final payload = item.payload;
    final category = payload['category']?.toString() ?? 'Complaint';
    final narrative = payload['narrative']?.toString() ?? '';
    final location = payload['location']?.toString() ?? 'No location specified';
    final formattedDate = DateFormat('MMM d, yyyy · h:mm a').format(item.deviceTime);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected ? context.brand : Theme.of(context).dividerColor,
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
                  color: dark ? Colors.amber.shade900.withValues(alpha: 0.25) : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: dark ? Colors.amber.shade700 : Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: dark ? Colors.amber.shade300 : Colors.amber.shade900),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isFil
                            ? 'Walang salaysay — I-tap ang "Edit" para lagyan ng detalye bago i-submit'
                            : 'No narrative — Tap "Edit" to provide details before submitting',
                        style: TextStyle(fontSize: 12, color: dark ? Colors.amber.shade200 : Colors.amber.shade900, fontWeight: FontWeight.w600),
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
                      color: dark ? Colors.blue.shade900.withValues(alpha: 0.25) : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: dark ? Colors.blue.shade700 : Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attach_file, size: 12, color: dark ? Colors.blue.shade300 : Colors.blue.shade800),
                        const SizedBox(width: 2),
                        Text(
                          '${item.evidencePaths.length}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: dark ? Colors.blue.shade200 : Colors.blue.shade900),
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
                  color: dark ? Colors.red.shade900.withValues(alpha: 0.25) : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: dark ? Colors.red.shade700 : Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: dark ? Colors.red.shade300 : Colors.red.shade800),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.lastError!,
                        style: TextStyle(fontSize: 11.5, color: dark ? Colors.red.shade200 : Colors.red.shade900),
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
                    label: Text(isFil ? 'I-edit' : 'Edit'),
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
                  label: Text(isFil ? 'Burahin' : 'Delete'),
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
    final isFil = context.read<LocaleProvider>().isFilipino;
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
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isFil ? 'Kailangan ang Resident Profile' : 'Resident Profile Required'),
          content: Text(
            isFil
                ? 'Kumpletuhin muna ang iyong resident verification profile bago magsumite ng drafts.'
                : 'You need to complete your resident verification profile before submitting drafts to the Barangay.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isFil ? 'Mamaya' : 'Later'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ResidentRegistrationScreen()),
                );
              },
              child: Text(isFil ? 'Kumpletuhin ang Profile' : 'Complete Profile'),
            ),
          ],
        ),
      );
      if (!mounted || auth.user?.residentId == null) return;
    }

    setState(() => _isSyncing = true);

    int successCount = 0;
    int failureCount = 0;

    for (final item in selectedItems) {
      if (!mounted) return;
      final ok = await SyncManager.syncSingleItem(context, item);
      if (ok) {
        _selectedIds.remove(item.id);
        successCount++;
      } else {
        failureCount++;
      }
    }

    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failureCount == 0
              ? (isFil ? 'Matagumpay na na-sync ang $successCount item!' : 'Successfully synced $successCount item(s)!')
              : (isFil ? 'Na-sync: $successCount. Nabigo: $failureCount.' : 'Synced $successCount item(s). $failureCount failed to sync.')),
          backgroundColor: failureCount == 0 ? Colors.green : Colors.orange,
        ),
      );
    }
  }
}
