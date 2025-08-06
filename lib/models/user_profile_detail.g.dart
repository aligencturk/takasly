// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfileDetail _$UserProfileDetailFromJson(Map<String, dynamic> json) =>
    UserProfileDetail(
      userID: (json['userID'] as num).toInt(),
      userFullname: json['userFullname'] as String,
      userImage: json['userImage'] as String?,
      memberSince: json['memberSince'] as String,
      averageRating: (json['averageRating'] as num).toDouble(),
      totalReviews: (json['totalReviews'] as num).toInt(),
      products: (json['products'] as List<dynamic>)
          .map((e) => ProfileProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      reviews: (json['reviews'] as List<dynamic>)
          .map((e) => ProfileReview.fromJson(e as Map<String, dynamic>))
          .toList(),
      myReviews: (json['myReviews'] as List<dynamic>)
          .map((e) => ProfileReview.fromJson(e as Map<String, dynamic>))
          .toList(),
      isApproved: json['isApproved'] as bool,
    );

Map<String, dynamic> _$UserProfileDetailToJson(UserProfileDetail instance) =>
    <String, dynamic>{
      'userID': instance.userID,
      'userFullname': instance.userFullname,
      'userImage': instance.userImage,
      'memberSince': instance.memberSince,
      'averageRating': instance.averageRating,
      'totalReviews': instance.totalReviews,
      'products': instance.products,
      'reviews': instance.reviews,
      'myReviews': instance.myReviews,
      'isApproved': instance.isApproved,
    };

ProfileProduct _$ProfileProductFromJson(Map<String, dynamic> json) =>
    ProfileProduct(
      productID: (json['productID'] as num).toInt(),
      title: json['title'] as String,
      mainImage: json['mainImage'] as String?,
      isFavorite: json['isFavorite'] as bool,
      description: json['description'] as String?,
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String?,
      condition: json['condition'] as String?,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      estimatedValue: (json['estimatedValue'] as num?)?.toDouble(),
      cityTitle: json['cityTitle'] as String?,
      districtTitle: json['districtTitle'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      productCode: json['productCode'] as String?,
      favoriteCount: (json['favoriteCount'] as num?)?.toInt(),
      isTrade: json['isTrade'] as bool?,
      isSponsor: json['isSponsor'] as bool?,
      categoryList: (json['categoryList'] as List<dynamic>?)
          ?.map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProfileProductToJson(ProfileProduct instance) =>
    <String, dynamic>{
      'productID': instance.productID,
      'title': instance.title,
      'mainImage': instance.mainImage,
      'isFavorite': instance.isFavorite,
      'description': instance.description,
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'condition': instance.condition,
      'brand': instance.brand,
      'model': instance.model,
      'estimatedValue': instance.estimatedValue,
      'cityTitle': instance.cityTitle,
      'districtTitle': instance.districtTitle,
      'createdAt': instance.createdAt?.toIso8601String(),
      'productCode': instance.productCode,
      'favoriteCount': instance.favoriteCount,
      'isTrade': instance.isTrade,
      'isSponsor': instance.isSponsor,
      'categoryList': instance.categoryList,
    };

ProfileReview _$ProfileReviewFromJson(Map<String, dynamic> json) =>
    ProfileReview(
      reviewID: (json['reviewID'] as num).toInt(),
      reviewerName: json['revieweeName'] as String? ?? '',
      reviewerImage: json['revieweeImage'] as String?,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String,
      reviewDate: json['reviewDate'] as String,
    );

Map<String, dynamic> _$ProfileReviewToJson(ProfileReview instance) =>
    <String, dynamic>{
      'reviewID': instance.reviewID,
      'revieweeName': instance.reviewerName,
      'revieweeImage': instance.reviewerImage,
      'rating': instance.rating,
      'comment': instance.comment,
      'reviewDate': instance.reviewDate,
    };
