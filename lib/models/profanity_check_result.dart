class ProfanityCheckResult {
  final bool hasProfanity;
  final String? detectedWord;
  final String level; // 'high', 'medium', 'low'
  final String? message;
  final List<String> suggestions;

  ProfanityCheckResult({
    required this.hasProfanity,
    this.detectedWord,
    required this.level,
    this.message,
    this.suggestions = const [],
  });

  factory ProfanityCheckResult.clean() {
    return ProfanityCheckResult(
      hasProfanity: false,
      level: 'clean',
      message: 'Metin uygun',
    );
  }

  factory ProfanityCheckResult.detected({
    required String word,
    required String level,
    String? message,
    List<String> suggestions = const [],
  }) {
    return ProfanityCheckResult(
      hasProfanity: true,
      detectedWord: word,
      level: level,
      message: message,
      suggestions: suggestions,
    );
  }

  bool get isHighLevel => level == 'high';
  bool get isMediumLevel => level == 'medium';
  bool get isLowLevel => level == 'low';

  @override
  String toString() {
    return 'ProfanityCheckResult(hasProfanity: $hasProfanity, level: $level, word: $detectedWord)';
  }
}
