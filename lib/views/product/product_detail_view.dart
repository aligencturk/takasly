import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../viewmodels/product_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/trade_viewmodel.dart';
import '../../models/chat.dart';
import '../../models/product.dart';
import '../../core/app_theme.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../chat/chat_detail_view.dart';
import '../trade/start_trade_view.dart';
import '../../utils/logger.dart';

class ProductDetailView extends StatelessWidget {
  final String productId;
  const ProductDetailView({super.key, required this.productId});

  void _showSnackBar(BuildContext context, String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppTheme.error : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: Provider.of<ProductViewModel>(context, listen: false),
      child: _ProductDetailBody(productId: productId, onShowSnackBar: (msg, {error = false}) => _showSnackBar(context, msg, error: error)),
    );
  }
}

class _ProductDetailBody extends StatefulWidget {
  final String productId;
  final void Function(String message, {bool error})? onShowSnackBar;
  const _ProductDetailBody({required this.productId, this.onShowSnackBar});

  @override
  State<_ProductDetailBody> createState() => _ProductDetailBodyState();
}

class _ProductDetailBodyState extends State<_ProductDetailBody> {
  PageController _pageController = PageController();
  int _currentImageIndex = 0;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductViewModel>(context, listen: false)
          .getProductDetail(widget.productId);
    });
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  void _shareProduct(BuildContext context, Product product) {
    // Ürün detay sayfası için link oluştur
    final productUrl = 'https://takasly.com/product/${product.id}';
    
    final shareText = '''
${product.title}

${product.description ?? 'Açıklama bulunmuyor'}

📍 ${product.cityTitle} / ${product.districtTitle}
🏷️ ${product.category?.name ?? 'Kategori belirtilmemiş'}
📅 ${product.createdAt.day.toString().padLeft(2, '0')}.${product.createdAt.month.toString().padLeft(2, '0')}.${product.createdAt.year}

🔗 Ürün linki: $productUrl

Takasly uygulamasından paylaşıldı.
''';

    // Sistem paylaşma menüsünü kullan
    Share.share(
      shareText,
      subject: 'Takasly - ${product.title}',
    ).then((_) {
      // Paylaşma işlemi sonrasında kullanıcıya bildirim göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.share, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('İlan paylaşıldı'),
              ],
            ),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        if (vm.isLoading) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: LoadingWidget(),
          );
        }
        
        if (vm.hasError) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: CustomErrorWidget(
              message: vm.errorMessage ?? 'Ürün detayı yüklenemedi.',
              onRetry: () => vm.getProductDetail(widget.productId),
            ),
          );
        }

        final product = vm.selectedProduct;
        if (product == null) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: Text(
                'Ürün bulunamadı.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: _scrollOffset > 50 
                ? AppTheme.primary.withOpacity(0.95)
                : AppTheme.primary,
            elevation: _scrollOffset > 50 ? 2 : 0,
            iconTheme: const IconThemeData(color: AppTheme.surface),
            title: AnimatedOpacity(
              opacity: _scrollOffset > 50 ? 1.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: const Text(
                'İlan Detayı',
                style: TextStyle(
                  color: AppTheme.surface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  vm.isFavorite(product.id) ? Icons.favorite : Icons.favorite_border,
                  color: vm.isFavorite(product.id) ? AppTheme.error : AppTheme.surface,
                ),
                onPressed: () => vm.toggleFavorite(product.id),
              ),
              IconButton(
                icon: Icon(Icons.share, color: AppTheme.surface),
                onPressed: () => _shareProduct(context, product),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  children: [
                    _ImageCarousel(
                      images: product.images,
                      pageController: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      currentIndex: _currentImageIndex,
                    ),
                    _ProductInfo(product: product),
                  ],
                ),
              ),
              _ActionBar(product: product, onShowSnackBar: widget.onShowSnackBar),
            ],
          ),
        );
      },
    );
  }
}

class _ImageCarousel extends StatelessWidget {
  final List<String> images;
  final PageController pageController;
  final Function(int) onPageChanged;
  final int currentIndex;

