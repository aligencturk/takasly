import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/http_client.dart';
import '../core/constants.dart';
import '../models/user.dart';
import '../models/user_profile_detail.dart';
import '../models/live_search.dart';
import '../models/user_block.dart';
import '../models/blocked_user.dart';
import '../utils/logger.dart';

class UserService {
  final HttpClient _httpClient = HttpClient();

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

      final response = await _httpClient.putWithBasicAuth(
        ApiConstants.userProfile,
        body: {
          'userToken': userToken,
          'platform': detectedPlatform,
          'version': appVersion,
        },
        fromJson: (json) {
          // Response formatını kontrol et
          if (json is Map<String, dynamic>) {
            // Token güncelleme kontrolü - API'den yeni token gelirse kaydet
            if (json.containsKey('token') &&
                json['token'] != null &&
                json['token'].toString().isNotEmpty) {
              final newToken = json['token'].toString();
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
                _updateTokenInBackground(newToken);
              }
            }
            // Eğer user field'ı içinde user verisi varsa
            else if (json.containsKey('user') &&
                json['user'] is Map<String, dynamic>) {
              userDataToTransform = json['user'];
            } else {
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

      return response;
    } catch (e) {
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
      }

      final response = await _httpClient.putWithBasicAuth(
        ApiConstants.updateAccount,
        body: body,
        fromJson: (json) {
          // Response formatını kontrol et
          if (json is Map<String, dynamic>) {
            // Token güncelleme kontrolü - API'den yeni token gelirse kaydet
            if (json.containsKey('token') &&
                json['token'] != null &&
                json['token'].toString().isNotEmpty) {
              final newToken = json['token'].toString();
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

            return User.fromJson(transformedData);
          }

          throw Exception('Invalid response format');
        },
      );

      return response;
    } catch (e) {
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

      final response = await _httpClient.putWithBasicAuth(
        ApiConstants.userProfile,
        body: {
          'userToken': userToken,
          'platform': detectedPlatform,
          'version': appVersion,
        },
        fromJson: (json) {
          // Response formatını kontrol et
          if (json is Map<String, dynamic>) {
            // Token güncelleme kontrolü - API'den yeni token gelirse kaydet
            if (json.containsKey('token') &&
                json['token'] != null &&
                json['token'].toString().isNotEmpty) {
              final newToken = json['token'].toString();
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
              final dataField = json['data'] as Map<String, dynamic>;

              // Data içinde user field'ı var mı kontrol et
              if (dataField.containsKey('user') &&
                  dataField['user'] is Map<String, dynamic>) {
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
                _updateTokenInBackground(newToken);
              }
            }
            // Eğer user field'ı içinde user verisi varsa
            else if (json.containsKey('user') &&
                json['user'] is Map<String, dynamic>) {
              userDataToTransform = json['user'];
            }
            // Eğer sadece başarı mesajı gelirse (error: false, 200: OK formatı)
            else if (json.containsKey('error') && json['error'] == false) {
              // data.user yapısını kontrol et
              if (json.containsKey('data') &&
                  json['data'] is Map<String, dynamic>) {
                final dataField = json['data'] as Map<String, dynamic>;
                if (dataField.containsKey('user') &&
                    dataField['user'] is Map<String, dynamic>) {
                  userDataToTransform =
                      dataField['user'] as Map<String, dynamic>;
                } else {
                  throw Exception(
                    'API returned success but no user data in data field. Response: $json',
                  );
                }
              } else {
                throw Exception(
                  'API returned success but no data field. Response: $json',
                );
              }
            } else {
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

            try {
              final user = User.fromJson(transformedData);
              return user;
            } catch (e, stackTrace) {
              rethrow;
            }
          }

          throw Exception('Invalid response format');
        },
      );

      return response;
    } catch (e) {
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
      final body = {
        'passToken': userToken,
        'password': newPassword,
        'passwordAgain': newPassword,
      };

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.changePassword,
        body: body,
        useBasicAuth: true,
        fromJson: (json) {
          // Response formatını kontrol et
          if (json is Map<String, dynamic>) {
            // Token güncelleme kontrolü - API'den yeni token gelirse kaydet
            if (json.containsKey('token') &&
                json['token'] != null &&
                json['token'].toString().isNotEmpty) {
              final newToken = json['token'].toString();
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
                _updateTokenInBackground(newToken);
              }
            }

            return json;
          }

          return {'success': true, 'message': 'Password updated successfully'};
        },
      );

      return response;
    } catch (e) {
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
      final body = {'userToken': userToken, 'password': password};

      final response = await _httpClient.putWithBasicAuth(
        ApiConstants.deleteUser,
        body: body,
        fromJson: (json) {
          // Response formatını kontrol et
          if (json is Map<String, dynamic>) {
            // Token güncelleme kontrolü - API'den yeni token gelirse kaydet
            if (json.containsKey('token') &&
                json['token'] != null &&
                json['token'].toString().isNotEmpty) {
              final newToken = json['token'].toString();
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
                _updateTokenInBackground(newToken);
              }
            }

            return json;
          }

          return {'success': true, 'message': 'Account deleted successfully'};
        },
      );

      return response;
    } catch (e) {
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
      // Token varsa query parameter olarak ekle, yoksa sadece Basic Auth kullan
      final endpoint = userToken != null && userToken.isNotEmpty
          ? '${ApiConstants.userProfileDetail}/$userId/profileDetail?userToken=$userToken'
          : '${ApiConstants.userProfileDetail}/$userId/profileDetail';

      final response = await _httpClient.getWithBasicAuth(
        endpoint,
        fromJson: (json) {
          // Response formatını kontrol et
          if (json is Map<String, dynamic>) {
            // Eğer data field'ı içinde profil detayları varsa
            if (json.containsKey('data') &&
                json['data'] is Map<String, dynamic>) {
              final dataField = json['data'] as Map<String, dynamic>;

              // Token güncelleme kontrolü
              if (dataField.containsKey('token') &&
                  dataField['token'] != null &&
                  dataField['token'].toString().isNotEmpty) {
                final newToken = dataField['token'].toString();
                _updateTokenInBackground(newToken);
              }

              return UserProfileDetail.fromJson(dataField);
            }
            // Eğer direkt profil detayları gelirse
            else if (json.containsKey('userID') ||
                json.containsKey('userFullname')) {
              return UserProfileDetail.fromJson(json);
            } else {
              throw Exception(
                'API returned unexpected format. Response: $json',
              );
            }
          }

          throw Exception('Invalid response format');
        },
      );

      return response;
    } catch (e) {
      return ApiResponse<UserProfileDetail>.error(ErrorMessages.userNotFound);
    }
  }

  /// Kullanıcı bilgilerini ID ile alır
  /// GET /service/user/id
  Future<ApiResponse<User>> getUserById(String userId) async {
    try {
      final response = await _httpClient.getWithBasicAuth(
        '${ApiConstants.userProfile}/$userId',
        fromJson: (json) {
          // Response formatını kontrol et
          if (json is Map<String, dynamic>) {
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
            }
            // Eğer user field'ı içinde user verisi varsa
            else if (json.containsKey('user') &&
                json['user'] is Map<String, dynamic>) {
              userDataToTransform = json['user'];
            } else {
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

            final user = User.fromJson(transformedData);
            return user;
          }

          throw Exception('Invalid response format');
        },
      );

      return response;
    } catch (e) {
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

      final response = await _httpClient
          .getWithBasicAuth<SearchHistoryResponse>(
            endpoint,
            fromJson: (json) => SearchHistoryResponse.fromJson(json),
          );

      return response;
    } catch (e) {
      return ApiResponse<SearchHistoryResponse>.error(
        ErrorMessages.unknownError,
      );
    }
  }

  /// Arama geçmişini temizler
  /// DELETE /service/user/account/{userId}/searchHistoryClear
  Future<ApiResponse<bool>> clearSearchHistory({required int userId}) async {
    try {
      final endpoint =
          '${ApiConstants.searchHistoryBase}/$userId/searchHistoryClear';
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
      return ApiResponse<bool>.error(ErrorMessages.unknownError);
    }
  }

  /// User service'ini test eder
  Future<bool> testUserService() async {
    try {
      final token = await getUserToken();
      if (token == null) {
        return false;
      }

      final response = await getUserProfile(userToken: token);
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  /// Kullanıcı hesabını siler (yeni endpoint)
  /// DELETE /service/user/account/delete
  Future<ApiResponse<bool>> deleteUserAccountNew({
    required String userToken,
  }) async {
    try {
      final response = await _httpClient.deleteWithBasicAuth<bool>(
        '/service/user/account/delete',
        body: {'userToken': userToken},
        fromJson: (json) {
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

      return response;
    } catch (e) {
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
            await prefs.setString(AppConstants.userTokenKey, newToken);
          }
        }
      } catch (e) {
        // Token güncelleme hatası sessizce geç
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
      return isApproved == true;
    }

    // userVerified alanı varsa onu kullan
    if (userData.containsKey('userVerified')) {
      final userVerified = userData['userVerified'];
      return userVerified == true;
    }

    // userStatus alanı varsa onu kontrol et
    if (userData.containsKey('userStatus')) {
      final status = userData['userStatus'].toString().toLowerCase();

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
    return false;
  }

  /// Kullanıcıyı engeller
  /// POST /service/user/account/userBlocked
  Future<ApiResponse<UserBlock>> blockUser({
    required String userToken,
    required int blockedUserID,
    String? reason,
  }) async {
    try {
      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.userBlocked,
        body: {
          'userToken': userToken,
          'blockedUserID': blockedUserID,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
        useBasicAuth: true,
        fromJson: (json) {
          // Response formatını kontrol et
          if (json is Map<String, dynamic>) {
            // Data field'ı içinde user block verisi varsa
            if (json.containsKey('data') &&
                json['data'] is Map<String, dynamic>) {
              final data = json['data'];
              return UserBlock(
                blockedUserID: blockedUserID,
                reason: reason,
                blockedAt: DateTime.now(),
                message: data['message']?.toString(),
              );
            }
            // Direkt user block verisi gelirse
            else if (json.containsKey('message')) {
              return UserBlock(
                blockedUserID: blockedUserID,
                reason: reason,
                blockedAt: DateTime.now(),
                message: json['message']?.toString(),
              );
            }
          }

          // Varsayılan response
          return UserBlock(
            blockedUserID: blockedUserID,
            reason: reason,
            blockedAt: DateTime.now(),
            message: 'Kullanıcı başarıyla engellendi.',
          );
        },
      );

      return response;
    } catch (e) {
      return ApiResponse<UserBlock>.error(ErrorMessages.unknownError);
    }
  }

  /// Kullanıcı engelini kaldırır
  /// POST /service/user/account/userUnBlocked
  Future<ApiResponse<UserBlock>> unblockUser({
    required String userToken,
    required int blockedUserID,
  }) async {
    try {
      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.userUnBlocked,
        body: {'userToken': userToken, 'blockedUserID': blockedUserID},
        useBasicAuth: true,
        fromJson: (json) {
          // Response formatını kontrol et
          if (json is Map<String, dynamic>) {
            // Data field'ı içinde user block verisi varsa
            if (json.containsKey('data') &&
                json['data'] is Map<String, dynamic>) {
              final data = json['data'];
              return UserBlock(
                blockedUserID: blockedUserID,
                reason: null,
                blockedAt: null,
                message: data['message']?.toString(),
              );
            }
            // Direkt user block verisi gelirse
            else if (json.containsKey('message')) {
              return UserBlock(
                blockedUserID: blockedUserID,
                reason: null,
                blockedAt: null,
                message: json['message']?.toString(),
              );
            }
          }

          // Varsayılan response
          return UserBlock(
            blockedUserID: blockedUserID,
            reason: null,
            blockedAt: null,
            message: 'Kullanıcı engeli başarıyla kaldırıldı.',
          );
        },
      );

      return response;
    } catch (e) {
      return ApiResponse<UserBlock>.error(ErrorMessages.unknownError);
    }
  }

  /// Engellenen kullanıcıları getirir
  /// GET /service/user/account/{userId}/blockedUsers
  Future<ApiResponse<List<BlockedUser>>> getBlockedUsers({
    required String userToken,
    required int userId,
  }) async {
    try {
      final endpoint = ApiConstants.blockedUsers.replaceAll(
        '{userId}',
        userId.toString(),
      );
      final response = await _httpClient.getWithBasicAuth(
        endpoint,
        fromJson: (json) {
          // Response formatını kontrol et
          if (json is Map<String, dynamic>) {
            // Data field'ı içinde users array varsa
            if (json.containsKey('data') &&
                json['data'] is Map<String, dynamic>) {
              final data = json['data'];
              if (data.containsKey('users') && data['users'] is List) {
                final usersList = data['users'] as List;
                // Her user objesi bir BlockedUser'a dönüştür
                return usersList.map((user) {
                  if (user is Map<String, dynamic>) {
                    try {
                      return BlockedUser.fromJson(user);
                    } catch (e) {
                      return null;
                    }
                  }
                  return null;
                }).where((user) => user != null).cast<BlockedUser>().toList();
              }
            }
          }

          // Varsayılan response
          return <BlockedUser>[];
        },
      );

      return response;
    } catch (e) {
      return ApiResponse<List<BlockedUser>>.error(ErrorMessages.unknownError);
    }
  }
}
