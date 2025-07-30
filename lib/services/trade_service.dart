import '../core/http_client.dart';
import '../core/constants.dart';
import '../models/trade.dart';
import '../utils/logger.dart';

class TradeService {
  final HttpClient _httpClient = HttpClient();
  static const String _tag = 'TradeService';

  Future<ApiResponse<Trade>> createTrade({
    required String receiverUserId,
    required List<String> offeredProductIds,
    required List<String> requestedProductIds,
    String? message,
  }) async {
    try {
      final response = await _httpClient.post(
        ApiConstants.trades,
        body: {
          'receiverUserId': receiverUserId,
          'offeredProductIds': offeredProductIds,
          'requestedProductIds': requestedProductIds,
          if (message != null) 'message': message,
        },
        fromJson: (json) => Trade.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<List<Trade>>> getMyTrades({
    int page = 1,
    int limit = AppConstants.defaultPageSize,
    TradeStatus? status,
    bool? asOfferer,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (status != null) queryParams['status'] = status.name;
      if (asOfferer != null) queryParams['asOfferer'] = asOfferer;

      final response = await _httpClient.get(
        '${ApiConstants.trades}/my',
        queryParams: queryParams,
        fromJson: (json) => (json['trades'] as List)
            .map((item) => Trade.fromJson(item))
            .toList(),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<Trade>> getTradeById(String tradeId) async {
    try {
      final response = await _httpClient.get(
        '${ApiConstants.trades}/$tradeId',
        fromJson: (json) => Trade.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<Trade>> acceptTrade(String tradeId) async {
    try {
      final response = await _httpClient.post(
        '${ApiConstants.trades}/$tradeId/accept',
        fromJson: (json) => Trade.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<Trade>> rejectTrade(String tradeId, {String? reason}) async {
    try {
      final body = <String, dynamic>{};
      if (reason != null) body['reason'] = reason;

      final response = await _httpClient.post(
        '${ApiConstants.trades}/$tradeId/reject',
        body: body.isNotEmpty ? body : null,
        fromJson: (json) => Trade.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<Trade>> cancelTrade(String tradeId, {String? reason}) async {
    try {
      final body = <String, dynamic>{};
      if (reason != null) body['reason'] = reason;

      final response = await _httpClient.post(
        '${ApiConstants.trades}/$tradeId/cancel',
        body: body.isNotEmpty ? body : null,
        fromJson: (json) => Trade.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<Trade>> completeTrade(String tradeId) async {
    try {
      final response = await _httpClient.post(
        '${ApiConstants.trades}/$tradeId/complete',
        fromJson: (json) => Trade.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<List<Trade>>> getTradesByProductId(String productId) async {
    try {
      final response = await _httpClient.get(
        '${ApiConstants.products}/$productId/trades',
        fromJson: (json) => (json['trades'] as List)
            .map((item) => Trade.fromJson(item))
            .toList(),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<List<Trade>>> getPendingTrades() async {
    try {
      final response = await _httpClient.get(
        '${ApiConstants.trades}/pending',
        fromJson: (json) => (json['trades'] as List)
            .map((item) => Trade.fromJson(item))
            .toList(),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<List<Trade>>> getCompletedTrades() async {
    try {
      final response = await _httpClient.get(
        '${ApiConstants.trades}/completed',
        fromJson: (json) => (json['trades'] as List)
            .map((item) => Trade.fromJson(item))
            .toList(),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<Map<String, int>>> getTradeStatistics() async {
    try {
      final response = await _httpClient.get(
        '${ApiConstants.trades}/statistics',
        fromJson: (json) => Map<String, int>.from(json),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<TradeOffer>> createTradeOffer({
    required String tradeId,
    required String productId,
    String? message,
  }) async {
    try {
      final response = await _httpClient.post(
        '${ApiConstants.trades}/$tradeId/offers',
        body: {
          'productId': productId,
          if (message != null) 'message': message,
        },
        fromJson: (json) => TradeOffer.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<List<TradeOffer>>> getTradeOffers(String tradeId) async {
    try {
      final response = await _httpClient.get(
        '${ApiConstants.trades}/$tradeId/offers',
        fromJson: (json) => (json['offers'] as List)
            .map((item) => TradeOffer.fromJson(item))
            .toList(),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  /// Takas başlatma endpoint'i
  Future<ApiResponse<StartTradeResponse>> startTrade({
    required String userToken,
    required int senderProductID,
    required int receiverProductID,
    required int deliveryTypeID,
    String? meetingLocation,
  }) async {
    try {
      Logger.info('Takas başlatma isteği gönderiliyor...', tag: _tag);
      
      final request = StartTradeRequest(
        userToken: userToken,
        senderProductID: senderProductID,
        receiverProductID: receiverProductID,
        deliveryTypeID: deliveryTypeID,
        meetingLocation: meetingLocation,
      );

      final response = await _httpClient.post(
        ApiConstants.startTrade,
        body: request.toJson(),
        fromJson: (json) => StartTradeResponse.fromJson(json),
      );

      if (response.isSuccess) {
        Logger.info('Takas başlatma başarılı: ${response.data?.data?.message}', tag: _tag);
      } else {
        Logger.error('Takas başlatma hatası: ${response.error}', tag: _tag);
      }

      return response;
    } catch (e) {
      Logger.error('Takas başlatma exception: $e', tag: _tag);
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  /// Takas durumları endpoint'i
  Future<ApiResponse<TradeStatusesResponse>> getTradeStatuses() async {
    try {
      Logger.info('Takas durumları yükleniyor...', tag: _tag);
      
      final response = await _httpClient.getWithBasicAuth(
        ApiConstants.tradeStatuses,
        fromJson: (json) => TradeStatusesResponse.fromJson(json),
      );

      if (response.isSuccess) {
        Logger.info('Takas durumları başarıyla yüklendi: ${response.data?.data?.statuses?.length ?? 0} durum', tag: _tag);
      } else {
        Logger.error('Takas durumları yükleme hatası: ${response.error}', tag: _tag);
      }

      return response;
    } catch (e) {
      Logger.error('Takas durumları exception: $e', tag: _tag);
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  /// Teslimat türleri endpoint'i
  Future<ApiResponse<DeliveryTypesResponse>> getDeliveryTypes() async {
    try {
      Logger.info('Teslimat türleri yükleniyor...', tag: _tag);
      
      final response = await _httpClient.getWithBasicAuth(
        ApiConstants.deliveryTypes,
        fromJson: (json) => DeliveryTypesResponse.fromJson(json),
      );

      if (response.isSuccess) {
        Logger.info('Teslimat türleri başarıyla yüklendi: ${response.data?.data?.deliveryTypes?.length ?? 0} tür', tag: _tag);
      } else {
        Logger.error('Teslimat türleri yükleme hatası: ${response.error}', tag: _tag);
      }

      return response;
    } catch (e) {
      Logger.error('Teslimat türleri exception: $e', tag: _tag);
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }
} 