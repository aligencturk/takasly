import '../core/http_client.dart';
import '../core/constants.dart';
import '../utils/logger.dart';

class GeneralService {
  final HttpClient _httpClient = HttpClient();

  /// Uygulama logolarını API'den alır
  /// GET /service/general/general/logos
  Future<Map<String, String>?> getLogos() async {
    try {
      Logger.debug(
        '🔍 GeneralService - Logo bilgileri alınıyor...',
        tag: 'GeneralService',
      );

      final response = await _httpClient.getWithBasicAuth(
        ApiConstants.logos,
        fromJson: (json) {
          Logger.debug(
            '🔍 GeneralService - Raw response: $json',
            tag: 'GeneralService',
          );

          if (json is Map<String, dynamic>) {
            // Error kontrolü
            if (json['error'] == true) {
              Logger.error(
                '❌ GeneralService - API error: ${json['message']}',
                tag: 'GeneralService',
              );
              return null;
            }

            // Success kontrolü
            if (json['success'] != true) {
              Logger.warning(
                '⚠️ GeneralService - API success false',
                tag: 'GeneralService',
              );
              return null;
            }

            // Data kontrolü
            if (json['data'] == null || json['data']['logos'] == null) {
              Logger.warning(
                '⚠️ GeneralService - No logos data found',
                tag: 'GeneralService',
              );
              return null;
            }

            final logos = json['data']['logos'] as Map<String, dynamic>;

            // Logo URL'lerini Map olarak döndür
            final Map<String, String> logoUrls = {
              'logoCircle': logos['logoCircle']?.toString() ?? '',
              'logo': logos['logo']?.toString() ?? '',
              'logo2': logos['logo2']?.toString() ?? '',
              'favicon': logos['favicon']?.toString() ?? '',
            };

            Logger.info(
              '✅ GeneralService - Logos loaded successfully',
              tag: 'GeneralService',
            );
            Logger.debug(
              '🔍 GeneralService - Logo URLs: $logoUrls',
              tag: 'GeneralService',
            );

            return logoUrls;
          }

          Logger.error(
            '❌ GeneralService - Invalid response format',
            tag: 'GeneralService',
          );
          return null;
        },
      );

      if (response.isSuccess && response.data != null) {
        return response.data;
      } else {
        Logger.error(
          '❌ GeneralService - API call failed: ${response.error}',
          tag: 'GeneralService',
        );
        return null;
      }
    } catch (e) {
      Logger.error('❌ GeneralService - Exception: $e', tag: 'GeneralService');
      return null;
    }
  }
}
