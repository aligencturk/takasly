import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'constants.dart';
import '../services/error_handler_service.dart';

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
      
      // Global error handler'ı çağır
      ErrorHandlerService.handleUnauthorizedError(null);
    } catch (e) {
      print('❌ Error clearing user data: $e');
    }
  }

  Future<void> _handleForbidden() async {
    print('🚨 403 Forbidden - Clearing user data and forcing logout');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userTokenKey);
      await prefs.remove(AppConstants.userIdKey);
      await prefs.remove(AppConstants.userDataKey);
      print('✅ User data cleared successfully for 403 error');
      
      // Global error handler'ı çağır
      ErrorHandlerService.handleForbiddenError(null);
    } catch (e) {
      print('❌ Error clearing user data for 403: $e');
    }
  }

  Map<String, String> _getBasicAuthHeaders() {
    final rawCredentials =
        '${ApiConstants.basicAuthUsername}:${ApiConstants.basicAuthPassword}';
    final credentials = base64.encode(utf8.encode(rawCredentials));

    print('🔐 API Basic Auth Username: ${ApiConstants.basicAuthUsername}');
    print('🔐 API Basic Auth Password: ${ApiConstants.basicAuthPassword}');
    print('🔐 Raw Credentials: $rawCredentials');
    print('🔐 Base64 Encoded: $credentials');

    final authHeader = '${ApiConstants.basic}$credentials';

    final headers = {
      ApiConstants.contentType: ApiConstants.applicationJson,
      'Accept': '*/*',
      ApiConstants.authorization: authHeader,
      'User-Agent': 'Takasly-App/1.0.0',
      'Cache-Control': 'no-cache',
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
          ? uri.replace(
              queryParameters: queryParams.map(
                (k, v) => MapEntry(k, v.toString()),
              ),
            )
          : uri;

      print("🌐 Full URL: $uriWithParams");

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
          ? uri.replace(
              queryParameters: queryParams.map(
                (k, v) => MapEntry(k, v.toString()),
              ),
            )
          : uri;

      print("🌐 Full URL: $uriWithParams");

      final headers = _getBasicAuthHeaders();

      final response = await http
          .get(uriWithParams, headers: headers)
          .timeout(_timeout);

      return await _handleResponse<T>(response, fromJson, isBasicAuth: true);
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
      print("🌐 Full URL: $uri");
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
    required bool useBasicAuth,
  }) async {
    try {
      final fullUrl = '${ApiConstants.fullUrl}$endpoint';
      final uri = Uri.parse(fullUrl);
      
      // useBasicAuth parametresine göre header seç
      final headers = useBasicAuth ? _getBasicAuthHeaders() : await _getHeaders();
      final bodyString = body != null ? json.encode(body) : null;

      print('🌐 Full URL: $fullUrl');
      print('🌐 URI: $uri');
      print('🔑 Headers: $headers');
      print('📤 Body String: $bodyString');

      final response = await http
          .post(uri, headers: headers, body: bodyString)
          .timeout(_timeout);

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Headers: ${response.headers}');
      print('📥 Response Body: ${response.body}');

      return await _handleResponse<T>(response, fromJson, isBasicAuth: useBasicAuth);
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
      print("🌐 Full URL: $uri");
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
      print("🌐 Full URL: $uri");
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

  Future<ApiResponse<T>> putWithBasicAuth<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final fullUrl = '${ApiConstants.fullUrl}$endpoint';
      final uri = Uri.parse(fullUrl);
      final headers = _getBasicAuthHeaders();
      final bodyString = body != null ? json.encode(body) : null;

      print('🌐 PUT Full URL: $fullUrl');
      print('🌐 PUT URI: $uri');
      print('🔑 PUT Headers: $headers');
      print('📤 PUT Body String: $bodyString');

      final response = await http
          .put(uri, headers: headers, body: bodyString)
          .timeout(_timeout);

      print('📥 PUT Response Status: ${response.statusCode}');
      print('📥 PUT Response Headers: ${response.headers}');
      print('📥 PUT Response Body: ${response.body}');

      return await _handleResponse<T>(response, fromJson, isBasicAuth: true);
    } on SocketException catch (e) {
      print('🚫 PUT Socket Exception: $e');
      return ApiResponse<T>.error(ErrorMessages.networkError);
    } on HttpException catch (e) {
      print('🚫 PUT HTTP Exception: $e');
      return ApiResponse<T>.error(ErrorMessages.networkError);
    } on FormatException catch (e) {
      print('🚫 PUT Format Exception: $e');
      return ApiResponse<T>.error(ErrorMessages.unknownError);
    } catch (e) {
      print('💥 PUT Exception: $e');
      return ApiResponse<T>.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<T>> deleteWithBasicAuth<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final fullUrl = '${ApiConstants.fullUrl}$endpoint';
      final uri = Uri.parse(fullUrl);
      final headers = _getBasicAuthHeaders();
      final bodyString = body != null ? json.encode(body) : null;

      print('🌐 DELETE Full URL: $fullUrl');
      print('🌐 DELETE URI: $uri');
      print('🔑 DELETE Headers: $headers');
      print('📤 DELETE Body String: $bodyString');

      final response = await http
          .delete(uri, headers: headers, body: bodyString)
          .timeout(_timeout);

      print('📥 DELETE Response Status: ${response.statusCode}');
      print('📥 DELETE Response Headers: ${response.headers}');
      print('📥 DELETE Response Body: ${response.body}');
      print('📥 DELETE Response Body Length: ${response.body.length}');
      print('📥 DELETE Response Body isEmpty: ${response.body.isEmpty}');

      final apiResponse = await _handleResponse<T>(response, fromJson, isBasicAuth: true);
      print('📥 DELETE _handleResponse result - isSuccess: ${apiResponse.isSuccess}');
      print('📥 DELETE _handleResponse result - error: ${apiResponse.error}');
      return apiResponse;
    } on SocketException catch (e) {
      print('🚫 DELETE Socket Exception: $e');
      return ApiResponse<T>.error(ErrorMessages.networkError);
    } on HttpException catch (e) {
      print('🚫 DELETE HTTP Exception: $e');
      return ApiResponse<T>.error(ErrorMessages.networkError);
    } on FormatException catch (e) {
      print('🚫 DELETE Format Exception: $e');
      return ApiResponse<T>.error(ErrorMessages.unknownError);
    } catch (e) {
      print('💥 DELETE Exception: $e');
      return ApiResponse<T>.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<T>> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson, {
    bool isBasicAuth = false,
  }) async {
    try {
      print('🔍 Handling response - Status Code: ${response.statusCode}');
      print('🔍 Response Body: ${response.body}');

      // Özel durum: 410 statusCode'u başarılı say, hata gösterme
      if (response.statusCode == ApiConstants.gone) {
        print('✅ 410 Status - Treating as success');
        print('✅ 410 - Response body: "${response.body}"');
        print('✅ 410 - Response body isEmpty: ${response.body.isEmpty}');

        if (response.body.isNotEmpty && response.body.trim() != 'null') {
          try {
            final data = json.decode(response.body);
            print('✅ 410 - Parsed data: $data');

            if (fromJson != null) {
              final result = fromJson(data);
              print('✅ 410 - fromJson result: $result');
              return ApiResponse<T>.success(result);
            } else {
              print('✅ 410 - Returning data directly');
              return ApiResponse<T>.success(data);
            }
          } catch (e) {
            print('⚠️ 410 - Failed to parse JSON: $e');
            print('⚠️ 410 - Raw response body: "${response.body}"');
            // JSON parse edilemiyorsa, fromJson fonksiyonu varsa boş data ile çağır
            if (fromJson != null) {
              try {
                // Boş bir Map ile fromJson'u çağır
                final result = fromJson({});
                print('⚠️ 410 - Returning empty fromJson result: $result');
                return ApiResponse<T>.success(result);
              } catch (e2) {
                print('⚠️ 410 - fromJson failed with empty data: $e2');
                return ApiResponse<T>.success(null);
              }
            } else {
              print('⚠️ 410 - Returning null due to JSON parse error');
              return ApiResponse<T>.success(null);
            }
          }
        } else {
          print('⚠️ 410 - Empty or null response body');
          if (fromJson != null) {
            try {
              // Boş bir Map ile fromJson'u çağır
              final result = fromJson({});
              print('⚠️ 410 - Returning empty fromJson result: $result');
              return ApiResponse<T>.success(result);
            } catch (e) {
              print('⚠️ 410 - fromJson failed with empty data: $e');
              return ApiResponse<T>.success(null);
            }
          } else {
            return ApiResponse<T>.success(null);
          }
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
            if (data['error_message'] != null &&
                data['error_message'] is String) {
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
          if (data['error_message'] != null) {
            errorMessage = data['error_message'].toString();
          } else if (data['message'] != null) {
            errorMessage = data['message'].toString();
          } else if (data['error'] != null) {
            errorMessage = data['error'].toString();
          } else if (data['errorMessage'] != null) {
            errorMessage = data['errorMessage'].toString();
          }

          print('❌ Extracted error message: $errorMessage');
        } catch (e) {
          print('⚠️ Failed to parse error response JSON: $e');

          // JSON parse edilemiyorsa, response body'yi kontrol et ve temizle
          String cleanBody = response.body.trim();

          if (cleanBody.contains('Yetkisiz giriş') ||
              cleanBody.contains('401')) {
            errorMessage = 'Kimlik doğrulama hatası';
          } else if (cleanBody.contains('403')) {
            errorMessage = 'Erişim reddedildi';
          } else if (cleanBody.contains('404')) {
            errorMessage = 'Kaynak bulunamadı';
          } else if (cleanBody.contains('500')) {
            errorMessage = 'Sunucu hatası';
          } else if (cleanBody.isNotEmpty && cleanBody.length < 200) {
            // Kısa mesajları olduğu gibi göster (çok uzun değilse)
            errorMessage = cleanBody;
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
          // 401 hatası alındığında sadece Bearer token kullanan endpoint'lerde otomatik logout
          if (!isBasicAuth) {
            await _handleUnauthorized();
            // Global error handler'ı çağır (401 hatası için)
            ErrorHandlerService.handleUnauthorizedError(null);
            if (errorMessage == ErrorMessages.unknownError) {
              errorMessage = 'Oturum süresi doldu. Lütfen tekrar giriş yapın.';
            }
          } else {
            if (errorMessage == ErrorMessages.unknownError) {
              errorMessage = 'Kimlik doğrulama hatası';
            }
          }
          break;
        case ApiConstants.forbidden:
          // 403 hatası alındığında sadece Bearer token kullanan endpoint'lerde otomatik logout
          if (!isBasicAuth) {
            print('🚨 403 Forbidden error detected in HTTP client');
            await _handleForbidden();
            // Global error handler'ı çağır (403 hatası için)
            ErrorHandlerService.handleForbiddenError(null);
            if (errorMessage == ErrorMessages.unknownError) {
              errorMessage = 'Erişim reddedildi. Lütfen tekrar giriş yapın.';
            }
          } else {
            if (errorMessage == ErrorMessages.unknownError) {
              errorMessage = ErrorMessages.accessDenied;
            }
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
      print(
        '📎 Files (${request.files.length}): ${request.files.map((f) => '${f.field}: ${f.filename}').toList()}',
      );

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
        final bool apiSuccess =
            jsonData['success'] == true || jsonData['error'] == false;

        print('📊 API Success check: $apiSuccess');
        print(
          '📊 Status Code Success check: ${response.statusCode >= 200 && response.statusCode < 300}',
        );
        print(
          '📊 410 Success check: ${response.statusCode == 410 && apiSuccess}',
        );

        if ((response.statusCode >= 200 && response.statusCode < 300) ||
            (response.statusCode == 410 && apiSuccess)) {
          print(
            '✅ API Success detected - Status: ${response.statusCode}, API Success: $apiSuccess',
          );
          final T data = fromJson(jsonData);
          print('✅ Data parsed successfully: $data');
          return ApiResponse.success(data);
        } else {
          print(
            '❌ API Error detected - Status: ${response.statusCode}, API Success: $apiSuccess',
          );
          final errorMessage =
              jsonData['message'] ?? jsonData['error'] ?? 'Unknown error';
          print('❌ Error message: $errorMessage');
          return ApiResponse.error(errorMessage.toString());
        }
      } catch (e) {
        print('❌ JSON parsing error: $e');
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return ApiResponse.error('JSON parsing error: $e');
        } else {
          return ApiResponse.error(
            'HTTP ${response.statusCode}: ${response.body}',
          );
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

  ApiResponse._({this.data, this.error, required this.isSuccess});

  factory ApiResponse.success(T? data) {
    return ApiResponse._(data: data, isSuccess: true);
  }

  factory ApiResponse.error(String error) {
    return ApiResponse._(error: error, isSuccess: false);
  }

  bool get hasError => !isSuccess;
}
