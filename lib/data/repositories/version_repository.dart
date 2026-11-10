import '../../config/app_constants.dart';
import '../../core/network/api_client.dart';
import '../models/app_version_info.dart';

class VersionRepository {
  final ApiClient _apiClient;

  VersionRepository(this._apiClient);

  Future<AppVersionInfo> checkLatestVersion() async {
    try {
      final response = await _apiClient.get(AppConstants.publicVersion);
      final data = response.data['data'] as Map<String, dynamic>;
      return AppVersionInfo.fromJson(data);
    } catch (_) {
      // Fallback default info if network/server is unavailable
      return const AppVersionInfo(
        latestVersion: AppConstants.appVersion,
        buildNumber: AppConstants.buildNumber,
        downloadUrl: 'https://github.com/JOls-00/baratrack-app/releases/latest/download/app-release.apk',
        releaseNotes: '',
      );
    }
  }

  Future<void> updateVersionSettings({
    required String latestVersion,
    required int buildNumber,
    required String downloadUrl,
    required String releaseNotes,
    required bool forceUpdate,
  }) async {
    await _apiClient.post(
      AppConstants.adminVersion,
      data: {
        'latest_version': latestVersion,
        'build_number': buildNumber,
        'download_url': downloadUrl,
        'release_notes': releaseNotes,
        'force_update': forceUpdate,
      },
    );
  }
}
