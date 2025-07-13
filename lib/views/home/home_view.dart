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
import '../product/add_product_view.dart';

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
      print('📱 HomeView: Post frame callback started');
      try {
        print('📱 HomeView: Getting ProductViewModel...');
        final productViewModel = Provider.of<ProductViewModel>(context, listen: false);
        print('📱 HomeView: ProductViewModel obtained, loading categories and products...');
        productViewModel.loadCategories();
        productViewModel.loadProducts(); // Ürünleri yükle
        print('📱 HomeView: Categories and products loading initiated');
      } catch (e, stackTrace) {
        print('❌ HomeView: Error in post frame callback: $e');
        print('❌ HomeView: Stack trace: $stackTrace');
      }
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
    print('📱 HomeView: build() method called');
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
        return _buildChatTab();
      case 2:
        return _buildTradeTab();
      case 3:
        return _buildMyTradesTab();
      case 4:
        return _buildAccountTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return Consumer<ProductViewModel>(
      builder: (context, productViewModel, child) {
        print('📱 Building HomeTab - categories: ${productViewModel.categories.length}, isLoading: ${productViewModel.isLoading}');
        
        // Sadece kategoriler yükleniyor, products yüklenmiyor, o yüzden loading kontrolü kaldırıldı
        // if (productViewModel.isLoading && productViewModel.products.isEmpty) {
        //   return const LoadingWidget();
        // }

         // Sadece kategoriler için hata kontrolü
         if (productViewModel.hasError && productViewModel.categories.isEmpty) {
           return custom_error.CustomErrorWidget(
             message: productViewModel.errorMessage ?? 'Bir hata oluştu',
             onRetry: () {
               productViewModel.loadCategories();
             },
           );
         }

        return RefreshIndicator(
          onRefresh: () async {
            try {
              await productViewModel.refreshProducts();
            } catch (e) {
              print('❌ RefreshIndicator error: $e');
            }
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
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
                      Text('DEBUG: Categories count: ${productViewModel.categories.length}'),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: productViewModel.categories.isEmpty 
                          ? const Center(
                              child: Text('Kategori yok', style: TextStyle(color: Colors.grey)),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              shrinkWrap: true,
                              physics: const ClampingScrollPhysics(),
                              itemCount: (productViewModel.categories.length) + 1, // +1 for "Tümü"
                              itemBuilder: (context, index) {
                                print('📱 Building category item $index of ${(productViewModel.categories.length) + 1}');
                            // İlk item "Tümü" olacak
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: GestureDetector(
                                  onTap: () {
                                    productViewModel.filterByCategory(null);
                                  },
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
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
                            
                            // Kategori listesinin boş olup olmadığını kontrol et
                            if (productViewModel.categories.isEmpty || index - 1 >= productViewModel.categories.length) {
                              return const SizedBox.shrink();
                            }
                            
                            final category = productViewModel.categories[index - 1];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () {
                                  productViewModel.filterByCategory(category.id);
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
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
                                      Flexible(
                                        child: Text(
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
                                        overflow: TextOverflow.ellipsis,
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
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const Expanded(
                        child: Text(
                          'Tüm Ürünler',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Flexible(
                        child: TextButton(
                          onPressed: () {
                            // Tümünü gör
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          child: const Text('Tümünü Gör'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Products List
              if (productViewModel.isLoading && productViewModel.products.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(AppConstants.defaultPadding),
                    padding: const EdgeInsets.all(40),
                    child: const Column(
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF2196F3),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Ürünler yükleniyor...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (productViewModel.hasError && productViewModel.products.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(AppConstants.defaultPadding),
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ürünler yüklenemedi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          productViewModel.errorMessage ?? 'Bilinmeyen hata',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red.shade400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            productViewModel.loadProducts(refresh: true);
                          },
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (productViewModel.products.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(AppConstants.defaultPadding),
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz ürün yok',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'İlk ürünü siz ekleyin!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= productViewModel.products.length) {
                          return null;
                        }
                        
                        final product = productViewModel.products[index];
                        return ProductCard(
                          product: product,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/product-detail',
                              arguments: product.id,
                            );
                          },
                        );
                      },
                      childCount: productViewModel.products.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatTab() {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Sohbetler',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // Chat List
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade300,
                      child: Icon(Icons.person, color: Colors.grey.shade600),
                    ),
                    title: Text('Kullanıcı ${index + 1}'),
                    subtitle: Text('Takasla ilgili mesaj...'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${12 + index}:${30 + index}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (index < 2)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '1',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      // Chat detail sayfasına git
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeTab() {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Takasla',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildTradeOptionCard(
                      icon: Icons.add_photo_alternate,
                      title: 'Ürün Ekle',
                      subtitle: 'Takas için ürün ekle',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddProductView(),
                          ),
                        );
                      },
                    ),
                    _buildTradeOptionCard(
                      icon: Icons.qr_code_scanner,
                      title: 'QR Tarama',
                      subtitle: 'QR kod ile takas',
                      onTap: () {
                        // QR tarama sayfasına git
                      },
                    ),
                    _buildTradeOptionCard(
                      icon: Icons.location_on,
                      title: 'Yakınımdaki',
                      subtitle: 'Yakındaki takaslar',
                      onTap: () {
                        // Yakındaki takaslar sayfasına git
                      },
                    ),
                    _buildTradeOptionCard(
                      icon: Icons.favorite,
                      title: 'Favoriler',
                      subtitle: 'Beğendiğin ürünler',
                      onTap: () {
                        // Favoriler sayfasına git
                      },
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

  Widget _buildTradeOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF10B981),
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyTradesTab() {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Takaslarım',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFF10B981),
                            width: 2,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Aktif',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Tamamlanan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'İptal Edilen',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Trades List
            Expanded(
              child: ListView.builder(
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.image,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ürün ${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Kullanıcı ${index + 1} ile takas',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Aktif',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${2 + index} gün önce',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTab() {
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