import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/product.dart';
import '../utils/logger.dart';
import '../viewmodels/product_viewmodel.dart';

class ProductListItem extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final bool isOwnProduct;

  const ProductListItem({
    super.key,
    required this.product,
    this.onTap,
    this.isOwnProduct = false,
  });

  String _buildLocationText(String? city, String? district) {
    final c = (city ?? '').trim();
    final d = (district ?? '').trim();
    if (c.isEmpty && d.isEmpty) return 'Konum belirtilmemiş';
    if (c.isNotEmpty && d.isEmpty) return c;
    if (c.isEmpty && d.isNotEmpty) return d;
    return '$c / $d';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: product.isSponsor == true
                  ? const Color(0xFFFEFEFC)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: product.isSponsor == true
                    ? const Color(0xFFB8860B)
                    : Colors.grey.shade200,
                width: product.isSponsor == true ? 2 : 1,
              ),
              boxShadow: product.isSponsor == true
                  ? [
                      BoxShadow(
                        color: const Color(0xFFDAA520).withOpacity(0.12),
                        spreadRadius: 0,
                        blurRadius: 16,
                        offset: const Offset(0, 3),
                      ),
                      BoxShadow(
                        color: const Color(0xFFB8860B).withOpacity(0.08),
                        spreadRadius: 0,
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: product.images.isNotEmpty
                        ? Image.network(product.images.first, fit: BoxFit.cover)
                        : Container(color: Colors.grey.shade200),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (product.isSponsor == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFDAA520), // goldenrod
                                    Color(0xFFB8860B), // dark goldenrod
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFDAA520,
                                    ).withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                  BoxShadow(
                                    color: const Color(
                                      0xFFB8860B,
                                    ).withOpacity(0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Vitrin',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _buildLocationText(
                                product.cityTitle,
                                product.districtTitle,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          if (isOwnProduct)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Senin İlanın',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Reklam banner'ı buradan kaldırıldı; liste içinde ayrı bir öğe olarak eklenecek
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Favori butonu (sağ üst) - kendi ilanlarında gösterme
        if (!isOwnProduct)
          Positioned(
            top: 6,
            right: 6,
            child: Consumer<ProductViewModel>(
              builder: (context, vm, child) {
                final bool isFavorite = vm.isFavorite(product.id);
                return GestureDetector(
                  onTap: () async {
                    try {
                      final result = await vm.toggleFavorite(product.id);
                      Logger.info(
                        'ProductListItem - toggleFavorite: ${result['message']}',
                      );
                      if (context.mounted && result['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message']),
                            duration: const Duration(seconds: 2),
                            backgroundColor: result['wasFavorite'] == true
                                ? Colors.orange
                                : Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result['message'] ?? 'İşlem başarısız',
                            ),
                            duration: const Duration(seconds: 3),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      Logger.error(
                        'ProductListItem - toggleFavorite error: $e',
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey[700],
                      size: 18,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
