import 'dart:io';
import 'package:dio/dio.dart' show DioException;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/offline_queue_item.dart';
import '../../data/repositories/offline_queue_repository.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/complaint_provider.dart';
import '../../presentation/providers/evidence_provider.dart';
import '../../presentation/screens/profile/resident_registration_screen.dart';

class SyncManager {
  static Future<void> handleProceedToOnline(BuildContext context) async {
    final queueRepo = context.read<OfflineQueueRepository>();
    final auth = context.read<AuthProvider>();
    final user = auth.user;

    final drafts = await queueRepo.getAll();
    final pendingDrafts = drafts.where((d) => d.state == 'draft' || d.state == 'failed').toList();

    if (user != null && user.role == 'Resident' && user.residentId == null && pendingDrafts.isNotEmpty) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Resident Profile Required'),
            content: Text(
              'You have ${pendingDrafts.length} unsent complaint draft(s). Please complete your resident verification profile before submitting them.',
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Later'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ResidentRegistrationScreen()),
                  );
                },
                child: const Text('Complete Profile'),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (pendingDrafts.isNotEmpty && context.mounted) {
      showSyncReviewModal(context, pendingDrafts);
    }
  }

  static void showSyncReviewModal(BuildContext context, List<OfflineQueueItem> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SyncReviewSheet(items: items),
    );
  }
}

class _SyncReviewSheet extends StatefulWidget {
  final List<OfflineQueueItem> items;
  const _SyncReviewSheet({required this.items});

  @override
  State<_SyncReviewSheet> createState() => _SyncReviewSheetState();
}

class _SyncReviewSheetState extends State<_SyncReviewSheet> {
  bool _isSyncing = false;
  int _currentIndex = 0;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.sync_rounded, color: Color(0xFFD61314), size: 24),
              const SizedBox(width: 10),
              Text(
                'Sync Offline Items (${widget.items.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'The following offline items are ready to be sent to the Barangay server:',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.items.length,
              separatorBuilder: (_, __) => const Divider(height: 8),
              itemBuilder: (ctx, i) {
                final item = widget.items[i];
                final category = item.payload['category']?.toString() ?? 'Complaint';
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined, color: Colors.blueGrey),
                  title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    DateFormat('MMM d, h:mm a').format(item.deviceTime),
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Text(item.state.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: item.state == 'failed' ? Colors.red : Colors.orange,
                      )),
                );
              },
            ),
          ),
          if (_isSyncing) ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: widget.items.isEmpty ? 1 : (_currentIndex / widget.items.length),
              color: const Color(0xFFD61314),
            ),
            const SizedBox(height: 8),
            Text(_statusMessage, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSyncing ? null : () => Navigator.pop(context),
                  child: const Text('Review Later'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD61314),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isSyncing ? null : _syncAll,
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: const Text('Sync All Now'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _syncAll() async {
    setState(() {
      _isSyncing = true;
      _currentIndex = 0;
      _statusMessage = 'Starting sync...';
    });

    final queueRepo = context.read<OfflineQueueRepository>();
    final complaintProvider = context.read<ComplaintProvider>();
    final evidenceProvider = context.read<EvidenceProvider>();
    final user = context.read<AuthProvider>().user;

    int success = 0;
    int failed = 0;

    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      setState(() {
        _currentIndex = i + 1;
        _statusMessage = 'Submitting item ${i + 1} of ${widget.items.length}...';
      });

      if (item.type == 'complaint') {
        try {
          final p = item.payload;
          final detailsText = (p['narrative']?.toString() ?? p['details']?.toString() ?? '').trim();
          final locationText = (p['location']?.toString() ?? '').trim();

          if (detailsText.isEmpty) {
            failed++;
            await queueRepo.updateState(
              item.id,
              'failed',
              error: 'Kulang ang salaysay (Details is required). I-tap ang "Edit" para lagyan ng detalye bago i-submit.',
            );
            continue;
          }

          if (locationText.isEmpty) {
            failed++;
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

          // 1. Submit complaint payload first
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

          // 2. Submit evidence uploads
          setState(() {
            _statusMessage = 'Uploading evidence for complaint #$complaintId...';
          });
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
            } catch (_) {}
          }

          await queueRepo.updateState(item.id, 'synced');
          await queueRepo.delete(item.id);
          success++;
        } catch (e) {
          failed++;
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
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failed == 0
              ? 'Successfully synced all $success item(s)!'
              : 'Synced $success item(s). $failed item(s) failed and remain saved for retry.'),
          backgroundColor: failed == 0 ? Colors.green : Colors.orange,
        ),
      );
    }
  }
}
