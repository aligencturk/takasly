import 'package:json_annotation/json_annotation.dart';
import 'user.dart';
import 'location.dart';

part 'product.g.dart';

@JsonSerializable()
class Product {
  final String id;
  final String title;
  final String description;
  final List<String> images;
  final String categoryId;
  final String categoryName;
  final Category category;
  final String condition;
  final String? brand;
  final String? model;
  final double? estimatedValue;
  final String ownerId;
  final User owner;
  final List<String> tradePreferences;
  final String cityId;
  final String cityTitle;
  final String districtId;
  final String districtTitle;
  final ProductStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.images,
    required this.categoryId,
    required this.categoryName,
    required this.category,
    required this.condition,
    this.brand,
    this.model,
    this.estimatedValue,
    required this.ownerId,
    required this.owner,
    required this.tradePreferences,
    required this.status,
    required this.cityId,
    required this.cityTitle,
    required this.districtId,
    required this.districtTitle,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // DateTime'ları güvenli şekilde parse et
    DateTime parseDateTime(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    return Product(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      category: json['category'] != null 
          ? Category.fromJson(json['category'] as Map<String, dynamic>)
          : Category(
              id: '',
              name: '',
              icon: '',
              isActive: true,
              order: 0,
            ),
      condition: json['condition'] as String,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      estimatedValue: (json['estimatedValue'] as num?)?.toDouble(),
      ownerId: json['ownerId'] as String,
      owner: json['owner'] != null 
          ? User.fromJson(json['owner'] as Map<String, dynamic>)
          : User(
              id: '',
              name: '',
              email: '',
              isVerified: false,
              isOnline: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
      tradePreferences: (json['tradePreferences'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      status: ProductStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ProductStatus.active,
      ),
      cityId: json['cityId'] as String,
      cityTitle: json['cityTitle'] as String,
      districtId: json['districtId'] as String,
      districtTitle: json['districtTitle'] as String,
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
      expiresAt: json['expiresAt'] != null ? parseDateTime(json['expiresAt']) : null,
    );
  }
  Map<String, dynamic> toJson() => _$ProductToJson(this);

  Product copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? images,
    String? categoryId,
    String? categoryName,
    Category? category,
    String? condition,
    String? brand,
    String? model,
    double? estimatedValue,
    String? ownerId,
    User? owner,
    List<String>? tradePreferences,
    ProductStatus? status,
    String? cityId,
    String? cityTitle,
    String? districtId,
    String? districtTitle,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      images: images ?? this.images,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      ownerId: ownerId ?? this.ownerId,
      owner: owner ?? this.owner,
      tradePreferences: tradePreferences ?? this.tradePreferences,
      status: status ?? this.status,
      cityId: cityId ?? this.cityId,
      cityTitle: cityTitle ?? this.cityTitle,
      districtId: districtId ?? this.districtId,
      districtTitle: districtTitle ?? this.districtTitle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Product(id: $id, title: $title, owner: ${owner.name})';
  }
}

@JsonSerializable()
class Category {
  final String id;
  final String name;
  final String icon;
  final String? parentId;
  final List<Category>? children;
  final bool isActive;
  final int order;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    this.parentId,
    this.children,
    required this.isActive,
    required this.order,
  });

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    String? parentId,
    List<Category>? children,
    bool? isActive,
    int? order,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      parentId: parentId ?? this.parentId,
      children: children ?? this.children,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Category(id: $id, name: $name)';
  }
}

enum ProductStatus {
  active,
  inactive,
  traded,
  expired,
  deleted,
}

enum ProductCondition {
  new_,
  likeNew,
  good,
  fair,
  poor,
}