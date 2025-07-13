import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/http_client.dart';
import '../core/constants.dart';
import '../models/user.dart';

class AuthService {
  final HttpClient _httpClient = HttpClient();
  static const String _tag = 'AuthService';

  Future<ApiResponse<User>> login(String email, String password) async {
    try {
      final response = await _httpClient.post(
        ApiConstants.login,
        body: {
          'email': email,
          'password': password,
        },
        fromJson: (json) => {
          'user': User.fromJson(json['user']),
          'token': json['token'] ?? '',
        },
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final user = data['user'] as User;
        final token = data['token'] as String;
        
        // Token ve kullanıcı bilgilerini kaydet
        await _saveUserData(user, token);
        
        return ApiResponse.success(user);
      }

      return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<User>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await _httpClient.post(
        ApiConstants.register,
        body: {
          'name': name,
          'email': email,
          'password': password,
          if (phone != null) 'phone': phone,
        },
        fromJson: (json) => {
          'user': User.fromJson(json['user']),
          'token': json['token'] ?? '',
        },
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final user = data['user'] as User;
        final token = data['token'] as String;
        
        // Token ve kullanıcı bilgilerini kaydet
        await _saveUserData(user, token);
        
        return ApiResponse.success(user);
      }

      return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<User>> getProfile() async {
    try {
      final response = await _httpClient.get(
        ApiConstants.profile,
        fromJson: (json) => User.fromJson(json),
      );

      if (response.isSuccess && response.data != null) {
        // Güncel kullanıcı bilgilerini kaydet
        await _saveUserDataOnly(response.data!);
      }

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<User>> updateProfile({
    String? name,
    String? phone,
    String? bio,
    String? avatar,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;
      if (bio != null) body['bio'] = bio;
      if (avatar != null) body['avatar'] = avatar;

      final response = await _httpClient.put(
        ApiConstants.profile,
        body: body,
        fromJson: (json) => User.fromJson(json),
      );

      if (response.isSuccess && response.data != null) {
        // Güncel kullanıcı bilgilerini kaydet
        await _saveUserDataOnly(response.data!);
      }

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<void>> logout() async {
    try {
      final response = await _httpClient.post(
        ApiConstants.logout,
        fromJson: (json) => null,
      );

      // API çağrısı başarılı veya başarısız olsa da local verileri temizle
      await _clearUserData();

      if (response.isSuccess) {
        return ApiResponse.success(null);
      }

      return response;
    } catch (e) {
      // Hata durumunda da local verileri temizle
      await _clearUserData();
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.userTokenKey);
    } catch (e) {
      return null;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(AppConstants.userDataKey);
      
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        return User.fromJson(userData);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveUserData(User user, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString(AppConstants.userTokenKey, token);
      await prefs.setString(AppConstants.userIdKey, user.id);
      await prefs.setString(AppConstants.userDataKey, json.encode(user.toJson()));
    } catch (e) {
      // Hata durumunda sessizce geç
    }
  }

  Future<void> _saveUserDataOnly(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString(AppConstants.userIdKey, user.id);
      await prefs.setString(AppConstants.userDataKey, json.encode(user.toJson()));
    } catch (e) {
      // Hata durumunda sessizce geç
    }
  }

  Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(AppConstants.userTokenKey);
      await prefs.remove(AppConstants.userIdKey);
      await prefs.remove(AppConstants.userDataKey);
    } catch (e) {
      // Hata durumunda sessizce geç
    }
  }
} 