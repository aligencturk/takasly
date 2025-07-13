import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class HttpClient {
  static final HttpClient _instance = HttpClient._internal();
  factory HttpClient() => _instance;
  HttpClient._internal();

  static const Duration _timeout = Duration(seconds: 30);
  
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.userTokenKey);
    
    final headers = {
      ApiConstants.contentType: ApiConstants.applicationJson,
      'Accept': ApiConstants.applicationJson,
    };
    
    if (token != null && token.isNotEmpty) {
      headers[ApiConstants.authorization] = '${ApiConstants.bearer}$token';
    }
    
    return headers;
  }

  Map<String, String> _getBasicAuthHeaders() {
    final rawCredentials = '${ApiConstants.basicAuthUsername}:${ApiConstants.basicAuthPassword}';
    final credentials = base64.encode(utf8.encode(rawCredentials));
    
    print('🔐 API Basic Auth Username: ${ApiConstants.basicAuthUsername}');
    print('🔐 API Basic Auth Password: ${ApiConstants.basicAuthPassword}');
    print('🔐 Raw Credentials: $rawCredentials');
    print('🔐 Base64 Encoded: $credentials');
    
    final authHeader = '${ApiConstants.basic}$credentials';
    
    final headers = {
      ApiConstants.contentType: ApiConstants.applicationJson,
      'Accept': ApiConstants.applicationJson,
      ApiConstants.authorization: authHeader,
    };
    
    print('🔐 Final Auth Header: $authHeader');
    print('🔐 All Headers: $headers');
    
    return headers;
  }

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.fullUrl}$endpoint');
      final uriWithParams = queryParams != null 
          ? uri.replace(queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())))
          : uri;
      
      final headers = await _getHeaders();
      
      final response = await http
          .get(uriWithParams, headers: headers)
          .timeout(_timeout);
      
      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      return ApiResponse<T>.error(ErrorMessages.networkError);
    } on HttpException {
      return ApiResponse<T>.error(ErrorMessages.networkError);
    } on FormatException {
      return ApiResponse<T>.error(ErrorMessages.unknownError);
    } catch (e) {
      return ApiResponse<T>.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.fullUrl}$endpoint');
      final headers = await _getHeaders();
      
      final response = await http
          .post(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(_timeout);
      
      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      return ApiResponse<T>.error(ErrorMessages.networkError);
    } on HttpException {
      return ApiResponse<T>.error(ErrorMessages.networkError);
    } on FormatException {
      return ApiResponse<T>.error(ErrorMessages.unknownError);
    } catch (e) {
      return ApiResponse<T>.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<T>> postWithBasicAuth<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final fullUrl = '${ApiConstants.fullUrl}$endpoint';
      final uri = Uri.parse(fullUrl);
      final headers = _getBasicAuthHeaders();
      final bodyString = body != null ? json.encode(body) : null;
      
      print('🌐 Full URL: $fullUrl');
      print('🌐 URI: $uri');
      print('🔑 Headers: $headers');
      print('📤 Body String: $bodyString');
      
      final response = await http
          .post(
            uri,
            headers: headers,
            body: bodyString,
          )
          .timeout(_timeout);
      
      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Headers: ${response.headers}');
      print('📥 Response Body: ${response.body}');
      
      return _handleResponse<T>(response, fromJson);
    } on SocketException catch (e) {
      print('🚫 Socket Exception: $e');
      return ApiResponse<T>.error(ErrorMessages.networkError);
    } on HttpException catch (e) {
      print('🚫 HTTP Exception: $e');
      return ApiResponse<T>.error(ErrorMessages.networkError);
    } on FormatException catch (e) {
      print('🚫 Format Exception: $e');
      return ApiResponse<T>.error(ErrorMessages.unknownError);
    } catch (e) {
      print('💥 PostWithBasicAuth Exception: $e');
      return ApiResponse<T>.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.fullUrl}$endpoint');
      final headers = await _getHeaders();
      
      final response = await http
          .put(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(_timeout);
      
      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      return ApiResponse<T>.error(ErrorMessages.networkError);
    } on HttpException {
      return ApiResponse<T>.error(ErrorMessages.networkError);
    } on FormatException {
      return ApiResponse<T>.error(ErrorMessages.unknownError);
    } catch (e) {
      return ApiResponse<T>.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.fullUrl}$endpoint');
      final headers = await _getHeaders();
      
      final response = await http
          .delete(uri, headers: headers)
          .timeout(_timeout);
      
      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      return ApiResponse<T>.error(ErrorMessages.networkError);
    } on HttpException {
      return ApiResponse<T>.error(ErrorMessages.networkError);
    } on FormatException {
      return ApiResponse<T>.error(ErrorMessages.unknownError);
    } catch (e) {
      return ApiResponse<T>.error(ErrorMessages.unknownError);
    }
  }

  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
  ) {
    try {
      print('🔍 Handling response - Status Code: ${response.statusCode}');
      print('🔍 Response Body: ${response.body}');
      
      // Özel durum: 410 statusCode'u başarılı say, hata gösterme
      if (response.statusCode == ApiConstants.gone) {
        print('✅ 410 Status - Treating as success');
        print('✅ 410 - Response body: "${response.body}"');
        print('✅ 410 - Response body isEmpty: ${response.body.isEmpty}');
        
        if (response.body.isNotEmpty) {
          try {
            final data = json.decode(response.body);
            print('✅ 410 - Parsed data: $data');
            
            if (fromJson != null) {
              return ApiResponse<T>.success(fromJson(data));
            } else {
              return ApiResponse<T>.success(data);
            }
          } catch (e) {
            print('⚠️ 410 - Failed to parse JSON: $e');
            print('⚠️ 410 - Raw response body: "${response.body}"');
            // JSON parse edilemiyorsa, raw response'u döndür
            return ApiResponse<T>.success(response.body as T?);
          }
        } else {
          print('⚠️ 410 - Empty response body');
          return ApiResponse<T>.success(null);
        }
      }
      
      // Özel durum: 417 statusCode'unda kullanıcıya görünür hata mesajı ver
      if (response.statusCode == ApiConstants.expectationFailed) {
        print('❌ 417 Status - Expectation Failed');
        String errorMessage = ErrorMessages.unknownError;
        if (response.body.isNotEmpty) {
          try {
            final data = json.decode(response.body);
            print('❌ 417 - Parsed error data: $data');
            
            // error_message field'ını öncelikle kontrol et
            if (data['error_message'] != null && data['error_message'] is String) {
              errorMessage = data['error_message'];
            } else if (data['message'] != null && data['message'] is String) {
              errorMessage = data['message'];
            } else if (data['error'] != null && data['error'] is String) {
              errorMessage = data['error'];
            }
            
            print('❌ 417 - Extracted error message: "$errorMessage"');
          } catch (e) {
            print('⚠️ 417 - Failed to parse error JSON: $e');
            errorMessage = response.body; // Raw response'u göster
          }
        }
        return ApiResponse<T>.error(errorMessage);
      }
      
      // Başarılı durumlar (200-299)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ Success status: ${response.statusCode}');
        if (response.body.isEmpty) {
          print('✅ Empty response body - returning null');
          return ApiResponse<T>.success(null);
        }
        
        try {
          final data = json.decode(response.body);
          print('✅ Parsed response data: $data');
          
          if (fromJson != null) {
            print('✅ Using fromJson function');
            return ApiResponse<T>.success(fromJson(data));
          }
          
          return ApiResponse<T>.success(data);
        } catch (e) {
          print('⚠️ Success - Failed to parse JSON: $e');
          return ApiResponse<T>.error('Sunucu yanıtı parse edilemedi');
        }
      }
      
      // Hata durumları
      print('❌ Error status: ${response.statusCode}');
      String errorMessage = ErrorMessages.unknownError;
      
      if (response.body.isNotEmpty) {
        try {
          final data = json.decode(response.body);
          print('❌ Error response data: $data');
          
          // Farklı hata mesajı alanlarını kontrol et
          errorMessage = data['message'] ?? 
                       data['error'] ?? 
                       data['error_message'] ?? 
                       data['errorMessage'] ?? 
                       errorMessage;
          
          print('❌ Extracted error message: $errorMessage');
        } catch (e) {
          print('⚠️ Failed to parse error response JSON: $e');
          
          // JSON parse edilemiyorsa, response body'yi kontrol et
          if (response.body.contains('Yetkisiz giriş')) {
            errorMessage = 'Kimlik doğrulama hatası';
          } else if (response.body.contains('401')) {
            errorMessage = 'Yetkisiz erişim';
          } else {
            errorMessage = 'Sunucu hatası';
          }
        }
      }
      
      // Status code'a göre özel hata mesajları
      switch (response.statusCode) {
        case ApiConstants.badRequest:
          if (errorMessage == ErrorMessages.unknownError) {
            errorMessage = 'Geçersiz istek';
          }
          break;
        case ApiConstants.unauthorized:
          if (errorMessage == ErrorMessages.unknownError) {
            errorMessage = 'Kimlik doğrulama hatası';
          }
          break;
        case ApiConstants.forbidden:
          if (errorMessage == ErrorMessages.unknownError) {
            errorMessage = ErrorMessages.accessDenied;
          }
          break;
        case ApiConstants.notFound:
          if (errorMessage == ErrorMessages.unknownError) {
            errorMessage = ErrorMessages.noDataFound;
          }
          break;
        case ApiConstants.conflict:
          if (errorMessage == ErrorMessages.unknownError) {
            errorMessage = 'Çakışma hatası';
          }
          break;
        case ApiConstants.serverError:
          if (errorMessage == ErrorMessages.unknownError) {
            errorMessage = ErrorMessages.serverError;
          }
          break;
        default:
          break;
      }
      
      print('❌ Final error message: $errorMessage');
      return ApiResponse<T>.error(errorMessage);
    } catch (e) {
      print('💥 HandleResponse Exception: $e');
      return ApiResponse<T>.error(ErrorMessages.unknownError);
    }
  }
}

class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  ApiResponse._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  factory ApiResponse.success(T? data) {
    return ApiResponse._(
      data: data,
      isSuccess: true,
    );
  }

  factory ApiResponse.error(String error) {
    return ApiResponse._(
      error: error,
      isSuccess: false,
    );
  }

  bool get hasError => !isSuccess;
} 