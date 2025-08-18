import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../viewmodels/product_viewmodel.dart';
import 'dart:async';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/app_theme.dart';
import '../../widgets/product_card.dart';
import '../../widgets/error_widget.dart' as custom_error;
import '../../widgets/skeletons/product_grid_skeleton.dart';

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
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında arama çubuğuna odaklan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
                // Debounce ile canlı arama
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  final vm = context.read<ProductViewModel>();
                  vm.liveSearch(value);
                });
              },
            ),
          ),
          actions: [
            if (_searchController.text.isNotEmpty)
              TextButton(
                onPressed: () {
                  final text = _searchController.text;
                  context.read<ProductViewModel>().liveSearch(text);
                  _performSearch(text);
                },
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
                  // Bilgilendirme mesajı: yalnızca arama alanı boşsa ve henüz arama yapılmadıysa göster
                  if (!_hasSearched && _searchController.text.isEmpty)
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
                              // Canlı arama önerileri (üstte)
                              if (!_searchFocusNode.hasFocus &&
                                  vm.liveResults.isNotEmpty)
                                const SizedBox.shrink(),

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

                  // Canlı arama: Yazarken üst boşluğu kapat
                  if (!_hasSearched && _searchController.text.isNotEmpty)
                    Expanded(
                      child: Consumer<ProductViewModel>(
                        builder: (context, vm, child) {
                          final results = vm.liveResults;
                          if (results.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 8,
                            ),
                            itemCount: results.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: Colors.grey[200]),
                            itemBuilder: (context, index) {
                              final item = results[index];
                              return ListTile(
                                leading: const Icon(
                                  Icons.shopping_bag,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                title: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  item.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/product-detail',
                                    arguments: {
                                      'productId': item.id.toString(),
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // Canlı arama önerileri (klavye açıkken de görünür)
            Consumer<ProductViewModel>(
              builder: (context, vm, child) {
                final results = vm.liveResults;
                // Üstte gösteriliyorsa alttaki çubuğu gizle
                if (!_hasSearched && _searchController.text.isNotEmpty) {
                  return const SizedBox.shrink();
                }
                if (_searchController.text.isEmpty || results.isEmpty) {
                  return const SizedBox.shrink();
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
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: results.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey[200]),
                    itemBuilder: (context, index) {
                      final item = results[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.shopping_bag,
                          color: Colors.grey,
                          size: 20,
                        ),
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        onTap: () {
                          // Ürün detayına git
                          Navigator.pushNamed(
                            context,
                            '/product-detail',
                            arguments: {'productId': item.id.toString()},
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),

            // Vitrin alanı kaldırıldı
          ],
        ),
      ),
    );
  }
}
