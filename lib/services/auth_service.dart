import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/http_client.dart';
import '../core/constants.dart';
import '../models/user.dart';

class AuthService {
  final HttpClient _httpClient = HttpClient();
  static const String _tag = 'AuthService';

  Future<ApiResponse<User>> login(String email, String password) async {
    try {
      print('🔐 LOGIN ATTEMPT: $email');
      print('📤 Request Body: {"userEmail": "$email", "userPassword": "$password"}');
      
      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.login,
        body: {
          'userEmail': email,
          'userPassword': password,
        },
        fromJson: (json) {
          print('🔍 Login fromJson - Raw data: $json');
          
          // 410 response formatını kontrol et
          if (json['data'] != null && json['data']['userID'] != null && json['data']['token'] != null) {
            print('✅ Login - 410 response format detected');
            final userData = json['data'];
            
            // Dummy user objesi oluştur
            final user = User(
              id: userData['userID'].toString(),
              name: 'User', // Dummy name
              email: email,
              rating: 0.0,
              totalTrades: 0,
              isVerified: false,
              isOnline: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            
            return {
              'user': user,
              'token': userData['token'] ?? '',
            };
          } else {
            // Standart format (eğer farklı response gelirse)
            print('✅ Login - Standard response format');
            return {
              'user': User.fromJson(json['user']),
              'token': json['token'] ?? '',
            };
          }
        },
      );

      print('📥 Response isSuccess: ${response.isSuccess}');
      print('📥 Response data: ${response.data}');
      print('📥 Response error: ${response.error}');

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final user = data['user'] as User;
        final token = data['token'] as String;
        
        print('✅ Login successful for user: ${user.id}');
        
        // Token ve kullanıcı bilgilerini kaydet
        await _saveUserData(user, token);
        
        return ApiResponse.success(user);
      }

      print('❌ Login failed: ${response.error}');
      return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
    } catch (e) {
      print('💥 Login exception: $e');
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<String> _getPlatform() async {
    try {
      if (Platform.isIOS) {
        return 'ios';
      } else if (Platform.isAndroid) {
        return 'android';
      } else {
        return 'web';
      }
    } catch (e) {
      return 'unknown';
    }
  }

  Future<ApiResponse<User>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required bool policy,
    required bool kvkk,
  }) async {
    try {
      final platform = await _getPlatform();
      
      print('📝 REGISTER ATTEMPT: $email');
      print('📤 Register Request Body: {"userFirstname": "$firstName", "userLastname": "$lastName", "userEmail": "$email", "userPhone": "$phone", "userPassword": "$password", "version": "1.0", "platform": "$platform", "policy": $policy, "kvkk": $kvkk}');
      
      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.register,
        body: {
          'userFirstname': firstName,
          'userLastname': lastName,
          'userEmail': email,
          'userPhone': phone,
          'userPassword': password,
          'version': '1.0',
          'platform': platform,
          'policy': policy,
          'kvkk': kvkk,
        },
        fromJson: (json) {
          print('🔍 Register fromJson - Raw data: $json');
          
          // 410 response formatını kontrol et
          if (json['data'] != null && json['data']['userID'] != null) {
            print('✅ Register - 410 response format detected');
            final userData = json['data'];
            
            // Dummy user objesi oluştur (register için token olmayabilir)
            final user = User(
              id: userData['userID'].toString(),
              name: '$firstName $lastName',
              email: email,
              phone: phone,
              rating: 0.0,
              totalTrades: 0,
              isVerified: false, // Email verification gerekli
              isOnline: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            
            return {
              'user': user,
              'token': userData['token'] ?? '', // Register'da token olmayabilir
            };
          } else {
            // Standart format (eğer farklı response gelirse)
            print('✅ Register - Standard response format');
            return {
              'user': User.fromJson(json['user']),
              'token': json['token'] ?? '',
            };
          }
        },
      );

      print('📥 Register Response isSuccess: ${response.isSuccess}');
      print('📥 Register Response data: ${response.data}');
      print('📥 Register Response error: ${response.error}');

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final user = data['user'] as User;
        final token = data['token'] as String;
        
        print('✅ Register successful for user: ${user.id}');
        
        // Token ve kullanıcı bilgilerini kaydet
        await _saveUserData(user, token);
        
        return ApiResponse.success(user);
      }

      print('❌ Register failed: ${response.error}');
      return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
    } catch (e) {
      print('💥 Register exception: $e');
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<void>> forgotPassword(String email) async {
    try {
      print('🔑 FORGOT PASSWORD ATTEMPT: $email');
      print('📤 Forgot Password Request Body: {"userEmail": "$email"}');
      
      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.forgotPassword,
        body: {
          'userEmail': email,
        },
        fromJson: (json) {
          print('🔍 ForgotPassword fromJson - Raw data: $json');
          return null; // Forgot password genelde sadece success/error döner
        },
      );

      print('📥 ForgotPassword Response isSuccess: ${response.isSuccess}');
      print('📥 ForgotPassword Response data: ${response.data}');
      print('📥 ForgotPassword Response error: ${response.error}');

      if (response.isSuccess) {
        print('✅ Forgot password request successful');
        return ApiResponse.success(null);
      }

      print('❌ Forgot password failed: ${response.error}');
      return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
    } catch (e) {
      print('💥 Forgot password exception: $e');
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<void>> checkEmailVerificationCode({
    required String email,
    required String code,
  }) async {
    try {
      print('✅ CHECK EMAIL CODE ATTEMPT: $email');
      print('📤 Check Code Request Body: {"userEmail": "$email", "code": "$code"}');
      
      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.checkCode,
        body: {
          'userEmail': email,
          'code': code,
        },
        fromJson: (json) {
          print('🔍 CheckCode fromJson - Raw data: $json');
          return null; // Email verification genelde sadece success/error döner
        },
      );

      print('📥 CheckCode Response isSuccess: ${response.isSuccess}');
      print('📥 CheckCode Response data: ${response.data}');
      print('📥 CheckCode Response error: ${response.error}');

      if (response.isSuccess) {
        print('✅ Email verification successful');
        return ApiResponse.success(null);
      }

      print('❌ Email verification failed: ${response.error}');
      return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
    } catch (e) {
      print('💥 Check email code exception: $e');
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<void>> resendEmailVerificationCode({
    required String email,
  }) async {
    try {
      print('🔄 RESEND EMAIL CODE ATTEMPT: $email');
      print('📤 Resend Code Request Body: {"userEmail": "$email"}');
      
      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.againSendCode,
        body: {
          'userEmail': email,
        },
        fromJson: (json) {
          print('🔍 ResendCode fromJson - Raw data: $json');
          return null; // Resend code genelde sadece success/error döner
        },
      );

      print('📥 ResendCode Response isSuccess: ${response.isSuccess}');
      print('📥 ResendCode Response data: ${response.data}');
      print('📥 ResendCode Response error: ${response.error}');

      if (response.isSuccess) {
        print('✅ Resend email code successful');
        return ApiResponse.success(null);
      }

      print('❌ Resend email code failed: ${response.error}');
      return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
    } catch (e) {
      print('💥 Resend email code exception: $e');
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<void>> updatePassword({
    required String email,
    required String verificationCode,
    required String newPassword,
  }) async {
    try {
      print('🔒 UPDATE PASSWORD ATTEMPT: $email');
      print('📤 Update Password Request Body: {"userEmail": "$email", "code": "$verificationCode", "newPassword": "$newPassword"}');
      
      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.updatePassword,
        body: {
          'userEmail': email,
          'code': verificationCode,
          'newPassword': newPassword,
        },
        fromJson: (json) {
          print('🔍 UpdatePassword fromJson - Raw data: $json');
          return null; // Update password genelde sadece success/error döner
        },
      );

      print('📥 UpdatePassword Response isSuccess: ${response.isSuccess}');
      print('📥 UpdatePassword Response data: ${response.data}');
      print('📥 UpdatePassword Response error: ${response.error}');

      if (response.isSuccess) {
        print('✅ Password update successful');
        return ApiResponse.success(null);
      }

      print('❌ Password update failed: ${response.error}');
      return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
    } catch (e) {
      print('💥 Update password exception: $e');
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

  Future<String?> getCurrentUserId() async {
    try {
      print('🔄 AuthService.getCurrentUserId called');
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);
      print('🔍 AuthService - Retrieved user ID: $userId');
      return userId;
    } catch (e) {
      print('❌ AuthService - Error getting current user ID: $e');
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.userTokenKey);
      final userId = prefs.getString(AppConstants.userIdKey);
      return token != null && token.isNotEmpty && userId != null && userId.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
} 