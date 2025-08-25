import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/profanity_check_result.dart';
import '../utils/logger.dart';

class ProfanityService {
  static ProfanityService? _instance;
  static ProfanityService get instance => _instance ??= ProfanityService._();

  ProfanityService._();

  Map<String, dynamic>? _profanityData;
  List<String> _exactWords = [];
  List<String> _stemWords = [];
  List<String> _abbreviations = [];
  List<String> _insultsGeneral = [];
  List<String> _hateSlurs = [];
  List<String> _familyAttacks = [];
  List<String> _threats = [];
  List<Map<String, dynamic>> _regexPatterns = [];
  List<String> _whitelistSubstrings = [];

  bool _isInitialized = false;

  /// Servisi başlat ve JSON verilerini yükle
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      Logger.info('🔍 ProfanityService - Küfür veritabanı yükleniyor...');

      final jsonString = await rootBundle.loadString(
        'assets/turkish_profanity_extended.json',
      );
      _profanityData = json.decode(jsonString) as Map<String, dynamic>;

      // Listeleri yükle
      _exactWords = List<String>.from(_profanityData!['lists']['exact'] ?? []);
      _stemWords = List<String>.from(_profanityData!['lists']['stems'] ?? []);
      _abbreviations = List<String>.from(
        _profanityData!['lists']['abbreviations'] ?? [],
      );
      _insultsGeneral = List<String>.from(
        _profanityData!['lists']['insults_general'] ?? [],
      );
      _hateSlurs = List<String>.from(
        _profanityData!['lists']['hate_slurs'] ?? [],
      );
      _familyAttacks = List<String>.from(
        _profanityData!['lists']['family_attacks'] ?? [],
      );
      _threats = List<String>.from(_profanityData!['lists']['threats'] ?? []);
      _regexPatterns = List<Map<String, dynamic>>.from(
        _profanityData!['regex'] ?? [],
      );
      _whitelistSubstrings = List<String>.from(
        _profanityData!['lists']['whitelist_substrings'] ?? [],
      );

      _isInitialized = true;
      Logger.info('✅ ProfanityService - Küfür veritabanı başarıyla yüklendi');
      Logger.info(
        '📊 Yüklenen veriler: ${_exactWords.length} exact, ${_stemWords.length} stem, ${_abbreviations.length} abbreviation, ${_insultsGeneral.length} insult, ${_regexPatterns.length} regex',
      );

