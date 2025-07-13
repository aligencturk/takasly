import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'product.g.dart';

@JsonSerializable()
class Product {
  final String id;
  final String title;
  final String description;
  final List<String> images;
  final String categoryId;
  final Category category;
  final String condition;
  final String? brand;
  final String? model;
  final double? estimatedValue;
  final String ownerId;
  final User owner;
  final List<String> tradePreferences;
  final ProductStatus status;
  final Location? location;
  final int viewCount;
  final int favoriteCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.images,
    required this.categoryId,
    required this.category,
    required this.condition,
    this.brand,
    this.model,
    this.estimatedValue,
    required this.ownerId,
    required this.owner,
    required this.tradePreferences,
    required this.status,
    this.location,
    required this.viewCount,
    required this.favoriteCount,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);

  Product copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? images,
    String? categoryId,
    Category? category,
    String? condition,
    String? brand,
    String? model,
    double? estimatedValue,
    String? ownerId,
    User? owner,
    List<String>? tradePreferences,
    ProductStatus? status,
    Location? location,
    int? viewCount,
    int? favoriteCount,
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
      category: category ?? this.category,
      condition: condition ?? this.condition,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      ownerId: ownerId ?? this.ownerId,
      owner: owner ?? this.owner,
      tradePreferences: tradePreferences ?? this.tradePreferences,
      status: status ?? this.status,
      location: location ?? this.location,
      viewCount: viewCount ?? this.viewCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
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