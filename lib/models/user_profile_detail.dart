import 'package:json_annotation/json_annotation.dart';

part 'user_profile_detail.g.dart';

@JsonSerializable()
class UserProfileDetail {
  final int userID;
  final String userFullname;
  final String? userImage;
  final String memberSince;
  final double averageRating;
  final int totalReviews;
  final List<ProfileProduct> products;
  final List<ProfileReview> reviews;
  final List<ProfileReview> myReviews;
  final bool isApproved;

  const UserProfileDetail({
    required this.userID,
    required this.userFullname,
    this.userImage,
    required this.memberSince,
    required this.averageRating,
    required this.totalReviews,
    required this.products,
    required this.reviews,
    required this.myReviews,
    required this.isApproved,
  });

  factory UserProfileDetail.fromJson(Map<String, dynamic> json) {
    try {
      return UserProfileDetail(
        userID: json['userID'] ?? 0,
        userFullname: json['userFullname'] ?? '',
        userImage: json['userImage'],
        memberSince: json['memberSince'] ?? '',
        averageRating: (json['averageRating'] ?? 0.0).toDouble(),
        totalReviews: json['totalReviews'] ?? 0,
        products: (json['products'] as List<dynamic>?)
                ?.map((e) => ProfileProduct.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        reviews: (json['reviews'] as List<dynamic>?)
                ?.map((e) => ProfileReview.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        myReviews: (json['myReviews'] as List<dynamic>?)
                ?.map((e) => ProfileReview.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        isApproved: json['isApproved'] ?? false,
      );
    } catch (e) {
      print('⚠️ UserProfileDetail.fromJson - Parse error: $e');
      return UserProfileDetail(
        userID: 0,
        userFullname: 'Kullanıcı',
        memberSince: '',
        averageRating: 0.0,
        totalReviews: 0,
        products: [],
        reviews: [],
        myReviews: [],
        isApproved: false,
      );
    }
  }

  Map<String, dynamic> toJson() => _$UserProfileDetailToJson(this);

  UserProfileDetail copyWith({
    int? userID,
    String? userFullname,
    String? userImage,
    String? memberSince,
    double? averageRating,
    int? totalReviews,
    List<ProfileProduct>? products,
    List<ProfileReview>? reviews,
    List<ProfileReview>? myReviews,
    bool? isApproved,
  }) {
    return UserProfileDetail(
      userID: userID ?? this.userID,
      userFullname: userFullname ?? this.userFullname,
      userImage: userImage ?? this.userImage,
      memberSince: memberSince ?? this.memberSince,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      products: products ?? this.products,
      reviews: reviews ?? this.reviews,
      myReviews: myReviews ?? this.myReviews,
      isApproved: isApproved ?? this.isApproved,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfileDetail && other.userID == userID;
  }

  @override
  int get hashCode => userID.hashCode;

  @override
  String toString() {
    return 'UserProfileDetail(userID: $userID, userFullname: $userFullname, averageRating: $averageRating, totalReviews: $totalReviews)';
  }
}

@JsonSerializable()
class ProfileProduct {
  final int productID;
  final String title;
  final String? mainImage;
  final bool isFavorite;
  // Ek alanlar - endpoint'ten gelen veriler
  final String? description;
  final String? categoryName;
  final String? condition;
  final String? brand;
  final String? model;
  final double? estimatedValue;
  final String? cityTitle;
  final String? districtTitle;
  final DateTime? createdAt;
  final String? productCode;
  final int? favoriteCount;
  final bool? isTrade;
  final bool? isSponsor;

  const ProfileProduct({
    required this.productID,
    required this.title,
    this.mainImage,
    required this.isFavorite,
    this.description,
    this.categoryName,
    this.condition,
    this.brand,
    this.model,
    this.estimatedValue,
    this.cityTitle,
    this.districtTitle,
    this.createdAt,
    this.productCode,
    this.favoriteCount,
    this.isTrade,
    this.isSponsor,
  });

  factory ProfileProduct.fromJson(Map<String, dynamic> json) {
    try {
      return ProfileProduct(
        productID: json['productID'] ?? json['id'] ?? 0,
        title: json['productTitle'] ?? json['title'] ?? '',
        mainImage: json['productImage'] ?? json['mainImage'] ?? json['image'],
        isFavorite: json['isFavorite'] ?? false,
        description: json['productDesc'] ?? json['description'],
        categoryName: json['categoryName'] ?? json['catname'] ?? json['category'],
        condition: json['productCondition'] ?? json['condition'],
        brand: json['brand'],
        model: json['model'],
        estimatedValue: json['estimatedValue'] != null ? (json['estimatedValue'] is int ? (json['estimatedValue'] as int).toDouble() : json['estimatedValue'] as double?) : null,
        cityTitle: json['cityTitle'] ?? json['city'],
        districtTitle: json['districtTitle'] ?? json['district'],
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
        productCode: json['productCode'] ?? json['code'],
        favoriteCount: json['favoriteCount'] ?? json['favorites'],
        isTrade: json['isTrade'] ?? json['trade'],
        isSponsor: json['isSponsor'] ?? json['sponsor'],
      );
    } catch (e) {
      print('⚠️ ProfileProduct.fromJson - Parse error: $e');
      return ProfileProduct(
        productID: 0,
        title: 'Ürün',
        isFavorite: false,
      );
    }
  }

  Map<String, dynamic> toJson() => _$ProfileProductToJson(this);

  ProfileProduct copyWith({
    int? productID,
    String? title,
    String? mainImage,
    bool? isFavorite,
    String? description,
    String? categoryName,
    String? condition,
    String? brand,
    String? model,
    double? estimatedValue,
    String? cityTitle,
    String? districtTitle,
    DateTime? createdAt,
    String? productCode,
    int? favoriteCount,
    bool? isTrade,
    bool? isSponsor,
  }) {
    return ProfileProduct(
      productID: productID ?? this.productID,
      title: title ?? this.title,
      mainImage: mainImage ?? this.mainImage,
      isFavorite: isFavorite ?? this.isFavorite,
      description: description ?? this.description,
      categoryName: categoryName ?? this.categoryName,
      condition: condition ?? this.condition,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      cityTitle: cityTitle ?? this.cityTitle,
      districtTitle: districtTitle ?? this.districtTitle,
      createdAt: createdAt ?? this.createdAt,
      productCode: productCode ?? this.productCode,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      isTrade: isTrade ?? this.isTrade,
      isSponsor: isSponsor ?? this.isSponsor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileProduct && other.productID == productID;
  }

  @override
  int get hashCode => productID.hashCode;

  @override
  String toString() {
    return 'ProfileProduct(productID: $productID, title: $title, isFavorite: $isFavorite)';
  }
}

@JsonSerializable()
class ProfileReview {
  final int reviewID;
  final String reviewerName;
  final String? reviewerImage;
  final int rating;
  final String comment;
  final String reviewDate;

  const ProfileReview({
    required this.reviewID,
    required this.reviewerName,
    this.reviewerImage,
    required this.rating,
    required this.comment,
    required this.reviewDate,
  });

  factory ProfileReview.fromJson(Map<String, dynamic> json) {
    try {
      return ProfileReview(
        reviewID: json['reviewID'] ?? 0,
        reviewerName: json['reviewerName'] ?? '',
        reviewerImage: json['reviewerImage'],
        rating: json['rating'] ?? 0,
        comment: json['comment'] ?? '',
        reviewDate: json['reviewDate'] ?? '',
      );
    } catch (e) {
      print('⚠️ ProfileReview.fromJson - Parse error: $e');
      return ProfileReview(
        reviewID: 0,
        reviewerName: 'Kullanıcı',
        rating: 0,
        comment: '',
        reviewDate: '',
      );
    }
  }

  Map<String, dynamic> toJson() => _$ProfileReviewToJson(this);

  ProfileReview copyWith({
    int? reviewID,
    String? reviewerName,
    String? reviewerImage,
    int? rating,
    String? comment,
    String? reviewDate,
  }) {
    return ProfileReview(
      reviewID: reviewID ?? this.reviewID,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewerImage: reviewerImage ?? this.reviewerImage,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      reviewDate: reviewDate ?? this.reviewDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileReview && other.reviewID == reviewID;
  }

  @override
  int get hashCode => reviewID.hashCode;

  @override
  String toString() {
    return 'ProfileReview(reviewID: $reviewID, reviewerName: $reviewerName, rating: $rating)';
  }
} 