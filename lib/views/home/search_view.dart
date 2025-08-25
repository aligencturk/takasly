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
import '../../utils/logger.dart';

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
      // Arama geçmişini ve popüler kategorileri yükle
      final vm = context.read<ProductViewModel>();
      vm.loadSearchHistory();
      vm.loadPopularCategories();
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
      // Metin arama geçmişine ekle
      productViewModel.addTextSearchHistory(query.trim());

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
        // Sadece arama yapıldıysa filtreleri temizle
        if (_hasSearched) {
          try {
            final productViewModel = context.read<ProductViewModel>();
            Logger.info('🔍 SearchView - clearFilters() çağrılıyor...');
            await productViewModel.clearFilters();
            Logger.info(
              '🔍 SearchView - Arama yapıldı, filtreler temizlendi (en yakın filtresi otomatik uygulandı)',
            );
          } catch (e) {
            Logger.error('❌ SearchView - WillPopScope clearFilters hatası: $e');
          }
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset:
            false, // Klavye açıldığında yukarı kaymayı engelle
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              // Sadece arama yapıldıysa filtreleri temizle
              if (_hasSearched) {
                try {
                  final productViewModel = context.read<ProductViewModel>();
                  Logger.info('🔍 SearchView - clearFilters() çağrılıyor...');
                  await productViewModel.clearFilters();
                  Logger.info(
                    '🔍 SearchView - Geri butonuna basıldı, arama yapıldı, filtreler temizlendi (en yakın filtresi otomatik uygulandı)',
                  );
                } catch (e) {
                  Logger.error('❌ SearchView - clearFilters hatası: $e');
                }
              }

              // Widget hala mounted mı kontrol et
              if (mounted && context.mounted) {
                Navigator.pop(context);
              }
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
              onSubmitted: (value) {
                // Enter'a basıldığında da _hasSearched'i sıfırla
                if (_hasSearched) {
                  setState(() {
                    _hasSearched = false;
                    _currentQuery = '';
                  });
                }
                _performSearch(value);
              },
              onChanged: (value) {
                setState(() {});
                // Debounce ile canlı arama
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  if (value.trim().isNotEmpty) {
                    final vm = context.read<ProductViewModel>();
                    vm.liveSearch(value);
                    // Yeni arama yapıldığında _hasSearched'i false yap
                    if (_hasSearched) {
                      setState(() {
                        _hasSearched = false;
                        _currentQuery = '';
                      });
                    }
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
                  // Ara butonuna basıldığında da _hasSearched'i sıfırla
                  if (_hasSearched) {
                    setState(() {
                      _hasSearched = false;
                      _currentQuery = '';
                    });
                  }
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
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF0F9F4), Color(0xFFF7F8FA), Color(0xFFFFFFFF)],
              stops: [0.0, 0.6, 1.0],
            ),
          ),
          child: Column(
            children: [
            // Ana içerik alanı
            Expanded(
              child: Column(
                children: [
                  // Ana içerik: Arama yapılmıyorsa geçmiş/popüler, yazılıyorsa canlı sonuçlar
                  if (!_hasSearched)
                    Expanded(
                      child: Consumer<ProductViewModel>(
                        builder: (context, vm, _) {
                          // Yazı varsa canlı öneriler, yoksa geçmiş + popüler
                          if (_searchController.text.isNotEmpty) {
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
                                      final vm =
                                          context.read<ProductViewModel>();
                                      // Kategori önerisine tıklandığında arama geçmişine ekle
                                      vm.addCategorySearchHistory(
                                        item.title,
                                        item.id.toString(),
                                      );

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
                          }

                          return Column(
                            children: [
                              // Geçmişler bölümü - üst kısım
                              Expanded(
                                flex: 2,
                                child: Column(
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
                                              label: const Text(
                                                'Geçmişi temizle',
                                              ),
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    Colors.redAccent,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    // Arama geçmişi listesi (son 4 öğe) veya boş mesajı
                                    Expanded(
                                      child: vm.searchHistory.isNotEmpty
                                          ? Container(
                                              color: Colors.white,
                                              child: ListView.separated(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                    ),
                                                itemCount:
                                                    vm.searchHistory.length > 4
                                                    ? 4
                                                    : vm.searchHistory.length,
                                                separatorBuilder: (_, __) =>
                                                    Divider(
                                                      height: 1,
                                                      color: Colors.grey[200],
                                                    ),
                                                itemBuilder: (context, index) {
                                                  final item =
                                                      vm.searchHistory[index];
                                                  return ListTile(
                                                    leading: Icon(
                                                      item.type == 'category'
                                                          ? Icons.category
                                                          : Icons.history,
                                                      color: Colors.grey,
                                                      size: 20,
                                                    ),
                                                    title: Text(
                                                      item.search,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    onTap: () {
                                                      // Türüne göre farklı davran
                                                      if (item.type ==
                                                              'category' &&
                                                          item.categoryId !=
                                                              null) {
                                                        // Kategori ise filtre uygula
                                                        final vm = context
                                                            .read<
                                                              ProductViewModel
                                                            >();
                                                        final filter = vm
                                                            .currentFilter
                                                            .copyWith(
                                                              categoryId: item
                                                                  .categoryId,
                                                              searchText: null,
                                                            );
                                                        vm.applyFilter(filter);
                                                        setState(() {
                                                          _searchController
                                                              .clear();
                                                          FocusScope.of(
                                                            context,
                                                          ).unfocus();
                                                          _hasSearched = true;
                                                          _currentQuery = '';
                                                        });
                                                      } else {
                                                        // Metin arama ise normal arama yap
                                                        _searchController.text =
                                                            item.search;
                                                        setState(() {});
                                                        context
                                                            .read<
                                                              ProductViewModel
                                                            >()
                                                            .liveSearch(
                                                              item.search,
                                                            );
                                                        _performSearch(
                                                          item.search,
                                                        );
                                                      }
                                                    },
                                                  );
                                                },
                                              ),
                                            )
                                          : Container(
                                              color: Colors.white,
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.history,
                                                      size: 48,
                                                      color: Colors.grey[400],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Henüz arama geçmişi yok',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),

                              // Popüler Kategoriler bölümü - ana kısım
                              Expanded(
                                flex: 3,
                                child: Column(
                                  children: [
                                    // Popüler kategoriler başlığı
                                    Container(
                                      width: double.infinity,
                                      color: Colors.grey[50],
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      child: Text(
                                        'Popüler Kategoriler',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ),

                                    // Popüler kategoriler listesi
                                    Expanded(
                                      child: vm.popularCategories.isNotEmpty
                                          ? Container(
                                              color: Colors.grey[50],
                                              child: ListView.separated(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                    ),
                                                itemCount:
                                                    vm.popularCategories.length,
                                                separatorBuilder: (_, __) =>
                                                    Divider(
                                                      height: 1,
                                                      color: Colors.grey[200],
                                                    ),
                                                itemBuilder: (context, index) {
                                                  final category = vm
                                                      .popularCategories[index];
                                                  return ListTile(
                                                    leading: const Icon(
                                                      Icons.category,
                                                      color: Colors.grey,
                                                      size: 20,
                                                    ),
                                                    title: Text(
                                                      category.catName,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    subtitle: Text(
                                                      '${category.productCount} ürün',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    onTap: () {
                                                      // Kategori tıklandığında arama geçmişine ekle
                                                      final vm = context
                                                          .read<
                                                            ProductViewModel
                                                          >();
                                                      vm.addCategorySearchHistory(
                                                        category.catName,
                                                        category.catId
                                                            .toString(),
                                                      );

                                                      final filter = vm
                                                          .currentFilter
                                                          .copyWith(
                                                            categoryId: category
                                                                .catId
                                                                .toString(),
                                                            searchText: null,
                                                          );
                                                      vm.applyFilter(filter);
                                                      setState(() {
                                                        _searchController
                                                            .clear();
                                                        FocusScope.of(
                                                          context,
                                                        ).unfocus();
                                                        _hasSearched = true;
                                                        _currentQuery = '';
                                                      });
                                                    },
                                                  );
                                                },
                                              ),
                                            )
                                          : Container(
                                              color: Colors.grey[50],
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.category,
                                                      size: 48,
                                                      color: Colors.grey[400],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Popüler kategoriler yükleniyor...',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),

                              // Eğer hem geçmiş hem de popüler kategoriler boşsa VE arama çubuğu boşsa bilgilendirme göster
                              if (vm.searchHistory.isEmpty &&
                                  vm.popularCategories.isEmpty &&
                                  _searchController.text.isEmpty)
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                  ),
                                ),
                            ],
                          );
                        },
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

                                // Popüler Kategoriler (sonuç bulunamadığında)
                                if (vm.popularCategories.isNotEmpty)
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
                                            'Popüler Kategoriler',
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
                                          itemCount:
                                              vm.popularCategories.length,
                                          separatorBuilder: (_, __) => Divider(
                                            height: 1,
                                            color: Colors.grey[200],
                                          ),
                                          itemBuilder: (context, index) {
                                            final category =
                                                vm.popularCategories[index];
                                            return ListTile(
                                              leading: const Icon(
                                                Icons.category,
                                                color: Colors.grey,
                                                size: 20,
                                              ),
                                              title: Text(
                                                category.catName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              subtitle: Text(
                                                '${category.productCount} ürün',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              onTap: () {
                                                final vm = context
                                                    .read<ProductViewModel>();
                                                // Kategori tıklandığında arama geçmişine ekle
                                                vm.addCategorySearchHistory(
                                                  category.catName,
                                                  category.catId.toString(),
                                                );

                                                final filter = vm.currentFilter
                                                    .copyWith(
                                                      categoryId: category.catId
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
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              // Sonuç sayısı başlığı
                              Container(
                                width: double.infinity,
                                color: AppTheme.background,
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  '${vm.products.length} sonuç bulundu',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              // Ürün grid'i - Ana sayfa tarzı
                              Expanded(
                                child: Container(
                                  color: AppTheme.background,
                                  child: GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      16,
                                    ),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 12.0,
                                          mainAxisSpacing: 12.0,
                                          childAspectRatio: 0.75,
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
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                  // Canlı arama bloğu kaldırıldı; yazarken içerik yukarıda geçmiş/popüler yerine gösteriliyor
                ],
              ),
            ),

            // Vitrin alanı kaldırıldı
          ],
          ),
        ),
      ),
    );
  }
}
