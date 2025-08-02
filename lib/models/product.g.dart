// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  images: (json['images'] as List<dynamic>).map((e) => e as String).toList(),
  categoryId: json['categoryId'] as String,
  categoryName: json['categoryName'] as String,
  category: Category.fromJson(json['category'] as Map<String, dynamic>),
  parentCategoryId: json['parentCategoryId'] as String?,
  parentCategoryName: json['parentCategoryName'] as String?,
  grandParentCategoryId: json['grandParentCategoryId'] as String?,
  grandParentCategoryName: json['grandParentCategoryName'] as String?,
  mainCategoryId: json['mainCategoryId'] as String?,
  mainCategoryName: json['mainCategoryName'] as String?,
  subCategoryId: json['subCategoryId'] as String?,
  subCategoryName: json['subCategoryName'] as String?,
  condition: json['condition'] as String,
  brand: json['brand'] as String?,
  model: json['model'] as String?,
  estimatedValue: (json['estimatedValue'] as num?)?.toDouble(),
  ownerId: json['ownerId'] as String,
  owner: User.fromJson(json['owner'] as Map<String, dynamic>),
  tradePreferences: (json['tradePreferences'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  status: $enumDecode(_$ProductStatusEnumMap, json['status']),
  cityId: json['cityId'] as String,
  cityTitle: json['cityTitle'] as String,
  districtId: json['districtId'] as String,
  districtTitle: json['districtTitle'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  expiresAt: json['expiresAt'] == null
      ? null
      : DateTime.parse(json['expiresAt'] as String),
);

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'images': instance.images,
  'categoryId': instance.categoryId,
  'categoryName': instance.categoryName,
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
