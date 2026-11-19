import 'dart:io';
import 'package:dio/dio.dart' show DioException;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_constants.dart';
import '../../data/models/offline_queue_item.dart';
import '../../data/repositories/offline_queue_repository.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/complaint_provider.dart';
import '../../presentation/providers/evidence_provider.dart';
import '../../presentation/providers/locale_provider.dart';
import '../../presentation/screens/offline/conflict_dialog.dart';
import '../../presentation/screens/profile/resident_registration_screen.dart';
import '../network/api_client.dart';
import '../router/app_router.dart';

class SyncManager {
  static Future<void> handleProceedToOnline(BuildContext context) async {
    final navCtx = AppRouter.navigatorKey.currentContext ?? context;
    final queueRepo = navCtx.read<OfflineQueueRepository>();
    final auth = navCtx.read<AuthProvider>();
    final user = auth.user;

    final drafts = await queueRepo.getAll();
    final pendingDrafts = drafts.where((d) => d.state == 'draft' || d.state == 'failed').toList();

    if (user != null && user.role == 'Resident' && user.residentId == null && pendingDrafts.isNotEmpty) {
      if (navCtx.mounted) {
        final isFil = navCtx.read<LocaleProvider>().isFilipino;
        showDialog(
          context: navCtx,
          builder: (ctx) => AlertDialog(
            title: Text(isFil ? 'Kailangan ang Resident Profile' : 'Resident Profile Required'),
            content: Text(
              isFil
                  ? 'May ${pendingDrafts.length} hindi pa naipapadalang draft. Kumpletuhin muna ang iyong resident profile bago mag-sync.'
                  : 'You have ${pendingDrafts.length} unsent complaint draft(s). Please complete your resident verification profile before submitting them.',
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isFil ? 'Mamaya' : 'Later'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    navCtx,
                    MaterialPageRoute(builder: (_) => const ResidentRegistrationScreen()),
                  );
                },
                child: Text(isFil ? 'Kumpletuhin ang Profile' : 'Complete Profile'),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (pendingDrafts.isNotEmpty && navCtx.mounted) {
      showSyncReviewModal(navCtx, pendingDrafts);
    }
  }

  static void showSyncReviewModal(BuildContext context, List<OfflineQueueItem> items) {
    final navCtx = AppRouter.navigatorKey.currentContext ?? context;
    showModalBottomSheet(
      context: navCtx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SyncReviewSheet(items: items),
    );
  }

  /// Syncs a single queued item across all supported offline types ('complaint', 'note',
  /// 'status_change', 'hearing_outcome'). Shared by SyncManager and OfflineDraftsScreen.
  static Future<bool> syncSingleItem(
    BuildContext context,
    OfflineQueueItem item, {
    ValueChanged<String>? onProgress,
  }) async {
    final queueRepo = context.read<OfflineQueueRepository>();
    final complaintProvider = context.read<ComplaintProvider>();
    final evidenceProvider = context.read<EvidenceProvider>();
    final apiClient = context.read<ApiClient>();
    final user = context.read<AuthProvider>().user;
    final isFil = context.read<LocaleProvider>().isFilipino;

    final p = item.payload;

    try {
      if (item.type == 'complaint') {
        final detailsText = (p['narrative']?.toString() ?? p['details']?.toString() ?? '').trim();
        final locationText = (p['location']?.toString() ?? '').trim();

        if (detailsText.isEmpty) {
          await queueRepo.updateState(
            item.id,
            'failed',
            error: isFil
                ? 'Kulang ang salaysay (Details is required). I-tap ang "Edit" para lagyan ng detalye bago i-submit.'
                : 'Narrative is required. Tap "Edit" to add complaint details before submitting.',
          );
          return false;
        }

        if (locationText.isEmpty) {
          await queueRepo.updateState(
            item.id,
            'failed',
            error: isFil
                ? 'Kulang ang lokasyon. I-tap ang "Edit" para lagyan ng lugar bago i-submit.'
                : 'Incident location is required. Tap "Edit" to add a location before submitting.',
          );
          return false;
        }

        final dynamic rawComplainantId = p['complainant_id'];
        final int? resolvedComplainantId =
            rawComplainantId is int ? rawComplainantId : user?.residentId;
        if (resolvedComplainantId == null) {
          await queueRepo.updateState(
            item.id,
            'failed',
            error: isFil
                ? 'Walang naka-link na Complainant Resident ID. Paki-verify muna ang iyong Resident Profile.'
                : 'Missing complainant Resident ID. Please complete your resident profile or select a resident.',
          );
          return false;
        }

        await queueRepo.updateState(item.id, 'sending');
        final dateStr = p['incident_date']?.toString() ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
        final timeStr = p['incident_time']?.toString() ?? '12:00:00';

        final complaintId = await complaintProvider.submitComplaint(
          complainantId: resolvedComplainantId,
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

        if (!kIsWeb && item.evidencePaths.isNotEmpty) {
          onProgress?.call(isFil
              ? 'Ina-upload ang ebidensya para sa reklamo #$complaintId...'
              : 'Uploading evidence for complaint #$complaintId...');
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
        }
      } else if (item.type == 'note') {
        final caseId = p['case_id'];
        final noteText = (p['note']?.toString() ?? '').trim();
        if (caseId == null || noteText.isEmpty) {
          await queueRepo.updateState(
            item.id,
            'failed',
            error: isFil ? 'Kulang ang case ID o tala.' : 'Case ID or note text is missing.',
          );
          return false;
        }
        await queueRepo.updateState(item.id, 'sending');
        try {
          await apiClient.put(
            '${AppConstants.cases}/$caseId',
            data: {
              'note': noteText,
              'client_uuid': item.id,
              if (item.baseUpdatedAt != null && item.baseUpdatedAt!.isNotEmpty)
                'base_updated_at': item.baseUpdatedAt,
            },
          );
        } on DioException catch (e) {
          if (e.response?.statusCode == 409 && context.mounted) {
            final server = e.response?.data?['server_version'] as Map? ?? {};
            final choice = await ConflictDialog.show(
              context,
              title: p['case_number']?.toString() ?? 'Case #$caseId',
              localValue: noteText,
              serverValue: server['remarks']?.toString() ?? '(Updated on server)',
              serverUpdatedAt: server['updated_at']?.toString() ?? '',
            );
            if (choice == ConflictChoice.keepMine) {
              await apiClient.put(
                '${AppConstants.cases}/$caseId',
                data: {'note': noteText, 'client_uuid': item.id, 'force': true},
              );
            } else if (choice == ConflictChoice.useServer) {
              await queueRepo.delete(item.id);
              return true;
            } else {
              rethrow;
            }
          } else {
            rethrow;
          }
        }
      } else if (item.type == 'status_change') {
        final caseId = p['case_id'];
        final status = p['status']?.toString();
        final remarks = p['remarks']?.toString() ?? '';
        if (caseId == null || status == null || status.isEmpty) {
          await queueRepo.updateState(
            item.id,
            'failed',
            error: isFil ? 'Kulang ang case ID o status.' : 'Case ID or target status is missing.',
          );
          return false;
        }
        await queueRepo.updateState(item.id, 'sending');
        try {
          await apiClient.put(
            '${AppConstants.cases}/$caseId/status',
            data: {
              'status': status,
              'remarks': remarks,
              if (item.baseUpdatedAt != null && item.baseUpdatedAt!.isNotEmpty)
                'base_updated_at': item.baseUpdatedAt,
            },
          );
        } on DioException catch (e) {
          if (e.response?.statusCode == 409 && context.mounted) {
            final server = e.response?.data?['server_version'] as Map? ?? {};
            final choice = await ConflictDialog.show(
              context,
              title: p['case_number']?.toString() ?? 'Case #$caseId',
              localValue: '$status${remarks.isNotEmpty ? ' — $remarks' : ''}',
              serverValue: '${server['status'] ?? ''} ${server['remarks'] ?? ''}'.trim(),
              serverUpdatedAt: server['updated_at']?.toString() ?? '',
            );
            if (choice == ConflictChoice.keepMine) {
              await apiClient.put(
                '${AppConstants.cases}/$caseId/status',
                data: {'status': status, 'remarks': remarks, 'force': true},
              );
            } else if (choice == ConflictChoice.useServer) {
              await queueRepo.delete(item.id);
              return true;
            } else {
              rethrow;
            }
          } else {
            rethrow;
          }
        }
      } else if (item.type == 'hearing_outcome') {
        final hearingId = p['hearing_id'];
        final status = p['status']?.toString() ?? 'Completed';
        final notes = p['notes']?.toString() ?? '';
        if (hearingId == null) {
          await queueRepo.updateState(
            item.id,
            'failed',
            error: isFil ? 'Kulang ang hearing ID.' : 'Hearing ID is missing.',
          );
          return false;
        }
        await queueRepo.updateState(item.id, 'sending');
        await apiClient.put(
          '${AppConstants.hearings}/$hearingId',
          data: {'status': status, 'notes': notes},
        );
      } else {
        await queueRepo.updateState(
          item.id,
          'failed',
          error: isFil ? 'Hindi kilalang uri ng draft (${item.type}).' : 'Unsupported draft type (${item.type}).',
        );
        return false;
      }

      await queueRepo.updateState(item.id, 'synced');
      await queueRepo.delete(item.id);
      return true;
    } catch (e) {
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
        friendlyError = isFil
            ? 'Kulang ang salaysay (Details is required). I-tap ang "Edit" para punan bago i-submit.'
            : 'Narrative is required. Tap "Edit" to fill it before submitting.';
      }

      await queueRepo.updateState(item.id, 'failed', error: friendlyError);
      return false;
    }
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
                final title = item.payload['title']?.toString() ??
                    item.payload['category']?.toString() ??
                    item.payload['case_number']?.toString() ??
                    item.type;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined, color: Colors.blueGrey),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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

    int success = 0;
    int failed = 0;

    for (int i = 0; i < widget.items.length; i++) {
      if (!mounted) return;
      final item = widget.items[i];
      setState(() {
        _currentIndex = i + 1;
        _statusMessage = 'Submitting item ${i + 1} of ${widget.items.length}...';
      });

      final ok = await SyncManager.syncSingleItem(
        context,
        item,
        onProgress: (msg) {
          if (mounted) setState(() => _statusMessage = msg);
        },
      );
      if (ok) {
        success++;
      } else {
        failed++;
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
