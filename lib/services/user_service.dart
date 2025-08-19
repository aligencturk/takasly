import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/http_client.dart';
import '../core/constants.dart';
import '../models/user.dart';
import '../models/user_profile_detail.dart';
import '../models/live_search.dart';
import '../utils/logger.dart';

class UserService {
  final HttpClient _httpClient = HttpClient();
  // tag kaldırıldı (kullanılmıyordu)

  /// Kullanıcı profilini günceller
  /// PUT /service/user/id
  Future<ApiResponse<User>> updateUserProfile({
    required String userToken,
    String? platform,
    String? version,
  }) async {
    try {
      // Platform detection
      final detectedPlatform = platform ?? getPlatform();
      final appVersion = version ?? AppConstants.appVersion;

      Logger.debug('UPDATE USER PROFILE', tag: 'UserService');
      Logger.debug(
        'Request Body: {"userToken": "$userToken", "platform": "$detectedPlatform", "version": "$appVersion"}',
        tag: 'UserService',
      );
      final response = await _httpClient.putWithBasicAuth(
        ApiConstants.userProfile,
        body: {
          'userToken': userToken,
          'platform': detectedPlatform,
          'version': appVersion,
        },
        fromJson: (json) {
          Logger.debug(
            'Update Profile fromJson - Raw data: $json',
            tag: 'UserService',
          );

          // Response formatını kontrol et
          if (json is Map<String, dynamic>) {
            // Token güncelleme kontrolü - API'den yeni token gelirse kaydet
            if (json.containsKey('token') &&
                json['token'] != null &&
                json['token'].toString().isNotEmpty) {
              final newToken = json['token'].toString();
              Logger.debug(
                'Update Profile - API response\'unda yeni token bulundu: ${newToken.substring(0, 20)}...',
                tag: 'UserService',
              );
              _updateTokenInBackground(newToken);
            }

            // API formatından model formatına dönüştür
            Map<String, dynamic> userDataToTransform;

            // Eğer direkt user verisi gelirse
            if (json.containsKey('id') || json.containsKey('userID')) {
              userDataToTransform = json;
            }
            // Eğer data field'ı içinde user verisi varsa
            else if (json.containsKey('data') &&
                json['data'] is Map<String, dynamic>) {
              userDataToTransform = json['data'];

              // Data içinde token kontrolü
              if (userDataToTransform.containsKey('token') &&
                  userDataToTransform['token'] != null &&
                  userDataToTransform['token'].toString().isNotEmpty) {
                final newToken = userDataToTransform['token'].toString();
                Logger.debug(
                  'Update Profile - Data field içinde yeni token bulundu: ${newToken.substring(0, 20)}...',
                  tag: 'UserService',
                );
                _updateTokenInBackground(newToken);
              }
            }
            // Eğer user field'ı içinde user verisi varsa
            else if (json.containsKey('user') &&
                json['user'] is Map<String, dynamic>) {
              userDataToTransform = json['user'];
            } else {
              Logger.warning(
                'Update Profile - Unexpected response format, creating default user',
                tag: 'UserService',
              );
              return User(
                id: '0',
                name: 'User',
                email: 'user@example.com',
                isVerified: false,
                isOnline: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
            }

            // API formatından model formatına dönüştür
            final transformedData = <String, dynamic>{
              'id':
                  userDataToTransform['userID']?.toString() ??
                  userDataToTransform['id']?.toString() ??
                  '0',
              'name':
                  userDataToTransform['userFullname'] ??
                  userDataToTransform['username'] ??
                  _buildUserName(userDataToTransform),
              'firstName':
                  userDataToTransform['userFirstname'] ??
                  userDataToTransform['firstName'],
              'lastName':
                  userDataToTransform['userLastname'] ??
                  userDataToTransform['lastName'],
              'email':
                  userDataToTransform['userEmail'] ??
                  userDataToTransform['email'] ??
                  'user@example.com',
              'phone':
                  userDataToTransform['userPhone'] ??
                  userDataToTransform['phone'],
              'avatar':
                  userDataToTransform['profilePhoto'] ??
                  userDataToTransform['userAvatar'] ??
                  userDataToTransform['avatar'],

              'totalTrades':
                  userDataToTransform['userTotalTrades'] ??
                  userDataToTransform['totalTrades'] ??
                  0,
              'isVerified':
                  userDataToTransform['isApproved'] ??
                  userDataToTransform['userVerified'] ??
                  userDataToTransform['isVerified'] ??
                  false,
              'isOnline':
                  ((userDataToTransform['userStatus']
                          ?.toString()
                          .toLowerCase() ==
                      'active') ||
                  (userDataToTransform['userOnline'] == true) ||
                  (userDataToTransform['isOnline'] == true)),
              'createdAt': _parseDateTime(
                userDataToTransform['userCreatedAt'] ??
                    userDataToTransform['createdAt'],
              ),
              'updatedAt': _parseDateTime(
                userDataToTransform['userUpdatedAt'] ??
                    userDataToTransform['updatedAt'],
              ),
              'lastSeenAt': _parseDateTime(
                userDataToTransform['userLastSeenAt'] ??
                    userDataToTransform['lastSeenAt'],
              ),
              'birthday':
                  userDataToTransform['userBirthday'] ??
                  userDataToTransform['birthday'],
              'gender':
                  userDataToTransform['userGender'] ??
                  userDataToTransform['gender'],
            };

            return User.fromJson(transformedData);
          }

          throw Exception('Invalid response format');
        },
      );

      print('✅ Update Profile Response: ${response.isSuccess}');
      print('🔍 Response Data: ${response.data}');
      print('🔍 Response Error: ${response.error}');

      return response;
    } catch (e) {
      print('❌ Update Profile Error: $e');
      return ApiResponse<User>.error(ErrorMessages.unknownError);
    }
  }

  /// Kullanıcı hesap bilgilerini günceller
  /// PUT /service/user/update/account
  Future<ApiResponse<User>> updateAccount({
    required String userToken,
    String? userFirstname,
    String? userLastname,
    String? userEmail,
    String? userPhone,
    String? userBirthday,
    int? userGender,
    String? profilePhoto,
    bool? isShowContact,
  }) async {
    try {
      Logger.debug('UPDATE ACCOUNT called', tag: 'UserService');
      Logger.debug(
        'userToken: ${userToken.substring(0, 20)}...',
        tag: 'UserService',
      );
      Logger.debug('userFirstname: $userFirstname', tag: 'UserService');
      Logger.debug('userLastname: $userLastname', tag: 'UserService');
      Logger.debug('userEmail: $userEmail', tag: 'UserService');
      Logger.debug('userPhone: $userPhone', tag: 'UserService');
      Logger.debug('userBirthday: $userBirthday', tag: 'UserService');
      Logger.debug('userGender: $userGender', tag: 'UserService');
      Logger.debug('isShowContact: $isShowContact', tag: 'UserService');
      Logger.debug(
        'profilePhoto: ${profilePhoto != null ? "provided" : "null"}',
        tag: 'UserService',
      );

      // Request body oluştur
      final Map<String, dynamic> body = {'userToken': userToken};

      // Null olmayan alanları ekle
      if (userFirstname != null) body['userFirstname'] = userFirstname;
      if (userLastname != null) body['userLastname'] = userLastname;
      if (userEmail != null) body['userEmail'] = userEmail;
      if (userPhone != null) body['userPhone'] = userPhone;
      if (userBirthday != null) body['userBirthday'] = userBirthday;
      if (userGender != null) body['userGender'] = userGender;
      if (isShowContact != null) body['isShowContact'] = isShowContact;
      if (profilePhoto != null) {
        // Profil fotoğrafını base64 formatında gönder
        body['profilePhoto'] = profilePhoto;
        Logger.debug(
          'Profile photo will be sent as base64',
          tag: 'UserService',
        );
      }

      Logger.debug('Request Body: $body', tag: 'UserService');

      final response = await _httpClient.putWithBasicAuth(
        ApiConstants.updateAccount,
        body: body,
        fromJson: (json) {
          Logger.debug(
            'Update Account fromJson - Raw data: $json',
            tag: 'UserService',
          );

          // Response formatını kontrol et
          if (json is Map<String, dynamic>) {
            // Token güncelleme kontrolü - API'den yeni token gelirse kaydet
            if (json.containsKey('token') &&
                json['token'] != null &&
                json['token'].toString().isNotEmpty) {
              final newToken = json['token'].toString();
              Logger.debug(
                'Update Account - API response\'unda yeni token bulundu: ${newToken.substring(0, 20)}...',
                tag: 'UserService',
              );
              _updateTokenInBackground(newToken);
            }

            // API formatından model formatına dönüştür
            Map<String, dynamic> userDataToTransform;

            // Eğer direkt user verisi gelirse
            if (json.containsKey('id') || json.containsKey('userID')) {
              userDataToTransform = json;
            }
            // Eğer data field'ı içinde user verisi varsa
            else if (json.containsKey('data') &&
                json['data'] is Map<String, dynamic>) {
              userDataToTransform = json['data'];

              // Data içinde token kontrolü
              if (userDataToTransform.containsKey('token') &&
                  userDataToTransform['token'] != null &&
                  userDataToTransform['token'].toString().isNotEmpty) {
                final newToken = userDataToTransform['token'].toString();
                Logger.debug(
                  'Update Account - Data field içinde yeni token bulundu: ${newToken.substring(0, 20)}...',
                  tag: 'UserService',
                );
                _updateTokenInBackground(newToken);
              }
            }
            // Eğer user field'ı içinde user verisi varsa
            else if (json.containsKey('user') &&
                json['user'] is Map<String, dynamic>) {
              userDataToTransform = json['user'];
            }
            // Eğer sadece success mesajı gelirse, parametrelerden user oluştur
            else if (json.containsKey('message') ||
                json.containsKey('success')) {
              Logger.debug(
                'Update Account - Success message format, creating user from parameters',
                tag: 'UserService',
              );
              return User(
                id: '0',
                name: [
                  userFirstname,
                  userLastname,
                ].where((e) => e != null).join(' '),
                firstName: userFirstname,
                lastName: userLastname,
                email: userEmail ?? 'user@example.com',
                phone: userPhone,
                avatar: null,
                isVerified: false,
                isOnline: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                birthday: userBirthday,
                gender: userGender?.toString(),
              );
            } else {
              Logger.warning(
                'Update Account - Unexpected response format, creating default user',
                tag: 'UserService',
              );
              return User(
                id: '0',
                name: [
                  userFirstname,
                  userLastname,
                ].where((e) => e != null).join(' '),
                firstName: userFirstname,
                lastName: userLastname,
                email: userEmail ?? 'user@example.com',
                phone: userPhone,
                avatar: null,
                isVerified: false,
                isOnline: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                birthday: userBirthday,
                gender: userGender?.toString(),
              );
            }

            print(
              '🔍 Update Account - Transforming user data: $userDataToTransform',
            );

            // API formatından model formatına dönüştür
            final transformedData = <String, dynamic>{
              'id':
                  userDataToTransform['userID']?.toString() ??
                  userDataToTransform['id']?.toString() ??
                  '0',
              'name':
                  userDataToTransform['userFullname'] ??
                  userDataToTransform['username'] ??
                  _buildUserName(userDataToTransform),
              'firstName':
                  userDataToTransform['userFirstname'] ??
                  userDataToTransform['firstName'],
              'lastName':
                  userDataToTransform['userLastname'] ??
                  userDataToTransform['lastName'],
              'email':
                  userDataToTransform['userEmail'] ??
                  userDataToTransform['email'] ??
                  'user@example.com',
              'phone':
                  userDataToTransform['userPhone'] ??
                  userDataToTransform['phone'],
              'avatar':
                  userDataToTransform['profilePhoto'] ??
                  userDataToTransform['userAvatar'] ??
                  userDataToTransform['avatar'],

              'isVerified':
                  userDataToTransform['userVerified'] ??
                  userDataToTransform['isVerified'] ??
                  false,
              'isOnline':
                  userDataToTransform['userOnline'] ??
                  userDataToTransform['isOnline'] ??
                  true,
              'createdAt': _parseDateTime(
                userDataToTransform['userCreatedAt'] ??
                    userDataToTransform['createdAt'],
              ),
              'updatedAt': _parseDateTime(
                userDataToTransform['userUpdatedAt'] ??
                    userDataToTransform['updatedAt'],
              ),
              'lastSeenAt': _parseDateTime(
                userDataToTransform['userLastSeenAt'] ??
                    userDataToTransform['lastSeenAt'],
              ),
              'birthday':
                  userDataToTransform['userBirthday'] ??
                  userDataToTransform['birthday'],
              'gender':
                  userDataToTransform['userGender'] ??
                  userDataToTransform['gender'],
            };

            print('🔍 Update Account - Transformed data: $transformedData');

            final user = User.fromJson(transformedData);
            print(
              '🔍 Update Account - Created user: name=${user.name}, firstName=${user.firstName}, lastName=${user.lastName}',
            );

            return User.fromJson(transformedData);
          }

          throw Exception('Invalid response format');
        },
      );

      print('✅ Update Account Response: ${response.isSuccess}');
      print('🔍 Response Data: ${response.data}');
      print('🔍 Response Error: ${response.error}');

      return response;
    } catch (e) {
      print('❌ Update Account Error: $e');
      return ApiResponse<User>.error(ErrorMessages.unknownError);
    }
  }

  /// Kullanıcı profilini alır (PUT version)
  /// PUT /service/user/id
  Future<ApiResponse<User>> getUserProfile({
    required String userToken,
    String? platform,
    String? version,
  }) async {
    try {
      // Platform detection
      final detectedPlatform = platform ?? getPlatform();
      final appVersion = version ?? AppConstants.appVersion;

      print('🔍 GET USER PROFILE (PUT)');
      print(
        '📤 Request Body: {"userToken": "$userToken", "platform": "$detectedPlatform", "version": "$appVersion"}',
      );

      final response = await _httpClient.putWithBasicAuth(
        ApiConstants.userProfile,
        body: {
          'userToken': userToken,
          'platform': detectedPlatform,
          'version': appVersion,
        },
        fromJson: (json) {
          print('🔍 Get Profile fromJson - Raw data: $json');

          // Response formatını kontrol et
          if (json is Map<String, dynamic>) {
            print('🔍 Get Profile - Response is Map<String, dynamic>');

            // Token güncelleme kontrolü - API'den yeni token gelirse kaydet
            if (json.containsKey('token') &&
                json['token'] != null &&
                json['token'].toString().isNotEmpty) {
              final newToken = json['token'].toString();
              print(
                '🔄 API response\'unda yeni token bulundu: ${newToken.substring(0, 20)}...',
              );
              _updateTokenInBackground(newToken);
            }

            // API formatından model formatına dönüştür
            Map<String, dynamic> userDataToTransform;

            // Eğer direkt user verisi gelirse
            if (json.containsKey('id') || json.containsKey('userID')) {
              print('🔍 Get Profile - Direct user data format detected');
              userDataToTransform = json;
            }
            // Eğer data field'ı içinde user verisi varsa
            else if (json.containsKey('data') &&
                json['data'] is Map<String, dynamic>) {
              print('🔍 Get Profile - Data field format detected');
              final dataField = json['data'] as Map<String, dynamic>;

              // Data içinde user field'ı var mı kontrol et
              if (dataField.containsKey('user') &&
                  dataField['user'] is Map<String, dynamic>) {
                print('🔍 Get Profile - User field inside data detected');
                userDataToTransform = dataField['user'] as Map<String, dynamic>;
              } else {
                // Data field'ı direkt user verisi içeriyor
                userDataToTransform = dataField;
              }

              // Data içinde token kontrolü
              if (userDataToTransform.containsKey('userToken') &&
                  userDataToTransform['userToken'] != null &&
                  userDataToTransform['userToken'].toString().isNotEmpty) {
                final newToken = userDataToTransform['userToken'].toString();
                print(
                  '🔄 Data field içinde yeni token bulundu: ${newToken.substring(0, 20)}...',
                );
                _updateTokenInBackground(newToken);
              }
            }
            // Eğer user field'ı içinde user verisi varsa
            else if (json.containsKey('user') &&
                json['user'] is Map<String, dynamic>) {
              print('🔍 Get Profile - User field format detected');
              userDataToTransform = json['user'];
            }
            // Eğer sadece başarı mesajı gelirse (error: false, 200: OK formatı)
            else if (json.containsKey('error') && json['error'] == false) {
              print(
                '⚠️ Get Profile - Success response, checking for nested data structure',
              );
              print('⚠️ Get Profile - Available keys: ${json.keys.toList()}');

              // data.user yapısını kontrol et
              if (json.containsKey('data') &&
                  json['data'] is Map<String, dynamic>) {
                final dataField = json['data'] as Map<String, dynamic>;
                if (dataField.containsKey('user') &&
                    dataField['user'] is Map<String, dynamic>) {
                  print(
                    '🔍 Get Profile - Found user data in data.user structure',
                  );
                  userDataToTransform =
                      dataField['user'] as Map<String, dynamic>;
                } else {
                  print('❌ Get Profile - No user data found in data field');
                  throw Exception(
                    'API returned success but no user data in data field. Response: $json',
                  );
                }
              } else {
                print('❌ Get Profile - No data field found in response');
                throw Exception(
                  'API returned success but no data field. Response: $json',
                );
              }
            } else {
              print(
                '⚠️ Get Profile - Unexpected response format, creating default user',
              );
              print('⚠️ Get Profile - Available keys: ${json.keys.toList()}');
              return User(
                id: '0',
                name: 'Default User',
                email: 'user@example.com',
                isVerified: false,
                isOnline: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
            }

            print(
              '🔍 Get Profile - Transforming user data: $userDataToTransform',
            );
            print(
              '🔍 Get Profile - userFirstname: ${userDataToTransform['userFirstname']}',
            );
            print(
              '🔍 Get Profile - userLastname: ${userDataToTransform['userLastname']}',
            );
            print(
              '🔍 Get Profile - firstName: ${userDataToTransform['firstName']}',
            );
            print(
              '🔍 Get Profile - lastName: ${userDataToTransform['lastName']}',
            );
            print(
              '🔍 Get Profile - userEmail: ${userDataToTransform['userEmail']}',
            );
            print(
              '🔍 Get Profile - Available keys: ${userDataToTransform.keys.toList()}',
            );

            // API formatından model formatına dönüştür
            final transformedData = <String, dynamic>{
              'id':
                  userDataToTransform['userID']?.toString() ??
                  userDataToTransform['id']?.toString() ??
                  '0',
              'name': _buildUserName(userDataToTransform),
              'firstName':
                  userDataToTransform['userFirstname'] ??
                  userDataToTransform['firstName'],
              'lastName':
                  userDataToTransform['userLastname'] ??
                  userDataToTransform['lastName'],
              'email':
                  userDataToTransform['userEmail'] ??
                  userDataToTransform['email'] ??
                  'user@example.com',
              'phone':
                  userDataToTransform['userPhone'] ??
                  userDataToTransform['phone'],
              'avatar':
                  userDataToTransform['profilePhoto'] ??
                  userDataToTransform['avatar'],

              'isVerified': _determineVerificationStatus(userDataToTransform),
              'isOnline':
                  userDataToTransform['userOnline'] ??
                  userDataToTransform['isOnline'] ??
                  true,
              'createdAt': _parseDateTime(
                userDataToTransform['userCreatedAt'] ??
                    userDataToTransform['createdAt'],
              ),
              'updatedAt': _parseDateTime(
                userDataToTransform['userUpdatedAt'] ??
                    userDataToTransform['updatedAt'],
              ),
              'lastSeenAt': _parseDateTime(
                userDataToTransform['userLastSeenAt'] ??
                    userDataToTransform['lastSeenAt'],
              ),
              'birthday':
                  userDataToTransform['userBirthday'] ??
                  userDataToTransform['birthday'],
              'gender':
                  userDataToTransform['userGender'] ??
                  userDataToTransform['gender'],
              // toplamlari ekle (varsa)
              'totalProducts':
                  userDataToTransform['totalProducts'] ??
                  userDataToTransform['productCount'] ??
                  0,
              'totalFavorites':
                  userDataToTransform['totalFavorites'] ??
                  userDataToTransform['favoriteCount'] ??
                  0,
              'token': userToken, // Token'ı User modeline ekle
              'myReviews':
                  userDataToTransform['myReviews'] ??
                  [], // Kullanıcının yaptığı değerlendirmeler
            };

            print('🔍 Get Profile - Transformed data: $transformedData');
            print(
              '🔍 Get Profile - isVerified in transformed data: ${transformedData['isVerified']}',
            );

            try {
              final user = User.fromJson(transformedData);
              print(
                '🔍 Get Profile - Created user: name=${user.name}, firstName=${user.firstName}, lastName=${user.lastName}',
              );
              print('🔍 Get Profile - User isVerified: ${user.isVerified}');
              print('✅ Get Profile - User object created successfully');
              return user;
            } catch (e, stackTrace) {
              print('❌ Get Profile - Error creating User from JSON: $e');
              print('❌ Get Profile - Stack trace: $stackTrace');
              print('❌ Get Profile - Transformed data was: $transformedData');
              rethrow;
            }
          }

          throw Exception('Invalid response format');
        },
      );

      print('✅ Get Profile Response: ${response.isSuccess}');
      print('🔍 Response Data: ${response.data}');
      print('🔍 Response Error: ${response.error}');

      return response;
    } catch (e) {
      print('❌ Get Profile Error: $e');
      return ApiResponse<User>.error(ErrorMessages.unknownError);
    }
  }

  /// Mevcut kullanıcıyı local storage'dan alır
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(AppConstants.userDataKey);

      if (userDataString != null) {
        final userJson = json.decode(userDataString);
        return User.fromJson(userJson);
      }

      return null;
    } catch (e) {
      print('❌ Get Current User Error: $e');
      return null;
    }
  }

