import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_constants.dart';
import '../../data/models/app_version_info.dart';

class UpdatePromptDialog extends StatefulWidget {
  final AppVersionInfo info;

  const UpdatePromptDialog({super.key, required this.info});

  static Future<void> show(BuildContext context, AppVersionInfo info) {
    return showDialog(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (context) => UpdatePromptDialog(info: info),
    );
  }

  @override
  State<UpdatePromptDialog> createState() => _UpdatePromptDialogState();
}

class _UpdatePromptDialogState extends State<UpdatePromptDialog> {
  bool _isDownloading = false;
  bool _isInstalling = false;
  double _progress = 0.0;
  String _progressText = '0%';
  String _downloadedMbText = '0.0 MB';
  String? _errorMessage;
  CancelToken? _cancelToken;

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _startUpdate() async {
    if (kIsWeb) {
      setState(() {
        _isDownloading = true;
        _progress = 1.0;
        _progressText = '100%';
        _downloadedMbText = 'Refreshing web app...';
      });
      await Future.delayed(const Duration(milliseconds: 1000));
      final uri = Uri.parse(widget.info.downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      return;
    }

    setState(() {
      _isDownloading = true;
      _isInstalling = false;
      _errorMessage = null;
      _progress = 0.0;
      _progressText = '0%';
      _downloadedMbText = 'Preparing download...';
    });

    _cancelToken = CancelToken();

    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/baratrack_v${widget.info.latestVersion}.apk';
      final file = File(savePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }

      final dio = Dio();
      await dio.download(
        widget.info.downloadUrl,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            final progress = received / total;
            final downloadedMb = (received / (1024 * 1024)).toStringAsFixed(1);
            final totalMb = (total / (1024 * 1024)).toStringAsFixed(1);
            setState(() {
              _progress = progress;
              _progressText = '${(progress * 100).toInt()}%';
              _downloadedMbText = '$downloadedMb MB / $totalMb MB';
            });
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _isInstalling = true;
        _progress = 1.0;
        _progressText = '100%';
        _downloadedMbText = 'Download complete! Starting installer...';
      });

      // Automatically launch Android package installer
      final result = await OpenFilex.open(
        savePath,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done && mounted) {
        setState(() {
          _isDownloading = false;
          _isInstalling = false;
          _errorMessage = 'Could not launch package installer automatically (${result.message}). Please tap below to update.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      String friendlyMsg = 'Download failed. Please check your internet connection and try again.';
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          friendlyMsg = 'The update package is currently being generated on the server (release in progress). Please tap "Update Now" again in 1–2 minutes.';
        } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
          friendlyMsg = 'Connection timed out. Please check your internet connection and try again.';
        } else {
          friendlyMsg = 'Server responded with code ${e.response?.statusCode ?? 'error'}. Please try again shortly.';
        }
      }
      setState(() {
        _isDownloading = false;
        _isInstalling = false;
        _errorMessage = friendlyMsg;
      });
    }
  }

  List<Widget> _buildFeatureList(String raw, Color primary) {
    final parts = raw.split(RegExp(r'[,;\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) {
      return [
        const Text('Performance improvements and bug fixes.', style: TextStyle(fontSize: 12, color: Colors.black87)),
      ];
    }
    return parts.map((part) {
      IconData icon = Icons.check_circle_outline;
      final lower = part.toLowerCase();
      if (lower.contains('id') || lower.contains('photo') || lower.contains('verification')) {
        icon = Icons.badge_outlined;
      } else if (lower.contains('track')) {
        icon = Icons.track_changes;
      } else if (lower.contains('announcement') || lower.contains('bulletin')) {
        icon = Icons.campaign_outlined;
      } else if (lower.contains('updater') || lower.contains('install')) {
        icon = Icons.system_update_alt;
      } else if (lower.contains('offline') || lower.contains('cache')) {
        icon = Icons.wifi_off_outlined;
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                part,
                style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return PopScope(
      canPop: !widget.info.forceUpdate && !_isDownloading,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.fromLTRB(16, 16, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isDownloading
                    ? (_isInstalling ? Icons.system_security_update_good : Icons.downloading_rounded)
                    : Icons.system_update_rounded,
                color: primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isDownloading
                        ? (_isInstalling ? 'Starting Installation' : 'Updating BaraTrack')
                        : 'Update Available',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'BaraTrack v${widget.info.latestVersion}',
                    style: TextStyle(
                      color: primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            if (_isDownloading) ...[
              const SizedBox(height: 12),
              Text(
                _isInstalling
                    ? 'Launching Android Package Installer...'
                    : 'Downloading latest update directly to your phone...',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _progressText,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primary),
                  ),
                  Text(
                    _downloadedMbText,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Please do not close this screen while updating.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current: v${AppConstants.appVersion}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                    ),
                    const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                    Text(
                      'Latest: v${widget.info.latestVersion}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                "What's New in This Version:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildFeatureList(widget.info.releaseNotes, primary),
                ),
              ),
              if (widget.info.forceUpdate) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.amber.shade900),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This update is required to keep using the application.',
                          style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
        actions: [
          if (!_isDownloading && !widget.info.forceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
          if (!_isDownloading)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Update Now', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _startUpdate,
            )
          else if (_isDownloading && !_isInstalling)
            TextButton(
              onPressed: () {
                _cancelToken?.cancel();
                setState(() {
                  _isDownloading = false;
                  _errorMessage = 'Download cancelled.';
                });
              },
              child: const Text('Cancel Download', style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
    );
  }
}
