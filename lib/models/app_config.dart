/// Remote app configuration fetched from Supabase `app_config` table.
/// Controls maintenance mode and version-gating for updates.
class AppConfig {
  final bool maintenanceMode;
  final String maintenanceMessage;
  final String minVersion;
  final String latestVersion;
  final String updateMessage;
  final String downloadUrl;

  const AppConfig({
    this.maintenanceMode = false,
    this.maintenanceMessage = '',
    this.minVersion = '1.0.0',
    this.latestVersion = '1.0.0',
    this.updateMessage = '',
    this.downloadUrl = '',
  });

  /// Fallback when the config table can't be reached (network error, etc.).
  /// The app continues normally — never block users due to a fetch failure.
  static const fallback = AppConfig();

  factory AppConfig.fromRow(Map<String, dynamic> row) {
    return AppConfig(
      maintenanceMode: (row['maintenance_mode'] as bool?) ?? false,
      maintenanceMessage: (row['maintenance_message'] as String?) ?? '',
      minVersion: (row['min_version'] as String?) ?? '1.0.0',
      latestVersion: (row['latest_version'] as String?) ?? '1.0.0',
      updateMessage: (row['update_message'] as String?) ?? '',
      downloadUrl: (row['download_url'] as String?) ?? '',
    );
  }
}

/// Compares two semantic version strings (e.g. "1.2.3" vs "1.3.0").
/// Returns negative if a < b, zero if equal, positive if a > b.
int compareVersions(String a, String b) {
  final partsA = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  final partsB = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();

  // Pad shorter list with zeros
  while (partsA.length < 3) {
    partsA.add(0);
  }
  while (partsB.length < 3) {
    partsB.add(0);
  }

  for (var i = 0; i < 3; i++) {
    if (partsA[i] != partsB[i]) return partsA[i] - partsB[i];
  }
  return 0;
}
