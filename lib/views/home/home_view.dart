import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../core/app_theme.dart';
import '../../widgets/product_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart' as custom_error;
import '../../widgets/filter_bottom_sheet.dart';
import '../../models/product_filter.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/category_list.dart';
import '../profile/profile_view.dart';
import '../product/add_product_view.dart';
import '../trade/trade_view.dart';
import '../../widgets/skeletons/product_grid_skeleton.dart';
import '../../widgets/custom_bottom_nav.dart';

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
      productViewModel.loadInitialData();
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
      backgroundColor: Colors.white,
      body: _buildPage(_currentIndex),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddProductView()),
            );
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
        return const Center(child: Text('Keşfet'));
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
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }

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
              (context, index) => ProductCard(
                product: vm.products[index],
                heroTag: 'home_product_${vm.products[index].id}_$index',
              ),
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
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Ürün ara...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey[500],
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
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
                      Icons.tune,
                      color: vm.currentFilter.hasActiveFilters
                          ? Colors.white
                          : Colors.grey[600],
                      size: 20,
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
