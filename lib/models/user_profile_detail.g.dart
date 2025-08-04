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
    );

Map<String, dynamic> _$ProfileProductToJson(ProfileProduct instance) =>
    <String, dynamic>{
      'productID': instance.productID,
      'title': instance.title,
      'mainImage': instance.mainImage,
      'isFavorite': instance.isFavorite,
    };

ProfileReview _$ProfileReviewFromJson(Map<String, dynamic> json) =>
    ProfileReview(
      reviewID: (json['reviewID'] as num).toInt(),
      reviewerName: json['reviewerName'] as String,
      reviewerImage: json['reviewerImage'] as String?,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String,
      reviewDate: json['reviewDate'] as String,
    );

Map<String, dynamic> _$ProfileReviewToJson(ProfileReview instance) =>
    <String, dynamic>{
      'reviewID': instance.reviewID,
      'reviewerName': instance.reviewerName,
      'reviewerImage': instance.reviewerImage,
      'rating': instance.rating,
      'comment': instance.comment,
      'reviewDate': instance.reviewDate,
    };
