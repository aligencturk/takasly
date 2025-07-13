import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/constants.dart';
import '../../widgets/product_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart' as custom_error;
import '../../widgets/custom_bottom_nav.dart';
import '../profile/profile_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Kategorileri yükle (ürünler endpoint'i belirlenmedi)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productViewModel = Provider.of<ProductViewModel>(context, listen: false);
      productViewModel.loadCategories();
      // productViewModel.loadProducts(); // Geçici olarak kapatıldı
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      final productViewModel = Provider.of<ProductViewModel>(context, listen: false);
      productViewModel.loadMoreProducts();
    }
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'phone':
      case 'telefon':
        return Icons.smartphone;
      case 'computer':
      case 'bilgisayar':
        return Icons.computer;
      case 'car':
      case 'araba':
        return Icons.directions_car;
      case 'book':
      case 'kitap':
        return Icons.menu_book;
      case 'clothes':
      case 'kiyafet':
        return Icons.checkroom;
      case 'home':
      case 'ev':
        return Icons.home;
      case 'sport':
      case 'spor':
        return Icons.sports_soccer;
      case 'music':
      case 'muzik':
        return Icons.music_note;
      case 'game':
      case 'oyun':
        return Icons.sports_esports;
      case 'beauty':
      case 'guzellik':
        return Icons.face_retouching_natural;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ProductSearchDelegate(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Bildirimler sayfasına git
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildSearchTab();
      case 2:
        return _buildTradeTab();
      case 3:
        return _buildFavoritesTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return Consumer<ProductViewModel>(
      builder: (context, productViewModel, child) {
        if (productViewModel.isLoading && productViewModel.products.isEmpty) {
          return const LoadingWidget();
        }

                 if (productViewModel.hasError && productViewModel.products.isEmpty) {
           return custom_error.CustomErrorWidget(
             message: productViewModel.errorMessage!,
             onRetry: () {
               productViewModel.refreshProducts();
             },
           );
         }

        return RefreshIndicator(
          onRefresh: () async {
            await productViewModel.refreshProducts();
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Categories Section
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kategoriler',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: productViewModel.categories.length + 1, // +1 for "Tümü"
                          itemBuilder: (context, index) {
                            // İlk item "Tümü" olacak
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: GestureDetector(
                                  onTap: () {
                                    productViewModel.filterByCategory(null);
                                  },
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: productViewModel.currentCategoryId == null 
                                              ? const Color(0xFF2196F3)
                                              : const Color(0xFF2196F3).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.apps,
                                          color: productViewModel.currentCategoryId == null 
                                              ? Colors.white
                                              : const Color(0xFF2196F3),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tümü',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: productViewModel.currentCategoryId == null 
                                              ? const Color(0xFF2196F3)
                                              : Colors.grey.shade700,
                                          fontWeight: productViewModel.currentCategoryId == null 
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            
                            final category = productViewModel.categories[index - 1];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () {
                                  productViewModel.filterByCategory(category.id);
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: productViewModel.currentCategoryId == category.id
                                            ? const Color(0xFF2196F3)
                                            : const Color(0xFF2196F3).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _getCategoryIcon(category.icon),
                                        color: productViewModel.currentCategoryId == category.id
                                            ? Colors.white
                                            : const Color(0xFF2196F3),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      category.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: productViewModel.currentCategoryId == category.id
                                            ? const Color(0xFF2196F3)
                                            : Colors.grey.shade700,
                                        fontWeight: productViewModel.currentCategoryId == category.id
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Products Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tüm Ürünler',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Tümünü gör
                        },
                        child: const Text('Tümünü Gör'),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Products Placeholder
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(AppConstants.defaultPadding),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ürünler Yükleniyor...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ana sayfa ürünleri için endpoint belirlendikten sonra\nürünler burada görüntülenecek.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchTab() {
    return const Center(
      child: Text('Arama'),
    );
  }

  Widget _buildTradeTab() {
    return const Center(
      child: Text('Takaslar'),
    );
  }

  Widget _buildFavoritesTab() {
    return const Center(
      child: Text('Favoriler'),
    );
  }

  Widget _buildProfileTab() {
    return const ProfileView();
  }
}

class ProductSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('Arama yapmak için kelime girin'),
      );
    }

    return Consumer<ProductViewModel>(
      builder: (context, productViewModel, child) {
        // Arama sonuçlarını göster
        productViewModel.searchProducts(query);
        
        return ListView.builder(
          itemCount: productViewModel.products.length,
          itemBuilder: (context, index) {
            final product = productViewModel.products[index];
            return ListTile(
              leading: product.images.isNotEmpty
                  ? Image.network(
                      product.images.first,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.image_not_supported),
              title: Text(product.title),
              subtitle: Text(product.description),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/product-detail',
                  arguments: product.id,
                );
                close(context, product.title);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(
      child: Text('Popüler aramalar burada gösterilecek'),
    );
  }
} 