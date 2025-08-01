import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../../viewmodels/product_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/trade_viewmodel.dart';
import '../../models/chat.dart';
import '../../models/product.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../chat/chat_detail_view.dart';
import '../profile/user_profile_detail_view.dart';
import '../../viewmodels/user_profile_detail_viewmodel.dart';
import '../../services/user_service.dart';
import '../../utils/logger.dart';

// Tam ekran görsel görüntüleme sayfası
class FullScreenImageView extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageView({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageView> createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<FullScreenImageView> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${_currentIndex + 1}/${widget.images.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 3.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.images[index],
                fit: BoxFit.contain,
                placeholder: (context, url) => Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.black,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

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
              // Favori ikonu
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

  void _openFullScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageView(
          images: images,
          initialIndex: currentIndex,
        ),
      ),
    );
  }

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
              return GestureDetector(
                onTap: () => _openFullScreen(context),
                child: Stack(
                  children: [
                    CachedNetworkImage(
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
                    ),
                    // Tam ekran göstergesi
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
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

class _ProductInfo extends StatefulWidget {
  final Product product;

  const _ProductInfo({required this.product});

  @override
  State<_ProductInfo> createState() => _ProductInfoState();
}

class _ProductInfoState extends State<_ProductInfo> {
  double? _averageRating;
  int? _totalReviews;
  bool _isLoadingProfile = false;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (_isLoadingProfile) return;
    
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString(AppConstants.userTokenKey);
      
      if (userToken != null && userToken.isNotEmpty) {
        try {
          final userId = int.parse(widget.product.ownerId);
          print('🔍 Product Detail - Loading user profile for ID: $userId');
          
          final response = await _userService.getUserProfileDetail(
            userToken: userToken,
            userId: userId,
          );
          
          if (response.isSuccess && response.data != null) {
            setState(() {
              _averageRating = response.data!.averageRating.toDouble();
              _totalReviews = response.data!.totalReviews;
            });
            print('✅ Product Detail - Profile loaded: Rating: $_averageRating, Reviews: $_totalReviews');
          } else {
            print('❌ Product Detail - Profile load failed: ${response.error}');
          }
        } catch (e) {
          print('❌ Product Detail - Profile load error: $e');
        }
      }
    } catch (e) {
      print('❌ Product Detail - SharedPreferences error: $e');
    } finally {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

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
                widget.product.title,
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
                    '${widget.product.cityTitle} / ${widget.product.districtTitle}',
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
              _InfoRow('Kategori :', _getCategoryDisplayName(widget.product)),
              _InfoRow('Durum :', widget.product.condition ?? 'Belirtilmemiş'),
              _InfoRow('İlan Tarihi :', 
                "${widget.product.createdAt.day.toString().padLeft(2, '0')}.${widget.product.createdAt.month.toString().padLeft(2, '0')}.${widget.product.createdAt.year}"),
              _InfoRow('İlan No :', widget.product.id),
              _InfoRow('Satıcı :', widget.product.owner?.name ?? 'Belirtilmemiş'),
              
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Açıklama
        if (widget.product.description != null && widget.product.description.isNotEmpty)
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
                widget.product.description,
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
                    '${widget.product.cityTitle} / ${widget.product.districtTitle}',
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
        
        const SizedBox(height: 8),
        
        // Kullanıcı Özeti
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: AppTheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Satıcı Bilgileri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildUserSummary(context, widget.product),
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

  Widget _buildUserSummary(BuildContext context, Product product) {
    final owner = product.owner;
    if (owner == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.person_outline,
                color: Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bilinmeyen Kullanıcı',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Kullanıcı bilgileri bulunamadı',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Gerçek verileri kullan
    final averageRating = _averageRating ?? 0.0;
    final totalReviews = _totalReviews ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          print('🔍 Product Detail - Kullanıcı özetine tıklandı');
          print('🔍 Product Detail - owner: ${owner.id} - ${owner.name}');
          
          // Token'ı SharedPreferences'dan al
          final prefs = await SharedPreferences.getInstance();
          final userToken = prefs.getString(AppConstants.userTokenKey);
          print('🔍 Product Detail - userToken from SharedPreferences: ${userToken?.substring(0, 20)}...');
          
          if (userToken != null && userToken.isNotEmpty) {
            try {
              final userId = int.parse(owner.id);
              print('🔍 Product Detail - userId parsed: $userId');
              print('🔍 Product Detail - Navigating to UserProfileDetailView...');
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileDetailView(
                    userId: userId,
                    userToken: userToken,
                  ),
                ),
              );
              print('🔍 Product Detail - Navigation completed');
            } catch (e) {
              print('❌ Product Detail - ID parse error: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Kullanıcı profili açılamadı'),
                  backgroundColor: AppTheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } else {
            print('❌ Product Detail - Token not available');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Kullanıcı profili açılamadı'),
                backgroundColor: AppTheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              // Kullanıcı Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: owner.avatar != null && owner.avatar!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: CachedNetworkImage(
                          imageUrl: owner.avatar!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[100],
                            child: const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 24,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[100],
                            child: Text(
                              owner.name.isNotEmpty
                                  ? owner.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Text(
                        owner.name.isNotEmpty
                            ? owner.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Kullanıcı Bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Puan
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              averageRating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // Yorum sayısı
                        Row(
                          children: [
                            Icon(
                              Icons.rate_review,
                              size: 16,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$totalReviews yorum',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Tıklama göstergesi
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
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
      ],
    );
  }


} 