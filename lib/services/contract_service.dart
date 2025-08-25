import '../core/http_client.dart';
import '../models/contract.dart';
import '../utils/logger.dart';

class ContractService {
  final HttpClient _httpClient = HttpClient();

  /// Üyelik sözleşmesini API'den alır
  /// GET /service/general/general/contract/4
  Future<ApiResponse<Contract>> getMembershipContract() async {
    try {
      Logger.debug(
        '🔍 ContractService - Üyelik sözleşmesi alınıyor...',
        tag: 'ContractService',
      );

      final response = await _httpClient.getWithBasicAuth(
        '/service/general/general/contract/4',
        fromJson: (json) {
          Logger.debug(
            '🔍 ContractService - Raw response: $json',
            tag: 'ContractService',
          );

          if (json is Map<String, dynamic>) {
            // Error kontrolü
            if (json['error'] == true) {
              final errorMsg = json['message'] ?? 'API hatası';
              Logger.error(
                '❌ ContractService - API error: $errorMsg',
                tag: 'ContractService',
              );
              return null;
            }

            // Success kontrolü
            if (json['success'] != true) {
              Logger.warning(
                '⚠️ ContractService - API success false',
                tag: 'ContractService',
              );
              return null;
            }

            // Data kontrolü
            if (json['data'] == null) {
              Logger.warning(
                '⚠️ ContractService - No contract data found',
                tag: 'ContractService',
              );
              return null;
            }

            try {
              final contract = Contract.fromJson(json['data']);
              Logger.info(
                '✅ ContractService - Contract loaded successfully',
                tag: 'ContractService',
              );
              Logger.debug(
                '🔍 ContractService - Contract: ${contract.title}',
                tag: 'ContractService',
              );
              return contract;
            } catch (parseError) {
              Logger.error(
                '❌ ContractService - Contract parse error: $parseError',
                tag: 'ContractService',
              );
              return null;
            }
          }

          Logger.error(
            '❌ ContractService - Invalid response format',
            tag: 'ContractService',
          );
          return null;
        },
      );

      if (response.isSuccess && response.data != null) {
        Logger.info(
          '✅ ContractService - Membership contract API call successful',
          tag: 'ContractService',
        );
        return ApiResponse.success(response.data!);
      } else {
        final errorMsg = response.error ?? 'Sözleşme yüklenemedi';
        Logger.error(
          '❌ ContractService - API call failed: $errorMsg',
          tag: 'ContractService',
        );
        return ApiResponse.error(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'Sözleşme yükleme hatası: $e';
      Logger.error('❌ ContractService - Exception: $e', tag: 'ContractService');
      return ApiResponse.error(errorMsg);
    }
  }

  /// KVKK aydınlatma metnini API'den alır
  /// GET /service/general/general/contract/3
  Future<ApiResponse<Contract>> getKvkkContract() async {
    try {
      Logger.debug(
        '🔍 ContractService - KVKK metni alınıyor...',
        tag: 'ContractService',
      );

      final response = await _httpClient.getWithBasicAuth(
        '/service/general/general/contract/3',
        fromJson: (json) {
          Logger.debug(
            '🔍 ContractService - KVKK Raw response: $json',
            tag: 'ContractService',
          );

          if (json is Map<String, dynamic>) {
            // Error kontrolü
            if (json['error'] == true) {
              final errorMsg = json['message'] ?? 'KVKK API hatası';
              Logger.error(
                '❌ ContractService - KVKK API error: $errorMsg',
                tag: 'ContractService',
              );
              return null;
            }

            // Success kontrolü
            if (json['success'] != true) {
              Logger.warning(
                '⚠️ ContractService - KVKK API success false',
                tag: 'ContractService',
              );
              return null;
            }

            // Data kontrolü
            if (json['data'] == null) {
              Logger.warning(
                '⚠️ ContractService - No KVKK data found',
                tag: 'ContractService',
              );
              return null;
            }

            try {
              final contract = Contract.fromJson(json['data']);
              Logger.info(
                '✅ ContractService - KVKK loaded successfully',
                tag: 'ContractService',
              );
              Logger.debug(
                '🔍 ContractService - KVKK: ${contract.title}',
                tag: 'ContractService',
              );
              return contract;
            } catch (parseError) {
              Logger.error(
                '❌ ContractService - KVKK parse error: $parseError',
                tag: 'ContractService',
              );
              return null;
            }
          }

          Logger.error(
            '❌ ContractService - KVKK Invalid response format',
            tag: 'ContractService',
          );
          return null;
        },
      );

      if (response.isSuccess && response.data != null) {
        Logger.info(
          '✅ ContractService - KVKK contract API call successful',
          tag: 'ContractService',
        );
        return ApiResponse.success(response.data!);
      } else {
        final errorMsg = response.error ?? 'KVKK metni yüklenemedi';
        Logger.error(
          '❌ ContractService - KVKK API call failed: $errorMsg',
          tag: 'ContractService',
        );
        return ApiResponse.error(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'KVKK yükleme hatası: $e';
      Logger.error(
        '❌ ContractService - KVKK Exception: $e',
        tag: 'ContractService',
      );
      return ApiResponse.error(errorMsg);
    }
  }
}
