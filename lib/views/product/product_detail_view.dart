import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../core/constants.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../models/product.dart';

class ProductDetailView extends StatefulWidget {
  final String productId;
  
  const ProductDetailView({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProduct();
    });
  }

  void _loadProduct() {
    final productViewModel = Provider.of<ProductViewModel>(context, listen: false);
    productViewModel.loadProductById(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () => _toggleFavorite(),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareProduct(),
          ),
        ],
      ),
      body: Consumer<ProductViewModel>(
        builder: (context, productViewModel, child) {
          if (productViewModel.isLoading) {
            return const LoadingWidget();
          }

          if (productViewModel.hasError) {
            return CustomErrorWidget(
              message: productViewModel.errorMessage!,
              onRetry: _loadProduct,
            );
          }

          final product = productViewModel.selectedProduct;
          if (product == null) {
            return const Center(
              child: Text('Ürün bulunamadı'),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductImages(product),
                _buildProductInfo(product),
                _buildProductDescription(product),
                _buildOwnerInfo(product),
                _buildActionButtons(product),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductImages(Product product) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppConstants.defaultBorderRadius),
          bottomRight: Radius.circular(AppConstants.defaultBorderRadius),
        ),
      ),
      child: product.images.isNotEmpty
          ? PageView.builder(
              itemCount: product.images.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppConstants.defaultBorderRadius),
                    bottomRight: Radius.circular(AppConstants.defaultBorderRadius),
                  ),
                  child: Image.network(
                    product.images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                );
              },
            )
          : const Center(
              child: Icon(
                Icons.image_not_supported,
                size: 64,
                color: Colors.grey,
              ),
            ),
    );
  }

  Widget _buildProductInfo(Product product) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (product.category != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                product.category.name,
                style: const TextStyle(
                  color: Color(0xFF2196F3),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
                             Text(
                 product.location?.city ?? 'Konum belirtilmemiş',
                 style: const TextStyle(
                   color: Colors.grey,
                   fontSize: 14,
                 ),
               ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                _formatDate(product.createdAt),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductDescription(Product product) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Açıklama',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.description.isNotEmpty
                ? product.description
                : 'Açıklama eklenmemiş',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerInfo(Product product) {
    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF2196F3),
            child: Text(
              product.ownerId.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ürün Sahibi',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                                 Text(
                   product.owner.name, // Normalde user name olacak
                   style: const TextStyle(
                     fontSize: 16,
                     fontWeight: FontWeight.w500,
                   ),
                 ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () => _contactOwner(product),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Product product) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _startTrade(product),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Takas Teklifi Ver'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addToWishlist(product),
                  icon: const Icon(Icons.bookmark_border),
                  label: const Text('İstek Listesi'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _reportProduct(product),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Şikayet'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  void _toggleFavorite() {
    // Favori ekleme/çıkarma işlemi
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Favori özelliği yakında aktif olacak'),
      ),
    );
  }

  void _shareProduct() {
    // Ürün paylaşma işlemi
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paylaş özelliği yakında aktif olacak'),
      ),
    );
  }

  void _contactOwner(Product product) {
    // Ürün sahibiyle iletişim
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mesajlaşma özelliği yakında aktif olacak'),
      ),
    );
  }

  void _startTrade(Product product) {
    // Takas teklifi verme
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Takas Teklifi'),
        content: const Text('Takas teklifi özelliği yakında aktif olacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _addToWishlist(Product product) {
    // İstek listesine ekleme
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('İstek listesi özelliği yakında aktif olacak'),
      ),
    );
  }

  void _reportProduct(Product product) {
    // Ürün şikayeti
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürün Şikayet'),
        content: const Text('Şikayet özelliği yakında aktif olacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
} 