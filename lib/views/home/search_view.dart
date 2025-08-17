import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/app_theme.dart';
import '../../widgets/product_card.dart';
import '../../widgets/error_widget.dart' as custom_error;
import '../../widgets/skeletons/product_grid_skeleton.dart';
import '../../models/product.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _hasSearched = false;
  String _currentQuery = '';
  bool _isLoadingSponsoredProducts = false;
  List<Product> _sponsoredProducts = [];

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında arama çubuğuna odaklan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
      _loadSponsoredProducts();
    });
  }

  Future<void> _loadSponsoredProducts() async {
    setState(() {
      _isLoadingSponsoredProducts = true;
    });

    try {
      final productViewModel = context.read<ProductViewModel>();

      // Mevcut products listesinden sponsor olanları filtrele
      final allProducts = productViewModel.products;
      final sponsored = allProducts
          .where((product) => product.isSponsor == true)
          .take(4)
          .toList();

      // Eğer mevcut listede sponsor ürün yoksa, tüm ürünleri yükle
      if (sponsored.isEmpty && allProducts.isEmpty) {
        await productViewModel.loadProducts();
        final refreshedProducts = productViewModel.products;
        final refreshedSponsored = refreshedProducts
            .where((product) => product.isSponsor == true)
            .take(4)
            .toList();

        setState(() {
          _sponsoredProducts = refreshedSponsored;
          _isLoadingSponsoredProducts = false;
        });
      } else {
        setState(() {
          _sponsoredProducts = sponsored;
          _isLoadingSponsoredProducts = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingSponsoredProducts = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().length >= 3) {
      setState(() {
        _hasSearched = true;
        _currentQuery = query.trim();
      });

      final productViewModel = context.read<ProductViewModel>();
      final filter = productViewModel.currentFilter.copyWith(
        searchText: query.trim(),
      );
      productViewModel.applyFilter(filter);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _hasSearched = false;
      _currentQuery = '';
    });

    final productViewModel = context.read<ProductViewModel>();
    // Filtreleri temizle ve tüm ürünleri yükle
    productViewModel.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Geri dönmeden önce filtreleri temizle
        if (_hasSearched) {
          final productViewModel = context.read<ProductViewModel>();
          productViewModel.clearFilters();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        resizeToAvoidBottomInset: true, // Klavyeyi dikkate al
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Geri dönmeden önce filtreleri temizle
              if (_hasSearched) {
                final productViewModel = context.read<ProductViewModel>();
                productViewModel.clearFilters();
              }
              Navigator.pop(context);
            },
          ),
          title: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Ürün ara...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                prefixIcon: Icon(
                  FontAwesomeIcons.search,
                  color: Colors.grey[500],
                  size: 16,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey[500],
                          size: 20,
                        ),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              onSubmitted: _performSearch,
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          actions: [
            if (_searchController.text.isNotEmpty)
              TextButton(
                onPressed: () => _performSearch(_searchController.text),
                child: const Text(
                  'Ara',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // Ana içerik alanı
            Expanded(
              child: Column(
                children: [
                  // Bilgilendirme mesajı
                  if (!_hasSearched)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.search, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Ürün Arama',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'En az 3 karakter yazarak\nürün aramaya başlayın',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                  // Arama sonuçları
                  if (_hasSearched)
                    Expanded(
                      child: Consumer<ProductViewModel>(
                        builder: (context, vm, child) {
                          if (vm.isLoading && vm.products.isEmpty) {
                            return const ProductGridSkeleton();
                          }

                          if (vm.hasError && vm.products.isEmpty) {
                            return custom_error.CustomErrorWidget(
                              message:
                                  vm.errorMessage ??
                                  'Arama sonuçları yüklenemedi.',
                              onRetry: () => _performSearch(_currentQuery),
                            );
                          }

                          if (vm.products.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Sonuç Bulunamadı',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '"$_currentQuery" için sonuç bulunamadı.\nFarklı anahtar kelimeler deneyin.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            children: [
                              // Sonuç sayısı
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  '${vm.products.length} sonuç bulundu',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              // Ürün grid'i
                              Expanded(
                                child: GridView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 10.0,
                                        mainAxisSpacing: 10.0,
                                        childAspectRatio: 0.7,
                                      ),
                                  itemCount: vm.products.length,
                                  itemBuilder: (context, index) {
                                    final product = vm.products[index];

                                    // Kullanıcının kendi ürünü olup olmadığını kontrol et
                                    bool isOwnProduct = false;
                                    if (vm.myProducts.isNotEmpty) {
                                      isOwnProduct = vm.myProducts.any(
                                        (myProduct) =>
                                            myProduct.id == product.id,
                                      );
                                    } else {
                                      // myProducts henüz yüklenmemişse, product.ownerId ile kontrol et
                                      final authViewModel =
                                          Provider.of<AuthViewModel>(
                                            context,
                                            listen: false,
                                          );
                                      final currentUserId =
                                          authViewModel.currentUser?.id;
                                      isOwnProduct =
                                          currentUserId != null &&
                                          product.ownerId == currentUserId;
                                    }

                                    return ProductCard(
                                      product: product,
                                      heroTag:
                                          'search_product_${product.id}_$index',
                                      hideFavoriteIcon:
                                          isOwnProduct, // Kullanıcının kendi ürünü ise favori ikonunu gizle
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // Sponsor İlanlar Bölümü - En Alt (Klavye açıldığında da görünür)
            _buildSponsoredSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSponsoredSection() {
    if (_sponsoredProducts.isEmpty && !_isLoadingSponsoredProducts) {
      return const SizedBox.shrink(); // Sponsor ürün yoksa gösterme
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Başlık
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      const Text(
                        'Vitrin İlanları',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (_sponsoredProducts.isNotEmpty)
                  Text(
                    '${_sponsoredProducts.length} ilan',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          // Sponsor ürünler horizontal liste
          Container(
            height: 160,
            child: _isLoadingSponsoredProducts
                ? Center(
                    child: Container(
                      width: 20,
                      height: 20,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _sponsoredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _sponsoredProducts[index];
                      return Container(
                        width: 120,
                        margin: EdgeInsets.only(
                          right: index < _sponsoredProducts.length - 1 ? 12 : 0,
                          bottom: 12,
                        ),
                        child: _buildSponsoredProductCard(product, index),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsoredProductCard(Product product, int index) {
    return GestureDetector(
      onTap: () {
        if (product.id != null && product.id.isNotEmpty) {
          Navigator.pushNamed(
            context,
            '/product-detail',
            arguments: {'productId': product.id},
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFBF0), Color(0xFFFFF8E1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ürün Resmi
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      // Resim
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.grey[100],
                        child: product.images.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: product.images[0],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[100],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                    size: 24,
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[100],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                    size: 24,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                                size: 24,
                              ),
                      ),
                      // Sponsor badge
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Ürün Bilgileri
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.title ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 8,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${product.cityTitle ?? ''}'.trim(),
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
