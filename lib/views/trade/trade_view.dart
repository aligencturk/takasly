import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../viewmodels/trade_viewmodel.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../services/auth_service.dart';
import '../../models/trade.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/product_card.dart';
import '../../core/app_theme.dart';

class TradeView extends StatefulWidget {
  const TradeView({super.key});

  @override
  State<TradeView> createState() => _TradeViewState();
}

class _TradeViewState extends State<TradeView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    print('🔄 TradeView initState called');
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔄 TradeView postFrameCallback - calling _loadData');
      _loadData();
    });
  }

  Future<void> _loadData() async {
    print('🔄 TradeView _loadData started');

    // Önce kullanıcının login olup olmadığını kontrol et
    final isLoggedIn = await _authService.isLoggedIn();
    print('🔍 TradeView - Is user logged in: $isLoggedIn');

    if (!isLoggedIn) {
      print('❌ TradeView - User not logged in, showing error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Oturum süresi doldu. Lütfen tekrar giriş yapın.'),
              ],
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    final tradeViewModel = Provider.of<TradeViewModel>(context, listen: false);
    final productViewModel = Provider.of<ProductViewModel>(
      context,
      listen: false,
    );

    print('🔄 TradeView - calling tradeViewModel.fetchMyTrades()');
    tradeViewModel.fetchMyTrades();

    // Dinamik kullanıcı ID'sini al
    print('🔄 TradeView - getting current user ID');
    final userId = await _authService.getCurrentUserId();
    print('🔍 TradeView - User ID: $userId');

    if (userId != null && userId.isNotEmpty) {
      print(
        '🔄 TradeView - calling productViewModel.loadFavoriteProducts()',
      );
      await productViewModel.loadFavoriteProducts();
      
      // Kullanıcı takaslarını yükle
      print('🔄 TradeView - calling tradeViewModel.loadUserTrades($userId)');
      await tradeViewModel.loadUserTrades(int.parse(userId));
      
      // Favorilerin yüklendiğini kontrol et
      print('🔍 TradeView - Checking if favorites loaded successfully');
      print('🔍 TradeView - favoriteProducts.length: ${productViewModel.favoriteProducts.length}');
    } else {
      print(
        '❌ TradeView - User ID is null or empty, user might not be logged in',
      );
      print('❌ TradeView - Redirecting to login or showing error');

      // Kullanıcı login olmamışsa hata göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.login, color: Colors.white),
                SizedBox(width: 8),
                Text('Lütfen giriş yapın'),
              ],
            ),
            backgroundColor: Colors.orange.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
    print('🔄 TradeView _loadData completed');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text(
          'Hesabım',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz_outlined, size: 16),
                  SizedBox(width: 4),
                  Text('Takaslar'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_outline, size: 16),
                  SizedBox(width: 4),
                  Text('Favoriler'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Consumer<ProductViewModel>(
        builder: (context, productViewModel, child) {
          print('🎨 TradeView Consumer builder called - ${DateTime.now()}');
          print(
            '🎨 TradeView - productViewModel.isLoading: ${productViewModel.isLoading}',
          );
          print(
            '🎨 TradeView - productViewModel.hasError: ${productViewModel.hasError}',
          );

          if (productViewModel.isLoading) {
            print('🎨 TradeView - Showing loading widget');
            return Container(
              color: AppTheme.background,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Yükleniyor...',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (productViewModel.hasError) {
            print('🎨 TradeView - Showing error widget (product error)');
            return CustomErrorWidget(
              message: productViewModel.errorMessage!,
              onRetry: _loadData,
            );
          }

          print('🎨 TradeView - Building TabBarView');
          return TabBarView(
            controller: _tabController,
            children: [
              // Takasladıklarım tab
              _buildTradedItemsTab(),

              // Favoriler tab
              _buildFavoritesTab(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTradedItemsTab() {
    return Consumer<TradeViewModel>(
      builder: (context, tradeViewModel, child) {
        if (tradeViewModel.isLoading) {
          return Container(
            color: Color(0xFFF8FAFF),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF10B981)),
                  SizedBox(height: 16),
                  Text(
                    'Takaslarınız yükleniyor...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF718096),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (tradeViewModel.hasError) {
          return Container(
            color: Color(0xFFF8FAFF),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    tradeViewModel.errorMessage ?? 'Bir hata oluştu',
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final userId = await _authService.getCurrentUserId();
                      if (userId != null) {
                        tradeViewModel.loadUserTrades(int.parse(userId));
                      }
                    },
                    child: Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          );
        }

        final trades = tradeViewModel.userTrades;
        
        if (trades.isEmpty) {
          return Container(
            color: Color(0xFFF8FAFF),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF10B981).withOpacity(0.1),
                            Color(0xFF059669).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Icon(
                        Icons.swap_horiz_outlined,
                        size: 50,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Henüz takasınız yok',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'İlk takasınızı başlatarak takas yolculuğuna başlayın',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF718096),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Container(
          color: Color(0xFFF8FAFF),
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: trades.length,
            itemBuilder: (context, index) {
              final trade = trades[index];
              return _buildTradeCard(trade);
            },
          ),
        );
      },
    );
  }

  Widget _buildTradeCard(UserTrade trade) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Takas başlığı ve durumu
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(trade.statusID).withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(trade.statusID),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(trade.statusID),
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Takas #${trade.offerID}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        trade.statusTitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: _getStatusColor(trade.statusID),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  trade.createdAt,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          
          // Ürünler
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Benim ürünüm
                Expanded(
                  child: _buildProductCard(trade.myProduct, 'Benim Ürünüm'),
                ),
                SizedBox(width: 16),
                // Takas ikonu
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.swap_horiz,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                // Onların ürünü
                Expanded(
                  child: _buildProductCard(trade.theirProduct, 'Onların Ürünü'),
                ),
              ],
            ),
          ),
          
          // Teslimat bilgileri
          if (trade.meetingLocation != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFFF7FAFC),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF718096),
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${trade.deliveryType} - ${trade.meetingLocation}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF718096),
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

  Widget _buildProductCard(TradeProduct? product, String title) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF718096),
            ),
          ),
          SizedBox(height: 8),
          if (product != null) ...[
            if (product.productImage.isNotEmpty)
              Container(
                height: 60,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.productImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.image_not_supported, color: Colors.grey.shade400);
                    },
                  ),
                ),
              ),
            SizedBox(height: 8),
            Text(
              product.productTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                product.productCondition,
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ] else ...[
            // Ürün silinmiş durumu
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade200,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline, color: Colors.grey.shade400, size: 24),
                    SizedBox(height: 4),
                    Text(
                      'Ürün Silinmiş',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(int statusId) {
    switch (statusId) {
      case 1: // Takas Başlatıldı
        return Colors.blue;
      case 2: // Kargoya Verildi
        return Colors.orange;
      case 3: // Teslim Edildi / Alındı
        return Colors.green;
      case 4: // Tamamlandı
        return Color(0xFF10B981);
      case 5: // İptal Edildi
        return Colors.red;
      case 6: // Beklemede
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(int statusId) {
    switch (statusId) {
      case 1: // Takas Başlatıldı
        return Icons.play_arrow;
      case 2: // Kargoya Verildi
        return Icons.local_shipping;
      case 3: // Teslim Edildi / Alındı
        return Icons.check_circle;
      case 4: // Tamamlandı
        return Icons.done_all;
      case 5: // İptal Edildi
        return Icons.cancel;
      case 6: // Beklemede
        return Icons.pause;
      default:
        return Icons.help;
    }
  }

  Widget _buildFavoritesTab() {
    return Consumer<ProductViewModel>(
      builder: (context, productViewModel, child) {
        print('🎨 TradeView._buildFavoritesTab called');
        print('🎨 TradeView - favoriteProducts.length: ${productViewModel.favoriteProducts.length}');
        print('🎨 TradeView - isLoadingFavorites: ${productViewModel.isLoadingFavorites}');
        print('🎨 TradeView - hasErrorFavorites: ${productViewModel.hasErrorFavorites}');
        print('🎨 TradeView - favoriteErrorMessage: ${productViewModel.favoriteErrorMessage}');

        if (productViewModel.isLoadingFavorites) {
          print('🎨 TradeView - Showing loading for favorites');
          return Container(
            color: Color(0xFFF8FAFF),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircularProgressIndicator(
                      color: Color(0xFFF56565),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Favoriler yükleniyor...',
                    style: TextStyle(
                      color: Color(0xFFF56565),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (productViewModel.hasErrorFavorites) {
          print('🎨 TradeView - Showing error for favorites');
          return CustomErrorWidget(
            message: productViewModel.favoriteErrorMessage ?? 'Favoriler yüklenirken hata oluştu',
            onRetry: () async {
              await productViewModel.loadFavoriteProducts();
            },
          );
        }

        if (productViewModel.favoriteProducts.isEmpty) {
          print('🎨 TradeView - No favorite products, showing empty state');
          return Container(
            color: Color(0xFFF8FAFF),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Container
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFF56565).withOpacity(0.1),
                            Color(0xFFE53E3E).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Icon(
                        Icons.favorite_outline,
                        size: 50,
                        color: Color(0xFFF56565),
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Henüz favori ilanın yok!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Beğendiğin ilanları favorilere ekleyerek burada görebilirsin',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF718096),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    // Yenile butonu ekle
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF56565).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color(0xFFF56565).withOpacity(0.3),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            print('🔄 TradeView - Manually refreshing favorites');
                            await productViewModel.loadFavoriteProducts();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.refresh, color: Color(0xFFF56565), size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Yenile',
                                  style: TextStyle(
                                    color: Color(0xFFF56565),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF10B981)],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // Ana sayfaya yönlendir
                            Navigator.of(context).pushReplacementNamed('/home');
                          },
                          borderRadius: BorderRadius.circular(25),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.home, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'İlanları Keşfet',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        print('🎨 TradeView - Building favorites grid with ${productViewModel.favoriteProducts.length} products');
        return Container(
          color: Color(0xFFF8FAFF),
          child: RefreshIndicator(
            onRefresh: () async {
              await productViewModel.loadFavoriteProducts();
            },
            child: Padding(
              padding: EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: productViewModel.favoriteProducts.length,
                itemBuilder: (context, index) {
                  final product = productViewModel.favoriteProducts[index];
                  print('🎨 Building FavoriteProductCard for index $index: ${product.title}');
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          print('🎨 FavoriteProductCard tapped: ${product.title}');
                          _showFavoriteProductDetails(product);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: ProductCard(
                          product: product,
                          heroTag: 'favorite_${product.id}_$index',
                          onTap: () {
                            print('🎨 FavoriteProductCard tapped: ${product.title}');
                            _showFavoriteProductDetails(product);
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFavoriteProductDetails(dynamic product) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Color(0xFFF8FAFF),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF56565), Color(0xFFE53E3E)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        product.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ürün resmi
                      if (product.images.isNotEmpty)
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey.shade200,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Builder(
                              builder: (context) {
                                final imageUrl = product.images.first;
                                
                                if (imageUrl.isEmpty || imageUrl == 'null' || imageUrl == 'undefined') {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFF56565).withOpacity(0.1),
                                          Color(0xFFE53E3E).withOpacity(0.1),
                                        ],
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 50,
                                      color: Color(0xFFF56565),
                                    ),
                                  );
                                }
                                
                                return CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFF56565).withOpacity(0.1),
                                          Color(0xFFE53E3E).withOpacity(0.1),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFFF56565),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFFF56565).withOpacity(0.1),
                                            Color(0xFFE53E3E).withOpacity(0.1),
                                          ],
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 50,
                                        color: Color(0xFFF56565),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),

                      if (product.images.isNotEmpty) SizedBox(height: 20),

                      // Açıklama
                      _buildDetailCard(
                        'Açıklama',
                        product.description.isNotEmpty
                            ? product.description
                            : 'Açıklama belirtilmemiş',
                        icon: Icons.description_outlined,
                      ),

                      SizedBox(height: 16),

                      // Durum
                      _buildDetailCard(
                        'Durum',
                        product.condition,
                        icon: Icons.info_outline,
                        isChip: true,
                        chipColor: Color(0xFF10B981),
                      ),

                      SizedBox(height: 16),

                      // Kategori
                      _buildDetailCard(
                        'Kategori',
                        product.category.name,
                        icon: Icons.category_outlined,
                      ),

                      SizedBox(height: 16),

                      // Takas tercihleri
                      if (product.tradePreferences.isNotEmpty)
                        _buildDetailCard(
                          'Takas Tercihi',
                          product.tradePreferences.join(', '),
                          icon: Icons.swap_horiz_outlined,
                        ),
                    ],
                  ),
                ),
              ),
              
              // Actions
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Favorilerden Çıkar butonu
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF56565), Color(0xFFE53E3E)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFF56565).withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            Navigator.pop(context);
                            await _removeFromFavorites(product.id);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.favorite_border, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Favorilerden Çıkar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    // İlanları Keşfet butonu
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Color(0xFF667EEA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Color(0xFF667EEA).withOpacity(0.3),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.of(context).pushReplacementNamed('/home');
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.home, color: Color(0xFF667EEA), size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'İlanları Keşfet',
                                  style: TextStyle(
                                    color: Color(0xFF667EEA),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, {
    required IconData icon,
    bool isChip = false,
    Color? chipColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF667EEA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Color(0xFF667EEA),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF718096),
                  ),
                ),
                SizedBox(height: 4),
                if (isChip)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (chipColor ?? Color(0xFF10B981)).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (chipColor ?? Color(0xFF10B981)).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        color: chipColor ?? Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2D3748),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFromFavorites(String productId) async {
    print('💔 TradeView - Removing product from favorites: $productId');

    try {
      final productViewModel = Provider.of<ProductViewModel>(
        context,
        listen: false,
      );
      final success = await productViewModel.toggleFavorite(productId);

      if (success) {
        print('✅ TradeView - Product removed from favorites successfully');
        print('✅ TradeView - Current favorite products count: ${productViewModel.favoriteProducts.length}');
        print('✅ TradeView - Current favorite product IDs: ${productViewModel.favoriteProducts.map((p) => p.id).toList()}');
        
        // UI'ı manuel olarak yeniden build et
        if (mounted) {
          setState(() {
            print('🔄 TradeView - setState called to refresh UI');
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.favorite_border, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Ürün favorilerden çıkarıldı'),
                ],
              ),
              backgroundColor: Color(0xFFF56565),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              action: SnackBarAction(
                label: 'Tamam',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      } else {
        print('❌ TradeView - Failed to remove product from favorites');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Favorilerden çıkarılamadı'),
                ],
              ),
              backgroundColor: Color(0xFFF56565),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              action: SnackBarAction(
                label: 'Tamam',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('💥 TradeView - Remove from favorites exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Favorilerden çıkarılırken hata oluştu'),
              ],
            ),
            backgroundColor: Color(0xFFF56565),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
} 