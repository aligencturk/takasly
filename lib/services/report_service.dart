import '../core/http_client.dart';
import '../core/constants.dart';
import '../utils/logger.dart';

class ReportService {
  final HttpClient _httpClient = HttpClient();
  static const String _tag = 'ReportService';

  /// Kullanıcı şikayet etme
  /// POST /service/user/product/reportUser
  Future<ApiResponse<bool>> reportUser({
    required String userToken,
    required int reportedUserID,
    required String reason,
    int? productID,
    int? offerID,
  }) async {
    try {
      Logger.info('Kullanıcı şikayet isteği gönderiliyor... ReportedUserID: $reportedUserID', tag: _tag);
      
      final requestBody = {
        'userToken': userToken,
        'reportedUserID': reportedUserID,
        'reason': reason,
      };

      // İsteğe bağlı alanları ekle
      if (productID != null) {
        requestBody['productID'] = productID;
      }
      if (offerID != null) {
        requestBody['offerID'] = offerID;
      }

      Logger.debug('Şikayet request body: $requestBody', tag: _tag);

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.reportUser,
        body: requestBody,
        fromJson: (json) => true, // Başarılı response için true döndür
        useBasicAuth: true,
      );

      if (response.isSuccess) {
        Logger.info('Kullanıcı şikayet başarılı', tag: _tag);
      } else {
        Logger.error('Kullanıcı şikayet hatası: ${response.error}', tag: _tag);
      }

      return response;
    } catch (e) {
      Logger.error('Kullanıcı şikayet exception: $e', tag: _tag);
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }
} 