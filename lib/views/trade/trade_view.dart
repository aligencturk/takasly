import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../viewmodels/trade_viewmodel.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/trade.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/product_card.dart';
import '../../widgets/trade_card.dart';
import '../../widgets/skeletons/trade_grid_skeleton.dart';
import '../../widgets/skeletons/favorite_grid_skeleton.dart';
import '../../core/app_theme.dart';
import '../../utils/logger.dart';
import 'trade_detail_view.dart';

class TradeView extends StatefulWidget {
  const TradeView({super.key});

  @override
  State<TradeView> createState() => _TradeViewState();
}

class _TradeViewState extends State<TradeView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  // Her trade için showButtons değerini saklayacak Map
  final Map<int, bool> _tradeShowButtonsMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    // showButtons Map'ini temizle
    _tradeShowButtonsMap.clear();

    // Önce kullanıcının login olup olmadığını kontrol et
    final isLoggedIn = await _authService.isLoggedIn();

    if (!isLoggedIn) {
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

    // Dinamik kullanıcı ID'sini al
    final userId = await _authService.getCurrentUserId();

    if (userId != null && userId.isNotEmpty) {
      // Paralel olarak tüm verileri yükle - performans optimizasyonu
      try {
        await Future.wait([
          // Takas durumlarını yükle
          tradeViewModel.loadTradeStatuses(),
          // Kullanıcı takaslarını yükle
          tradeViewModel.loadUserTrades(int.parse(userId)),
          // Favorileri yükle (eğer yüklenmemişse)
          productViewModel.favoriteProducts.isEmpty 
              ? productViewModel.loadFavoriteProducts() 
              : Future.value(),
        ]);
        
        // Takas kontrolü API'sini arka planda çalıştır (UI'ı bloklamasın)
        _checkTradeStatusesInBackground(tradeViewModel);
        
      } catch (e) {
        // Hata durumunda sadece log'la, UI'ı bloklama
      }
    } else {
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
          'Takaslarım',
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
          if (productViewModel.isLoading) {
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
            return CustomErrorWidget(
              message: productViewModel.errorMessage!,
              onRetry: _loadData,
            );
          }

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
        
        // Test için geçici olarak skeleton'ı göster
        if (tradeViewModel.isLoading || tradeViewModel.userTrades.isEmpty) {
          return const TradeGridSkeleton();
        }

        // Kompakt durum filtreleme butonu
        Widget _buildStatusFilterButton() {
          return Container(
            margin: EdgeInsets.all(12),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showStatusFilterDialog(tradeViewModel),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_list, color: Color(0xFF10B981), size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Durum Filtrele',
                          style: TextStyle(
                            color: Color(0xFF2D3748),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down, color: Color(0xFF10B981), size: 18),
                      ],
                    ),
                  ),
                ),
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
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 12),
                  Text(
                    tradeViewModel.errorMessage ?? 'Bir hata oluştu',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final userId = await _authService.getCurrentUserId();
                      if (userId != null) {
                        try {
                          await tradeViewModel.loadUserTrades(int.parse(userId));
                        } catch (e) {
                          print('⚠️ TradeView - Retry loadUserTrades exception: $e');
                        }
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
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF10B981).withOpacity(0.1),
                            Color(0xFF059669).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Icon(
                        Icons.swap_horiz_outlined,
                        size: 32,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Henüz takasınız yok',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'İlk takasınızı başlatarak takas yolculuğuna başlayın',
                      style: TextStyle(
                        fontSize: 13,
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
          child: Column(
            children: [
              _buildStatusFilterButton(),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  itemCount: trades.length,
                  itemBuilder: (context, index) {
                    final trade = trades[index];
                    
                    // TradeViewModel'den güncel trade bilgisini al
                    final updatedTrade = tradeViewModel.getTradeByOfferId(trade.offerID) ?? trade;
                    
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      child: TradeCard(
                        trade: updatedTrade,
                        currentUserId: tradeViewModel.currentUserId,
                        showButtons: _tradeShowButtonsMap[updatedTrade.offerID], // API'den gelen showButtons değeri
                        // Debug: showButtons değerini log'la
                        // showButtons: _tradeShowButtonsMap[updatedTrade.offerID],
                        onTap: () {
                          // Takas detayına git
                          Logger.info('Takas detayına gidiliyor: ${updatedTrade.offerID}', tag: 'TradeView');
                        },
                        onDetailTap: () {
                          // Takas detay sayfasına git
                          Logger.info('Takas detay sayfasına gidiliyor: ${updatedTrade.offerID}', tag: 'TradeView');
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TradeDetailView(offerID: updatedTrade.offerID),
                            ),
                          );
                        },
                        onStatusChange: (newStatusId) {
                          // TradeCard'dan gelen newStatusId aslında mevcut durum
                          // Bu durumda sadece dialog açılması gerekiyor
                          Logger.info('TradeCard onStatusChange çağrıldı: $newStatusId', tag: 'TradeView');
                          
                          // Eğer mevcut durum 4 (Tamamlandı) ise yorum dialog'unu aç
                          if (newStatusId == 4) {
                            _showTradeCompleteDialog(updatedTrade);
                          } else {
                            _showStatusChangeDialog(updatedTrade);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
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
      case 1: // Beklemede / Pending
        return Colors.orange;
      case 2: // Onaylandı / Approved
        return Colors.green;
      case 3: // İptal Edildi / Cancelled
        return Colors.red;
      case 4: // Tamamlandı / Completed
        return Color(0xFF10B981);
      case 5: // Reddedildi / Rejected
        return Colors.red;
      case 6: // Beklemede / Pending (alternatif)
        return Colors.grey;
      case 7: // Engellendi / Blocked
        return Colors.red;
      case 8: // İptal / Cancel (alternatif)
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(int statusId) {
    switch (statusId) {
      case 1: // Beklemede / Pending
        return Icons.pending;
      case 2: // Onaylandı / Approved
        return Icons.check_circle;
      case 3: // İptal Edildi / Cancelled
        return Icons.cancel;
      case 4: // Tamamlandı / Completed
        return Icons.done_all;
      case 5: // Reddedildi / Rejected
        return Icons.block;
      case 6: // Beklemede / Pending (alternatif)
        return Icons.pause;
      case 7: // Engellendi / Blocked
        return Icons.block;
      case 8: // İptal / Cancel (alternatif)
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Widget _buildFavoritesTab() {
    return Consumer<ProductViewModel>(
      builder: (context, productViewModel, child) {
        // Test için geçici olarak skeleton'ı göster
        if (productViewModel.isLoadingFavorites || productViewModel.favoriteProducts.isEmpty) {
          return const FavoriteGridSkeleton();
        }

        if (productViewModel.hasErrorFavorites) {
          return CustomErrorWidget(
            message: productViewModel.favoriteErrorMessage ?? 'Favoriler yüklenirken hata oluştu',
            onRetry: () async {
              await productViewModel.loadFavoriteProducts();
            },
          );
        }

        if (productViewModel.favoriteProducts.isEmpty) {
          return Container(
            color: Color(0xFFF8FAFF),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Container
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFF56565).withOpacity(0.1),
                            Color(0xFFE53E3E).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Icon(
                        Icons.favorite_outline,
                        size: 32,
                        color: Color(0xFFF56565),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Henüz favori ilanın yok!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Beğendiğin ilanları favorilere ekleyerek burada görebilirsin',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF718096),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    // Yenile butonu ekle
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF56565).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Color(0xFFF56565).withOpacity(0.3),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            await productViewModel.loadFavoriteProducts();
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.refresh, color: Color(0xFFF56565), size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Yenile',
                                  style: TextStyle(
                                    color: Color(0xFFF56565),
                                    fontSize: 13,
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
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF10B981)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 15,
                            offset: Offset(0, 8),
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
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.home, color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'İlanları Keşfet',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
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

        return Container(
          color: Color(0xFFF8FAFF),
          child: RefreshIndicator(
            onRefresh: () async {
              await productViewModel.loadFavoriteProducts();
            },
            child: Padding(
              padding: EdgeInsets.all(12),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                itemCount: productViewModel.favoriteProducts.length,
                itemBuilder: (context, index) {
                  final product = productViewModel.favoriteProducts[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _showFavoriteProductDetails(product);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: ProductCard(
                          product: product,
                          heroTag: 'favorite_${product.id}_$index',
                          onTap: () {
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
    try {
      final productViewModel = Provider.of<ProductViewModel>(
        context,
        listen: false,
      );
      final success = await productViewModel.toggleFavorite(productId);

      if (success) {
        // UI'ı manuel olarak yeniden build et
        if (mounted) {
          setState(() {
            // UI'ı yenile
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

  /// Durum filtreleme dialog'u göster
  void _showStatusFilterDialog(TradeViewModel tradeViewModel) {
    int? selectedStatusId;
    
    // API'den gelen durumları kontrol et
    if (tradeViewModel.tradeStatuses.isEmpty) {
      // Durumlar yüklenmemişse önce yükle
      tradeViewModel.loadTradeStatuses().then((_) {
        // Durumlar yüklendikten sonra dialog'u tekrar göster
        if (mounted) {
          _showStatusFilterDialog(tradeViewModel);
        }
      });
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.filter_list, color: Color(0xFF10B981), size: 24),
            SizedBox(width: 8),
            Text('Durum Filtrele'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tümü seçeneği
              RadioListTile<int?>(
                title: Row(
                  children: [
                    Icon(Icons.all_inclusive, color: Color(0xFF10B981), size: 20),
                    SizedBox(width: 8),
                    Text('Tümü', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                value: null,
                groupValue: selectedStatusId,
                onChanged: (value) {
                  selectedStatusId = value;
                },
                activeColor: Color(0xFF10B981),
              ),
              Divider(),
              // API'den gelen durum seçenekleri
              ...tradeViewModel.tradeStatuses.map((status) => RadioListTile<int?>(
                title: Row(
                  children: [
                    Icon(_getStatusIcon(status.statusID), color: _getStatusColor(status.statusID), size: 20),
                    SizedBox(width: 8),
                    Text(status.statusTitle),
                  ],
                ),
                subtitle: Text(
                  '${tradeViewModel.userTrades.where((trade) => trade.statusID == status.statusID).length} takas',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                value: status.statusID,
                groupValue: selectedStatusId,
                onChanged: (value) {
                  selectedStatusId = value;
                },
                activeColor: Color(0xFF10B981),
              )).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Seçilen duruma göre filtreleme işlemi
              if (selectedStatusId != null) {
                Logger.info('Seçilen durum ID: $selectedStatusId', tag: 'TradeView');
                // Burada filtreleme işlemi yapılacak
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: Text('Filtrele'),
          ),
        ],
      ),
    );
  }

  /// Durum değiştirme dropdown dialog'u göster
  void _showStatusChangeDialog(UserTrade trade) {
    int? selectedStatusId;
    final tradeViewModel = Provider.of<TradeViewModel>(context, listen: false);
    
    Logger.info('🔄 Durum değiştirme dialog\'u açılıyor - Trade #${trade.offerID}, Mevcut Durum: ${trade.statusID} (${trade.statusTitle})', tag: 'TradeView');
    
    // API'den gelen durumları kontrol et
    if (tradeViewModel.tradeStatuses.isEmpty) {
      // Durumlar yüklenmemişse önce yükle
      tradeViewModel.loadTradeStatuses().then((_) {
        // Durumlar yüklendikten sonra dialog'u tekrar göster
        if (mounted) {
          _showStatusChangeDialog(trade);
        }
      });
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.update, color: Color(0xFF10B981), size: 24),
            SizedBox(width: 8),
            Text('Durum Değiştir'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Yeni durumu seçin:',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              
              // Mevcut durum gösterimi
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(trade.statusID).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getStatusColor(trade.statusID).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(_getStatusIcon(trade.statusID), color: _getStatusColor(trade.statusID), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Mevcut: ${tradeViewModel.getStatusTitleById(trade.statusID)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: _getStatusColor(trade.statusID),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 16),
              
              // Dropdown - API'den gelen durumları kullan
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonFormField<int>(
                  value: selectedStatusId,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: InputBorder.none,
                    hintText: 'Durum seçin...',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                  items: () {
                    final allStatuses = tradeViewModel.tradeStatuses;
                    final filteredStatuses = allStatuses.where((status) => 
                      // Mevcut durumu hariç tut
                      status.statusID != trade.statusID &&
                      // Kullanıcının manuel seçmemesi gereken durumları hariç tut
                      status.statusID != 1 && // Bekleyen/Onay bekliyor
                      status.statusID != 3 && // İptal edildi (varsayılan)
                      status.statusID != 6 && // Süresi doldu (varsayılan)
                      status.statusID != 0    // Bilinmeyen durum
                    ).toList();
                    
                    Logger.info('🔄 Durum filtreleme - Toplam: ${allStatuses.length}, Filtrelenmiş: ${filteredStatuses.length}', tag: 'TradeView');
                    Logger.info('🔄 Filtrelenen durumlar: ${filteredStatuses.map((s) => '${s.statusID}(${s.statusTitle})').join(', ')}', tag: 'TradeView');
                    
                    return filteredStatuses.map((status) => DropdownMenuItem<int>(
                        value: status.statusID,
                        child: Row(
                          children: [
                            Icon(_getStatusIcon(status.statusID), color: _getStatusColor(status.statusID), size: 18),
                            SizedBox(width: 8),
                            Text(
                              status.statusTitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: _getStatusColor(status.statusID),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ))
                      .toList();
                  }(),
                  onChanged: (value) {
                    selectedStatusId = value;
                  },
                  dropdownColor: Colors.white,
                  icon: Icon(Icons.arrow_drop_down, color: Color(0xFF10B981)),
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedStatusId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lütfen bir durum seçin'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              
              // Seçilen durumun tamamlanma durumunu kontrol et
              final selectedStatus = tradeViewModel.tradeStatuses.firstWhere(
                (status) => status.statusID == selectedStatusId,
                orElse: () => const TradeStatusModel(statusID: 0, statusTitle: ''),
              );
              
              // Önce durumu güncelle
              final updateSuccess = await _updateTradeStatus(trade, selectedStatusId!);
              
              if (updateSuccess) {
                Logger.info('✅ Durum güncelleme başarılı, UI yenileniyor...', tag: 'TradeView');
                
                // Manuel olarak TradeViewModel'i yenile
                final userId = await _authService.getCurrentUserId();
                if (userId != null) {
                  await tradeViewModel.loadUserTrades(int.parse(userId));
                  Logger.info('✅ TradeViewModel manuel olarak yenilendi', tag: 'TradeView');
                  
                  // Yenilenen trade'i kontrol et
                  final updatedTrade = tradeViewModel.getTradeByOfferId(trade.offerID);
                  if (updatedTrade != null) {
                    Logger.info('✅ Güncellenmiş trade bulundu: #${updatedTrade.offerID}, statusID=${updatedTrade.statusID}', tag: 'TradeView');
                  } else {
                    Logger.warning('⚠️ Güncellenmiş trade bulunamadı: #${trade.offerID}', tag: 'TradeView');
                  }
                }
                
                // Eğer durum güncelleme başarılıysa ve tamamlanma durumundaysa yorum dialog'unu göster
                if (selectedStatus.statusID == 4 || selectedStatus.statusID == 5) {
                  _showTradeCompleteDialog(trade);
                }
              } else {
                Logger.error('❌ Durum güncelleme başarısız', tag: 'TradeView');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: Text('Değiştir'),
          ),
        ],
      ),
    );
  }

  /// Takas tamamlandığında yorum ve yıldız verme dialog'u göster
  void _showTradeCompleteDialog(UserTrade trade) {
    double rating = 5.0;
    final TextEditingController commentController = TextEditingController();
    
    // Dialog başlığını duruma göre ayarla
    String dialogTitle = trade.statusID == 4 ? 'Teslim Edildi' : 'Takas Tamamlandı';
    String dialogSubtitle = trade.statusID == 4 
        ? 'Ürün teslim edildi! Karşı tarafa yorum ve puan verin.'
        : 'Takasınızı tamamladınız! Karşı tarafa yorum ve puan verin.';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 24),
            SizedBox(width: 8),
            Text(dialogTitle),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dialogSubtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 20),
              
              // Yıldız değerlendirmesi
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Puan: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(width: 8),
                  ...List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        rating = index + 1.0;
                        // State'i güncellemek için dialog'u yeniden build et
                        Navigator.pop(context);
                        _showTradeCompleteDialog(trade);
                      },
                      child: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                    );
                  }),
                ],
              ),
              
              SizedBox(height: 20),
              
              // Yorum alanı
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Takas deneyiminizi paylaşın...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF10B981), width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (commentController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lütfen bir yorum yazın'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              final success = await _completeTradeWithReview(trade, rating.toInt(), commentController.text.trim());
              if (success) {
                // Başarılı işlem sonrası ek işlemler gerekebilir
                Logger.info('Takas tamamlama ve yorum gönderme başarılı', tag: 'TradeView');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: Text('Tamamla'),
          ),
        ],
      ),
    );
  }

  /// Takas durumunu güncelle
  Future<bool> _updateTradeStatus(UserTrade trade, int newStatusId) async {
    try {
      final tradeViewModel = Provider.of<TradeViewModel>(context, listen: false);
      final userService = UserService();
      final userToken = await userService.getUserToken();
      
      if (userToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kullanici token\'i bulunamadi')),
        );
        return false;
      }

      // Önce takas kontrolü yap
      Logger.info('Durum guncelleme oncesi takas kontrolu yapiliyor...', tag: 'TradeView');
      final checkResult = await tradeViewModel.checkTradeStatus(
        userToken: userToken,
        senderProductID: trade.myProduct?.productID ?? 0,
        receiverProductID: trade.theirProduct?.productID ?? 0,
      );

      if (checkResult != null && checkResult.data != null) {
        final data = checkResult.data!;
        Logger.info('Takas kontrolu sonucu: success=${data.success}, isSender=${data.isSender}, isReceiver=${data.isReceiver}, showButtons=${data.showButtons}, message=${data.message}', tag: 'TradeView');
        
        // API'den gelen bilgilere gore islem yap
        if (!data.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data.message),
              backgroundColor: Colors.orange,
            ),
          );
          return false;
        }
        
        // Butonlarin gosterilip gosterilmeyecegini kontrol et
        if (!data.showButtons) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data.message),
              backgroundColor: Colors.blue,
            ),
          );
          return false;
        }
      } else {
        Logger.warning('Takas kontrolu basarisiz', tag: 'TradeView');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Takas durumu kontrol edilemedi. Lutfen tekrar deneyin.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      final success = await tradeViewModel.updateTradeStatus(
        userToken: userToken,
        offerID: trade.offerID,
        newStatusID: newStatusId,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Takas durumu basariyla guncellendi'),
            backgroundColor: Colors.green,
          ),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tradeViewModel.errorMessage ?? 'Durum guncellenirken hata olustu'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Durum guncellenirken hata olustu: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  /// Arka planda takas kontrolü yap (UI'ı bloklamasın)
  void _checkTradeStatusesInBackground(TradeViewModel tradeViewModel) {
    // Arka planda çalıştır, UI'ı bloklamasın
    Future.microtask(() async {
      try {
        final userService = UserService();
        final userToken = await userService.getUserToken();
        
        if (userToken == null || userToken.isEmpty) {
          return;
        }

        // Sadece bekleyen takasları kontrol et (performans için)
        final tradesToCheck = tradeViewModel.userTrades.where((trade) => 
          trade.statusID == 1 // Sadece bekleyen takaslar
        ).toList();
        
        if (tradesToCheck.isEmpty) {
          return;
        }

        // Her trade için takas kontrolü yap (paralel olarak, daha hızlı)
        final futures = tradesToCheck.map((trade) async {
          try {
            final senderProductID = trade.myProduct?.productID ?? 0;
            final receiverProductID = trade.theirProduct?.productID ?? 0;
            
            if (senderProductID == 0 || receiverProductID == 0) {
              return;
            }
            
            final checkResult = await tradeViewModel.checkTradeStatus(
              userToken: userToken,
              senderProductID: senderProductID,
              receiverProductID: receiverProductID,
            );
            
            if (checkResult != null && checkResult.data != null) {
              final data = checkResult.data!;
              _tradeShowButtonsMap[trade.offerID] = data.showButtons;
              
              // UI'ı güncelle (mounted kontrolü ile)
              if (mounted) {
                setState(() {
                  // UI'ı yenile
                });
              }
            }
          } catch (e) {
            // Hata durumunda sessizce devam et
          }
        });

        await Future.wait(futures);
        
      } catch (e) {
        // Genel hata durumunda sessizce devam et
      }
    });
  }

  /// Tum takaslar icin takas kontrolu API'sini cagir (eski metod - geriye uyumluluk için)
  Future<void> _checkTradeStatusesForAllTrades(TradeViewModel tradeViewModel) async {
    try {
      Logger.info('Takas kontrolu baslatiliyor...', tag: 'TradeView');
      
      final userService = UserService();
      final userToken = await userService.getUserToken();
      
      if (userToken == null || userToken.isEmpty) {
        Logger.warning('Kullanici token\'i bulunamadi, takas kontrolu yapilamiyor', tag: 'TradeView');
        return;
      }

      // Bekleyen ve onaylanmış takasları filtrele (API kontrolü için)
      final tradesToCheck = tradeViewModel.userTrades.where((trade) => 
        trade.statusID == 1 || trade.statusID == 2 // Bekleyen veya onaylanmış takaslar
      ).toList();
      
      if (tradesToCheck.isEmpty) {
        Logger.info('Kontrol edilecek takas bulunamadi, kontrol yapilmiyor', tag: 'TradeView');
        return;
      }

      Logger.info('${tradesToCheck.length} adet takas icin kontrol yapiliyor (Bekleyen: ${tradesToCheck.where((t) => t.statusID == 1).length}, Onaylanmis: ${tradesToCheck.where((t) => t.statusID == 2).length})', tag: 'TradeView');

      // Her trade icin takas kontrolu yap (sira ile, UI'yi bloklamamak icin)
      for (var i = 0; i < tradesToCheck.length; i++) {
        final trade = tradesToCheck[i];
        
        // UI'nin responsive kalması için kısa bir gecikme ekle
        if (i > 0) {
          await Future.delayed(Duration(milliseconds: 100));
        }
        
        Logger.info('Takas kontrolu yapiliyor: Trade #${trade.offerID} (${i + 1}/${tradesToCheck.length}) - StatusID: ${trade.statusID}', tag: 'TradeView');
        
        try {
          // Product ID'leri kontrol et
          final senderProductID = trade.myProduct?.productID ?? 0;
          final receiverProductID = trade.theirProduct?.productID ?? 0;
          
          // Eğer product ID'ler geçersizse API çağrısı yapma
          if (senderProductID == 0 || receiverProductID == 0) {
            Logger.warning('Trade #${trade.offerID} icin gecersiz product ID\'ler: senderProductID=$senderProductID, receiverProductID=$receiverProductID', tag: 'TradeView');
            continue;
          }
          
          Logger.info('Trade #${trade.offerID} icin API cagrisi yapiliyor: senderProductID=$senderProductID, receiverProductID=$receiverProductID', tag: 'TradeView');
          
          final checkResult = await tradeViewModel.checkTradeStatus(
            userToken: userToken,
            senderProductID: senderProductID,
            receiverProductID: receiverProductID,
          );
          
          if (checkResult != null && checkResult.data != null) {
            final data = checkResult.data!;
            Logger.info('Takas kontrolu sonucu: success=${data.success}, isSender=${data.isSender}, isReceiver=${data.isReceiver}, showButtons=${data.showButtons}, message=${data.message}', tag: 'TradeView');
            
            // showButtons değerini sakla
            _tradeShowButtonsMap[trade.offerID] = data.showButtons;
            Logger.info('Trade #${trade.offerID} icin showButtons değeri saklandi: ${data.showButtons}', tag: 'TradeView');
            
            // Buton gösterme durumunu log'la
            if (data.showButtons) {
              Logger.info('✅ Trade #${trade.offerID} icin butonlar gosterilecek (API: showButtons=true, StatusID: ${trade.statusID})', tag: 'TradeView');
            } else {
              // Eğer alıcı ise ve bekleyen takas ise butonlar gösterilecek
              final isReceiver = trade.isConfirm == 0;
              if (trade.statusID == 1 && isReceiver) {
                Logger.info('✅ Trade #${trade.offerID} icin butonlar gosterilecek (API: showButtons=false ama alici ve bekleyen takas, StatusID: ${trade.statusID})', tag: 'TradeView');
              } else {
                Logger.info('❌ Trade #${trade.offerID} icin butonlar gizlenecek (API: showButtons=false, StatusID: ${trade.statusID})', tag: 'TradeView');
              }
            }
            
            // API'den gelen bilgilere gore trade durumunu guncelle
            if (data.success) {
              Logger.info('Takas kontrolu basarili, guncel durum: ${data.message}', tag: 'TradeView');
            }
          } else {
            Logger.warning('Takas kontrolu basarisiz: Trade #${trade.offerID}', tag: 'TradeView');
          }
        } catch (e) {
          Logger.error('Takas kontrolu sirasinda hata (Trade #${trade.offerID}): $e', tag: 'TradeView');
          // Hata durumunda devam et, diğer takasları kontrol et
          continue;
        }
      }
      
      Logger.info('Takas kontrolu tamamlandi', tag: 'TradeView');
    } catch (e) {
      Logger.error('Takas kontrolu sirasinda genel hata: $e', tag: 'TradeView');
    }
  }

  /// Takas tamamlandığında yorum ve yıldız ile birlikte tamamla
  Future<bool> _completeTradeWithReview(UserTrade trade, int rating, String comment) async {
    try {
      final tradeViewModel = Provider.of<TradeViewModel>(context, listen: false);
      final userService = UserService();
      final userToken = await userService.getUserToken();
      
      if (userToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kullanici token\'i bulunamadi')),
        );
        return false;
      }

      // Önce takas kontrolü yap
      Logger.info('Takas tamamlama oncesi takas kontrolu yapiliyor...', tag: 'TradeView');
      final checkResult = await tradeViewModel.checkTradeStatus(
        userToken: userToken,
        senderProductID: trade.myProduct?.productID ?? 0,
        receiverProductID: trade.theirProduct?.productID ?? 0,
      );

      if (checkResult != null && checkResult.data != null) {
        final data = checkResult.data!;
        Logger.info('Takas kontrolu sonucu: success=${data.success}, isSender=${data.isSender}, isReceiver=${data.isReceiver}, showButtons=${data.showButtons}, message=${data.message}', tag: 'TradeView');
        
        // API'den gelen bilgilere gore islem yap
        if (!data.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data.message),
              backgroundColor: Colors.orange,
            ),
          );
          return false;
        }
        
        // Butonlarin gosterilip gosterilmeyecegini kontrol et
        if (!data.showButtons) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data.message),
              backgroundColor: Colors.blue,
            ),
          );
          return false;
        }
      } else {
        Logger.warning('Takas kontrolu basarisiz', tag: 'TradeView');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Takas durumu kontrol edilemedi. Lutfen tekrar deneyin.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      // Karsi tarafin kullanici ID'sini bul
      int? toUserID;
      if (trade.myProduct != null && trade.theirProduct != null) {
        // Eger benim urunum varsa, karsi tarafin urununun sahibi
        toUserID = trade.theirProduct!.userID;
      } else if (trade.theirProduct != null) {
        toUserID = trade.theirProduct!.userID;
      }

      if (toUserID == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Karsi taraf bilgisi bulunamadi')),
        );
        return false;
      }

      final success = await tradeViewModel.completeTradeWithReview(
        userToken: userToken,
        offerID: trade.offerID,
        statusID: 4, // Tamamlandı
        toUserID: toUserID,
        rating: rating,
        comment: comment,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Takas basariyla tamamlandi ve yorum gonderildi'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        
        // Takaslari yeniden yukle
        final userId = await _authService.getCurrentUserId();
        if (userId != null) {
          await tradeViewModel.loadUserTrades(int.parse(userId));
          Logger.info('✅ TradeViewModel manuel olarak yenilendi (completeTradeWithReview)', tag: 'TradeView');
          
          // Yenilenen trade'i kontrol et
          final updatedTrade = tradeViewModel.getTradeByOfferId(trade.offerID);
          if (updatedTrade != null) {
            Logger.info('✅ Guncellenmis trade bulundu (completeTradeWithReview): #${updatedTrade.offerID}, statusID=${updatedTrade.statusID}', tag: 'TradeView');
          } else {
            Logger.warning('⚠️ Guncellenmis trade bulunamadi (completeTradeWithReview): #${trade.offerID}', tag: 'TradeView');
          }
        }
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tradeViewModel.errorMessage ?? 'Takas tamamlanirken hata olustu'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Takas tamamlanirken hata olustu: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }


} 