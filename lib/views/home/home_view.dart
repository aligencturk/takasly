import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';

import '../../widgets/announcement_dialog.dart';
import '../../widgets/product_card.dart';
import '../../widgets/error_widget.dart' as custom_error;
import '../../widgets/filter_bottom_sheet.dart';
import 'widgets/category_list.dart';
import '../profile/profile_view.dart';
import '../product/add_product_view.dart';
import '../trade/trade_view.dart';
import '../chat/chat_list_view.dart';
import '../home/search_view.dart';
import '../notifications/notification_list_view.dart';
import '../../widgets/skeletons/product_grid_skeleton.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../utils/logger.dart';
import '../../widgets/native_ad_grid_card.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Hot reload kontrolü - sadece debug modda
      if (kDebugMode) {
        Logger.info(
          '🔧 HomeView - Debug mode detected, checking hot reload state...',
        );
        final authViewModel = Provider.of<AuthViewModel>(
          context,
          listen: false,
        );
        await authViewModel.checkHotReloadState();
      }

      final productViewModel = Provider.of<ProductViewModel>(
        context,
        listen: false,
      );
      productViewModel.loadInitialData();
      // Favorileri arka planda yükle (UI'ı bloklamasın)
      Future.microtask(() {
        productViewModel.loadFavoriteProducts();
      });
      // Kategorilerin yüklendiğinden emin ol
      if (productViewModel.categories.isEmpty) {
        productViewModel.loadCategories();
      }

      // Bildirimleri arka planda yükle
      final notificationViewModel = Provider.of<NotificationViewModel>(
        context,
        listen: false,
      );
      Future.microtask(() {
        notificationViewModel.loadNotifications();
      });

      // Remote Config duyuru kontrolü - arka planda çalıştır
      Future.microtask(() async {
        try {
          // 2 saniye bekle ki remote config initialize olsun
          await Future.delayed(const Duration(seconds: 2));

          await AnnouncementDialog.showIfNeeded(context);
        } catch (e) {
          Logger.error('❌ Remote Config duyuru kontrolü hatası: $e', error: e);
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Scroll pozisyonunu kontrol et
    final position = _scrollController.position;
    final maxScrollExtent = position.maxScrollExtent;
    final currentPixels = position.pixels;

    // Eğer scroll pozisyonu %80'e ulaştıysa ve daha fazla ürün varsa yükle (daha agresif)
    if (currentPixels >= maxScrollExtent * 0.8 && maxScrollExtent > 0) {
      final productViewModel = Provider.of<ProductViewModel>(
        context,
        listen: false,
      );

      Logger.info(
        '📜 HomeView - Scroll position: $currentPixels/$maxScrollExtent (${(currentPixels / maxScrollExtent * 100).toStringAsFixed(1)}%)',
      );
      Logger.info(
        '📜 HomeView - hasMore: ${productViewModel.hasMore}, isLoadingMore: ${productViewModel.isLoadingMore}',
      );

      // Sadece loadMoreProducts çağır, o zaten filtreleri kontrol ediyor
      if (productViewModel.hasMore && !productViewModel.isLoadingMore) {
        Logger.info('📜 HomeView - Triggering loadMoreProducts');
        productViewModel.loadMoreProducts();
      }
    }
  }

  double _calculateChildAspectRatio(BuildContext context) {
    return 0.7; // Tüm cihazlarda sabit oran
  }

  double _calculateGridSpacing(BuildContext context) {
    return 10.0; // Tüm cihazlarda sabit spacing
  }

  double _calculateHorizontalPadding(BuildContext context) {
    return 20.0; // Tüm cihazlarda sabit padding
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F9F4), Color(0xFFF7F8FA), Color(0xFFFFFFFF)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: _buildPage(_currentIndex),
      ),

      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) async {
          if (index == 4) {
            // İlan Ekle butonu artık index 4'te
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddProductView()),
            );

            // Ürün ekleme sayfasından dönüldüğünde ürün listesini yenile
            if (result == true) {
              final productViewModel = Provider.of<ProductViewModel>(
                context,
                listen: false,
              );
              await productViewModel.refreshProducts();

              // UI'ın yenilenmesini garanti altına al
              if (mounted) {
                setState(() {
                  // State'i yenilemek için boş bir setState çağrısı
                });
              }
            }
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const ChatListView();
      case 2:
        return const TradeView();
      case 3:
        return const ProfileView();
      case 4:
        return const Center(
          child: Text('Boş Sayfa'),
        ); // İlan Ekle butonu için boş sayfa
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () => Provider.of<ProductViewModel>(
        context,
        listen: false,
      ).refreshProducts(),
      color: Colors.grey[600],
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          const HomeAppBar(),
          const SliverToBoxAdapter(),
          _buildFilterBar(),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          const CategoryList(),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          _buildProductGrid(),
          _buildLoadingIndicator(),
          // Alt navigasyon ile son kartlar arasında ferah boşluk
          _buildBottomSpacer(),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        if (vm.isLoading && vm.products.isEmpty) {
          return const SliverToBoxAdapter(child: ProductGridSkeleton());
        }

        if (vm.hasError && vm.products.isEmpty) {
          return SliverFillRemaining(
            child: custom_error.CustomErrorWidget(
              message: vm.errorMessage ?? 'Ürünler yüklenemedi.',
              onRetry: () => vm.refreshProducts(),
            ),
          );
        }

        if (vm.products.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Text(
                'Gösterilecek ürün bulunamadı.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          );
        }

        final int productCount = vm.products.length;
        final int adCount = productCount ~/ 4; // Her 4 ürüne 1 reklam
        final int totalItemCount = productCount + adCount;
        Logger.info(
          '📊 HomeView - Toplam ürün: $productCount, Toplam item (reklam dahil): $totalItemCount, hasMore: ${vm.hasMore}, isLoadingMore: ${vm.isLoadingMore}',
        );

        return SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: _calculateHorizontalPadding(context),
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: _calculateGridSpacing(context),
              mainAxisSpacing: _calculateGridSpacing(context),
              childAspectRatio: _calculateChildAspectRatio(context),
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              // Her 5. eleman reklam (index: 4,9,14,...)
              final bool isAd = ((index + 1) % 5 == 0);
              if (isAd) {
                return NativeAdGridCard(key: ValueKey('ad_$index'));
              }

              // Bu index'e kadar yerleşen reklam sayısı
              final int numAdsBefore = (index + 1) ~/ 5;
              final int productIndex = index - numAdsBefore;

              if (productIndex < 0 || productIndex >= productCount) {
                return const SizedBox.shrink();
              }

              final product = vm.products[productIndex];

              // Kullanıcının kendi ürünü olup olmadığını kontrol et
              bool isOwnProduct = false;
              if (vm.myProducts.isNotEmpty) {
                isOwnProduct = vm.myProducts.any(
                  (myProduct) => myProduct.id == product.id,
                );
              } else {
                final authViewModel = Provider.of<AuthViewModel>(
                  context,
                  listen: false,
                );
                final currentUserId = authViewModel.currentUser?.id;
                isOwnProduct =
                    currentUserId != null && product.ownerId == currentUserId;
              }

              return ProductCard(
                product: product,
                heroTag: 'home_product_${product.id}_$index',
                hideFavoriteIcon: isOwnProduct,
              );
            }, childCount: totalItemCount),
          ),
        );
      },
    );
  }

  Widget _buildFilterBar() {
    return SliverToBoxAdapter(
      child: Consumer<ProductViewModel>(
        builder: (context, vm, child) {
          return Container(
            margin: EdgeInsets.symmetric(
              horizontal: _calculateHorizontalPadding(context),
            ),
            child: Row(
              children: [
                // Arama butonu
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchView(),
                        ),
                      );
                    },
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Icon(
                            FontAwesomeIcons.search,
                            color: Colors.grey[500],
                            size: 15,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Ürün ara...',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: vm.currentFilter.hasActiveFilters
                        ? Colors.grey[800]
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: vm.currentFilter.hasActiveFilters
                          ? Colors.grey[800]!
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: IconButton(
                    onPressed: () => _showFilterBottomSheet(vm),
                    icon: Icon(
                      FontAwesomeIcons.filter,
                      color: vm.currentFilter.hasActiveFilters
                          ? Colors.white
                          : Colors.grey[600],
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SliverToBoxAdapter(
      child: Consumer<ProductViewModel>(
        builder: (context, vm, child) {
          Logger.info(
            '📊 HomeView - Loading indicator: isLoadingMore=${vm.isLoadingMore}, hasMore=${vm.hasMore}',
          );

          return vm.isLoadingMore
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                    ),
                  ),
                )
              : const SizedBox.shrink();
        },
      ),
    );
  }

  void _showFilterBottomSheet(ProductViewModel vm) {
    if (vm.cities.isEmpty) {
      vm.loadCities();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        currentFilter: vm.currentFilter,
        onApplyFilter: (filter) {
          vm.applyFilter(filter);
        },
      ),
    );
  }

  // Alt navigasyon ile çakışmayı önlemek için ekstra boşluk bırakır
  Widget _buildBottomSpacer() {
    final double bottomSafe = MediaQuery.of(context).padding.bottom;
    const double extra = 24.0; // bir tık artırılmış boşluk
    return const SliverToBoxAdapter(child: SizedBox(height: extra));
  }
}

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    // Responsive boyutlar
    final iconSize = screenWidth < 360 ? 16.0 : 18.0;
    final containerSize = screenWidth < 360 ? 36.0 : 40.0;
    final badgeSize = screenWidth < 360 ? 10.0 : 12.0;
    final badgeFontSize = screenWidth < 360 ? 6.0 : 8.0;
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: false,
      floating: false,
      expandedHeight: 60,
      centerTitle: false, // Logo'yu sola yaslamak için false yapıyoruz
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol taraf - Logo
          Image.asset(
            'assets/icons/icontext.png',
            width: screenWidth < 360 ? 100 : 120,
            height: screenWidth < 360 ? 100 : 120,
          ),

          // Sağ taraf - Bildirimler ve Favoriler ikonları
          Row(
            children: [
              // Bildirimler ikonu
              Container(
                width: containerSize,
                height: containerSize,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    Logger.debug('Bildirimler ikonuna tıklandı');
                    // Bildirimleri okundu olarak işaretle
                    final notificationViewModel =
                        Provider.of<NotificationViewModel>(
                          context,
                          listen: false,
                        );
                    notificationViewModel.markAllAsRead();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationListView(),
                      ),
                    );
                  },
                  icon: Stack(
                    children: [
                      Icon(
                        FontAwesomeIcons.bell,
                        size: iconSize,
                        color: Colors.grey[700],
                      ),
                      // Bildirim sayısı badge'i - dinamik
                      Consumer<NotificationViewModel>(
                        builder: (context, notificationViewModel, child) {
                          final notificationCount =
                              notificationViewModel.unreadCount;
                          return notificationCount > 0
                              ? Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: notificationCount > 9
                                        ? badgeSize + 2
                                        : badgeSize,
                                    height: notificationCount > 9
                                        ? badgeSize + 2
                                        : badgeSize,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        notificationCount > 9
                                            ? '9+'
                                            : notificationCount.toString(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: notificationCount > 9
                                              ? badgeFontSize - 1
                                              : badgeFontSize,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),

              const SizedBox(width: 8),

              // Favoriler ikonu
              Container(
                width: containerSize,
                height: containerSize,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    Logger.debug('Favoriler ikonuna tıklandı');
                    // TradeView'a favoriler sekmesi ile yönlendir
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TradeView(
                          initialTabIndex: 1,
                        ), // 1 = Favoriler sekmesi
                      ),
                    );
                  },
                  icon: Icon(
                    FontAwesomeIcons.heart,
                    size: iconSize,
                    color: Colors.grey[700],
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
