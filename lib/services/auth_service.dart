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
        Logger.debug('🔑 Token saved after register: ${token.substring(0, 10)}...');

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

  Future<ApiResponse<Map<String, dynamic>?>> forgotPassword(String email) async {
    try {
      Logger.info('🔑 FORGOT PASSWORD ATTEMPT: $email');
      Logger.debug('📤 Forgot Password Request Body: {"userEmail": "$email"}');

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.forgotPassword,
        body: {'userEmail': email},
        useBasicAuth: true,
        fromJson: (json) {
          Logger.debug('🔍 ForgotPassword fromJson - Raw data: $json');
          
          // API response'unda codeToken var mı kontrol et
          if (json is Map<String, dynamic>) {
            final result = <String, dynamic>{};
            
            // Tüm response verilerini logla
            Logger.debug('🔍 ForgotPassword response keys: ${json.keys.toList()}');
            
            // codeToken varsa al (direkt response'ta veya data objesi içinde)
            String? codeToken;
            if (json.containsKey('codeToken') && json['codeToken'] != null) {
              codeToken = json['codeToken'].toString();
              Logger.debug('🔑 CodeToken found in response root: $codeToken');
            } else if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
              final data = json['data'] as Map<String, dynamic>;
              if (data.containsKey('codeToken') && data['codeToken'] != null) {
                codeToken = data['codeToken'].toString();
                Logger.debug('🔑 CodeToken found in data object: $codeToken');
              }
            }
            
            if (codeToken != null) {
              result['codeToken'] = codeToken;
            } else {
              Logger.warning('⚠️ CodeToken not found in response or data object');
            }
            
            // Mail bilgilerini de al
            if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
              final data = json['data'] as Map<String, dynamic>;
              if (data.containsKey('mail') && data['mail'] is Map<String, dynamic>) {
                result['mail'] = data['mail'];
                Logger.debug('📧 Mail info found: ${data['mail']}');
              }
            }
            
            // Diğer response verilerini de al
            json.forEach((key, value) {
              if (key != 'codeToken' && key != 'data') {
                result[key] = value;
              }
            });
            
            Logger.debug('🔍 Final result: $result');
            return result.isNotEmpty ? result : null;
          }
          
          Logger.warning('⚠️ Response is not a Map: ${json.runtimeType}');
          return null;
        },
      );

      Logger.debug('📥 ForgotPassword Response isSuccess: ${response.isSuccess}');
      Logger.debug('📥 ForgotPassword Response data: ${response.data}');
      Logger.debug('📥 ForgotPassword Response error: ${response.error}');

      if (response.isSuccess) {
        Logger.info('✅ Forgot password request successful');
        return ApiResponse.success(response.data);
      }

      Logger.error('❌ Forgot password failed: ${response.error}');
      return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
    } catch (e) {
      Logger.error('💥 Forgot password exception: $e', error: e);
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<void>> checkEmailVerificationCode({
    required String code,
    required String codeToken,
  }) async {
    try {
      Logger.info('✅ CHECK EMAIL CODE ATTEMPT: $codeToken');
      Logger.debug(
        '📤 Check Code Request Body: {"code": "$code", "codeToken": "$codeToken"}',
      );

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.checkCode,
        body: {'code': code, 'codeToken': codeToken},
        useBasicAuth: true,
        fromJson: (json) {
          Logger.debug('🔍 CheckCode fromJson - Raw data: $json');
          return null; // Email verification genelde sadece success/error döner
        },
      );

      Logger.debug('📥 CheckCode Response isSuccess:  {response.isSuccess}');
      Logger.debug('📥 CheckCode Response data: ${response.data}');
      Logger.debug('📥 CheckCode Response error: ${response.error}');

      if (response.isSuccess) {
        Logger.info('✅ Email verification successful');
        
        // Kullanıcının isVerified durumunu güncelle
        try {
          final currentUser = await getCurrentUser();
          if (currentUser != null) {
            final updatedUser = User(
              id: currentUser.id,
              name: currentUser.name,
              firstName: currentUser.firstName,
              lastName: currentUser.lastName,
              email: currentUser.email,
              phone: currentUser.phone,
              isVerified: true, // E-posta doğrulandı
              isOnline: currentUser.isOnline,
              createdAt: currentUser.createdAt,
              updatedAt: DateTime.now(),
              token: currentUser.token,
            );
            
            await _saveUserDataOnly(updatedUser);
            Logger.info('✅ User verification status updated to true');
          }
        } catch (e) {
          Logger.warning('⚠️ Failed to update user verification status: $e');
        }
        
        return ApiResponse.success(null);
      }

      Logger.error('❌ Email verification failed: ${response.error}');
      return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
    } catch (e) {
      Logger.error('💥 Check email code exception: $e', error: e);
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<Map<String, dynamic>?>> checkPasswordResetCode({
    required String code,
    required String email,
    required String codeToken,
  }) async {
    try {
      Logger.info('🔑 CHECK PASSWORD RESET CODE ATTEMPT: $email');
      Logger.debug(
        '📤 Check Password Reset Code Request Body: {"code": "$code", "userEmail": "$email", "codeToken": "$codeToken"}',
      );

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.checkCode,
        body: {'code': code, 'userEmail': email, 'codeToken': codeToken},
        useBasicAuth: true,
        fromJson: (json) {
          Logger.debug('🔍 CheckPasswordResetCode fromJson - Raw data: $json');
          
          // API response'unda passToken var mı kontrol et
          if (json is Map<String, dynamic>) {
            final result = <String, dynamic>{};
            
            // Tüm response verilerini logla
            Logger.debug('🔍 CheckPasswordResetCode response keys: ${json.keys.toList()}');
            
            // passToken varsa al (direkt response'ta veya data objesi içinde)
            String? passToken;
            if (json.containsKey('passToken') && json['passToken'] != null) {
              passToken = json['passToken'].toString();
              Logger.debug('🔑 PassToken found in response root: $passToken');
            } else if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
              final data = json['data'] as Map<String, dynamic>;
              if (data.containsKey('passToken') && data['passToken'] != null) {
                passToken = data['passToken'].toString();
                Logger.debug('🔑 PassToken found in data object: $passToken');
              }
            }
            
            if (passToken != null) {
              result['passToken'] = passToken;
            } else {
              Logger.warning('⚠️ PassToken not found in response or data object');
            }
            
            // Diğer response verilerini de al
            json.forEach((key, value) {
              if (key != 'passToken') {
                result[key] = value;
              }
            });
            
            Logger.debug('🔍 Final result: $result');
            return result.isNotEmpty ? result : null;
          }
          
          Logger.warning('⚠️ Response is not a Map: ${json.runtimeType}');
          return null;
        },
      );

      Logger.debug('📥 CheckPasswordResetCode Response isSuccess: ${response.isSuccess}');
      Logger.debug('📥 CheckPasswordResetCode Response data: ${response.data}');
      Logger.debug('📥 CheckPasswordResetCode Response error: ${response.error}');

      if (response.isSuccess) {
        Logger.info('✅ Password reset code verification successful');
        return ApiResponse.success(response.data);
      }

      Logger.error('❌ Password reset code verification failed: ${response.error}');
      return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
    } catch (e) {
      Logger.error('💥 Check password reset code exception: $e', error: e);
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<Map<String, dynamic>?>> resendEmailVerificationCode({
    required String email,
  }) async {
    try {
      Logger.info('🔄 RESEND EMAIL CODE ATTEMPT: $email');
      
      // Email validation
      if (email.trim().isEmpty) {
        Logger.error('❌ Email is empty');
        return ApiResponse.error('E-posta adresi boş olamaz');
      }
      
      // Email format validation
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
      if (!emailRegex.hasMatch(email)) {
        Logger.error('❌ Invalid email format: $email');
        return ApiResponse.error('Geçersiz e-posta formatı');
      }
      
      final requestBody = {
        'userEmail': email.trim(),
      };
      Logger.debug('📤 Resend Code Request Body: ${json.encode(requestBody)}');

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.againSendCode,
        body: requestBody,
        useBasicAuth: true,
        fromJson: (json) {
          Logger.debug('🔍 ResendCode fromJson - Raw data: $json');
          
          // API response'unda codeToken var mı kontrol et
          if (json is Map<String, dynamic>) {
            final result = <String, dynamic>{};
            
            // Tüm response verilerini logla
            Logger.debug('🔍 ResendCode response keys: ${json.keys.toList()}');
            
            // codeToken varsa al (direkt response'ta veya data objesi içinde)
            String? codeToken;
            if (json.containsKey('codeToken') && json['codeToken'] != null) {
              codeToken = json['codeToken'].toString();
              Logger.debug('🔑 CodeToken found in response root: $codeToken');
            } else if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
              final data = json['data'] as Map<String, dynamic>;
              if (data.containsKey('codeToken') && data['codeToken'] != null) {
                codeToken = data['codeToken'].toString();
                Logger.debug('🔑 CodeToken found in data object: $codeToken');
              }
            }
            
            if (codeToken != null) {
              result['codeToken'] = codeToken;
            } else {
              Logger.warning('⚠️ CodeToken not found in response or data object');
            }
            
            // Diğer response verilerini de al
            json.forEach((key, value) {
              if (key != 'codeToken') {
                result[key] = value;
              }
            });
            
            Logger.debug('🔍 Final result: $result');
            return result.isNotEmpty ? result : null;
          }
          
          Logger.warning('⚠️ Response is not a Map: ${json.runtimeType}');
          return null;
        },
      );

      Logger.debug('📥 ResendCode Response isSuccess: ${response.isSuccess}');
      Logger.debug('📥 ResendCode Response data: ${response.data}');
      Logger.debug('📥 ResendCode Response error: ${response.error}');

      if (response.isSuccess) {
        Logger.info('✅ Resend email code successful');
        return ApiResponse.success(response.data);
      }

      Logger.error('❌ Resend email code failed: ${response.error}');
      return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
    } catch (e) {
      Logger.error('💥 Resend email code exception: $e', error: e);
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<Map<String, dynamic>?>> resendEmailVerificationCodeWithToken({
    required String userToken,
  }) async {
    try {
      Logger.info('📧 RESEND EMAIL VERIFICATION CODE WITH TOKEN ATTEMPT');
      
      // Token validation
      if (userToken.trim().isEmpty) {
        Logger.error('❌ User token is empty');
        return ApiResponse.error('Kullanıcı token\'ı boş olamaz');
      }
      
      final requestBody = {
        'userToken': userToken.trim(),
      };
      Logger.debug('📤 Resend Code with Token Request Body: ${json.encode(requestBody)}');

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.againSendCode,
        body: requestBody,
        useBasicAuth: true,
        fromJson: (json) {
          Logger.debug('🔍 ResendCode with Token fromJson - Raw data: $json');
          
          // API response'unda codeToken var mı kontrol et
          if (json is Map<String, dynamic>) {
            final result = <String, dynamic>{};
            
            // Tüm response verilerini logla
            Logger.debug('🔍 ResendCode with Token response keys: ${json.keys.toList()}');
            
            // codeToken varsa al (direkt response'ta veya data objesi içinde)
            String? codeToken;
            if (json.containsKey('codeToken') && json['codeToken'] != null) {
              codeToken = json['codeToken'].toString();
              Logger.debug('🔑 CodeToken found in response root: $codeToken');
            } else if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
              final data = json['data'] as Map<String, dynamic>;
              if (data.containsKey('codeToken') && data['codeToken'] != null) {
                codeToken = data['codeToken'].toString();
                Logger.debug('🔑 CodeToken found in data object: $codeToken');
              }
            }
            
            if (codeToken != null) {
              result['codeToken'] = codeToken;
            } else {
              Logger.warning('⚠️ CodeToken not found in response or data object');
            }
            
            // Diğer response verilerini de al
            json.forEach((key, value) {
              if (key != 'codeToken') {
                result[key] = value;
              }
            });
            
            Logger.debug('🔍 Final result with token: $result');
            return result.isNotEmpty ? result : null;
          }
          
          Logger.warning('⚠️ Response with token is not a Map: ${json.runtimeType}');
          return null;
        },
      );

      Logger.debug('📥 ResendCode with Token Response isSuccess: ${response.isSuccess}');
      Logger.debug('📥 ResendCode with Token Response data: ${response.data}');
      Logger.debug('📥 ResendCode with Token Response error: ${response.error}');

      if (response.isSuccess) {
        Logger.info('✅ Resend email code with token successful');
        return ApiResponse.success(response.data);
      }

      Logger.error('❌ Resend email code with token failed: ${response.error}');
      return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
    } catch (e) {
      Logger.error('💥 Resend email code with token exception: $e', error: e);
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<void>> updatePassword({
    required String passToken,
    required String password,
    required String passwordAgain,
  }) async {
    Logger.info('🔒 UPDATE PASSWORD ATTEMPT with passToken');
    
    // updatePassword metodunu changePassword metoduna yönlendir
    return await changePassword(
      passToken: passToken,
      password: password,
      passwordAgain: passwordAgain,
    );
  }

  Future<ApiResponse<void>> changePassword({
    required String passToken,
    required String password,
    required String passwordAgain,
  }) async {
    try {
      Logger.info('🔒 CHANGE PASSWORD ATTEMPT with passToken');
      Logger.debug(
        '📤 Change Password Request Body: {"passToken": "$passToken", "password": "$password", "passwordAgain": "$passwordAgain"}',
      );

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.changePassword,
        body: {
          'passToken': passToken,
          'password': password,
          'passwordAgain': passwordAgain,
        },
        useBasicAuth: true,
        fromJson: (json) {
          Logger.debug('🔍 ChangePassword fromJson - Raw data: $json');
          return null; // Change password genelde sadece success/error döner
        },
      );

      Logger.debug('📥 ChangePassword Response isSuccess: ${response.isSuccess}');
      Logger.debug('📥 ChangePassword Response data: ${response.data}');
      Logger.debug('📥 ChangePassword Response error: ${response.error}');

      if (response.isSuccess) {
        Logger.info('✅ Password change successful');
        return ApiResponse.success(null);
      }

      Logger.error('❌ Password change failed: ${response.error}');
      return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
    } catch (e) {
      Logger.error('💥 Change password exception: $e', error: e);
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  // Direkt şifre değiştirme (e-posta doğrulaması olmadan)
  Future<ApiResponse<void>> updateUserPassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordAgain,
  }) async {
    try {
      Logger.info('🔒 UPDATE USER PASSWORD ATTEMPT (direct)');
      
      // Mevcut kullanıcının token'ını al
      final userToken = await getCurrentUserToken();
      if (userToken == null || userToken.isEmpty) {
        Logger.error('❌ User token not found');
        return ApiResponse.error('Kullanıcı token\'ı bulunamadı. Lütfen tekrar giriş yapın.');
      }
      
      Logger.debug(
        '📤 Update User Password Request Body: {"passToken": "${userToken.substring(0, 10)}...", "password": "${newPassword.length} chars", "passwordAgain": "${newPasswordAgain.length} chars"}',
      );

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.changePassword,
        body: {
          'passToken': userToken, // Mevcut kullanıcının token'ını kullan
          'password': newPassword,
          'passwordAgain': newPasswordAgain,
        },
        useBasicAuth: true,
        fromJson: (json) {
          Logger.debug('🔍 UpdateUserPassword fromJson - Raw data: $json');
          return null; // Update password genelde sadece success/error döner
        },
      );

      Logger.debug('📥 UpdateUserPassword Response isSuccess: ${response.isSuccess}');
      Logger.debug('📥 UpdateUserPassword Response data: ${response.data}');
      Logger.debug('📥 UpdateUserPassword Response error: ${response.error}');

      if (response.isSuccess) {
        Logger.info('✅ User password update successful');
        return ApiResponse.success(null);
      }

      Logger.error('❌ User password update failed: ${response.error}');
      return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
    } catch (e) {
      Logger.error('💥 Update user password exception: $e', error: e);
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
      Logger.debug('🚪 AuthService.logout called');
      
      // API çağrısı yapmadan direkt local verileri temizle
      await _clearUserData();
      
      Logger.debug('✅ AuthService.logout - Local data cleared successfully');
      return ApiResponse.success(null);
    } catch (e) {
      Logger.error('❌ AuthService.logout - Exception: $e', error: e);
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
      Logger.info('👤 AuthService.getCurrentUser - Quick fetch for hot reload');
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(AppConstants.userDataKey);

      if (userDataString != null && userDataString.isNotEmpty) {
        Logger.debug('✅ AuthService.getCurrentUser - User data found, length: ${userDataString.length}');
        final userData = json.decode(userDataString);
        final user = User.fromJson(userData);
        Logger.info('✅ AuthService.getCurrentUser - User loaded: ${user.id} - ${user.name}');
        return user;
      }

      Logger.warning('❌ AuthService.getCurrentUser - No user data found');
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
      Logger.info('🔍 AuthService.isLoggedIn - Quick check for hot reload');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.userTokenKey);
      final userId = prefs.getString(AppConstants.userIdKey);
      
      Logger.debug('🔍 AuthService.isLoggedIn - userId=[$userId], token=[${token?.substring(0, token.length > 10 ? 10 : token.length)}...]');
      
      final isLoggedIn = token != null &&
          token.isNotEmpty &&
          userId != null &&
          userId.isNotEmpty;
          
      Logger.info('🔍 AuthService.isLoggedIn - Result: $isLoggedIn');
      return isLoggedIn;
    } catch (e) {
      Logger.error('❌ AuthService.isLoggedIn - Exception: $e', error: e);
      return false;
    }
  }

  // Mevcut kullanıcının token'ını al
  Future<String?> getCurrentUserToken() async {
    try {
      Logger.debug('🔍 AuthService.getCurrentUserToken called');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.userTokenKey);
      
      Logger.debug('🔍 AuthService.getCurrentUserToken - token=[${token?.substring(0, token.length > 10 ? 10 : token.length)}...]');
      
      return token;
    } catch (e) {
      Logger.error('❌ AuthService.getCurrentUserToken - Exception: $e', error: e);
      return null;
    }
  }
}
