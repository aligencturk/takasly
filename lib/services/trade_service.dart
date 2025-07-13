import '../core/http_client.dart';
import '../core/constants.dart';
import '../models/trade.dart';

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
} 