import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:takasly/core/app_theme.dart';
import 'package:takasly/models/product.dart';
import 'package:provider/provider.dart';
import 'package:takasly/viewmodels/product_viewmodel.dart';
import 'package:takasly/utils/logger.dart';
import '../../views/product/product_detail_view.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final String? heroTag;
  final bool hideFavoriteIcon;
  final bool isProfileView;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.heroTag,
    this.hideFavoriteIcon = false,
    this.isProfileView = false,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  @override
  void dispose() {
    // Widget dispose edildiğinde temizlik yap
    Logger.debug('🧹 ProductCard - Disposing product: ${widget.product.id}');
    super.dispose();
  }

  // Placeholder resim widget'ı
  Widget _buildPlaceholderImage(double screenWidth) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(screenWidth < 360 ? 6 : 8),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              color: Colors.grey[400],
              size: screenWidth < 360 ? 20 : 28,
            ),
            const SizedBox(height: 4),
            Text(
              'Resim yok',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: screenWidth < 360 ? 8 : 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryDisplayName(Product product, BuildContext context) {
    // Debug: Kategori bilgilerini logla
    Logger.debug(
      '🔍 ProductCard._getCategoryDisplayName - Product: ${product.title}',
      tag: 'ProductCard',
    );
    Logger.debug(
      '🔍 ProductCard._getCategoryDisplayName - categoryId: ${product.categoryId}',
      tag: 'ProductCard',
    );
    Logger.debug(
      '🔍 ProductCard._getCategoryDisplayName - catname: ${product.catname}',
      tag: 'ProductCard',
    );
    Logger.debug(
      '🔍 ProductCard._getCategoryDisplayName - category.name: ${product.category.name}',
      tag: 'ProductCard',
    );

    // 3 katmanlı kategori sisteminde öncelik sırası:
    // 1. Ana kategori adı (mainCategoryName)
    if (product.mainCategoryName != null &&
        product.mainCategoryName!.isNotEmpty &&
        product.mainCategoryName != 'null' &&
        product.mainCategoryName != 'Kategori' &&
        product.mainCategoryName != 'Kategori Yok') {
      Logger.debug(
        '🔍 ProductCard._getCategoryDisplayName - Using mainCategoryName: ${product.mainCategoryName}',
        tag: 'ProductCard',
      );
      return product.mainCategoryName!;
    }

    // 2. Üst kategori adı (parentCategoryName)
    if (product.parentCategoryName != null &&
        product.parentCategoryName!.isNotEmpty &&
        product.parentCategoryName != 'null' &&
        product.parentCategoryName != 'Kategori' &&
        product.parentCategoryName != 'Kategori Yok') {
      Logger.debug(
        '🔍 ProductCard._getCategoryDisplayName - Using parentCategoryName: ${product.parentCategoryName}',
        tag: 'ProductCard',
      );
      return product.parentCategoryName!;
    }

    // 3. Alt kategori adı (subCategoryName)
    if (product.subCategoryName != null &&
        product.subCategoryName!.isNotEmpty &&
        product.subCategoryName != 'null' &&
        product.subCategoryName != 'Kategori' &&
        product.subCategoryName != 'Kategori Yok') {
      Logger.debug(
        '🔍 ProductCard._getCategoryDisplayName - Using subCategoryName: ${product.subCategoryName}',
        tag: 'ProductCard',
      );
      return product.subCategoryName!;
    }

    // 4. Direkt categoryName alanı (categoryList'ten gelen en spesifik kategori)
    if (product.catname.isNotEmpty &&
        product.catname != 'null' &&
        product.catname != 'Kategori') {
      Logger.debug(
        '🔍 ProductCard._getCategoryDisplayName - Using catname: ${product.catname}',
        tag: 'ProductCard',
      );
      return product.catname;
    }

    // 5. Category nesnesinin name alanı
    if (product.category.name.isNotEmpty &&
        product.category.name != 'Kategori' &&
        product.category.name != 'Kategori Yok') {
      Logger.debug(
        '🔍 ProductCard._getCategoryDisplayName - Using category.name: ${product.category.name}',
        tag: 'ProductCard',
      );
      return product.category.name;
    }

    // 6. ProductViewModel'den kategori arama (sadece ana kategoriler için)
    final productViewModel = Provider.of<ProductViewModel>(
      context,
      listen: false,
    );
    final categoryName = productViewModel.getCategoryNameById(
      product.categoryId,
    );
    if (categoryName != 'Kategori Yok') {
      Logger.debug(
        '🔍 ProductCard._getCategoryDisplayName - Using ProductViewModel category: $categoryName',
        tag: 'ProductCard',
      );
      return categoryName;
    }

    // 7. Eğer hiçbir kategori bulunamazsa, en azından "Kategori" yazısını göster
    Logger.debug(
      '🔍 ProductCard._getCategoryDisplayName - No valid category found, using default: Kategori',
      tag: 'ProductCard',
    );
    return 'Kategori';
  }

  @override
  Widget build(BuildContext context) {
    // Null safety kontrolü
    if (widget.product == null) {
      Logger.warning('⚠️ ProductCard - Null product detected');
      return const SizedBox.shrink();
    }

    // Product ID kontrolü
    if (widget.product.id == null || widget.product.id.isEmpty) {
      Logger.warning(
        '⚠️ ProductCard - Invalid product ID: ${widget.product.id}',
      );
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    // Responsive boyutlar hesaplandı

    // Responsive font boyutları
    final categoryFontSize = screenWidth < 360 ? 9.0 : 11.0;
    final titleFontSize = screenWidth < 360 ? 10.0 : 12.0;
    final locationFontSize = screenWidth < 360 ? 8.0 : 10.0;

    return GestureDetector(
      onTap:
          widget.onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProductDetailView(productId: widget.product.id),
              ),
            );
          },
      child: Container(
        decoration: BoxDecoration(
          color: widget.product.isSponsor == true
              ? Colors
                    .amber
                    .shade50 // Sponsor ürünler için altın rengi background
              : Colors.white,
          borderRadius: BorderRadius.circular(screenWidth < 360 ? 6 : 8),
          border: Border.all(
            color: widget.product.isSponsor == true
                ? Colors
                      .amber
                      .shade300 // Sponsor ürünler için altın rengi border
                : const Color.fromARGB(255, 209, 209, 209),
            width: widget.product.isSponsor == true
                ? 2
                : 1, // Sponsor ürünler için kalın border
          ),
          boxShadow: widget.product.isSponsor == true
              ? [
                  BoxShadow(
                    color: Colors.amber.shade200.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null, // Sponsor ürünler için gölge efekti
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resim - Responsive yükseklik
            AspectRatio(
              aspectRatio: 1.0, // Kare resim
              child: Stack(
                children: [
                  Builder(
                    builder: (context) {
                      // Images listesi null safety kontrolü
                      if (widget.product.images == null ||
                          widget.product.images.isEmpty) {
                        return _buildPlaceholderImage(screenWidth);
                      }

                      final imageUrl = widget.product.images.first;

                      // Resim URL'si boş veya geçersizse placeholder göster
                      final uri = Uri.tryParse(imageUrl);
                      if (imageUrl.isEmpty ||
                          imageUrl == 'null' ||
                          imageUrl == 'undefined' ||
                          imageUrl.contains('product_68852b20b6cac.png') ||
                          uri == null ||
                          !uri.hasAbsolutePath) {
                        return _buildPlaceholderImage(screenWidth);
                      }

                      return ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(screenWidth < 360 ? 6 : 8),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[200]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) {
                            Logger.warning(
                              '⚠️ ProductCard - Image load error for product ${widget.product.id}: $error',
                            );
                            return _buildPlaceholderImage(screenWidth);
                          },
                        ),
                      );
                    },
                  ),
                  // Sponsor badge'i - sadece sponsor ürünlerde göster
                  if (widget.product.isSponsor == true)
                    Positioned(
                      top: screenWidth < 360 ? 4 : 6,
                      left: screenWidth < 360 ? 4 : 6,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth < 360 ? 4 : 6,
                          vertical: screenWidth < 360 ? 2 : 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade600,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          'Vitrin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth < 360 ? 7 : 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Favori kalp ikonu - sadece hideFavoriteIcon false ise göster
                  if (!widget.hideFavoriteIcon)
                    Consumer<ProductViewModel>(
                      builder: (context, productViewModel, child) {
                        final isFavorite = productViewModel.isFavorite(
                          widget.product.id,
                        );
                        return Positioned(
                          top: screenWidth < 360 ? 4 : 6,
                          right: screenWidth < 360 ? 4 : 6,
                          child: GestureDetector(
                            onTap: () async {
                              final result = await productViewModel
                                  .toggleFavorite(widget.product.id);
                              if (result['success'] == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message']),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: result['wasFavorite']
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                );
                              } else {
                                // 417 hatası veya diğer hatalar için API'den gelen mesajı göster
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message']),
                                    duration: const Duration(seconds: 3),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(
                                  screenWidth < 360 ? 8 : 12,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(
                                screenWidth < 360 ? 3 : 4,
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  key: ValueKey(
                                    'favorite_${widget.product.id}',
                                  ),
                                  color: isFavorite
                                      ? Colors.red
                                      : Colors.grey[600],
                                  size: screenWidth < 360 ? 14 : 18,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            // Bilgiler - Responsive ve taşma güvenli
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: screenWidth < 360 ? 6 : 10,
                  top: screenWidth < 360 ? 6 : 12,
                  bottom: screenWidth < 360 ? 4 : 6,
                  right: screenWidth < 360 ? 6 : 10,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double availableHeight = constraints.maxHeight;
                    final double categoryLineHeight = categoryFontSize * 1.0;
                    final double titleLineHeight = titleFontSize * 1.2;
                    final double locationLineHeight = locationFontSize * 1.2;
                    final double spacingSmall = screenWidth < 360 ? 3 : 4;
                    final double spacingAfterCategory = screenWidth < 360
                        ? 3
                        : 5;

                    // Altta konum satırı için ayrılacak alan
                    final double reservedForBottom =
                        locationLineHeight + spacingSmall;

                    // Başlık için kalan alanı hesapla
                    double remainingForTitle =
                        availableHeight -
                        categoryLineHeight -
                        spacingAfterCategory -
                        reservedForBottom;
                    if (remainingForTitle < titleLineHeight) {
                      remainingForTitle = titleLineHeight; // En az 1 satır
                    }

                    int allowedTitleLines =
                        (remainingForTitle / titleLineHeight).floor().clamp(
                          1,
                          screenWidth < 360 ? 2 : 3,
                        );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kategori
                        Text(
                          _getCategoryDisplayName(widget.product, context),
                          style: textTheme.bodySmall?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                            fontSize: categoryFontSize,
                            height: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                        SizedBox(height: spacingAfterCategory),

                        // Başlık - dinamik satır sayısı ile
                        Expanded(
                          child: Text(
                            widget.product.title,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: titleFontSize,
                              height: 1.2,
                            ),
                            maxLines: allowedTitleLines,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                          ),
                        ),
                        SizedBox(height: spacingSmall),

                        // Konum
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: screenWidth < 360 ? 8 : 10,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  final cityTitle =
                                      widget.product.cityTitle.isNotEmpty
                                      ? widget.product.cityTitle
                                      : 'Şehir belirtilmemiş';
                                  final districtTitle =
                                      widget.product.districtTitle.isNotEmpty
                                      ? widget.product.districtTitle
                                      : 'İlçe belirtilmemiş';
                                  final locationText =
                                      '$cityTitle/$districtTitle';
                                  return Text(
                                    locationText,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[500],
                                      fontSize: locationFontSize,
                                      height: 1.0,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
