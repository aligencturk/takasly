import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../core/constants.dart';

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
        print('✅ UserViewModel - Local user loaded: ${user.name}');
      } else {
        print('⚠️ UserViewModel - No local user, checking token...');
        final token = await _userService.getUserToken();
        if (token != null && token.isNotEmpty) {
          print('🔑 UserViewModel - Token found, fetching from API');
          await refreshUser();
        } else {
          print('❌ UserViewModel - No token found, user needs to login');
        }
      }
    } catch (e) {
      print('❌ UserViewModel - Initialize error: $e');
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
      print('🔄 UserViewModel.forceRefreshUser - Starting...');
      
      // Önce local storage'daki mevcut kullanıcıyı kontrol et
      final localUser = await _userService.getCurrentUser();
      if (localUser != null) {
        print('📱 UserViewModel - Found local user: ${localUser.name} (ID: ${localUser.id})');
        print('📱 UserViewModel - Local user details: firstName=${localUser.firstName}, lastName=${localUser.lastName}');
      } else {
        print('📱 UserViewModel - No local user found');
      }
      
      final success = await getUserProfile();
      if (success) {
        print('✅ UserViewModel - User refreshed successfully');
        print('✅ UserViewModel - Current user: ${_currentUser?.name} (ID: ${_currentUser?.id})');
        print('✅ UserViewModel - User details: firstName=${_currentUser?.firstName}, lastName=${_currentUser?.lastName}');
      } else {
        print('❌ UserViewModel - Failed to refresh user');
      }
    } catch (e) {
      print('❌ UserViewModel - Force refresh error: $e');
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);
    }
  }

  /// Kullanıcı profilini günceller
  Future<bool> updateUserProfile({
    String? platform,
    String? version,
  }) async {
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
  }) async {
    final token = await _userService.getUserToken();
    if (token == null) {
      _setError(ErrorMessages.sessionExpired);
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _userService.updateAccount(
        userToken: token,
        userFirstname: userFirstname,
        userLastname: userLastname,
        userEmail: userEmail,
        userPhone: userPhone,
        userBirthday: userBirthday,
        userGender: userGender,
        profilePhoto: profilePhoto,
      );
      
      if (response.isSuccess && response.data != null) {
        _currentUser = response.data;
        await _userService.saveCurrentUser(response.data!);
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

  /// Kullanıcı profilini alır
  Future<bool> getUserProfile({
    String? platform,
    String? version,
  }) async {
    final token = await _userService.getUserToken();
    if (token == null) {
      print('❌ UserViewModel.getUserProfile - No token found');
      _setError(ErrorMessages.sessionExpired);
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      print('🔄 UserViewModel.getUserProfile - Calling API with token: ${token.substring(0, 20)}...');
      
      final response = await _userService.getUserProfile(
        userToken: token,
        platform: platform,
        version: version,
      );
      
      print('📡 UserViewModel.getUserProfile - API response received');
      print('📡 Response isSuccess: ${response.isSuccess}');
      print('📡 Response error: ${response.error}');
      
      if (response.isSuccess && response.data != null) {
        print('✅ UserViewModel.getUserProfile - API returned user data');
        print('✅ User data: name=${response.data!.name}, firstName=${response.data!.firstName}, lastName=${response.data!.lastName}');
        print('✅ User data: email=${response.data!.email}, phone=${response.data!.phone}');
        
        _currentUser = response.data;
        await _userService.saveCurrentUser(response.data!);
        _setLoading(false);
        return true;
      } else {
        print('❌ UserViewModel.getUserProfile - API failed or returned null');
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
  Future<bool> deleteUserAccount({
    required String password,
  }) async {
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
        print('✅ User data: name=${response.data!.name}, id=${response.data!.id}');
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