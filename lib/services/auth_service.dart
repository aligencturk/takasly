import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/http_client.dart';
import '../core/constants.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../utils/logger.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/notification_service.dart';
import 'package:device_info_plus/device_info_plus.dart';

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
            Logger.warning(
              '⚠️ Failed to fetch complete profile, using login data',
            );
          }
        } catch (e) {
          Logger.warning(
            '⚠️ Error fetching complete profile: $e, using login data',
          );
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

  Future<ApiResponse<User>> loginSocial({
    required String platform, // 'google' | 'apple'
    String? accessToken, // google
    String? idToken, // google ve apple için
    required String deviceID,
    String? fcmToken,
    String? devicePlatform, // 'ios', 'android', 'web'
  }) async {
    try {
      // Eski kullanıcı verilerini temizle
      await _clearUserData();

      final Map<String, dynamic> body = {
        'platform': platform,
        'deviceID': deviceID,
        'version': '1.0.0',
      };

      // devicePlatform parametresini ekle
      if (devicePlatform != null && devicePlatform.isNotEmpty) {
        body['devicePlatform'] = devicePlatform;
      } else {
        // Eğer devicePlatform verilmemişse otomatik olarak tespit et
        final autoPlatform = await _getPlatform();
        body['devicePlatform'] = autoPlatform;
      }

      if (fcmToken != null && fcmToken.isNotEmpty) {
        body['fcmToken'] = fcmToken;
      }

      if (platform.toLowerCase() == 'google') {
        if (accessToken != null) {
          body['accessToken'] = accessToken;
        }
        if (idToken != null) {
          body['idToken'] = idToken;
        }
      }

      if (platform.toLowerCase() == 'apple' && idToken != null) {
        body['idToken'] = idToken;
      }

      Logger.info('🔐 SOCIAL LOGIN ATTEMPT: $platform');
      Logger.debug('📤 Social Login Request Body: ${json.encode(body)}');

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.loginSocial,
        body: body,
        useBasicAuth: true,
        fromJson: (json) {
          Logger.debug('🔍 SocialLogin fromJson - Raw data: $json');

          // 410/200 format: data içinde user ve token
          if (json is Map<String, dynamic>) {
            Map<String, dynamic>? dataField;
            if (json.containsKey('data') &&
                json['data'] is Map<String, dynamic>) {
              dataField = json['data'] as Map<String, dynamic>;
            } else {
              dataField = json; // bazı durumlarda direkt dönebilir
            }

            if (dataField['userID'] != null &&
                (dataField['token'] != null || json['token'] != null)) {
              final tokenString = (dataField['token'] ?? json['token'])
                  .toString();
              final user = User(
                id: dataField['userID'].toString(),
                name:
                    (dataField['userFirstname'] != null &&
                        dataField['userLastname'] != null)
                    ? '${dataField['userFirstname']} ${dataField['userLastname']}'
                    : dataField['userName']?.toString() ?? 'Kullanıcı',
                firstName: dataField['userFirstname']?.toString(),
                lastName: dataField['userLastname']?.toString(),
                email: dataField['userEmail']?.toString() ?? '',
                phone: dataField['userPhone']?.toString(),
                isVerified: (dataField['userVerified'] ?? false) == true,
                isOnline: true,
                createdAt: dataField['userCreatedAt'] != null
                    ? DateTime.tryParse(
                            dataField['userCreatedAt'].toString(),
                          ) ??
                          DateTime.now()
                    : DateTime.now(),
                updatedAt: DateTime.now(),
                token: tokenString,
              );

              return {'user': user, 'token': tokenString};
            }

            // Alternatif standart format
            if (json.containsKey('user')) {
              final user = User.fromJson(json['user']);
              final token = json['token']?.toString() ?? '';
              return {'user': user, 'token': token};
            }
          }

          return {
            'user': User(
              id: '0',
              name: 'Kullanıcı',
              firstName: null,
              lastName: null,
              email: 'user@example.com',
              phone: null,
              isVerified: false,
              isOnline: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              token: '',
            ),
            'token': '',
          };
        },
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final user = data['user'] as User;
        final token = data['token'] as String? ?? '';

        if (token.isNotEmpty) {
          await _saveUserData(user, token);
          await _updateTokenIfNeeded(token);
        } else {
          // Bazı sosyal login akışlarında token body dışında olabilir, yine de user'ı kaydetme
          await _saveUserDataOnly(user);
        }

        return ApiResponse.success(user);
      }

      return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
    } catch (e) {
      Logger.error('💥 Social login exception: $e', error: e);
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

  Future<ApiResponse<Map<String, dynamic>>> register({
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
            final tokenString =
                (userData['userToken'] ?? userData['token'] ?? '').toString();
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
              token: tokenString, // Token'ı User nesnesine dahil et
            );

            Logger.debug(
              '✅ User objesi oluşturuldu: ${user.id} - ${user.name}',
            );

            // codeToken'ı da response'a ekle
            final result = {
              'user': user,
              'token':
                  tokenString, // Register'da token userToken olarak gelebilir
            };

            // codeToken varsa ekle
            if (userData.containsKey('codeToken') &&
                userData['codeToken'] != null) {
              result['codeToken'] = userData['codeToken'].toString();
              Logger.debug(
                '🔑 CodeToken found in response: ${result['codeToken']}',
              );
            }

            return result;
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
        Logger.debug(
          '🔑 Token saved after register: ${token.substring(0, 10)}...',
        );

        // codeToken'ı da kaydet (email verification için)
        if (data.containsKey('codeToken') && data['codeToken'] != null) {
          final codeToken = data['codeToken'].toString();
          Logger.debug('🔑 CodeToken saved after register: $codeToken');
          // codeToken'ı SharedPreferences'a kaydet
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('codeToken', codeToken);
        }

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

              // Kullanıcı verilerini SharedPreferences'a kaydet
              await _saveUserData(completeUser, token);

              return ApiResponse.success({
                'user': completeUser,
                'token': token,
                'codeToken': data['codeToken'],
              });
            } else {
              Logger.warning(
                '⚠️ Failed to fetch complete profile, using register data',
              );
            }
          } catch (e) {
            Logger.warning(
              '⚠️ Error fetching complete profile: $e, using register data',
            );
          }

          // Token'ı her zaman güncelle
          await _updateTokenIfNeeded(token);
        }

        // Kullanıcı verilerini SharedPreferences'a kaydet
        await _saveUserData(user, token);

        return ApiResponse.success({
          'user': user,
          'token': token,
          'codeToken': data['codeToken'],
        });
      }

      Logger.error('❌ Register failed: ${response.error}');
      return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
    } catch (e) {
      Logger.error('💥 Register exception: $e', error: e);
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<Map<String, dynamic>?>> forgotPassword(
    String email,
  ) async {
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
            Logger.debug(
              '🔍 ForgotPassword response keys: ${json.keys.toList()}',
            );

            // codeToken varsa al (direkt response'ta veya data objesi içinde)
            String? codeToken;
            if (json.containsKey('codeToken') && json['codeToken'] != null) {
              codeToken = json['codeToken'].toString();
              Logger.debug('🔑 CodeToken found in response root: $codeToken');
            } else if (json.containsKey('data') &&
                json['data'] is Map<String, dynamic>) {
              final data = json['data'] as Map<String, dynamic>;
              if (data.containsKey('codeToken') && data['codeToken'] != null) {
                codeToken = data['codeToken'].toString();
                Logger.debug('🔑 CodeToken found in data object: $codeToken');
              }
            }

            if (codeToken != null) {
              result['codeToken'] = codeToken;
            } else {
              Logger.warning(
                '⚠️ CodeToken not found in response or data object',
              );
            }

            // Mail bilgilerini de al
            if (json.containsKey('data') &&
                json['data'] is Map<String, dynamic>) {
              final data = json['data'] as Map<String, dynamic>;
              if (data.containsKey('mail') &&
                  data['mail'] is Map<String, dynamic>) {
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

      Logger.debug(
        '📥 ForgotPassword Response isSuccess: ${response.isSuccess}',
      );
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

  Future<ApiResponse<bool>> checkEmailVerificationCode({
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

        return ApiResponse.success(true);
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
            Logger.debug(
              '🔍 CheckPasswordResetCode response keys: ${json.keys.toList()}',
            );

            // passToken varsa al (direkt response'ta veya data objesi içinde)
            String? passToken;
            if (json.containsKey('passToken') && json['passToken'] != null) {
              passToken = json['passToken'].toString();
              Logger.debug('🔑 PassToken found in response root: $passToken');
            } else if (json.containsKey('data') &&
                json['data'] is Map<String, dynamic>) {
              final data = json['data'] as Map<String, dynamic>;
              if (data.containsKey('passToken') && data['passToken'] != null) {
                passToken = data['passToken'].toString();
                Logger.debug('🔑 PassToken found in data object: $passToken');
              }
            }

            if (passToken != null) {
              result['passToken'] = passToken;
            } else {
              Logger.warning(
                '⚠️ PassToken not found in response or data object',
              );
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

      Logger.debug(
        '📥 CheckPasswordResetCode Response isSuccess: ${response.isSuccess}',
      );
      Logger.debug('📥 CheckPasswordResetCode Response data: ${response.data}');
      Logger.debug(
        '📥 CheckPasswordResetCode Response error: ${response.error}',
      );

      if (response.isSuccess) {
        Logger.info('✅ Password reset code verification successful');
        return ApiResponse.success(response.data);
      }

      Logger.error(
        '❌ Password reset code verification failed: ${response.error}',
      );
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

      final requestBody = {'userEmail': email.trim()};
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
            } else if (json.containsKey('code_token') &&
                json['code_token'] != null) {
              codeToken = json['code_token'].toString();
              Logger.debug(
                '🔑 CodeToken found in response root (snake): $codeToken',
              );
            } else if (json.containsKey('data') &&
                json['data'] is Map<String, dynamic>) {
              final data = json['data'] as Map<String, dynamic>;
              if (data.containsKey('codeToken') && data['codeToken'] != null) {
                codeToken = data['codeToken'].toString();
                Logger.debug('🔑 CodeToken found in data object: $codeToken');
              } else if (data.containsKey('code_token') &&
                  data['code_token'] != null) {
                codeToken = data['code_token'].toString();
                Logger.debug(
                  '🔑 CodeToken found in data object (snake): $codeToken',
                );
              } else if (data.containsKey('mail') &&
                  data['mail'] is Map<String, dynamic>) {
                final mail = data['mail'] as Map<String, dynamic>;
                if (mail['codeToken'] != null) {
                  codeToken = mail['codeToken'].toString();
                  Logger.debug('🔑 CodeToken found in data.mail: $codeToken');
                } else if (mail['code_token'] != null) {
                  codeToken = mail['code_token'].toString();
                  Logger.debug(
                    '🔑 CodeToken found in data.mail (snake): $codeToken',
                  );
                }
              }
            } else if (json.containsKey('mail') &&
                json['mail'] is Map<String, dynamic>) {
              final mail = json['mail'] as Map<String, dynamic>;
              if (mail['codeToken'] != null) {
                codeToken = mail['codeToken'].toString();
                Logger.debug('🔑 CodeToken found in mail: $codeToken');
              } else if (mail['code_token'] != null) {
                codeToken = mail['code_token'].toString();
                Logger.debug('🔑 CodeToken found in mail (snake): $codeToken');
              }
            }

            if (codeToken != null) {
              result['codeToken'] = codeToken;
            } else {
              Logger.warning(
                '⚠️ CodeToken not found in response or data object',
              );
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

  Future<ApiResponse<Map<String, dynamic>?>>
  resendEmailVerificationCodeWithToken({required String userToken}) async {
    try {
      Logger.info('📧 RESEND EMAIL VERIFICATION CODE WITH TOKEN ATTEMPT');

      // Token validation
      if (userToken.trim().isEmpty) {
        Logger.error('❌ User token is empty');
        return ApiResponse.error('Kullanıcı token\'ı boş olamaz');
      }

      final requestBody = {'userToken': userToken.trim()};
      Logger.debug(
        '📤 Resend Code with Token Request Body: ${json.encode(requestBody)}',
      );

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
            Logger.debug(
              '🔍 ResendCode with Token response keys: ${json.keys.toList()}',
            );

            // codeToken varsa al (direkt response'ta veya data objesi içinde)
            String? codeToken;
            if (json.containsKey('codeToken') && json['codeToken'] != null) {
              codeToken = json['codeToken'].toString();
              Logger.debug('🔑 CodeToken found in response root: $codeToken');
            } else if (json.containsKey('code_token') &&
                json['code_token'] != null) {
              codeToken = json['code_token'].toString();
              Logger.debug(
                '🔑 CodeToken found in response root (snake): $codeToken',
              );
            } else if (json.containsKey('data') &&
                json['data'] is Map<String, dynamic>) {
              final data = json['data'] as Map<String, dynamic>;
              if (data.containsKey('codeToken') && data['codeToken'] != null) {
                codeToken = data['codeToken'].toString();
                Logger.debug('🔑 CodeToken found in data object: $codeToken');
              } else if (data.containsKey('code_token') &&
                  data['code_token'] != null) {
                codeToken = data['code_token'].toString();
                Logger.debug(
                  '🔑 CodeToken found in data object (snake): $codeToken',
                );
              } else if (data.containsKey('mail') &&
                  data['mail'] is Map<String, dynamic>) {
                final mail = data['mail'] as Map<String, dynamic>;
                if (mail['codeToken'] != null) {
                  codeToken = mail['codeToken'].toString();
                  Logger.debug('🔑 CodeToken found in data.mail: $codeToken');
                } else if (mail['code_token'] != null) {
                  codeToken = mail['code_token'].toString();
                  Logger.debug(
                    '🔑 CodeToken found in data.mail (snake): $codeToken',
                  );
                }
              }
            } else if (json.containsKey('mail') &&
                json['mail'] is Map<String, dynamic>) {
              final mail = json['mail'] as Map<String, dynamic>;
              if (mail['codeToken'] != null) {
                codeToken = mail['codeToken'].toString();
                Logger.debug('🔑 CodeToken found in mail: $codeToken');
              } else if (mail['code_token'] != null) {
                codeToken = mail['code_token'].toString();
                Logger.debug('🔑 CodeToken found in mail (snake): $codeToken');
              }
            }

            if (codeToken != null) {
              result['codeToken'] = codeToken;
            } else {
              Logger.warning(
                '⚠️ CodeToken not found in response or data object',
              );
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

          Logger.warning(
            '⚠️ Response with token is not a Map: ${json.runtimeType}',
          );
          return null;
        },
      );

      Logger.debug(
        '📥 ResendCode with Token Response isSuccess: ${response.isSuccess}',
      );
      Logger.debug('📥 ResendCode with Token Response data: ${response.data}');
      Logger.debug(
        '📥 ResendCode with Token Response error: ${response.error}',
      );

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

      Logger.debug(
        '📥 ChangePassword Response isSuccess: ${response.isSuccess}',
      );
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
        return ApiResponse.error(
          'Kullanıcı token\'ı bulunamadı. Lütfen tekrar giriş yapın.',
        );
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

      Logger.debug(
        '📥 UpdateUserPassword Response isSuccess: ${response.isSuccess}',
      );
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
            if (json.containsKey('token') &&
                json['token'] != null &&
                json['token'].toString().isNotEmpty) {
              final newToken = json['token'].toString();
              Logger.debug(
                '🔄 Get Profile - API response\'unda yeni token bulundu: ${newToken.substring(0, 20)}...',
              );
              _updateTokenIfNeeded(newToken);
            }

            // Data içinde token kontrolü
            if (json.containsKey('data') &&
                json['data'] is Map<String, dynamic>) {
              final data = json['data'] as Map<String, dynamic>;
              if (data.containsKey('token') &&
                  data['token'] != null &&
                  data['token'].toString().isNotEmpty) {
                final newToken = data['token'].toString();
                Logger.debug(
                  '🔄 Get Profile - Data field içinde yeni token bulundu: ${newToken.substring(0, 20)}...',
                );
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
            if (json.containsKey('token') &&
                json['token'] != null &&
                json['token'].toString().isNotEmpty) {
              final newToken = json['token'].toString();
              Logger.debug(
                '🔄 Update Profile - API response\'unda yeni token bulundu: ${newToken.substring(0, 20)}...',
              );
              _updateTokenIfNeeded(newToken);
            }

            // Data içinde token kontrolü
            if (json.containsKey('data') &&
                json['data'] is Map<String, dynamic>) {
              final data = json['data'] as Map<String, dynamic>;
              if (data.containsKey('token') &&
                  data['token'] != null &&
                  data['token'].toString().isNotEmpty) {
                final newToken = data['token'].toString();
                Logger.debug(
                  '🔄 Update Profile - Data field içinde yeni token bulundu: ${newToken.substring(0, 20)}...',
                );
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
        Logger.debug(
          '✅ AuthService.getCurrentUser - User data found, length: ${userDataString.length}',
        );
        final userData = json.decode(userDataString);
        final user = User.fromJson(userData);
        Logger.info(
          '✅ AuthService.getCurrentUser - User loaded: ${user.id} - ${user.name}',
        );
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

      if (user.id.isNotEmpty && token.isNotEmpty) {
        Logger.debug(
          'Login sonrası userId kaydediliyor: [${user.id}], token: [${token.substring(0, 10)}...]',
        );
        await prefs.setString(AppConstants.userTokenKey, token);
        await prefs.setString(AppConstants.userIdKey, user.id);
        await prefs.setString(
          AppConstants.userDataKey,
          json.encode(user.toJson()),
        );

        // FCM token'ı Firebase'e kaydet - async olarak çalıştır
        _saveFCMTokenToFirebase(user.id)
            .then((_) {
              Logger.info('✅ FCM token Firebase\'e kaydetme tamamlandı');
            })
            .catchError((error) {
              Logger.error(
                '❌ FCM token Firebase\'e kaydetme hatası: $error',
                error: error,
              );
            });

        // Kaydetme sonrası kontrol
        final savedUserId = prefs.getString(AppConstants.userIdKey);
        Logger.debug(
          '🔍 _saveUserData - Saved and retrieved userId: [$savedUserId]',
        );
      } else {
        Logger.error(
          'HATA: Login sonrası userId veya token null/boş! userId: [${user.id}], token: [$token]',
        );
      }
    } catch (e) {
      Logger.error('❌ _saveUserData - Exception: $e', error: e);
    }
  }

  // FCM token'ı Firebase'e kaydet
  Future<void> _saveFCMTokenToFirebase(String userId) async {
    try {
      Logger.info('🔄 FCM token Firebase\'e kaydediliyor...');
      Logger.info('👤 User ID: $userId');

      // NotificationService'ten FCM token'ı al
      final fcmToken = await NotificationService.instance.getFCMToken();

      if (fcmToken != null && fcmToken.isNotEmpty) {
        Logger.info('✅ FCM token alındı: ${fcmToken.substring(0, 20)}...');

        // Firebase Database'e FCM token'ı kaydet
        final database = FirebaseDatabase.instance.ref();

        // Cihaz bilgisi ile birlikte FCM token'ı kaydet
        final deviceInfo = await _getDeviceInfo();
        final path = 'users/$userId/fcmToken';

        Logger.info(
          '📝 FCM token kaydediliyor: $path = ${fcmToken.substring(0, 20)}...',
        );
        Logger.info('📱 Cihaz bilgisi: $deviceInfo');

        // Token ve cihaz bilgisini birlikte kaydet
        final tokenData = {
          'token': fcmToken,
          'deviceInfo': deviceInfo,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        };

        await database.child(path).set(tokenData);
        Logger.info('✅ FCM token ve cihaz bilgisi Firebase\'e kaydedildi');

        // Kaydedilen token'ı kontrol et
        final savedToken = await database.child(path).get();
        if (savedToken.value != null) {
          final savedValue = savedToken.value.toString();
          Logger.info(
            '✅ FCM token başarıyla Firebase\'e kaydedildi ve doğrulandı: ${fcmToken.substring(0, 20)}...',
          );

          // Token'ı SharedPreferences'a kaydet
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fcmToken', fcmToken);
          Logger.info('✅ FCM token SharedPreferences\'a kaydedildi');
        } else {
          Logger.error('❌ FCM token kaydedildi ama doğrulanamadı!');
        }
      } else {
        Logger.warning('⚠️ FCM token alınamadı, Firebase\'e kaydedilmedi');

        // FCM token alınamadıysa tekrar deneme
        await Future.delayed(Duration(seconds: 2));
        final retryToken = await NotificationService.instance.getFCMToken();
        if (retryToken != null && retryToken.isNotEmpty) {
          Logger.info(
            '🔄 FCM token retry ile alındı, tekrar kaydetme deneniyor...',
          );
          await _saveFCMTokenToFirebase(userId);
        }
      }
    } catch (e) {
      Logger.error('❌ FCM token Firebase\'e kaydetme hatası: $e', error: e);

      // Hata durumunda tekrar deneme
      try {
        await Future.delayed(Duration(seconds: 3));
        Logger.info('🔄 FCM token kaydetme hatası sonrası tekrar deneniyor...');
        await _saveFCMTokenToFirebase(userId);
      } catch (retryError) {
        Logger.error(
          '❌ FCM token kaydetme retry hatası: $retryError',
          error: retryError,
        );
      }
    }
  }

  // Cihaz bilgisini al
  Future<String> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = 'unknown';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId =
            '${androidInfo.brand}_${androidInfo.model}_${androidInfo.id}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId =
            '${iosInfo.name}_${iosInfo.model}_${iosInfo.identifierForVendor}';
      }

      return deviceId;
    } catch (e) {
      Logger.warning('⚠️ Cihaz bilgisi alınamadı: $e');
      return 'unknown_device';
    }
  }

  Future<void> _saveUserDataOnly(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (user.id.isNotEmpty) {
        Logger.debug(
          'Profil güncelleme sonrası userId kaydediliyor: ${user.id}',
        );
        await prefs.setString(AppConstants.userIdKey, user.id);
      } else {
        Logger.debug(
          'Profil güncelleme sonrası userId boş, eski id korunuyor.',
        );
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
          Logger.debug(
            '🔄 Token güncelleniyor: ${newToken.substring(0, 20)}...',
          );
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
      Logger.debug(
        '🔍 AuthService - Retrieved user data length: ${userData?.length}',
      );

      // User data'yı parse edip ID'yi kontrol et
      if (userData != null) {
        try {
          final userJson = json.decode(userData);
          final userIdFromData = userJson['id'];
          Logger.debug(
            '🔍 AuthService - User ID from userData: [$userIdFromData]',
          );
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
      Logger.error(
        '❌ AuthService - Error getting current user ID: $e',
        error: e,
      );
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      Logger.info('🔍 AuthService.isLoggedIn - Quick check for hot reload');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.userTokenKey);
      final userId = prefs.getString(AppConstants.userIdKey);

      Logger.debug(
        '🔍 AuthService.isLoggedIn - userId=[$userId], token=[${token?.substring(0, token.length > 10 ? 10 : token.length)}...]',
      );

      final isLoggedIn =
          token != null &&
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

      Logger.debug(
        '🔍 AuthService.getCurrentUserToken - token=[${token?.substring(0, token.length > 10 ? 10 : token.length)}...]',
      );

      return token;
    } catch (e) {
      Logger.error(
        '❌ AuthService.getCurrentUserToken - Exception: $e',
        error: e,
      );
      return null;
    }
  }

  // Kayıt sonrası alınan codeToken'ı al
  Future<String?> getStoredCodeToken() async {
    try {
      Logger.debug('🔍 AuthService.getStoredCodeToken called');
      final prefs = await SharedPreferences.getInstance();
      final codeToken = prefs.getString('codeToken');

      if (codeToken != null && codeToken.isNotEmpty) {
        Logger.debug('✅ CodeToken found: $codeToken');
      } else {
        Logger.debug('❌ No codeToken found');
      }

      return codeToken;
    } catch (e) {
      Logger.error(
        '❌ AuthService.getStoredCodeToken - Exception: $e',
        error: e,
      );
      return null;
    }
  }

  // codeToken'ı temizle (kullanıldıktan sonra)
  Future<void> clearStoredCodeToken() async {
    try {
      Logger.debug('🧹 Clearing stored codeToken');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('codeToken');
      Logger.debug('✅ CodeToken cleared');
    } catch (e) {
      Logger.error('❌ Error clearing codeToken: $e', error: e);
    }
  }

  /// FCM token'ları temizler
  Future<void> clearFCMTokens() async {
    try {
      Logger.info('🧹 FCM token\'lar temizleniyor...');

      final database = FirebaseDatabase.instance.ref();

      // Tüm kullanıcılardaki FCM token'ları temizle
      final allUsersSnapshot = await database.child('users').get();
      if (allUsersSnapshot.value != null) {
        dynamic rawValue = allUsersSnapshot.value;
        Map<String, dynamic>? allUsers;

        if (rawValue is Map) {
          allUsers = Map<String, dynamic>.from(rawValue);
        } else if (rawValue is List) {
          allUsers = <String, dynamic>{};
          for (int i = 0; i < rawValue.length; i++) {
            if (rawValue[i] != null) {
              allUsers[i.toString()] = rawValue[i];
            }
          }
        }

        if (allUsers != null) {
          Logger.info('🔍 Firebase\'de ${allUsers.length} kullanıcı bulundu');

          for (final entry in allUsers.entries) {
            final userId = entry.key;
            final userData = entry.value;

            Logger.info('🔍 Kullanıcı $userId kontrol ediliyor...');

            if (userData is Map && userData.containsKey('fcmToken')) {
              final fcmToken = userData['fcmToken'] as String;
              Logger.info(
                '🧹 Kullanıcı $userId\'den FCM token temizleniyor: ${fcmToken.substring(0, 20)}...',
              );

              await database.child('users/$userId/fcmToken').remove();
              Logger.info('✅ Kullanıcı $userId\'den FCM token temizlendi');
            } else {
              Logger.info('ℹ️ Kullanıcı $userId\'de FCM token yok');
            }
          }
        }
      }

      Logger.info('✅ Tüm FCM token\'lar temizlendi!');
    } catch (e) {
      Logger.error('❌ FCM token temizleme hatası: $e', error: e);
    }
  }

  /// FCM token'ı test etmek için kullanılır
  Future<void> testFCMToken() async {
    try {
      Logger.info('🧪 FCM token test başlatılıyor...');

      // Mevcut kullanıcı bilgilerini kontrol et
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);
      final userToken = prefs.getString(AppConstants.userTokenKey);
      final fcmToken = prefs.getString('fcmToken');

      Logger.info('🔍 Mevcut kullanıcı bilgileri:');
      Logger.info('👤 User ID: [$userId]');
      Logger.info('🔑 User Token: [${userToken?.substring(0, 10)}...]');
      Logger.info('📱 FCM Token: [${fcmToken?.substring(0, 20)}...]');

      if (userId != null && userId.isNotEmpty) {
        Logger.info('✅ Kullanıcı ID bulundu: $userId');

        // Sadece mevcut kullanıcıya FCM token kaydet (temizlik yapma)
        Logger.info('📝 Kullanıcı $userId için FCM token kaydediliyor...');
        await _saveFCMTokenToFirebase(userId);

        Logger.info('✅ FCM token başarıyla kaydedildi!');
      } else {
        Logger.warning('⚠️ Kullanıcı ID bulunamadı, FCM token kaydedilemedi');
      }
    } catch (e) {
      Logger.error('❌ FCM token test hatası: $e', error: e);
    }
  }

  /// Token'ın geçerli olup olmadığını kontrol eder
  Future<bool> isTokenValid() async {
    try {
      Logger.info('🔍 AuthService.isTokenValid - Checking token validity');

      final token = await getToken();
      if (token == null || token.isEmpty) {
        Logger.warning('⚠️ AuthService.isTokenValid - No token found');
        return false;
      }

      // UserService ile profile çekmeye çalışarak token'ı test et
      final userService = UserService();
      final response = await userService.getUserProfile(userToken: token);

      if (response.isSuccess && response.data != null) {
        Logger.info('✅ AuthService.isTokenValid - Token is valid');
        return true;
      } else {
        Logger.warning(
          '⚠️ AuthService.isTokenValid - Token is invalid: ${response.error}',
        );

        // Token geçersizse kullanıcı verilerini temizle
        if (response.error != null &&
            (response.error!.contains('token') ||
                response.error!.contains('401') ||
                response.error!.contains('403') ||
                response.error!.contains('Geçersiz') ||
                response.error!.contains('doğrulama'))) {
          Logger.info(
            '🧹 AuthService.isTokenValid - Clearing invalid token data',
          );
          await _clearUserData();
        }

        return false;
      }
    } catch (e) {
      Logger.error('❌ AuthService.isTokenValid - Exception: $e', error: e);
      return false;
    }
  }

  // FCM token'ı debug et
  Future<void> debugFCMToken(String userId) async {
    try {
      Logger.info('🔍 FCM token debug başlatılıyor...', tag: 'AuthService');

      // 1. SharedPreferences'dan token al
      final prefs = await SharedPreferences.getInstance();
      final localToken = prefs.getString('fcmToken');
      Logger.info(
        '📱 Local FCM token: ${localToken != null ? '${localToken.substring(0, 20)}...' : 'null'}',
        tag: 'AuthService',
      );

      // 2. NotificationService'den token al
      final notificationToken = await NotificationService.instance
          .getFCMToken();
      Logger.info(
        '🔔 NotificationService FCM token: ${notificationToken != null ? '${notificationToken.substring(0, 20)}...' : 'null'}',
        tag: 'AuthService',
      );

      // 3. Firebase'den token al
      final database = FirebaseDatabase.instance.ref();
      final firebaseTokenSnapshot = await database
          .child('users/$userId/fcmToken')
          .get();
      final firebaseToken = firebaseTokenSnapshot.value?.toString();
      Logger.info(
        '🔥 Firebase FCM token: ${firebaseToken != null ? '${firebaseToken.substring(0, 20)}...' : 'null'}',
        tag: 'AuthService',
      );

      // 4. Token'ları karşılaştır
      if (localToken == notificationToken &&
          notificationToken == firebaseToken) {
        Logger.info('✅ Tüm FCM token\'lar eşleşiyor', tag: 'AuthService');
      } else {
        Logger.warning('⚠️ FCM token\'lar eşleşmiyor!', tag: 'AuthService');
        Logger.warning(
          '📱 Local: ${localToken?.substring(0, 20)}...',
          tag: 'AuthService',
        );
        Logger.warning(
          '🔔 Notification: ${notificationToken?.substring(0, 20)}...',
          tag: 'AuthService',
        );
        Logger.warning(
          '🔥 Firebase: ${firebaseToken?.substring(0, 20)}...',
          tag: 'AuthService',
        );

        // Firebase'deki token'ı güncelle
        if (notificationToken != null && notificationToken.isNotEmpty) {
          Logger.info(
            '🔄 Firebase\'deki FCM token güncelleniyor...',
            tag: 'AuthService',
          );
          await database.child('users/$userId/fcmToken').set(notificationToken);
          Logger.info('✅ Firebase FCM token güncellendi', tag: 'AuthService');
        }
      }

      // 5. Token uzunluklarını kontrol et
      Logger.info('📏 Token uzunlukları:', tag: 'AuthService');
      Logger.info('📱 Local: ${localToken?.length ?? 0}', tag: 'AuthService');
      Logger.info(
        '🔔 Notification: ${notificationToken?.length ?? 0}',
        tag: 'AuthService',
      );
      Logger.info(
        '🔥 Firebase: ${firebaseToken?.length ?? 0}',
        tag: 'AuthService',
      );
    } catch (e) {
      Logger.error(
        '❌ FCM token debug hatası: $e',
        error: e,
        tag: 'AuthService',
      );
    }
  }
}
