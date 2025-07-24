import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/http_client.dart';
import '../core/constants.dart';
import '../models/user.dart';

class UserService {
  final HttpClient _httpClient = HttpClient();
  static const String _tag = 'UserService';

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

      print('🔄 UPDATE USER PROFILE');
      print(
        '📤 Request Body: {"userToken": "$userToken", "platform": "$detectedPlatform", "version": "$appVersion"}',
      );

      final response = await _httpClient.put(
        ApiConstants.userProfile,
        body: {
          'userToken': userToken,
          'platform': detectedPlatform,
          'version': appVersion,
        },
        fromJson: (json) {
          print('🔍 Update Profile fromJson - Raw data: $json');

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
              print(
                '⚠️ Update Profile - Unexpected response format, creating default user',
              );
              return User(
                id: '0',
                name: 'User',
                email: 'user@example.com',
                rating: 0.0,
                totalTrades: 0,
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
                  userDataToTransform['userAvatar'] ??
                  userDataToTransform['avatar'],
              'bio':
                  userDataToTransform['userBio'] ?? userDataToTransform['bio'],
              'rating':
                  (userDataToTransform['userRating'] ??
                          userDataToTransform['rating'] ??
                          0.0)
                      .toDouble(),
              'totalTrades':
                  userDataToTransform['userTotalTrades'] ??
                  userDataToTransform['totalTrades'] ??
                  0,
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
  }) async {
    try {
      print('🔄 UPDATE ACCOUNT');

      // Request body oluştur
      final Map<String, dynamic> body = {'userToken': userToken};

      // Null olmayan alanları ekle
      if (userFirstname != null) body['userFirstname'] = userFirstname;
      if (userLastname != null) body['userLastname'] = userLastname;
      if (userEmail != null) body['userEmail'] = userEmail;
      if (userPhone != null) body['userPhone'] = userPhone;
      if (userBirthday != null) body['userBirthday'] = userBirthday;
      if (userGender != null) body['userGender'] = userGender;
      if (profilePhoto != null) body['profilePhoto'] = profilePhoto;

      print('📤 Request Body: $body');

      final response = await _httpClient.put(
        ApiConstants.updateAccount,
        body: body,
        fromJson: (json) {
          print('🔍 Update Account fromJson - Raw data: $json');

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
            }
            // Eğer sadece success mesajı gelirse, parametrelerden user oluştur
            else if (json.containsKey('message') ||
                json.containsKey('success')) {
              print(
                '🔍 Update Account - Success message format, creating user from parameters',
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
                bio: null,
                location: null,
                rating: 0.0,
                totalTrades: 0,
                isVerified: false,
                isOnline: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                birthday: userBirthday,
                gender: userGender,
              );
            } else {
              print(
                '⚠️ Update Account - Unexpected response format, creating default user',
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
                bio: null,
                location: null,
                rating: 0.0,
                totalTrades: 0,
                isVerified: false,
                isOnline: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                birthday: userBirthday,
                gender: userGender,
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
                  userDataToTransform['userAvatar'] ??
                  userDataToTransform['avatar'],
              'bio':
                  userDataToTransform['userBio'] ?? userDataToTransform['bio'],
              'rating':
                  (userDataToTransform['userRating'] ??
                          userDataToTransform['rating'] ??
                          0.0)
                      .toDouble(),
              'totalTrades':
                  userDataToTransform['userTotalTrades'] ??
                  userDataToTransform['totalTrades'] ??
                  0,
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

      print('✅ Update Account Response: ${response.isSuccess}');
      print('🔍 Response Data: ${response.data}');
      print('🔍 Response Error: ${response.error}');

      return response;
    } catch (e) {
      print('❌ Update Account Error: $e');
      return ApiResponse<User>.error(ErrorMessages.unknownError);
    }
  }

  /// Kullanıcı profilini alır (GET version)
  /// GET /service/user/id
  Future<ApiResponse<User>> getUserProfile({
    required String userToken,
    String? platform,
    String? version,
  }) async {
    try {
      // Platform detection
      final detectedPlatform = platform ?? getPlatform();
      final appVersion = version ?? AppConstants.appVersion;

      print('🔍 GET USER PROFILE');
      print(
        '📤 Query Params: {"userToken": "$userToken", "platform": "$detectedPlatform", "version": "$appVersion"}',
      );

      final response = await _httpClient.getWithBasicAuth(
        ApiConstants.userProfile,
        queryParams: {
          'userToken': userToken,
          'platform': detectedPlatform,
          'version': appVersion,
        },
        fromJson: (json) {
          print('🔍 Get Profile fromJson - Raw data: $json');

          // Response formatını kontrol et
          if (json is Map<String, dynamic>) {
            print('🔍 Get Profile - Response is Map<String, dynamic>');

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
              userDataToTransform = json['data'];
            }
            // Eğer user field'ı içinde user verisi varsa
            else if (json.containsKey('user') &&
                json['user'] is Map<String, dynamic>) {
              print('🔍 Get Profile - User field format detected');
              userDataToTransform = json['user'];
            } else {
              print(
                '⚠️ Get Profile - Unexpected response format, creating default user',
              );
              print('⚠️ Get Profile - Available keys: ${json.keys.toList()}');
              return User(
                id: '0',
                name: 'Default User',
                email: 'user@example.com',
                rating: 0.0,
                totalTrades: 0,
                isVerified: false,
                isOnline: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
            }

            print(
              '🔍 Get Profile - Transforming user data: $userDataToTransform',
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
                  userDataToTransform['userAvatar'] ??
                  userDataToTransform['avatar'],
              'bio':
                  userDataToTransform['userBio'] ?? userDataToTransform['bio'],
              'rating':
                  (userDataToTransform['userRating'] ??
                          userDataToTransform['rating'] ??
                          0.0)
                      .toDouble(),
              'totalTrades':
                  userDataToTransform['userTotalTrades'] ??
                  userDataToTransform['totalTrades'] ??
                  0,
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

            print('🔍 Get Profile - Transformed data: $transformedData');

            final user = User.fromJson(transformedData);
            print(
              '🔍 Get Profile - Created user: name=${user.name}, firstName=${user.firstName}, lastName=${user.lastName}',
            );
            return user;
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
        'userToken': userToken,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      };

      print('📤 Request Body: $body');

      final response = await _httpClient.put(
        ApiConstants.updateUserPassword,
        body: body,
        fromJson: (json) {
          print('🔍 Update Password fromJson - Raw data: $json');

          // Response formatını kontrol et
          if (json is Map<String, dynamic>) {
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

      final response = await _httpClient.put(
        ApiConstants.deleteUser,
        body: body,
        fromJson: (json) {
          print('🔍 Delete User fromJson - Raw data: $json');

          // Response formatını kontrol et
          if (json is Map<String, dynamic>) {
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

  /// Kullanıcı adını oluşturur
  String _buildUserName(Map<String, dynamic> userData) {
    final firstName = userData['userFirstname'] ?? userData['firstName'];
    final lastName = userData['userLastname'] ?? userData['lastName'];

    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName;
    } else if (lastName != null) {
      return lastName;
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
}
