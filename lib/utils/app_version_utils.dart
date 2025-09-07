import 'package:package_info_plus/package_info_plus.dart';
import 'package:logger/logger.dart';

class AppVersionUtils {
  static final Logger _logger = Logger();
  static PackageInfo? _packageInfo;
  static String? _cachedVersion;

  /// Uygulama versiyon bilgisini alır
  /// iOS: Info.plist'ten CFBundleShortVersionString değerini alır
  /// Android: build.gradle'dan versionName değerini alır
  static Future<String> getAppVersion() async {
    try {
      // Cache'den kontrol et
      if (_cachedVersion != null) {
        return _cachedVersion!;
      }

      // PackageInfo'yu al
      _packageInfo ??= await PackageInfo.fromPlatform();
      
      // Versiyon bilgisini al
      _cachedVersion = _packageInfo!.version;
      
      _logger.i('App version loaded: $_cachedVersion');
      return _cachedVersion!;
    } catch (e) {
      _logger.e('Error getting app version: $e');
      // Hata durumunda fallback değer döndür
      return '1.0.0';
    }
  }

  /// Build number'ı alır
  static Future<String> getBuildNumber() async {
    try {
      _packageInfo ??= await PackageInfo.fromPlatform();
      return _packageInfo!.buildNumber;
    } catch (e) {
      _logger.e('Error getting build number: $e');
      return '1';
    }
  }

  /// Package name'i alır
  static Future<String> getPackageName() async {
    try {
      _packageInfo ??= await PackageInfo.fromPlatform();
      return _packageInfo!.packageName;
    } catch (e) {
      _logger.e('Error getting package name: $e');
      return 'com.rivorya.takaslyapp';
    }
  }

  /// App name'i alır
  static Future<String> getAppName() async {
    try {
      _packageInfo ??= await PackageInfo.fromPlatform();
      return _packageInfo!.appName;
    } catch (e) {
      _logger.e('Error getting app name: $e');
      return 'Takasly';
    }
  }

  /// Cache'i temizler (test amaçlı veya güncelleme sonrası)
  static void clearCache() {
    _packageInfo = null;
    _cachedVersion = null;
    _logger.i('App version cache cleared');
  }

  /// Versiyon bilgisini formatlanmış şekilde döndürür
  /// Örnek: "1.0.5 (36)"
  static Future<String> getFormattedVersion() async {
    try {
      final version = await getAppVersion();
      final buildNumber = await getBuildNumber();
      return '$version ($buildNumber)';
    } catch (e) {
      _logger.e('Error getting formatted version: $e');
      return '1.0.0 (1)';
    }
  }

  /// Versiyon karşılaştırması yapar
  /// currentVersion > targetVersion ise 1
  /// currentVersion == targetVersion ise 0
  /// currentVersion < targetVersion ise -1
  static Future<int> compareVersion(String targetVersion) async {
    try {
      final currentVersion = await getAppVersion();
      return _compareVersionStrings(currentVersion, targetVersion);
    } catch (e) {
      _logger.e('Error comparing versions: $e');
      return 0;
    }
  }

  /// İki versiyon string'ini karşılaştırır
  static int _compareVersionStrings(String version1, String version2) {
    try {
      final v1Parts = version1.split('.').map(int.parse).toList();
      final v2Parts = version2.split('.').map(int.parse).toList();
      
      // Eksik kısımları 0 ile doldur
      while (v1Parts.length < v2Parts.length) v1Parts.add(0);
      while (v2Parts.length < v1Parts.length) v2Parts.add(0);
      
      for (int i = 0; i < v1Parts.length; i++) {
        if (v1Parts[i] > v2Parts[i]) return 1;
        if (v1Parts[i] < v2Parts[i]) return -1;
      }
      
      return 0;
    } catch (e) {
      _logger.e('Error parsing version strings: $e');
      return 0;
    }
  }
}
