import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/ad_viewmodel.dart';
import '../../core/app_theme.dart';
import '../../widgets/product_card.dart';
import '../../widgets/error_widget.dart' as custom_error;
import '../../widgets/filter_bottom_sheet.dart';
import 'widgets/category_list.dart';
import '../profile/profile_view.dart';
import '../product/add_product_view.dart';
import '../trade/trade_view.dart';
import '../chat/chat_list_view.dart';
import '../home/search_view.dart';
import '../../widgets/skeletons/product_grid_skeleton.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/native_ad_widget.dart';
import '../../utils/logger.dart';


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
        Logger.info('🔧 HomeView - Debug mode detected, checking hot reload state...');
        final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
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
      
      // AdMob'u arka planda başlat (UI'ı bloklamasın)
      Future.microtask(() {
        final adViewModel = Provider.of<AdViewModel>(context, listen: false);
        adViewModel.initializeAdMob();
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final productViewModel = Provider.of<ProductViewModel>(
        context,
        listen: false,
      );
      if (productViewModel.currentFilter.hasActiveFilters) {
        productViewModel.loadMoreFilteredProducts();
      } else {
        productViewModel.loadMoreProducts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0F9F4),
              Color(0xFFF7F8FA),
              Color(0xFFFFFFFF),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: _buildPage(_currentIndex),
      ),
      
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) async {
          if (index == 2) {
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
        return const Center(child: Text('Boş Sayfa'));
      case 3:
        return const TradeView();
      case 4:
        return const ProfileView();
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
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return Consumer2<ProductViewModel, AdViewModel>(
      builder: (context, vm, adVm, child) {
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
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }

        // Ürün sayısını AdViewModel'e bildir
        adVm.updateProductCount(vm.products.length);

        // Her 4 üründe 1 reklam göstermek için toplam item sayısını hesapla
        final int totalItems = vm.products.length + (vm.products.length ~/ 4);
        
        Logger.debug('📊 HomeView - Toplam ürün: ${vm.products.length}, Toplam item: $totalItems');
        Logger.debug('📊 HomeView - Reklam durumu: isAdLoaded=${adVm.isAdLoaded}');
        
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Her 4 üründen sonra reklam göster (4, 8, 12, 16, ...)
                final int adFrequency = 4;
                final int adCount = index ~/ (adFrequency + 1); // Kaç tane reklam geçti
                final int productIndex = index - adCount; // Gerçek ürün indeksi
                
                // Bu pozisyon reklam pozisyonu mu?
                final bool isAdPosition = (index + 1) % (adFrequency + 1) == 0;
                
                Logger.debug('🎯 HomeView - Index: $index, ProductIndex: $productIndex, isAdPosition: $isAdPosition');
                
                                 // Eğer bu pozisyon reklam pozisyonu ise ve reklam yüklüyse
                 if (isAdPosition && adVm.isAdLoaded) {
                   Logger.info('✅ HomeView - Reklam gösteriliyor. Index: $index, ProductIndex: $productIndex');
                   return RepaintBoundary(
                     child: Container(
                       decoration: BoxDecoration(
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(12),
                         boxShadow: [
                           BoxShadow(
                             color: Colors.black.withOpacity(0.1),
                             blurRadius: 4,
                             offset: const Offset(0, 2),
                           ),
                         ],
                       ),
                       child: ClipRRect(
                         borderRadius: BorderRadius.circular(12),
                         child: const NativeAdWidget(),
                       ),
                     ),
                   );
                 }
                
                // Eğer ürün indeksi geçerli aralıkta ise ürün göster
                if (productIndex < vm.products.length) {
                  final product = vm.products[productIndex];
                  
                  // Kullanıcının kendi ürünü olup olmadığını kontrol et
                  bool isOwnProduct = false;
                  if (vm.myProducts.isNotEmpty) {
                    isOwnProduct = vm.myProducts.any((myProduct) => myProduct.id == product.id);
                  } else {
                    // myProducts henüz yüklenmemişse, product.ownerId ile kontrol et
                    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
                    final currentUserId = authViewModel.currentUser?.id;
                    isOwnProduct = currentUserId != null && product.ownerId == currentUserId;
                  }
                  
                  return ProductCard(
                    product: product,
                    heroTag: 'home_product_${product.id}_$productIndex',
                    hideFavoriteIcon: isOwnProduct, // Kullanıcının kendi ürünü ise favori ikonunu gizle
                  );
                }
                
                // Geçersiz indeks için boş widget
                Logger.debug('🚫 HomeView - Geçersiz indeks: $index');
                return const SizedBox.shrink();
              },
              childCount: totalItems,
            ),
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
            margin: const EdgeInsets.symmetric(horizontal: 20),
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
}

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
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
            width: 120,
            height: 120,
          ),
          
          // Sağ taraf - Bildirimler ve Favoriler ikonları
          Row(
            children: [
              // Bildirimler ikonu
              Container(
                width: 40,
                height: 40,
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
                    // TODO: Bildirimler sayfasına yönlendirme
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bildirimler yakında eklenecek'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Stack(
                    children: [
                      Icon(
                        FontAwesomeIcons.bell,
                        size: 18,
                        color: Colors.grey[700],
                      ),
                      // Bildirim sayısı badge'i (gelecekte dinamik olacak)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '3',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Favoriler ikonu
              Container(
                width: 40,
                height: 40,
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
                        builder: (context) => const TradeView(initialTabIndex: 1), // 1 = Favoriler sekmesi
                      ),
                    );
                  },
                  icon: Icon(
                    FontAwesomeIcons.heart,
                    size: 18,
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
