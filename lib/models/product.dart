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
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    // Güvenli string dönüşümü
    String safeString(dynamic value) {
      if (value is String) return value;
      if (value != null) return value.toString();
      return '';
    }

    // Güvenli liste dönüşümü
    List<String> safeStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => safeString(e)).toList();
      }
      return [];
    }

    // Güvenli Map dönüşümü
    Map<String, dynamic>? safeMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) {
        final Map<String, dynamic> result = {};
        value.forEach((k, v) {
          if (k is String) {
            result[k] = v;
          }
        });
        return result;
      }
      return null;
    }

    return Product(
      id: safeString(json['id']),
      title: safeString(json['title']),
      description: safeString(json['description']),
      images: safeStringList(json['images']),
      categoryId: safeString(json['categoryId']),
      categoryName: safeString(json['categoryName']),
      category: safeMap(json['category']) != null 
          ? Category.fromJson(safeMap(json['category'])!)
          : Category(
              id: safeString(json['categoryId']),
              name: safeString(json['categoryName']),
              icon: '',
              isActive: true,
              order: 0,
            ),
      condition: safeString(json['condition']),
      brand: json['brand'] != null ? safeString(json['brand']) : null,
      model: json['model'] != null ? safeString(json['model']) : null,
      estimatedValue: (json['estimatedValue'] as num?)?.toDouble(),
      ownerId: safeString(json['ownerId']),
      owner: safeMap(json['owner']) != null 
          ? User.fromJson(safeMap(json['owner'])!)
          : User(
              id: safeString(json['ownerId']),
              name: 'Kullanıcı',
              email: '',
              isVerified: false,
              isOnline: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
      tradePreferences: safeStringList(json['tradePreferences']),
      status: ProductStatus.values.firstWhere(
        (e) => e.name == safeString(json['status']),
        orElse: () => ProductStatus.active,
      ),
      cityId: safeString(json['cityId']),
      cityTitle: safeString(json['cityTitle']),
      districtId: safeString(json['districtId']),
      districtTitle: safeString(json['districtTitle']),
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
      expiresAt: json['expiresAt'] != null ? parseDateTime(json['expiresAt']) : null,
    );
  }
  Map<String, dynamic> toJson() {
    final json = _$ProductToJson(this);
    // Category ve User nesnelerini Firebase uyumlu hale getir
    json['category'] = category.toJson();
    json['owner'] = owner.toJson();
    return json;
  }

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

  factory Category.fromJson(Map<String, dynamic> json) {
    // Güvenli string dönüşümü
    String safeString(dynamic value) {
      if (value is String) return value;
      if (value != null) return value.toString();
      return '';
    }

    // Güvenli int dönüşümü
    int safeInt(dynamic value, {int defaultValue = 0}) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      if (value is num) return value.toInt();
      return defaultValue;
    }

    // Güvenli bool dönüşümü
    bool safeBool(dynamic value, {bool defaultValue = true}) {
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      if (value is int) return value != 0;
      return defaultValue;
    }

    // Güvenli liste dönüşümü
    List<Category>? safeCategoryList(dynamic value) {
      if (value is List) {
        return value.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
      }
      return null;
    }

    return Category(
      id: safeString(json['id']),
      name: safeString(json['name']),
      icon: safeString(json['icon']),
      parentId: json['parentId'] != null ? safeString(json['parentId']) : null,
      children: safeCategoryList(json['children']),
      isActive: safeBool(json['isActive']),
      order: safeInt(json['order']),
    );
  }
  
  // Firebase uyumlu toJson metodu
  Map<String, dynamic> toJson() {
    final json = _$CategoryToJson(this);
    // children alanını Firebase uyumlu hale getir
    if (children != null) {
      json['children'] = children!.map((child) => child.toJson()).toList();
    }
    return json;
  }

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