      // Test kontrolü yap
      _testProfanityDetection();
    } catch (e, stackTrace) {
      Logger.error('❌ ProfanityService - Küfür veritabanı yüklenemedi: $e');
      Logger.error('Stack trace: $stackTrace');

      // Hata durumunda basit bir fallback listesi oluştur
      _createFallbackLists();
      _isInitialized = true;
      Logger.warning('⚠️ ProfanityService - Fallback listeler kullanılıyor');
    }
  }

  /// Fallback listeler oluştur
  void _createFallbackLists() {
    _exactWords = [
      'orospu',
      'pezevenk',
      'gavat',
      'kaltak',
      'kahpe',
      'piç',
      'yavşak',
      'şerefsiz',
      'namussuz',
    ];
    _stemWords = [
      'sik',
      'siktir',
      'amcık',
      'amına',
      'yarrak',
      'göt',
      'çük',
      'ibne',
    ];
    _abbreviations = ['amk', 'aq', 'oç', 'mk'];
    _insultsGeneral = [
      'aptal',
      'salak',
      'ahmak',
      'beyinsiz',
      'gerizekalı',
      'dangalak',
    ];
    _regexPatterns = [];
    _whitelistSubstrings = [];
  }

  /// Küfür tespitini test et
  void _testProfanityDetection() {
    try {
      final testCases = [
        'test amk test',
        'merhaba orospu nasılsın',
        'bu bir test mesajı',
        'aq ne diyorsun',
        'siktir git buradan',
        'aptal salak',
        'gerizekalı',
        'beyinsiz',
        'dangalak',
        'ibne',
        'top',
        'dönme',
        'zenci',
        'çingene',
        'kızılbaş',
        'ermeni dölü',
        'yunan tohumu',
        'amına koyayım',
        'sikeyim',
        'göt',
        'yarrak',
        'çük',
        'amcık',
        'pezevenk',
        'gavat',
        'kaltak',
        'kahpe',
        'piç',
        'yavşak',
        'şerefsiz',
        'namussuz',
        'sürtük',
        'puşt',
        'it oğlu it',
        'test a.m.k test',
        'test a m k test',
        'test a.q test',
        'test a q test',
        'test o.ç test',
        'test o ç test',
        'test s.ktir test',
        'test s g test',
        'test s.g test',
        'test y g test',
        'test y.g test',
        'test mk test',
      ];

      Logger.info('🧪 ProfanityService - Test başlatılıyor...');

      for (final testText in testCases) {
        final result = checkText(testText, sensitivity: 'medium');
        Logger.info('🧪 ProfanityService - Test: "$testText" -> $result');
      }

      Logger.info('🧪 ProfanityService - Test tamamlandı');
    } catch (e) {
      Logger.error('❌ ProfanityService - Test hatası: $e');
    }
  }

  /// Metni küfür/hakaret açısından kontrol et
  ProfanityCheckResult checkText(String text, {String sensitivity = 'medium'}) {
    if (!_isInitialized) {
      Logger.warning('⚠️ ProfanityService - Servis henüz başlatılmamış');
      return ProfanityCheckResult.clean();
    }

    if (text.trim().isEmpty) {
      return ProfanityCheckResult.clean();
    }

    final normalizedText = _normalizeText(text);
    Logger.info(
      '🔍 ProfanityService - Metin kontrol ediliyor: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."',
    );
    Logger.info(
      '🔍 ProfanityService - Normalize edilmiş metin: "${normalizedText.substring(0, normalizedText.length > 50 ? 50 : normalizedText.length)}..."',
    );

    // 1. Tam kelime eşleşmeleri kontrol et
    Logger.info('🔍 ProfanityService - Tam kelime kontrolü yapılıyor...');
    final exactMatch = _checkExactWords(normalizedText);
    if (exactMatch.hasProfanity) {
      Logger.info(
        '🚫 ProfanityService - Tam kelime eşleşmesi bulundu: ${exactMatch.detectedWord}',
      );
      return exactMatch;
    }

    // 2. Regex pattern'ları kontrol et
    Logger.info('🔍 ProfanityService - Regex kontrolü yapılıyor...');
    final regexMatch = _checkRegexPatterns(normalizedText);
    if (regexMatch.hasProfanity) {
      Logger.info(
        '🚫 ProfanityService - Regex eşleşmesi bulundu: ${regexMatch.detectedWord}',
      );
      return regexMatch;
    }

    // 3. Kısaltmalar kontrol et
    Logger.info('🔍 ProfanityService - Kısaltma kontrolü yapılıyor...');
    final abbrevMatch = _checkAbbreviations(normalizedText);
    if (abbrevMatch.hasProfanity) {
      Logger.info(
        '🚫 ProfanityService - Kısaltma eşleşmesi bulundu: ${abbrevMatch.detectedWord}',
      );
      return abbrevMatch;
    }

    // 4. Genel hakaretler kontrol et
    Logger.info('🔍 ProfanityService - Genel hakaret kontrolü yapılıyor...');
    final insultMatch = _checkInsultsGeneral(normalizedText);
    if (insultMatch.hasProfanity) {
      Logger.info(
        '🚫 ProfanityService - Genel hakaret eşleşmesi bulundu: ${insultMatch.detectedWord}',
      );
      return insultMatch;
    }

    // 5. Hassasiyet seviyesine göre ek kontroller
    if (sensitivity == 'high' || sensitivity == 'medium') {
      Logger.info('🔍 ProfanityService - Stem kontrolü yapılıyor...');
      final stemMatch = _checkStemWords(normalizedText);
      if (stemMatch.hasProfanity) {
        Logger.info(
          '🚫 ProfanityService - Stem eşleşmesi bulundu: ${stemMatch.detectedWord}',
        );
        return stemMatch;
      }
    }

    Logger.info('✅ ProfanityService - Metin temiz');
    return ProfanityCheckResult.clean();
  }

  /// Tam kelime eşleşmelerini kontrol et
  ProfanityCheckResult _checkExactWords(String normalizedText) {
    final words = normalizedText.split(RegExp(r'\s+'));
    Logger.info('🔍 ProfanityService - Kelimeler ayrıştırıldı: $words');

    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^\wçğıöşüÇĞIİÖŞÜ]'), '');
      Logger.info(
        '🔍 ProfanityService - Kelime kontrol ediliyor: "$cleanWord"',
      );

      if (_exactWords.contains(cleanWord.toLowerCase())) {
        Logger.info('🚫 ProfanityService - Tam kelime eşleşmesi: "$cleanWord"');
        return ProfanityCheckResult.detected(
          word: cleanWord,
          level: 'high',
          message: 'Uygunsuz kelime tespit edildi',
        );
      }
    }

    Logger.info('✅ ProfanityService - Tam kelime eşleşmesi bulunamadı');
    return ProfanityCheckResult.clean();
  }

  /// Regex pattern'larını kontrol et
  ProfanityCheckResult _checkRegexPatterns(String normalizedText) {
    Logger.info('🔍 ProfanityService - Regex pattern kontrolü başlatılıyor...');

    for (final pattern in _regexPatterns) {
      try {
        // Pattern'ı temizle ve Dart RegExp için uygun hale getir
        String cleanPattern = pattern['pattern'] as String;

        // (?i) inline flag'ini kaldır (case insensitive zaten RegExp parametresi ile set ediliyor)
        cleanPattern = cleanPattern.replaceFirst(RegExp(r'^\(\?i\)'), '');

        final regex = RegExp(cleanPattern, caseSensitive: false);
        Logger.info(
          '🔍 ProfanityService - Regex pattern test ediliyor: $cleanPattern',
        );

        if (regex.hasMatch(normalizedText)) {
          final match = regex.firstMatch(normalizedText);
          final matchedText = match?.group(0) ?? '';

          Logger.info(
            '🔍 ProfanityService - Regex eşleşmesi bulundu: "$matchedText"',
          );

          // Whitelist kontrolü
          if (_isWhitelisted(matchedText)) {
            Logger.info(
              '✅ ProfanityService - Whitelist kontrolü geçildi: "$matchedText"',
            );
            continue;
          }

          Logger.info(
            '🚫 ProfanityService - Regex eşleşmesi onaylandı: "$matchedText"',
          );
          return ProfanityCheckResult.detected(
            word: matchedText,
            level: pattern['level'] as String,
            message: _getMessageForLevel(pattern['level'] as String),
          );
        }
      } catch (e) {
        Logger.error(
          '❌ ProfanityService - Regex hatası: $e, pattern: ${pattern['pattern']}',
        );
      }
    }

    Logger.info('✅ ProfanityService - Regex eşleşmesi bulunamadı');
    return ProfanityCheckResult.clean();
  }

  /// Kısaltmaları kontrol et
  ProfanityCheckResult _checkAbbreviations(String normalizedText) {
    final words = normalizedText.split(RegExp(r'\s+'));
    Logger.info(
      '🔍 ProfanityService - Kısaltma kontrolü için kelimeler: $words',
    );

    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^\wçğıöşüÇĞIİÖŞÜ]'), '');
      Logger.info(
        '🔍 ProfanityService - Kısaltma kontrol ediliyor: "$cleanWord"',
      );

      if (_abbreviations.contains(cleanWord.toLowerCase())) {
        Logger.info('🚫 ProfanityService - Kısaltma eşleşmesi: "$cleanWord"');
        return ProfanityCheckResult.detected(
          word: cleanWord,
          level: 'high',
          message: 'Uygunsuz kısaltma tespit edildi',
        );
      }
    }

    // Ayrıca noktalı kısaltmaları da kontrol et
    final noktaliKisaltmalar = ['a.m.k', 'a.q', 'o.ç', 's.ktir', 's.g', 'y.g'];

    for (final kisaltma in noktaliKisaltmalar) {
      if (normalizedText.contains(kisaltma)) {
        Logger.info(
          '🚫 ProfanityService - Noktalı kısaltma eşleşmesi: "$kisaltma"',
        );
        return ProfanityCheckResult.detected(
          word: kisaltma,
          level: 'high',
          message: 'Uygunsuz kısaltma tespit edildi',
        );
      }
    }

    Logger.info('✅ ProfanityService - Kısaltma eşleşmesi bulunamadı');
    return ProfanityCheckResult.clean();
  }

  /// Genel hakaretleri kontrol et
  ProfanityCheckResult _checkInsultsGeneral(String normalizedText) {
    final words = normalizedText.split(RegExp(r'\s+'));
    Logger.info(
      '🔍 ProfanityService - Genel hakaret kontrolü için kelimeler: $words',
    );

    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^\wçğıöşüÇĞIİÖŞÜ]'), '');
      Logger.info(
        '🔍 ProfanityService - Genel hakaret kelime kontrol ediliyor: "$cleanWord"',
      );

      if (_insultsGeneral.contains(cleanWord.toLowerCase())) {
        Logger.info(
          '🚫 ProfanityService - Genel hakaret eşleşmesi: "$cleanWord"',
        );
        return ProfanityCheckResult.detected(
          word: cleanWord,
          level: 'medium',
          message: 'Genel hakaret tespit edildi',
        );
      }
    }

    Logger.info('✅ ProfanityService - Genel hakaret eşleşmesi bulunamadı');
    return ProfanityCheckResult.clean();
  }

  /// Stem kelimeleri kontrol et
  ProfanityCheckResult _checkStemWords(String normalizedText) {
    final words = normalizedText.split(RegExp(r'\s+'));
    Logger.info('🔍 ProfanityService - Stem kontrolü için kelimeler: $words');

    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^\wçğıöşüÇĞIİÖŞÜ]'), '');
      Logger.info(
        '🔍 ProfanityService - Stem kelime kontrol ediliyor: "$cleanWord"',
      );

      for (final stem in _stemWords) {
        if (cleanWord.toLowerCase().contains(stem.toLowerCase())) {
          Logger.info(
            '🔍 ProfanityService - Stem eşleşmesi bulundu: "$cleanWord" contains "$stem"',
          );

          // Whitelist kontrolü
          if (_isWhitelisted(cleanWord)) {
            Logger.info(
              '✅ ProfanityService - Whitelist kontrolü geçildi: "$cleanWord"',
            );
            continue;
          }

          Logger.info(
            '🚫 ProfanityService - Stem eşleşmesi onaylandı: "$cleanWord"',
          );
          return ProfanityCheckResult.detected(
            word: cleanWord,
            level: 'medium',
            message: 'Potansiyel uygunsuz içerik tespit edildi',
          );
        }
      }
    }

    Logger.info('✅ ProfanityService - Stem eşleşmesi bulunamadı');
    return ProfanityCheckResult.clean();
  }

  /// Whitelist kontrolü
  bool _isWhitelisted(String word) {
    return _whitelistSubstrings.any(
      (whitelist) => word.toLowerCase().contains(whitelist.toLowerCase()),
    );
  }

  /// Seviyeye göre mesaj döndür
  String _getMessageForLevel(String level) {
    switch (level) {
      case 'high':
        return 'Ağır uygunsuz içerik tespit edildi';
      case 'medium':
        return 'Uygunsuz içerik tespit edildi';
      case 'low':
        return 'Potansiyel uygunsuz içerik tespit edildi';
      default:
        return 'Uygunsuz içerik tespit edildi';
    }
  }

  /// Metni normalize et
  String _normalizeText(String text) {
    String normalized = text.toLowerCase();

    // Diacritics korunuyor (ç, ğ, ı, ö, ş, ü)
    // Whitespace collapse
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');

    // Noktalama işaretlerini kaldır (küfür kontrolü için)
    normalized = normalized.replaceAll(RegExp(r'[^\wçğıöşüÇĞIİÖŞÜ\s]'), '');

    // Çoklu boşlukları tek boşluğa çevir
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');

    Logger.info('🔍 ProfanityService - Orijinal metin: "$text"');
    Logger.info('🔍 ProfanityService - Normalize edilmiş metin: "$normalized"');

    return normalized.trim();
  }

  /// Servis durumunu kontrol et
  bool get isInitialized => _isInitialized;

  /// İstatistikleri getir
  Map<String, int> getStatistics() {
    return {
      'exact_words': _exactWords.length,
      'stem_words': _stemWords.length,
      'abbreviations': _abbreviations.length,
      'insults_general': _insultsGeneral.length,
      'hate_slurs': _hateSlurs.length,
      'family_attacks': _familyAttacks.length,
      'threats': _threats.length,
      'regex_patterns': _regexPatterns.length,
      'whitelist_substrings': _whitelistSubstrings.length,
    };
  }
}
