import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/http_client.dart';
import '../core/constants.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../utils/logger.dart';

class AuthService {
  final HttpClient _httpClient = HttpClient();

  Future<ApiResponse<User>> login(String email, String password) async {
    try {
      // Önce eski kullanıcı verilerini temizle
      await _clearUserData();
      
      Logger.info('🔐 LOGIN ATTEMPT: $email');
      Logger.debug(
        '📤 Login Request Body: {"userEmail": "$email", "userPassword": "$password"}',
      );

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.login,
        body: {'userEmail': email, 'userPassword': password},
        useBasicAuth: true,
        fromJson: (json) {
          Logger.debug('🔍 Login fromJson - Raw data: $json');

          // 410 response formatını kontrol et
          if (json['data'] != null &&
              json['data']['userID'] != null &&
              json['data']['token'] != null) {
            Logger.debug('✅ Login - 410 response format detected');
            final userData = json['data'];

            // API'den gelen verilerle user objesi oluştur
            final user = User(
              id: userData['userID'].toString(),
              name:
                  userData['userFirstname'] != null &&
                      userData['userLastname'] != null
                  ? '${userData['userFirstname']} ${userData['userLastname']}'
                  : userData['userName'] ?? 'Kullanıcı',
              firstName: userData['userFirstname'],
              lastName: userData['userLastname'],
              email: userData['userEmail'] ?? email,
              phone: userData['userPhone'],
              rating: (userData['userRating'] ?? 0.0).toDouble(),
              totalTrades: userData['userTotalTrades'] ?? 0,
              isVerified: userData['userVerified'] ?? false,
              isOnline: true,
              createdAt: userData['userCreatedAt'] != null
                  ? DateTime.tryParse(userData['userCreatedAt']) ??
                        DateTime.now()
                  : DateTime.now(),
              updatedAt: userData['userUpdatedAt'] != null
                  ? DateTime.tryParse(userData['userUpdatedAt']) ??
                        DateTime.now()
                  : DateTime.now(),
              token: userData['token'], // Token'ı User nesnesine dahil et
            );

            return {'user': user, 'token': userData['token'] ?? ''};
          } else {
            // Standart format (eğer farklı response gelirse)
            Logger.debug('✅ Login - Standard response format');
            return {
              'user': User.fromJson(json['user']),
              'token': json['token'] ?? '',
            };
          }
        },
      );

      Logger.debug('📥 Response isSuccess: ${response.isSuccess}');
      Logger.debug('📥 Response data: ${response.data}');
      Logger.debug('📥 Response error: ${response.error}');

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final user = data['user'] as User;
        final token = data['token'] as String;

        Logger.info('✅ Login successful for user: ${user.id}');

        // Token ve kullanıcı bilgilerini kaydet
        await _saveUserData(user, token);

        // Login sonrasında tam kullanıcı bilgilerini çek
        try {
          Logger.debug('🔄 Fetching complete user profile after login...');
          final userService = UserService();
          final profileResponse = await userService.getUserProfile(
            userToken: token,
          );

          if (profileResponse.isSuccess && profileResponse.data != null) {
            final completeUser = profileResponse.data!;
            // Sadece gerçek user data'sı varsa güncelle (ID 0 değilse)
            if (completeUser.id != '0' &&
                completeUser.email != 'user@example.com') {
              Logger.info('✅ Complete user profile fetched successfully');
              await _saveUserDataOnly(completeUser);
              
              // Token'ı her zaman güncelle (API'den yeni token gelebilir)
              await _updateTokenIfNeeded(token);
              
              return ApiResponse.success(completeUser);
            } else {
              Logger.warning(
                '⚠️ Complete profile is default user, using login data instead',
              );
            }
          } else {
            Logger.warning('⚠️ Failed to fetch complete profile, using login data');
          }
        } catch (e) {
          Logger.warning('⚠️ Error fetching complete profile: $e, using login data');
        }
        
        // Token'ı her zaman güncelle
        await _updateTokenIfNeeded(token);

        return ApiResponse.success(user);
      }

