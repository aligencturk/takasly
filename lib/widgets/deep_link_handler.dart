import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/deep_link_viewmodel.dart';
import '../utils/logger.dart';

/// Deep Link Handler Widget
/// Deep link geldiğinde ürün detay sayfasına yönlendirme yapar
class DeepLinkHandler extends StatefulWidget {
  final Widget child;
  
  const DeepLinkHandler({
    super.key,
    required this.child,
  });

  @override
  State<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<DeepLinkHandler> {
  @override
  void initState() {
    super.initState();
    
    // Widget build edildikten sonra deep link ViewModel'i başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDeepLink();
    });
  }
  
  /// Deep link ViewModel'i başlat
  Future<void> _initializeDeepLink() async {
    try {
      final deepLinkViewModel = context.read<DeepLinkViewModel>();
      await deepLinkViewModel.initialize();
      
      Logger.info('Deep Link Handler başlatıldı');
    } catch (e) {
      Logger.error('Deep Link Handler başlatılırken hata: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<DeepLinkViewModel>(
      builder: (context, deepLinkViewModel, child) {
        // Deep link işleniyorsa loading göster
        if (deepLinkViewModel.isProcessing) {
          return _buildLoadingOverlay();
        }
        
        // Deep link hatası varsa hata mesajı göster
        if (deepLinkViewModel.hasError) {
          return _buildErrorOverlay(deepLinkViewModel);
        }
        
        // Deep link ile product ID geldiyse ürün detay sayfasına yönlendir
        if (deepLinkViewModel.pendingProductId != null) {
          _handleProductDeepLink(deepLinkViewModel.pendingProductId!);
        }
        
        // Normal child widget'ı göster
        return widget.child;
      },
    );
  }
  
  /// Loading overlay'i göster
  Widget _buildLoadingOverlay() {
    return Stack(
      children: [
        widget.child,
        Container(
          color: Colors.black54,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  'Deep link işleniyor...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  /// Hata overlay'i göster
  Widget _buildErrorOverlay(DeepLinkViewModel deepLinkViewModel) {
    return Stack(
      children: [
        widget.child,
        Container(
          color: Colors.black54,
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Deep Link Hatası',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    deepLinkViewModel.errorMessage ?? 'Bilinmeyen hata',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          deepLinkViewModel.clearError();
                        },
                        child: const Text('Tamam'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          deepLinkViewModel.clearError();
                          _initializeDeepLink();
                        },
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  /// Ürün deep link'ini işle
  void _handleProductDeepLink(String productId) {
    try {
      Logger.info('Ürün deep link\'i işleniyor. Product ID: $productId');
      
      // Deep link ViewModel'den pending product ID'yi temizle
      final deepLinkViewModel = context.read<DeepLinkViewModel>();
      deepLinkViewModel.clearPendingProductId();
      
      // Ürün detay sayfasına yönlendir
      Navigator.of(context).pushNamed(
        '/product-detail',
        arguments: {'productId': productId},
      );
      
      Logger.info('Ürün detay sayfasına yönlendirildi. Product ID: $productId');
    } catch (e) {
      Logger.error('Ürün deep link\'i işlenirken hata: $e');
    }
  }
}
