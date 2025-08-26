import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';

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

      Logger.info('Cache service initialized: ${_cacheDir!.path}');
    } catch (e) {
      Logger.error('Cache service initialization failed', error: e);
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
          Logger.info('Icon loaded from memory cache: $url');
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
          Logger.info('Icon loaded from disk cache: $url');
          return bytes;
        } else {
          // Expired file'ı sil
          await file.delete();
        }
      }

      return null;
    } catch (e) {
      Logger.error('Error getting cached icon: $url', error: e);
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

      Logger.info('Icon cached successfully: $url');
    } catch (e) {
      Logger.error('Error caching icon: $url', error: e);
    }
  }

  Future<void> _checkDiskCacheSize() async {
    try {
      final currentSize = await getCacheSize();
      if (currentSize > _maxDiskCacheSize) {
        await _cleanupDiskCache();
      }
    } catch (e) {
      Logger.error('Error checking disk cache size', error: e);
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
        if (currentSize - deletedSize <= _maxDiskCacheSize * 0.8)
          break; // %80'e düşür

        final fileSize = await entry.key.length();
        await entry.key.delete();
        deletedSize += fileSize;
      }

      Logger.info('Disk cache cleaned up, freed ${deletedSize ~/ 1024}KB');
    } catch (e) {
      Logger.error('Error cleaning up disk cache', error: e);
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

    Logger.info('Memory cache cleaned up, removed $itemsToRemove items');
  }

  Future<Uint8List?> downloadAndCacheIcon(String url) async {
    // Eğer aynı URL için zaten bir download işlemi varsa, onu bekle
    if (_loadingFutures.containsKey(url)) {
      Logger.info('Waiting for existing download: $url');
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
        Logger.error(
          'Failed to download icon: $url, status: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      Logger.error('Error downloading icon: $url', error: e);
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

      Logger.info('Cache cleared successfully');
    } catch (e) {
      Logger.error('Error clearing cache', error: e);
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

      Logger.info('Expired cache cleared');
    } catch (e) {
      Logger.error('Error clearing expired cache', error: e);
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
      Logger.error('Error getting cache size', error: e);
      return 0;
    }
  }

  Future<void> logCacheStats() async {
    Logger.info('Cache Stats:');
    Logger.info('  Memory cache items: ${_memoryCache.length}');
    Logger.info('  Memory cache timestamps: ${_cacheTimestamps.length}');
    Logger.info('  Loading futures: ${_loadingFutures.length}');
    Logger.info('  Cache directory: ${_cacheDir?.path ?? 'Not initialized'}');

    if (_cacheDir != null) {
      final diskSize = await getCacheSize();
      Logger.info('  Disk cache size: ${diskSize ~/ 1024}KB');
    }

    if (_totalRequests > 0) {
      final memoryHitRate = (_memoryCacheHits / _totalRequests * 100)
          .toStringAsFixed(1);
      final diskHitRate = (_diskCacheHits / _totalRequests * 100)
          .toStringAsFixed(1);
      final totalHitRate =
          ((_memoryCacheHits + _diskCacheHits) / _totalRequests * 100)
              .toStringAsFixed(1);

      Logger.info('  Total requests: $_totalRequests');
      Logger.info('  Memory cache hits: $_memoryCacheHits ($memoryHitRate%)');
      Logger.info('  Disk cache hits: $_diskCacheHits ($diskHitRate%)');
      Logger.info('  Total hit rate: $totalHitRate%');
    }
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
      
      Logger.info('🔒 CacheService - Saved ${blockedUsers.length} blocked users');
    } catch (e) {
      Logger.error('❌ CacheService - Error saving blocked users: $e', error: e);
    }
  }

  /// Engellenen kullanıcıları döndürür
  String? getBlockedUsers() {
    try {
      if (_cacheDir == null) return null;

      final file = File('${_cacheDir!.path}/blocked_users.json');
      if (!file.existsSync()) return null;

      final jsonData = file.readAsStringSync();
      Logger.info('🔒 CacheService - Retrieved blocked users from cache');
      return jsonData;
    } catch (e) {
      Logger.error('❌ CacheService - Error getting blocked users: $e', error: e);
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
        Logger.info('🔒 CacheService - Cleared blocked users cache');
      }
    } catch (e) {
      Logger.error('❌ CacheService - Error clearing blocked users: $e', error: e);
    }
  }
}
