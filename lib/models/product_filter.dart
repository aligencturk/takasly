// Sentinel nesnesi: copyWith içinde explicit null ile field temizlemeyi ayırt etmek için kullanılır
const Object _unset = Object();

class ProductFilter {
  final String? categoryId;
  final String? subCategoryId;
  final String? subSubCategoryId;
  final String? subSubSubCategoryId;
  final List<String> conditionIds;
  final String? cityId;
  final String? districtId;
  final String sortType;
  final String? searchText;
  final String viewType; // 'grid' | 'list'

  const ProductFilter({
    this.categoryId,
    this.subCategoryId,
    this.subSubCategoryId,
    this.subSubSubCategoryId,
    this.conditionIds = const [],
    this.cityId,
    this.districtId,
    this.sortType = 'default',
    this.searchText,
    this.viewType = 'grid',
  });

  ProductFilter copyWith({
    Object? categoryId = _unset,
    Object? subCategoryId = _unset,
    Object? subSubCategoryId = _unset,
    Object? subSubSubCategoryId = _unset,
    List<String>? conditionIds,
    Object? cityId = _unset,
    Object? districtId = _unset,
    String? sortType,
    Object? searchText = _unset,
    String? viewType,
  }) {
    return ProductFilter(
      categoryId: categoryId != _unset
          ? categoryId as String?
          : this.categoryId,
      subCategoryId: subCategoryId != _unset
          ? subCategoryId as String?
          : this.subCategoryId,
      subSubCategoryId: subSubCategoryId != _unset
          ? subSubCategoryId as String?
          : this.subSubCategoryId,
      subSubSubCategoryId: subSubSubCategoryId != _unset
          ? subSubSubCategoryId as String?
          : this.subSubSubCategoryId,
      conditionIds: conditionIds ?? this.conditionIds,
      cityId: cityId != _unset ? cityId as String? : this.cityId,
      districtId: districtId != _unset
          ? districtId as String?
          : this.districtId,
      sortType: sortType ?? this.sortType,
      searchText: searchText != _unset
          ? searchText as String?
          : this.searchText,
      viewType: viewType ?? this.viewType,
    );
  }

  bool get hasActiveFilters {
    return categoryId != null ||
        subCategoryId != null ||
        subSubCategoryId != null ||
        subSubSubCategoryId != null ||
        conditionIds.isNotEmpty ||
        cityId != null ||
        districtId != null ||
        sortType != 'default' ||
        (searchText != null && searchText!.isNotEmpty);
  }

  Map<String, dynamic> toApiBody({
    required String userToken,
    required int page,
    String? userLat,
    String? userLong,
  }) {
    // En spesifik kategori ID'sini kullan
    String? finalCategoryId =
        subSubSubCategoryId ?? subSubCategoryId ?? subCategoryId ?? categoryId;

    return {
      'userToken': userToken,
      'categoryID': finalCategoryId != null
          ? int.tryParse(finalCategoryId) ?? 0
          : 0,
      'conditionIDs': conditionIds.map((id) => int.tryParse(id) ?? 0).toList(),
      'cityID': cityId != null ? int.tryParse(cityId!) ?? 0 : 0,
      'districtID': districtId != null ? int.tryParse(districtId!) ?? 0 : 0,
      'userLat': userLat ?? '',
      'userLong': userLong ?? '',
      'sortType': sortType,
      'page': page,
      'searchText': searchText ?? '', // searchText parametresi eklendi
    };
  }

  @override
  String toString() {
    return 'ProductFilter(categoryId: $categoryId, subCategoryId: $subCategoryId, subSubCategoryId: $subSubCategoryId, subSubSubCategoryId: $subSubSubCategoryId, conditionIds: $conditionIds, cityId: $cityId, districtId: $districtId, sortType: $sortType, searchText: $searchText, viewType: $viewType)';
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
