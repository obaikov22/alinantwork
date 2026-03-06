import 'package:dio/dio.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseNotes;

  const UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
  });
}

class UpdateService {
  static const _repoOwner = 'obaikov22';
  static const _repoName = 'alinantwork';
  static const _apiUrl =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  static final _dio = Dio();

  /// Returns [UpdateInfo] if a newer version is available, or null otherwise.
  /// Returns null silently on 404 (no release yet) or any network error.
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _apiUrl,
        options: Options(
          headers: {'Accept': 'application/vnd.github+json'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 404 || response.data == null) return null;

      final data = response.data!;
      final tagName = (data['tag_name'] as String? ?? '').replaceFirst('v', '');
      final releaseNotes = (data['body'] as String? ?? '').trim();

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (!_isNewer(tagName, currentVersion)) return null;

      final assets = data['assets'] as List<dynamic>? ?? [];
      final apkAsset = assets.cast<Map<String, dynamic>>().where(
        (a) => (a['name'] as String? ?? '').endsWith('.apk'),
      ).firstOrNull;

      if (apkAsset == null) return null;

      return UpdateInfo(
        version: tagName,
        downloadUrl: apkAsset['browser_download_url'] as String,
        releaseNotes: releaseNotes.isEmpty ? 'No release notes provided.' : releaseNotes,
      );
    } catch (_) {
      return null;
    }
  }

  /// Downloads the APK and triggers installation.
  /// [onProgress] receives values from 0.0 to 1.0.
  static Future<void> downloadAndInstall(
    String url,
    void Function(double progress) onProgress,
  ) async {
    final tmpDir = await getTemporaryDirectory();
    final savePath = '${tmpDir.path}/alinantwork_update.apk';

    await _dio.download(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress(received / total);
      },
    );

    await OpenFile.open(savePath);
  }

  /// Compares two semver strings (e.g. "1.2.3").
  /// Returns true if [remote] is strictly greater than [current].
  static bool _isNewer(String remote, String current) {
    final r = _parseParts(remote);
    final c = _parseParts(current);
    for (var i = 0; i < 3; i++) {
      if (r[i] > c[i]) return true;
      if (r[i] < c[i]) return false;
    }
    return false;
  }

  static List<int> _parseParts(String version) {
    final parts = version.split('.');
    return List.generate(3, (i) => i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0);
  }
}
