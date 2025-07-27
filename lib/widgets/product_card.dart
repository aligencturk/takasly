import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:takasly/core/app_theme.dart';
import 'package:takasly/models/product.dart';
import '../../views/product/product_detail_view.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final String? heroTag;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.heroTag,
  });

  String _getCategoryDisplayName(Product product) {
    if (product.category == null) return 'Kategori Yok';
    
    // Eğer alt kategori varsa sadece alt kategori adını göster
    if (product.category.parentId != null) {
      return product.category.name;
    }
    
    return product.category.name;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap ?? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailView(productId: product.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resim
            Expanded(
              flex: 5,
              child: Hero(
                tag: heroTag ?? 'product_image_${product.id}_${DateTime.now().millisecondsSinceEpoch}',
                child: Builder(
                  builder: (context) {
                    final imageUrl = product.images.isNotEmpty ? product.images.first : '';
                    
                    // Resim URL'si boş veya geçersizse placeholder göster
                    final uri = Uri.tryParse(imageUrl);
                    if (imageUrl.isEmpty || 
                        imageUrl == 'null' || 
                        imageUrl == 'undefined' ||
                        imageUrl.contains('product_68852b20b6cac.png') ||
                        uri == null ||
                        !uri.hasAbsolutePath) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey[400],
                                size: 32,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Resim yok',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    return ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[200]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.grey[400],
                                    size: 32,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Resim yüklenemedi',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            // Bilgiler
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Kategori
                  
                    // Başlık
                    Text(
                      product.title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                      Container(
                      constraints: const BoxConstraints(
                        minHeight: 16, // iOS için minimum yükseklik
                      ),
                      child: Text(
                        _getCategoryDisplayName(product),
                        style: textTheme.bodySmall?.copyWith(
                          color: AppTheme.primary, // Debug için kırmızı renk
                          fontWeight: FontWeight.w600, // Daha kalın font
                          letterSpacing: 0.5,
                          fontSize: 12, // Daha büyük font boyutu
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Konum
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined, 
                          size: 12, 
                          color: Colors.grey[500],
                        ),
                        Text(
                          product.cityTitle + "/" + product.districtTitle,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
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
}