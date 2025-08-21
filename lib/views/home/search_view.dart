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
      // Arama geçmişini yükle
      context.read<ProductViewModel>().loadSearchHistory();
    });
    // Odaklanınca geçmişi tazele
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        context.read<ProductViewModel>().loadSearchHistory();
      }
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
    if (query.trim().length >= 2) {
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

  /// Subtitle'dan ürün sayısını çıkarır (örn: "İZMİR > KARŞIYAKA" -> 0, "Kategori" -> 0)
  int _extractProductCount(String subtitle) {
    try {
      // Subtitle'da sayı varsa onu al
      final regex = RegExp(r'(\d+)');
      final match = regex.firstMatch(subtitle);
      if (match != null) {
        return int.tryParse(match.group(1) ?? '0') ?? 0;
      }

      // Sayı yoksa varsayılan olarak 0 döndür
      return 0;
    } catch (e) {
      return 0;
    }
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
                  if (value.trim().isNotEmpty) {
                    final vm = context.read<ProductViewModel>();
                    vm.liveSearch(value);
                  }
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
                  // Ana içerik: Geçmiş ve öneriler (arama yapılmamışsa)
                  if (!_hasSearched)
                    Consumer<ProductViewModel>(
                      builder: (context, vm, _) {
                        // "Geçmişler" başlığı her zaman üstte sabit
                        return Column(
                          children: [
                            // Sabit "Geçmişler" başlığı
                            Container(
                              width: double.infinity,
                              color: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Geçmişler',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  if (vm.searchHistory.isNotEmpty)
                                    TextButton.icon(
                                      onPressed: () {
                                        context
                                            .read<ProductViewModel>()
                                            .clearSearchHistory();
                                      },
                                      icon: const Icon(
                                        Icons.delete_sweep,
                                        size: 18,
                                      ),
                                      label: const Text('Geçmişi temizle'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Arama geçmişi listesi
                            if (vm.searchHistory.isNotEmpty)
                              Container(
                                color: Colors.white,
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  itemCount: vm.searchHistory.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color: Colors.grey[200],
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = vm.searchHistory[index];
                                    return ListTile(
                                      leading: const Icon(
                                        Icons.history,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                      title: Text(
                                        item.search,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      onTap: () {
                                        _searchController.text = item.search;
                                        setState(() {});
                                        context
                                            .read<ProductViewModel>()
                                            .liveSearch(item.search);
                                        _performSearch(item.search);
                                      },
                                    );
                                  },
                                ),
                              ),

                            // Canlı öneriler (sadece arama çubuğu boşken göster)
                            if (vm.liveResults.isNotEmpty &&
                                _searchController.text.isEmpty)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      child: Text(
                                        'Arama Önerileri',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                    Builder(
                                      builder: (context) {
                                        // Sadece kategorileri filtrele ve sırala
                                        final categories = vm.liveResults
                                            .where(
                                              (item) =>
                                                  item.type != 'product' &&
                                                  item.icon != 'product',
                                            )
                                            .toList();

                                        // En çok ilandan en aza sırala (subtitle'daki sayıya göre)
                                        categories.sort((a, b) {
                                          final aCount = _extractProductCount(
                                            a.subtitle,
                                          );
                                          final bCount = _extractProductCount(
                                            b.subtitle,
                                          );
                                          return bCount.compareTo(
                                            aCount,
                                          ); // Büyükten küçüğe
                                        });

                                        if (categories.isEmpty)
                                          return const SizedBox.shrink();

                                        return ListView.separated(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: categories.length,
                                          separatorBuilder: (_, __) => Divider(
                                            height: 1,
                                            color: Colors.grey[200],
                                          ),
                                          itemBuilder: (context, index) {
                                            final item = categories[index];
                                            return ListTile(
                                              leading: const Icon(
                                                Icons.category,
                                                color: Colors.grey,
                                                size: 20,
                                              ),
                                              title: Text(
                                                item.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontSize: 14),
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
                                                // Kategori önerisine tıklandığında arama geçmişine ekle
                                                final vm = context
                                                    .read<ProductViewModel>();
                                                vm.addSearchHistoryEntry(
                                                  item.title,
                                                );

                                                final filter = vm.currentFilter
                                                    .copyWith(
                                                      categoryId: item.id
                                                          .toString(),
                                                      searchText: null,
                                                    );
                                                vm.applyFilter(filter);
                                                setState(() {
                                                  _searchController.clear();
                                                  FocusScope.of(
                                                    context,
                                                  ).unfocus();
                                                  _hasSearched = true;
                                                  _currentQuery = '';
                                                });
                                              },
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),

                            // Eğer hem geçmiş hem de öneriler boşsa VE arama çubuğu boşsa bilgilendirme göster
                            if (vm.searchHistory.isEmpty &&
                                vm.liveResults.isEmpty &&
                                _searchController.text.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.search,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
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
                                      'En az 2 karakter yazarak\nürün aramaya başlayın',
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
                          ],
                        );
                      },
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
                            return Column(
                              children: [
                                // Sonuç bulunamadı mesajı
                                Expanded(
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                  ),
                                ),

                                // Öneriler (sonuç bulunamadığında)
                                if (vm.liveResults.isNotEmpty)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border(
                                        top: BorderSide(
                                          color: Colors.grey[200]!,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Text(
                                            'Öneriler',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ),
                                        ListView.separated(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: vm.liveResults.length,
                                          separatorBuilder: (_, __) => Divider(
                                            height: 1,
                                            color: Colors.grey[200],
                                          ),
                                          itemBuilder: (context, index) {
                                            final item = vm.liveResults[index];
                                            return ListTile(
                                              leading: Icon(
                                                (item.type == 'product' ||
                                                        item.icon == 'product')
                                                    ? Icons.shopping_bag
                                                    : Icons.category,
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
                                                if (item.type == 'product' ||
                                                    item.icon == 'product') {
                                                  Navigator.pushNamed(
                                                    context,
                                                    '/product-detail',
                                                    arguments: {
                                                      'productId': item.id
                                                          .toString(),
                                                    },
                                                  );
                                                } else {
                                                  final vm = context
                                                      .read<ProductViewModel>();
                                                  // Kategori önerisine tıklandığında arama geçmişine ekle
                                                  vm.addSearchHistoryEntry(
                                                    item.title,
                                                  );

                                                  final filter = vm
                                                      .currentFilter
                                                      .copyWith(
                                                        categoryId: item.id
                                                            .toString(),
                                                        searchText: null,
                                                      );
                                                  vm.applyFilter(filter);
                                                  setState(() {
                                                    _searchController.clear();
                                                    FocusScope.of(
                                                      context,
                                                    ).unfocus();
                                                    _hasSearched = true;
                                                    _currentQuery = '';
                                                  });
                                                }
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
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
                                leading: Icon(
                                  (item.type == 'product' ||
                                          item.icon == 'product')
                                      ? Icons.shopping_bag
                                      : Icons.category,
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
                                  if (item.type == 'product' ||
                                      item.icon == 'product') {
                                    Navigator.pushNamed(
                                      context,
                                      '/product-detail',
                                      arguments: {
                                        'productId': item.id.toString(),
                                      },
                                    );
                                  } else {
                                    final vm = context.read<ProductViewModel>();
                                    // Kategori önerisine tıklandığında arama geçmişine ekle
                                    vm.addSearchHistoryEntry(item.title);

                                    final filter = vm.currentFilter.copyWith(
                                      categoryId: item.id.toString(),
                                      searchText: null,
                                    );
                                    vm.applyFilter(filter);
                                    setState(() {
                                      _searchController.clear();
                                      FocusScope.of(context).unfocus();
                                      _hasSearched = true;
                                      _currentQuery = '';
                                    });
                                  }
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

            // Vitrin alanı kaldırıldı
          ],
        ),
      ),
    );
  }
}
