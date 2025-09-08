import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../viewmodels/general_viewmodel.dart';

import '../../widgets/announcement_dialog.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_list_item.dart';
import '../../widgets/inline_banner_ad.dart';
import '../../widgets/native_ad_wide_card.dart';
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
import '../product/product_detail_view.dart';
import '../../services/location_service.dart';
import '../../viewmodels/app_update_viewmodel.dart';

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
      await _initializeHomeView();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sayfa tekrar aktif olduğunda (örn: search_view'dan dönüldüğünde) en yakın filtresini kontrol et
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkAndApplyLocationFilter();
    });
  }

  @override
  void didUpdateWidget(covariant HomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Widget güncellendiğinde en yakın filtresini kontrol et
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkAndApplyLocationFilter();
    });
  }

  @override
  void activate() {
    super.activate();
    Logger.info('🔄 HomeView - activate() called, checking location filter...');
    // Sayfa tekrar aktif olduğunda (örn: navigator'dan dönüldüğünde) en yakın filtresini kontrol et
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkAndApplyLocationFilter();
    });
  }

  Future<void> _initializeHomeView() async {
    // Hot reload kontrolü - sadece debug modda
    if (kDebugMode) {
      Logger.info(
        '🔧 HomeView - Debug mode detected, checking hot reload state...',
      );
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      await authViewModel.checkHotReloadState();
    }

    final productViewModel = Provider.of<ProductViewModel>(
      context,
      listen: false,
    );

    // İlk girişte konum bazlı filtreleme yap
    Logger.info('📍 HomeView - İlk giriş, konum bazlı filtreleme başlatılıyor');
    await productViewModel.loadInitialData();

    // Konum filtreleme kontrolü
    await _checkAndApplyLocationFilter();

    // Favorileri sadece kullanıcı giriş yapmışsa yükle
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    if (authViewModel.currentUser != null) {
      Logger.info('❤️ HomeView - Kullanıcı giriş yapmış, favoriler yükleniyor');
      Future.microtask(() {
        productViewModel.loadFavoriteProducts();
      });
    } else {
      Logger.info(
        '❌ HomeView - Kullanıcı giriş yapmamış, favoriler yüklenmiyor',
      );
    }
    // Kategorilerin yüklendiğinden emin ol
    if (productViewModel.categories.isEmpty) {
      productViewModel.loadCategories();
    }

    // Logo bilgilerini yükle
    final generalViewModel = Provider.of<GeneralViewModel>(
      context,
      listen: false,
    );
    Future.microtask(() {
      generalViewModel.loadLogos();
    });

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

    // Uygulama güncelleme kontrolü - ana sayfada tetikle
    Future.microtask(() async {
      try {
        if (!mounted) return;
        final updater = context.read<AppUpdateViewModel>();
        await updater.checkForUpdate(context);
      } catch (e) {
        Logger.error('❌ HomeView - Güncelleme kontrolü hatası: $e');
      }
    });
  }

  Future<void> _checkAndApplyLocationFilter() async {
    final productViewModel = Provider.of<ProductViewModel>(
      context,
      listen: false,
    );
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    // Kullanıcı giriş yapmadıysa filtre uygulama
    if (authViewModel.currentUser == null) {
      Logger.info(
        '📍 HomeView - Kullanıcı giriş yapmamış, location filter atlanıyor',
      );
      return;
    }

    // Ürünler henüz yüklenmemişse bekle
    if (productViewModel.products.isEmpty && productViewModel.isLoading) {
      Logger.info(
        '📍 HomeView - Ürünler henüz yükleniyor, location filter bekleniyor',
      );
      return;
    }

    final currentFilter = productViewModel.currentFilter;

    Logger.info(
      '📍 HomeView - Location filter kontrol ediliyor: sortType=${currentFilter.sortType}, hasActiveFilters=${currentFilter.hasActiveFilters}',
    );

    // İlk girişte veya filtreler temizlenmişse, en yakın filtresini uygula
    if (currentFilter.sortType == 'default' &&
        !currentFilter.hasActiveFilters) {
      Logger.info(
        '📍 HomeView - İlk giriş tespit edildi, en yakın sıralama uygulanıyor',
      );

      // Konum izinlerini kontrol et ve gerekirse iste
      final locationService = LocationService();
      final hasPermission = await locationService.checkLocationPermission();

      if (hasPermission) {
        final isLocationEnabled = await locationService
            .isLocationServiceEnabled();
        if (isLocationEnabled) {
          Logger.info(
            '📍 HomeView - Konum servisleri aktif, location filtresi uygulanıyor',
          );
          await productViewModel.applyFilter(
            currentFilter.copyWith(sortType: 'location'),
          );
        } else {
          Logger.warning(
            '⚠️ HomeView - GPS servisi kapalı, varsayılan sıralama kullanılıyor',
          );
          // GPS kapalıysa kullanıcıya bilgi ver
          _showLocationServiceDialog();
        }
      } else {
        Logger.warning(
          '⚠️ HomeView - Konum izni verilmedi, varsayılan sıralama kullanılıyor',
        );
        // Konum izni verilmediyse kullanıcıya bilgi ver
        _showLocationPermissionDialog();
      }
    } else if (currentFilter.sortType != 'location' &&
        !currentFilter.hasActiveFilters) {
      // Eğer sortType location değilse ve aktif filtre yoksa, en yakın filtresini uygula
      Logger.info(
        '📍 HomeView - Filtre sıfırlandı tespit edildi, en yakın sıralama uygulanıyor',
      );
      await productViewModel.applyFilter(
        currentFilter.copyWith(sortType: 'location'),
      );
    } else if (currentFilter.sortType == 'location') {
      // Zaten location filtresi uygulanmışsa, sadece log yaz
      Logger.info(
        '📍 HomeView - Location filtresi zaten uygulanmış, işlem gerekmiyor',
      );
    } else if (currentFilter.sortType == 'location' &&
        currentFilter.hasActiveFilters) {
      // Location filtresi var ama başka filtreler de var, sadece log yaz
      Logger.info(
        '📍 HomeView - Location filtresi diğer filtrelerle birlikte aktif, işlem gerekmiyor',
      );
    } else {
      Logger.info(
        '📍 HomeView - Diğer filtreler aktif, location filtresi uygulanmıyor',
      );
    }
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
            // Ana sayfa butonuna (index 0) tekrar basıldığında sayfayı yenile
            if (index == 0 && _currentIndex == 0) {
              Logger.info(
                '🔄 HomeView - Ana sayfa butonuna tekrar basıldı, sayfa yenileniyor',
              );

              final productViewModel = Provider.of<ProductViewModel>(
                context,
                listen: false,
              );

              // Ürünleri yenile
              await productViewModel.refreshProducts();

              // Favorileri yenile
              await productViewModel.loadFavoriteProducts();

              // Kategorileri yenile (eğer boşsa)
              if (productViewModel.categories.isEmpty) {
                productViewModel.loadCategories();
              }

              // UI'ın yenilenmesini garanti altına al
              if (mounted) {
                setState(() {
                  // State'i yenilemek için boş bir setState çağrısı
                });
              }
            }

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
      onRefresh: () async {
        final productViewModel = Provider.of<ProductViewModel>(
          context,
          listen: false,
        );

        try {
          // Pull-to-refresh: konum izni varsa otomatik en yakın sıralamasını uygula
          final locationService = LocationService();
          final hasPermission = await locationService.checkLocationPermission();
          final isLocationEnabled =
              hasPermission && await locationService.isLocationServiceEnabled();

          if (isLocationEnabled) {
            Logger.info('📍 Pull-to-refresh: En yakın sıralaması uygulanıyor');
            await productViewModel.applyFilter(
              productViewModel.currentFilter.copyWith(sortType: 'location'),
            );
          } else {
            Logger.warning(
              '⚠️ Pull-to-refresh: Konum izni/servisi yok, varsayılan yenileme',
            );
            await productViewModel.refreshProducts();
          }
        } catch (e) {
          Logger.error('❌ Pull-to-refresh sırasında hata: $e', error: e);
          await productViewModel.refreshProducts();
        }

        // UI'ın yenilenmesini garanti altına al
        if (mounted) {
          setState(() {
            // State'i yenilemek için boş bir setState çağrısı
          });
        }
      },
      color: Colors.grey[600],
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          const HomeAppBar(),
          _buildFilterBar(),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          const CategoryList(),

          _buildProductGrid(),
          _buildLoadingIndicator(),
          // Alt navigasyon ile son kartlar arasında ferah boşluk
          _buildBottomSpacer(),
        ],
      ),
    );
  }

  // _ViewChip top-level tanım (HomeViewState dışında)
  // kaldırıldı: _ViewChip (yerine inline GestureDetector kullanılıyor)

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

        // Ürün listesi null safety kontrolü
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

        // Ürün listesi geçerlilik kontrolü
        final validProducts = vm.products
            .where((product) => product.id.isNotEmpty)
            .toList();

        if (validProducts.isEmpty) {
          Logger.warning(
            '⚠️ HomeView - No valid products found after filtering',
          );
          return const SliverFillRemaining(
            child: Center(
              child: Text(
                'Geçerli ürün bulunamadı.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          );
        }

        // Sponsor ürünleri en üste çıkar
        final sponsorProducts = validProducts
            .where((product) => product.isSponsor == true)
            .toList();
        final regularProducts = validProducts
            .where((product) => product.isSponsor != true)
            .toList();
        final sortedProducts = [...sponsorProducts, ...regularProducts];

        Logger.info(
          '🎯 HomeView - Sponsor products: ${sponsorProducts.length}, Regular products: ${regularProducts.length}',
        );

        final int productCount =
            sortedProducts.length; // Sıralanmış ürün sayısını kullan
        Logger.info(
          '📊 HomeView - Toplam ürün: $productCount, hasMore: ${vm.hasMore}, isLoadingMore: ${vm.isLoadingMore}',
        );

        // Ürün listesi null safety kontrolü
        if (productCount == 0) {
          return const SliverFillRemaining(
            child: Center(
              child: Text(
                'Gösterilecek ürün bulunamadı.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          );
        }

        // Görünüm tipine göre liste/grid öğelerini hazırla
        final bool isListView = vm.currentFilter.viewType == 'list';

        // Grid için öğeler
        final List<Widget> gridItems = [];
        // Liste için öğeler
        final List<Widget> listItems = [];

        for (int i = 0; i < productCount; i++) {
          final product = sortedProducts[i];

          if (product.id.isEmpty) {
            Logger.warning(
              '⚠️ HomeView - Invalid product ID at index $i: ${product.id}',
            );
            continue;
          }

          bool isOwnProduct = false;
          try {
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
          } catch (e) {
            Logger.error('❌ HomeView - Error checking product ownership: $e');
            isOwnProduct = false;
          }

          final uniqueHeroTag =
              'home_product_${product.id}_${DateTime.now().millisecondsSinceEpoch}_$i';

          // Grid öğesi
          gridItems.add(
            ProductCard(
              key: ValueKey('product_${product.id}_$i'),
              product: product,
              heroTag: uniqueHeroTag,
              hideFavoriteIcon: isOwnProduct,
            ),
          );

          // Her 5 üründe bir ürün kartına benzer reklam yerleştir
          if ((i + 1) % 5 == 0) {
            gridItems.add(const NativeAdWideCard());
          }

          // Liste öğesi
          listItems.add(
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 6.0,
              ),
              child: ProductListItem(
                product: product,
                isOwnProduct: isOwnProduct,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailView(productId: product.id),
                    ),
                  );
                },
              ),
            ),
          );

          // Her 5 öğede bir banner reklamı bağımsız liste item'ı olarak ekle
          if ((i + 1) % 5 == 0) {
            listItems.add(
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                child: InlineBannerAd(),
              ),
            );
          }

          // Her 6 ürün sonra reklam ekle
          // Eski native reklam kartları kaldırıldı; banner artık ProductListItem içinde gösterilecek
        }

        if (isListView) {
          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index < 0 || index >= listItems.length) {
                Logger.warning(
                  '⚠️ HomeView - List index out of bounds: $index, length: ${listItems.length}',
                );
                return const SizedBox.shrink();
              }
              final item = listItems[index];
              return item;
            }, childCount: listItems.length),
          );
        }

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
              // Index güvenliği kontrolü
              if (index < 0 || index >= gridItems.length) {
                Logger.warning(
                  '⚠️ HomeView - Grid index out of bounds: $index, length: ${gridItems.length}',
                );
                return const SizedBox.shrink();
              }

              final item = gridItems[index];
              return item;
            }, childCount: gridItems.length),
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
                    onTap: () async {
                      Logger.info(
                        '🔍 HomeView - Arama butonuna tıklandı, geçmiş yükleniyor...',
                      );

                      // Arama geçmişini önceden yükle
                      final productViewModel = Provider.of<ProductViewModel>(
                        context,
                        listen: false,
                      );

                      try {
                        Logger.info(
                          '📡 HomeView - loadSearchHistory() çağrılıyor...',
                        );
                        await productViewModel.loadSearchHistory();
                        Logger.info(
                          '✅ HomeView - Arama geçmişi başarıyla yüklendi',
                        );
                      } catch (e) {
                        Logger.error(
                          '❌ HomeView - Arama geçmişi yüklenirken hata: $e',
                        );
                      }

                      Logger.info('🚀 HomeView - SearchView açılıyor...');
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
    const double extra = 24.0; // bir tık artırılmış boşluk
    return const SliverToBoxAdapter(child: SizedBox(height: extra));
  }

  // Konum izni dialog'u
  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.blue),
            SizedBox(width: 8),
            Text('Konum İzni Gerekli'),
          ],
        ),
        content: Text(
          'Size en yakın ilanları gösterebilmek için konum izninize ihtiyacımız var. '
          'Konum izni vermek ister misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Hayır'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final locationService = LocationService();
              await locationService.openLocationSettings();
            },
            child: Text('Ayarlara Git'),
          ),
        ],
      ),
    );
  }

  // GPS servisi dialog'u
  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.gps_fixed, color: Colors.orange),
            SizedBox(width: 8),
            Text('GPS Servisi Kapalı'),
          ],
        ),
        content: Text(
          'Size en yakın ilanları gösterebilmek için GPS servisinin açık olması gerekiyor. '
          'GPS\'i açmak ister misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Hayır'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final locationService = LocationService();
              await locationService.openGPSSettings();
            },
            child: Text('GPS\'i Aç'),
          ),
        ],
      ),
    );
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
          Consumer<GeneralViewModel>(
            builder: (context, generalViewModel, child) {
              final logoUrl = generalViewModel.mainLogoUrl;

              if (logoUrl != null && logoUrl.isNotEmpty) {
                return AppNetworkImage(
                  imageUrl: logoUrl,
                  width: screenWidth < 360 ? 100 : 120,
                  height: screenWidth < 360 ? 100 : 120,
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.circular(8),
                  errorWidget: Image.asset(
                    'assets/icons/icontext.png',
                    width: screenWidth < 360 ? 100 : 120,
                    height: screenWidth < 360 ? 100 : 120,
                  ),
                );
              } else {
                // Logo henüz yüklenmediyse fallback kullan
                return Image.asset(
                  'assets/icons/icontext.png',
                  width: screenWidth < 360 ? 100 : 120,
                  height: screenWidth < 360 ? 100 : 120,
                );
              }
            },
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
                  onPressed: () async {
                    Logger.debug('Bildirimler ikonuna tıklandı');
                    // Bildirimleri okundu olarak işaretle
                    final notificationViewModel =
                        Provider.of<NotificationViewModel>(
                          context,
                          listen: false,
                        );
                    await notificationViewModel.markAllAsRead();

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

              // Görünüm Popup Menüsü
              Consumer<ProductViewModel>(
                builder: (context, vm, child) {
                  final isListView = vm.currentFilter.viewType == 'list';
                  return Container(
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
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'grid' && isListView) {
                          vm.applyFilter(
                            vm.currentFilter.copyWith(viewType: 'grid'),
                          );
                        } else if (value == 'list' && !isListView) {
                          vm.applyFilter(
                            vm.currentFilter.copyWith(viewType: 'list'),
                          );
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'grid',
                          child: Row(
                            children: [
                              Icon(
                                Icons.grid_view_rounded,
                                size: 16,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(width: 8),
                              const Text('Izgara'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'list',
                          child: Row(
                            children: [
                              Icon(
                                Icons.view_agenda_rounded,
                                size: 16,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(width: 8),
                              const Text('Liste'),
                            ],
                          ),
                        ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isListView
                                  ? Icons.view_agenda_rounded
                                  : Icons.grid_view_rounded,
                              size: 14,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Görünüm',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: Colors.grey[700],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
