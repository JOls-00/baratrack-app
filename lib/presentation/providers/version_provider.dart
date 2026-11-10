import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../config/app_constants.dart';
import '../../core/widgets/update_prompt_dialog.dart';
import '../../data/models/app_version_info.dart';
import '../../data/repositories/version_repository.dart';

class VersionProvider extends ChangeNotifier {
  final VersionRepository _versionRepository;

  VersionProvider(this._versionRepository);

  AppVersionInfo? _latestInfo;
  bool _isChecking = false;
  bool _hasUpdate = false;
  bool _hasPromptedThisSession = false;

  AppVersionInfo? get latestInfo => _latestInfo;
  bool get isChecking => _isChecking;
  bool get hasUpdate => _hasUpdate;

  Future<void> checkForUpdates({BuildContext? context, bool manual = false}) async {
    // Only check updates on mobile platforms (Web users always load the newest build)
    if (kIsWeb && !manual) return;

    if (_isChecking) return;
    _isChecking = true;
    notifyListeners();

    try {
      final info = await _versionRepository.checkLatestVersion();
      _latestInfo = info;
      _hasUpdate = info.isNewerThan(AppConstants.appVersion, AppConstants.buildNumber);

      if (_hasUpdate) {
        if (context != null && context.mounted) {
          if (manual || !_hasPromptedThisSession) {
            _hasPromptedThisSession = true;
            UpdatePromptDialog.show(context, info);
          }
        }
      } else if (manual && context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are on the latest version of BaraTrack (v${AppConstants.appVersion}).'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking for app updates: $e');
      if (manual && context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not check for updates. Please verify your internet connection.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }
}
