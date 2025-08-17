import 'package:flutter/material.dart';
import '../models/user_profile_detail.dart';
import '../services/user_service.dart';
import '../utils/logger.dart';

class UserProfileDetailViewModel extends ChangeNotifier {
  final UserService _userService = UserService();
  static const String _tag = 'UserProfileDetailViewModel';

  // State variables
  UserProfileDetail? _profileDetail;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  String? _userToken;

  // Getters
  UserProfileDetail? get profileDetail => _profileDetail;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  bool get hasData => _profileDetail != null;

  /// Profil detaylarını yükler
  /// userToken artık opsiyonel - backend'de token zorunluluğu kaldırıldı
  Future<void> loadProfileDetail({
    String? userToken,
    required int userId,
  }) async {
    try {
      Logger.debug('🔄 Loading profile detail for user ID: $userId', tag: _tag);
      Logger.debug('🔑 User token: ${userToken != null ? "${userToken.substring(0, 20)}..." : "null"}', tag: _tag);
      
      _setLoading(true);
      _clearError();

      final response = await _userService.getUserProfileDetail(
        userToken: userToken,
        userId: userId,
      );

      if (response.isSuccess && response.data != null) {
        _profileDetail = response.data;
        Logger.debug('✅ Profile detail loaded successfully', tag: _tag);
        Logger.debug('📊 User: ${_profileDetail!.userFullname}, Rating: ${_profileDetail!.averageRating}', tag: _tag);
        Logger.debug('📊 MyReviews count: ${_profileDetail!.myReviews.length}', tag: _tag);
        Logger.debug('📊 Reviews count: ${_profileDetail!.reviews.length}', tag: _tag);
        Logger.debug('📊 Products count: ${_profileDetail!.products.length}', tag: _tag);
      } else {
        _setError(response.error ?? 'Profil detayları yüklenemedi');
        Logger.error('❌ Failed to load profile detail: ${response.error}', tag: _tag);
      }
    } catch (e) {
      _setError('Beklenmeyen bir hata oluştu: $e');
      Logger.error('❌ Exception while loading profile detail: $e', tag: _tag);
    } finally {
      _setLoading(false);
    }
  }

  /// Profil detaylarını yeniler
  Future<void> refreshProfileDetail({
    String? userToken,
    required int userId,
  }) async {
    Logger.debug('🔄 Refreshing profile detail', tag: _tag);
    await loadProfileDetail(userToken: userToken, userId: userId);
  }

  /// Profil detaylarını temizler
  void clearProfileDetail() {
    Logger.debug('🧹 Clearing profile detail', tag: _tag);
    _profileDetail = null;
    _clearError();
    notifyListeners();
  }

  /// Loading state'ini ayarlar
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Error state'ini ayarlar
  void _setError(String message) {
    _hasError = true;
    _errorMessage = message;
    notifyListeners();
  }

  /// Error state'ini temizler
  void _clearError() {
    _hasError = false;
    _errorMessage = '';
  }

  /// User token'ı kaydeder
  void setUserToken(String token) {
    _userToken = token;
  }

  /// User token'ı alır
  String? get userToken => _userToken;

  /// Ortalama rating'i formatlar
  String get formattedAverageRating {
    if (_profileDetail == null) return '0.0';
    return _profileDetail!.averageRating.toStringAsFixed(1);
  }

  /// Toplam yorum sayısını formatlar
  String get formattedTotalReviews {
    if (_profileDetail == null) return '0';
    return _profileDetail!.totalReviews.toString();
  }

  /// Ürün sayısını formatlar
  String get formattedProductCount {
    if (_profileDetail == null) return '0';
    return _profileDetail!.products.length.toString();
  }

  /// Yorum sayısını formatlar
  String get formattedReviewCount {
    if (_profileDetail == null) return '0';
    return _profileDetail!.reviews.length.toString();
  }

  /// Kendi yorum sayısını formatlar
  String get formattedMyReviewCount {
    if (_profileDetail == null) return '0';
    return _profileDetail!.myReviews.length.toString();
  }

  /// Ürünlerin favori olup olmadığını kontrol eder
  bool isProductFavorite(int productId) {
    if (_profileDetail == null) return false;
    final product = _profileDetail!.products.firstWhere(
      (p) => p.productID == productId,
      orElse: () => ProfileProduct(
        productID: 0,
        title: '',
        isFavorite: false,
      ),
    );
    return product.isFavorite;
  }

  /// Belirli bir ürünü alır
  ProfileProduct? getProductById(int productId) {
    if (_profileDetail == null) return null;
    try {
      return _profileDetail!.products.firstWhere(
        (p) => p.productID == productId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Belirli bir yorumu alır
  ProfileReview? getReviewById(int reviewId) {
    if (_profileDetail == null) return null;
    try {
      return _profileDetail!.reviews.firstWhere(
        (r) => r.reviewID == reviewId,
      );
    } catch (e) {
      return null;
    }
  }

  /// En son yorumları alır (limit ile)
  List<ProfileReview> getRecentReviews({int limit = 5}) {
    if (_profileDetail == null) return [];
    
    final sortedReviews = List<ProfileReview>.from(_profileDetail!.reviews);
    sortedReviews.sort((a, b) => b.reviewDate.compareTo(a.reviewDate));
    
    if (sortedReviews.length <= limit) {
      return sortedReviews;
    }
    
    return sortedReviews.take(limit).toList();
  }

  /// En son kendi yorumlarını alır (limit ile)
  List<ProfileReview> getRecentMyReviews({int limit = 5}) {
    if (_profileDetail == null) return [];
    
    final sortedMyReviews = List<ProfileReview>.from(_profileDetail!.myReviews);
    sortedMyReviews.sort((a, b) => b.reviewDate.compareTo(a.reviewDate));
    
    if (sortedMyReviews.length <= limit) {
      return sortedMyReviews;
    }
    
    return sortedMyReviews.take(limit).toList();
  }

  /// Belirli bir kendi yorumunu alır
  ProfileReview? getMyReviewById(int reviewId) {
    if (_profileDetail == null) return null;
    try {
      return _profileDetail!.myReviews.firstWhere(
        (r) => r.reviewID == reviewId,
      );
    } catch (e) {
      return null;
    }
  }

  /// En popüler ürünleri alır (limit ile)
  List<ProfileProduct> getPopularProducts({int limit = 5}) {
    if (_profileDetail == null) return [];
    
    final products = List<ProfileProduct>.from(_profileDetail!.products);
    
    if (products.length <= limit) {
      return products;
    }
    
    return products.take(limit).toList();
  }

  @override
  void dispose() {
    Logger.debug('🗑️ Disposing UserProfileDetailViewModel', tag: _tag);
    super.dispose();
  }
} 