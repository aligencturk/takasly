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
      // Özel durum: 410 statusCode'u başarılı say, hata gösterme
      if (response.statusCode == ApiConstants.gone) {
        if (fromJson != null && response.body.isNotEmpty) {
          final data = json.decode(response.body);
          return ApiResponse<T>.success(fromJson(data));
        }
        return ApiResponse<T>.success(null);
      }
      
      // Özel durum: 417 statusCode'unda kullanıcıya görünür hata mesajı ver
      if (response.statusCode == ApiConstants.expectationFailed) {
        String errorMessage = ErrorMessages.unknownError;
        if (response.body.isNotEmpty) {
          try {
            final data = json.decode(response.body);
            errorMessage = data['message'] ?? data['error'] ?? errorMessage;
          } catch (_) {
            // JSON decode hatası durumunda default mesaj kullan
          }
        }
        return ApiResponse<T>.error(errorMessage);
      }
      
      // Başarılı durumlar
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return ApiResponse<T>.success(null);
        }
        
        final data = json.decode(response.body);
        
        if (fromJson != null) {
          return ApiResponse<T>.success(fromJson(data));
        }
        
        return ApiResponse<T>.success(data);
      }
      
      // Hata durumları
      String errorMessage = ErrorMessages.unknownError;
      
      if (response.body.isNotEmpty) {
        try {
          final data = json.decode(response.body);
          errorMessage = data['message'] ?? data['error'] ?? errorMessage;
        } catch (_) {
          // JSON decode hatası durumunda status code'a göre mesaj belirle
        }
      }
      
      // Status code'a göre özel hata mesajları
      switch (response.statusCode) {
        case ApiConstants.badRequest:
          errorMessage = errorMessage == ErrorMessages.unknownError 
              ? 'Geçersiz istek' 
              : errorMessage;
          break;
        case ApiConstants.unauthorized:
          errorMessage = ErrorMessages.invalidCredentials;
          break;
        case ApiConstants.forbidden:
          errorMessage = ErrorMessages.accessDenied;
          break;
        case ApiConstants.notFound:
          errorMessage = ErrorMessages.noDataFound;
          break;
        case ApiConstants.conflict:
          errorMessage = errorMessage == ErrorMessages.unknownError 
              ? 'Çakışma hatası' 
              : errorMessage;
          break;
        case ApiConstants.serverError:
          errorMessage = ErrorMessages.serverError;
          break;
        default:
          break;
      }
      
      return ApiResponse<T>.error(errorMessage);
    } catch (e) {
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