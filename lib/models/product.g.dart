// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************



Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'images': instance.images,
  'categoryId': instance.categoryId,
  'catname': instance.catname,
  'category': instance.category,
  'parentCategoryId': instance.parentCategoryId,
  'parentCategoryName': instance.parentCategoryName,
  'grandParentCategoryId': instance.grandParentCategoryId,
  'grandParentCategoryName': instance.grandParentCategoryName,
  'mainCategoryId': instance.mainCategoryId,
  'mainCategoryName': instance.mainCategoryName,
  'subCategoryId': instance.subCategoryId,
  'subCategoryName': instance.subCategoryName,
  'condition': instance.condition,
  'brand': instance.brand,
  'model': instance.model,
  'estimatedValue': instance.estimatedValue,
  'ownerId': instance.ownerId,
  'owner': instance.owner,
  'tradePreferences': instance.tradePreferences,
  'cityId': instance.cityId,
  'cityTitle': instance.cityTitle,
  'districtId': instance.districtId,
  'districtTitle': instance.districtTitle,
  'status': _$ProductStatusEnumMap[instance.status]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'expiresAt': instance.expiresAt?.toIso8601String(),
  'productImage': instance.productImage,
  'productGallery': instance.productGallery,
  'productCondition': instance.productCondition,
  'tradeFor': instance.tradeFor,
  'categoryList': instance.categoryList,
  'userFullname': instance.userFullname,
  'userFirstname': instance.userFirstname,
  'userLastname': instance.userLastname,
  'userPhone': instance.userPhone,
  'proView': instance.proView,
  'isShowContact': instance.isShowContact,
  'isFavorite': instance.isFavorite,
  'isSponsor': instance.isSponsor,
  'isTrade': instance.isTrade,
  'productLat': instance.productLat,
  'productLong': instance.productLong,
  'productCode': instance.productCode,
  'favoriteCount': instance.favoriteCount,
};

const _$ProductStatusEnumMap = {
  ProductStatus.active: 'active',
  ProductStatus.inactive: 'inactive',
  ProductStatus.traded: 'traded',
  ProductStatus.expired: 'expired',
  ProductStatus.deleted: 'deleted',
};

Category _$CategoryFromJson(Map<String, dynamic> json) => Category(
  id: json['id'] as String,
  name: json['name'] as String,
  icon: json['icon'] as String,
  parentId: json['parentId'] as String?,
  parentName: json['parentName'] as String?,
  grandParentId: json['grandParentId'] as String?,
  grandParentName: json['grandParentName'] as String?,
  mainCategoryId: json['mainCategoryId'] as String?,
  mainCategoryName: json['mainCategoryName'] as String?,
  subCategoryId: json['subCategoryId'] as String?,
  subCategoryName: json['subCategoryName'] as String?,
  children: (json['children'] as List<dynamic>?)
      ?.map((e) => Category.fromJson(e as Map<String, dynamic>))
      .toList(),
  isActive: json['isActive'] as bool,
  order: (json['order'] as num).toInt(),
  level: (json['level'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'icon': instance.icon,
  'parentId': instance.parentId,
  'parentName': instance.parentName,
  'grandParentId': instance.grandParentId,
  'grandParentName': instance.grandParentName,
  'mainCategoryId': instance.mainCategoryId,
  'mainCategoryName': instance.mainCategoryName,
  'subCategoryId': instance.subCategoryId,
  'subCategoryName': instance.subCategoryName,
  'children': instance.children,
  'isActive': instance.isActive,
  'order': instance.order,
  'level': instance.level,
};