  /// Kullanıcı verisini local storage'a kaydeder
  Future<bool> saveCurrentUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = json.encode(user.toJson());
      await prefs.setString(AppConstants.userDataKey, userJson);
      return true;
    } catch (e) {
      print('❌ Save Current User Error: $e');
      return false;
    }
  }

  /// Kullanıcı verisini local storage'dan siler
  Future<bool> clearCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userDataKey);
      return true;
    } catch (e) {
      print('❌ Clear Current User Error: $e');
      return false;
    }
  }

  /// Platform detection (iOS/Android)
  String getPlatform() {
    if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isAndroid) {
      return 'android';
    } else {
      return 'unknown';
    }
  }

  /// User token'ı local storage'dan alır
  Future<String?> getUserToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.userTokenKey);
    } catch (e) {
      print('❌ Get User Token Error: $e');
      return null;
    }
  }

  /// User token'ı local storage'a kaydeder
  Future<bool> saveUserToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userTokenKey, token);
      return true;
    } catch (e) {
      print('❌ Save User Token Error: $e');
      return false;
    }
  }

  /// User token'ı local storage'dan siler
  Future<bool> clearUserToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userTokenKey);
      return true;
    } catch (e) {
      print('❌ Clear User Token Error: $e');
      return false;
    }
  }

  /// Kullanıcı giriş yapmış mı kontrol eder
  Future<bool> isLoggedIn() async {
    final token = await getUserToken();
    final user = await getCurrentUser();
    return token != null && token.isNotEmpty && user != null;
  }

  /// Kullanıcı şifresini günceller
  /// PUT /service/user/update/password
  Future<ApiResponse<Map<String, dynamic>>> updateUserPassword({
    required String userToken,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      print('🔄 UPDATE USER PASSWORD');

      final body = {
        'passToken': userToken,
        'password': newPassword,
        'passwordAgain': newPassword,
      };

      print('📤 Request Body: $body');

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.changePassword,
        body: body,
        useBasicAuth: true,
        fromJson: (json) {
          print('🔍 Update Password fromJson - Raw data: $json');

          // Response formatını kontrol et
          if (json is Map<String, dynamic>) {
            // Token güncelleme kontrolü - API'den yeni token gelirse kaydet
            if (json.containsKey('token') &&
                json['token'] != null &&
                json['token'].toString().isNotEmpty) {
              final newToken = json['token'].toString();
              print(
                '🔄 Update Password - API response\'unda yeni token bulundu: ${newToken.substring(0, 20)}...',
              );
              _updateTokenInBackground(newToken);
            }

            // Data içinde token kontrolü
            if (json.containsKey('data') &&
                json['data'] is Map<String, dynamic>) {
              final data = json['data'] as Map<String, dynamic>;
              if (data.containsKey('token') &&
                  data['token'] != null &&
                  data['token'].toString().isNotEmpty) {
                final newToken = data['token'].toString();
                print(
                  '🔄 Update Password - Data field içinde yeni token bulundu: ${newToken.substring(0, 20)}...',
                );
                _updateTokenInBackground(newToken);
              }
            }

            return json;
          }

          return {'success': true, 'message': 'Password updated successfully'};
        },
      );

      print('✅ Update Password Response: ${response.isSuccess}');
      print('🔍 Response Data: ${response.data}');
      print('🔍 Response Error: ${response.error}');

      return response;
    } catch (e) {
      print('❌ Update Password Error: $e');
      return ApiResponse<Map<String, dynamic>>.error(
        ErrorMessages.unknownError,
      );
    }
  }

  /// Kullanıcı hesabını siler
  /// DELETE /service/user/delete
  Future<ApiResponse<Map<String, dynamic>>> deleteUserAccount({
    required String userToken,
    required String password,
  }) async {
    try {
      print('🗑️ DELETE USER ACCOUNT');

      final body = {'userToken': userToken, 'password': password};

      print('📤 Request Body: $body');

      final response = await _httpClient.putWithBasicAuth(
        ApiConstants.deleteUser,
        body: body,
        fromJson: (json) {
          print('🔍 Delete User fromJson - Raw data: $json');

          // Response formatını kontrol et
          if (json is Map<String, dynamic>) {
            // Token güncelleme kontrolü - API'den yeni token gelirse kaydet
            if (json.containsKey('token') &&
                json['token'] != null &&
                json['token'].toString().isNotEmpty) {
              final newToken = json['token'].toString();
              print(
                '🔄 Delete User - API response\'unda yeni token bulundu: ${newToken.substring(0, 20)}...',
              );
              _updateTokenInBackground(newToken);
            }

            // Data içinde token kontrolü
            if (json.containsKey('data') &&
                json['data'] is Map<String, dynamic>) {
              final data = json['data'] as Map<String, dynamic>;
              if (data.containsKey('token') &&
                  data['token'] != null &&
                  data['token'].toString().isNotEmpty) {
                final newToken = data['token'].toString();
                print(
                  '🔄 Delete User - Data field içinde yeni token bulundu: ${newToken.substring(0, 20)}...',
                );
                _updateTokenInBackground(newToken);
              }
            }

            return json;
          }

          return {'success': true, 'message': 'Account deleted successfully'};
        },
      );

      print('✅ Delete User Response: ${response.isSuccess}');
      print('🔍 Response Data: ${response.data}');
      print('🔍 Response Error: ${response.error}');

      return response;
    } catch (e) {
      print('❌ Delete User Error: $e');
      return ApiResponse<Map<String, dynamic>>.error(
        ErrorMessages.unknownError,
      );
    }
  }

  /// Kullanıcı profil detaylarını alır
  /// GET /service/user/account/{userId}/profileDetail
  /// userToken artık opsiyonel - backend'de token zorunluluğu kaldırıldı
  Future<ApiResponse<UserProfileDetail>> getUserProfileDetail({
    String? userToken,
    required int userId,
  }) async {
    try {
      print('🔍 GET USER PROFILE DETAIL');
      print(
        '📤 User ID: $userId, User Token: ${userToken != null ? "${userToken.substring(0, 20)}..." : "null"}',
      );

      // Token varsa query parameter olarak ekle, yoksa sadece Basic Auth kullan
      final endpoint = userToken != null && userToken.isNotEmpty
          ? '${ApiConstants.userProfileDetail}/$userId/profileDetail?userToken=$userToken'
          : '${ApiConstants.userProfileDetail}/$userId/profileDetail';

      final response = await _httpClient.getWithBasicAuth(
        endpoint,
        fromJson: (json) {
          print('🔍 Get Profile Detail fromJson - Raw data: $json');

          // Response formatını kontrol et
          if (json is Map<String, dynamic>) {
            // Eğer data field'ı içinde profil detayları varsa
            if (json.containsKey('data') &&
                json['data'] is Map<String, dynamic>) {
              print('🔍 Get Profile Detail - Data field format detected');
              final dataField = json['data'] as Map<String, dynamic>;

              // Token güncelleme kontrolü
              if (dataField.containsKey('token') &&
                  dataField['token'] != null &&
                  dataField['token'].toString().isNotEmpty) {
                final newToken = dataField['token'].toString();
                print(
                  '🔄 Profile Detail - Data field içinde yeni token bulundu: ${newToken.substring(0, 20)}...',
                );
                _updateTokenInBackground(newToken);
              }

              // Products array'ini logla
              if (dataField.containsKey('products') &&
                  dataField['products'] is List) {
                final products = dataField['products'] as List;
                print(
                  '🔍 Get Profile Detail - Products count: ${products.length}',
                );
              }

              // Reviews array'ini logla
              if (dataField.containsKey('reviews') &&
                  dataField['reviews'] is List) {
                final reviews = dataField['reviews'] as List;
                print(
                  '🔍 Get Profile Detail - Reviews count: ${reviews.length}',
                );
              }

              // MyReviews array'ini logla
              if (dataField.containsKey('myReviews') &&
                  dataField['myReviews'] is List) {
                final myReviews = dataField['myReviews'] as List;
                print(
                  '🔍 Get Profile Detail - MyReviews count: ${myReviews.length}',
                );
              }

              return UserProfileDetail.fromJson(dataField);
            }
            // Eğer direkt profil detayları gelirse
            else if (json.containsKey('userID') ||
                json.containsKey('userFullname')) {
              print(
                '🔍 Get Profile Detail - Direct profile data format detected',
              );

              // Products array'ini logla
              if (json.containsKey('products') && json['products'] is List) {
                final products = json['products'] as List;
                print(
                  '🔍 Get Profile Detail - Products count: ${products.length}',
                );
              }

              // Reviews array'ini detaylı logla
              if (json.containsKey('reviews') && json['reviews'] is List) {
                final reviews = json['reviews'] as List;
                print(
                  '🔍 Get Profile Detail - Reviews count: ${reviews.length}',
                );
                for (int i = 0; i < reviews.length && i < 3; i++) {
                  final review = reviews[i];
                  print('🔍 Review $i: $review');
                }
              }

              // MyReviews array'ini detaylı logla
              if (json.containsKey('myReviews') && json['myReviews'] is List) {
                final myReviews = json['myReviews'] as List;
                print(
                  '🔍 Get Profile Detail - MyReviews count: ${myReviews.length}',
                );
                print('🔍 Get Profile Detail - MyReviews raw data: $myReviews');
                for (int i = 0; i < myReviews.length && i < 3; i++) {
                  final review = myReviews[i];
                  print('🔍 MyReview $i: $review');
                  if (review is Map<String, dynamic>) {
                    print('🔍 MyReview $i keys: ${review.keys.toList()}');
                    print('🔍 MyReview $i reviewID: ${review['reviewID']}');
                    print(
                      '🔍 MyReview $i revieweeName: ${review['revieweeName']}',
                    );
                    print(
                      '🔍 MyReview $i revieweeImage: ${review['revieweeImage']}',
                    );
                    print('🔍 MyReview $i rating: ${review['rating']}');
                    print('🔍 MyReview $i comment: ${review['comment']}');
                    print('🔍 MyReview $i reviewDate: ${review['reviewDate']}');
                  }
                }
              } else {
                print(
                  '⚠️ Get Profile Detail - myReviews field not found or not a list',
                );
                print(
                  '⚠️ Get Profile Detail - Available keys: ${json.keys.toList()}',
                );
              }

              return UserProfileDetail.fromJson(json);
            } else {
              print('⚠️ Get Profile Detail - Unexpected response format');
              print(
                '⚠️ Get Profile Detail - Available keys: ${json.keys.toList()}',
              );
              throw Exception(
                'API returned unexpected format. Response: $json',
              );
            }
          }

          throw Exception('Invalid response format');
        },
      );

      print('✅ Get Profile Detail Response: ${response.isSuccess}');
      print('🔍 Response Data: ${response.data}');
      print('🔍 Response Error: ${response.error}');

      return response;
    } catch (e) {
      print('❌ Get Profile Detail Error: $e');
      return ApiResponse<UserProfileDetail>.error(ErrorMessages.userNotFound);
    }
  }

  /// Kullanıcı bilgilerini ID ile alır
  /// GET /service/user/id
  Future<ApiResponse<User>> getUserById(String userId) async {
    try {
      print('🔍 GET USER BY ID');
      print('📤 User ID: $userId');

      final response = await _httpClient.getWithBasicAuth(
        '${ApiConstants.userProfile}/$userId',
        fromJson: (json) {
          print('🔍 Get User By ID fromJson - Raw data: $json');

          // Response formatını kontrol et
          if (json is Map<String, dynamic>) {
            // API formatından model formatına dönüştür
            Map<String, dynamic> userDataToTransform;

            // Eğer direkt user verisi gelirse
            if (json.containsKey('id') || json.containsKey('userID')) {
              print('🔍 Get User By ID - Direct user data format detected');
              userDataToTransform = json;
            }
            // Eğer data field'ı içinde user verisi varsa
            else if (json.containsKey('data') &&
                json['data'] is Map<String, dynamic>) {
              print('🔍 Get User By ID - Data field format detected');
              userDataToTransform = json['data'];
            }
            // Eğer user field'ı içinde user verisi varsa
            else if (json.containsKey('user') &&
                json['user'] is Map<String, dynamic>) {
              print('🔍 Get User By ID - User field format detected');
              userDataToTransform = json['user'];
            } else {
              print(
                '⚠️ Get User By ID - Unexpected response format, creating default user',
              );
              print(
                '⚠️ Get User By ID - Available keys: ${json.keys.toList()}',
              );
              return User(
                id: userId,
                name: 'Kullanıcı',
                email: 'user@example.com',
                isVerified: false,
                isOnline: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
            }

            // API formatından model formatına dönüştür
            final transformedData = <String, dynamic>{
              'id':
                  userDataToTransform['userID']?.toString() ??
                  userDataToTransform['id']?.toString() ??
                  userId,
              'name': _buildUserName(userDataToTransform),
              'firstName':
                  userDataToTransform['userFirstname'] ??
                  userDataToTransform['firstName'],
              'lastName':
                  userDataToTransform['userLastname'] ??
                  userDataToTransform['lastName'],
              'email':
                  userDataToTransform['userEmail'] ??
                  userDataToTransform['email'] ??
                  'user@example.com',
              'phone':
                  userDataToTransform['userPhone'] ??
                  userDataToTransform['phone'],
              'avatar':
                  userDataToTransform['userAvatar'] ??
                  userDataToTransform['avatar'],

              'isVerified':
                  userDataToTransform['userVerified'] ??
                  userDataToTransform['isVerified'] ??
                  false,
              'isOnline':
                  userDataToTransform['userOnline'] ??
                  userDataToTransform['isOnline'] ??
                  true,
              'createdAt': _parseDateTime(
                userDataToTransform['userCreatedAt'] ??
                    userDataToTransform['createdAt'],
              ),
              'updatedAt': _parseDateTime(
                userDataToTransform['userUpdatedAt'] ??
                    userDataToTransform['updatedAt'],
              ),
              'lastSeenAt': _parseDateTime(
                userDataToTransform['userLastSeenAt'] ??
                    userDataToTransform['lastSeenAt'],
              ),
              'birthday':
                  userDataToTransform['userBirthday'] ??
                  userDataToTransform['birthday'],
              'gender':
                  userDataToTransform['userGender'] ??
                  userDataToTransform['gender'],
              'myReviews':
                  userDataToTransform['myReviews'] ??
                  [], // Kullanıcının yaptığı değerlendirmeler
            };

            print('🔍 Get User By ID - Transformed data: $transformedData');

            final user = User.fromJson(transformedData);
            print('✅ Get User By ID - User created: ${user.id} - ${user.name}');
            return user;
          }

          throw Exception('Invalid response format');
        },
      );

      print('✅ Get User By ID Response: ${response.isSuccess}');
      print('🔍 Response Data: ${response.data}');
      print('🔍 Response Error: ${response.error}');

      return response;
    } catch (e) {
      print('❌ Get User By ID Error: $e');
      return ApiResponse<User>.error(ErrorMessages.userNotFound);
    }
  }

  /// Arama geçmişini getirir
  Future<ApiResponse<SearchHistoryResponse>> getSearchHistory({
    required int userId,
  }) async {
    try {
      final endpoint =
          '${ApiConstants.searchHistoryBase}/$userId/searchHistory';
      Logger.debug('GET Search History: $endpoint', tag: 'UserService');
      final response = await _httpClient
          .getWithBasicAuth<SearchHistoryResponse>(
            endpoint,
            fromJson: (json) => SearchHistoryResponse.fromJson(json),
          );
      return response;
    } catch (e) {
      Logger.error('❌ getSearchHistory error: $e', tag: 'UserService');
      return ApiResponse<SearchHistoryResponse>.error(
        ErrorMessages.unknownError,
      );
    }
  }

  /// Arama geçmişini temizler
  /// DELETE /service/user/account/{userId}/searchHistoryClear
  Future<ApiResponse<bool>> clearSearchHistory({
    required int userId,
  }) async {
    try {
      final endpoint =
          '${ApiConstants.searchHistoryBase}/$userId/searchHistoryClear';
      Logger.debug('DELETE Search History Clear: $endpoint', tag: 'UserService');
      final response = await _httpClient.deleteWithBasicAuth<bool>(
        endpoint,
        fromJson: (json) {
          // Esnek başarı kontrolü
          if (json is Map<String, dynamic>) {
            if (json['success'] == true || json['cleared'] == true) {
              return true;
            }
          } else if (json is bool) {
            return json;
          }
          // Body boş ya da beklenmedik ise bile başarılı say
          return true;
        },
      );
      return response;
    } catch (e) {
      Logger.error('❌ clearSearchHistory error: $e', tag: 'UserService');
      return ApiResponse<bool>.error(ErrorMessages.unknownError);
    }
  }

  /// User service'ini test eder
  Future<bool> testUserService() async {
    try {
      final token = await getUserToken();
      if (token == null) {
        print('❌ Test User Service: No token found');
        return false;
      }

      final response = await getUserProfile(userToken: token);
      return response.isSuccess;
    } catch (e) {
      print('❌ Test User Service Error: $e');
      return false;
    }
  }

  /// Kullanıcı hesabını siler (yeni endpoint)
  /// DELETE /service/user/account/delete
  Future<ApiResponse<bool>> deleteUserAccountNew({
    required String userToken,
  }) async {
    try {
      print('🗑️ DELETE USER ACCOUNT (NEW ENDPOINT)');
      print('📤 User Token: ${userToken.substring(0, 20)}...');

      final response = await _httpClient.deleteWithBasicAuth<bool>(
        '/service/user/account/delete',
        body: {'userToken': userToken},
        fromJson: (json) {
          print('🔍 Delete Account fromJson - Raw data: $json');

          // API'den gelen response'u kontrol et
          if (json is Map<String, dynamic>) {
            // Başarı durumunu kontrol et
            if (json.containsKey('success') && json['success'] == true) {
              return true;
            }
            // Error durumunu kontrol et
            if (json.containsKey('error') && json['error'] == true) {
              throw Exception(
                json['message'] ?? 'Hesap silme işlemi başarısız',
              );
            }
          }

          // Direkt bool değer gelirse
          if (json is bool) {
            return json;
          }

          // Varsayılan olarak başarılı kabul et
          return true;
        },
      );

      print('✅ Delete Account Response: ${response.isSuccess}');
      print('🔍 Response Data: ${response.data}');
      print('🔍 Response Error: ${response.error}');

      return response;
    } catch (e) {
      print('❌ Delete Account Error: $e');
      return ApiResponse<bool>.error(
        'Hesap silme işlemi sırasında hata oluştu: $e',
      );
    }
  }

  /// Token'ı arka planda günceller (async olarak)
  void _updateTokenInBackground(String newToken) {
    // Arka planda token güncelleme işlemini başlat
    Future.microtask(() async {
      try {
        if (newToken.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          final currentToken = prefs.getString(AppConstants.userTokenKey);

          // Token farklıysa veya yoksa güncelle
          if (currentToken != newToken) {
            print(
              '🔄 UserService - Token güncelleniyor: ${newToken.substring(0, 20)}...',
            );
            await prefs.setString(AppConstants.userTokenKey, newToken);
            print('✅ UserService - Token başarıyla güncellendi');
          } else {
            print('ℹ️ UserService - Token zaten güncel, güncelleme gerekmiyor');
          }
        } else {
          print('⚠️ UserService - Boş token, güncelleme yapılmadı');
        }
      } catch (e) {
        print('❌ UserService - Token güncelleme hatası: $e');
      }
    });
  }

  /// Kullanıcı adını oluşturur
  String _buildUserName(Map<String, dynamic> userData) {
    // Önce userFullname'i kontrol et
    final fullName = userData['userFullname'] ?? userData['fullName'];
    if (fullName != null && fullName.toString().trim().isNotEmpty) {
      return fullName.toString().trim();
    }

    // Sonra firstName ve lastName'i kontrol et
    final firstName = userData['userFirstname'] ?? userData['firstName'];
    final lastName = userData['userLastname'] ?? userData['lastName'];

    if (firstName != null &&
        firstName.toString().trim().isNotEmpty &&
        lastName != null &&
        lastName.toString().trim().isNotEmpty) {
      return '${firstName.toString().trim()} ${lastName.toString().trim()}';
    } else if (firstName != null && firstName.toString().trim().isNotEmpty) {
      return firstName.toString().trim();
    } else if (lastName != null && lastName.toString().trim().isNotEmpty) {
      return lastName.toString().trim();
    } else {
      return userData['userName'] ?? userData['name'] ?? 'Kullanıcı';
    }
  }

  /// DateTime parse eder
  String _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now().toIso8601String();
    } else if (value is String) {
      try {
        DateTime.parse(value);
        return value;
      } catch (e) {
        return DateTime.now().toIso8601String();
      }
    } else if (value is DateTime) {
      return value.toIso8601String();
    }
    return DateTime.now().toIso8601String();
  }

  /// Kullanıcının doğrulama durumunu belirler
  bool _determineVerificationStatus(Map<String, dynamic> userData) {
    // isApproved alanı varsa onu öncelikli olarak kullan
    if (userData.containsKey('isApproved')) {
      final isApproved = userData['isApproved'];
      print(
        '🔍 Verification Status - isApproved: $isApproved (type: ${isApproved.runtimeType})',
      );
      return isApproved == true;
    }

    // userVerified alanı varsa onu kullan
    if (userData.containsKey('userVerified')) {
      final userVerified = userData['userVerified'];
      print(
        '🔍 Verification Status - userVerified: $userVerified (type: ${userVerified.runtimeType})',
      );
      return userVerified == true;
    }

    // userStatus alanı varsa onu kontrol et
    if (userData.containsKey('userStatus')) {
      final status = userData['userStatus'].toString().toLowerCase();
      print('🔍 Verification Status - userStatus: $status');

      // Aktif durumlar
      if (status == 'activated' || status == 'active' || status == 'verified') {
        return true;
      }

      // Aktif olmayan durumlar
      if (status == 'not_activated' ||
          status == 'inactive' ||
          status == 'pending') {
        return false;
      }
    }

    // Varsayılan olarak doğrulanmamış kabul et
    print(
      '🔍 Verification Status - Default: false (no verification fields found)',
    );
    return false;
  }
}
