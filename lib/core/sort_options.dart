enum SortOption {
  defaultSort('default', 'Varsayılan'),
  newestFirst('newest', 'Yeniden Eskiye'),
  oldestFirst('oldest', 'Eskiden Yeniye'),
  mostViewed('most_viewed', 'En Çok İncelenenler'),
  nearestToMe('nearest', 'Bana En Yakın');

  const SortOption(this.value, this.displayName);

  final String value;
  final String displayName;

  static List<SortOption> get allOptions => SortOption.values;

  static SortOption fromValue(String value) {
    return SortOption.values.firstWhere(
      (option) => option.value == value,
      orElse: () => SortOption.defaultSort,
    );
  }
}
