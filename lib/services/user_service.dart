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
      print('📤 Request Body: {"userToken": "$userToken", "platform": "$detectedPlatform", "version": "$appVersion"}');
      
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
            // Eğer direkt user verisi gelirse
            if (json.containsKey('id') || json.containsKey('userID')) {
              return User.fromJson(json);
            }
            
            // Eğer data field'ı içinde user verisi varsa
            if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
              return User.fromJson(json['data']);
            }
            
            // Eğer user field'ı içinde user verisi varsa
            if (json.containsKey('user') && json['user'] is Map<String, dynamic>) {
              return User.fromJson(json['user']);
            }
            
            // Eğer hiçbiri yoksa default response
            print('⚠️ Unexpected response format, creating default user');
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
      final Map<String, dynamic> body = {
        'userToken': userToken,
      };
      
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
            // Eğer direkt user verisi gelirse
            if (json.containsKey('id') || json.containsKey('userID')) {
              return User.fromJson(json);
            }
            
            // Eğer data field'ı içinde user verisi varsa
            if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
              return User.fromJson(json['data']);
            }
            
            // Eğer user field'ı içinde user verisi varsa
            if (json.containsKey('user') && json['user'] is Map<String, dynamic>) {
              return User.fromJson(json['user']);
            }
            
            // Eğer sadece success mesajı gelirse, mevcut user'ı güncellemeye çalış
            if (json.containsKey('message') || json.containsKey('success')) {
              // Update için dummy user oluştur
              return User(
                id: '0',
                name: [userFirstname, userLastname].where((e) => e != null).join(' '),
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
            
            // Eğer hiçbiri yoksa default response
            print('⚠️ Unexpected response format, creating default user');
            return User(
              id: '0',
              name: [userFirstname, userLastname].where((e) => e != null).join(' '),
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
      print('📤 Query Params: {"userToken": "$userToken", "platform": "$detectedPlatform", "version": "$appVersion"}');
      
      final response = await _httpClient.get(
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
            // Eğer direkt user verisi gelirse
            if (json.containsKey('id') || json.containsKey('userID')) {
              return User.fromJson(json);
            }
            
            // Eğer data field'ı içinde user verisi varsa
            if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
              return User.fromJson(json['data']);
            }
            
            // Eğer user field'ı içinde user verisi varsa
            if (json.containsKey('user') && json['user'] is Map<String, dynamic>) {
              return User.fromJson(json['user']);
            }
            
            // Eğer hiçbiri yoksa default response
            print('⚠️ Unexpected response format, creating default user');
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
} 