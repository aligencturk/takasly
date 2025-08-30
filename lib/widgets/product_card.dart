// import removed: cached_network_image is now wrapped by AppNetworkImage
import 'package:takasly/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:takasly/core/app_theme.dart';
import 'package:takasly/models/product.dart';
import 'package:provider/provider.dart';
import 'package:takasly/viewmodels/product_viewmodel.dart';
import 'package:takasly/utils/logger.dart';
import '../../views/product/product_detail_view.dart';
import 'package:takasly/viewmodels/auth_viewmodel.dart';

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
    // API'den gelen categoryList alanını kontrol et
    if (product.categoryList != null && product.categoryList!.isNotEmpty) {
      // categoryList'ten en spesifik kategoriyi al (son eleman)
      final mostSpecificCategory = product.categoryList!.last;
      return mostSpecificCategory.name;
    }

    // 3 katmanlı kategori sisteminde öncelik sırası:
    // 1. Ana kategori adı (mainCategoryName)
    if (product.mainCategoryName != null &&
        product.mainCategoryName!.isNotEmpty &&
        product.mainCategoryName != 'null' &&
        product.mainCategoryName != 'Kategori' &&
        product.mainCategoryName != 'Kategori Yok') {
      return product.mainCategoryName!;
    }

    // 2. Üst kategori adı (parentCategoryName)
    if (product.parentCategoryName != null &&
        product.parentCategoryName!.isNotEmpty &&
        product.parentCategoryName != 'null' &&
        product.parentCategoryName != 'Kategori' &&
        product.parentCategoryName != 'Kategori Yok') {
      return product.parentCategoryName!;
    }

    // 3. Alt kategori adı (subCategoryName)
    if (product.subCategoryName != null &&
        product.subCategoryName!.isNotEmpty &&
        product.subCategoryName != 'null' &&
        product.subCategoryName != 'Kategori' &&
        product.subCategoryName != 'Kategori Yok') {
      return product.subCategoryName!;
    }

    // 4. Direkt categoryName alanı (categoryList'ten gelen en spesifik kategori)
    if (product.catname.isNotEmpty &&
        product.catname != 'null' &&
        product.catname != 'Kategori') {
      return product.catname;
    }

    // 5. Category nesnesinin name alanı
    if (product.category.name.isNotEmpty &&
        product.category.name != 'Kategori' &&
        product.category.name != 'Kategori Yok') {
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
      return categoryName;
    }

    // 7. Eğer hiçbir kategori bulunamazsa, en azından "Kategori" yazısını göster
    return 'Kategori';
  }

  @override
  Widget build(BuildContext context) {
    // Null safety kontrolü
    if (widget.product.id.isEmpty) {
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
              ? const Color(
                  0xFFFEFEFC,
                ) // Sponsor ürünler için ultra premium white background
              : Colors.white,
          borderRadius: BorderRadius.circular(screenWidth < 360 ? 6 : 8),
          border: Border.all(
            color: widget.product.isSponsor == true
                ? const Color(
                    0xFFB8860B,
                  ) // Sponsor ürünler için premium dark gold border
                : const Color.fromARGB(255, 209, 209, 209),
            width: widget.product.isSponsor == true
                ? 2
                : 1, // Sponsor ürünler için premium kalın border
          ),
          boxShadow: widget.product.isSponsor == true
              ? [
                  BoxShadow(
                    color: const Color(0xFFB8860B).withOpacity(0.12),
                    spreadRadius: 0,
                    blurRadius: 16,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: const Color(0xFFDAA520).withOpacity(0.08),
                    spreadRadius: 0,
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null, // Sponsor ürünler için premium çift gölge efekti
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
                      if (widget.product.images.isEmpty) {
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

                      return AppNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(screenWidth < 360 ? 6 : 8),
                        ),
                        placeholder: Shimmer.fromColors(
                          baseColor: Colors.grey[200]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: _buildPlaceholderImage(screenWidth),
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
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFDAA520), // Premium goldenrod
                              Color(0xFFB8860B), // Premium dark goldenrod
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFDAA520).withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: const Color(0xFFB8860B).withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
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
                    Consumer2<ProductViewModel, AuthViewModel>(
                      builder: (context, productViewModel, authViewModel, child) {
                        // Kullanıcı giriş yapmamışsa favori gösterme
                        if (authViewModel.currentUser == null) {
                          return const SizedBox.shrink();
                        }

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
                    // Constraint güvenliği kontrolü
                    if (constraints.maxHeight.isInfinite ||
                        constraints.maxHeight <= 0) {
                      return const SizedBox.shrink();
                    }

                    // Grid constraint kontrolü - grid içinde kullanıldığında maxHeight sınırlı olmalı
                    if (constraints.hasBoundedHeight &&
                        constraints.maxHeight > 1000) {
                      return const SizedBox.shrink();
                    }

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
