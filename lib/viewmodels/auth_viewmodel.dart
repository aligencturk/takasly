import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/firebase_chat_service.dart';
import '../core/constants.dart';
import 'product_viewmodel.dart';
import '../utils/logger.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseChatService _firebaseChatService = FirebaseChatService();
  ProductViewModel? _productViewModel;

  User? _currentUser;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;
  bool _isInitialized = false; // Hot reload kontrolü için
  bool _isHotRestart = false; // Hot restart kontrolü için

  // ProductViewModel referansını ayarla
  void setProductViewModel(ProductViewModel productViewModel) {
    _productViewModel = productViewModel;
  }

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn && _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isInitialized => _isInitialized;

  // Async login durumu kontrolü
  Future<bool> get isLoggedInAsync async {
    // Sadece hot restart durumunda otomatik giriş yap
    if (!_isInitialized && _isHotRestart) {
      await _initializeAuth();
    }
    // Daha güvenli kontrol: Hem isLoggedIn hem de currentUser kontrolü
    return _isLoggedIn && _currentUser != null && _currentUser!.id.isNotEmpty;
  }

  AuthViewModel() {
    Logger.info('🚀 AuthViewModel constructor called');
    // Constructor'da hiç otomatik giriş yapma
    // Sadece manuel olarak çağrıldığında giriş yap
    _isLoggedIn = false;
    _isInitialized = false;
  }

  Future<void> _initializeAuth() async {
    if (_isInitialized) {
      Logger.info('🔄 AuthViewModel already initialized, skipping...');
      return;
    }

    Logger.info('🔐 AuthViewModel initializing authentication for hot reload...');
    _setLoading(true);
    
    try {
      // Hızlı kontrol - SharedPreferences'dan direkt oku
      _isLoggedIn = await _authService.isLoggedIn();
      Logger.info('🔍 Quick login check result: $_isLoggedIn');
      
      if (_isLoggedIn) {
        Logger.info('✅ User is logged in, fetching current user data...');
        _currentUser = await _authService.getCurrentUser();
        
        if (_currentUser != null && _currentUser!.id.isNotEmpty && _currentUser!.id != '0') {
          Logger.info('✅ Current user loaded: ${_currentUser!.name} (${_currentUser!.id})');
          
          // Firebase'e kullanıcıyı kaydet (hot reload için)
          try {
            await _firebaseChatService.saveUser(_currentUser!);
            Logger.info('✅ User saved to Firebase for hot reload');
          } catch (e) {
            Logger.warning('⚠️ Firebase save error during hot reload: $e');
          }
        } else {
          Logger.warning('⚠️ User is logged in but current user data is null, empty ID, or ID is 0');
          _isLoggedIn = false;
          _currentUser = null;
          
          // Geçersiz verileri temizle
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(AppConstants.userTokenKey);
            await prefs.remove(AppConstants.userIdKey);
            await prefs.remove(AppConstants.userDataKey);
            Logger.info('✅ Invalid user data cleared');
          } catch (e) {
            Logger.error('❌ Error clearing invalid user data: $e', error: e);
          }
        }
      } else {
        Logger.info('❌ User is not logged in');
        _currentUser = null;
      }
      
      _isInitialized = true;
      Logger.info('✅ AuthViewModel initialization completed for hot reload');
    } catch (e) {
      Logger.error('❌ AuthViewModel initialization error: $e', error: e);
      _setError(ErrorMessages.unknownError);
      _isLoggedIn = false;
      _currentUser = null;
    } finally {
      _setLoading(false);
    }
  }

  // Hot reload için manuel yeniden başlatma
  Future<void> reinitializeForHotReload() async {
    Logger.info('🔄 Reinitializing AuthViewModel for hot reload...');
    _isInitialized = false;
    await _initializeAuth();
  }

  // Hot restart için otomatik giriş yap
  Future<void> enableHotRestartAutoLogin() async {
    Logger.info('🔄 Enabling hot restart auto-login...');
    _isHotRestart = true;
    if (!_isInitialized) {
      await _initializeAuth();
    }
  }

  // Hot reload durumunu kontrol et ve gerekirse yeniden başlat
  Future<void> checkHotReloadState() async {
    Logger.info('🔄 Checking hot reload state...');
    
    // Sadece hot restart durumunda otomatik giriş yap
    if (!_isInitialized && _isHotRestart) {
      Logger.info('🔄 Hot restart detected, running initialization...');
      await _initializeAuth();
      return;
    }
    
    // Eğer initialized ama user data yoksa ve hot restart ise, yeniden kontrol et
    if (_isInitialized && _currentUser == null && _isLoggedIn && _isHotRestart) {
      Logger.warning('⚠️ Hot restart: Initialized but no user data, rechecking...');
      _isInitialized = false;
      await _initializeAuth();
      return;
    }
    
    Logger.info('✅ Hot reload state check completed - User: ${_currentUser?.name ?? 'None'}, LoggedIn: $_isLoggedIn, HotRestart: $_isHotRestart');
  }

  Future<bool> login(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      _setError(ErrorMessages.fieldRequired);
      return false;
    }

    if (!_isValidEmail(email)) {
      _setError(ErrorMessages.invalidEmail);
      return false;
    }

    _setLoading(true);
    _clearError();

    // Önce eski kullanıcı verilerini temizle
    _currentUser = null;
    _isLoggedIn = false;
    
    // Ürün verilerini de temizle (kullanıcı değişikliği)
    _productViewModel?.clearAllProductData();

    try {
      final response = await _authService.login(email, password);

      if (response.isSuccess && response.data != null) {
        _currentUser = response.data;
        _isLoggedIn = true;
        
        // Firebase'e kullanıcıyı kaydet
        try {
          await _firebaseChatService.saveUser(_currentUser!);
        } catch (e) {
          // Firebase kaydetme hatası kritik değil, devam et
          print('Firebase kullanıcı kaydetme hatası: $e');
        }
        
        _setLoading(false);
        notifyListeners(); // UI'ı güncelle
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

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required bool policy,
    required bool kvkk,
  }) async {
    Logger.debug('🚀 AuthViewModel.register başlatılıyor...', tag: 'AuthViewModel');
    Logger.debug('📝 Parametreler: firstName=$firstName, lastName=$lastName, email=$email, phone=$phone', tag: 'AuthViewModel');
    
    if (firstName.trim().isEmpty ||
        lastName.trim().isEmpty ||
        email.trim().isEmpty ||
        password.trim().isEmpty ||
        phone.trim().isEmpty) {
      Logger.warning('❌ Boş alan hatası', tag: 'AuthViewModel');
      _setError(ErrorMessages.fieldRequired);
      return false;
    }

    if (!_isValidEmail(email)) {
      Logger.warning('❌ Geçersiz email formatı: $email', tag: 'AuthViewModel');
      _setError(ErrorMessages.invalidEmail);
      return false;
    }

    if (firstName.length > AppConstants.maxUsernameLength) {
      Logger.warning('❌ İsim çok uzun: ${firstName.length}', tag: 'AuthViewModel');
      _setError('İsim çok uzun');
      return false;
    }

    if (lastName.length > AppConstants.maxUsernameLength) {
      Logger.warning('❌ Soyisim çok uzun: ${lastName.length}', tag: 'AuthViewModel');
      _setError('Soyisim çok uzun');
      return false;
    }

    if (!policy) {
      Logger.warning('❌ Gizlilik politikası kabul edilmedi', tag: 'AuthViewModel');
      _setError('Gizlilik politikasını kabul etmelisiniz');
      return false;
    }

    if (!kvkk) {
      Logger.warning('❌ KVKK metni kabul edilmedi', tag: 'AuthViewModel');
      _setError('KVKK metnini kabul etmelisiniz');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      Logger.debug('📡 AuthService.register çağrılıyor...', tag: 'AuthViewModel');
      
      final response = await _authService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone,
        policy: policy,
        kvkk: kvkk,
      );

      Logger.debug('📥 AuthService response alındı', tag: 'AuthViewModel');
      Logger.debug('📊 Response isSuccess: ${response.isSuccess}', tag: 'AuthViewModel');
      Logger.debug('📊 Response data: ${response.data}', tag: 'AuthViewModel');
      Logger.debug('📊 Response error: ${response.error}', tag: 'AuthViewModel');

      if (response.isSuccess && response.data != null) {
        Logger.info('✅ Register başarılı, user data alındı', tag: 'AuthViewModel');
        _currentUser = response.data;
        _isLoggedIn = true;
        _setLoading(false);
        return true;
      } else {
        Logger.error('❌ Register başarısız', tag: 'AuthViewModel');
        Logger.error('❌ Error message: ${response.error}', tag: 'AuthViewModel');
        _setError(response.error ?? ErrorMessages.unknownError);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      Logger.error('💥 Register exception: $e', tag: 'AuthViewModel', error: e);
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return false;
    }
  }

  Future<Map<String, dynamic>?> forgotPassword(String email) async {
    if (email.trim().isEmpty) {
      _setError(ErrorMessages.fieldRequired);
      return null;
    }

    if (!_isValidEmail(email)) {
      _setError(ErrorMessages.invalidEmail);
      return null;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.forgotPassword(email);

      if (response.isSuccess) {
        _setLoading(false);
        return response.data;
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
        _setLoading(false);
        return null;
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return null;
    }
  }

  Future<bool> checkEmailVerificationCode({
    required String code,
    required String codeToken,
  }) async {
    if (code.trim().isEmpty || codeToken.trim().isEmpty) {
      _setError(ErrorMessages.fieldRequired);
      return false;
    }

    if (code.length < 6) {
      _setError('Doğrulama kodu 6 haneli olmalıdır');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.checkEmailVerificationCode(
        code: code,
        codeToken: codeToken,
      );

      if (response.isSuccess) {
        // Kullanıcının isVerified durumunu güncelle
        if (_currentUser != null) {
          _currentUser = User(
            id: _currentUser!.id,
            name: _currentUser!.name,
            firstName: _currentUser!.firstName,
            lastName: _currentUser!.lastName,
            email: _currentUser!.email,
            phone: _currentUser!.phone,
            isVerified: true, // E-posta doğrulandı
            isOnline: _currentUser!.isOnline,
            createdAt: _currentUser!.createdAt,
            updatedAt: DateTime.now(),
            token: _currentUser!.token,
          );
          notifyListeners();
          Logger.info('✅ User verification status updated in ViewModel');
        }
        
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

  Future<Map<String, dynamic>?> resendEmailVerificationCode({required String email}) async {
    // Email validation
    if (email.trim().isEmpty) {
      _setError('E-posta adresi boş olamaz');
      return null;
    }

    // Email format validation
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      _setError('Geçersiz e-posta formatı');
      return null;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.resendEmailVerificationCode(
        email: email.trim(),
      );

      Logger.debug('📥 ResendEmailVerificationCode response: ${response.isSuccess}', tag: 'AuthViewModel');
      Logger.debug('📥 ResendEmailVerificationCode data: ${response.data}', tag: 'AuthViewModel');
      Logger.debug('📥 ResendEmailVerificationCode error: ${response.error}', tag: 'AuthViewModel');

      if (response.isSuccess) {
        _setLoading(false);
        return response.data;
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
        _setLoading(false);
        return null;
      }
    } catch (e) {
      Logger.error('💥 ResendEmailVerificationCode exception: $e', error: e);
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return null;
    }
  }

  Future<Map<String, dynamic>?> checkPasswordResetCode({
    required String code,
    required String email,
    required String codeToken,
  }) async {
    Logger.info('🔑 AuthViewModel.checkPasswordResetCode called');
    
    if (code.trim().isEmpty || email.trim().isEmpty || codeToken.trim().isEmpty) {
      _setError(ErrorMessages.fieldRequired);
      return null;
    }

    if (code.length < 4) {
      _setError('Doğrulama kodu en az 4 karakter olmalıdır');
      return null;
    }

    if (!_isValidEmail(email)) {
      _setError(ErrorMessages.invalidEmail);
      return null;
    }

    _setLoading(true);
    _clearError();

    try {
      Logger.debug('📤 AuthViewModel - Calling authService.checkPasswordResetCode');
      final response = await _authService.checkPasswordResetCode(
        code: code,
        email: email,
        codeToken: codeToken,
      );

      if (response.isSuccess) {
        Logger.info('✅ AuthViewModel - Password reset code verification successful');
        _setLoading(false);
        return response.data;
      } else {
        Logger.error('❌ AuthViewModel - Password reset code verification failed: ${response.error}');
        _setError(response.error ?? ErrorMessages.unknownError);
        _setLoading(false);
        return null;
      }
    } catch (e) {
      Logger.error('💥 AuthViewModel - Password reset code verification exception: $e', error: e);
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return null;
    }
  }

  Future<Map<String, dynamic>?> resendEmailVerificationCodeWithToken({required String userToken}) async {
    // Token validation
    if (userToken.trim().isEmpty) {
      _setError('Kullanıcı token\'ı boş olamaz');
      return null;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.resendEmailVerificationCodeWithToken(
        userToken: userToken.trim(),
      );

      Logger.debug('📥 ResendEmailVerificationCodeWithToken response: ${response.isSuccess}', tag: 'AuthViewModel');
      Logger.debug('📥 ResendEmailVerificationCodeWithToken data: ${response.data}', tag: 'AuthViewModel');
      Logger.debug('📥 ResendEmailVerificationCodeWithToken error: ${response.error}', tag: 'AuthViewModel');

      if (response.isSuccess) {
        _setLoading(false);
        return response.data;
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
        _setLoading(false);
        return null;
      }
    } catch (e) {
      Logger.error('💥 ResendEmailVerificationCodeWithToken exception: $e', error: e);
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return null;
    }
  }

  Future<bool> updatePassword({
    required String passToken,
    required String password,
    required String passwordAgain,
  }) async {
    Logger.info('🔒 AuthViewModel.updatePassword called with passToken');
    
    // updatePassword metodunu changePassword metoduna yönlendir
    return await changePassword(
      passToken: passToken,
      password: password,
      passwordAgain: passwordAgain,
    );
  }

  Future<bool> changePassword({
    required String passToken,
    required String password,
    required String passwordAgain,
  }) async {
    Logger.info('🔒 AuthViewModel.changePassword called with passToken');
    
    if (passToken.trim().isEmpty ||
        password.trim().isEmpty ||
        passwordAgain.trim().isEmpty) {
      _setError(ErrorMessages.fieldRequired);
      return false;
    }

    if (password != passwordAgain) {
      _setError('Şifreler eşleşmiyor');
      return false;
    }

    if (password.length < AppConstants.minPasswordLength) {
      _setError(ErrorMessages.weakPassword);
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      Logger.debug('📤 AuthViewModel - Calling authService.changePassword');
      final response = await _authService.changePassword(
        passToken: passToken,
        password: password,
        passwordAgain: passwordAgain,
      );

      if (response.isSuccess) {
        Logger.info('✅ AuthViewModel - Password change successful');
        _setLoading(false);
        return true;
      } else {
        Logger.error('❌ AuthViewModel - Password change failed: ${response.error}');
        _setError(response.error ?? ErrorMessages.unknownError);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      Logger.error('💥 AuthViewModel - Password change exception: $e', error: e);
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return false;
    }
  }

  // Direkt şifre değiştirme (e-posta doğrulaması olmadan)
  Future<bool> updateUserPassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordAgain,
  }) async {
    Logger.info('🔒 AuthViewModel.updateUserPassword called (direct)');
    
    if (currentPassword.trim().isEmpty ||
        newPassword.trim().isEmpty ||
        newPasswordAgain.trim().isEmpty) {
      _setError(ErrorMessages.fieldRequired);
      return false;
    }

    if (newPassword != newPasswordAgain) {
      _setError('Şifreler eşleşmiyor');
      return false;
    }

    if (newPassword.length < AppConstants.minPasswordLength) {
      _setError(ErrorMessages.weakPassword);
      return false;
    }

    if (currentPassword == newPassword) {
      _setError('Yeni şifre mevcut şifre ile aynı olamaz');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      Logger.debug('📤 AuthViewModel - Calling authService.updateUserPassword');
      final response = await _authService.updateUserPassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordAgain: newPasswordAgain,
      );

      if (response.isSuccess) {
        Logger.info('✅ AuthViewModel - User password update successful');
        _setLoading(false);
        return true;
      } else {
        Logger.error('❌ AuthViewModel - User password update failed: ${response.error}');
        _setError(response.error ?? ErrorMessages.unknownError);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      Logger.error('💥 AuthViewModel - User password update exception: $e', error: e);
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return false;
    }
  }



  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? bio,
    String? avatar,
  }) async {
    if (name != null && name.trim().isEmpty) {
      _setError(ErrorMessages.fieldRequired);
      return false;
    }

    if (name != null && name.length > AppConstants.maxUsernameLength) {
      _setError('İsim çok uzun');
      return false;
    }

    if (bio != null && bio.length > AppConstants.maxDescriptionLength) {
      _setError('Açıklama çok uzun');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.updateProfile(
        name: name,
        phone: phone,
        bio: bio,
        avatar: avatar,
      );

      if (response.isSuccess && response.data != null) {
        _currentUser = response.data;
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

  Future<bool> logout() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.logout();

      if (response.isSuccess) {
        _currentUser = null;
        _isLoggedIn = false;
        
        // Çıkış yapılırken ürün verilerini de temizle
        _productViewModel?.clearAllProductData();
        
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

  Future<void> refreshProfile() async {
    if (!_isLoggedIn) return;

    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.getProfile();

      if (response.isSuccess && response.data != null) {
        _currentUser = response.data;
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _clearError();
  }

  void setError(String error) {
    _setError(error);
  }

  // 403 hatası durumunda otomatik logout
  Future<void> handleForbiddenError() async {
    Logger.warning('🚨 403 Forbidden error detected - Auto logout');
    
    // Token'ı temizle
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userTokenKey);
      await prefs.remove(AppConstants.userIdKey);
      await prefs.remove(AppConstants.userDataKey);
      Logger.info('✅ User data cleared for 403 error');
    } catch (e) {
      Logger.error('❌ Error clearing user data: $e', error: e);
    }
    
    _currentUser = null;
    _isLoggedIn = false;
    _isInitialized = false;
    _clearError();
    notifyListeners();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

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

  @override
  void dispose() {
    super.dispose();
  }
}
