// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************


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

Map<String, dynamic> _$ProfileReviewToJson(ProfileReview instance) =>
    <String, dynamic>{
      'reviewID': instance.reviewID,
      'reviewerUserID': instance.reviewerUserID,
      'reviewerName': instance.reviewerName,
      'reviewerImage': instance.reviewerImage,
      'revieweeName': instance.revieweeName,
      'rating': instance.rating,
      'comment': instance.comment,
      'reviewDate': instance.reviewDate,
    };
