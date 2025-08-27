import 'package:takasly/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../services/cache_service.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../models/chat.dart';
import '../../models/product.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../views/product/product_detail_view.dart';
import '../../views/trade/start_trade_view.dart';
import '../../views/profile/user_profile_detail_view.dart';
import '../../widgets/report_dialog.dart';
import '../../widgets/user_block_dialog.dart';
import '../../widgets/profanity_check_chat_input.dart';
import '../../services/profanity_service.dart';
import '../../models/profanity_check_result.dart';
import '../../utils/logger.dart';

class ChatDetailView extends StatefulWidget {
  final Chat chat;

  const ChatDetailView({super.key, required this.chat});

  @override
  State<ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<ChatDetailView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasMessageSent = false; // Mesaj gönderildi mi kontrolü için
  Product? _chatProduct; // Chat'e ait ürün bilgisi
  bool _isDisposed = false; // Widget dispose edildi mi kontrolü için
  bool _isMessagingBlocked = false; // Karşı taraf engelliyse mesaj gönderimi kapalı

  @override
  void initState() {
    super.initState();

    // Scroll listener ekle - yukarı scroll ettiğinde eski mesajları yükle
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
      _checkMessagingBlocked();
      // Sayfa açıldığında en aşağıya scroll et
      _scrollToBottom();
    });
  }

  @override
  void deactivate() {
    // Widget deaktive edildiğinde (sayfa değiştiğinde) boş chat'i temizle
    _cleanupEmptyChat();
    super.deactivate();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _cleanupEmptyChat() {
    // Eğer hiç mesaj gönderilmediyse ve widget hala mounted ise
    if (!_isDisposed && !_hasMessageSent) {
      try {
        final chatViewModel = context.read<ChatViewModel>();
        final chatMessages = chatViewModel.messages
            .where((message) => message.chatId == widget.chat.id)
            .toList();

        // Eğer hiç mesaj yoksa chat'i sil
        if (chatMessages.isEmpty) {
          chatViewModel.deleteEmptyChat(widget.chat.id);
        }
      } catch (e) {
        // Context artık geçerli değilse veya Provider erişim hatası varsa
        // Bu durumda hiçbir şey yapma, sadece logla
        Logger.error(
          'ChatDetailView: _cleanupEmptyChat hatası (widget dispose edilmiş olabilir): $e',
        );
      }
    }
  }

  void _onScroll() {
    // Yukarı scroll edildiğinde ve en üstteyse eski mesajları yükle
    if (!_isDisposed &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100) {
      try {
        final chatViewModel = context.read<ChatViewModel>();
        if (chatViewModel.hasMoreMessages && !chatViewModel.isLoadingMore) {
          chatViewModel.loadOlderMessages();
        }
      } catch (e) {
        // Context artık geçerli değilse hata yakala
        Logger.error(
          'ChatDetailView: _onScroll hatası (widget dispose edilmiş olabilir): $e',
        );
      }
    }
  }

  void _loadMessages() {
    if (_isDisposed) return;

    try {
      final chatViewModel = context.read<ChatViewModel>();
      final authViewModel = context.read<AuthViewModel>();

      chatViewModel.loadMessages(widget.chat.id);

      // Chat'e ait ürün bilgisini yükle
      _loadChatProduct();

      // Chat açıldığında mesajları okundu olarak işaretle (kısa bir gecikme ile)
      if (authViewModel.currentUser != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            if (!_isDisposed) {
              final chatViewModel = context.read<ChatViewModel>();
              final authViewModel = context.read<AuthViewModel>();
              chatViewModel.markMessagesAsRead(
                widget.chat.id,
                authViewModel.currentUser!.id,
              );
            }
          } catch (e) {
            Logger.error(
              'ChatDetailView: markMessagesAsRead hatası (widget dispose edilmiş olabilir): $e',
            );
          }
        });
      }
    } catch (e) {
      Logger.error('ChatDetailView: _loadMessages hatası: $e');
    }
  }

  void _checkMessagingBlocked() {
    try {
      final authViewModel = context.read<AuthViewModel>();
      final otherParticipant = widget.chat.participants
          .where((user) => user.id != authViewModel.currentUser?.id)
          .firstOrNull;
      if (otherParticipant == null) return;

      final cacheService = CacheService();
      final blockedJson = cacheService.getBlockedUsers();
      if (blockedJson == null || blockedJson.isEmpty) {
        _isMessagingBlocked = false;
        if (!_isDisposed) setState(() {});
        return;
      }

      final List<dynamic> blockedList = jsonDecode(blockedJson);
      final blockedIds = blockedList
          .where((e) => e is Map<String, dynamic> && e.containsKey('blockedUserID'))
          .map((e) => int.tryParse(e['blockedUserID'].toString()))
          .whereType<int>()
          .toSet();

      final otherIdInt = int.tryParse(otherParticipant.id);
      _isMessagingBlocked = otherIdInt != null && blockedIds.contains(otherIdInt);
      if (!_isDisposed) setState(() {});
    } catch (e) {
      Logger.error('ChatDetailView: _checkMessagingBlocked hatası: $e');
    }
  }

  void _loadChatProduct() async {
    if (_isDisposed) return;

    try {
      // Öncelik: trade içindeki ürünler
      if (widget.chat.trade.offeredProducts.isNotEmpty) {
        _chatProduct = widget.chat.trade.offeredProducts.first;
        if (!_isDisposed) setState(() {});
        return;
      } else if (widget.chat.trade.requestedProducts.isNotEmpty) {
        _chatProduct = widget.chat.trade.requestedProducts.first;
        if (!_isDisposed) setState(() {});
        return;
      }

      // Eğer trade'de ürün yoksa, ürün mesajlarını kontrol et
      final chatViewModel = context.read<ChatViewModel>();
      final productMsgs = chatViewModel.messages.where(
        (m) => m.type == MessageType.product && m.product != null,
      );

      if (productMsgs.isNotEmpty) {
        // En son gönderilen ürün mesajını al
        _chatProduct = productMsgs.last.product;
        if (!_isDisposed) setState(() {});
        return;
      }

      // Eğer mesajlarda da yoksa, tradeId'den ürün bilgisini almaya çalış
      if (widget.chat.tradeId.isNotEmpty) {
        final productViewModel = context.read<ProductViewModel>();
        final product = await productViewModel.getProductDetail(
          widget.chat.tradeId,
        );
        if (!_isDisposed && product != null) {
          _chatProduct = product;
          setState(() {});
        }
      }
    } catch (e) {
      Logger.error('ChatDetailView: _loadChatProduct hatası: $e');
    }
  }

  // Mesajlar yüklendiğinde ürün bilgisini güncelle
  void _updateChatProductFromMessages() {
    if (_isDisposed) return;

    try {
      // Eğer chat'in üst kısmında zaten bir ürün varsa (trade'den gelen), mesajlardan ürün alma
      if (_chatProduct != null) {
        return;
      }

      final chatViewModel = context.read<ChatViewModel>();
      final productMsgs = chatViewModel.messages.where(
        (m) => m.type == MessageType.product && m.product != null,
      );

      if (productMsgs.isNotEmpty && _chatProduct == null) {
        // En son gönderilen ürün mesajını al
        _chatProduct = productMsgs.last.product;
        if (!_isDisposed) setState(() {});
      }
    } catch (e) {
      Logger.error('ChatDetailView: _updateChatProductFromMessages hatası: $e');
    }
  }

  void _sendMessage() {
    if (_isDisposed) return;
    if (_isMessagingBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bu kullanıcıyı engellediniz. Mesaj gönderemezsiniz.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Küfür kontrolü yap
    if (ProfanityService.instance.isInitialized) {
      final result = ProfanityService.instance.checkText(
        message,
        sensitivity: 'medium',
      );

      if (result.hasProfanity) {
        // Küfür tespit edildi, uyarı göster
        _showProfanityWarning(result);
        return;
      }
    } else {
      // ProfanityService başlatılmamışsa uyarı göster
      _showServiceNotInitializedWarning();
      return;
    }

    try {
      final authViewModel = context.read<AuthViewModel>();
      final chatViewModel = context.read<ChatViewModel>();

      if (authViewModel.currentUser != null) {
        chatViewModel.sendMessage(
          chatId: widget.chat.id,
          content: message,
          senderId: authViewModel.currentUser!.id,
        );
        _messageController.clear();
        _scrollToBottom();

        // Mesaj gönderildi flag'ini set et
        _hasMessageSent = true;

        // Mesaj gönderildikten sonra tüm mesajları okundu olarak işaretle (kısa gecikme ile)
        Future.delayed(const Duration(milliseconds: 300), () {
          try {
            if (!_isDisposed) {
              final chatViewModel = context.read<ChatViewModel>();
              final authViewModel = context.read<AuthViewModel>();
              chatViewModel.markMessagesAsRead(
                widget.chat.id,
                authViewModel.currentUser!.id,
              );
            }
          } catch (e) {
            Logger.error(
              'ChatDetailView: _sendMessage markMessagesAsRead hatası: $e',
            );
          }
        });
      }
    } catch (e) {
      Logger.error('ChatDetailView: _sendMessage hatası: $e');
    }
  }

  // ProfanityService başlatılmamış uyarısı
  void _showServiceNotInitializedWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Küfür kontrol servisi henüz başlatılmamış. Lütfen tekrar deneyin.',
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Küfür uyarısı gösterme metodu
  void _showProfanityWarning(ProfanityCheckResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getWarningIcon(result.level),
              color: _getWarningColor(result.level),
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Uygunsuz İçerik'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.message ?? 'Uygunsuz içerik tespit edildi'),
            if (result.detectedWord != null) ...[
              const SizedBox(height: 8),
              Text(
                'Tespit edilen: "${result.detectedWord}"',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Lütfen mesajınızı düzenleyip tekrar deneyin.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  // Uyarı rengi belirleme
  Color _getWarningColor(String level) {
    switch (level) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  // Uyarı ikonu belirleme
  IconData _getWarningIcon(String level) {
    switch (level) {
      case 'high':
        return Icons.block;
      case 'medium':
        return Icons.warning_amber_rounded;
      case 'low':
        return Icons.info_outline;
      default:
        return Icons.info_outline;
    }
  }

  void _scrollToBottom() {
    if (_isDisposed) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && _scrollController.hasClients) {
        // reverse: true olduğu için en üste scroll et (en yeni mesajlar aşağıda)
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showProductSelection() {
    try {
      final authViewModel = context.read<AuthViewModel>();
      final productViewModel = context.read<ProductViewModel>();

      // Kullanıcının kendi ürünlerini yükle
      productViewModel.loadUserProducts(authViewModel.currentUser!.id);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.inventory_2_rounded,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'İlanınızı Seçin',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Paylaşmak istediğiniz ilanı seçin',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.grey,
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Consumer<ProductViewModel>(
                  builder: (context, vm, child) {
                    if (vm.isLoading) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 20),
                            Text(
                              'İlanlarınız yükleniyor...',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (vm.userProducts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.inventory_2_outlined,
                                size: 56,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Henüz ilanınız yok',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'İlan ekledikten sonra burada\ngörünecek',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: vm.userProducts.length,
                      itemBuilder: (context, index) {
                        final product = vm.userProducts[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.pop(context);
                                _showMessageSelection(product);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Resim
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.grey[50],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: _buildProductImage(
                                          product.images.isNotEmpty
                                              ? product.images.first
                                              : '',
                                          60,
                                          60,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // İçerik
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primary
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  product.catname,
                                                  style: TextStyle(
                                                    color: AppTheme.primary,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const Spacer(),
                                              if (product.estimatedValue !=
                                                  null)
                                                Text(
                                                  '₺${product.estimatedValue!.toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 16,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Seçim göstergesi
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward_ios,
                                        color: AppTheme.primary,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      Logger.error('ChatDetailView: _showProductSelection hatası: $e');
    }
  }

  void _showMessageSelection(Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary,
                          AppTheme.primary.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.message_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mesaj Seçin',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'İsteğe bağlı olarak mesaj ekleyin',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!, width: 1),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 20,
                      ),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Mesaj seçenekleri
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Sadece ilan gönder butonu
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _sendProductOnly(product);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.send_rounded,
                              size: 20,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Sadece İlan Gönder',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Hazır mesajlar başlığı
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[100]!, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Hazır Mesajlar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Mesaj seçenekleri
                    Column(
                      children: [
                        _buildMessageOption(
                          'Bu ilanım var, ilgilenir misin?',
                          product,
                          Icons.question_mark_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildMessageOption(
                          'Bu ürünü beğendin mi?',
                          product,
                          Icons.favorite_border_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildMessageOption(
                          'Bu ilanım hoşuna gitti mi?',
                          product,
                          Icons.thumb_up_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildMessageOption(
                          'Bu ürünle ilgileniyor musun?',
                          product,
                          Icons.visibility_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildMessageOption(
                          'Bu ilanım nasıl? Beğendin mi?',
                          product,
                          Icons.star_outline_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageOption(String message, Product product, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(context);
            _sendProductWithMessage(product, message);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sendProductOnly(Product product) {
    if (_isDisposed) return;
    if (_isMessagingBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bu kullanıcıyı engellediniz. Mesaj gönderemezsiniz.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authViewModel = context.read<AuthViewModel>();
    final chatViewModel = context.read<ChatViewModel>();

    if (authViewModel.currentUser != null) {
      chatViewModel.sendProductMessage(
        chatId: widget.chat.id,
        product: product,
        senderId: authViewModel.currentUser!.id,
      );
      _scrollToBottom();

      // Mesaj gönderildi flag'ini set et
      _hasMessageSent = true;

      // Chat'e ait ürün bilgisini güncelleme kaldırıldı - bu chat'in üst kısmındaki ürün kartının değişmesine neden oluyordu
      // _chatProduct = product;
      // if (!_isDisposed) setState(() {});

      // Ürün mesajı gönderildikten sonra tüm mesajları okundu olarak işaretle (kısa gecikme ile)
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!_isDisposed) {
          chatViewModel.markMessagesAsRead(
            widget.chat.id,
            authViewModel.currentUser!.id,
          );
        }
      });
    }
  }

  void _sendProductWithMessage(Product product, String message) {
    if (_isDisposed) return;
    if (_isMessagingBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bu kullanıcıyı engellediniz. Mesaj gönderemezsiniz.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authViewModel = context.read<AuthViewModel>();
    final chatViewModel = context.read<ChatViewModel>();

    if (authViewModel.currentUser != null) {
      // Önce ürün mesajını gönder
      chatViewModel.sendProductMessage(
        chatId: widget.chat.id,
        product: product,
        senderId: authViewModel.currentUser!.id,
      );

      // Chat'e ait ürün bilgisini güncelleme kaldırıldı - bu chat'in üst kısmındaki ürün kartının değişmesine neden oluyordu
      // _chatProduct = product;
      // if (!_isDisposed) setState(() {});

      // Sonra seçilen mesajı gönder
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isDisposed) {
          chatViewModel.sendMessage(
            chatId: widget.chat.id,
            content: message,
            senderId: authViewModel.currentUser!.id,
          );
        }
      });

      _scrollToBottom();

      // Mesaj gönderildi flag'ini set et
      _hasMessageSent = true;

      // Mesajlar gönderildikten sonra tüm mesajları okundu olarak işaretle (kısa gecikme ile)
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!_isDisposed) {
          chatViewModel.markMessagesAsRead(
            widget.chat.id,
            authViewModel.currentUser!.id,
          );
        }
      });
    }
  }

  void _showReportDialog() {
    final authViewModel = context.read<AuthViewModel>();
    final otherParticipant = widget.chat.participants
        .where((user) => user.id != authViewModel.currentUser?.id)
        .firstOrNull;

    if (otherParticipant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kullanıcı bilgisi bulunamadı'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Kullanıcı kendini şikayet etmeye çalışıyorsa uyarı göster
    if (authViewModel.currentUser?.id == otherParticipant.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kendinizi şikayet edemezsiniz'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final userId = int.parse(otherParticipant.id);
      final productId = _chatProduct?.id != null
          ? int.tryParse(_chatProduct!.id)
          : null;

      showDialog(
        context: context,
        builder: (context) => ReportDialog(
          reportedUserID: userId,
          reportedUserName: otherParticipant.name,
          productID: productId,
        ),
      );
    } catch (e) {
      Logger.error('ChatDetailView: _showReportDialog hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Şikayet dialog açılamadı'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showBlockDialog() {
    final authViewModel = context.read<AuthViewModel>();
    final otherParticipant = widget.chat.participants
        .where((user) => user.id != authViewModel.currentUser?.id)
        .firstOrNull;

    if (otherParticipant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kullanıcı bilgisi bulunamadı'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Kullanıcı kendini engellemeye çalışıyorsa uyarı göster
    if (authViewModel.currentUser?.id == otherParticipant.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kendinizi engelleyemezsiniz'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final userId = int.parse(otherParticipant.id);

      showDialog(
        context: context,
        builder: (context) => UserBlockDialog(
          userId: userId,
          userName: otherParticipant.name,
          onUserBlocked: () {
            try {
              // Ürün listesini yenile
              final productVM = context.read<ProductViewModel>();
              productVM.refreshProducts();
            } catch (_) {}
            // PlatformView yeniden yaratma hatasını önlemek için rootNavigator ile yönlendir
            Navigator.of(context, rootNavigator: true)
                .pushNamedAndRemoveUntil('/home', (route) => false);
          },
        ),
      );
    } catch (e) {
      Logger.error('ChatDetailView: _showBlockDialog hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Engelleme dialog açılamadı'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _startTrade(BuildContext context, Product product) {
    final authViewModel = context.read<AuthViewModel>();

    // Kullanıcı giriş yapmamışsa login sayfasına yönlendir
    if (authViewModel.currentUser == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    // Kullanıcı kendi ürünüyle takas yapmaya çalışıyorsa uyarı göster
    if (authViewModel.currentUser!.id == product.ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Kendi ürününüzle takas yapamazsınız'),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Takas başlatma sayfasına yönlendir
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StartTradeView(receiverProduct: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sohbete ait ürün bilgisini kullan
    final chatProduct = _chatProduct;
    return ChangeNotifierProvider(
      create: (_) => UserViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: _buildAppBarTitle(),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            // Takas Başlat butonu
            if (chatProduct != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: ElevatedButton(
                  onPressed: _isMessagingBlocked ? null : () => _startTrade(context, chatProduct),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isMessagingBlocked ? Colors.grey[300] : Colors.white,
                    foregroundColor: _isMessagingBlocked ? Colors.grey[600] : AppTheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    minimumSize: const Size(0, 32),
                  ),
                  child: Text(
                    _isMessagingBlocked ? 'Engellendi' : 'Takas Başlat',
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.w600,
                      color: _isMessagingBlocked ? Colors.grey[600] : AppTheme.primary,
                    ),
                  ),
                ),
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'report') {
                  _showReportDialog();
                } else if (value == 'block') {
                  _showBlockDialog();
                }
              },
              itemBuilder: (context) {
                // Sadece giriş yapmış kullanıcılar için şikayet ve engelleme seçenekleri
                final authViewModel = context.read<AuthViewModel>();
                final items = <PopupMenuItem<String>>[];

                if (authViewModel.isLoggedIn) {
                  // Şikayet seçeneği her zaman göster
                  items.add(
                    PopupMenuItem<String>(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(
                            Icons.report_problem_outlined,
                            size: 20,
                            color: Colors.red[600],
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Kullanıcıyı Şikayet Et',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  
                  // Engelleme seçeneği sadece kullanıcı henüz engellenmemişse göster
                  if (!_isMessagingBlocked) {
                    items.add(
                      PopupMenuItem<String>(
                        value: 'block',
                        child: Row(
                          children: [
                            Icon(
                              Icons.block_outlined,
                              size: 20,
                              color: Colors.orange[600],
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Kullanıcıyı Engelle',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                }

                return items;
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Ürün kartı gösterimi (sohbete ait ürün varsa)
            if (chatProduct != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildChatProductCard(chatProduct),
              ),
            Expanded(
              child: Consumer<ChatViewModel>(
                builder: (context, chatViewModel, child) {
                  // Mesajlar yüklendiğinde ürün bilgisini güncelle (sadece chat'in üst kısmında ürün yoksa)
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!_isDisposed && _chatProduct == null) {
                      _updateChatProductFromMessages();
                    }
                  });

                  if (chatViewModel.isLoading &&
                      chatViewModel.messages.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (chatViewModel.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Mesajlar yüklenemedi',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            chatViewModel.error!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              chatViewModel.clearError();
                              _loadMessages();
                            },
                            child: const Text('Tekrar Dene'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (chatViewModel.messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz mesaj yok',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'İlk mesajı göndererek\nsohbeti başlatın',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        chatViewModel.messages.length +
                        (chatViewModel.isLoadingMore ? 1 : 0),
                    reverse: true, // Mesajları ters çevir - en yeni en aşağıda
                    itemBuilder: (context, index) {
                      // Loading indicator için
                      if (chatViewModel.isLoadingMore && index == 0) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Eski mesajlar yükleniyor...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Reverse olduğu için index'i ters çevir
                      final messageIndex = chatViewModel.isLoadingMore
                          ? index - 1
                          : index;
                      final message =
                          chatViewModel.messages[chatViewModel.messages.length -
                              1 -
                              messageIndex];
                      return _MessageBubble(
                        message: message,
                        isMe:
                            message.senderId ==
                            context.read<AuthViewModel>().currentUser?.id,
                        isMessagingBlocked: _isMessagingBlocked,
                      );
                    },
                  );
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatProductCard(Product product) {
    return GestureDetector(
      onTap: _isMessagingBlocked ? null : () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailView(productId: product.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        color: _isMessagingBlocked ? Colors.grey[100] : Colors.white,
        child: Row(
          children: [
            // Sol taraf - Resim
            Container(
              width: 50,
              height: 50,
              color: Colors.grey[50],
              child: _buildProductImage(
                product.images.isNotEmpty ? product.images.first : '',
                50,
                50,
              ),
            ),
            const SizedBox(width: 12),
            // Orta kısım - İçerik
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: _isMessagingBlocked ? Colors.grey[500] : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        product.catname,
                        style: TextStyle(
                          color: _isMessagingBlocked ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (product.estimatedValue != null)
                        Text(
                          '₺${product.estimatedValue!.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _isMessagingBlocked ? Colors.grey[500] : Colors.green,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Sağ taraf - Tıklama göstergesi veya engelleme ikonu
            if (_isMessagingBlocked)
              Icon(Icons.block, color: Colors.red[400], size: 16)
            else
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 14),
          ],
        ),
      ),
    );
  }

  // URL validasyonu için yardımcı metod
  bool _isValidImageUrl(String url) {
    if (url.isEmpty || url == 'null' || url == 'undefined') {
      return false;
    }

    try {
      final uri = Uri.parse(url);
      // file:/// protokolü ile başlayan URL'ler geçersiz
      if (uri.scheme == 'file') {
        return false;
      }
      // HTTP veya HTTPS protokolü olmalı
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (e) {
      return false;
    }
  }

  // Güvenli resim widget'ı
  Widget _buildProductImage(String imageUrl, double width, double height) {
    if (!_isValidImageUrl(imageUrl)) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[100],
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey[400],
          size: 20,
        ),
      );
    }

    return AppNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(8),
    );
  }

  Widget _buildAppBarTitle() {
    final authViewModel = context.read<AuthViewModel>();
    final otherParticipant = widget.chat.participants
        .where((user) => user.id != authViewModel.currentUser?.id)
        .firstOrNull;

    // URL validasyonu için yardımcı metod
    bool _isValidImageUrl(String url) {
      if (url.isEmpty || url == 'null' || url == 'undefined') {
        return false;
      }

      try {
        final uri = Uri.parse(url);
        // file:/// protokolü ile başlayan URL'ler geçersiz
        if (uri.scheme == 'file') {
          return false;
        }
        // HTTP veya HTTPS protokolü olmalı
        return uri.scheme == 'http' || uri.scheme == 'https';
      } catch (e) {
        return false;
      }
    }

    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _isMessagingBlocked ? null : () async {
              final prefs = await SharedPreferences.getInstance();
              final userToken = prefs.getString(AppConstants.userTokenKey);

              if (otherParticipant != null &&
                  authViewModel.currentUser != null &&
                  userToken != null &&
                  userToken.isNotEmpty) {
                try {
                  final userId = int.parse(otherParticipant.id);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileDetailView(
                        userId: userId,
                        userToken: userToken,
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Kullanıcı profili açılamadı'),
                      backgroundColor: AppTheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Kullanıcı bilgisi bulunamadı'),
                    backgroundColor: AppTheme.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _isMessagingBlocked ? Colors.grey[300] : Colors.white,
                  child:
                      otherParticipant?.avatar != null &&
                          _isValidImageUrl(otherParticipant!.avatar!)
                      ? ClipOval(
                          child: Image.network(
                            otherParticipant.avatar!,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Text(
                                otherParticipant.name.isNotEmpty
                                    ? otherParticipant.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: _isMessagingBlocked ? Colors.grey[500] : AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        )
                      : Text(
                          otherParticipant?.name.isNotEmpty == true
                              ? otherParticipant!.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: _isMessagingBlocked ? Colors.grey[500] : AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                // Engelleme göstergesi
                if (_isMessagingBlocked)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red[400],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.block,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                otherParticipant?.name ?? 'Bilinmeyen Kullanıcı',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    if (_isMessagingBlocked) {
      return SafeArea(
        bottom: true,
        minimum: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.block, color: Colors.red[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bu kullanıcı engellendi. Mesaj gönderemezsiniz.',
                  style: TextStyle(color: Colors.red[700], fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      bottom: true,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.inventory_2_outlined, size: 20),
                onPressed: () {
                  _showProductSelection();
                },
                tooltip: 'İlan Gönder',
                color: Colors.grey[700],
                padding: const EdgeInsets.all(8),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ProfanityCheckChatInput(
                controller: _messageController,
                hintText: 'Mesajınızı yazın...',
                maxLines: null,
                sensitivity: 'medium',
                onSendPressed: () {
                  // ProfanityCheckChatInput küfür kontrolü yapıyor
                  // Bu callback sadece küfür kontrolü geçildiğinde çağrılıyor
                  _sendMessage();
                },
                onSubmitted: (_) {
                  // Enter tuşuna basıldığında da küfür kontrolü yap
                  _sendMessage();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isMessagingBlocked;

  const _MessageBubble({
    required this.message, 
    required this.isMe,
    required this.isMessagingBlocked,
  });

  // URL validasyonu için yardımcı metod
  bool _isValidImageUrl(String url) {
    if (url.isEmpty || url == 'null' || url == 'undefined') {
      return false;
    }

    try {
      final uri = Uri.parse(url);
      // file:/// protokolü ile başlayan URL'ler geçersiz
      if (uri.scheme == 'file') {
        return false;
      }
      // HTTP veya HTTPS protokolü olmalı
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (e) {
      return false;
    }
  }

  // Güvenli resim widget'ı
  Widget _buildProductImage(
    String imageUrl,
    double width,
    double height, {
    double borderRadius = 8,
  }) {
    if (!_isValidImageUrl(imageUrl)) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey[400],
          size: 20,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        imageUrl,
        width: width,
        height: width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Colors.grey[400],
              size: 20,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Product mesajları için özel layout
    if (message.type == MessageType.product && message.product != null) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            left: isMe ? 64 : 0,
            right: isMe ? 0 : 64,
            bottom: 8,
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              _buildProductCard(context, message.product!),
              const SizedBox(height: 4),
              Padding(
                padding: EdgeInsets.only(
                  left: isMe ? 0 : 8,
                  right: isMe ? 8 : 0,
                ),
                child: Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      );
    }

 
    // Diğer mesaj tipleri için normal bubble
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 64 : 0,
          right: isMe ? 0 : 64,
          bottom: 8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.type == MessageType.text) ...[
              Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ] else if (message.type == MessageType.image) ...[
              if (message.imageUrl != null &&
                  _isValidImageUrl(message.imageUrl!))
                AppNetworkImage(
                  imageUrl: message.imageUrl!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(8),
                ),
            ] else ...[
              // Sistem mesajları
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: isMessagingBlocked ? null : () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailView(productId: product.id),
          ),
        );
      },
      child: Container(
        width: 260,
        height: 80,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isMessagingBlocked ? Colors.grey[100] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            // Sol taraf - Resim
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
                color: Colors.grey[50],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
                child: _buildProductImage(
                  product.images.isNotEmpty ? product.images.first : '',
                  80,
                  80,
                  borderRadius: 16,
                ),
              ),
            ),
            // Sağ taraf - İçerik
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Üst kısım - Başlık
                    Text(
                      product.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isMessagingBlocked ? Colors.grey[500] : Colors.black87,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Alt kısım - Kategori ve fiyat
                    Row(
                      children: [
                        // Kategori badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isMessagingBlocked 
                                ? Colors.grey[300] 
                                : AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.catname,
                            style: TextStyle(
                              color: isMessagingBlocked ? Colors.grey[600] : AppTheme.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Fiyat
                        if (product.estimatedValue != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isMessagingBlocked 
                                  ? Colors.grey[300] 
                                  : Colors.green.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '₺${product.estimatedValue!.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: isMessagingBlocked ? Colors.grey[600] : Colors.green,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Sağ kenar - Tıklama göstergesi veya engelleme ikonu
            Container(
              width: 32,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isMessagingBlocked)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.block,
                        size: 10,
                        color: Colors.red[600],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