      Logger.error('❌ Login failed: ${response.error}');
      return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
    } catch (e) {
      Logger.error('💥 Login exception: $e', error: e);
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

      Logger.info('📝 REGISTER ATTEMPT: $email');
      Logger.debug(
        '📤 Register Request Body: {"userFirstname": "$firstName", "userLastname": "$lastName", "userEmail": "$email", "userPhone": "$phone", "userPassword": "$password", "version": "1.0", "platform": "$platform", "policy": $policy, "kvkk": $kvkk}',
      );

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
        useBasicAuth: true,
        fromJson: (json) {
          Logger.debug('🔍 Register fromJson - Raw data: $json');

          // 410 response formatını kontrol et
          if (json['data'] != null && json['data']['userID'] != null) {
            Logger.debug('✅ Register - 410 response format detected');
            final userData = json['data'];

            // API'den gelen verilerle user objesi oluştur
            final user = User(
              id: userData['userID'].toString(),
              name:
                  userData['userFirstname'] != null &&
                      userData['userLastname'] != null
                  ? '${userData['userFirstname']} ${userData['userLastname']}'
                  : '$firstName $lastName',
              firstName: userData['userFirstname'] ?? firstName,
              lastName: userData['userLastname'] ?? lastName,
              email: userData['userEmail'] ?? email,
              phone: userData['userPhone'] ?? phone,
              rating: (userData['userRating'] ?? 0.0).toDouble(),
              totalTrades: userData['userTotalTrades'] ?? 0,
              isVerified:
                  userData['userVerified'] ??
                  false, // Email verification gerekli
              isOnline: true,
              createdAt: userData['userCreatedAt'] != null
                  ? DateTime.tryParse(userData['userCreatedAt']) ??
                        DateTime.now()
                  : DateTime.now(),
              updatedAt: userData['userUpdatedAt'] != null
                  ? DateTime.tryParse(userData['userUpdatedAt']) ??
                        DateTime.now()
                  : DateTime.now(),
              token: userData['token'], // Token'ı User nesnesine dahil et
            );

            return {
              'user': user,
              'token': userData['token'] ?? '', // Register'da token olmayabilir
            };
          } else {
            // Standart format (eğer farklı response gelirse)
            Logger.debug('✅ Register - Standard response format');
            return {
              'user': User.fromJson(json['user']),
              'token': json['token'] ?? '',
            };
          }
        },
      );

      Logger.debug('📥 Register Response isSuccess: ${response.isSuccess}');
      Logger.debug('📥 Register Response data: ${response.data}');
      Logger.debug('📥 Register Response error: ${response.error}');

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final user = data['user'] as User;
        final token = data['token'] as String;

        Logger.info('✅ Register successful for user: ${user.id}');

        // Token ve kullanıcı bilgilerini kaydet
        await _saveUserData(user, token);

        // Register sonrasında tam kullanıcı bilgilerini çek (token varsa)
        if (token.isNotEmpty) {
          try {
            Logger.debug('🔄 Fetching complete user profile after register...');
            final userService = UserService();
            final profileResponse = await userService.getUserProfile(
              userToken: token,
            );

            if (profileResponse.isSuccess && profileResponse.data != null) {
              Logger.info('✅ Complete user profile fetched successfully');
              final completeUser = profileResponse.data!;
              await _saveUserDataOnly(completeUser);
              
              // Token'ı her zaman güncelle (API'den yeni token gelebilir)
              await _updateTokenIfNeeded(token);
              
              return ApiResponse.success(completeUser);
            } else {
              Logger.warning('⚠️ Failed to fetch complete profile, using register data');
            }
          } catch (e) {
            Logger.warning(
              '⚠️ Error fetching complete profile: $e, using register data',
            );
          }
          
          // Token'ı her zaman güncelle
          await _updateTokenIfNeeded(token);
        }

        return ApiResponse.success(user);
      }

      Logger.error('❌ Register failed: ${response.error}');
      return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
    } catch (e) {
      Logger.error('💥 Register exception: $e', error: e);
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<void>> forgotPassword(String email) async {
    try {
      Logger.info('🔑 FORGOT PASSWORD ATTEMPT: $email');
      Logger.debug('📤 Forgot Password Request Body: {"userEmail": "$email"}');

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.forgotPassword,
        body: {'userEmail': email},
        useBasicAuth: true,
        fromJson: (json) {
          Logger.debug('🔍 ForgotPassword fromJson - Raw data: $json');
          return null; // Forgot password genelde sadece success/error döner
        },
      );

      Logger.debug('📥 ForgotPassword Response isSuccess: ${response.isSuccess}');
      Logger.debug('📥 ForgotPassword Response data: ${response.data}');
      Logger.debug('📥 ForgotPassword Response error: ${response.error}');

      if (response.isSuccess) {
        Logger.info('✅ Forgot password request successful');
        return ApiResponse.success(null);
      }

      Logger.error('❌ Forgot password failed: ${response.error}');
      return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
    } catch (e) {
      Logger.error('💥 Forgot password exception: $e', error: e);
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<void>> checkEmailVerificationCode({
    required String email,
    required String code,
  }) async {
    try {
      Logger.info('✅ CHECK EMAIL CODE ATTEMPT: $email');
      Logger.debug(
        '📤 Check Code Request Body: {"code": "$code", "codeToken": "$email"}',
      );

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.checkCode,
        body: {'code': code, 'codeToken': email},
        useBasicAuth: true,
        fromJson: (json) {
          Logger.debug('🔍 CheckCode fromJson - Raw data: $json');
          return null; // Email verification genelde sadece success/error döner
        },
      );

      Logger.debug('📥 CheckCode Response isSuccess: ${response.isSuccess}');
      Logger.debug('📥 CheckCode Response data: ${response.data}');
      Logger.debug('📥 CheckCode Response error: ${response.error}');

      if (response.isSuccess) {
        Logger.info('✅ Email verification successful');
        return ApiResponse.success(null);
      }

      Logger.error('❌ Email verification failed: ${response.error}');
      return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
    } catch (e) {
      Logger.error('💥 Check email code exception: $e', error: e);
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<void>> resendEmailVerificationCode({
    required String email,
  }) async {
    try {
      Logger.info('🔄 RESEND EMAIL CODE ATTEMPT: $email');
      Logger.debug('📤 Resend Code Request Body: {"userEmail": "$email"}');

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.againSendCode,
        body: {'userEmail': email},
        useBasicAuth: true,
        fromJson: (json) {
          Logger.debug('🔍 ResendCode fromJson - Raw data: $json');
          return null; // Resend code genelde sadece success/error döner
        },
      );

      Logger.debug('📥 ResendCode Response isSuccess: ${response.isSuccess}');
      Logger.debug('📥 ResendCode Response data: ${response.data}');
      Logger.debug('📥 ResendCode Response error: ${response.error}');

      if (response.isSuccess) {
        Logger.info('✅ Resend email code successful');
        return ApiResponse.success(null);
      }

      Logger.error('❌ Resend email code failed: ${response.error}');
      return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
    } catch (e) {
      Logger.error('💥 Resend email code exception: $e', error: e);
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<void>> updatePassword({
    required String email,
    required String verificationCode,
    required String newPassword,
  }) async {
    try {
      Logger.info('🔒 UPDATE PASSWORD ATTEMPT: $email');
      Logger.debug(
        '📤 Update Password Request Body: {"userEmail": "$email", "code": "$verificationCode", "newPassword": "$newPassword"}',
      );

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.updatePassword,
        body: {
          'userEmail': email,
          'code': verificationCode,
          'newPassword': newPassword,
        },
        useBasicAuth: true,
        fromJson: (json) {
          Logger.debug('🔍 UpdatePassword fromJson - Raw data: $json');
          return null; // Update password genelde sadece success/error döner
        },
      );

      Logger.debug('📥 UpdatePassword Response isSuccess: ${response.isSuccess}');
      Logger.debug('📥 UpdatePassword Response data: ${response.data}');
      Logger.debug('📥 UpdatePassword Response error: ${response.error}');

      if (response.isSuccess) {
        Logger.info('✅ Password update successful');
        return ApiResponse.success(null);
      }

      Logger.error('❌ Password update failed: ${response.error}');
      return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
    } catch (e) {
      Logger.error('💥 Update password exception: $e', error: e);
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<User>> getProfile() async {
    try {
      final response = await _httpClient.get(
        ApiConstants.profile,
        fromJson: (json) {
          // Token güncelleme kontrolü - API'den yeni token gelirse kaydet
          if (json is Map<String, dynamic>) {
            if (json.containsKey('token') && json['token'] != null && json['token'].toString().isNotEmpty) {
              final newToken = json['token'].toString();
              Logger.debug('🔄 Get Profile - API response\'unda yeni token bulundu: ${newToken.substring(0, 20)}...');
              _updateTokenIfNeeded(newToken);
            }
            
            // Data içinde token kontrolü
            if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
              final data = json['data'] as Map<String, dynamic>;
              if (data.containsKey('token') && data['token'] != null && data['token'].toString().isNotEmpty) {
                final newToken = data['token'].toString();
                Logger.debug('🔄 Get Profile - Data field içinde yeni token bulundu: ${newToken.substring(0, 20)}...');
                _updateTokenIfNeeded(newToken);
              }
            }
          }
          
          return User.fromJson(json);
        },
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
        fromJson: (json) {
          // Token güncelleme kontrolü - API'den yeni token gelirse kaydet
          if (json is Map<String, dynamic>) {
            if (json.containsKey('token') && json['token'] != null && json['token'].toString().isNotEmpty) {
              final newToken = json['token'].toString();
              Logger.debug('🔄 Update Profile - API response\'unda yeni token bulundu: ${newToken.substring(0, 20)}...');
              _updateTokenIfNeeded(newToken);
            }
            
            // Data içinde token kontrolü
            if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
              final data = json['data'] as Map<String, dynamic>;
              if (data.containsKey('token') && data['token'] != null && data['token'].toString().isNotEmpty) {
                final newToken = data['token'].toString();
                Logger.debug('🔄 Update Profile - Data field içinde yeni token bulundu: ${newToken.substring(0, 20)}...');
                _updateTokenIfNeeded(newToken);
              }
            }
          }
          
          return User.fromJson(json);
        },
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
      Logger.debug('🔑 AuthService.getToken called');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.userTokenKey);

      if (token != null) {
        Logger.debug(
          '✅ AuthService.getToken - Token found: ${token.substring(0, 20)}...',
        );
      } else {
        Logger.debug('❌ AuthService.getToken - No token found');
      }

      return token;
    } catch (e) {
      Logger.error('❌ AuthService.getToken - Exception: $e', error: e);
      return null;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      Logger.debug('👤 AuthService.getCurrentUser called');
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(AppConstants.userDataKey);

      if (userDataString != null) {
        Logger.debug('✅ AuthService.getCurrentUser - User data found');
        final userData = json.decode(userDataString);
        final user = User.fromJson(userData);
        Logger.debug('✅ AuthService.getCurrentUser - User: ${user.id} - ${user.name}');
        return user;
      }

      Logger.debug('❌ AuthService.getCurrentUser - No user data found');
      return null;
    } catch (e) {
      Logger.error('❌ AuthService.getCurrentUser - Exception: $e', error: e);
      return null;
    }
  }

  Future<void> _saveUserData(User user, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      Logger.debug(
        '🔍 _saveUserData - User object: id=${user.id}, name=${user.name}, email=${user.email}',
      );
      Logger.debug('🔍 _saveUserData - User.toJson(): ${user.toJson()}');

      if (user.id != null &&
          user.id.isNotEmpty &&
          token != null &&
          token.isNotEmpty) {
        Logger.debug(
          'Login sonrası userId kaydediliyor: [${user.id}], token: [${token.substring(0, 10)}...]',
        );
        await prefs.setString(AppConstants.userTokenKey, token);
        await prefs.setString(AppConstants.userIdKey, user.id);
        await prefs.setString(
          AppConstants.userDataKey,
          json.encode(user.toJson()),
        );

        // Kaydetme sonrası kontrol
        final savedUserId = prefs.getString(AppConstants.userIdKey);
        Logger.debug('🔍 _saveUserData - Saved and retrieved userId: [$savedUserId]');
      } else {
        Logger.error(
          'HATA: Login sonrası userId veya token null/boş! userId: [${user.id}], token: [$token]',
        );
      }
    } catch (e) {
      Logger.error('❌ _saveUserData - Exception: $e', error: e);
    }
  }

  Future<void> _saveUserDataOnly(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (user.id != null && user.id.isNotEmpty) {
        Logger.debug(
          'Profil güncelleme sonrası userId kaydediliyor: ${user.id}',
        );
        await prefs.setString(AppConstants.userIdKey, user.id);
      } else {
        Logger.debug('Profil güncelleme sonrası userId boş, eski id korunuyor.');
      }
      
      // Mevcut token'ı koru
      final currentToken = prefs.getString(AppConstants.userTokenKey);
      if (currentToken != null && user.token == null) {
        user = user.copyWith(token: currentToken);
      }
      
      await prefs.setString(
        AppConstants.userDataKey,
        json.encode(user.toJson()),
      );
    } catch (e) {
      // Hata durumunda sessizce geç
    }
  }

  /// Token'ı SharedPreferences'a günceller
  Future<void> _updateTokenIfNeeded(String newToken) async {
    try {
      if (newToken.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final currentToken = prefs.getString(AppConstants.userTokenKey);
        
        // Token farklıysa veya yoksa güncelle
        if (currentToken != newToken) {
          Logger.debug('🔄 Token güncelleniyor: ${newToken.substring(0, 20)}...');
          await prefs.setString(AppConstants.userTokenKey, newToken);
          Logger.debug('✅ Token başarıyla güncellendi');
        } else {
          Logger.debug('ℹ️ Token zaten güncel, güncelleme gerekmiyor');
        }
      } else {
        Logger.warning('⚠️ Boş token, güncelleme yapılmadı');
      }
    } catch (e) {
      Logger.error('❌ Token güncelleme hatası: $e', error: e);
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
      Logger.debug('🔄 AuthService.getCurrentUserId called');
      final prefs = await SharedPreferences.getInstance();

      // Tüm kaydedilmiş key'leri kontrol et
      final allKeys = prefs.getKeys();
      Logger.debug('🔍 AuthService - All SharedPreferences keys: $allKeys');

      final userId = prefs.getString(AppConstants.userIdKey);
      final userToken = prefs.getString(AppConstants.userTokenKey);
      final userData = prefs.getString(AppConstants.userDataKey);

      Logger.debug(
        '🔍 AuthService - AppConstants.userIdKey: ${AppConstants.userIdKey}',
      );
      Logger.debug('🔍 AuthService - Retrieved user ID: [$userId]');
      Logger.debug(
        '🔍 AuthService - Retrieved user token: ${userToken?.substring(0, 10)}...',
      );
      Logger.debug('🔍 AuthService - Retrieved user data length: ${userData?.length}');

      // User data'yı parse edip ID'yi kontrol et
      if (userData != null) {
        try {
          final userJson = json.decode(userData);
          final userIdFromData = userJson['id'];
          Logger.debug('🔍 AuthService - User ID from userData: [$userIdFromData]');
          Logger.debug('🔍 AuthService - Full userData: $userJson');

          // Eğer userData'daki ID farklıysa, onu kullan
          if (userIdFromData != null &&
              userIdFromData.toString() != '0' &&
              userId == '0') {
            Logger.debug(
              '🔧 AuthService - Using ID from userData instead: [$userIdFromData]',
            );
            return userIdFromData.toString();
          }
        } catch (e) {
          Logger.error('❌ AuthService - Error parsing userData: $e', error: e);
        }
      }

      return userId;
    } catch (e) {
      Logger.error('❌ AuthService - Error getting current user ID: $e', error: e);
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.userTokenKey);
      final userId = prefs.getString(AppConstants.userIdKey);
      Logger.debug('isLoggedIn kontrolü: userId=[$userId], token=[$token]');
      return token != null &&
          token.isNotEmpty &&
          userId != null &&
          userId.isNotEmpty;
    } catch (e) {
      Logger.error('isLoggedIn exception: $e', error: e);
      return false;
    }
  }
}
