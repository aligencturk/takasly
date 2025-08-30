import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/profanity_check_result.dart';

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

      // Test kontrolü yap
      _testProfanityDetection();
    } catch (e, stackTrace) {
      // Hata durumunda basit bir fallback listesi oluştur
      _createFallbackLists();
      _isInitialized = true;
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

      for (final testText in testCases) {
        final result = checkText(testText, sensitivity: 'medium');
      }
    } catch (e) {
      // Test hatası
    }
  }

  /// Metni küfür/hakaret açısından kontrol et
  ProfanityCheckResult checkText(String text, {String sensitivity = 'medium'}) {
    if (!_isInitialized) {
      return ProfanityCheckResult.clean();
    }

    if (text.trim().isEmpty) {
      return ProfanityCheckResult.clean();
    }

    final normalizedText = _normalizeText(text);

    // 1. Tam kelime eşleşmeleri kontrol et
    final exactMatch = _checkExactWords(normalizedText);
    if (exactMatch.hasProfanity) {
      return exactMatch;
    }

    // 2. Regex pattern'ları kontrol et
    final regexMatch = _checkRegexPatterns(normalizedText);
    if (regexMatch.hasProfanity) {
      return regexMatch;
    }

    // 3. Kısaltmalar kontrol et
    final abbrevMatch = _checkAbbreviations(normalizedText);
    if (abbrevMatch.hasProfanity) {
      return abbrevMatch;
    }

    // 4. Genel hakaretler kontrol et
    final insultMatch = _checkInsultsGeneral(normalizedText);
    if (insultMatch.hasProfanity) {
      return insultMatch;
    }

    // 5. Hassasiyet seviyesine göre ek kontroller
    if (sensitivity == 'high' || sensitivity == 'medium') {
      final stemMatch = _checkStemWords(normalizedText);
      if (stemMatch.hasProfanity) {
        return stemMatch;
      }
    }

    return ProfanityCheckResult.clean();
  }

  /// Tam kelime eşleşmelerini kontrol et
  ProfanityCheckResult _checkExactWords(String normalizedText) {
    final words = normalizedText.split(RegExp(r'\s+'));

    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^\wçğıöşüÇĞIİÖŞÜ]'), '');

      if (_exactWords.contains(cleanWord.toLowerCase())) {
        return ProfanityCheckResult.detected(
          word: cleanWord,
          level: 'high',
          message: 'Uygunsuz kelime tespit edildi',
        );
      }
    }

    return ProfanityCheckResult.clean();
  }

  /// Regex pattern'larını kontrol et
  ProfanityCheckResult _checkRegexPatterns(String normalizedText) {
    for (final pattern in _regexPatterns) {
      try {
        // Pattern'ı temizle ve Dart RegExp için uygun hale getir
        String cleanPattern = pattern['pattern'] as String;

        // (?i) inline flag'ini kaldır (case insensitive zaten RegExp parametresi ile set ediliyor)
        cleanPattern = cleanPattern.replaceFirst(RegExp(r'^\(\?i\)'), '');

        final regex = RegExp(cleanPattern, caseSensitive: false);

        if (regex.hasMatch(normalizedText)) {
          final match = regex.firstMatch(normalizedText);
          final matchedText = match?.group(0) ?? '';

          // Whitelist kontrolü
          if (_isWhitelisted(matchedText)) {
            continue;
          }

          return ProfanityCheckResult.detected(
            word: matchedText,
            level: pattern['level'] as String,
            message: _getMessageForLevel(pattern['level'] as String),
          );
        }
      } catch (e) {
        // Regex hatası
      }
    }

    return ProfanityCheckResult.clean();
  }

  /// Kısaltmaları kontrol et
  ProfanityCheckResult _checkAbbreviations(String normalizedText) {
    final words = normalizedText.split(RegExp(r'\s+'));

    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^\wçğıöşüÇĞIİÖŞÜ]'), '');

      if (_abbreviations.contains(cleanWord.toLowerCase())) {
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
        return ProfanityCheckResult.detected(
          word: kisaltma,
          level: 'high',
          message: 'Uygunsuz kısaltma tespit edildi',
        );
      }
    }

    return ProfanityCheckResult.clean();
  }

  /// Genel hakaretleri kontrol et
  ProfanityCheckResult _checkInsultsGeneral(String normalizedText) {
    final words = normalizedText.split(RegExp(r'\s+'));

    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^\wçğıöşüÇĞIİÖŞÜ]'), '');

      if (_insultsGeneral.contains(cleanWord.toLowerCase())) {
        return ProfanityCheckResult.detected(
          word: cleanWord,
          level: 'medium',
          message: 'Genel hakaret tespit edildi',
        );
      }
    }

    return ProfanityCheckResult.clean();
  }

  /// Stem kelimeleri kontrol et
  ProfanityCheckResult _checkStemWords(String normalizedText) {
    final words = normalizedText.split(RegExp(r'\s+'));

    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^\wçğıöşüÇĞIİÖŞÜ]'), '');

      for (final stem in _stemWords) {
        if (cleanWord.toLowerCase().contains(stem.toLowerCase())) {
          // Whitelist kontrolü
          if (_isWhitelisted(cleanWord)) {
            continue;
          }

          return ProfanityCheckResult.detected(
            word: cleanWord,
            level: 'medium',
            message: 'Potansiyel uygunsuz içerik tespit edildi',
          );
        }
      }
    }

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
