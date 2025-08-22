class PopularCategory {
  final int catId;
  final String catName;
  final String catImage;
  final int productCount;

  const PopularCategory({
    required this.catId,
    required this.catName,
    required this.catImage,
    required this.productCount,
  });

  factory PopularCategory.fromJson(Map<String, dynamic> json) {
    return PopularCategory(
      catId: json['catID'] as int,
      catName: json['catName'] as String,
      catImage: json['catImage'] as String,
      productCount: json['productCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'catID': catId,
      'catName': catName,
      'catImage': catImage,
      'productCount': productCount,
    };
  }
}

class PopularCategoriesResponse {
  final bool error;
  final bool success;
  final PopularCategoriesData data;

  const PopularCategoriesResponse({
    required this.error,
    required this.success,
    required this.data,
  });

  factory PopularCategoriesResponse.fromJson(Map<String, dynamic> json) {
    return PopularCategoriesResponse(
      error: json['error'] as bool,
      success: json['success'] as bool,
      data: PopularCategoriesData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'success': success,
      'data': data.toJson(),
    };
  }
}

class PopularCategoriesData {
  final List<PopularCategory> categories;

  const PopularCategoriesData({
    required this.categories,
  });

  factory PopularCategoriesData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> categoriesJson = json['categories'] as List<dynamic>;
    final List<PopularCategory> categories = categoriesJson
        .map((json) => PopularCategory.fromJson(json as Map<String, dynamic>))
        .toList();
    
    return PopularCategoriesData(categories: categories);
  }

  Map<String, dynamic> toJson() {
    return {
      'categories': categories.map((category) => category.toJson()).toList(),
    };
  }
}
