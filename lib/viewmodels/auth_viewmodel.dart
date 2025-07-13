import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../core/constants.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _currentUser;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  AuthViewModel() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _setLoading(true);
    try {
      _isLoggedIn = await _authService.isLoggedIn();
      if (_isLoggedIn) {
        _currentUser = await _authService.getCurrentUser();
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);
    }
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

    if (password.length < AppConstants.minPasswordLength) {
      _setError(ErrorMessages.weakPassword);
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.login(email, password);
      
      if (response.isSuccess && response.data != null) {
        _currentUser = response.data;
        _isLoggedIn = true;
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

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    if (name.trim().isEmpty || email.trim().isEmpty || password.trim().isEmpty) {
      _setError(ErrorMessages.fieldRequired);
      return false;
    }

    if (!_isValidEmail(email)) {
      _setError(ErrorMessages.invalidEmail);
      return false;
    }

    if (password.length < AppConstants.minPasswordLength) {
      _setError(ErrorMessages.weakPassword);
      return false;
    }

    if (name.length > AppConstants.maxUsernameLength) {
      _setError('İsim çok uzun');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      
      if (response.isSuccess && response.data != null) {
        _currentUser = response.data;
        _isLoggedIn = true;
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