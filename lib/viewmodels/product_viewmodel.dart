import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/product.dart' as product_model;
import '../models/city.dart';
import '../models/district.dart';
import '../models/condition.dart';
import '../models/product_filter.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../services/cache_service.dart';
import '../core/constants.dart';
import '../core/sort_options.dart';
import '../core/http_client.dart'; // ApiResponse için
import '../views/home/widgets/category_list.dart'; // CategoryIconCache için
import '../utils/logger.dart';
import '../services/error_handler_service.dart';

class ProductViewModel extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();

  List<product_model.Product> _products = [];
  List<product_model.Product> _favoriteProducts = [];
  List<product_model.Product> _myProducts = [];
  List<product_model.Category> _categories = [];
  List<product_model.Category> _subCategories = [];
  List<product_model.Category> _subSubCategories = [];
  List<product_model.Category> _subSubSubCategories = [];
  String? _selectedParentCategoryId;
  String? _selectedSubCategoryId;
  String? _selectedSubSubCategoryId;
  List<City> _cities = [];
  List<District> _districts = [];
  List<Condition> _conditions = [];
  product_model.Product? _selectedProduct;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingFavorites = false;
  bool _hasMore = true;
  String? _errorMessage;
  String? _favoriteErrorMessage;

  int _currentPage = 1;
  String? _currentCategoryId;
  String? _currentsearchText;
  String? _currentCity;
  String? _currentCondition;
  SortOption _currentSortOption = SortOption.defaultSort;

  // Yeni filtreleme sistemi
  ProductFilter _currentFilter = const ProductFilter();

  // Filter getter
  ProductFilter get currentFilter => _currentFilter;

  // Getters
  List<product_model.Product> get products => _products;
  List<product_model.Product> get favoriteProducts => _favoriteProducts;
  List<product_model.Product> get myProducts => _myProducts;
  List<product_model.Product> get userProducts => _myProducts;
  List<product_model.Category> get categories => _categories;
  List<product_model.Category> get subCategories => _subCategories;
  List<product_model.Category> get subSubCategories => _subSubCategories;
  List<product_model.Category> get subSubSubCategories => _subSubSubCategories;
  String? get selectedParentCategoryId => _selectedParentCategoryId;
  String? get selectedSubCategoryId => _selectedSubCategoryId;
  String? get selectedSubSubCategoryId => _selectedSubSubCategoryId;
  List<City> get cities => _cities;
  List<District> get districts => _districts;
  List<Condition> get conditions => _conditions;
  product_model.Product? get selectedProduct => _selectedProduct;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingFavorites => _isLoadingFavorites;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasErrorFavorites => _favoriteErrorMessage != null;
  String? get favoriteErrorMessage => _favoriteErrorMessage;

  int get currentPage => _currentPage;
  String? get currentCategoryId => _currentFilter.categoryId;
  String? get currentsearchText => _currentsearchText;
  String? get currentCity => _currentCity;
  String? get currentCondition => _currentCondition;
  SortOption get currentSortOption => _currentSortOption;

  ProductViewModel() {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await Future.wait([loadAllProducts(), loadCategories(), loadConditions()]);
  }

  Future<void> loadAllProducts({
    int page = 1,
    int limit = AppConstants.defaultPageSize,
    bool refresh = false,
  }) async {
    Logger.info(
      '🔄 ProductViewModel.loadAllProducts started - page: $page, refresh: $refresh',
    );

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _products.clear();
      Logger.info(
        '🔄 ProductViewModel.loadAllProducts - refresh mode, cleared products',
      );
    } else {
      // Refresh değilse ve ilk sayfa ise sayfa numarasını 1'e ayarla
      if (_currentPage == 1) {
        _hasMore = true;
      }
    }

    if (_isLoading || _isLoadingMore) {
      Logger.warning('⚠️ ProductViewModel.loadAllProducts - already loading, returning');
      Logger.warning('⚠️ _isLoading: $_isLoading, _isLoadingMore: $_isLoadingMore');
      return;
    }

    if (_currentPage == 1) {
      _setLoading(true);
      Logger.info(
        '🔄 ProductViewModel.loadAllProducts - set loading true for first page',
      );
    } else {
      _setLoadingMore(true);
      Logger.info(
        '🔄 ProductViewModel.loadAllProducts - set loading more true for page $_currentPage',
      );
    }

    _clearError();

    try {
      Logger.info(
        '🌐 ProductViewModel.loadAllProducts - calling getAllProducts with page: $_currentPage, limit: $limit',
      );
      final response = await _productService.getAllProducts(
        page: _currentPage,
        limit: limit,
      );

      Logger.info('📡 ProductViewModel.loadAllProducts - response received');
      Logger.info('📊 Response success: ${response.isSuccess}');
      Logger.info('📊 Response error: ${response.error}');
      Logger.info('📊 Response data products count: ${response.data?.products.length ?? 0}');

      if (response.isSuccess && response.data != null) {
        final paginatedData = response.data!;
        final newProducts = paginatedData.products;
        Logger.info(
          '✅ ProductViewModel.loadAllProducts - got ${newProducts.length} products',
        );
        Logger.info(
          '✅ ProductViewModel.loadAllProducts - pagination: page=${paginatedData.currentPage}, totalPages=${paginatedData.totalPages}, totalItems=${paginatedData.totalItems}, hasMore=${paginatedData.hasMore}',
        );

        if (_currentPage == 1) {
          _products = newProducts;
          Logger.info(
            '✅ ProductViewModel.loadAllProducts - set products for first page',
          );
        } else {
          _products.addAll(newProducts);
          Logger.info(
            '✅ ProductViewModel.loadAllProducts - added products to existing list',
          );
        }

        // API'den gelen sayfalama bilgilerini kullan
        _hasMore = paginatedData.hasMore; // currentPage < totalPages
        _currentPage = paginatedData.currentPage + 1; // Bir sonraki sayfa
        Logger.info(
          '✅ ProductViewModel.loadAllProducts - hasMore: $_hasMore (${paginatedData.currentPage} < ${paginatedData.totalPages}), nextPage: $_currentPage, totalProducts: ${_products.length}',
        );
      } else {
        Logger.error(
          '❌ ProductViewModel.loadAllProducts - API error: ${response.error}',
        );
        
        // 403 hatası kontrolü
        if (response.error != null && 
            (response.error!.contains('403') || 
             response.error!.contains('Erişim reddedildi') ||
             response.error!.contains('Geçersiz kullanıcı token'))) {
          Logger.warning('🚨 403 error detected in ProductViewModel - triggering global error handler');
          ErrorHandlerService.handleForbiddenError(null);
        }
        
        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      Logger.error('💥 ProductViewModel.loadAllProducts - Exception: $e');
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);
      _setLoadingMore(false);
      Logger.info(
        '🏁 ProductViewModel.loadAllProducts completed - final products count: ${_products.length}',
      );
      notifyListeners(); // UI'ı güncelle
    }
  }

  Future<void> loadProducts({
    String? categoryId,
    String? searchText,
    String? city,
    String? condition,
    bool refresh = false,
  }) async {
    Logger.info('🔄 ProductViewModel.loadProducts - Starting with params: categoryId=$categoryId, searchText=$searchText, city=$city, condition=$condition, refresh=$refresh');
    Logger.info('🔄 ProductViewModel.loadProducts - Current state: page=$_currentPage, hasMore=$_hasMore, isLoading=$_isLoading, isLoadingMore=$_isLoadingMore');
    
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _products.clear();
      Logger.info('🔄 ProductViewModel.loadProducts - Refresh mode: reset page=1, hasMore=true, cleared products');
    } else {
      // Refresh değilse ve ilk sayfa ise sayfa numarasını 1'e ayarla
      if (_currentPage == 1) {
        _hasMore = true;
        Logger.info('🔄 ProductViewModel.loadProducts - First page: set hasMore=true');
      }
    }

    if (_isLoading || _isLoadingMore) {
      Logger.warning('⚠️ ProductViewModel.loadProducts - Already loading, returning');
      return;
    }

    _currentCategoryId = categoryId;
    _currentsearchText = searchText;
    _currentCity = city;
    _currentCondition = condition;
    Logger.info('🔄 ProductViewModel.loadProducts - Updated current filters: categoryId=$_currentCategoryId, searchText=$_currentsearchText, city=$_currentCity, condition=$_currentCondition');

    if (_currentPage == 1) {
      _setLoading(true);
      Logger.info('🔄 ProductViewModel.loadProducts - First page: set loading=true');
    } else {
      _setLoadingMore(true);
      Logger.info('🔄 ProductViewModel.loadProducts - Next page: set loadingMore=true');
    }

    _clearError();

    try {
      Logger.info('📡 ProductViewModel.loadProducts - Making API call with page=$_currentPage, sortBy=${_currentSortOption.value}');
      final response = await _productService.getAllProducts(
        page: _currentPage,
        limit: AppConstants.defaultPageSize,
      );

      Logger.info('📡 ProductViewModel.loadProducts - Response received');
      Logger.info('📊 Response success: ${response.isSuccess}');
      Logger.info('📊 Response error: ${response.error}');
      Logger.info('📊 Response data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        final paginatedData = response.data!;
        final newProducts = paginatedData.products;
        Logger.info('✅ ProductViewModel.loadProducts - Got ${newProducts.length} products');
        Logger.info('✅ ProductViewModel.loadProducts - pagination: page=${paginatedData.currentPage}, totalPages=${paginatedData.totalPages}, totalItems=${paginatedData.totalItems}, hasMore=${paginatedData.hasMore}');

        if (_currentPage == 1) {
          _products = newProducts;
          Logger.info('✅ ProductViewModel.loadProducts - First page: replaced products list');
        } else {
          _products.addAll(newProducts);
          Logger.info('✅ ProductViewModel.loadProducts - Next page: added ${newProducts.length} products to existing list');
        }

        // API'den gelen sayfalama bilgilerini kullan
        _hasMore = paginatedData.hasMore;
        _currentPage = paginatedData.currentPage + 1;
        
        Logger.info('✅ ProductViewModel.loadProducts - Updated state: hasMore=$_hasMore (${paginatedData.currentPage} < ${paginatedData.totalPages}), nextPage=$_currentPage, totalProducts=${_products.length}');
      } else {
        // 403 hatası kontrolü
        if (response.error != null && 
            (response.error!.contains('403') || 
             response.error!.contains('Erişim reddedildi') ||
             response.error!.contains('Geçersiz kullanıcı token'))) {
          Logger.warning('🚨 403 error detected in ProductViewModel.loadProducts - triggering global error handler');
          ErrorHandlerService.handleForbiddenError(null);
        }
        
        Logger.error('❌ ProductViewModel.loadProducts - API error: ${response.error}');
        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      Logger.error('💥 ProductViewModel.loadProducts - Exception: $e');
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);
      _setLoadingMore(false);
      notifyListeners();
      Logger.info('🏁 ProductViewModel.loadProducts - Completed, final state: isLoading=$_isLoading, isLoadingMore=$_isLoadingMore');
    }
  }

  Future<void> loadMoreProducts() async {
    if (!_hasMore || _isLoadingMore) {
      Logger.info('⚠️ ProductViewModel.loadMoreProducts - Skipping: hasMore=$_hasMore, isLoadingMore=$_isLoadingMore');
      return;
    }

    Logger.info('🔄 ProductViewModel.loadMoreProducts - Loading page $_currentPage');
    Logger.info('🔄 ProductViewModel.loadMoreProducts - Current filter: $_currentFilter');
    Logger.info('🔄 ProductViewModel.loadMoreProducts - Current products count: ${_products.length}');
    
    _setLoadingMore(true);
    _clearError();

    try {
      ApiResponse<product_model.PaginatedProducts> response;
      
      // Eğer aktif filtreler varsa filtrelenmiş ürünleri yükle
      if (_currentFilter.hasActiveFilters) {
        Logger.info('🔍 ProductViewModel.loadMoreProducts - Using filtered products API');
        response = await _productService.getAllProductsWithFilter(
          filter: _currentFilter,
          page: _currentPage,
          limit: AppConstants.defaultPageSize,
        );
      } else {
        Logger.info('🔍 ProductViewModel.loadMoreProducts - Using all products API');
        response = await _productService.getAllProducts(
          page: _currentPage,
          limit: AppConstants.defaultPageSize,
        );
      }

      Logger.info('📡 ProductViewModel.loadMoreProducts - Response received');
      Logger.info('📊 Response success: ${response.isSuccess}');
      Logger.info('📊 Response error: ${response.error}');
      Logger.info('📊 Response data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        final paginatedData = response.data!;
        final newProducts = paginatedData.products;
        Logger.info('✅ ProductViewModel.loadMoreProducts - got ${newProducts.length} more products');
        Logger.info('✅ ProductViewModel.loadMoreProducts - pagination: page=${paginatedData.currentPage}, totalPages=${paginatedData.totalPages}, totalItems=${paginatedData.totalItems}, hasMore=${paginatedData.hasMore}');

        // Yeni ürünleri mevcut listeye ekle
        _products.addAll(newProducts);
        _hasMore = paginatedData.hasMore;
        _currentPage = paginatedData.currentPage + 1;
        
        Logger.info('✅ ProductViewModel.loadMoreProducts - hasMore: $_hasMore (${paginatedData.currentPage} < ${paginatedData.totalPages}), nextPage: $_currentPage, totalProducts: ${_products.length}');
        Logger.info('✅ ProductViewModel.loadMoreProducts - All products loaded successfully');
      } else {
        Logger.error('❌ ProductViewModel.loadMoreProducts - API error: ${response.error}');
        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      Logger.error('💥 ProductViewModel.loadMoreProducts - Exception: $e');
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoadingMore(false);
      notifyListeners();
      Logger.info('🏁 ProductViewModel.loadMoreProducts - Completed, final state: isLoadingMore=$_isLoadingMore, totalProducts: ${_products.length}');
    }
  }

  Future<void> refreshProducts() async {
    Logger.info('🔄 ProductViewModel.refreshProducts started');
    Logger.info(
      '🔄 ProductViewModel - Current _products.length: ${_products.length}',
    );
    try {
      // Loading state'leri sıfırla ve temizle
      _isLoading = false;
      _isLoadingMore = false;
      _clearError();
      
      // Sayfa numarasını sıfırla
      _currentPage = 1;
      _hasMore = true;
      
      // Kategorileri yükle (eğer yoksa)
      await loadCategories();
      
      // Ürünleri yeniden yükle
      await loadAllProducts(refresh: true);
      
      Logger.info('✅ ProductViewModel.refreshProducts completed');
      Logger.info('✅ ProductViewModel - Final _products.length: ${_products.length}');
    } catch (e) {
      Logger.error('❌ refreshProducts error: $e');
      _errorMessage = 'Veri yenilenirken hata oluştu: $e';
      notifyListeners();
    }
  }

  Future<void> searchProducts(String query) async {
    Logger.info('🔍 ProductViewModel.searchProducts - Starting search with query: "$query"');
    Logger.info('🔍 ProductViewModel.searchProducts - Current state: page=$_currentPage, hasMore=$_hasMore');
    
    _currentsearchText = query;
    // Sayfa numarasını sıfırla
    _currentPage = 1;
    _hasMore = true;
    Logger.info('🔍 ProductViewModel.searchProducts - Reset pagination: page=1, hasMore=true');
    notifyListeners();

    Logger.info('🔍 ProductViewModel.searchProducts - Calling loadProducts with filters: categoryId=$_currentCategoryId, searchText=$query, city=$_currentCity, condition=$_currentCondition');
    await loadProducts(
      categoryId: _currentCategoryId,
      searchText: query,
      city: _currentCity,
      condition: _currentCondition,
      refresh: true,
    );
    
    Logger.info('✅ ProductViewModel.searchProducts - Search completed, total products: ${_products.length}');
  }

  Future<void> filterByCategory(String? categoryId) async {
    Logger.info('🏷️ ProductViewModel.filterByCategory - Starting filter with categoryId: $categoryId');
    Logger.info('🏷️ ProductViewModel.filterByCategory - Current state: page=$_currentPage, hasMore=$_hasMore');
    
    // Sayfa numarasını sıfırla
    _currentPage = 1;
    _hasMore = true;
    Logger.info('🏷️ ProductViewModel.filterByCategory - Reset pagination: page=1, hasMore=true');
    
    // Yeni filtreleme sistemi kullan
    final newFilter = _currentFilter.copyWith(categoryId: categoryId);
    Logger.info('🏷️ ProductViewModel.filterByCategory - Created new filter: $newFilter');
    Logger.info('🏷️ ProductViewModel.filterByCategory - Previous filter: $_currentFilter');
    
    await applyFilter(newFilter);
    
    Logger.info('✅ ProductViewModel.filterByCategory - Filter applied, total products: ${_products.length}');
  }

  Future<void> sortProducts(SortOption sortOption) async {
    Logger.info('📊 ProductViewModel.sortProducts - Starting sort with option: $sortOption');
    Logger.info('📊 ProductViewModel.sortProducts - Current state: page=$_currentPage, hasMore=$_hasMore');
    Logger.info('📊 ProductViewModel.sortProducts - Previous sort option: $_currentSortOption');
    
    _currentSortOption = sortOption;
    // Sayfa numarasını sıfırla
    _currentPage = 1;
    _hasMore = true;
    Logger.info('📊 ProductViewModel.sortProducts - Reset pagination: page=1, hasMore=true');
    notifyListeners();

    Logger.info('📊 ProductViewModel.sortProducts - Calling loadProducts with filters: categoryId=$_currentCategoryId, searchText=$_currentsearchText, city=$_currentCity, condition=$_currentCondition');
    await loadProducts(
      categoryId: _currentCategoryId,
      searchText: _currentsearchText,
      city: _currentCity,
      condition: _currentCondition,
      refresh: true,
    );
    
    print('✅ ProductViewModel.sortProducts - Sort completed, total products: ${_products.length}');
  }

  Future<void> loadProductById(String productId) async {
    print('🔍 ProductViewModel.loadProductById - Starting to load product: $productId');
    _setLoading(true);
    _clearError();

    try {
      print('📡 ProductViewModel.loadProductById - Making API call for product: $productId');
      final response = await _productService.getProductById(productId);

      print('📡 ProductViewModel.loadProductById - Response received');
      print('📊 Response success: ${response.isSuccess}');
      print('📊 Response error: ${response.error}');
      print('📊 Response data: ${response.data?.title ?? 'null'}');

      if (response.isSuccess && response.data != null) {
        _selectedProduct = response.data;
        print('✅ ProductViewModel.loadProductById - Product loaded successfully: ${response.data!.title}');

        // View count'u artır
        print('👁️ ProductViewModel.loadProductById - Incrementing view count');
        _productService.incrementViewCount(productId);
      } else {
        // 403 hatası kontrolü
        if (response.error != null && 
            (response.error!.contains('403') || 
             response.error!.contains('Erişim reddedildi') ||
             response.error!.contains('Geçersiz kullanıcı token'))) {
          Logger.warning('🚨 403 error detected in ProductViewModel.loadProductById - triggering global error handler');
          ErrorHandlerService.handleForbiddenError(null);
        }
        
        print('❌ ProductViewModel.loadProductById - API error: ${response.error}');
        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      print('💥 ProductViewModel.loadProductById - Exception: $e');
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);
      print('🏁 ProductViewModel.loadProductById - Completed');
    }
  }

  Future<void> loadUserProducts(String userId) async {
    print('🔄 ProductViewModel.loadUserProducts started for user $userId');
    _setLoading(true);
    _clearError();

    try {
      final response = await _productService.getProductsByUserId(userId);
      print('🔍 ProductViewModel - Response isSuccess: ${response.isSuccess}');
      print('🔍 ProductViewModel - Response data: ${response.data}');
      print('🔍 ProductViewModel - Response error: ${response.error}');

      if (response.isSuccess) {
        _myProducts = response.data ?? [];
        print(
          '✅ ProductViewModel - Successfully loaded ${_myProducts.length} user products',
        );
        
        // Yüklenen ürünlerin adres bilgilerini kontrol et
        for (int i = 0; i < _myProducts.length; i++) {
          final product = _myProducts[i];
          print('📍 ProductViewModel - Product $i: ${product.title}');
          print('📍 ProductViewModel - Product $i location: cityTitle="${product.cityTitle}", districtTitle="${product.districtTitle}"');
        }
      } else {
        final errorMessage = response.error ?? ErrorMessages.unknownError;
        _setError(errorMessage);
        print(
          '❌ ProductViewModel - Failed to load user products: $errorMessage',
        );
      }
    } catch (e) {
      final errorMessage = ErrorMessages.unknownError;
      _setError(errorMessage);
      print('💥 ProductViewModel - Exception in loadUserProducts: $e');
    } finally {
      _setLoading(false);
      print('🔄 ProductViewModel.loadUserProducts completed');
    }
  }

  Future<void> loadFavoriteProducts() async {
    // Eğer favoriler zaten yüklüyse ve loading değilse, tekrar yükleme
    if (_favoriteProducts.isNotEmpty && !_isLoadingFavorites) {
      Logger.info('✅ Favoriler zaten yüklü (${_favoriteProducts.length} ürün), tekrar yüklenmiyor', tag: 'ProductViewModel');
      return;
    }
    
    Logger.info('🔄 ProductViewModel.loadFavoriteProducts - Starting to load favorite products', tag: 'ProductViewModel');
    _setLoadingFavorites(true);
    _clearFavoriteError();

    try {
      Logger.info('🌐 ProductViewModel.loadFavoriteProducts - Calling productService.getFavoriteProducts()', tag: 'ProductViewModel');
      final response = await _productService.getFavoriteProducts();
      
      Logger.info('📡 ProductViewModel.loadFavoriteProducts - Response received', tag: 'ProductViewModel');
      Logger.info('📊 Response isSuccess: ${response.isSuccess}, data length: ${response.data?.length ?? 0}', tag: 'ProductViewModel');

      if (response.isSuccess && response.data != null) {
        Logger.info('📦 ProductViewModel.loadFavoriteProducts - Before assignment, current count: ${_favoriteProducts.length}', tag: 'ProductViewModel');
        _favoriteProducts = response.data!;
        Logger.info('✅ ProductViewModel.loadFavoriteProducts - Successfully loaded ${_favoriteProducts.length} favorite products', tag: 'ProductViewModel');
        
        // Favori ürünlerin detaylarını logla
        for (int i = 0; i < _favoriteProducts.length; i++) {
          final product = _favoriteProducts[i];
          Logger.debug('📦 Favorite product $i: ${product.title} (ID: ${product.id})', tag: 'ProductViewModel');
        }
        Logger.info('📦 ProductViewModel.loadFavoriteProducts - After assignment, favorite IDs: ${_favoriteProducts.map((p) => p.id).toList()}', tag: 'ProductViewModel');
      } else {
        final errorMessage = response.error ?? ErrorMessages.unknownError;
        Logger.error('❌ ProductViewModel.loadFavoriteProducts - API error: $errorMessage', tag: 'ProductViewModel');
        _setFavoriteError(errorMessage);
      }
    } catch (e) {
      Logger.error('💥 ProductViewModel.loadFavoriteProducts - Exception: $e', tag: 'ProductViewModel');
      _setFavoriteError(ErrorMessages.unknownError);
    } finally {
      _setLoadingFavorites(false);
      Logger.info('🏁 ProductViewModel.loadFavoriteProducts - Completed', tag: 'ProductViewModel');
    }
  }

  Future<void> loadCategories() async {
    print('🏷️ Loading categories...');
    
    // Eğer kategoriler zaten yüklüyse ve boş değilse, tekrar yükleme
    if (_categories.isNotEmpty) {
      print('🏷️ Categories already loaded: ${_categories.length} items');
      return;
    }
    
    try {
      final response = await _productService.getCategories();
      print(
        '🏷️ Categories response: success=${response.isSuccess}, error=${response.error}',
      );

      if (response.isSuccess && response.data != null) {
        _categories = response.data ?? [];
        print('🏷️ Categories loaded: ${_categories.length} items');
        
        // Kategori detaylarını logla
        print('🏷️ Loaded ${_categories.length} categories:');
        for (int i = 0; i < _categories.length; i++) {
          final category = _categories[i];
          print('  ${i + 1}. ${category.name} (Icon: "${category.icon}")');
          
          // Kategori ikonlarını önceden cache'le
          if (category.icon != null && category.icon!.isNotEmpty) {
            _preloadCategoryIcon(category.icon!);
          }
        }
        
        notifyListeners();
      } else {
        print('🏷️ Categories failed: ${response.error}');
        _setError(response.error ?? 'Kategoriler yüklenemedi');
      }
    } catch (e) {
      print('💥 Categories error: $e');
      _setError('Kategoriler yüklenirken hata oluştu');
    }
  }

  void _preloadCategoryIcon(String iconUrl) {
    // Eğer global cache'de zaten varsa yükleme
    if (CategoryIconCache.hasIcon(iconUrl)) {
      print('✅ Category icon already in global cache: $iconUrl');
      return;
    }
    
    // Arka planda ikonları cache'le
    CacheService().downloadAndCacheIcon(iconUrl).then((downloadedIcon) {
      if (downloadedIcon != null) {
        CategoryIconCache.setIcon(iconUrl, downloadedIcon);
        print('✅ Category icon preloaded to global cache: $iconUrl');
      }
    }).catchError((error) {
      print('⚠️ Failed to preload category icon: $iconUrl, error: $error');
    });
  }

  Future<void> loadSubCategories(String parentCategoryId) async {
    print('🏷️ Loading sub-categories for parent $parentCategoryId...');
    try {
      final response = await _productService.getSubCategories(parentCategoryId);
      print(
        '🏷️ Sub-categories response: success=${response.isSuccess}, error=${response.error}',
      );

      if (response.isSuccess && response.data != null) {
        _subCategories = response.data ?? [];
        _selectedParentCategoryId = parentCategoryId;
        print('🏷️ Sub-categories loaded: ${_subCategories.length} items');
        _subCategories.forEach((cat) => print('  - ${cat.name} (${cat.id})'));
        notifyListeners();
      } else {
        print('🏷️ Sub-categories failed: ${response.error}');
        _subCategories.clear();
        _selectedParentCategoryId = null;
        notifyListeners();
      }
    } catch (e) {
      print('💥 Sub-categories error: $e');
      _subCategories.clear();
      _selectedParentCategoryId = null;
      notifyListeners();
    }
  }

  void clearSubCategories() {
    _subCategories.clear();
    _subSubCategories.clear();
    _subSubSubCategories.clear();
    _selectedParentCategoryId = null;
    _selectedSubCategoryId = null;
    _selectedSubSubCategoryId = null;
    notifyListeners();
  }

  Future<void> loadSubSubCategories(String parentSubCategoryId) async {
    print('🏷️ Loading sub-sub-categories for parent $parentSubCategoryId...');
    try {
      final response = await _productService.getSubSubCategories(parentSubCategoryId);
      print(
        '🏷️ Sub-sub-categories response: success=${response.isSuccess}, error=${response.error}',
      );

      if (response.isSuccess && response.data != null) {
        _subSubCategories = response.data ?? [];
        _selectedSubCategoryId = parentSubCategoryId;
        print('🏷️ Sub-sub-categories loaded: ${_subSubCategories.length} items');
        _subSubCategories.forEach((cat) => print('  - ${cat.name} (${cat.id})'));
        print('🏷️ Notifying listeners after loading sub-sub-categories');
        notifyListeners();
      } else {
        print('🏷️ Sub-sub-categories failed: ${response.error}');
        _subSubCategories.clear();
        _selectedSubCategoryId = null;
        print('🏷️ Notifying listeners after clearing sub-sub-categories');
        notifyListeners();
      }
    } catch (e) {
      print('💥 Sub-sub-categories error: $e');
      _subSubCategories.clear();
      _selectedSubCategoryId = null;
      print('🏷️ Notifying listeners after error in sub-sub-categories');
      notifyListeners();
    }
  }

  void clearSubSubCategories() {
    _subSubCategories.clear();
    _subSubSubCategories.clear();
    _selectedSubCategoryId = null;
    _selectedSubSubCategoryId = null;
    notifyListeners();
  }

  Future<void> loadSubSubSubCategories(String parentSubSubCategoryId) async {
    try {
      final response = await _productService.getSubSubSubCategories(parentSubSubCategoryId);

      if (response.isSuccess && response.data != null) {
        _subSubSubCategories = response.data ?? [];
        _selectedSubSubCategoryId = parentSubSubCategoryId;
        notifyListeners();
      } else {
        _subSubSubCategories.clear();
        _selectedSubSubCategoryId = null;
        notifyListeners();
      }
    } catch (e) {
      _subSubSubCategories.clear();
      _selectedSubSubCategoryId = null;
      notifyListeners();
    }
  }

  void clearSubSubSubCategories() {
    _subSubSubCategories.clear();
    _selectedSubSubCategoryId = null;
    notifyListeners();
  }

  // Kategori ID'sine göre kategori adını bul
  String getCategoryNameById(String categoryId) {
    if (categoryId.isEmpty) return 'Kategori Yok';
    
    print('🔍 getCategoryNameById - Looking for category ID: $categoryId');
    print('🔍 Available categories count: ${_categories.length}');
    
    // Tüm kategorilerin ID'lerini yazdır
    print('🔍 All available category IDs:');
    for (int i = 0; i < _categories.length; i++) {
      final category = _categories[i];
      print('  ${i + 1}. ID: "${category.id}" -> Name: "${category.name}"');
    }
    
    try {
      final category = _categories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => const product_model.Category(id: '', name: 'Kategori Yok', icon: '', isActive: true, order: 0),
      );
      
      print('🔍 Found category: ID="${category.id}", Name="${category.name}"');
      
      if (category.name.isNotEmpty && 
          category.name != 'Kategori Yok' && 
          category.name != 'Kategori' &&
          category.name != 'null') {
        print('✅ Returning valid category name: ${category.name}');
        return category.name;
      } else {
        print('❌ Category name is invalid: "${category.name}"');
      }
    } catch (e) {
      print('❌ Error finding category by ID: $e');
    }
    
    print('❌ No valid category found, returning "Kategori Yok"');
    return 'Kategori Yok';
  }

  // Kategori ID'sine göre kategori nesnesini bul
  product_model.Category? getCategoryById(String categoryId) {
    if (categoryId.isEmpty) return null;
    
    try {
      return _categories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => const product_model.Category(id: '', name: 'Kategori Yok', icon: '', isActive: true, order: 0),
      );
    } catch (e) {
      print('Error finding category by ID: $e');
      return null;
    }
  }

  Future<void> loadCities() async {
    print('🏙️ Loading cities...');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _productService.getCities();
      print(
        '🏙️ Cities response: success=${response.isSuccess}, error=${response.error}',
      );

      if (response.isSuccess && response.data != null) {
        _cities = response.data ?? [];
        print('🏙️ Cities loaded: ${_cities.length} items');

        // Tüm şehirleri logla
        if (_cities.isNotEmpty) {
          print('🏙️ All cities loaded:');
          for (int i = 0; i < _cities.length; i++) {
            final city = _cities[i];
            print(
              '  ${i + 1}. ${city.name} (ID: ${city.id}, Plate: ${city.plateCode})',
            );
          }
        } else {
          print('⚠️ No cities in the response data');
        }

        _isLoading = false;
        notifyListeners();
      } else {
        print('🏙️ Cities failed: ${response.error}');
        print('🏙️ Response data: ${response.data}');
        _isLoading = false;
        _setError(response.error ?? 'İller yüklenemedi');
      }
    } catch (e) {
      print('💥 Cities error: $e');
      _isLoading = false;
      _setError('İller yüklenirken hata oluştu');
    }
  }

  Future<void> loadDistricts(String cityId) async {
    print('🏘️ Loading districts for city $cityId...');
    try {
      final response = await _productService.getDistricts(cityId);
      print(
        '🏘️ Districts response: success=${response.isSuccess}, error=${response.error}',
      );

      if (response.isSuccess && response.data != null) {
        _districts = response.data ?? [];
        print(
          '🏘️ Districts loaded: ${_districts.length} items for city $cityId',
        );

        // Tüm ilçeleri logla
        if (_districts.isNotEmpty) {
          print('🏘️ All districts loaded:');
          for (int i = 0; i < _districts.length; i++) {
            final district = _districts[i];
            print('  ${i + 1}. ${district.name} (ID: ${district.id})');
          }
        } else {
          print('⚠️ No districts in the response data');
        }

        notifyListeners();
      } else {
        print('🏘️ Districts failed: ${response.error}');
        print('🏘️ Response data: ${response.data}');
        _districts = []; // Boş liste ata, hata gösterme
        notifyListeners();
      }
    } catch (e) {
      print('💥 Districts error: $e');
      _districts = []; // Boş liste ata, hata gösterme
      notifyListeners();
    }
  }

  void clearDistricts() {
    _districts = [];
    notifyListeners();
  }

  Future<void> loadConditions() async {
    print('🏷️ Loading conditions...');
    try {
      final response = await _productService.getConditions();
      print(
        '🏷️ Conditions response: success=${response.isSuccess}, error=${response.error}',
      );

      if (response.isSuccess && response.data != null) {
        _conditions = response.data ?? [];
        print('🏷️ Conditions loaded: ${_conditions.length} items');

        // Tüm durumları logla
        if (_conditions.isNotEmpty) {
          print('🏷️ All conditions loaded:');
          for (int i = 0; i < _conditions.length; i++) {
            final condition = _conditions[i];
            print('  ${i + 1}. ${condition.name} (ID: ${condition.id})');
          }
        } else {
          print('⚠️ No conditions in the response data');
        }

        notifyListeners();
      } else {
        print('🏷️ Conditions failed: ${response.error}');
        print('🏷️ Response data: ${response.data}');
        _setError(response.error ?? 'Ürün durumları yüklenemedi');
      }
    } catch (e) {
      print('💥 Conditions error: $e');
      _setError('Ürün durumları yüklenirken hata oluştu');
    }
  }

  Future<bool> createProduct({
    required String title,
    required String description,
    required List<String> images,
    required String categoryId,
    required String condition,
    String? brand,
    String? model,
    double? estimatedValue,
    required List<String> tradePreferences,
    String? cityId,
    String? cityTitle,
    String? districtId,
    String? districtTitle,
  }) async {
    print('🚀 ProductViewModel.createProduct - Starting product creation');
    print('📝 Product details: title="$title", categoryId=$categoryId, condition=$condition');
    print('📸 Images count: ${images.length}');
    print('🏷️ Trade preferences: $tradePreferences');
    print('📍 Location: cityId=$cityId, districtId=$districtId');
    
    if (title.trim().isEmpty || description.trim().isEmpty) {
      print('❌ ProductViewModel.createProduct - Validation failed: title or description is empty');
      _setError(ErrorMessages.fieldRequired);
      return false;
    }

    if (images.isEmpty) {
      print('❌ ProductViewModel.createProduct - Validation failed: no images provided');
      _setError('En az bir resim eklemelisiniz');
      return false;
    }

    if (tradePreferences.isEmpty) {
      print('❌ ProductViewModel.createProduct - Validation failed: no trade preferences');
      _setError('Takas tercihlerinizi belirtmelisiniz');
      return false;
    }

    print('✅ ProductViewModel.createProduct - Validation passed, starting API call');
    _setLoading(true);
    _clearError();

    try {
      print('📡 ProductViewModel.createProduct - Making API call to create product');
      final response = await _productService.createProduct(
        title: title,
        description: description,
        images: images,
        categoryId: categoryId,
        condition: condition,
        brand: brand,
        model: model,
        estimatedValue: estimatedValue,
        tradePreferences: tradePreferences,
        cityId: cityId,
        cityTitle: cityTitle,
        districtId: districtId,
        districtTitle: districtTitle,
      );

      print('📡 ProductViewModel.createProduct - Response received');
      print('📊 Response success: ${response.isSuccess}');
      print('📊 Response error: ${response.error}');
      print('📊 Response data: ${response.data?.title ?? 'null'}');

      if (response.isSuccess && response.data != null) {
        _myProducts.insert(0, response.data!);
        print('✅ ProductViewModel.createProduct - Product created successfully: ${response.data!.title}');
        print('✅ ProductViewModel.createProduct - Added to myProducts list, total count: ${_myProducts.length}');
        _setLoading(false);
        return true;
      } else {
        print('❌ ProductViewModel.createProduct - API error: ${response.error}');
        _setError(response.error ?? ErrorMessages.unknownError);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('💥 ProductViewModel.createProduct - Exception: $e');
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return false;
    }
  }

  Future<Map<String, dynamic>> toggleFavorite(String productId) async {
    print('🔄 ProductViewModel.toggleFavorite - Starting toggle for product: $productId');
    try {
      // Kullanıcının kendi ürünü olup olmadığını kontrol et
      final isOwnProduct = _myProducts.any((p) => p.id == productId);
      if (isOwnProduct) {
        print('❌ ProductViewModel.toggleFavorite - User cannot favorite their own product: $productId');
        return {
          'success': false,
          'wasFavorite': false,
          'message': 'Kendi ürününüzü favoriye ekleyemezsiniz',
        };
      }
      
      print('🔄 ProductViewModel.toggleFavorite - Toggling favorite for product: $productId');
      final isFavorite = _favoriteProducts.any((p) => p.id == productId);
      print('🔍 ProductViewModel.toggleFavorite - Is currently favorite: $isFavorite');
      print('🔍 ProductViewModel.toggleFavorite - Current favorite products count: ${_favoriteProducts.length}');
      print('🔍 ProductViewModel.toggleFavorite - Current favorite product IDs: ${_favoriteProducts.map((p) => p.id).toList()}');

      if (isFavorite) {
        // Favorilerden çıkar
        print('🗑️ ProductViewModel.toggleFavorite - Removing from favorites');
        print('🗑️ ProductViewModel.toggleFavorite - Product ID: $productId');
        print('🗑️ ProductViewModel.toggleFavorite - Calling removeFromFavorites API...');
        final response = await _productService.removeFromFavorites(productId);
        print('📡 ProductViewModel.toggleFavorite - Remove response isSuccess: ${response.isSuccess}');
        print('📡 ProductViewModel.toggleFavorite - Remove response error: ${response.error}');
        print('📡 ProductViewModel.toggleFavorite - Before removal, favorite count: ${_favoriteProducts.length}');
        print('📡 ProductViewModel.toggleFavorite - Before removal, favorite IDs: ${_favoriteProducts.map((p) => p.id).toList()}');
        
        if (response.isSuccess) {
          print('✅ ProductViewModel.toggleFavorite - API call successful, removing from local list');
          _favoriteProducts.removeWhere((p) => p.id == productId);
          print('✅ ProductViewModel.toggleFavorite - Successfully removed from local favorites list');
          print('✅ ProductViewModel.toggleFavorite - Current favorite products count: ${_favoriteProducts.length}');
          print('✅ ProductViewModel.toggleFavorite - Current favorite product IDs: ${_favoriteProducts.map((p) => p.id).toList()}');
          notifyListeners();
          return {
            'success': true,
            'wasFavorite': true,
            'message': 'Ürün favorilerden çıkarıldı',
          };
        } else {
          print('❌ ProductViewModel.toggleFavorite - Failed to remove from favorites: ${response.error}');
          // API başarısız olsa bile local list'ten çıkar (kullanıcı deneyimi için)
          print('⚠️ ProductViewModel.toggleFavorite - Removing from local list despite API failure');
          _favoriteProducts.removeWhere((p) => p.id == productId);
          notifyListeners();
          return {
            'success': false,
            'wasFavorite': true,
            'message': response.error ?? 'Ürün favorilerden çıkarılamadı',
          };
        }
      } else {
        // Favorilere ekle
        print('❤️ ProductViewModel.toggleFavorite - Adding to favorites');
        final response = await _productService.addToFavorites(productId);
        if (response.isSuccess) {
          // Favorilere eklenen ürünü bulup listeye ekle
          product_model.Product? productToAdd;
          
          // Önce _products listesinde ara
          try {
            productToAdd = _products.firstWhere((p) => p.id == productId);
            print('✅ ProductViewModel.toggleFavorite - Found product in _products list');
          } catch (e) {
            print('⚠️ ProductViewModel.toggleFavorite - Product not found in _products, trying _myProducts');
            // _products'da bulunamazsa _myProducts'da ara
            try {
              productToAdd = _myProducts.firstWhere((p) => p.id == productId);
              print('✅ ProductViewModel.toggleFavorite - Found product in _myProducts list');
            } catch (e) {
              print('❌ ProductViewModel.toggleFavorite - Product not found in any list, will reload favorites');
              // Hiçbir listede bulunamazsa favorileri yeniden yükle
              await loadFavoriteProducts();
              notifyListeners();
              return {
                'success': true,
                'wasFavorite': false,
                'message': 'Ürün favorilere eklendi',
              };
            }
          }
          
          if (productToAdd != null) {
            _favoriteProducts.add(productToAdd);
            print('✅ ProductViewModel.toggleFavorite - Successfully added to favorites');
            notifyListeners();
            return {
              'success': true,
              'wasFavorite': false,
              'message': 'Ürün favorilere eklendi',
            };
          }
        } else {
          print('❌ ProductViewModel.toggleFavorite - Failed to add to favorites: ${response.error}');
          return {
            'success': false,
            'wasFavorite': false,
            'message': response.error ?? 'Ürün favorilere eklenemedi',
          };
        }
      }
      return {
        'success': false,
        'wasFavorite': isFavorite,
        'message': 'İşlem başarısız',
      };
    } catch (e) {
      print('💥 ProductViewModel.toggleFavorite - Exception: $e');
      return {
        'success': false,
        'wasFavorite': _favoriteProducts.any((p) => p.id == productId),
        'message': 'Bir hata oluştu',
      };
    }
  }

  bool isFavorite(String productId) {
    return _favoriteProducts.any((p) => p.id == productId);
  }

  void clearSelectedProduct() {
    _selectedProduct = null;
    notifyListeners();
  }

  /// Kullanıcı değişikliği durumunda tüm ürün listelerini temizler
  void clearAllProductData() {
    print('🧹 ProductViewModel.clearAllProductData - Clearing all product data');
    _products.clear();
    _myProducts.clear();
    _favoriteProducts.clear();
    _selectedProduct = null;
    _currentPage = 1;
    _hasMore = true;
    _currentFilter = const ProductFilter();
    _currentCategoryId = null;
    _currentsearchText = null;
    _currentCity = null;
    _currentCondition = null;
    _clearError();
    notifyListeners();
    print('✅ ProductViewModel.clearAllProductData - All product data cleared');
  }

  void clearError() {
    _clearError();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setLoadingMore(bool loading) {
    _isLoadingMore = loading;
    notifyListeners();
  }

  void _setLoadingFavorites(bool loading) {
    _isLoadingFavorites = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _setFavoriteError(String error) {
    _favoriteErrorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _clearFavoriteError() {
    _favoriteErrorMessage = null;
    notifyListeners();
  }

  Future<bool> addProduct({
    required String userToken,
    required String userId,
    required String productTitle,
    required String productDescription,
    required String categoryId,
    required String conditionId,
    required String tradeFor,
    required List<File> productImages,
  }) async {
    print('🚀 ProductViewModel.addProduct - Starting product addition');
    print('📝 Product details: title="$productTitle", categoryId=$categoryId, conditionId=$conditionId');
    print('👤 User: userId=$userId, token=${userToken.substring(0, 20)}...');
    print('📸 Images count: ${productImages.length}');
    print('🔄 Trade for: $tradeFor');
    
    if (productTitle.trim().isEmpty) {
      print('❌ ProductViewModel.addProduct - Validation failed: product title is empty');
      _setError('Ürün başlığı boş olamaz');
      return false;
    }

    if (productDescription.trim().isEmpty) {
      print('❌ ProductViewModel.addProduct - Validation failed: product description is empty');
      _setError('Ürün açıklaması boş olamaz');
      return false;
    }

    if (productImages.isEmpty) {
      print('❌ ProductViewModel.addProduct - Validation failed: no product images');
      _setError('En az bir ürün resmi seçmelisiniz');
      return false;
    }

    print('✅ ProductViewModel.addProduct - Validation passed, starting API call');
    _setLoading(true);
    _clearError();

    try {
      print('📡 ProductViewModel.addProduct - Making API call to add product');
      final response = await _productService.addProduct(
        userToken: userToken,
        userId: userId,
        productTitle: productTitle,
        productDescription: productDescription,
        categoryId: categoryId,
        conditionId: conditionId,
        tradeFor: tradeFor,
        productImages: productImages,
      );

      print('📡 ProductViewModel.addProduct - Response received');
      print('📊 Response success: ${response.isSuccess}');
      print('📊 Response error: ${response.error}');
      print('📊 Response data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        final responseData = response.data!;
        final productId = responseData['productID']?.toString() ?? 'unknown';
        final message = responseData['message']?.toString() ?? 'İlan eklendi';

        print('✅ ProductViewModel.addProduct - Product added successfully!');
        print('🆔 Product ID: $productId');
        print('💬 Message: $message');

        // Başarılı olduktan sonra ürün listesini yenile
        print('🔄 ProductViewModel.addProduct - Refreshing products...');
        await refreshProducts();
        return true;
      } else {
        print('❌ ProductViewModel.addProduct - API error: ${response.error}');
        _setError(response.error ?? 'İlan eklenemedi');
        return false;
      }
    } catch (e) {
      print('💥 ProductViewModel.addProduct - Exception: $e');
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return false;
    }
  }

  // Ürün silme metodu
  Future<bool> deleteUserProduct(String productId) async {
    print(
      '🗑️ ProductViewModel.deleteUserProduct called with productId: $productId',
    );

    _setLoading(true);
    _clearError();

    try {
      // Current user'ı al
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        print('❌ Current user bulunamadı');
        _setError('Kullanıcı oturumu bulunamadı');
        _setLoading(false);
        return false;
      }
      print('✅ Current user: ${currentUser.id} - ${currentUser.name}');

      // User token'ı al ve detaylı kontrol et
      final userToken = await _authService.getToken();
      if (userToken == null || userToken.isEmpty) {
        print('❌ User token bulunamadı veya boş');
        _setError('Kullanıcı token\'ı bulunamadı');
        _setLoading(false);
        return false;
      }

      print('✅ User token alındı: ${userToken.substring(0, 20)}...');
      print('✅ User token length: ${userToken.length}');

      // Token geçerliliğini kontrol et - zaten currentUser var, tekrar almaya gerek yok
      print('✅ Current user verified: ${currentUser.id} - ${currentUser.name}');

      // API'de ownership kontrolü yapılacağı için client-side kontrol kaldırıldı
      print('🗑️ Deleting product: $productId');
      final response = await _productService.deleteUserProduct(
        userToken: userToken,
        productId: productId,
      );

      print('📡 Delete response alındı');
      print('📊 Response success: ${response.isSuccess}');
      print('📊 Response error: ${response.error}');
      print('📊 Response data: ${response.data}');

      if (response.isSuccess) {
        print('✅ Product delete API call successful');

        print('✅ Product delete API call successful');

        // Optimistic UI update: remove the product from both local lists immediately
        final originalProductIndex = _myProducts.indexWhere((p) => p.id == productId);
        final originalAllProductsIndex = _products.indexWhere((p) => p.id == productId);
        product_model.Product? removedProduct;
        product_model.Product? removedAllProduct;
        
        if (originalProductIndex != -1) {
          removedProduct = _myProducts.removeAt(originalProductIndex);
        }
        
        if (originalAllProductsIndex != -1) {
          removedAllProduct = _products.removeAt(originalAllProductsIndex);
        }
        
        notifyListeners(); // UI'ı hemen güncelle

        // Verification with retry logic
        bool isVerified = await _verifyDeletion(productId);

        if (isVerified) {
          print('✅ VERIFIED: Product successfully deleted from API');
          
          // Ana sayfa ürün listesini de yenile
          print('🔄 Refreshing all products after deletion...');
          await refreshProducts();
          
        } else {
          print('❌ CRITICAL: Product still exists in API after deletion!');
          // Rollback: add the product back to both lists if verification fails
          if (removedProduct != null && originalProductIndex != -1) {
            _myProducts.insert(originalProductIndex, removedProduct);
          }
          if (removedAllProduct != null && originalAllProductsIndex != -1) {
            _products.insert(originalAllProductsIndex, removedAllProduct);
          }
          notifyListeners(); // UI'ı eski haline getir
          _setError('Ürün silinemedi. Lütfen tekrar deneyin.');
          _setLoading(false);
          return false;
        }

        _setLoading(false);
        return true;
      } else {
        print('❌ Product delete failed: ${response.error}');
        _setError(response.error ?? 'Ürün silinemedi');
        _setLoading(false);
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Product delete exception: $e');
      print('❌ Stack trace: $stackTrace');
      _setError('Ürün silinirken hata oluştu: $e');
      _setLoading(false);
      return false;
    }
  }

  // Ürün güncelleme metodu
  Future<bool> updateProduct({
    required String productId,
    String? title,
    String? description,
    List<String>? images,
    String? categoryId,
    String? conditionId,
    List<String>? tradePreferences,
    String? cityId,
    String? cityTitle,
    String? districtId,
    String? districtTitle,
    String? productLat,
    String? productLong,
    bool? isShowContact,
  }) async {
    print('🔄 ProductViewModel.updateProduct called');
    print('📝 Parameters:');
    print('  - productId: $productId');
    print('  - title: $title');
    print('  - description: $description');
    print('  - images count: ${images?.length ?? 0}');
    print('  - categoryId: $categoryId');
    print('  - conditionId: $conditionId');

    print('  - tradePreferences: $tradePreferences');
    print('  - cityId: $cityId');
    print('  - cityTitle: $cityTitle');
    print('  - districtId: $districtId');
    print('  - districtTitle: $districtTitle');
    print('  - isShowContact: $isShowContact');

    _setLoading(true);
    _clearError();

    try {
      // Current user'ı al
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        print('❌ Current user not found!');
        _setError('Kullanıcı bilgileri bulunamadı');
        _setLoading(false);
        return false;
      }

      // Token'ı AuthService'den al
      final userToken = await _authService.getToken();
      if (userToken?.isEmpty ?? true) {
        print('❌ User token is empty!');
        _setError('Kullanıcı token\'ı bulunamadı. Lütfen tekrar giriş yapın.');
        _setLoading(false);
        return false;
      }

      print('👤 Current user: ${currentUser.email}');
      print('🔑 User token: ${userToken?.substring(0, 20)}...');

      // Null check for userToken
      if (userToken == null) {
        print('❌ User token is null');
        _setError('Kullanıcı token\'ı bulunamadı. Lütfen tekrar giriş yapın.');
        _setLoading(false);
        return false;
      }

      // Token geçerliliğini kontrol et (basit kontrol)
      if (userToken.length < 20) {
        print('❌ User token is too short, likely invalid!');
        _setError('Kullanıcı token\'ı geçersiz. Lütfen tekrar giriş yapın.');
        _setLoading(false);
        return false;
      }

      // ProductService.updateProduct metodunu çağır
      final response = await _productService.updateProduct(
        productId,
        userToken: userToken,
        title: title,
        description: description,
        images: images,
        categoryId: categoryId,
        conditionId: conditionId,
        tradePreferences: tradePreferences,
        cityId: cityId,
        cityTitle: cityTitle,
        districtId: districtId,
        districtTitle: districtTitle,
        productLat: productLat,
        productLong: productLong,
        isShowContact: isShowContact,
      );

      print('📡 Update response alındı');
      print('📊 Response success: ${response.isSuccess}');
      print('📊 Response error: ${response.error}');
      print('📊 Response data: ${response.data}');

      if (response.isSuccess) {
        // API'den gelen yanıt kontrolü
        if (response.data != null) {
          final updatedProduct = response.data!;
          print('✅ Product updated successfully with data!');
          print('🆔 Updated Product ID: ${updatedProduct.id}');
          print('📝 Updated Product Title: ${updatedProduct.title}');

          // API'den dönen ürün verisi eksikse (sadece ID varsa), güncel veriyi çek
          if (updatedProduct.title.isEmpty || updatedProduct.description.isEmpty) {
            print('🔄 API returned incomplete product data, fetching full details...');
            await _loadUpdatedProduct(productId);
          } else {
            // Güncellenmiş ürünü listelerde güncelle
            _updateProductInLists(updatedProduct);

            // Seçili ürünü güncelle
            if (_selectedProduct?.id == productId) {
              _selectedProduct = updatedProduct;
            }
          }
        } else {
          print('✅ Product updated successfully (no data returned from API)');
          // API'den ürün verisi dönmediğinde, sadece o ürünü yeniden yükle
          print('🔄 Loading updated product data...');
          await _loadUpdatedProduct(productId);
        }

        _setLoading(false);
        return true;
      } else {
        print('❌ Product update failed: ${response.error}');
        
        // Token hatası kontrolü
        if (response.error != null && 
            (response.error!.contains('Geçersiz kullanıcı token') ||
             response.error!.contains('Üye doğrulama bilgileri hatalı') ||
             response.error!.contains('403') ||
             response.error!.contains('Forbidden'))) {
          print('🔐 Token error detected, redirecting to login...');
          _setError('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.');
          
          // Kullanıcıyı logout yap
          await _authService.logout();
          
          _setLoading(false);
          return false;
        }
        
        _setError(response.error ?? 'Ürün güncellenemedi');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('❌ ProductViewModel.updateProduct - Exception: $e');
      _setError('Ürün güncellenirken hata oluştu: $e');
      _setLoading(false);
      return false;
    }
  }

  // Güncellenmiş ürünü yeniden yükle
  Future<void> _loadUpdatedProduct(String productId) async {
    print('🔄 _loadUpdatedProduct - Loading updated product: $productId');
    try {
      // Önce getProductById ile dene
      var response = await _productService.getProductById(productId);
      
      // Eğer getProductById başarısız olursa, getProductDetail ile dene
      if (!response.isSuccess || response.data == null) {
        print('🔄 getProductById failed, trying getProductDetail...');
        
        // User token'ı al
        final userToken = await _authService.getToken();
        if (userToken != null && userToken.isNotEmpty) {
          response = await _productService.getProductDetail(
            userToken: userToken,
            productId: productId,
          );
        }
      }
      
      if (response.isSuccess && response.data != null) {
        final updatedProduct = response.data!;
        print('✅ _loadUpdatedProduct - Product loaded successfully');
        print('📝 Loaded product title: ${updatedProduct.title}');
        print('📝 Loaded product description: ${updatedProduct.description}');
        _updateProductInLists(updatedProduct);
        
        // Seçili ürünü de güncelle
        if (_selectedProduct?.id == productId) {
          _selectedProduct = updatedProduct;
        }
      } else {
        print('❌ _loadUpdatedProduct - Failed to load updated product: ${response.error}');
        // Eğer ürün yüklenemezse, tüm listeyi yenile
        await refreshProducts();
      }
    } catch (e) {
      print('❌ _loadUpdatedProduct - Exception: $e');
      // Hata durumunda tüm listeyi yenile
      await refreshProducts();
    }
  }

  // Güncellenmiş ürünü listelerde güncelle
  void _updateProductInLists(product_model.Product updatedProduct) {
    // Ana ürün listesinde güncelle
    final productIndex = _products.indexWhere((p) => p.id == updatedProduct.id);
    if (productIndex != -1) {
      _products[productIndex] = updatedProduct;
      print('✅ Updated product in main products list at index $productIndex');
    }

    // Kullanıcının ürünleri listesinde güncelle
    final myProductIndex = _myProducts.indexWhere((p) => p.id == updatedProduct.id);
    if (myProductIndex != -1) {
      _myProducts[myProductIndex] = updatedProduct;
      print('✅ Updated product in my products list at index $myProductIndex');
    }

    // Favori ürünler listesinde güncelle
    final favoriteIndex = _favoriteProducts.indexWhere((p) => p.id == updatedProduct.id);
    if (favoriteIndex != -1) {
      _favoriteProducts[favoriteIndex] = updatedProduct;
      print('✅ Updated product in favorite products list at index $favoriteIndex');
    }

    notifyListeners();
  }

  // Yeni addProductWithEndpoint method'u kullanıcının verdiği endpoint için
  Future<bool> addProductWithEndpoint({
    required String productTitle,
    required String productDescription,
    required String categoryId,
    required String conditionId,
    required String tradeFor,
    required List<File> productImages,
    String? selectedCityId,
    String? selectedDistrictId,
    bool? isShowContact,
  }) async {
    print('🚀 addProductWithEndpoint başlatıldı');
    print('📝 Parametreler:');
    print('  - productTitle: $productTitle');
    print('  - productDescription: $productDescription');
    print('  - categoryId: $categoryId');
    print('  - conditionId: $conditionId');
    print('  - tradeFor: $tradeFor');
    print('  - productImages count: ${productImages.length}');
    print('  - selectedCityId: $selectedCityId');
    print('  - selectedDistrictId: $selectedDistrictId');
    print('  - isShowContact: $isShowContact');

    // Validasyonlar
    if (productTitle.trim().isEmpty || productDescription.trim().isEmpty) {
      print('❌ Validation failed: Başlık ve açıklama zorunludur');
      _setError('Başlık ve açıklama zorunludur');
      return false;
    }

    if (tradeFor.trim().isEmpty) {
      print('❌ Validation failed: Takas tercihi belirtmelisiniz');
      _setError('Takas tercihi belirtmelisiniz');
      return false;
    }

    // Resim validasyonu - en az bir resim gerekli
    if (productImages.isEmpty) {
      print('❌ Validation failed: En az bir resim gerekli');
      _setError('En az bir fotoğraf eklemelisiniz');
      return false;
    }

    // Resim durumu kontrolü
    print('📸 ${productImages.length} resim yüklenecek:');
    for (int i = 0; i < productImages.length; i++) {
      print('  ${i + 1}. ${productImages[i].path.split('/').last}');
    }

    print('🔄 Loading state ayarlanıyor...');
    _setLoading(true);
    _clearError();

    try {
      print('👤 Current user alınıyor...');
      // Current user'ı al
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        print('❌ Current user bulunamadı');
        _setError('Kullanıcı oturumu bulunamadı');
        return false;
      }
      print('✅ Current user: ${currentUser.id} - ${currentUser.name}');

      print('🔑 User token alınıyor...');
      // User token'ı al (stored token)
      final userToken = await _authService.getToken();
      if (userToken == null) {
        print('❌ User token bulunamadı');
        _setError('Kullanıcı token\'ı bulunamadı');
        return false;
      }
      print('✅ User token alındı: ${userToken.substring(0, 20)}...');

      print('🛍️ Adding product for user: ${currentUser.id}');
      print('📝 Product title: $productTitle');
      print('📂 Category ID: $categoryId');
      print('🔄 Trade for: $tradeFor');

      print('📡 API çağrısı yapılıyor...');
      final response = await _productService.addProduct(
        userToken: userToken,
        userId: currentUser.id,
        productTitle: productTitle,
        productDescription: productDescription,
        categoryId: categoryId,
        conditionId: conditionId,
        tradeFor: tradeFor,
        productImages: productImages,
        selectedCityId: selectedCityId,
        selectedDistrictId: selectedDistrictId,
        isShowContact: isShowContact,
      );

      print('📡 API response alındı');
      print('📊 Response success: ${response.isSuccess}');
      print('📊 Response error: ${response.error}');
      print('📊 Response data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        final responseData = response.data!;
        final productId = responseData['productID']?.toString() ?? 'unknown';
        final message = responseData['message']?.toString() ?? 'İlan eklendi';

        print('✅ Product added successfully!');
        print('🆔 Product ID: $productId');
        print('💬 Message: $message');

        // Başarılı olduktan sonra ürün listesini yenile
        print('🔄 Refreshing products...');
        await refreshProducts();
        return true;
      } else {
        print('❌ Product add failed: ${response.error}');
        _setError(response.error ?? 'İlan eklenemedi');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Product add exception: $e');
      print('❌ Stack trace: $stackTrace');
      _setError('İlan eklenirken hata oluştu: $e');
      return false;
    } finally {
      print('🏁 Loading state false yapılıyor...');
      _setLoading(false);
      print('🏁 addProductWithEndpoint tamamlandı');
    }
  }

  // Yeni filtreleme metodları
  Future<void> applyFilter(ProductFilter filter) async {
    Logger.info('🔍 ProductViewModel.applyFilter - New filter: $filter');
    _currentFilter = filter;
    _currentPage = 1;
    _hasMore = true;
    _products.clear();

    _setLoading(true);
    _clearError();

    try {
      final response = await _productService.getAllProductsWithFilter(
        filter: filter,
        page: 1,
        limit: AppConstants.defaultPageSize,
      );

      Logger.info('📡 ProductViewModel.applyFilter - response received');
      Logger.info('📊 Response success: ${response.isSuccess}');
      Logger.info('📊 Response data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        final paginatedData = response.data!;
        final newProducts = paginatedData.products;
        Logger.info(
          '✅ ProductViewModel.applyFilter - got ${newProducts.length} products',
        );
        Logger.info(
          '✅ ProductViewModel.applyFilter - pagination: page=${paginatedData.currentPage}, totalPages=${paginatedData.totalPages}, totalItems=${paginatedData.totalItems}, hasMore=${paginatedData.hasMore}',
        );

        _products = newProducts;
        _hasMore = paginatedData.hasMore;
        _currentPage = paginatedData.currentPage + 1; // Bir sonraki sayfa

        Logger.info('✅ ProductViewModel.applyFilter - hasMore: $_hasMore (${paginatedData.currentPage} < ${paginatedData.totalPages})');
      } else {
        Logger.error('❌ ProductViewModel.applyFilter - API error: ${response.error}');
        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      Logger.error('💥 ProductViewModel.applyFilter - Exception: $e');
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);
      Logger.info(
        '🏁 ProductViewModel.applyFilter completed - final products count: ${_products.length}',
      );
      notifyListeners();
    }
  }

  Future<void> clearFilters() async {
    Logger.info('🧹 ProductViewModel.clearFilters - Starting to clear all filters');
    Logger.info('🧹 ProductViewModel.clearFilters - Before: _currentFilter = $_currentFilter');
    Logger.info('🧹 ProductViewModel.clearFilters - Current state: page=$_currentPage, hasMore=$_hasMore, productsCount=${_products.length}');
    
    // Tüm filtreleri sıfırla
    _currentFilter = const ProductFilter();
    _currentPage = 1;
    _hasMore = true;
    _products.clear();
    
    // Eski arama parametrelerini de temizle
    _currentCategoryId = null;
    _currentsearchText = null;
    _currentCity = null;
    _currentCondition = null;
    
    Logger.info('🧹 ProductViewModel.clearFilters - After: _currentFilter = $_currentFilter');
    Logger.info('🧹 ProductViewModel.clearFilters - Reset pagination: page=1, hasMore=true');
    Logger.info('🧹 ProductViewModel.clearFilters - Cleared all filter parameters');
    Logger.info('🧹 ProductViewModel.clearFilters - Loading all products...');
    
    await loadAllProducts(refresh: true);
    
    Logger.info('✅ ProductViewModel.clearFilters - Completed, products count: ${_products.length}');
  }



  Future<bool> _verifyDeletion(String productId, {int retries = 3, Duration delay = const Duration(seconds: 1)}) async {
    print('🔍 ProductViewModel._verifyDeletion - Starting verification for product: $productId');
    print('🔍 ProductViewModel._verifyDeletion - Retries: $retries, delay: $delay');
    
    for (int i = 0; i < retries; i++) {
      print('🔍 ProductViewModel._verifyDeletion - Verification attempt #${i + 1} for product $productId...');
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        print('❌ ProductViewModel._verifyDeletion - Current user is null, verification failed');
        return false; // Should not happen
      }

      print('👤 ProductViewModel._verifyDeletion - Current user: ${currentUser.id}');
      await loadUserProducts(currentUser.id);
      final productStillExists = _myProducts.any((p) => p.id == productId);

      if (!productStillExists) {
        print('✅ ProductViewModel._verifyDeletion - Product $productId successfully deleted, verification passed');
        return true; // Verified!
      }

      print('⚠️ ProductViewModel._verifyDeletion - Product $productId still exists in myProducts list');
      print('⚠️ ProductViewModel._verifyDeletion - Waiting for ${delay * (i + 1)} before next attempt...');
      await Future.delayed(delay * (i + 1)); // Increasing delay
    }
    
    print('❌ ProductViewModel._verifyDeletion - Verification failed after $retries attempts');
    return false; // Failed after all retries
  }

  /// Ürün detayını getirir (detay sayfası için)
  Future<product_model.Product?> getProductDetail(String productId) async {
    print('🔍 ProductViewModel.getProductDetail - Starting to get product detail: $productId');
    _setLoading(true);
    _clearError();
    try {
      print('🔑 ProductViewModel.getProductDetail - Getting user token');
      final userToken = await _authService.getToken();
      if (userToken == null || userToken.isEmpty) {
        print('❌ ProductViewModel.getProductDetail - User token is null or empty');
        _setError('Kullanıcı oturumu bulunamadı');
        _setLoading(false);
        return null;
      }
      print('✅ ProductViewModel.getProductDetail - User token obtained: ${userToken.substring(0, 20)}...');
      
      print('📡 ProductViewModel.getProductDetail - Making API call for product detail');
      final response = await _productService.getProductDetail(
        userToken: userToken,
        productId: productId,
      );
      
      print('📡 ProductViewModel.getProductDetail - Response received');
      print('📊 Response success: ${response.isSuccess}');
      print('📊 Response error: ${response.error}');
      print('📊 Response data: ${response.data?.title ?? 'null'}');
      
      if (response.isSuccess && response.data != null) {
        _selectedProduct = response.data;
        print('✅ ProductViewModel.getProductDetail - Product detail loaded successfully: ${response.data!.title}');
        _setLoading(false);
        return response.data;
      } else {
        print('❌ ProductViewModel.getProductDetail - API error: ${response.error}');
        _setError(response.error ?? 'Ürün detayı alınamadı');
        _setLoading(false);
        return null;
      }
    } catch (e) {
      print('💥 ProductViewModel.getProductDetail - Exception: $e');
      _setError('Ürün detayı alınamadı: $e');
      _setLoading(false);
      return null;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