  const _ImageCarousel({
    required this.images,
    required this.pageController,
    required this.onPageChanged,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        height: 250,
        color: AppTheme.surface,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                size: 60,
                color: AppTheme.textSecondary,
              ),
              SizedBox(height: 12),
              Text(
                'Fotoğraf Yok',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 250,
      color: AppTheme.surface,
      child: Stack(
        children: [
          PageView.builder(
            controller: pageController,
            onPageChanged: onPageChanged,
            itemCount: images.length,
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: images[index],
                fit: BoxFit.contain,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  color: AppTheme.background,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.background,
                  child: Center(
                    child: Icon(Icons.broken_image, size: 60, color: AppTheme.textSecondary),
                  ),
                ),
              );
            },
          ),
          if (images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: images.asMap().entries.map((entry) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentIndex == entry.key 
                          ? AppTheme.primary 
                          : AppTheme.textSecondary,
                    ),
                  );
                }).toList(),
              ),
            ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${currentIndex + 1}/${images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductInfo extends StatelessWidget {
  final Product product;

  const _ProductInfo({required this.product});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Başlık ve Konum
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: AppTheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.location_on, 
                    size: 16, 
                    color: AppTheme.error
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${product.cityTitle} / ${product.districtTitle}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Ürün Bilgileri
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: AppTheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'İlan Bilgileri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _InfoRow('Kategori :', _getCategoryDisplayName(product)),
              _InfoRow('Durum :', product.condition ?? 'Belirtilmemiş'),
              _InfoRow('İlan Tarihi :', 
                "${product.createdAt.day.toString().padLeft(2, '0')}.${product.createdAt.month.toString().padLeft(2, '0')}.${product.createdAt.year}"),
              _InfoRow('İlan No :', product.id),
              _InfoRow('Satıcı :', product.owner?.name ?? 'Belirtilmemiş'),
              
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Açıklama
        if (product.description != null && product.description.isNotEmpty)
                  Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: AppTheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Açıklama',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                product.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
              ],
            ),
          ),
        
        const SizedBox(height: 8),
        
        // Konum Detayı
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: AppTheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Konum Bilgileri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.location_city, 
                    size: 18, 
                    color: AppTheme.primary
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${product.cityTitle} / ${product.districtTitle}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 80), // Bottom padding for action bar
      ],
    );
  }

  String _getCategoryDisplayName(Product product) {
    if (product.category == null) return 'Belirtilmemiş';
    
    if (product.category.parentId != null) {
      return product.category.name;
    }
    
    return product.category.name;
  }

  Widget _InfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final Product product;
  final void Function(String message, {bool error})? onShowSnackBar;

  const _ActionBar({required this.product, this.onShowSnackBar});

  Future<void> _startChat(BuildContext context) async {
    final authViewModel = context.read<AuthViewModel>();
    final chatViewModel = context.read<ChatViewModel>();
    
    if (authViewModel.currentUser == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (authViewModel.currentUser!.id == product.ownerId) {
      onShowSnackBar?.call('Kendi ürününüze mesaj gönderemezsiniz.', error: true);
      return;
    }

    try {
      
      Chat? existingChat;
      try {
        existingChat = chatViewModel.chats.firstWhere(
          (chat) => chat.tradeId == product.id,
        );
        Logger.info('Mevcut chat bulundu:  [1m${existingChat.id} [0m');
      } catch (e) {
        Logger.info('Mevcut chat bulunamadı, yeni chat oluşturulacak');
      }

      if (existingChat != null) {
        // Chat zaten varsa direkt chat sayfasına git
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailView(chat: existingChat!),
          ),
        );
      } else {
        // Yeni chat oluştur
        Logger.info('Yeni chat oluşturuluyor... Product ID: ${product.id}');
        final chatId = await chatViewModel.createChat(
          tradeId: product.id, // Product ID'sini tradeId olarak kullan
          participantIds: [authViewModel.currentUser!.id, product.ownerId],
        );

        if (chatId != null) {
          // Yeni chat'i doğrudan getir ve yönlendir
          final newChat = await chatViewModel.getChatById(chatId);
          if (newChat != null) {
            Logger.info('Yeni chat doğrudan getirildi ve chat sayfasına yönlendiriliyor: ${newChat.id}');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailView(chat: newChat),
              ),
            );
            return;
          }
          // Yedek: Polling ile bulmaya çalış (çok nadir gerekebilir)
          chatViewModel.loadChats(authViewModel.currentUser!.id);
          Chat? polledChat;
          int retryCount = 0;
          const maxRetries = 10;
          while (polledChat == null && retryCount < maxRetries) {
            await Future.delayed(const Duration(milliseconds: 500));
            retryCount++;
            Logger.info('Chat arama denemesi $retryCount/$maxRetries...');
            try {
              polledChat = chatViewModel.chats.firstWhere((chat) => chat.id == chatId);
              Logger.info('Chat ID ile bulundu: ${polledChat.id}');
              break;
            } catch (e) {
              try {
                polledChat = chatViewModel.chats.firstWhere((chat) => chat.tradeId == product.id);
                Logger.info('Chat tradeId ile bulundu: ${polledChat.id}');
                break;
              } catch (e2) {
                Logger.info('Chat henüz bulunamadı, tekrar deneniyor... (${chatViewModel.chats.length} chat var)');
              }
            }
          }
          if (polledChat != null) {
            Logger.info('Polling ile chat bulundu ve chat sayfasına yönlendiriliyor: ${polledChat.id}');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailView(chat: polledChat!),
              ),
            );
          } else {
            Logger.error('Chat oluşturuldu ama $maxRetries deneme sonrası bulunamadı: $chatId');
            onShowSnackBar?.call('Chat oluşturuldu ama bulunamadı. Lütfen tekrar deneyin.', error: true);
          }
        } else {
          onShowSnackBar?.call('Chat oluşturulamadı. Lütfen tekrar deneyin.', error: true);
        }
      }
    } catch (e) {
      Logger.error('Chat başlatma hatası: $e');
      onShowSnackBar?.call('Hata: $e', error: true);
    }
  }

  void _callOwner(BuildContext context) {
    final authViewModel = context.read<AuthViewModel>();
    
    if (authViewModel.currentUser == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (authViewModel.currentUser!.id == product.ownerId) {
      onShowSnackBar?.call('Kendi ürününüzü arayamazsınız.', error: true);
      return;
    }

    onShowSnackBar?.call('Arama özelliği yakında eklenecek.', error: false);
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.read<AuthViewModel>();
    final isOwnProduct = authViewModel.currentUser?.id == product.ownerId;

          return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          boxShadow: AppTheme.cardShadow,
        ),
      child: isOwnProduct
          ? _buildOwnProductActions(context)
          : _buildOtherProductActions(context),
    );
  }

  Widget _buildOwnProductActions(BuildContext context) {
    return Column(
      children: [
                  Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.1),
              borderRadius: AppTheme.borderRadius,
              border: Border.all(color: AppTheme.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline, 
                  color: AppTheme.error, 
                  size: 20
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bu sizin ilanınız. Düzenlemek için profil sayfanıza gidin.',
                    style: TextStyle(
                      color: AppTheme.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            icon: const Icon(Icons.edit, size: 14),
            label: const Text(
              'İlanımı Düzenle',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: BorderSide(color: AppTheme.primary, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.borderRadius,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtherProductActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 45,
                child: OutlinedButton.icon(
                  onPressed: () => _callOwner(context),
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text(
                    'Ara',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: BorderSide(color: AppTheme.primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.borderRadius,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 45,
                child: ElevatedButton.icon(
                  onPressed: () => _startChat(context),
                  icon: const Icon(Icons.message, size: 16),
                  label: const Text(
                    'Mesaj Gönder',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.borderRadius,
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton.icon(
            onPressed: () => _startTrade(context),
            icon: const Icon(Icons.swap_horiz, size: 16),
            label: const Text(
              'Takas Başlat',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.borderRadius,
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  void _startTrade(BuildContext context) {
    final productViewModel = Provider.of<ProductViewModel>(context, listen: false);
    final product = productViewModel.selectedProduct;
    
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ürün bilgileri yüklenemedi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StartTradeView(receiverProduct: product),
      ),
    );
  }
} 