import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/blocked_user.dart';
import '../services/user_service.dart';
import '../core/constants.dart';
import '../services/error_handler_service.dart';
import '../utils/logger.dart';

class UserViewModel extends ChangeNotifier {
  final UserService _userService = UserService();

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isLoggedIn => _currentUser != null;

  UserViewModel() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    _setLoading(true);
    try {
      final user = await _userService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        Logger.info('Local user loaded: ${user.name}', tag: 'UserViewModel');
      } else {
        Logger.warning(
          'No local user, checking token...',
          tag: 'UserViewModel',
        );
        final token = await _userService.getUserToken();
        if (token != null && token.isNotEmpty) {
          Logger.debug('Token found, fetching from API', tag: 'UserViewModel');
          await refreshUser();
        } else {
          Logger.error(
            'No token found, user needs to login',
            tag: 'UserViewModel',
          );
        }
      }
    } catch (e) {
      Logger.error('Initialize error: $e', tag: 'UserViewModel');
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);
    }
  }

  /// Kullanıcı bilgilerini zorla yeniler (local storage boşsa API'den çeker)
  Future<void> forceRefreshUser() async {
    _setLoading(true);
    _clearError();

    try {
      Logger.debug('forceRefreshUser - Starting...', tag: 'UserViewModel');

      // Önce local storage'daki mevcut kullanıcıyı kontrol et
      final localUser = await _userService.getCurrentUser();
      if (localUser != null) {
        Logger.debug(
          'Found local user: ${localUser.name} (ID: ${localUser.id})',
          tag: 'UserViewModel',
        );
        Logger.debug(
          'Local user details: firstName=${localUser.firstName}, lastName=${localUser.lastName}',
          tag: 'UserViewModel',
        );
      } else {
        Logger.debug('No local user found', tag: 'UserViewModel');
      }

      final success = await getUserProfile();
      if (success) {
        Logger.info('User refreshed successfully', tag: 'UserViewModel');
        Logger.debug(
          'Current user: ${_currentUser?.name} (ID: ${_currentUser?.id})',
          tag: 'UserViewModel',
        );
        Logger.debug(
          'User details: firstName=${_currentUser?.firstName}, lastName=${_currentUser?.lastName}',
          tag: 'UserViewModel',
        );
        Logger.debug(
          'User isVerified: ${_currentUser?.isVerified}',
          tag: 'UserViewModel',
        );
      } else {
        Logger.error('Failed to refresh user', tag: 'UserViewModel');
      }
    } catch (e) {
      Logger.error('Force refresh error: $e', tag: 'UserViewModel');
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);
    }
  }

  /// Kullanıcı profilini günceller
  Future<bool> updateUserProfile({String? platform, String? version}) async {
    final token = await _userService.getUserToken();
    if (token == null) {
      _setError(ErrorMessages.sessionExpired);
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _userService.updateUserProfile(
        userToken: token,
        platform: platform,
        version: version,
      );

      if (response.isSuccess && response.data != null) {
        _currentUser = response.data;
        await _userService.saveCurrentUser(response.data!);
        _setLoading(false);
        return true;
      } else {
        // 403 hatası kontrolü
        if (response.error != null &&
            (response.error!.contains('403') ||
                response.error!.contains('Erişim reddedildi') ||
                response.error!.contains('Hesabınızın süresi doldu'))) {
          print(
            '🚨 403 error detected in UserViewModel.updateUserProfile - triggering global error handler',
          );
          ErrorHandlerService.handleForbiddenError(null);
        }

        _setError(response.error ?? ErrorMessages.unknownError);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return false;
    }
  }

  /// Kullanıcı hesap bilgilerini günceller
  Future<bool> updateAccount({
    String? userFirstname,
    String? userLastname,
    String? userEmail,
    String? userPhone,
    String? userBirthday,
    int? userGender,
    String? profilePhoto,
    bool? isShowContact,
  }) async {
    Logger.debug('updateAccount called with:', tag: 'UserViewModel');
    Logger.debug('userFirstname: $userFirstname', tag: 'UserViewModel');
    Logger.debug('userLastname: $userLastname', tag: 'UserViewModel');
    Logger.debug('userEmail: $userEmail', tag: 'UserViewModel');
    Logger.debug('userPhone: $userPhone', tag: 'UserViewModel');
    Logger.debug('userBirthday: $userBirthday', tag: 'UserViewModel');
    Logger.debug('userGender: $userGender', tag: 'UserViewModel');
    Logger.debug('isShowContact: $isShowContact', tag: 'UserViewModel');
    Logger.debug(
      'profilePhoto: ${profilePhoto != null ? "provided" : "null"}',
      tag: 'UserViewModel',
    );

    final token = await _userService.getUserToken();
    if (token == null) {
      Logger.error('No token found for updateAccount', tag: 'UserViewModel');
      _setError(ErrorMessages.sessionExpired);
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      Logger.debug(
        'Calling _userService.updateAccount...',
        tag: 'UserViewModel',
      );
      final response = await _userService.updateAccount(
        userToken: token,
        userFirstname: userFirstname,
        userLastname: userLastname,
        userEmail: userEmail,
        userPhone: userPhone,
        userBirthday: userBirthday,
        userGender: userGender,
        profilePhoto: profilePhoto,
        isShowContact: isShowContact,
      );

      Logger.debug('updateAccount response received:', tag: 'UserViewModel');
      Logger.debug('isSuccess: ${response.isSuccess}', tag: 'UserViewModel');
      Logger.debug('error: ${response.error}', tag: 'UserViewModel');
      Logger.debug(
        'data: ${response.data != null ? "present" : "null"}',
        tag: 'UserViewModel',
      );

      if (response.isSuccess && response.data != null) {
        Logger.info('Account updated successfully', tag: 'UserViewModel');
        _currentUser = response.data;
        await _userService.saveCurrentUser(response.data!);
        _setLoading(false);
        return true;
      } else {
        Logger.error(
          'Account update failed: ${response.error}',
          tag: 'UserViewModel',
        );
        _setError(response.error ?? ErrorMessages.unknownError);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      Logger.error('updateAccount exception: $e', tag: 'UserViewModel');
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return false;
    }
  }

  /// Kullanıcı profilini alır
  Future<bool> getUserProfile({String? platform, String? version}) async {
    final token = await _userService.getUserToken();
    if (token == null) {
      Logger.error('getUserProfile - No token found', tag: 'UserViewModel');
      _setError(ErrorMessages.sessionExpired);
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      Logger.debug(
        'getUserProfile - Calling API with token: ${token.substring(0, 20)}...',
        tag: 'UserViewModel',
      );

      final response = await _userService.getUserProfile(
        userToken: token,
        platform: platform,
        version: version,
      );

      Logger.debug(
        'getUserProfile - API response received',
        tag: 'UserViewModel',
      );
      Logger.debug(
        'Response isSuccess: ${response.isSuccess}',
        tag: 'UserViewModel',
      );
      Logger.debug('Response error: ${response.error}', tag: 'UserViewModel');

      if (response.isSuccess && response.data != null) {
        Logger.info(
          'getUserProfile - API returned user data',
          tag: 'UserViewModel',
        );
        Logger.debug(
          'User data: name=${response.data!.name}, firstName=${response.data!.firstName}, lastName=${response.data!.lastName}',
          tag: 'UserViewModel',
        );
        Logger.debug(
          'User data: email=${response.data!.email}, phone=${response.data!.phone}',
          tag: 'UserViewModel',
        );

        _currentUser = response.data;
        await _userService.saveCurrentUser(response.data!);
        _setLoading(false);
        return true;
      } else {
        Logger.error(
          'getUserProfile - API failed or returned null',
          tag: 'UserViewModel',
        );

        // 403 hatası kontrolü
        if (response.error != null &&
            (response.error!.contains('403') ||
                response.error!.contains('Erişim reddedildi') ||
                response.error!.contains('Hesabınızın süresi doldu'))) {
          Logger.warning(
            '403 error detected in getUserProfile - triggering global error handler',
            tag: 'UserViewModel',
          );
          ErrorHandlerService.handleForbiddenError(null);
        }

        _setError(response.error ?? ErrorMessages.unknownError);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('❌ UserViewModel.getUserProfile - Exception: $e');
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return false;
    }
  }

  /// Kullanıcı verisini yeniler
  Future<bool> refreshUser() async {
    return await getUserProfile();
  }

  /// Kullanıcı çıkış işlemi
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _userService.clearCurrentUser();
      await _userService.clearUserToken();
      _currentUser = null;
      _clearError();
    } catch (e) {
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);
    }
  }

  /// Kullanıcı giriş yapmış mı kontrol eder
  Future<bool> checkLoginStatus() async {
    return await _userService.isLoggedIn();
  }

  /// Kullanıcı şifresini günceller
  Future<bool> updateUserPassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = await _userService.getUserToken();
    if (token == null) {
      _setError(ErrorMessages.sessionExpired);
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _userService.updateUserPassword(
        userToken: token,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      if (response.isSuccess) {
        _setLoading(false);
        return true;
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return false;
    }
  }

  /// Kullanıcı hesabını siler (eski endpoint)
  Future<bool> deleteUserAccount({required String password}) async {
    final token = await _userService.getUserToken();
    if (token == null) {
      _setError(ErrorMessages.sessionExpired);
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _userService.deleteUserAccount(
        userToken: token,
        password: password,
      );

      if (response.isSuccess) {
        // Hesap silindikten sonra tüm local data'yı temizle
        await logout();
        _setLoading(false);
        return true;
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return false;
    }
  }

  /// Kullanıcı hesabını siler (yeni endpoint)
  Future<bool> deleteUserAccountNew() async {
    final token = await _userService.getUserToken();
    if (token == null) {
      _setError(ErrorMessages.sessionExpired);
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _userService.deleteUserAccountNew(
        userToken: token,
      );

      if (response.isSuccess && response.data == true) {
        // Hesap silindikten sonra tüm local data'yı temizle
        await logout();
        _setLoading(false);
        return true;
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return false;
    }
  }

  /// User service'ini test eder
  Future<bool> testUserService() async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _userService.testUserService();
      if (success) {
        _setLoading(false);
        return true;
      } else {
        _setError('User service test failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return false;
    }
  }

  /// Kullanıcı bilgilerini manuel olarak ayarlar
  void setCurrentUser(User user) {
    print('👤 UserViewModel: Setting current user: ${user.email}');
    try {
      _currentUser = user;
      print('👤 UserViewModel: User object set in memory');
      _userService.saveCurrentUser(user);
      print('👤 UserViewModel: User saved to local storage');
      notifyListeners();
      print('👤 UserViewModel: Listeners notified');
    } catch (e, stackTrace) {
      print('❌ UserViewModel: Error in setCurrentUser: $e');
      print('❌ UserViewModel: Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Kullanıcı token'ını ayarlar
  Future<void> setUserToken(String token) async {
    await _userService.saveUserToken(token);
  }

  /// Kullanıcı token'ını alır
  Future<String?> getUserToken() async {
    return await _userService.getUserToken();
  }

  /// Platform bilgisini alır
  String getPlatform() {
    return _userService.getPlatform();
  }

  /// Kullanıcı bilgilerini ID ile alır
  /// GET /service/user/id
  Future<User?> getUserById(String userId) async {
    print('🔍 UserViewModel.getUserById called with userId: $userId');
    _setLoading(true);
    _clearError();

    try {
      final response = await _userService.getUserById(userId);

      print('📡 UserViewModel.getUserById - API response received');
      print('📡 Response isSuccess: ${response.isSuccess}');
      print('📡 Response error: ${response.error}');

      if (response.isSuccess && response.data != null) {
        print('✅ UserViewModel.getUserById - API returned user data');
        print(
          '✅ User data: name=${response.data!.name}, id=${response.data!.id}',
        );
        print('✅ User data: email=${response.data!.email}');

        _setLoading(false);
        return response.data;
      } else {
        print('❌ UserViewModel.getUserById - API failed or returned null');
        _setError(response.error ?? ErrorMessages.userNotFound);
        _setLoading(false);
        return null;
      }
    } catch (e) {
      print('❌ UserViewModel.getUserById - Exception: $e');
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return null;
    }
  }

  /// Kullanıcıyı engeller
  Future<bool> blockUser({required int blockedUserID, String? reason}) async {
    final token = await _userService.getUserToken();
    if (token == null) {
      _setError(ErrorMessages.sessionExpired);
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      Logger.debug('Blocking user: $blockedUserID', tag: 'UserViewModel');

      final response = await _userService.blockUser(
        userToken: token,
        blockedUserID: blockedUserID,
        reason: reason,
      );

      if (response.isSuccess && response.data != null) {
        Logger.info(
          'User blocked successfully: ${response.data!.message}',
          tag: 'UserViewModel',
        );
        _setLoading(false);
        return true;
      } else {
        Logger.error(
          'Failed to block user: ${response.error}',
          tag: 'UserViewModel',
        );
        _setError(response.error ?? ErrorMessages.unknownError);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      Logger.error('Block user error: $e', tag: 'UserViewModel');
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return false;
    }
  }

  /// Kullanıcı engelini kaldırır
  Future<bool> unblockUser({required int blockedUserID}) async {
    final token = await _userService.getUserToken();
    if (token == null) {
      _setError(ErrorMessages.sessionExpired);
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      Logger.debug('Unblocking user: $blockedUserID', tag: 'UserViewModel');

      final response = await _userService.unblockUser(
        userToken: token,
        blockedUserID: blockedUserID,
      );

      if (response.isSuccess && response.data != null) {
        Logger.info(
          'User unblocked successfully: ${response.data!.message}',
          tag: 'UserViewModel',
        );
        _setLoading(false);
        return true;
      } else {
        Logger.error(
          'Failed to unblock user: ${response.error}',
          tag: 'UserViewModel',
        );
        _setError(response.error ?? ErrorMessages.unknownError);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      Logger.error('Unblock user error: $e', tag: 'UserViewModel');
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return false;
    }
  }

  /// Engellenen kullanıcıları getirir
  Future<List<BlockedUser>?> getBlockedUsers() async {
    final token = await _userService.getUserToken();
    if (token == null) {
      _setError(ErrorMessages.sessionExpired);
      return null;
    }

    // Mevcut kullanıcının ID'sini al
    final currentUser = await _userService.getCurrentUser();
    if (currentUser == null) {
      Logger.warning('No current user found', tag: 'UserViewModel');
      _setError('Kullanıcı bilgisi bulunamadı');
      return null;
    }

    final userId = int.tryParse(currentUser.id);
    if (userId == null) {
      Logger.warning(
        'Invalid user ID: ${currentUser.id}',
        tag: 'UserViewModel',
      );
      _setError('Geçersiz kullanıcı ID');
      return null;
    }

    _setLoading(true);
    _clearError();

    try {
      Logger.debug(
        'Getting blocked users for user ID: $userId',
        tag: 'UserViewModel',
      );

      final response = await _userService.getBlockedUsers(
        userToken: token,
        userId: userId,
      );

      if (response.isSuccess && response.data != null) {
        Logger.info(
          'Blocked users retrieved successfully: ${response.data!.length} users',
          tag: 'UserViewModel',
        );
        _setLoading(false);
        return response.data;
      } else {
        Logger.error(
          'Failed to get blocked users: ${response.error}',
          tag: 'UserViewModel',
        );
        _setError(response.error ?? ErrorMessages.unknownError);
        _setLoading(false);
        return null;
      }
    } catch (e) {
      Logger.error('Get blocked users error: $e', tag: 'UserViewModel');
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return null;
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
