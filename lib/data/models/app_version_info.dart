class AppVersionInfo {
  final String latestVersion;
  final int buildNumber;
  final String downloadUrl;
  final String releaseNotes;
  final bool forceUpdate;
  final String? publishedAt;

  const AppVersionInfo({
    required this.latestVersion,
    required this.buildNumber,
    required this.downloadUrl,
    required this.releaseNotes,
    this.forceUpdate = false,
    this.publishedAt,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      latestVersion: (json['latest_version'] ?? '1.0.0').toString(),
      buildNumber: int.tryParse(json['build_number']?.toString() ?? '1') ?? 1,
      downloadUrl: (json['download_url'] ?? '').toString(),
      releaseNotes: (json['release_notes'] ?? '').toString(),
      forceUpdate: json['force_update'] == true || json['force_update'] == 1 || json['force_update'] == '1',
      publishedAt: json['published_at']?.toString(),
    );
  }

  /// Returns true if this remote version is newer than the provided current version and build number.
  bool isNewerThan(String currentVersion, int currentBuild) {
    final cmp = _compareSemVer(latestVersion, currentVersion);
    if (cmp > 0) return true;
    if (cmp == 0 && buildNumber > currentBuild) return true;
    return false;
  }

  static int _compareSemVer(String v1, String v2) {
    // Strip any +build suffixes
    final clean1 = v1.split('+').first.trim();
    final clean2 = v2.split('+').first.trim();

    final parts1 = clean1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = clean2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;
    for (int i = 0; i < maxLen; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }
}
