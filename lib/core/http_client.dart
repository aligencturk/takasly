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

  Future<void> _handleUnauthorized() async {
    print('🚨 401 Unauthorized - Clearing user data and forcing logout');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userTokenKey);
      await prefs.remove(AppConstants.userIdKey);
      await prefs.remove(AppConstants.userDataKey);
      print('✅ User data cleared successfully');
    } catch (e) {
      print('❌ Error clearing user data: $e');
    }
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
      
      return await _handleResponse<T>(response, fromJson);
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

  Future<ApiResponse<T>> getWithBasicAuth<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.fullUrl}$endpoint');
      final uriWithParams = queryParams != null 
          ? uri.replace(queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())))
          : uri;
      
      final headers = _getBasicAuthHeaders();
      
      final response = await http
          .get(uriWithParams, headers: headers)
          .timeout(_timeout);
      
      return await _handleResponse<T>(response, fromJson);
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
      
      return await _handleResponse<T>(response, fromJson);
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
      
      return await _handleResponse<T>(response, fromJson);
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
      
      return await _handleResponse<T>(response, fromJson);
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
      
      return await _handleResponse<T>(response, fromJson);
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

  Future<ApiResponse<T>> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
  ) async {
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
            return ApiResponse<T>.success(null);
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
      
      // Özel durum: 410 ama response'da success:true varsa başarılı say
      if (response.statusCode == ApiConstants.gone) {
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          if (jsonData['success'] == true) {
            print('✅ 410 Status - Treating as success');
            print('✅ 410 - Response body: "${response.body}"');
            print('✅ 410 - Parsed data: $jsonData');
            
            // 410 olsa bile success:true varsa başarılı say
            try {
              if (fromJson != null) {
                final T data = fromJson(jsonData);
                print('✅ 410 - Successfully parsed data: $data');
                return ApiResponse.success(data);
              } else {
                print('✅ 410 - No fromJson function, returning raw data');
                return ApiResponse<T>.success(jsonData as T?);
              }
            } catch (e) {
              print('! 410 - Failed to parse JSON: $e');
              print('! 410 - Raw response body: "${response.body}"');
              return ApiResponse<T>.error('Data parsing error: $e');
            }
          }
        } catch (e) {
          print('! 410 - Failed to handle as success: $e');
        }
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
          // 401 hatası alındığında otomatik logout
          await _handleUnauthorized();
          if (errorMessage == ErrorMessages.unknownError) {
            errorMessage = 'Oturum süresi doldu. Lütfen tekrar giriş yapın.';
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

  // Multipart form-data request method
  Future<ApiResponse<T>> postMultipart<T>(
    String endpoint, {
    required Map<String, String> fields,
    Map<String, File>? files,
    Map<String, List<File>>? multipleFiles,
    required T Function(Map<String, dynamic>) fromJson,
    bool useBasicAuth = false,
  }) async {
    print('🚀 HttpClient.postMultipart called');
    print('📝 Parameters:');
    print('  - endpoint: $endpoint');
    print('  - fields count: ${fields.length}');
    print('  - files count: ${files?.length ?? 0}');
    print('  - multipleFiles count: ${multipleFiles?.length ?? 0}');
    print('  - useBasicAuth: $useBasicAuth');
    
    try {
      final url = Uri.parse('${ApiConstants.fullUrl}$endpoint');
      print('🌐 Full URL: $url');
      
      final request = http.MultipartRequest('POST', url);
      
      // Headers ekle
      if (useBasicAuth) {
        print('🔑 Adding basic auth headers');
        request.headers.addAll(_getBasicAuthHeaders());
      } else {
        print('🔑 Adding bearer token headers');
        request.headers.addAll(await _getHeaders());
      }
      
      print('📋 Request headers: ${request.headers}');
      
      // Form fields ekle
      request.fields.addAll(fields);
      print('📝 Form fields added: ${request.fields}');
      
      // Single files ekle
      if (files != null) {
        print('📎 Adding ${files.length} single files');
        for (String key in files.keys) {
          final file = files[key]!;
          final multipartFile = await http.MultipartFile.fromPath(
            key,
            file.path,
          );
          request.files.add(multipartFile);
          print('  - Added single file: $key -> ${file.path.split('/').last}');
        }
      }
      
      // Multiple files ekle (aynı key ile birden fazla dosya)
      if (multipleFiles != null) {
        print('📎 Adding multiple files');
        for (String key in multipleFiles.keys) {
          final fileList = multipleFiles[key]!;
          print('  - Key: $key, Files count: ${fileList.length}');
          for (File file in fileList) {
            final multipartFile = await http.MultipartFile.fromPath(
              key,
              file.path,
            );
            request.files.add(multipartFile);
            print('    - Added file: ${file.path.split('/').last}');
          }
        }
      }
      
      print('🌐 Multipart Request: ${request.method} ${request.url}');
      print('📝 Fields: ${request.fields}');
      print('📎 Files (${request.files.length}): ${request.files.map((f) => '${f.field}: ${f.filename}').toList()}');
      
      print('📡 Sending multipart request...');
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Headers: ${response.headers}');
      print('📡 Response Body: ${response.body}');
      
      try {
        print('📥 Parsing JSON response...');
        final Map<String, dynamic> jsonData = json.decode(response.body);
        print('📥 Parsed JSON: $jsonData');
        
        // API response'unda success field'ını kontrol et
        // Bazı API'ler garip status code gönderebilir ama body'de success bilgisi doğru olur
        final bool apiSuccess = jsonData['success'] == true || 
                                 jsonData['error'] == false;
        
        print('📊 API Success check: $apiSuccess');
        print('📊 Status Code Success check: ${response.statusCode >= 200 && response.statusCode < 300}');
        print('📊 410 Success check: ${response.statusCode == 410 && apiSuccess}');
        
        if ((response.statusCode >= 200 && response.statusCode < 300) || 
            (response.statusCode == 410 && apiSuccess)) {
          print('✅ API Success detected - Status: ${response.statusCode}, API Success: $apiSuccess');
          final T data = fromJson(jsonData);
          print('✅ Data parsed successfully: $data');
          return ApiResponse.success(data);
        } else {
          print('❌ API Error detected - Status: ${response.statusCode}, API Success: $apiSuccess');
          final errorMessage = jsonData['message'] ?? 
                               jsonData['error'] ?? 
                               'Unknown error';
          print('❌ Error message: $errorMessage');
          return ApiResponse.error(errorMessage.toString());
        }
      } catch (e) {
        print('❌ JSON parsing error: $e');
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return ApiResponse.error('JSON parsing error: $e');
        } else {
          return ApiResponse.error('HTTP ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e, stackTrace) {
      print('❌ Network error: $e');
      print('❌ Stack trace: $stackTrace');
      if (e is SocketException) {
        return ApiResponse.error(ErrorMessages.networkError);
      }
      return ApiResponse.error(ErrorMessages.unknownError);
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