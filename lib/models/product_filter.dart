class ProductFilter {
  final String? categoryId;
  final List<String> conditionIds;
  final String? cityId;
  final String? districtId;
  final String sortType;
  final String? searchQuery;

  const ProductFilter({
    this.categoryId,
    this.conditionIds = const [],
    this.cityId,
    this.districtId,
    this.sortType = 'default',
    this.searchQuery,
  });

  ProductFilter copyWith({
    String? categoryId,
    List<String>? conditionIds,
    String? cityId,
    String? districtId,
    String? sortType,
    String? searchQuery,
  }) {
    return ProductFilter(
      categoryId: categoryId,
      conditionIds: conditionIds ?? this.conditionIds,
      cityId: cityId,
      districtId: districtId,
      sortType: sortType ?? this.sortType,
      searchQuery: searchQuery,
    );
  }

  bool get hasActiveFilters {
    return categoryId != null ||
        conditionIds.isNotEmpty ||
        cityId != null ||
        districtId != null ||
        sortType != 'default' ||
        (searchQuery != null && searchQuery!.isNotEmpty);
  }

  Map<String, dynamic> toApiBody({
    required String userToken,
    required int page,
    String? userLat,
    String? userLong,
  }) {
    return {
      'userToken': userToken,
      'categoryID': categoryId != null ? int.tryParse(categoryId!) ?? 0 : 0,
      'conditionIDs': conditionIds.map((id) => int.tryParse(id) ?? 0).toList(),
      'cityID': cityId != null ? int.tryParse(cityId!) ?? 0 : 0,
      'districtID': districtId != null ? int.tryParse(districtId!) ?? 0 : 0,
      'userLat': userLat ?? '',
      'userLong': userLong ?? '',
      'sortType': sortType,
      'page': page,
    };
  }

  @override
  String toString() {
    return 'ProductFilter(categoryId: $categoryId, conditionIds: $conditionIds, cityId: $cityId, districtId: $districtId, sortType: $sortType, searchQuery: $searchQuery)';
  }
}

enum SortType {
  defaultSort('default', 'Varsayılan'),
  newestToOldest('newest', 'Yeniden Eskiye'),
  oldestToNewest('oldest', 'Eskiden Yeniye'),
  mostViewed('popular', 'En Çok İncelenenler'),
  nearestToMe('location', 'Bana En Yakın');

  const SortType(this.value, this.label);
  final String value;
  final String label;
}
