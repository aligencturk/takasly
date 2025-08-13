import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
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
import 'edit_product_view.dart';
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

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool error = false,
  }) {
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
      child: _ProductDetailBody(
        productId: productId,
        onShowSnackBar: (msg, {error = false}) =>
            _showSnackBar(context, msg, error: error),
      ),
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
      Provider.of<ProductViewModel>(
        context,
        listen: false,
      ).getProductDetail(widget.productId);
    });
  }

  void _onScroll() {
    if (mounted) {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    }
  }

  void _shareProduct(BuildContext context, Product product) {
    // API'den gelen shareLink'i kullan, yoksa varsayılan link oluştur
    final productUrl =
        product.shareLink ?? 'https://takasly.com/product/${product.id}';

    final shareText =
        '''
${product.title}

$productUrl

Takasly uygulamasından paylaşıldı.

''';

    // Sistem paylaşma menüsünü kullan
    Share.share(shareText, subject: 'Takasly - ${product.title}').then((_) {
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
              child: Text('Ürün bulunamadı.', style: TextStyle(fontSize: 16)),
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
              // Favori ikonu - sadece kendi ilanı değilse göster
              if (Provider.of<AuthViewModel>(
                    context,
                    listen: false,
                  ).currentUser?.id !=
                  product.ownerId)
                IconButton(
                  icon: Icon(
                    vm.isFavorite(product.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: vm.isFavorite(product.id)
                        ? AppTheme.error
                        : AppTheme.surface,
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
                      product: product,
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
              _ActionBar(
                product: product,
                onShowSnackBar: widget.onShowSnackBar,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ImageCarousel extends StatelessWidget {
  final Product product;
  final List<String> images;
  final PageController pageController;
  final Function(int) onPageChanged;
  final int currentIndex;

  const _ImageCarousel({
    required this.product,
    required this.images,
    required this.pageController,
    required this.onPageChanged,
    required this.currentIndex,
  });

  void _openFullScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FullScreenImageView(images: images, initialIndex: currentIndex),
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.background,
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 60,
                            color: AppTheme.textSecondary,
                          ),
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

    if (!mounted) return;
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString(AppConstants.userTokenKey);

      if (userToken != null && userToken.isNotEmpty) {
        try {
          // Yeni API'den gelen userID'yi kullan
          final userId = int.parse(widget.product.ownerId);
          Logger.debug(
            '🔍 Product Detail - Loading user profile for ID: $userId',
          );

          final response = await _userService.getUserProfileDetail(
            userToken: userToken,
            userId: userId,
          );

          if (mounted && response.isSuccess && response.data != null) {
            setState(() {
              _averageRating = response.data!.averageRating.toDouble();
              _totalReviews = response.data!.totalReviews;
            });
            Logger.debug(
              '✅ Product Detail - Profile loaded: Rating: $_averageRating, Reviews: $_totalReviews',
            );
          } else {
            Logger.error(
              '❌ Product Detail - Profile load failed: ${response.error}',
            );
          }
        } catch (e) {
          Logger.error('❌ Product Detail - Profile load error: $e');
        }
      }
    } catch (e) {
      Logger.error('❌ Product Detail - SharedPreferences error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Başlık ve Konum (En önemli - üstte)
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
                  Icon(Icons.location_on, size: 16, color: AppTheme.error),
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

        // 2. Kullanıcı Özeti (İletişim için önemli)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: AppTheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kullanıcı Bilgileri',
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

        const SizedBox(height: 8),

        // 3. Açıklama (Ürün detayı için kritik)
        if (widget.product.description != null &&
            widget.product.description.isNotEmpty)
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

        // 4. Takas Tercihi (Takas uygulaması için önemli)
        if (widget.product.tradeFor != null &&
            widget.product.tradeFor!.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Takas Tercihi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(Icons.swap_horiz, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.product.tradeFor!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // 5. Ürün Bilgileri (Teknik detaylar)
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
              // 1. En önemli bilgiler (üst sırada)
              _InfoRow(
                'İlan Sahibi :',
                widget.product.userFullname ??
                    widget.product.owner?.name ??
                    'Belirtilmemiş',
              ),
              if (widget.product.isShowContact == true &&
                  widget.product.userPhone != null &&
                  widget.product.userPhone!.isNotEmpty)
                _InfoRow('İletişim :', widget.product.userPhone!),
              _InfoRow(
                'Durum :',
                widget.product.productCondition ??
                    widget.product.condition ??
                    'Belirtilmemiş',
              ),
              _InfoRow('Kategori :', _getCategoryDisplayName(widget.product)),

              // 2. Orta önemdeki bilgiler
              _InfoRow(
                'İlan Tarihi :',
                "${widget.product.createdAt.day.toString().padLeft(2, '0')}.${widget.product.createdAt.month.toString().padLeft(2, '0')}.${widget.product.createdAt.year}",
              ),
              if (widget.product.proView != null &&
                  widget.product.proView!.isNotEmpty)
                _InfoRow('Görüntülenme :', widget.product.proView!),
              if (widget.product.favoriteCount != null &&
                  widget.product.favoriteCount! > 0)
                _InfoRow(
                  'Favori :',
                  'Bu ilanı ${widget.product.favoriteCount} kişi favoriledi',
                ),

              // 3. Teknik bilgiler (alt sırada)
              if (widget.product.productCode != null &&
                  widget.product.productCode!.isNotEmpty)
                _InfoRow('İlan Kodu :', widget.product.productCode!),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // 6. Konum Detayı (En altta - harita ve detaylar)
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
                  Icon(Icons.location_city, size: 18, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    _getLocationDisplayText(widget.product),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Harita
              if (widget.product.productLat != null &&
                  widget.product.productLong != null &&
                  widget.product.productLat!.isNotEmpty &&
                  widget.product.productLong!.isNotEmpty)
                _buildLocationMap(widget.product),
              const SizedBox(height: 12),
              // Harita açma butonları
              if (widget.product.productLat != null &&
                  widget.product.productLong != null &&
                  widget.product.productLat!.isNotEmpty &&
                  widget.product.productLong!.isNotEmpty)
                _buildMapButtons(widget.product),
            ],
          ),
        ),

        const SizedBox(height: 80), // Bottom padding for action bar
      ],
    );
  }

  String _getCategoryDisplayName(Product product) {
    // Önce categoryList'i kontrol et (yeni API)
    if (product.categoryList != null && product.categoryList!.isNotEmpty) {
      return product.categoryList!.map((cat) => cat.name).join(' > ');
    }

    // Sonra categoryName'i kontrol et (API'den direkt gelen)
    if (product.catname.isNotEmpty) {
      return product.catname;
    }

    // Sonra category objesini kontrol et
    if (product.category != null && product.category.name.isNotEmpty) {
      return product.category.name;
    }

    // Son olarak categoryId'yi kontrol et
    if (product.categoryId.isNotEmpty) {
      return 'Kategori ID: ${product.categoryId}';
    }

    return 'Belirtilmemiş';
  }

  String _getLocationDisplayText(Product product) {
    final cityTitle = product.cityTitle?.trim() ?? '';
    final districtTitle = product.districtTitle?.trim() ?? '';

    // Her iki alan da boşsa
    if (cityTitle.isEmpty && districtTitle.isEmpty) {
      return 'Konum belirtilmemiş';
    }

    // Sadece şehir varsa
    if (cityTitle.isNotEmpty && districtTitle.isEmpty) {
      return cityTitle;
    }

    // Sadece ilçe varsa
    if (cityTitle.isEmpty && districtTitle.isNotEmpty) {
      return districtTitle;
    }

    // Her ikisi de varsa
    return '$cityTitle / $districtTitle';
  }

  Widget _buildLocationMap(Product product) {
    try {
      final lat = double.tryParse(product.productLat ?? '');
      final lng = double.tryParse(product.productLong ?? '');

      if (lat == null || lng == null) {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'Konum bilgisi bulunamadı',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        );
      }

      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(lat, lng),
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                enableMultiFingerGestureRace: false,
                flags: InteractiveFlag.pinchMove,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rivorya.takaslyapp',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(lat, lng),
                    width: 40,
                    height: 40,
                    child: Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Harita yüklenirken hata oluştu',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
        ),
      );
    }
  }

  Widget _buildMapButtons(Product product) {
    return Row(
      children: [
        Expanded(
          child: _buildMapButton(
            title: 'Yol Tarifi Al',
            icon: Icons.directions,
            color: Colors.green,
            onTap: () => _getDirections(product),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMapButton(
            title: 'Konumu Paylaş',
            icon: Icons.share_location,
            color: Colors.orange,
            onTap: () => _shareLocation(product),
          ),
        ),
      ],
    );
  }

  Widget _buildMapButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: color.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

  void _getDirections(Product product) async {
    try {
      final lat = double.tryParse(product.productLat ?? '');
      final lng = double.tryParse(product.productLong ?? '');

      if (lat == null || lng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konum bilgisi bulunamadı'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }

      // Platform'a göre yol tarifi URL'i
      if (Platform.isIOS) {
        // iOS için Apple Maps yol tarifi
        final url = 'https://maps.apple.com/?daddr=$lat,$lng&dirflg=d';
        await launchUrl(Uri.parse(url));
      } else {
        // Android için Google Maps yol tarifi
        final url = 'https://maps.google.com/maps?daddr=$lat,$lng';
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yol tarifi açılırken hata oluştu: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _shareLocation(Product product) {
    try {
      final lat = double.tryParse(product.productLat ?? '');
      final lng = double.tryParse(product.productLong ?? '');

      if (lat == null || lng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konum bilgisi bulunamadı'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }

      final locationText =
          '${product.title}\n'
          '${product.cityTitle} / ${product.districtTitle}\n'
          'Konum: https://maps.google.com/?q=$lat,$lng';

      Share.share(locationText, subject: 'Takasly - ${product.title}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Konum paylaşılırken hata oluştu: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Widget _InfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
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
            child: Row(
              children: [
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
                // İlan Kodu için kopyalama butonu
                if (label.trim() == 'İlan Kodu :')
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.copy, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('İlan kodu kopyalandı'),
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
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.copy,
                          size: 16,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String userName) {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildUserSummary(BuildContext context, Product product) {
    // Yeni API'den gelen kullanıcı bilgilerini kullan
    final userName =
        product.userFullname ?? product.owner?.name ?? 'Bilinmeyen Kullanıcı';
    final owner = product.owner;
    final userPhone = product.userPhone;

    // Debug loglar sadeleştirildi (gereksiz tekrarlar kaldırıldı)
    Logger.debug(
      'Product Detail - isShowContact: ${product.isShowContact}',
      tag: 'ProductDetail',
    );
    Logger.debug(
      'Product Detail - userPhone: $userPhone',
      tag: 'ProductDetail',
    );
    Logger.debug(
      'Product Detail - owner: ${owner?.id} - ${owner?.name}',
      tag: 'ProductDetail',
    );
    Logger.debug(
      'Product Detail - selected avatar src: ${product.profilePhoto ?? product.userImage ?? owner?.avatar}',
      tag: 'ProductDetail',
    );

    if (owner == null && product.userFullname == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person_outline,
                color: Colors.grey,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Bilinmeyen Kullanıcı',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
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
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          Logger.debug(
            'Product Detail - Kullanıcı özetine tıklandı',
            tag: 'ProductDetail',
          );
          Logger.debug(
            'Product Detail - owner: ${owner.id} - ${owner.name}',
            tag: 'ProductDetail',
          );

          // Token'ı SharedPreferences'dan al
          final prefs = await SharedPreferences.getInstance();
          final userToken = prefs.getString(AppConstants.userTokenKey);
          Logger.debug(
            'Product Detail - userToken from SharedPreferences: ${userToken?.substring(0, 20)}...',
            tag: 'ProductDetail',
          );

          if (userToken != null && userToken.isNotEmpty) {
            try {
              // Yeni API'den gelen userID'yi kullan
              final userId = int.parse(product.ownerId);
              Logger.debug(
                'Product Detail - userId parsed: $userId',
                tag: 'ProductDetail',
              );
              Logger.debug(
                'Product Detail - Navigating to UserProfileDetailView...',
                tag: 'ProductDetail',
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileDetailView(
                    userId: userId,
                    userToken: userToken,
                  ),
                ),
              );
              Logger.debug(
                'Product Detail - Navigation completed',
                tag: 'ProductDetail',
              );
            } catch (e) {
              Logger.error(
                'Product Detail - ID parse error: $e',
                tag: 'ProductDetail',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Kullanıcı profili açılamadı'),
                  backgroundColor: AppTheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } else {
            Logger.error(
              'Product Detail - Token not available',
              tag: 'ProductDetail',
            );
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              // Kullanıcı Avatar - Daha küçük
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child:
                      (product.profilePhoto != null &&
                              product.profilePhoto!.isNotEmpty) ||
                          (product.userImage != null &&
                              product.userImage!.isNotEmpty) ||
                          (owner?.avatar != null && owner!.avatar!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl:
                              product.profilePhoto ??
                              product.userImage ??
                              owner?.avatar ??
                              '',
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              _buildAvatarPlaceholder(userName),
                          errorWidget: (context, url, error) =>
                              _buildAvatarPlaceholder(userName),
                        )
                      : _buildAvatarPlaceholder(userName),
                ),
              ),
              const SizedBox(width: 8),
              // Kullanıcı Bilgileri - Kompakt tasarım
              Expanded(
                child: Row(
                  children: [
                    // İsim ve puan yan yana
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.star, size: 12, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                averageRating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '($totalReviews)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Telefon numarası - sadece isShowContact true ise göster
                    if (product.isShowContact == true &&
                        userPhone != null &&
                        userPhone.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone, size: 14, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            userPhone,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: userPhone),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.copy,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 6),
                                        Text('Telefon kopyalandı'),
                                      ],
                                    ),
                                    backgroundColor: AppTheme.primary,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  Icons.copy,
                                  size: 12,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Tıklama göstergesi - Daha küçük
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.primary,
                  size: 12,
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
      onShowSnackBar?.call(
        'Kendi ürününüze mesaj gönderemezsiniz.',
        error: true,
      );
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
            Logger.info(
              'Yeni chat doğrudan getirildi ve chat sayfasına yönlendiriliyor: ${newChat.id}',
            );
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
              polledChat = chatViewModel.chats.firstWhere(
                (chat) => chat.id == chatId,
              );
              Logger.info('Chat ID ile bulundu: ${polledChat.id}');
              break;
            } catch (e) {
              try {
                polledChat = chatViewModel.chats.firstWhere(
                  (chat) => chat.tradeId == product.id,
                );
                Logger.info('Chat tradeId ile bulundu: ${polledChat.id}');
                break;
              } catch (e2) {
                Logger.info(
                  'Chat henüz bulunamadı, tekrar deneniyor... (${chatViewModel.chats.length} chat var)',
                );
              }
            }
          }
          if (polledChat != null) {
            Logger.info(
              'Polling ile chat bulundu ve chat sayfasına yönlendiriliyor: ${polledChat.id}',
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailView(chat: polledChat!),
              ),
            );
          } else {
            Logger.error(
              'Chat oluşturuldu ama $maxRetries deneme sonrası bulunamadı: $chatId',
            );
            onShowSnackBar?.call(
              'Chat oluşturuldu ama bulunamadı. Lütfen tekrar deneyin.',
              error: true,
            );
          }
        } else {
          onShowSnackBar?.call(
            'Chat oluşturulamadı. Lütfen tekrar deneyin.',
            error: true,
          );
        }
      }
    } catch (e) {
      Logger.error('Chat başlatma hatası: $e');
      onShowSnackBar?.call('Hata: $e', error: true);
    }
  }

  Future<void> _callOwner(BuildContext context) async {
    final authViewModel = context.read<AuthViewModel>();

    if (authViewModel.currentUser == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (authViewModel.currentUser!.id == product.ownerId) {
      onShowSnackBar?.call('Kendi ürününüzü arayamazsınız.', error: true);
      return;
    }

    // isShowContact false ise telefon numarasını gösterme
    if (product.isShowContact == false) {
      onShowSnackBar?.call(
        'Bu kullanıcının iletişim bilgileri gizli.',
        error: true,
      );
      return;
    }

    // Telefon numarası varsa arama yap
    if (product.userPhone != null && product.userPhone!.isNotEmpty) {
      // Telefon numarasını arama uygulamasında aç
      try {
        final phoneNumber = product.userPhone!.replaceAll(
          RegExp(r'[^\d+]'),
          '',
        );
        final url = 'tel:$phoneNumber';
        await launchUrl(Uri.parse(url));
      } catch (e) {
        onShowSnackBar?.call('Arama başlatılamadı: $e', error: true);
      }
    } else {
      onShowSnackBar?.call('Telefon numarası bulunamadı.', error: true);
    }
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
        Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.error, size: 20),
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
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProductView(product: product),
                ),
              );
            },
            icon: const Icon(Icons.edit, size: 14),
            label: const Text(
              'İlanımı Düzenle',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
            // Arama butonu - sadece isShowContact true ise göster
            if (product.isShowContact == true)
              Expanded(
                child: SizedBox(
                  height: 45,
                  child: OutlinedButton.icon(
                    onPressed: () async => await _callOwner(context),
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
            // Arama butonu yoksa mesaj butonu tam genişlikte olsun
            if (product.isShowContact == true) const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 45,
                child: ElevatedButton.icon(
                  onPressed: () => _startChat(context),
                  icon: const Icon(Icons.message, size: 16),
                  label: const Text(
                    'Mesaj Gönder',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
