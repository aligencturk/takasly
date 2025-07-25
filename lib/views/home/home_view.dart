import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../core/app_theme.dart'; // Yeni temayı import et
import '../../widgets/product_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart' as custom_error;
import '../../widgets/filter_bottom_sheet.dart';
import '../../models/product_filter.dart';
import 'widgets/home_app_bar.dart'; // Yeni AppBar
import 'widgets/category_list.dart'; // Yeni Kategori Listesi
import '../profile/profile_view.dart';
import '../product/add_product_view.dart';
import '../trade/trade_view.dart';
import '../../widgets/skeletons/product_grid_skeleton.dart'; // Skeleton'u import et

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productViewModel = Provider.of<ProductViewModel>(
        context,
        listen: false,
      );
      productViewModel.loadInitialData(); // Tüm başlangıç verilerini yükle
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
      // Eğer filtre aktifse filtered products yükle, değilse normal products yükle
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
      backgroundColor: AppTheme.background,
      body: _buildPage(_currentIndex),
      floatingActionButton: FloatingActionButton(
        heroTag: "home_fab",
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductView()),
          );
        },
        backgroundColor: AppTheme.accent,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return _buildHomeTab();
      case 1:
        // TODO: Keşfet Sayfası
        return const Center(child: Text('Keşfet'));
      case 2:
        // AddProductView butonu FAB ile handle ediliyor.
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
      color: AppTheme.primary,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          const HomeAppBar(), // Yeni, modern AppBar
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          _buildFilterBar(), // Filtreleme çubuğu
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          const CategoryList(), // Yeni, yatay kategori listesi
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          _buildProductGrid(), // Yeni, GridView ürün listesi
          _buildLoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        print('🎨 HomeView - Consumer builder called');
        print('🎨 HomeView - vm.isLoading: ${vm.isLoading}');
        print('🎨 HomeView - vm.products.length: ${vm.products.length}');
        print('🎨 HomeView - vm.hasError: ${vm.hasError}');
        print('🎨 HomeView - vm.errorMessage: ${vm.errorMessage}');

        if (vm.isLoading && vm.products.isEmpty) {
          print('🎨 HomeView - Showing skeleton loader');
          return const SliverToBoxAdapter(child: ProductGridSkeleton());
        }

        if (vm.hasError && vm.products.isEmpty) {
          print('🎨 HomeView - Showing error widget');
          return SliverFillRemaining(
            child: custom_error.CustomErrorWidget(
              message: vm.errorMessage ?? 'Ürünler yüklenemedi.',
              onRetry: () => vm.refreshProducts(),
            ),
          );
        }

        if (vm.products.isEmpty) {
          print('🎨 HomeView - Showing empty message');
          return const SliverFillRemaining(
            child: Center(child: Text('Gösterilecek ürün bulunamadı.')),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75, // Kart oranını ayarla
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => ProductCard(product: vm.products[index]),
              childCount: vm.products.length,
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
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Arama kutusu
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Ürün ara...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade600,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (query) {
                        if (query.trim().isNotEmpty) {
                          final filter = vm.currentFilter.copyWith(
                            searchQuery: query.trim(),
                          );
                          vm.applyFilter(filter);
                        } else {
                          vm.clearFilters();
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Filtre butonu
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: vm.currentFilter.hasActiveFilters
                        ? AppTheme.primary
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: vm.currentFilter.hasActiveFilters
                          ? AppTheme.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: IconButton(
                    onPressed: () => _showFilterBottomSheet(vm),
                    icon: Icon(
                      Icons.tune,
                      color: vm.currentFilter.hasActiveFilters
                          ? Colors.white
                          : Colors.grey.shade600,
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
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: AppTheme.surface,
      elevation: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavBarItem(
            icon: Icons.home_filled,
            index: 0,
            label: 'Ana Sayfa',
          ),
          _buildNavBarItem(
            icon: Icons.explore_outlined,
            index: 1,
            label: 'Keşfet',
          ),
          const SizedBox(width: 48), // FAB için boşluk
          _buildNavBarItem(
            icon: Icons.swap_horiz,
            index: 3,
            label: 'Takaslarım',
          ),
          _buildNavBarItem(
            icon: Icons.person_outline,
            index: 4,
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildNavBarItem({
    required IconData icon,
    required int index,
    required String label,
  }) {
    final bool isSelected = _currentIndex == index;
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
        size: 28,
      ),
      onPressed: () {
        if (index != 2) {
          // Ortadaki boşluk tıklanabilir değil
          setState(() {
            _currentIndex = index;
          });
        }
      },
      tooltip: label,
    );
  }

  void _showFilterBottomSheet(ProductViewModel vm) {
    // Önce şehirleri yükle
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
          print('🔍 HomeView - Applying filter: $filter');
          vm.applyFilter(filter);
        },
      ),
    );
  }
}
