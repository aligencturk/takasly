import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _cacheDirName = 'category_icons';
  static const Duration _cacheExpiry = Duration(days: 7); // 7 gün cache süresi
  static const int _maxMemoryCacheSize =
      50; // Maximum 50 icon memory cache'de tut
  static const int _maxDiskCacheSize =
      50 * 1024 * 1024; // 50MB disk cache limit

  Directory? _cacheDir;
  final Map<String, Uint8List> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, Future<Uint8List?>> _loadingFutures = {};

  // Cache istatistikleri
  int _memoryCacheHits = 0;
  int _diskCacheHits = 0;
  int _totalRequests = 0;

  Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${appDir.path}/$_cacheDirName');

      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
    } catch (e) {
      // Cache service initialization failed
    }
  }

  Future<Uint8List?> getCachedIcon(String url) async {
    _totalRequests++;

    try {
      // Memory cache kontrolü
      if (_memoryCache.containsKey(url)) {
        final timestamp = _cacheTimestamps[url];
        if (timestamp != null &&
            DateTime.now().difference(timestamp) < _cacheExpiry) {
          _memoryCacheHits++;
          return _memoryCache[url];
        } else {
          // Expired cache'i temizle
          _memoryCache.remove(url);
          _cacheTimestamps.remove(url);
        }
      }

      // Disk cache kontrolü
      if (_cacheDir == null) {
        await initialize();
      }

      final fileName = _getFileNameFromUrl(url);
      final file = File('${_cacheDir!.path}/$fileName');

      if (await file.exists()) {
        final stat = await file.stat();
        if (DateTime.now().difference(stat.modified) < _cacheExpiry) {
          final bytes = await file.readAsBytes();
          // Memory cache'e ekle
          _memoryCache[url] = bytes;
          _cacheTimestamps[url] = DateTime.now();
          _diskCacheHits++;
          return bytes;
        } else {
          // Expired file'ı sil
          await file.delete();
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> cacheIcon(String url, Uint8List bytes) async {
    try {
      // Memory cache boyutunu kontrol et
      if (_memoryCache.length >= _maxMemoryCacheSize) {
        _cleanupMemoryCache();
      }

      // Memory cache'e ekle
      _memoryCache[url] = bytes;
      _cacheTimestamps[url] = DateTime.now();

      // Disk cache'e kaydet
      if (_cacheDir == null) {
        await initialize();
      }

      final fileName = _getFileNameFromUrl(url);
      final file = File('${_cacheDir!.path}/$fileName');
      await file.writeAsBytes(bytes);

      // Disk cache boyutunu kontrol et
      await _checkDiskCacheSize();
    } catch (e) {
      // Error caching icon
    }
  }

  Future<void> _checkDiskCacheSize() async {
    try {
      final currentSize = await getCacheSize();
      if (currentSize > _maxDiskCacheSize) {
        await _cleanupDiskCache();
      }
    } catch (e) {
      // Error checking disk cache size
    }
  }

  Future<void> _cleanupDiskCache() async {
    try {
      if (_cacheDir == null || !await _cacheDir!.exists()) return;

      final files = await _cacheDir!.list().toList();
      final fileStats = <File, DateTime>{};

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          fileStats[file] = stat.modified;
        }
      }

      // En eski dosyaları sil
      final sortedFiles = fileStats.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      int currentSize = await getCacheSize();
      int deletedSize = 0;

      for (final entry in sortedFiles) {
        if (currentSize - deletedSize <= _maxDiskCacheSize * 0.8) {
          break; // %80'e düşür
        }

        final fileSize = await entry.key.length();
        await entry.key.delete();
        deletedSize += fileSize;
      }
    } catch (e) {
      // Error cleaning up disk cache
    }
  }

  void _cleanupMemoryCache() {
    // En eski cache'leri temizle
    final sortedEntries = _cacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final itemsToRemove = (_memoryCache.length - _maxMemoryCacheSize + 10)
        .clamp(0, _memoryCache.length);

    for (int i = 0; i < itemsToRemove; i++) {
      final key = sortedEntries[i].key;
      _memoryCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  Future<Uint8List?> downloadAndCacheIcon(String url) async {
    // Eğer aynı URL için zaten bir download işlemi varsa, onu bekle
    if (_loadingFutures.containsKey(url)) {
      return await _loadingFutures[url]!;
    }

    // Yeni download işlemi başlat
    final future = _downloadAndCacheIconInternal(url);
    _loadingFutures[url] = future;

    try {
      final result = await future;
      return result;
    } finally {
      _loadingFutures.remove(url);
    }
  }

  Future<Uint8List?> _downloadAndCacheIconInternal(String url) async {
    try {
      // Önce cache'den kontrol et (concurrent request'ler için)
      final cachedIcon = await getCachedIcon(url);
      if (cachedIcon != null) {
        return cachedIcon;
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        await cacheIcon(url, bytes);
        return bytes;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  String _getFileNameFromUrl(String url) {
    // URL'den güvenli dosya adı oluştur
    final uri = Uri.parse(url);
    final path = uri.path;
    final fileName = path.split('/').last;

    // Eğer dosya adı yoksa veya geçersizse hash kullan
    if (fileName.isEmpty || fileName == path) {
      return '${url.hashCode}.cache';
    }

    // Dosya uzantısını koru
    final extension = fileName.contains('.')
        ? fileName.split('.').last
        : 'cache';
    return '${url.hashCode}.$extension';
  }

  Future<void> clearCache() async {
    try {
      _memoryCache.clear();
      _cacheTimestamps.clear();
      _loadingFutures.clear();

      // İstatistikleri sıfırla
      _memoryCacheHits = 0;
      _diskCacheHits = 0;
      _totalRequests = 0;

      if (_cacheDir != null && await _cacheDir!.exists()) {
        await _cacheDir!.delete(recursive: true);
        await _cacheDir!.create();
      }
    } catch (e) {
      // Error clearing cache
    }
  }

  Future<void> clearExpiredCache() async {
    try {
      final now = DateTime.now();

      // Memory cache'den expired item'ları temizle
      final expiredKeys = _cacheTimestamps.entries
          .where((entry) => now.difference(entry.value) >= _cacheExpiry)
          .map((entry) => entry.key)
          .toList();

      for (final key in expiredKeys) {
        _memoryCache.remove(key);
        _cacheTimestamps.remove(key);
      }

      // Disk cache'den expired file'ları temizle
      if (_cacheDir != null && await _cacheDir!.exists()) {
        final files = await _cacheDir!.list().toList();
        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            if (now.difference(stat.modified) >= _cacheExpiry) {
              await file.delete();
            }
          }
        }
      }
    } catch (e) {
      // Error clearing expired cache
    }
  }

  Future<int> getCacheSize() async {
    try {
      if (_cacheDir == null || !await _cacheDir!.exists()) return 0;

      int totalSize = 0;
      final files = await _cacheDir!.list().toList();

      for (final file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  Future<void> logCacheStats() async {
    // Cache Stats logging removed
  }

  /// Engellenen kullanıcıları saklar
  Future<void> saveBlockedUsers(List<Map<String, dynamic>> blockedUsers) async {
    try {
      if (_cacheDir == null) {
        await initialize();
      }

      final file = File('${_cacheDir!.path}/blocked_users.json');
      final jsonData = jsonEncode(blockedUsers);
      await file.writeAsString(jsonData);
    } catch (e) {
      // Error saving blocked users
    }
  }

  /// Engellenen kullanıcıları döndürür
  String? getBlockedUsers() {
    try {
      if (_cacheDir == null) return null;

      final file = File('${_cacheDir!.path}/blocked_users.json');
      if (!file.existsSync()) return null;

      final jsonData = file.readAsStringSync();
      return jsonData;
    } catch (e) {
      return null;
    }
  }

  /// Engellenen kullanıcıları temizler
  Future<void> clearBlockedUsers() async {
    try {
      if (_cacheDir == null) return;

      final file = File('${_cacheDir!.path}/blocked_users.json');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Error clearing blocked users
    }
  }

  /// Onboarding durumunu kaydeder
  Future<void> setOnboardingCompleted(bool completed) async {
    try {
      if (_cacheDir == null) {
        await initialize();
      }

      final file = File('${_cacheDir!.path}/onboarding_completed.json');
      final jsonData = jsonEncode({
        'completed': completed,
        'timestamp': DateTime.now().toIso8601String(),
      });
      await file.writeAsString(jsonData);
    } catch (e) {
      // Error saving onboarding status
    }
  }

  /// Onboarding durumunu döndürür
  Future<bool?> isOnboardingCompleted() async {
    try {
      if (_cacheDir == null) {
        await initialize();
      }

      final file = File('${_cacheDir!.path}/onboarding_completed.json');
      if (!await file.exists()) return null;

      final jsonData = await file.readAsString();
      final data = jsonDecode(jsonData) as Map<String, dynamic>;

      return data['completed'] as bool?;
    } catch (e) {
      return null;
    }
  }

  /// TEST İÇİN: Onboarding durumunu sıfırlar (her girişte gösterir)
  Future<void> resetOnboardingForTesting() async {
    try {
      await setOnboardingCompleted(false);
    } catch (e) {
      // Error resetting onboarding for testing
    }
  }
}
