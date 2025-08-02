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
  bool _isLoadingMore = false; // Pagination için
  String? _error;
  int _unreadCount = 0;
  String? _currentChatId;
  String? _currentUserId;
  Map<String, int> _chatUnreadCounts = {};
  bool _hasMoreMessages = true; // Daha fazla mesaj var mı?

  // Getters
  List<Chat> get chats => _chats;
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  int get unreadCount => _unreadCount;
  String? get currentChatId => _currentChatId;
  Map<String, int> get chatUnreadCounts => _chatUnreadCounts;
  bool get hasMoreMessages => _hasMoreMessages;

  // Chat'leri yükle
  void loadChats(String userId) {
    // Eğer zaten yükleniyorsa tekrar yükleme
    if (_isLoading) {
      Logger.info('ChatViewModel: Zaten yükleniyor, tekrar yükleme yapılmıyor', tag: _tag);
      return;
    }
    
    _currentUserId = userId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Logger.info('ChatViewModel: Chat\'ler yükleniyor... userId= [1m$userId [0m', tag: _tag);
      
      // Minimum loading süresi için timer
      final loadingStartTime = DateTime.now();
      
      _chatService.getChatsStream(userId).listen(
        (chats) {
          Logger.info('ChatViewModel:  [1m${chats.length} [0m chat yüklendi', tag: _tag);
          for (final chat in chats) {
            Logger.debug('ChatViewModel: Chat ${chat.id} - tradeId=${chat.tradeId} - lastMessage: ${chat.lastMessage?.content ?? 'null'}', tag: _tag);
          }
          // Kullanıcı tarafından silinenleri filtrele
          final filteredChats = chats.where((chat) => !chat.deletedBy.contains(userId)).toList();
          _chats = filteredChats;
          
          // Minimum 500ms loading göster
          final loadingDuration = DateTime.now().difference(loadingStartTime);
          if (loadingDuration.inMilliseconds < 500) {
            Future.delayed(Duration(milliseconds: 500 - loadingDuration.inMilliseconds), () {
              _isLoading = false;
              // Her chat için unread count hesapla
              _calculateChatUnreadCounts();
              notifyListeners();
            });
          } else {
            _isLoading = false;
            // Her chat için unread count hesapla
            _calculateChatUnreadCounts();
            notifyListeners();
          }
        },
        onError: (error) {
          _error = error.toString();
          _isLoading = false;
          notifyListeners();
          Logger.error('ChatViewModel: Chat yükleme hatası: $error', tag: _tag);
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      Logger.error('ChatViewModel: Chat yükleme hatası: $e', tag: _tag);
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
          // Unread count'ları güncelle
          _calculateChatUnreadCounts();
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

  // Mesajları okundu olarak işaretle
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      // Bu chat'teki okunmamış mesajları bul
      final unreadMessages = _messages.where((message) => 
        message.chatId == chatId && 
        message.senderId != userId && 
        !message.isRead && 
        !message.isDeleted
      ).toList();
      
      // Her okunmamış mesajı işaretle
      for (final message in unreadMessages) {
        await _chatService.markMessageAsRead(chatId, message.id);
      }
      
      // Unread count'ları güncelle
      _calculateChatUnreadCounts();
      notifyListeners();
      
      Logger.info('${unreadMessages.length} mesaj okundu olarak işaretlendi', tag: _tag);
    } catch (e) {
      Logger.error('Mesaj okundu işaretleme hatası: $e', tag: _tag);
    }
  }

  // Belirli bir mesajı okundu olarak işaretle
  Future<void> markMessageAsRead(String chatId, String messageId) async {
    try {
      await _chatService.markMessageAsRead(chatId, messageId);
      
      // Unread count'ları güncelle
      _calculateChatUnreadCounts();
      notifyListeners();
      
      Logger.info('Mesaj okundu olarak işaretlendi: $messageId', tag: _tag);
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
      Logger.info('ChatViewModel: Chat oluşturma isteği - tradeId=$tradeId, participants=$participantIds', tag: _tag);
      
      final chatId = await _chatService.createChat(
        tradeId: tradeId,
        participantIds: participantIds,
      );
      
      Logger.info('ChatViewModel: Chat başarıyla oluşturuldu - chatId=$chatId', tag: _tag);
      return chatId;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      Logger.error('ChatViewModel: Chat oluşturma hatası: $e', tag: _tag);
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

  // Daha eski mesajları yükle (pagination)
  Future<void> loadOlderMessages() async {
    if (_isLoadingMore || !_hasMoreMessages || _messages.isEmpty) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    try {
      // En eski mesajın zamanını al
      final oldestMessage = _messages.first;
      final olderMessages = await _chatService.loadOlderMessages(
        _currentChatId!,
        oldestMessage.createdAt,
        limit: 20,
      );
      
      if (olderMessages.isNotEmpty) {
        // Yeni mesajları listenin başına ekle
        _messages.insertAll(0, olderMessages);
        
        // Eğer 20'den az mesaj geldiyse, daha fazla mesaj yok demektir
        if (olderMessages.length < 20) {
          _hasMoreMessages = false;
        }
      } else {
        _hasMoreMessages = false;
      }
      
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoadingMore = false;
      notifyListeners();
      Logger.error('Eski mesaj yükleme hatası: $e', tag: _tag);
    }
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
    
    // Toplam unread count'u hesapla
    _unreadCount = _chatUnreadCounts.values.fold(0, (sum, count) => sum + count);
  }

  // Chat sil (soft delete)
  Future<void> deleteChat(String chatId) async {
    try {
      // Kullanıcı ID'sini al
      final currentUserId = _currentUserId;
      if (currentUserId == null) {
        Logger.error('ChatViewModel: currentUserId null, chat silinemez', tag: _tag);
        return;
      }

      Logger.info('ChatViewModel: Chat silme işlemi başlatılıyor - chatId=$chatId, currentUserId=$currentUserId', tag: _tag);

      // Chat'i bul
      final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
      if (chatIndex == -1) {
        Logger.error('ChatViewModel: Chat bulunamadı - chatId=$chatId', tag: _tag);
        return;
      }

      final chat = _chats[chatIndex];
      Logger.info('ChatViewModel: Chat bulundu - chatId=$chatId, currentDeletedBy=${chat.deletedBy}', tag: _tag);
      
      // deletedBy listesine kullanıcı ID'sini ekle
      final updatedDeletedBy = List<String>.from(chat.deletedBy)..add(currentUserId);
      final updatedChat = chat.copyWith(deletedBy: updatedDeletedBy);
      
      // Local listeyi güncelle - chat'i listeden kaldır
      _chats.removeAt(chatIndex);
      
      // Firebase'e güncelle
      await _chatService.updateChatDeletedBy(chatId, updatedDeletedBy);
      
      // Unread count'ları güncelle
      _calculateChatUnreadCounts();
      
      // Güvenli şekilde notifyListeners çağır
      try {
        notifyListeners();
      } catch (e) {
        Logger.warning('ChatViewModel: notifyListeners hatası (widget dispose edilmiş olabilir): $e', tag: _tag);
      }
      
      Logger.info('ChatViewModel: Chat başarıyla silindi - chatId=$chatId', tag: _tag);
    } catch (e) {
      _error = e.toString();
      try {
        notifyListeners();
      } catch (notifyError) {
        Logger.warning('ChatViewModel: notifyListeners hatası (widget dispose edilmiş olabilir): $notifyError', tag: _tag);
      }
      Logger.error('ChatViewModel: Chat silme hatası: $e', tag: _tag);
      rethrow;
    }
  }

  // Chat sabitle / sabiti kaldır
  void togglePinChat(String chatId) {
    try {
      final index = _chats.indexWhere((chat) => chat.id == chatId);
      if (index != -1) {
        final chat = _chats[index];
        _chats[index] = chat.copyWith(isPinned: !(chat.isPinned));
        try {
          notifyListeners();
        } catch (e) {
          Logger.warning('ChatViewModel: togglePinChat notifyListeners hatası: $e', tag: _tag);
        }
      }
    } catch (e) {
      Logger.error('Chat sabitleme hatası: $e', tag: _tag);
    }
  }

  // Boş chat'i sil (WhatsApp mantığı - mesaj gönderilmeden çıkılırsa)
  Future<void> deleteEmptyChat(String chatId) async {
    try {
      // Chat'teki mesajları kontrol et
      final chatMessages = _messages.where((message) => message.chatId == chatId).toList();
      
      // Eğer hiç mesaj yoksa chat'i sil
      if (chatMessages.isEmpty) {
        await _chatService.deleteChat(chatId);
        
        // Local listeyi güncelle
        _chats.removeWhere((chat) => chat.id == chatId);
        try {
          notifyListeners();
        } catch (e) {
          Logger.warning('ChatViewModel: deleteEmptyChat notifyListeners hatası: $e', tag: _tag);
        }
        
        Logger.info('Boş chat silindi: $chatId', tag: _tag);
      }
    } catch (e) {
      Logger.error('Boş chat silme hatası: $e', tag: _tag);
    }
  }

  // Chat'i id ile getir
  Future<Chat?> getChatById(String chatId) async {
    try {
      Logger.info('ChatViewModel: getChatById çağrıldı - chatId=$chatId', tag: _tag);
      final chat = await _chatService.getChatById(chatId);
      return chat;
    } catch (e) {
      Logger.error('ChatViewModel: getChatById hatası: $e', tag: _tag);
      return null;
    }
  }
} 