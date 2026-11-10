import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_constants.dart';
import '../../data/models/app_version_info.dart';

class UpdatePromptDialog extends StatelessWidget {
  final AppVersionInfo info;

  const UpdatePromptDialog({super.key, required this.info});

  static Future<void> show(BuildContext context, AppVersionInfo info) {
    return showDialog(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (context) => UpdatePromptDialog(info: info),
    );
  }

  Future<void> _launchDownload(BuildContext context) async {
    final uri = Uri.tryParse(info.downloadUrl);
    if (uri != null) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !info.forceUpdate,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.fromLTRB(16, 16, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.system_update, color: theme.colorScheme.primary, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update Available',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'BaraTrack v${info.latestVersion}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    'Latest: v${info.latestVersion}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (info.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                "What's New:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 140),
                child: SingleChildScrollView(
                  child: Text(
                    info.releaseNotes,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                'A new version with performance improvements and bug fixes is ready to download.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (info.forceUpdate) ...[
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
        ),
        actions: [
          if (!info.forceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Update Now', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              _launchDownload(context);
              if (!info.forceUpdate) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}
