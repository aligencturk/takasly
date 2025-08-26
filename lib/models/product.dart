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
  final String catname;
  final Category category;
  // 3 katmanlı kategori sistemi için ek alanlar
  final String? parentCategoryId;
  final String? parentCategoryName;
  final String? grandParentCategoryId;
  final String? grandParentCategoryName;
  final String? mainCategoryId;
  final String? mainCategoryName;
  final String? subCategoryId;
  final String? subCategoryName;
  final String? subSubCategoryId;
  final String? subSubCategoryName;
  final String? subSubSubCategoryId;
  final String? subSubSubCategoryName;
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

  // Yeni API alanları
  final String? productImage;
  final List<String>? productGallery;
  final String? productCondition;
  final String? tradeFor;
  final List<Category>? categoryList;
  final String? userFullname;
  final String? userFirstname;
  final String? userLastname;
  final String? userPhone;
  final String? userImage;
  final String? proView;
  final bool? isShowContact;
  final bool? isFavorite;
  final bool? isSponsor;
  final String? sponsorUntil;
  final bool? isTrade;
  final String? productLat;
  final String? productLong;
  final String? productCode;
  final int? favoriteCount;
  final String? profilePhoto;
  final String? shareLink;
  // Kullanıcı puan bilgileri - artık product detail API'den geliyor
  final double? averageRating;
  final int? totalReviews;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.images,
    required this.categoryId,
    required this.catname,
    required this.category,
    this.parentCategoryId,
    this.parentCategoryName,
    this.grandParentCategoryId,
    this.grandParentCategoryName,
    this.mainCategoryId,
    this.mainCategoryName,
    this.subCategoryId,
    this.subCategoryName,
    this.subSubCategoryId,
    this.subSubCategoryName,
    this.subSubSubCategoryId,
    this.subSubSubCategoryName,
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
    // Yeni API alanları
    this.productImage,
    this.productGallery,
    this.productCondition,
    this.tradeFor,
    this.categoryList,
    this.userFullname,
    this.userFirstname,
    this.userLastname,
    this.userPhone,
    this.userImage,
    this.proView,
    this.isShowContact,
    this.isFavorite,
    this.isSponsor,
    this.sponsorUntil,
    this.isTrade,
    this.productLat,
    this.productLong,
    this.productCode,
    this.favoriteCount,
    this.profilePhoto,
    this.shareLink,
    this.averageRating,
    this.totalReviews,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // DateTime'ları güvenli şekilde parse et
    DateTime parseDateTime(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) {
        try {
          // Türkçe tarih formatı için özel parsing (02.08.2025)
          if (value.contains('.')) {
            final parts = value.split('.');
            if (parts.length == 3) {
              final day = int.tryParse(parts[0]) ?? 1;
              final month = int.tryParse(parts[1]) ?? 1;
              final year = int.tryParse(parts[2]) ?? 2025;
              return DateTime(year, month, day);
            }
          }
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

    // Güvenli Category listesi dönüşümü
    List<Category> safeCategoryList(dynamic value) {
      if (value is List) {
        return value.map((e) {
          if (e is Map<String, dynamic>) {
            return Category.fromJson(e);
          }
          return Category(
            id: safeString(e['catID'] ?? e['id']),
            name: safeString(e['catName'] ?? e['name']),
            icon: '',
            isActive: true,
            order: 0,
          );
        }).toList();
      }
      return [];
    }

    // Yeni API yanıtı için alan mapping
    final productId = safeString(json['productID'] ?? json['id']);
    final productTitle = safeString(json['productTitle'] ?? json['title']);
    final productDesc = safeString(json['productDesc'] ?? json['description']);
    final productImage = json['productImage'] != null
        ? safeString(json['productImage'])
        : null;
    final productGallery = json['productGallery'] != null
        ? safeStringList(json['productGallery'])
        : null;
    final productCondition = json['productCondition'] != null
        ? safeString(json['productCondition'])
        : null;
    final tradeFor = json['tradeFor'] != null
        ? safeString(json['tradeFor'])
        : null;
    final categoryList = json['categoryList'] != null
        ? safeCategoryList(json['categoryList'])
        : null;
    final userId = safeString(json['userID'] ?? json['ownerId']);
    final categoryId = safeString(json['categoryID'] ?? json['categoryId']);
    final cityId = safeString(json['cityID'] ?? json['cityId']);
    final districtId = safeString(json['districtID'] ?? json['districtId']);
    final cityTitle = safeString(json['cityTitle']);
    final districtTitle = safeString(json['districtTitle']);
    final productLat = json['productLat'] != null
        ? safeString(json['productLat'])
        : null;
    final productLong = json['productLong'] != null
        ? safeString(json['productLong'])
        : null;
    final userFullname = json['userFullname'] != null
        ? safeString(json['userFullname'])
        : null;
    final userFirstname = json['userFirstname'] != null
        ? safeString(json['userFirstname'])
        : null;
    final userLastname = json['userLastname'] != null
        ? safeString(json['userLastname'])
        : null;
    final userPhone = json['userPhone'] != null
        ? safeString(json['userPhone'])
        : null;
    final userImage = json['userImage'] != null
        ? safeString(json['userImage'])
        : json['userAvatar'] != null
        ? safeString(json['userAvatar'])
        : json['profileImage'] != null
        ? safeString(json['profileImage'])
        : json['avatar'] != null
        ? safeString(json['avatar'])
        : null;
    final createdAt = parseDateTime(json['createdAt']);
    final proView = json['proView'] != null
        ? safeString(json['proView'])
        : null;
    final isShowContact = json['isShowContact'] as bool?;
    final isFavorite = json['isFavorite'] as bool?;
    final isSponsor = json['isSponsor'] as bool?;
    final sponsorUntil = json['sponsorUntil'] != null
        ? safeString(json['sponsorUntil'])
        : null;
    final isTrade = json['isTrade'] as bool?;
    final productCode = json['productCode'] != null
        ? safeString(json['productCode'])
        : null;
    final favoriteCount = json['favoriteCount'] as int?;
    final profilePhoto = json['profilePhoto'] != null
        ? safeString(json['profilePhoto'])
        : null;
    final shareLink = json['shareLink'] != null
        ? safeString(json['shareLink'])
        : null;

    // Kullanıcı puan bilgileri - artık product detail API'den geliyor
    final averageRating = json['averageRating'] != null
        ? double.tryParse(json['averageRating'].toString())
        : null;
    final totalReviews = json['totalReviews'] != null
        ? int.tryParse(json['totalReviews'].toString())
        : null;

    // Ana resim ve galeri resimlerini birleştir
    final allImages = <String>[];
    if (productImage != null && productImage.isNotEmpty) {
      allImages.add(productImage);
    }
    if (productGallery != null) {
      allImages.addAll(productGallery);
    }
    if (allImages.isEmpty && json['images'] != null) {
      allImages.addAll(safeStringList(json['images']));
    }

    // Kategori bilgisini oluştur
    Category category;
    if (categoryList != null && categoryList.isNotEmpty) {
      category = categoryList.first;
    } else if (safeMap(json['category']) != null) {
      category = Category.fromJson(safeMap(json['category'])!);
    } else {
      category = Category(
        id: categoryId,
        name: safeString(json['catname'] ?? json['categoryName']),
        icon: '',
        isActive: true,
        order: 0,
      );
    }

    // Kullanıcı bilgisini oluştur
    User owner;
    if (safeMap(json['owner']) != null) {
      owner = User.fromJson(safeMap(json['owner'])!);
    } else {
      owner = User(
        id: userId,
        name: userFullname ?? userFirstname ?? 'Kullanıcı',
        firstName: userFirstname,
        lastName: userLastname,
        email: '',
        isVerified: false,
        isOnline: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    return Product(
      id: productId,
      title: productTitle,
      description: productDesc,
      images: allImages,
      categoryId: categoryId,
      catname: category.name,
      category: category,
      parentCategoryId: json['parentCategoryId'] != null
          ? safeString(json['parentCategoryId'])
          : null,
      parentCategoryName: json['parentCategoryName'] != null
          ? safeString(json['parentCategoryName'])
          : null,
      grandParentCategoryId: json['grandParentCategoryId'] != null
          ? safeString(json['grandParentCategoryId'])
          : null,
      grandParentCategoryName: json['grandParentCategoryName'] != null
          ? safeString(json['grandParentCategoryName'])
          : null,
      mainCategoryId: json['mainCategoryId'] != null
          ? safeString(json['mainCategoryId'])
          : null,
      mainCategoryName: json['mainCategoryName'] != null
          ? safeString(json['mainCategoryName'])
          : null,
      subCategoryId: json['subCategoryId'] != null
          ? safeString(json['subCategoryId'])
          : null,
      subCategoryName: json['subCategoryName'] != null
          ? safeString(json['subCategoryName'])
          : null,
      subSubCategoryId: json['subSubCategoryId'] != null
          ? safeString(json['subSubCategoryId'])
          : null,
      subSubCategoryName: json['subSubCategoryName'] != null
          ? safeString(json['subSubCategoryName'])
          : null,
      subSubSubCategoryId: json['subSubSubCategoryId'] != null
          ? safeString(json['subSubSubCategoryId'])
          : null,
      subSubSubCategoryName: json['subSubSubCategoryName'] != null
          ? safeString(json['subSubSubCategoryName'])
          : null,
      condition: productCondition ?? safeString(json['condition']),
      brand: json['brand'] != null ? safeString(json['brand']) : null,
      model: json['model'] != null ? safeString(json['model']) : null,
      estimatedValue: (json['estimatedValue'] as num?)?.toDouble(),
      ownerId: userId,
      owner: owner,
      tradePreferences: tradeFor != null
          ? [tradeFor]
          : safeStringList(json['tradePreferences']),
      status: ProductStatus.values.firstWhere(
        (e) => e.name == safeString(json['status']),
        orElse: () => ProductStatus.active,
      ),
      cityId: cityId,
      cityTitle: cityTitle,
      districtId: districtId,
      districtTitle: districtTitle,
      createdAt: createdAt,
      updatedAt: parseDateTime(json['updatedAt']),
      expiresAt: json['expiresAt'] != null
          ? parseDateTime(json['expiresAt'])
          : null,
      // Yeni API alanları
      productImage: productImage,
      productGallery: productGallery,
      productCondition: productCondition,
      tradeFor: tradeFor,
      categoryList: categoryList,
      userFullname: userFullname,
      userFirstname: userFirstname,
      userLastname: userLastname,
      userPhone: userPhone,
      userImage: userImage,
      proView: proView,
      isShowContact: isShowContact,
      isFavorite: isFavorite,
      isSponsor: isSponsor,
      sponsorUntil: sponsorUntil,
      isTrade: isTrade,
      productLat: productLat,
      productLong: productLong,
      productCode: productCode,
      favoriteCount: favoriteCount,
      profilePhoto: profilePhoto,
      shareLink: shareLink,
      // Kullanıcı puan bilgileri - artık product detail API'den geliyor
      averageRating: averageRating,
      totalReviews: totalReviews,
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
    String? parentCategoryId,
    String? parentCategoryName,
    String? grandParentCategoryId,
    String? grandParentCategoryName,
    String? mainCategoryId,
    String? mainCategoryName,
    String? subCategoryId,
    String? subCategoryName,
    String? subSubCategoryId,
    String? subSubCategoryName,
    String? subSubSubCategoryId,
    String? subSubSubCategoryName,
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
    // Yeni API alanları
    String? productImage,
    List<String>? productGallery,
    String? productCondition,
    String? tradeFor,
    List<Category>? categoryList,
    String? userFullname,
    String? userFirstname,
    String? userLastname,
    String? userPhone,
    String? userImage,
    String? proView,
    bool? isShowContact,
    bool? isFavorite,
    bool? isSponsor,
    String? sponsorUntil,
    bool? isTrade,
    String? productLat,
    String? productLong,
    String? productCode,
    int? favoriteCount,
    String? profilePhoto,
    String? shareLink,
    double? averageRating,
    int? totalReviews,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      images: images ?? this.images,
      categoryId: categoryId ?? this.categoryId,
      catname: catname,
      category: category ?? this.category,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
      parentCategoryName: parentCategoryName ?? this.parentCategoryName,
      grandParentCategoryId:
          grandParentCategoryId ?? this.grandParentCategoryId,
      grandParentCategoryName:
          grandParentCategoryName ?? this.grandParentCategoryName,
      mainCategoryId: mainCategoryId ?? this.mainCategoryId,
      mainCategoryName: mainCategoryName ?? this.mainCategoryName,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      subCategoryName: subCategoryName ?? this.subCategoryName,
      subSubCategoryId: subSubCategoryId ?? this.subSubCategoryId,
      subSubCategoryName: subSubCategoryName ?? this.subSubCategoryName,
      subSubSubCategoryId: subSubSubCategoryId ?? this.subSubSubCategoryId,
      subSubSubCategoryName:
          subSubSubCategoryName ?? this.subSubSubCategoryName,
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
      // Yeni API alanları
      productImage: productImage ?? this.productImage,
      productGallery: productGallery ?? this.productGallery,
      productCondition: productCondition ?? this.productCondition,
      tradeFor: tradeFor ?? this.tradeFor,
      categoryList: categoryList ?? this.categoryList,
      userFullname: userFullname ?? this.userFullname,
      userFirstname: userFirstname ?? this.userFirstname,
      userLastname: userLastname ?? this.userLastname,
      userPhone: userPhone ?? this.userPhone,
      userImage: userImage ?? this.userImage,
      proView: proView ?? this.proView,
      isShowContact: isShowContact ?? this.isShowContact,
      isFavorite: isFavorite ?? this.isFavorite,
      isSponsor: isSponsor ?? this.isSponsor,
      sponsorUntil: sponsorUntil ?? this.sponsorUntil,
      isTrade: isTrade ?? this.isTrade,
      productLat: productLat ?? this.productLat,
      productLong: productLong ?? this.productLong,
      productCode: productCode ?? this.productCode,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      shareLink: shareLink ?? this.shareLink,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
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

class PaginatedProducts {
  final List<Product> products;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasMore;

  PaginatedProducts({
    required this.products,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasMore,
  });

  factory PaginatedProducts.fromJson(Map<String, dynamic> json) {
    // API response'unda products listesi data.products içinde olabilir
    List<dynamic> productsList;
    if (json['data'] != null && json['data']['products'] != null) {
      productsList = json['data']['products'] as List;
    } else if (json['products'] != null) {
      productsList = json['products'] as List;
    } else {
      productsList = [];
    }

    final products = productsList
        .map((item) => Product.fromJson(item))
        .toList();

    // Sayfalama bilgileri data içinde olabilir
    Map<String, dynamic> data = json['data'] ?? json;
    final currentPage = data['page'] as int? ?? 1;
    final totalPages = data['totalPages'] as int? ?? 1;
    final totalItems = data['totalItems'] as int? ?? products.length;
    final hasMore = currentPage < totalPages;

    return PaginatedProducts(
      products: products,
      currentPage: currentPage,
      totalPages: totalPages,
      totalItems: totalItems,
      hasMore: hasMore,
    );
  }
}

@JsonSerializable()
class Category {
  final String id;
  final String name;
  final String icon;
  final String? parentId;
  final String? parentName;
  final String? grandParentId;
  final String? grandParentName;
  final String? mainCategoryId;
  final String? mainCategoryName;
  final String? subCategoryId;
  final String? subCategoryName;
  final List<Category>? children;
  final bool isActive;
  final int order;
  final int level; // 1: Ana kategori, 2: Alt kategori, 3: Alt-alt kategori

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    this.parentId,
    this.parentName,
    this.grandParentId,
    this.grandParentName,
    this.mainCategoryId,
    this.mainCategoryName,
    this.subCategoryId,
    this.subCategoryName,
    this.children,
    required this.isActive,
    required this.order,
    this.level = 1,
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
        return value
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return null;
    }

    return Category(
      id: safeString(json['catID'] ?? json['id']),
      name: safeString(json['catName'] ?? json['name']),
      icon: safeString(json['icon']),
      parentId: json['parentId'] != null ? safeString(json['parentId']) : null,
      parentName: json['parentName'] != null
          ? safeString(json['parentName'])
          : null,
      grandParentId: json['grandParentId'] != null
          ? safeString(json['grandParentId'])
          : null,
      grandParentName: json['grandParentName'] != null
          ? safeString(json['grandParentName'])
          : null,
      mainCategoryId: json['mainCategoryId'] != null
          ? safeString(json['mainCategoryId'])
          : null,
      mainCategoryName: json['mainCategoryName'] != null
          ? safeString(json['mainCategoryName'])
          : null,
      subCategoryId: json['subCategoryId'] != null
          ? safeString(json['subCategoryId'])
          : null,
      subCategoryName: json['subCategoryName'] != null
          ? safeString(json['subCategoryName'])
          : null,
      children: safeCategoryList(json['children']),
      isActive: safeBool(json['isActive']),
      order: safeInt(json['order']),
      level: safeInt(json['level'], defaultValue: 1),
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
    String? parentName,
    String? grandParentId,
    String? grandParentName,
    String? mainCategoryId,
    String? mainCategoryName,
    String? subCategoryId,
    String? subCategoryName,
    List<Category>? children,
    bool? isActive,
    int? order,
    int? level,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      parentId: parentId ?? this.parentId,
      parentName: parentName ?? this.parentName,
      grandParentId: grandParentId ?? this.grandParentId,
      grandParentName: grandParentName ?? this.grandParentName,
      mainCategoryId: mainCategoryId ?? this.mainCategoryId,
      mainCategoryName: mainCategoryName ?? this.mainCategoryName,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      subCategoryName: subCategoryName ?? this.subCategoryName,
      children: children ?? this.children,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      level: level ?? this.level,
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

enum ProductStatus { active, inactive, traded, expired, deleted }

enum ProductCondition { new_, likeNew, good, fair, poor }
