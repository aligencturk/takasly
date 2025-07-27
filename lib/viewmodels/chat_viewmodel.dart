import 'package:flutter/foundation.dart';
import '../models/chat.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../services/firebase_chat_service.dart';
import '../utils/logger.dart';

class ChatViewModel extends ChangeNotifier {
  static const String _tag = 'ChatViewModel';
  
  final FirebaseChatService _chatService = FirebaseChatService();
  
  List<Chat> _chats = [];
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;
  String? _currentChatId;
  String? _currentUserId;
  Map<String, int> _chatUnreadCounts = {};

  // Getters
  List<Chat> get chats => _chats;
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;
  String? get currentChatId => _currentChatId;
  Map<String, int> get chatUnreadCounts => _chatUnreadCounts;

  // Chat'leri yükle
  void loadChats(String userId) {
    _currentUserId = userId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _chatService.getChatsStream(userId).listen(
        (chats) {
          _chats = chats;
          _isLoading = false;
          // Her chat için unread count hesapla
          _calculateChatUnreadCounts();
          notifyListeners();
        },
        onError: (error) {
          _error = error.toString();
          _isLoading = false;
          notifyListeners();
          Logger.error('Chat yükleme hatası: $error', tag: _tag);
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      Logger.error('Chat yükleme hatası: $e', tag: _tag);
    }
  }

  // Mesajları yükle
  void loadMessages(String chatId) {
    _currentChatId = chatId;
    _messages = [];
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _chatService.getMessagesStream(chatId).listen(
        (messages) {
          _messages = messages;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _error = error.toString();
          _isLoading = false;
          notifyListeners();
          Logger.error('Mesaj yükleme hatası: $error', tag: _tag);
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      Logger.error('Mesaj yükleme hatası: $e', tag: _tag);
    }
  }

  // Mesaj gönder
  Future<void> sendMessage({
    required String chatId,
    required String content,
    required String senderId,
    MessageType type = MessageType.text,
    String? imageUrl,
    String? replyToId,
    Product? product,
  }) async {
    try {
      await _chatService.sendMessage(
        chatId: chatId,
        content: content,
        senderId: senderId,
        type: type,
        imageUrl: imageUrl,
        replyToId: replyToId,
        product: product,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      Logger.error('Mesaj gönderme hatası: $e', tag: _tag);
    }
  }

  // Product mesajı gönder
  Future<void> sendProductMessage({
    required String chatId,
    required Product product,
    required String senderId,
  }) async {
    try {
      await _chatService.sendMessage(
        chatId: chatId,
        content: 'İlan gönderdi: ${product.title}',
        senderId: senderId,
        type: MessageType.product,
        product: product,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      Logger.error('Product mesaj gönderme hatası: $e', tag: _tag);
    }
  }

  // Mesajı okundu olarak işaretle
  Future<void> markMessageAsRead(String chatId, String messageId) async {
    try {
      await _chatService.markMessageAsRead(chatId, messageId);
    } catch (e) {
      Logger.error('Mesaj okundu işaretleme hatası: $e', tag: _tag);
    }
  }

  // Mesajı sil
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _chatService.deleteMessage(chatId, messageId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      Logger.error('Mesaj silme hatası: $e', tag: _tag);
    }
  }

  // Chat oluştur
  Future<String?> createChat({
    required String tradeId,
    required List<String> participantIds,
  }) async {
    try {
      final chatId = await _chatService.createChat(
        tradeId: tradeId,
        participantIds: participantIds,
      );
      return chatId;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      Logger.error('Chat oluşturma hatası: $e', tag: _tag);
      return null;
    }
  }

  // Okunmamış mesaj sayısını yükle
  void loadUnreadCount(String userId) {
    try {
      _chatService.getUnreadCountStream(userId).listen(
        (count) {
          _unreadCount = count;
          notifyListeners();
        },
        onError: (error) {
          Logger.error('Okunmamış mesaj sayısı yükleme hatası: $error', tag: _tag);
        },
      );
    } catch (e) {
      Logger.error('Okunmamış mesaj sayısı yükleme hatası: $e', tag: _tag);
    }
  }

  // Hata temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Loading durumunu temizle
  void clearLoading() {
    _isLoading = false;
    notifyListeners();
  }

  // Mesajları temizle
  void clearMessages() {
    _messages = [];
    _currentChatId = null;
    notifyListeners();
  }

  // Chat'leri temizle
  void clearChats() {
    _chats = [];
    notifyListeners();
  }

  // Her chat için unread count hesapla
  void _calculateChatUnreadCounts() {
    _chatUnreadCounts.clear();
    
    for (final chat in _chats) {
      int unreadCount = 0;
      
      // Bu chat'teki mesajları kontrol et
      for (final message in _messages) {
        if (message.chatId == chat.id && 
            message.senderId != _currentUserId && 
            !message.isRead && 
            !message.isDeleted) {
          unreadCount++;
        }
      }
      
      _chatUnreadCounts[chat.id] = unreadCount;
    }
  }
} 