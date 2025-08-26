import '../core/http_client.dart';
import '../core/constants.dart';
import '../models/chat.dart';

class ChatService {
  final HttpClient _httpClient = HttpClient();

  Future<ApiResponse<List<Chat>>> getChats({
    int page = 1,
    int limit = AppConstants.defaultPageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      final response = await _httpClient.get(
        ApiConstants.chat,
        queryParams: queryParams,
        fromJson: (json) => (json['chats'] as List)
            .map((item) => Chat.fromJson(item))
            .toList(),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<Chat>> getChatById(String chatId) async {
    try {
      final response = await _httpClient.get(
        '${ApiConstants.chat}/$chatId',
        fromJson: (json) => Chat.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<Chat>> getChatByTradeId(String tradeId) async {
    try {
      final response = await _httpClient.get(
        '${ApiConstants.chat}/trade/$tradeId',
        fromJson: (json) => Chat.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<List<Message>>> getMessages(
    String chatId, {
    int page = 1,
    int limit = AppConstants.defaultPageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      final response = await _httpClient.get(
        '${ApiConstants.chat}/$chatId/messages',
        queryParams: queryParams,
        fromJson: (json) => (json['messages'] as List)
            .map((item) => Message.fromJson(item))
            .toList(),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<Message>> sendMessage({
    required String chatId,
    required String content,
    MessageType type = MessageType.text,
    String? imageUrl,
    String? replyToId,
  }) async {
    try {
      final body = {
        'content': content,
        'type': type.name,
      };

      if (imageUrl != null) body['imageUrl'] = imageUrl;
      if (replyToId != null) body['replyToId'] = replyToId;

      final response = await _httpClient.post(
        '${ApiConstants.chat}/$chatId/messages',
        body: body,
        fromJson: (json) => Message.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<void>> markAsRead(String chatId, String messageId) async {
    try {
      final response = await _httpClient.post(
        '${ApiConstants.chat}/$chatId/messages/$messageId/read',
        fromJson: (json) => null,
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<void>> markChatAsRead(String chatId) async {
    try {
      final response = await _httpClient.post(
        '${ApiConstants.chat}/$chatId/read',
        fromJson: (json) => null,
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<void>> deleteMessage(String chatId, String messageId) async {
    try {
      final response = await _httpClient.delete(
        '${ApiConstants.chat}/$chatId/messages/$messageId',
        fromJson: (json) => null,
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<int>> getUnreadCount() async {
    try {
      final response = await _httpClient.get(
        '${ApiConstants.chat}/unread-count',
        fromJson: (json) => json['count'] as int,
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<Message>> sendTradeOfferMessage({
    required String chatId,
    required String tradeId,
    required String message,
  }) async {
    try {
      final response = await _httpClient.post(
        '${ApiConstants.chat}/$chatId/trade-offer',
        body: {
          'tradeId': tradeId,
          'message': message,
        },
        fromJson: (json) => Message.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<Message>> sendTradeStatusMessage({
    required String chatId,
    required String tradeId,
    required String status,
    String? message,
  }) async {
    try {
      final body = {
        'tradeId': tradeId,
        'status': status,
      };

      if (message != null) body['message'] = message;

      final response = await _httpClient.post(
        '${ApiConstants.chat}/$chatId/trade-status',
        body: body,
        fromJson: (json) => Message.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<String>> uploadImage(String filePath) async {
    try {
      // Bu gerçek implementasyonda multipart/form-data olarak implement edilecek
      // Şimdilik mock response döndürüyoruz
      final response = await _httpClient.post(
        '${ApiConstants.chat}/upload-image',
        body: {
          'filePath': filePath,
        },
        fromJson: (json) => json['imageUrl'] as String,
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }
} 