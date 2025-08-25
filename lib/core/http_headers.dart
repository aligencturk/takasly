import 'dart:convert';
import 'package:takasly/core/constants.dart';
import 'package:takasly/utils/logger.dart';

class HttpHeadersUtil {
  HttpHeadersUtil._();

  static Map<String, String> basicAuthHeaders() {
    try {
      final raw =
          '${ApiConstants.basicAuthUsername}:${ApiConstants.basicAuthPassword}';
      final encoded = base64.encode(utf8.encode(raw));
      return {
        ApiConstants.contentType: ApiConstants.applicationJson,
        'Accept': '*/*',
        ApiConstants.authorization: '${ApiConstants.basic}$encoded',
        'Cache-Control': 'no-cache',
      };
    } catch (e, st) {
      Logger.error(
        'Basic auth header oluşturulamadı: $e',
        error: e,
        stackTrace: st,
      );
      return {
        ApiConstants.contentType: ApiConstants.applicationJson,
        'Accept': '*/*',
      };
    }
  }
}
