import '../core/http_client.dart';
import '../core/constants.dart';
import '../models/trade.dart';
import '../models/trade_detail.dart';
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

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.startTrade,
        body: request.toJson(),
        fromJson: (json) => StartTradeResponse.fromJson(json),
        useBasicAuth: true,
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

  /// Takas tamamlama endpoint'i
  Future<ApiResponse<TradeCompleteResponse>> completeTradeWithStatus({
    required String userToken,
    required int offerID,
    required int statusID,
    String? meetingLocation,
    TradeReview? review,
  }) async {
    try {
      Logger.info('Takas tamamlama isteği gönderiliyor...', tag: _tag);
      
      final request = TradeCompleteRequest(
        userToken: userToken,
        offerID: offerID,
        statusID: statusID,
        meetingLocation: meetingLocation,
        review: review,
      );

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.tradeComplete,
        body: request.toJson(),
        fromJson: (json) => TradeCompleteResponse.fromJson(json),
        useBasicAuth: true,
      );

      if (response.isSuccess) {
        Logger.info('Takas tamamlama başarılı: ${response.data?.data?.message}', tag: _tag);
      } else {
        Logger.error('Takas tamamlama hatası: ${response.error}', tag: _tag);
      }

      return response;
    } catch (e) {
      Logger.error('Takas tamamlama exception: $e', tag: _tag);
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  /// Kullanıcının takasları endpoint'i
  Future<ApiResponse<UserTradesResponse>> getUserTrades(int userId) async {
    try {
      Logger.info('Kullanıcı takasları yükleniyor... UserID: $userId', tag: _tag);
      
      final response = await _httpClient.getWithBasicAuth(
        '${ApiConstants.userTrades}/$userId/tradeList',
        fromJson: (json) => UserTradesResponse.fromJson(json),
      );

      if (response.isSuccess) {
        final tradesCount = response.data?.data?.trades?.length ?? 0;
        Logger.info('Kullanıcı takasları başarıyla yüklendi: $tradesCount takas', tag: _tag);
        
        // Debug: Her trade'i logla
        if (response.data?.data?.trades != null) {
          for (var trade in response.data!.data!.trades!) {
            Logger.debug('Trade: offerID=${trade.offerID}, statusID=${trade.statusID}, statusTitle=${trade.statusTitle}, cancelDesc="${trade.cancelDesc}"', tag: _tag);
          }
        }
      } else {
        Logger.error('Kullanıcı takasları yükleme hatası: ${response.error}', tag: _tag);
      }

      return response;
    } catch (e) {
      Logger.error('Kullanıcı takasları exception: $e', tag: _tag);
      // Exception durumunda boş response döndür
      return ApiResponse.success(UserTradesResponse(
        error: false,
        success: true,
        data: UserTradesData(trades: []),
      ));
    }
  }

  /// Takas onaylama endpoint'i
  Future<ApiResponse<ConfirmTradeResponse>> confirmTrade({
    required String userToken,
    required int offerID,
    required bool isConfirm,
    String? cancelDesc,
  }) async {
    try {
      Logger.info('Takas onaylama isteği gönderiliyor... OfferID: $offerID, Onay: $isConfirm', tag: _tag);
      
      final request = ConfirmTradeRequest(
        userToken: userToken,
        offerID: offerID,
        isConfirm: isConfirm ? 1 : 0,
        cancelDesc: cancelDesc ?? '',
      );

      Logger.debug('Takas onaylama request: ${request.toJson()}', tag: _tag);

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.confirmTrade,
        body: request.toJson(),
        fromJson: (json) => ConfirmTradeResponse.fromJson(json),
        useBasicAuth: true,
      );

      if (response.isSuccess) {
        Logger.info('Takas onaylama başarılı: ${response.data?.data?.message}', tag: _tag);
      } else {
        Logger.error('Takas onaylama hatası: ${response.error}', tag: _tag);
      }

      return response;
    } catch (e) {
      Logger.error('Takas onaylama exception: $e', tag: _tag);
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  /// Takas durumu güncelleme endpoint'i
  Future<ApiResponse<ConfirmTradeResponse>> updateTradeStatus({
    required String userToken,
    required int offerID,
    required int statusID,
  }) async {
    try {
      Logger.info('Takas durumu güncelleme isteği gönderiliyor... OfferID: $offerID, Yeni Durum: $statusID', tag: _tag);
      
      final request = {
        'userToken': userToken,
        'offerID': offerID,
        'statusID': statusID,
      };

      Logger.debug('Takas durumu güncelleme request: $request', tag: _tag);

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.updateTradeStatus,
        body: request,
        fromJson: (json) => ConfirmTradeResponse.fromJson(json),
        useBasicAuth: true,
      );

      if (response.isSuccess) {
        Logger.info('Takas durumu güncelleme başarılı: ${response.data?.data?.message}', tag: _tag);
      } else {
        Logger.error('Takas durumu güncelleme hatası: ${response.error}', tag: _tag);
      }

      return response;
    } catch (e) {
      Logger.error('Takas durumu güncelleme exception: $e', tag: _tag);
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  /// Takas tamamlandığında yorum ve yıldız ile birlikte tamamla
  Future<ApiResponse<ConfirmTradeResponse>> completeTradeWithReview({
    required String userToken,
    required int offerID,
    required int statusID,
    required int toUserID,
    required int rating,
    required String comment,
  }) async {
    try {
      Logger.info('Takas tamamlama ve yorum gönderme isteği gönderiliyor... OfferID: $offerID, Rating: $rating', tag: _tag);
      
      final request = {
        'userToken': userToken,
        'offerID': offerID,
        'statusID': statusID,
        'review': {
          'toUserID': toUserID,
          'rating': rating,
          'comment': comment,
        },
      };

      Logger.debug('Takas tamamlama request: $request', tag: _tag);

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.tradeComplete,
        body: request,
        fromJson: (json) => ConfirmTradeResponse.fromJson(json),
        useBasicAuth: true,
      );

      if (response.isSuccess) {
        Logger.info('Takas tamamlama ve yorum gönderme başarılı: ${response.data?.data?.message}', tag: _tag);
      } else {
        Logger.error('Takas tamamlama hatası: ${response.error}', tag: _tag);
      }

      return response;
    } catch (e) {
      Logger.error('Takas tamamlama exception: $e', tag: _tag);
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  /// Takas kontrolü endpoint'i
  Future<ApiResponse<CheckTradeStatusResponse>> checkTradeStatus({
    required String userToken,
    required int senderProductID,
    required int receiverProductID,
  }) async {
    try {
      Logger.info('Takas kontrolü isteği gönderiliyor... SenderProductID: $senderProductID, ReceiverProductID: $receiverProductID', tag: _tag);
      
      final request = CheckTradeStatusRequest(
        userToken: userToken,
        senderProductID: senderProductID,
        receiverProductID: receiverProductID,
      );

      Logger.debug('Takas kontrolü request: ${request.toJson()}', tag: _tag);

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.checkTradeStatus,
        body: request.toJson(),
        fromJson: (json) => CheckTradeStatusResponse.fromJson(json),
        useBasicAuth: true,
      );

      if (response.isSuccess) {
        final data = response.data?.data;
        Logger.info('Takas kontrolü başarılı: success=${data?.success}, isSender=${data?.isSender}, isReceiver=${data?.isReceiver}, showButtons=${data?.showButtons}, message=${data?.message}', tag: _tag);
      } else {
        Logger.error('Takas kontrolü hatası: ${response.error}', tag: _tag);
      }

      return response;
    } catch (e) {
      Logger.error('Takas kontrolü exception: $e', tag: _tag);
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  /// Takas detayı getir
  Future<ApiResponse<TradeDetail>> getTradeDetail({
    required String userToken,
    required int offerID,
  }) async {
    try {
      Logger.info('Takas detayı getirme isteği gönderiliyor... OfferID: $offerID', tag: _tag);
      
      final endpoint = '${ApiConstants.tradeDetail}/$offerID/tradeDetail';
      final queryParams = {'userToken': userToken};
      
      Logger.debug('Takas detayı endpoint: $endpoint', tag: _tag);
      Logger.debug('Takas detayı query params: $queryParams', tag: _tag);

      final response = await _httpClient.getWithBasicAuth(
        endpoint,
        queryParams: queryParams,
        fromJson: (json) {
          Logger.debug('Takas detayı response: $json', tag: _tag);
          // API response'unda data field'ı var, onu parse et
          if (json is Map<String, dynamic> && json.containsKey('data')) {
            Logger.debug('Takas detayı data field bulundu: ${json['data']}', tag: _tag);
            return TradeDetail.fromJson(json['data']);
          } else {
            Logger.debug('Takas detayı direkt json parse ediliyor', tag: _tag);
            return TradeDetail.fromJson(json);
          }
        },
      );

      if (response.isSuccess) {
        final data = response.data;
        // Null değerleri güvenli bir şekilde log'la
        final offerID = data?.offerID ?? 0;
        final senderStatusTitle = data?.senderStatusTitle ?? 'Bilinmeyen';
        final receiverStatusTitle = data?.receiverStatusTitle ?? 'Bilinmeyen';
        final senderName = data?.sender.userName ?? 'Bilinmeyen';
        final receiverName = data?.receiver.userName ?? 'Bilinmeyen';
        Logger.info('Takas detayı başarılı: OfferID=$offerID, SenderStatus=$senderStatusTitle, ReceiverStatus=$receiverStatusTitle, Sender=$senderName, Receiver=$receiverName', tag: _tag);
      } else {
        Logger.error('Takas detayı hatası: ${response.error}', tag: _tag);
      }

      return response;
    } catch (e) {
      Logger.error('Takas detayı exception: $e', tag: _tag);
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }
} 