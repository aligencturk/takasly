import 'package:json_annotation/json_annotation.dart';
import '../utils/logger.dart';
import 'product.dart';

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
      // API'den gelen farklı field isimlerini kontrol et
      final isApproved = json['isApproved'] ?? 
                        json['userApproved'] ?? 
                        json['verified'] ?? 
                        json['isVerified'] ?? 
                        false;
      
      Logger.debug('🔍 UserProfileDetail.fromJson - isApproved: $isApproved', tag: 'UserProfileDetail');
      
      // Kullanıcı adını düzgün şekilde parse et
      String userFullname = '';
      if (json['userFullname'] != null && json['userFullname'].toString().isNotEmpty && json['userFullname'].toString() != 'null') {
        userFullname = json['userFullname'].toString();
      } else if (json['fullName'] != null && json['fullName'].toString().isNotEmpty && json['fullName'].toString() != 'null') {
        userFullname = json['fullName'].toString();
      } else if (json['name'] != null && json['name'].toString().isNotEmpty && json['name'].toString() != 'null') {
        userFullname = json['name'].toString();
      } else if (json['firstName'] != null && json['lastName'] != null) {
        userFullname = '${json['firstName']} ${json['lastName']}'.trim();
      }
      
      Logger.debug('🔍 UserProfileDetail.fromJson - userFullname: $userFullname', tag: 'UserProfileDetail');
      
      final result = UserProfileDetail(
        userID: json['userID'] ?? json['id'] ?? 0,
        userFullname: userFullname,
        userImage: json['userImage'] ?? json['profileImage'] ?? json['avatar'],
        memberSince: json['memberSince'] ?? json['createdAt'] ?? '',
        averageRating: (json['averageRating'] ?? json['rating'] ?? 0.0).toDouble(),
        totalReviews: json['totalReviews'] ?? json['reviewCount'] ?? 0,
        products: (json['products'] as List<dynamic>?)
                ?.map((e) => ProfileProduct.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        reviews: (json['reviews'] as List<dynamic>?)
                ?.map((e) => ProfileReview.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        myReviews: (json['myReviews'] as List<dynamic>?)
                ?.map((e) {
                  Logger.debug('🔍 UserProfileDetail.fromJson - Parsing myReview: $e', tag: 'UserProfileDetail');
                  return ProfileReview.fromJson(e as Map<String, dynamic>);
                })
                .toList() ??
            [],
        isApproved: isApproved,
      );
      
      // Debug logları ekle
      Logger.debug('🔍 UserProfileDetail.fromJson - Parsed successfully', tag: 'UserProfileDetail');
      Logger.debug('🔍 UserProfileDetail.fromJson - User: $userFullname (ID: ${json['userID'] ?? json['id'] ?? 0})', tag: 'UserProfileDetail');
      Logger.debug('🔍 UserProfileDetail.fromJson - MyReviews count: ${(json['myReviews'] as List<dynamic>?)?.length ?? 0}', tag: 'UserProfileDetail');
      Logger.debug('🔍 UserProfileDetail.fromJson - Reviews count: ${(json['reviews'] as List<dynamic>?)?.length ?? 0}', tag: 'UserProfileDetail');
      Logger.debug('🔍 UserProfileDetail.fromJson - Products count: ${(json['products'] as List<dynamic>?)?.length ?? 0}', tag: 'UserProfileDetail');
      
      // MyReviews detaylarını logla
      final myReviewsList = json['myReviews'] as List<dynamic>?;
      if (myReviewsList != null) {
        for (int i = 0; i < myReviewsList.length; i++) {
          final reviewJson = myReviewsList[i] as Map<String, dynamic>;
          Logger.debug('🔍 UserProfileDetail.fromJson - MyReview $i: ID=${reviewJson['reviewID']}, Rating=${reviewJson['rating']}, Comment="${reviewJson['comment']}"', tag: 'UserProfileDetail');
        }
      }
      
      return result;
    } catch (e) {
      Logger.error('⚠️ UserProfileDetail.fromJson - Parse error: $e', tag: 'UserProfileDetail');
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
  final String? categoryId; // Kategori ID'si eklendi
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
  final List<Category>? categoryList;

  const ProfileProduct({
    required this.productID,
    required this.title,
    this.mainImage,
    required this.isFavorite,
    this.description,
    this.categoryId,
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
    this.categoryList,
  });

  factory ProfileProduct.fromJson(Map<String, dynamic> json) {
    try {
      Logger.debug('🔍 ProfileProduct.fromJson - Raw JSON: $json', tag: 'ProfileProduct');
      Logger.debug('🔍 ProfileProduct.fromJson - Available keys: ${json.keys.toList()}', tag: 'ProfileProduct');
      
      // Kategori ID'sini parse et
      String? categoryId;
      Logger.debug('🔍 ProfileProduct.fromJson - Checking categoryId fields...', tag: 'ProfileProduct');
      Logger.debug('🔍 ProfileProduct.fromJson - categoryId: ${json['categoryId']}', tag: 'ProfileProduct');
      Logger.debug('🔍 ProfileProduct.fromJson - category_id: ${json['category_id']}', tag: 'ProfileProduct');
      Logger.debug('🔍 ProfileProduct.fromJson - catId: ${json['catId']}', tag: 'ProfileProduct');
      
      if (json['categoryId'] != null && json['categoryId'].toString().isNotEmpty && json['categoryId'].toString() != 'null') {
        categoryId = json['categoryId'].toString();
        Logger.debug('🔍 ProfileProduct.fromJson - Using categoryId: $categoryId', tag: 'ProfileProduct');
      } else if (json['category_id'] != null && json['category_id'].toString().isNotEmpty && json['category_id'].toString() != 'null') {
        categoryId = json['category_id'].toString();
        Logger.debug('🔍 ProfileProduct.fromJson - Using category_id: $categoryId', tag: 'ProfileProduct');
      } else if (json['catId'] != null && json['catId'].toString().isNotEmpty && json['catId'].toString() != 'null') {
        categoryId = json['catId'].toString();
        Logger.debug('🔍 ProfileProduct.fromJson - Using catId: $categoryId', tag: 'ProfileProduct');
      } else {
        Logger.debug('🔍 ProfileProduct.fromJson - No valid categoryId found', tag: 'ProfileProduct');
      }
      
      // Kategori adını düzgün şekilde parse et
      String? categoryName;
      Logger.debug('🔍 ProfileProduct.fromJson - Checking categoryName fields...', tag: 'ProfileProduct');
      Logger.debug('🔍 ProfileProduct.fromJson - categoryName: ${json['categoryName']}', tag: 'ProfileProduct');
      Logger.debug('🔍 ProfileProduct.fromJson - catname: ${json['catname']}', tag: 'ProfileProduct');
      Logger.debug('🔍 ProfileProduct.fromJson - category: ${json['category']}', tag: 'ProfileProduct');
      
      if (json['categoryName'] != null && json['categoryName'].toString().isNotEmpty && json['categoryName'].toString() != 'null') {
        categoryName = json['categoryName'].toString();
        Logger.debug('🔍 ProfileProduct.fromJson - Using categoryName: $categoryName', tag: 'ProfileProduct');
      } else if (json['catname'] != null && json['catname'].toString().isNotEmpty && json['catname'].toString() != 'null') {
        categoryName = json['catname'].toString();
        Logger.debug('🔍 ProfileProduct.fromJson - Using catname: $categoryName', tag: 'ProfileProduct');
      } else if (json['category'] != null && json['category'].toString().isNotEmpty && json['category'].toString() != 'null') {
        categoryName = json['category'].toString();
        Logger.debug('🔍 ProfileProduct.fromJson - Using category: $categoryName', tag: 'ProfileProduct');
      } else {
        Logger.debug('🔍 ProfileProduct.fromJson - No valid categoryName found', tag: 'ProfileProduct');
      }
      
      Logger.debug('🔍 ProfileProduct.fromJson - Final categoryId: $categoryId, categoryName: $categoryName', tag: 'ProfileProduct');
      
      // CategoryList'i parse et
      List<Category>? categoryList;
      if (json['categoryList'] != null && json['categoryList'] is List) {
        try {
          categoryList = (json['categoryList'] as List).map((catJson) {
            return Category(
              id: catJson['catID']?.toString() ?? '0',
              name: catJson['catName']?.toString() ?? 'Kategori',
              icon: '',
              isActive: true,
              order: 0,
            );
          }).toList();
          Logger.debug('🔍 ProfileProduct.fromJson - categoryList parsed: ${categoryList.length} categories', tag: 'ProfileProduct');
        } catch (e) {
          Logger.error('⚠️ ProfileProduct.fromJson - categoryList parse error: $e', tag: 'ProfileProduct');
          categoryList = null;
        }
      }
      
      return ProfileProduct(
        productID: json['productID'] ?? json['id'] ?? 0,
        title: json['productTitle'] ?? json['title'] ?? '',
        mainImage: json['productImage'] ?? json['mainImage'] ?? json['image'],
        isFavorite: json['isFavorite'] ?? false,
        description: json['productDesc'] ?? json['description'],
        categoryId: categoryId,
        categoryName: categoryName,
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
        categoryList: categoryList,
      );
    } catch (e) {
      Logger.error('⚠️ ProfileProduct.fromJson - Parse error: $e', tag: 'ProfileProduct');
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
    String? categoryId,
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
    List<Category>? categoryList,
  }) {
    return ProfileProduct(
      productID: productID ?? this.productID,
      title: title ?? this.title,
      mainImage: mainImage ?? this.mainImage,
      isFavorite: isFavorite ?? this.isFavorite,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
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
      categoryList: categoryList ?? this.categoryList,
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
   final int? reviewerUserID;
   final String reviewerName;
   final String? reviewerImage;
   final String? revieweeName; // Kim için yorum yapıldı
   final int rating;
   final String comment;
   final String reviewDate;

     const ProfileReview({
     required this.reviewID,
     this.reviewerUserID,
     required this.reviewerName,
     this.reviewerImage,
     this.revieweeName,
     required this.rating,
     required this.comment,
     required this.reviewDate,
   });

  factory ProfileReview.fromJson(Map<String, dynamic> json) {
    try {
      Logger.debug('🔍 ProfileReview.fromJson - Parsing: $json', tag: 'ProfileReview');
      Logger.debug('🔍 ProfileReview.fromJson - Available keys: ${json.keys.toList()}', tag: 'ProfileReview');
      
      // API'den gelen farklı field isimlerini kontrol et
      final reviewID = json['reviewID'] ?? json['id'] ?? 0;
      // Kullanıcı ID'sini farklı olası alanlardan oku
      int? reviewerUserID;
      Logger.debug('🔍 ProfileReview.fromJson - All JSON data: $json', tag: 'ProfileReview');
      Logger.debug('🔍 ProfileReview.fromJson - Checking revieweeID: ${json['revieweeID']}', tag: 'ProfileReview');
      Logger.debug('🔍 ProfileReview.fromJson - Checking reviewerID: ${json['reviewerID']}', tag: 'ProfileReview');
      Logger.debug('🔍 ProfileReview.fromJson - Checking userID: ${json['userID']}', tag: 'ProfileReview');
      Logger.debug('🔍 ProfileReview.fromJson - Checking userId: ${json['userId']}', tag: 'ProfileReview');
      Logger.debug('🔍 ProfileReview.fromJson - Checking fromUserID: ${json['fromUserID']}', tag: 'ProfileReview');
      Logger.debug('🔍 ProfileReview.fromJson - Checking reviewerUserID: ${json['reviewerUserID']}', tag: 'ProfileReview');
      
      final dynamic reviewerIdRaw = json['revieweeID'] ?? json['reviewerID'] ?? json['userID'] ?? json['userId'] ?? json['fromUserID'] ?? json['reviewerUserID'] ?? json['revieweeUserID'] ?? json['user_id'] ?? json['reviewer_id'] ?? json['reviewee_id'] ?? json['from_user_id'] ?? json['fromUserId'] ?? json['reviewerId'] ?? json['revieweeId'];
      if (reviewerIdRaw is int) {
        reviewerUserID = reviewerIdRaw;
      } else if (reviewerIdRaw is String) {
        reviewerUserID = int.tryParse(reviewerIdRaw);
      }
      
      Logger.debug('🔍 ProfileReview.fromJson - Final reviewerUserID: $reviewerUserID (from raw: $reviewerIdRaw)', tag: 'ProfileReview');
      final rating = json['rating'] ?? 0;
      final comment = json['comment'] ?? '';
      final reviewDate = json['reviewDate'] ?? json['date'] ?? '';
      
      // Reviewer name için farklı field isimlerini kontrol et
      String reviewerName = '';
      if (json['revieweeName'] != null && json['revieweeName'].toString().isNotEmpty && json['revieweeName'].toString() != 'null') {
        reviewerName = json['revieweeName'].toString();
        Logger.debug('🔍 ProfileReview.fromJson - Using revieweeName: $reviewerName', tag: 'ProfileReview');
      } else if (json['reviewerName'] != null && json['reviewerName'].toString().isNotEmpty && json['reviewerName'].toString() != 'null') {
        reviewerName = json['reviewerName'].toString();
        Logger.debug('🔍 ProfileReview.fromJson - Using reviewerName: $reviewerName', tag: 'ProfileReview');
      } else if (json['name'] != null && json['name'].toString().isNotEmpty && json['name'].toString() != 'null') {
        reviewerName = json['name'].toString();
        Logger.debug('🔍 ProfileReview.fromJson - Using name: $reviewerName', tag: 'ProfileReview');
      } else if (json['userName'] != null && json['userName'].toString().isNotEmpty && json['userName'].toString() != 'null') {
        reviewerName = json['userName'].toString();
        Logger.debug('🔍 ProfileReview.fromJson - Using userName: $reviewerName', tag: 'ProfileReview');
      } else {
        Logger.warning('⚠️ ProfileReview.fromJson - No valid reviewer name found', tag: 'ProfileReview');
        reviewerName = 'Kullanıcı';
      }
      
             // Reviewer image için farklı field isimlerini kontrol et
       String? reviewerImage;
       if (json['revieweeImage'] != null && json['revieweeImage'].toString().isNotEmpty && json['revieweeImage'].toString() != 'null') {
         reviewerImage = json['revieweeImage'].toString();
         Logger.debug('🔍 ProfileReview.fromJson - Using revieweeImage: $reviewerImage', tag: 'ProfileReview');
       } else if (json['reviewerImage'] != null && json['reviewerImage'].toString().isNotEmpty && json['reviewerImage'].toString() != 'null') {
         reviewerImage = json['reviewerImage'].toString();
         Logger.debug('🔍 ProfileReview.fromJson - Using reviewerImage: $reviewerImage', tag: 'ProfileReview');
       } else if (json['image'] != null && json['image'].toString().isNotEmpty && json['image'].toString() != 'null') {
         reviewerImage = json['image'].toString();
         Logger.debug('🔍 ProfileReview.fromJson - Using image: $reviewerImage', tag: 'ProfileReview');
       } else if (json['avatar'] != null && json['avatar'].toString().isNotEmpty && json['avatar'].toString() != 'null') {
         reviewerImage = json['avatar'].toString();
         Logger.debug('🔍 ProfileReview.fromJson - Using avatar: $reviewerImage', tag: 'ProfileReview');
       }

       // Reviewee name için - kim için yorum yapıldı
       String? revieweeName;
       if (json['revieweeName'] != null && json['revieweeName'].toString().isNotEmpty && json['revieweeName'].toString() != 'null') {
         revieweeName = json['revieweeName'].toString();
         Logger.debug('🔍 ProfileReview.fromJson - Using revieweeName: $revieweeName', tag: 'ProfileReview');
       } else if (json['toUserName'] != null && json['toUserName'].toString().isNotEmpty && json['toUserName'].toString() != 'null') {
         revieweeName = json['toUserName'].toString();
         Logger.debug('🔍 ProfileReview.fromJson - Using toUserName: $revieweeName', tag: 'ProfileReview');
       } else if (json['targetUserName'] != null && json['targetUserName'].toString().isNotEmpty && json['targetUserName'].toString() != 'null') {
         revieweeName = json['targetUserName'].toString();
         Logger.debug('🔍 ProfileReview.fromJson - Using targetUserName: $revieweeName', tag: 'ProfileReview');
       }
       
       final result = ProfileReview(
         reviewID: reviewID,
         reviewerUserID: reviewerUserID,
         reviewerName: reviewerName,
         reviewerImage: reviewerImage,
         revieweeName: revieweeName,
         rating: rating,
         comment: comment,
         reviewDate: reviewDate,
       );
      
      Logger.debug('🔍 ProfileReview.fromJson - Parsed successfully: ID=${result.reviewID}, Name="${result.reviewerName}", Rating=${result.rating}, Comment="${result.comment}"', tag: 'ProfileReview');
      
      return result;
    } catch (e) {
      Logger.error('⚠️ ProfileReview.fromJson - Parse error: $e', tag: 'ProfileReview');
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
     int? reviewerUserID,
     String? reviewerName,
     String? reviewerImage,
     String? revieweeName,
     int? rating,
     String? comment,
     String? reviewDate,
   }) {
     return ProfileReview(
       reviewID: reviewID ?? this.reviewID,
       reviewerUserID: reviewerUserID ?? this.reviewerUserID,
       reviewerName: reviewerName ?? this.reviewerName,
       reviewerImage: reviewerImage ?? this.reviewerImage,
       revieweeName: revieweeName ?? this.revieweeName,
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