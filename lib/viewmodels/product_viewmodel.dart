import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/product.dart' as product_model;
import '../models/city.dart';
import '../models/district.dart';
import '../models/condition.dart';
import '../models/product_filter.dart';
import '../models/popular_category.dart';
import '../services/product_service.dart';
import '../models/live_search.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/cache_service.dart';
import '../core/constants.dart';
import '../core/sort_options.dart';
import '../core/http_client.dart'; // ApiResponse için
import '../views/home/widgets/category_list.dart'; // CategoryIconCache için
import '../services/error_handler_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/location_service.dart';
import '../utils/logger.dart';

class ProductViewModel extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final CacheService _cacheService = CacheService();
  // Canlı arama state'i
  List<LiveSearchItem> _liveResults = [];
  bool _isLiveSearching = false;
  String _liveQuery = '';
  List<SearchHistoryItem> _searchHistory = [];
  // Local cache, backend boş dönerse kullanmak için
  static const int _maxLocalHistory = 10;

  List<product_model.Product> _products = [];
  List<product_model.Product> _favoriteProducts = [];
  List<product_model.Product> _myProducts = [];
  List<product_model.Category> _categories = [];
  List<product_model.Category> _subCategories = [];
  List<product_model.Category> _subSubCategories = [];
  List<product_model.Category> _subSubSubCategories = [];
  List<PopularCategory> _popularCategories = [];
  String? _selectedParentCategoryId;
  String? _selectedSubCategoryId;
  String? _selectedSubSubCategoryId;
  List<City> _cities = [];
  List<District> _districts = [];
  String? _lastDistrictsRequestedCityId;
  List<Condition> _conditions = [];
  product_model.Product? _selectedProduct;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingFavorites = false;
  bool _hasMore = true;
  String? _errorMessage;
  String? _favoriteErrorMessage;
  String? _lastAddedProductId; // Son eklenen ürünün ID'si

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
  List<LiveSearchItem> get liveResults => _liveResults;
  bool get isLiveSearching => _isLiveSearching;
  String get liveQuery => _liveQuery;
  List<SearchHistoryItem> get searchHistory => _searchHistory;
  List<product_model.Product> get favoriteProducts => _favoriteProducts;
  List<product_model.Product> get myProducts => _myProducts;
  List<product_model.Product> get userProducts => _myProducts;
  List<product_model.Category> get categories => _categories;
  List<product_model.Category> get subCategories => _subCategories;
  List<product_model.Category> get subSubCategories => _subSubCategories;
  List<product_model.Category> get subSubSubCategories => _subSubSubCategories;
  List<PopularCategory> get popularCategories => _popularCategories;
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
  String? get lastAddedProductId => _lastAddedProductId;

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
    await Future.wait([loadCategories(), loadConditions()]);

    // İlk girişte konum bazlı filtreleme yap

    try {
      // Konum servislerini kontrol et
      final locationService = LocationService();
      final hasPermission = await locationService.checkLocationPermission();

      if (hasPermission) {
        final isLocationEnabled = await locationService
            .isLocationServiceEnabled();
        if (isLocationEnabled) {
          // Konum bazlı filtreleme ile ürünleri yükle
          final locationFilter = _currentFilter.copyWith(sortType: 'location');
          await applyFilter(locationFilter);
        } else {
          await loadAllProducts();
        }
      } else {
        await loadAllProducts();
      }
    } catch (e) {
      // Hata durumunda varsayılan yükleme yap
      await loadAllProducts();
    }
  }

  Future<void> loadAllProducts({
    int page = 1,
    int limit = AppConstants.defaultPageSize,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _products.clear();
    } else {
      // Refresh değilse ve ilk sayfa ise sayfa numarasını 1'e ayarla
      if (_currentPage == 1) {
        _hasMore = true;
      }
    }

    if (_isLoading || _isLoadingMore) {
      return;
    }

    if (_currentPage == 1) {
      _setLoading(true);
    } else {
      _setLoadingMore(true);
    }

    _clearError();

    try {
      final response = await _productService.getAllProducts(
        page: _currentPage,
        limit: limit,
      );

      if (response.isSuccess && response.data != null) {
        final paginatedData = response.data!;
        final newProducts = paginatedData.products;

        if (_currentPage == 1) {
          // Null safety kontrolü
          if (newProducts.isNotEmpty) {
            _products = newProducts
                .where((product) => product.id.isNotEmpty)
                .toList();
          } else {
            _products = [];
          }
        } else {
          // Null safety kontrolü ile ekleme
          final validProducts = newProducts
              .where((product) => product.id.isNotEmpty)
              .toList();
          _products.addAll(validProducts);
        }

        // API'den gelen sayfalama bilgilerini kullan
        _hasMore = paginatedData.hasMore; // currentPage < totalPages
        _currentPage = paginatedData.currentPage + 1; // Bir sonraki sayfa

        // Engellenen kullanıcıların ilanlarını filtrele
        if (_currentPage == 1) {
          _products = _filterBlockedUsersProducts(_products);
        }
      } else {
        // 403 hatası kontrolü
        if (response.error != null &&
            (response.error!.contains('403') ||
                response.error!.contains('Erişim reddedildi') ||
                response.error!.contains('Hesabınızın süresi doldu'))) {
          ErrorHandlerService.handleForbiddenError(null);
        }

        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);
      _setLoadingMore(false);

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
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _products.clear();
    } else {
      // Refresh değilse ve ilk sayfa ise sayfa numarasını 1'e ayarla
      if (_currentPage == 1) {
        _hasMore = true;
      }
    }

    if (_isLoading || _isLoadingMore) {
      return;
    }

    _currentCategoryId = categoryId;
    _currentsearchText = searchText;
    _currentCity = city;
    _currentCondition = condition;

    if (_currentPage == 1) {
      _setLoading(true);
    } else {
      _setLoadingMore(true);
    }

    _clearError();

    try {
      final response = await _productService.getAllProducts(
        page: _currentPage,
        limit: AppConstants.defaultPageSize,
      );

      if (response.isSuccess && response.data != null) {
        final paginatedData = response.data!;
        final newProducts = paginatedData.products;

        if (_currentPage == 1) {
          // Null safety kontrolü
          if (newProducts.isNotEmpty) {
            _products = newProducts
                .where((product) => product.id.isNotEmpty)
                .toList();
          } else {
            _products = [];
          }
        } else {
          // Null safety kontrolü ile ekleme
          final validProducts = newProducts
              .where((product) => product.id.isNotEmpty)
              .toList();
          _products.addAll(validProducts);
        }

        // API'den gelen sayfalama bilgilerini kullan
        _hasMore = paginatedData.hasMore;
        _currentPage = paginatedData.currentPage + 1;
      } else {
        // 403 hatası kontrolü
        if (response.error != null &&
            (response.error!.contains('403') ||
                response.error!.contains('Erişim reddedildi') ||
                response.error!.contains('Hesabınızın süresi doldu'))) {
          ErrorHandlerService.handleForbiddenError(null);
        }

        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);
      _setLoadingMore(false);
      notifyListeners();
    }
  }

  Future<void> loadMoreProducts() async {
    if (!_hasMore || _isLoadingMore) {
      return;
    }

    _setLoadingMore(true);
    _clearError();

    try {
      ApiResponse<product_model.PaginatedProducts> response;

      // Eğer aktif filtreler varsa filtrelenmiş ürünleri yükle
      if (_currentFilter.hasActiveFilters) {
        response = await _productService.getAllProductsWithFilter(
          filter: _currentFilter,
          page: _currentPage,
          limit: AppConstants.defaultPageSize,
        );
      } else {
        response = await _productService.getAllProducts(
          page: _currentPage,
          limit: AppConstants.defaultPageSize,
        );
      }

      if (response.isSuccess && response.data != null) {
        final paginatedData = response.data!;
        final newProducts = paginatedData.products;

        // Yeni ürünleri mevcut listeye ekle
        _products.addAll(newProducts);
        _hasMore = paginatedData.hasMore;
        _currentPage = paginatedData.currentPage + 1;
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoadingMore(false);
      notifyListeners();
    }
  }

  Future<void> refreshProducts() async {
    try {
      // Mevcut filtreleri koruyarak ürünleri yenile
      await loadAllProducts(page: 1, refresh: true);

      // Engellenen kullanıcıların ilanlarını filtrele
      _products = _filterBlockedUsersProducts(_products);

      // Favorileri de filtrele
      _favoriteProducts = _filterBlockedUsersProducts(_favoriteProducts);

      // Benim ilanlarımı da filtrele
      _myProducts = _filterBlockedUsersProducts(_myProducts);

      notifyListeners();
    } catch (e) {
      _setError('Ürünler yenilenirken hata oluştu');
    }
  }

  Future<void> searchProducts(String query) async {
    _currentsearchText = query;
    // Sayfa numarasını sıfırla
    _currentPage = 1;
    _hasMore = true;

    notifyListeners();

    await loadProducts(
      categoryId: _currentCategoryId,
      searchText: query,
      city: _currentCity,
      condition: _currentCondition,
      refresh: true,
    );
  }

  // Canlı arama
  Future<void> liveSearch(String query) async {
    _liveQuery = query;
    if (query.trim().length < 2) {
      _liveResults = [];
      _isLiveSearching = false;
      notifyListeners();
      return;
    }

    _isLiveSearching = true;
    notifyListeners();

    try {
      final response = await _productService.liveSearch(
        searchText: query.trim(),
      );
      if (response.isSuccess && response.data != null) {
        final resp = response.data!; // LiveSearchResponse
        // Yinelenenleri temizle ve ürünleri üstte sırala
        final List<LiveSearchItem> raw = resp.data.results;
        final Set<String> seen = <String>{};
        final List<LiveSearchItem> unique = [];
        for (final item in raw) {
          final String key = item.type == 'product'
              ? 'product:${item.id}'
              : '${item.type}:${item.title.trim().toLowerCase()}';
          if (seen.contains(key)) continue;
          seen.add(key);
          unique.add(item);
        }
        unique.sort((a, b) {
          if (a.type == b.type) return 0;
          return a.type == 'product' ? -1 : 1;
        });
        _liveResults = unique;
      } else {
        _liveResults = [];
      }
    } catch (e) {
      _liveResults = [];
    } finally {
      _isLiveSearching = false;
      notifyListeners();
    }
  }

  // Arama geçmişini getir
  Future<void> loadSearchHistory() async {
    try {
      final currentUser = await _authService.getCurrentUser();

      if (currentUser == null || currentUser.id.isEmpty) {
        await _loadLocalHistoryFallback();
        notifyListeners();
        return;
      }

      final userId = int.tryParse(currentUser.id);

      if (userId == null) {
        await _loadLocalHistoryFallback();
        notifyListeners();
        return;
      }

      final resp = await _userService.getSearchHistory(userId: userId);

      if (resp.isSuccess && resp.data != null && resp.data!.items.isNotEmpty) {
        _searchHistory = resp.data!.items;

        // Local cache'e yaz
        await _saveLocalHistory(_searchHistory);
      } else {
        // Backend boş ise local fallback göster
        await _loadLocalHistoryFallback();
      }
    } catch (e) {
      await _loadLocalHistoryFallback();
    } finally {
      notifyListeners();
    }
  }

  // Arama geçmişini temizle
  Future<void> clearSearchHistory() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null || currentUser.id.isEmpty) {
        _searchHistory = [];
        // Local cache'i de temizle
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(AppConstants.localSearchHistoryKey);
        notifyListeners();
        return;
      }

      final userId = int.tryParse(currentUser.id);
      if (userId == null) {
        _searchHistory = [];
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(AppConstants.localSearchHistoryKey);
        notifyListeners();
        return;
      }

      final resp = await _userService.clearSearchHistory(userId: userId);
      if (resp.isSuccess) {
        _searchHistory = [];
        // Local cache'i temizle
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(AppConstants.localSearchHistoryKey);
      } else {
        // Backend başarısız olsa bile UI'da temizliği göster
        _searchHistory = [];
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(AppConstants.localSearchHistoryKey);
      }
    } catch (e) {
      _searchHistory = [];
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.localSearchHistoryKey);
    } finally {
      notifyListeners();
    }
  }

  // Local arama geçmişine kayıt ekle (login olmasa da çalışır)
  Future<void> addSearchHistoryEntry(
    String query, {
    String? type,
    String? categoryId,
  }) async {
    try {
      final normalized = query.trim();
      if (normalized.isEmpty) return;

      // Var mı kontrol et
      final existingIndex = _searchHistory.indexWhere(
        (e) => e.search.toLowerCase() == normalized.toLowerCase(),
      );

      if (existingIndex != -1) {
        final current = _searchHistory[existingIndex];
        final updated = SearchHistoryItem(
          search: current.search,
          searchCount: (current.searchCount) + 1,
          lastSearched: DateTime.now().toIso8601String(),
          formattedDate: 'az önce',
          type: type ?? current.type,
          categoryId: categoryId ?? current.categoryId,
        );
        _searchHistory[existingIndex] = updated;
        // En üste taşı
        final item = _searchHistory.removeAt(existingIndex);
        _searchHistory.insert(0, item);
      } else {
        _searchHistory.insert(
          0,
          SearchHistoryItem(
            search: normalized,
            searchCount: 1,
            lastSearched: DateTime.now().toIso8601String(),
            formattedDate: 'az önce',
            type: type ?? 'text',
            categoryId: categoryId,
          ),
        );
      }

      // Maksimum boyutu koru ve kaydet
      if (_searchHistory.length > _maxLocalHistory) {
        _searchHistory = _searchHistory.take(_maxLocalHistory).toList();
      }
      await _saveLocalHistory(_searchHistory);
    } catch (e) {
    } finally {
      notifyListeners();
    }
  }

  /// Kategori arama geçmişi ekler
  Future<void> addCategorySearchHistory(
    String categoryName,
    String categoryId,
  ) async {
    await addSearchHistoryEntry(
      categoryName,
      type: 'category',
      categoryId: categoryId,
    );
  }

  /// Metin arama geçmişi ekler
  Future<void> addTextSearchHistory(String query) async {
    await addSearchHistoryEntry(query, type: 'text');
  }

  Future<void> _loadLocalHistoryFallback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.localSearchHistoryKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _searchHistory = list
            .where((e) => e is Map<String, dynamic>)
            .map((e) => SearchHistoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _searchHistory = [];
      }
    } catch (_) {
      _searchHistory = [];
    }
  }

  Future<void> _saveLocalHistory(List<SearchHistoryItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trimmed = items.take(_maxLocalHistory).toList();
      final jsonList = trimmed
          .map(
            (e) => {
              'search': e.search,
              'searchCount': e.searchCount,
              'lastSearched': e.lastSearched,
              'formattedDate': e.formattedDate,
            },
          )
          .toList();
      await prefs.setString(
        AppConstants.localSearchHistoryKey,
        jsonEncode(jsonList),
      );
    } catch (_) {}
  }

  Future<void> filterByCategory(String? categoryId) async {
    // Sayfa numarasını sıfırla
    _currentPage = 1;
    _hasMore = true;

    // Yeni filtreleme sistemi kullan
    final newFilter = _currentFilter.copyWith(categoryId: categoryId);

    await applyFilter(newFilter);
  }

  Future<void> sortProducts(SortOption sortOption) async {
    _currentSortOption = sortOption;
    // Sayfa numarasını sıfırla
    _currentPage = 1;
    _hasMore = true;

    notifyListeners();

    await loadProducts(
      categoryId: _currentCategoryId,
      searchText: _currentsearchText,
      city: _currentCity,
      condition: _currentCondition,
      refresh: true,
    );
  }

  Future<void> loadProductById(String productId) async {
    _setLoading(true);
    _clearError();

    try {
      // Yeni mantık: sadece yeni endpoint ile getir (Basic Auth + userToken)
      final userToken = await _authService.getToken();
      if (userToken == null || userToken.isEmpty) {
        _setError('Kullanıcı oturumu bulunamadı');
        return;
      }

      final response = await _productService.getProductDetail(
        userToken: userToken,
        productId: productId,
      );

      if (response.isSuccess && response.data != null) {
        _selectedProduct = response.data;

        // View count'u artır (arka planda)

        _productService.incrementViewCount(productId);
      } else {
        if (response.error != null &&
            (response.error!.contains('403') ||
                response.error!.contains('Erişim reddedildi') ||
                response.error!.contains('Hesabınızın süresi doldu'))) {
          ErrorHandlerService.handleForbiddenError(null);
        }

        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUserProducts(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _productService.getProductsByUserId(userId);

      if (response.isSuccess) {
        _myProducts = response.data ?? [];

        // Yüklenen ürünlerin adres bilgilerini kontrol et
        for (int i = 0; i < _myProducts.length; i++) {
          final product = _myProducts[i];
        }
      } else {
        final errorMessage = response.error ?? ErrorMessages.unknownError;
        _setError(errorMessage);
      }
    } catch (e) {
      final errorMessage = ErrorMessages.unknownError;
      _setError(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadFavoriteProducts() async {
    // Kullanıcı giriş yapmamışsa favorileri yükleme
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) {
      // Favorileri temizle
      _favoriteProducts.clear();
      notifyListeners();
      return;
    }

    // Kullanıcı değişmişse cache'i temizle
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUserId = prefs.getString('favorite_products_user_id');
      if (cachedUserId != null && cachedUserId != currentUser.id) {
        Logger.info(
          '🔄 ProductViewModel - Kullanıcı değişmiş, favori cache temizleniyor',
        );
        await clearFavoriteCache();
      }
    } catch (e) {
      Logger.warning('⚠️ ProductViewModel - Cache kontrol hatası: $e');
    }

    // Eğer favoriler zaten yüklüyse ve loading değilse, tekrar yükleme
    if (_favoriteProducts.isNotEmpty && !_isLoadingFavorites) {
      return;
    }

    _setLoadingFavorites(true);
    _clearFavoriteError();

    try {
      // Önce kategorileri yükle (kategori adları için gerekli)
      if (_categories.isEmpty) {
        await loadCategories();
      }

      final response = await _productService.getFavoriteProducts();

      if (response.isSuccess && response.data != null) {
        _favoriteProducts = response.data!;

        // Kullanıcı ID'sini cache'e kaydet
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('favorite_products_user_id', currentUser.id);
          Logger.info(
            '✅ ProductViewModel - Favori cache kullanıcı ID kaydedildi: ${currentUser.id}',
          );
        } catch (e) {
          Logger.warning('⚠️ ProductViewModel - Cache kaydetme hatası: $e');
        }

        // Favori ürünlerin detaylarını logla
        for (int i = 0; i < _favoriteProducts.length; i++) {
          final product = _favoriteProducts[i];
        }
      } else {
        final errorMessage = response.error ?? ErrorMessages.unknownError;

        _setFavoriteError(errorMessage);
      }
    } catch (e) {
      _setFavoriteError(ErrorMessages.unknownError);
    } finally {
      _setLoadingFavorites(false);
    }
  }

  Future<void> loadCategories() async {
    // Eğer kategoriler zaten yüklüyse ve boş değilse, tekrar yükleme
    if (_categories.isNotEmpty) {
      return;
    }

    try {
      final response = await _productService.getCategories();

      if (response.isSuccess && response.data != null) {
        _categories = response.data ?? [];

        // Kategori detaylarını logla

        for (int i = 0; i < _categories.length; i++) {
          final category = _categories[i];

          // Kategori ikonlarını önceden cache'le
          if (category.icon.isNotEmpty) {
            _preloadCategoryIcon(category.icon);
          }
        }

        notifyListeners();
      } else {
        _setError(response.error ?? 'Kategoriler yüklenemedi');
      }
    } catch (e) {
      _setError('Kategoriler yüklenirken hata oluştu');
    }
  }

  void _preloadCategoryIcon(String iconUrl) {
    // Eğer global cache'de zaten varsa yükleme
    if (CategoryIconCache.hasIcon(iconUrl)) {
      return;
    }

    // Arka planda ikonları cache'le
    CacheService()
        .downloadAndCacheIcon(iconUrl)
        .then((downloadedIcon) {
          if (downloadedIcon != null) {
            CategoryIconCache.setIcon(iconUrl, downloadedIcon);
          }
        })
        .catchError((error) {});
  }

  /// Popüler kategorileri yükler
  Future<void> loadPopularCategories() async {
    try {
      final response = await _productService.getPopularCategories();

      if (response.isSuccess && response.data != null) {
        _popularCategories = response.data ?? [];

        notifyListeners();
      } else {
        _popularCategories.clear();
        notifyListeners();
      }
    } catch (e) {
      _popularCategories.clear();
      notifyListeners();
    }
  }

  Future<void> loadSubCategories(String parentCategoryId) async {
    try {
      final response = await _productService.getSubCategories(parentCategoryId);

      if (response.isSuccess && response.data != null) {
        _subCategories = response.data ?? [];
        _selectedParentCategoryId = parentCategoryId;

        _subCategories.forEach((cat) => print('  - ${cat.name} (${cat.id})'));
        notifyListeners();
      } else {
        _subCategories.clear();
        _selectedParentCategoryId = null;
        notifyListeners();
      }
    } catch (e) {
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
    try {
      final response = await _productService.getSubSubCategories(
        parentSubCategoryId,
      );

      if (response.isSuccess && response.data != null) {
        _subSubCategories = response.data ?? [];
        _selectedSubCategoryId = parentSubCategoryId;

        _subSubCategories.forEach(
          (cat) => print('  - ${cat.name} (${cat.id})'),
        );

        notifyListeners();
      } else {
        _subSubCategories.clear();
        _selectedSubCategoryId = null;

        notifyListeners();
      }
    } catch (e) {
      _subSubCategories.clear();
      _selectedSubCategoryId = null;

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
      final response = await _productService.getSubSubSubCategories(
        parentSubSubCategoryId,
      );

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

    // Tüm kategorilerin ID'lerini yazdır

    for (int i = 0; i < _categories.length; i++) {
      final category = _categories[i];
    }

    try {
      final category = _categories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => const product_model.Category(
          id: '',
          name: 'Kategori Yok',
          icon: '',
          isActive: true,
          order: 0,
        ),
      );

      if (category.name.isNotEmpty &&
          category.name != 'Kategori Yok' &&
          category.name != 'Kategori' &&
          category.name != 'null') {
        return category.name;
      } else {}
    } catch (e) {}

    return 'Kategori Yok';
  }

  // Kategori ID'sine göre kategori nesnesini bul
  product_model.Category? getCategoryById(String categoryId) {
    if (categoryId.isEmpty) return null;

    try {
      return _categories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => const product_model.Category(
          id: '',
          name: 'Kategori Yok',
          icon: '',
          isActive: true,
          order: 0,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> loadCities() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _productService.getCities();

      if (response.isSuccess && response.data != null) {
        _cities = response.data ?? [];

        // Tüm şehirleri logla
        if (_cities.isNotEmpty) {
          for (int i = 0; i < _cities.length; i++) {
            final city = _cities[i];
          }
        } else {}

        _isLoading = false;
        notifyListeners();
      } else {
        _isLoading = false;
        _setError(response.error ?? 'İller yüklenemedi');
      }
    } catch (e) {
      _isLoading = false;
      _setError('İller yüklenirken hata oluştu');
    }
  }

  Future<void> loadDistricts(String cityId) async {
    // Şehir değiştiğinde önce mevcut ilçe listesini boşalt ve UI'ı temizle
    _lastDistrictsRequestedCityId = cityId;
    _districts = [];
    notifyListeners();
    try {
      final response = await _productService.getDistricts(cityId);

      // Eğer bu arada farklı bir şehir için istek yapılmışsa, bu yanıtı yoksay
      if (_lastDistrictsRequestedCityId != cityId) {
        return;
      }

      if (response.isSuccess && response.data != null) {
        _districts = response.data ?? [];

        // Tüm ilçeleri logla (gerekirse)
        if (_districts.isNotEmpty) {
          for (int i = 0; i < _districts.length; i++) {
            final district = _districts[i];
          }
        }

        notifyListeners();
      } else {
        _districts = []; // Boş liste ata, hata gösterme
        notifyListeners();
      }
    } catch (e) {
      // Hata durumunda da listeyi boş tut
      _districts = [];
      notifyListeners();
    }
  }

  void clearDistricts() {
    _districts = [];
    notifyListeners();
  }

  Future<void> loadConditions() async {
    try {
      final response = await _productService.getConditions();

      if (response.isSuccess && response.data != null) {
        _conditions = response.data ?? [];

        // Tüm durumları logla
        if (_conditions.isNotEmpty) {
          for (int i = 0; i < _conditions.length; i++) {
            final condition = _conditions[i];
          }
        } else {}

        notifyListeners();
      } else {
        _setError(response.error ?? 'Ürün durumları yüklenemedi');
      }
    } catch (e) {
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
    if (title.trim().isEmpty || description.trim().isEmpty) {
      _setError(ErrorMessages.fieldRequired);
      return false;
    }

    if (images.isEmpty) {
      _setError('En az bir resim eklemelisiniz');
      return false;
    }

    // Takas tercihleri opsiyoneldir; boş olabilir

    _setLoading(true);
    _clearError();

    try {
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

      if (response.isSuccess && response.data != null) {
        _myProducts.insert(0, response.data!);

        _setLoading(false);
        return true;
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return false;
    }
  }

  Future<Map<String, dynamic>> toggleFavorite(String productId) async {
    try {
      // Kullanıcının kendi ürünü olup olmadığını kontrol et
      final isOwnProduct = _myProducts.any((p) => p.id == productId);
      if (isOwnProduct) {
        return {
          'success': false,
          'wasFavorite': false,
          'message': 'Kendi ürününüzü favoriye ekleyemezsiniz',
        };
      }

      final isFavorite = _favoriteProducts.any((p) => p.id == productId);

      if (isFavorite) {
        // Favorilerden çıkar

        final response = await _productService.removeFromFavorites(productId);

        if (response.isSuccess) {
          _favoriteProducts.removeWhere((p) => p.id == productId);

          notifyListeners();
          return {
            'success': true,
            'wasFavorite': true,
            'message': 'Ürün favorilerden çıkarıldı',
          };
        } else {
          // API başarısız olsa bile local list'ten çıkar (kullanıcı deneyimi için)

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

        final response = await _productService.addToFavorites(productId);
        if (response.isSuccess) {
          // Favorilere eklenen ürünü bulup listeye ekle
          product_model.Product? productToAdd;

          // Önce _products listesinde ara
          try {
            productToAdd = _products.firstWhere((p) => p.id == productId);
          } catch (e) {
            // _products'da bulunamazsa _myProducts'da ara
            try {
              productToAdd = _myProducts.firstWhere((p) => p.id == productId);
            } catch (e) {
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

          // productToAdd burada null olamaz; doğrudan ekle
          _favoriteProducts.add(productToAdd);

          notifyListeners();
          return {
            'success': true,
            'wasFavorite': false,
            'message': 'Ürün favorilere eklendi',
          };
        } else {
          return {
            'success': false,
            'wasFavorite': false,
            'message': response.error ?? 'Ürün favorilere eklenemedi',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'wasFavorite': _favoriteProducts.any((p) => p.id == productId),
        'message': 'Bir hata oluştu',
      };
    }
  }

  bool isFavorite(String productId) {
    // Eğer favori listesi boşsa false döndür
    if (_favoriteProducts.isEmpty) {
      return false;
    }

    return _favoriteProducts.any((p) => p.id == productId);
  }

  void clearSelectedProduct() {
    _selectedProduct = null;
    notifyListeners();
  }

  /// Kullanıcı değişikliği durumunda tüm ürün listelerini temizler
  void clearAllProductData() {
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
  }

  /// Kullanıcı değişikliği durumunda favori cache'ini temizler
  Future<void> clearFavoriteCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Favori ile ilgili tüm cache'leri temizle
      await prefs.remove('favorite_products_cache');
      await prefs.remove('favorite_products_timestamp');
      await prefs.remove('favorite_products_user_id');

      // Memory'deki favori listesini de temizle
      _favoriteProducts.clear();

      Logger.info('✅ ProductViewModel - Favori cache temizlendi');
      notifyListeners();
    } catch (e) {
      Logger.error('❌ ProductViewModel - Favori cache temizleme hatası: $e');
    }
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
    if (productTitle.trim().isEmpty) {
      _setError('Ürün başlığı boş olamaz');
      return false;
    }

    if (productDescription.trim().isEmpty) {
      _setError('Ürün açıklaması boş olamaz');
      return false;
    }

    if (productImages.isEmpty) {
      _setError('En az bir ürün resmi seçmelisiniz');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
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

      if (response.isSuccess && response.data != null) {
        final responseData = response.data!;
        final productId = responseData['productID']?.toString() ?? 'unknown';
        final message = responseData['message']?.toString() ?? 'İlan eklendi';

        // Başarılı olduktan sonra ürün listesini yenile

        await refreshProducts();
        return true;
      } else {
        _setError(response.error ?? 'İlan eklenemedi');
        return false;
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return false;
    }
  }

  // Ürün silme metodu
  Future<bool> deleteUserProduct(String productId) async {
    _setLoading(true);
    _clearError();

    try {
      // Current user'ı al
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        _setError('Kullanıcı oturumu bulunamadı');
        _setLoading(false);
        return false;
      }

      // User token'ı al ve detaylı kontrol et
      final userToken = await _authService.getToken();
      if (userToken == null || userToken.isEmpty) {
        _setError('Kullanıcı token\'ı bulunamadı');
        _setLoading(false);
        return false;
      }

      // Token geçerliliğini kontrol et - zaten currentUser var, tekrar almaya gerek yok

      // API'de ownership kontrolü yapılacağı için client-side kontrol kaldırıldı

      final response = await _productService.deleteUserProduct(
        userToken: userToken,
        productId: productId,
      );

      if (response.isSuccess) {
        // Optimistic UI update: remove the product from both local lists immediately
        final originalProductIndex = _myProducts.indexWhere(
          (p) => p.id == productId,
        );
        final originalAllProductsIndex = _products.indexWhere(
          (p) => p.id == productId,
        );
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
          // Ana sayfa ürün listesini de yenile

          await refreshProducts();
        } else {
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
        _setError(response.error ?? 'Ürün silinemedi');
        _setLoading(false);
        return false;
      }
    } catch (e, stackTrace) {
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
    List<String>? existingImageUrls,
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
    _setLoading(true);
    _clearError();

    try {
      // Current user'ı al
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        _setError('Kullanıcı bilgileri bulunamadı');
        _setLoading(false);
        return false;
      }

      // Token'ı AuthService'den al
      final userToken = await _authService.getToken();
      if (userToken?.isEmpty ?? true) {
        _setError('Kullanıcı token\'ı bulunamadı. Lütfen tekrar giriş yapın.');
        _setLoading(false);
        return false;
      }

      // Null check for userToken
      if (userToken == null) {
        _setError('Kullanıcı token\'ı bulunamadı. Lütfen tekrar giriş yapın.');
        _setLoading(false);
        return false;
      }

      // Token geçerliliğini kontrol et (basit kontrol)
      if (userToken.length < 20) {
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
        existingImageUrls: existingImageUrls,
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

      if (response.isSuccess) {
        // API'den gelen yanıt kontrolü
        if (response.data != null) {
          final updatedProduct = response.data!;

          // API'den dönen ürün verisi eksikse (sadece ID varsa), güncel veriyi çek
          if (updatedProduct.title.isEmpty ||
              updatedProduct.description.isEmpty) {
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
          // API'den ürün verisi dönmediğinde, sadece o ürünü yeniden yükle

          await _loadUpdatedProduct(productId);
        }

        _setLoading(false);
        return true;
      } else {
        // Token hatası kontrolü
        if (response.error != null &&
            (response.error!.contains('Hesabınızın süresi doldu') ||
                response.error!.contains('Üye doğrulama bilgileri hatalı') ||
                response.error!.contains('403') ||
                response.error!.contains('Forbidden'))) {
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
      _setError('Ürün güncellenirken hata oluştu: $e');
      _setLoading(false);
      return false;
    }
  }

  // Güncellenmiş ürünü yeniden yükle
  Future<void> _loadUpdatedProduct(String productId) async {
    try {
      // Yeni mantık: yalnızca yeni ürün detay endpoint'i
      final userToken = await _authService.getToken();
      if (userToken == null || userToken.isEmpty) {
        await refreshProducts();
        return;
      }

      final response = await _productService.getProductDetail(
        userToken: userToken,
        productId: productId,
      );

      if (response.isSuccess && response.data != null) {
        final updatedProduct = response.data!;

        _updateProductInLists(updatedProduct);
        if (_selectedProduct?.id == productId) {
          _selectedProduct = updatedProduct;
        }
      } else {
        await refreshProducts();
      }
    } catch (e) {
      await refreshProducts();
    }
  }

  // Güncellenmiş ürünü listelerde güncelle
  void _updateProductInLists(product_model.Product updatedProduct) {
    // Ana ürün listesinde güncelle
    final productIndex = _products.indexWhere((p) => p.id == updatedProduct.id);
    if (productIndex != -1) {
      _products[productIndex] = updatedProduct;
    }

    // Kullanıcının ürünleri listesinde güncelle
    final myProductIndex = _myProducts.indexWhere(
      (p) => p.id == updatedProduct.id,
    );
    if (myProductIndex != -1) {
      _myProducts[myProductIndex] = updatedProduct;
    }

    // Favori ürünler listesinde güncelle
    final favoriteIndex = _favoriteProducts.indexWhere(
      (p) => p.id == updatedProduct.id,
    );
    if (favoriteIndex != -1) {
      _favoriteProducts[favoriteIndex] = updatedProduct;
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
    String? selectedCityTitle,
    String? selectedDistrictTitle,
    bool? isShowContact,
    double? userProvidedLatitude,
    double? userProvidedLongitude,
  }) async {
    // Validasyonlar
    if (productTitle.trim().isEmpty || productDescription.trim().isEmpty) {
      _setError('Başlık ve açıklama zorunludur');
      return false;
    }

    // Takas tercihi opsiyoneldir; boş olabilir

    // Resim validasyonu - en az bir resim gerekli
    if (productImages.isEmpty) {
      _setError('En az bir fotoğraf eklemelisiniz');
      return false;
    }

    // Resim durumu kontrolü
    for (int i = 0; i < productImages.length; i++) {}

    _setLoading(true);
    _clearError();

    try {
      // Current user'ı al
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        _setError('Kullanıcı oturumu bulunamadı');
        return false;
      }

      // User token'ı al (stored token)
      final userToken = await _authService.getToken();
      if (userToken == null) {
        _setError('Kullanıcı token\'ı bulunamadı');
        return false;
      }

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
        selectedCityTitle: selectedCityTitle,
        selectedDistrictTitle: selectedDistrictTitle,
        isShowContact: isShowContact,
        userProvidedLatitude: userProvidedLatitude,
        userProvidedLongitude: userProvidedLongitude,
      );

      if (response.isSuccess && response.data != null) {
        final responseData = response.data!;
        final productId = responseData['productID']?.toString() ?? 'unknown';
        final message = responseData['message']?.toString() ?? 'İlan eklendi';

        // Son eklenen ürün ID'sini sakla (sponsor için)
        _lastAddedProductId = productId;

        // Başarılı olduktan sonra ürün listesini yenile

        await refreshProducts();
        return true;
      } else {
        _setError(response.error ?? 'İlan eklenemedi');
        return false;
      }
    } catch (e, stackTrace) {
      _setError('İlan eklenirken hata oluştu: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Yeni filtreleme metodları
  Future<void> applyFilter(ProductFilter filter) async {
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

      if (response.isSuccess && response.data != null) {
        final paginatedData = response.data!;
        final newProducts = paginatedData.products;

        // Null safety kontrolü
        if (newProducts.isNotEmpty) {
          _products = newProducts
              .where((product) => product.id.isNotEmpty)
              .toList();
        } else {
          _products = [];
        }
        _hasMore = paginatedData.hasMore;
        _currentPage = paginatedData.currentPage + 1; // Bir sonraki sayfa
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);

      notifyListeners();
    }
  }

  Future<void> clearFilters() async {
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

    await loadAllProducts(refresh: true);

    // Letgo gibi: Kullanıcı giriş yapmışsa otomatik olarak "en yakın" filtresini uygula
    final currentUser = await _authService.getCurrentUser();
    if (currentUser != null) {
      try {
        // Konum bazlı filtreleme uygula
        final locationFilter = _currentFilter.copyWith(sortType: 'location');

        await applyFilter(locationFilter);
      } catch (e) {
        // Hata durumunda varsayılan sıralamaya geri dön

        try {
          await applyFilter(_currentFilter.copyWith(sortType: 'default'));
        } catch (e2) {}
      }
    } else {}
  }

  Future<bool> _verifyDeletion(
    String productId, {
    int retries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    for (int i = 0; i < retries; i++) {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        return false; // Should not happen
      }

      await loadUserProducts(currentUser.id);
      final productStillExists = _myProducts.any((p) => p.id == productId);

      if (!productStillExists) {
        return true; // Verified!
      }

      await Future.delayed(delay * (i + 1)); // Increasing delay
    }

    return false; // Failed after all retries
  }

  /// Ürün detayını getirir (detay sayfası için)
  /// Kullanıcının giriş durumuna göre API endpoint'ini dinamik olarak yönetir
  Future<product_model.Product?> getProductDetail(String productId) async {
    _setLoading(true);
    _clearError();
    try {
      final userToken = await _authService.getToken();
      if (userToken == null || userToken.isEmpty) {
      } else {}

      final response = await _productService.getProductDetail(
        userToken: userToken, // Token yoksa null gönderilecek
        productId: productId,
      );

      if (response.data != null) {}

      if (response.isSuccess && response.data != null) {
        _selectedProduct = response.data;

        _setLoading(false);
        return response.data;
      } else {
        _setError(response.error ?? 'Ürün detayı alınamadı');
        _setLoading(false);
        return null;
      }
    } catch (e) {
      _setError('Ürün detayı alınamadı: $e');
      _setLoading(false);
      return null;
    }
  }

  /// Ürünü sponsor yapar (ödüllü reklam sonrası)
  Future<bool> sponsorProduct(String productId) async {
    try {
      // User token'ı al
      final userToken = await _authService.getToken();
      if (userToken == null || userToken.isEmpty) {
        _setError('Kullanıcı oturumu bulunamadı');
        return false;
      }

      // Product ID'yi integer'a çevir
      final int? productIdInt = int.tryParse(productId);
      if (productIdInt == null) {
        _setError('Geçersiz ürün ID\'si');
        return false;
      }

      final response = await _productService.sponsorProduct(
        userToken: userToken,
        productId: productIdInt,
      );

      if (response.isSuccess && response.data != null) {
        // Response'dan sponsor bilgilerini al
        final responseData = response.data!;
        final sponsorUntil = responseData['sponsorUntil']?.toString();
        final message =
            responseData['message']?.toString() ??
            'Ürününüz başarıyla öne çıkarıldı.';

        // Local listelerdeki ürünü güncelle
        await _updateProductSponsorStatus(productId, sponsorUntil);

        // Success message'ı göster (UI katmanında kullanılabilir)
        return true;
      } else {
        _setError(response.error ?? 'Ürün öne çıkarılamadı');
        return false;
      }
    } catch (e) {
      _setError('Ürün öne çıkarılırken hata oluştu: $e');
      return false;
    }
  }

  /// Local listelerdeki ürünün sponsor durumunu günceller
  Future<void> _updateProductSponsorStatus(
    String productId,
    String? sponsorUntil,
  ) async {
    // Ana ürün listesinde güncelle
    final productIndex = _products.indexWhere((p) => p.id == productId);
    if (productIndex != -1) {
      _products[productIndex] = _products[productIndex].copyWith(
        isSponsor: true,
        sponsorUntil: sponsorUntil,
      );
    }

    // Kullanıcının ürünleri listesinde güncelle
    final myProductIndex = _myProducts.indexWhere((p) => p.id == productId);
    if (myProductIndex != -1) {
      _myProducts[myProductIndex] = _myProducts[myProductIndex].copyWith(
        isSponsor: true,
        sponsorUntil: sponsorUntil,
      );
    }

    // Favori ürünler listesinde güncelle
    final favoriteIndex = _favoriteProducts.indexWhere(
      (p) => p.id == productId,
    );
    if (favoriteIndex != -1) {
      _favoriteProducts[favoriteIndex] = _favoriteProducts[favoriteIndex]
          .copyWith(isSponsor: true, sponsorUntil: sponsorUntil);
    }

    // Seçili ürünü güncelle
    if (_selectedProduct?.id == productId) {
      _selectedProduct = _selectedProduct!.copyWith(
        isSponsor: true,
        sponsorUntil: sponsorUntil,
      );
    }

    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Koordinatlardan il ve ilçe ID'lerini bulur
  Future<Map<String, String>?> findCityDistrictIdsFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // Önce şehirler yüklenmemişse yükle
      if (_cities.isEmpty) {
        await loadCities();
      }

      // Koordinatlardan il ve ilçe isimlerini al
      final locationService = LocationService();
      final locationInfo = await locationService.getCityDistrictFromCoordinates(
        latitude,
        longitude,
      );

      if (locationInfo == null) {
        return null;
      }

      final cityName = locationInfo['city'];
      final districtName = locationInfo['district'];
      final fullAddress = locationInfo['fullAddress'];

      // İl ID'sini bul
      String? cityId;
      if (cityName != null && cityName.isNotEmpty) {
        // Türkçe karakterleri normalize et
        final normalizedCityName = _normalizeTurkishText(cityName);

        cityId = _findCityIdByName(normalizedCityName);

        if (cityId != null) {
        } else {}
      }

      // İlçe ID'sini bul (eğer il bulunduysa ve ilçe bilgisi varsa)
      String? districtId;
      if (cityId != null && districtName != null && districtName.isNotEmpty) {
        // Her durumda doğru şehir için ilçeleri yeniden yükle (stale listeyi önle)
        await loadDistricts(cityId);

        // Türkçe karakterleri normalize et
        final normalizedDistrictName = _normalizeTurkishText(districtName);

        districtId = _findDistrictIdByName(normalizedDistrictName);

        if (districtId != null) {
        } else {
          // İlçe bulunamadıysa, ilçe listesini kontrol et ve logla

          // Alternatif arama yöntemleri dene

          // 1. Kısmi eşleşme ara (daha esnek)
          final partialMatch = _findDistrictByPartialMatch(
            normalizedDistrictName,
          );
          if (partialMatch != null) {
            districtId = partialMatch;
          }

          // 2. Benzer isim ara
          if (districtId == null) {
            final similarMatch = _findDistrictBySimilarName(
              normalizedDistrictName,
            );
            if (similarMatch != null) {
              districtId = similarMatch;
            }
          }
        }
      } else if (cityId != null) {}

      if (cityId != null) {
        final result = {
          'cityId': cityId,
          'districtId': districtId ?? '',
          'cityName': cityName ?? '',
          'districtName': districtName ?? '',
        };

        return result;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// İl adına göre ID bulur
  String? _findCityIdByName(String cityName) {
    try {
      // Tam eşleşme ara
      var city = _cities.firstWhere(
        (city) =>
            _normalizeTurkishText(city.name).toLowerCase() ==
            cityName.toLowerCase(),
        orElse: () => throw Exception('Şehir bulunamadı'),
      );
      return city.id;
    } catch (e) {
      // Tam eşleşme bulunamadıysa kısmi eşleşme ara
      try {
        var city = _cities.firstWhere(
          (city) =>
              _normalizeTurkishText(
                city.name,
              ).toLowerCase().contains(cityName.toLowerCase()) ||
              cityName.toLowerCase().contains(
                _normalizeTurkishText(city.name).toLowerCase(),
              ),
          orElse: () => throw Exception('Şehir bulunamadı'),
        );
        return city.id;
      } catch (e) {
        return null;
      }
    }
  }

  /// İlçe adına göre ID bulur
  String? _findDistrictIdByName(String districtName) {
    try {
      // Tam eşleşme ara
      var district = _districts.firstWhere(
        (district) =>
            _normalizeTurkishText(district.name).toLowerCase() ==
            districtName.toLowerCase(),
        orElse: () => throw Exception('İlçe bulunamadı'),
      );
      return district.id;
    } catch (e) {
      // Tam eşleşme bulunamadıysa kısmi eşleşme ara
      try {
        var district = _districts.firstWhere(
          (district) =>
              _normalizeTurkishText(
                district.name,
              ).toLowerCase().contains(districtName.toLowerCase()) ||
              districtName.toLowerCase().contains(
                _normalizeTurkishText(district.name).toLowerCase(),
              ),
          orElse: () => throw Exception('İlçe bulunamadı'),
        );
        return district.id;
      } catch (e) {
        return null;
      }
    }
  }

  /// Türkçe karakterleri normalize eder
  String _normalizeTurkishText(String text) {
    return text
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .replaceAll('Ğ', 'ğ')
        .replaceAll('Ü', 'ü')
        .replaceAll('Ş', 'ş')
        .replaceAll('Ö', 'ö')
        .replaceAll('Ç', 'ç');
  }

  /// İlçe adına göre kısmi eşleşme ile ID bulur
  String? _findDistrictByPartialMatch(String districtName) {
    try {
      // Daha esnek kısmi eşleşme ara
      var district = _districts.firstWhere((district) {
        final normalizedDistrictName = _normalizeTurkishText(
          district.name,
        ).toLowerCase();
        final searchName = districtName.toLowerCase();

        // Kelime bazında eşleşme ara
        final districtWords = normalizedDistrictName.split(' ');
        final searchWords = searchName.split(' ');

        // En az bir kelime eşleşiyorsa kabul et
        for (final searchWord in searchWords) {
          if (searchWord.length > 2) {
            // 2 karakterden uzun kelimeler
            for (final districtWord in districtWords) {
              if (districtWord.contains(searchWord) ||
                  searchWord.contains(districtWord)) {
                return true;
              }
            }
          }
        }

        return false;
      }, orElse: () => throw Exception('İlçe bulunamadı'));
      return district.id;
    } catch (e) {
      return null;
    }
  }

  /// İlçe adına göre benzer isim ile ID bulur
  String? _findDistrictBySimilarName(String districtName) {
    try {
      // Levenshtein mesafesi ile en benzer ismi bul
      String? bestMatch;
      double bestScore = 0.8; // Minimum benzerlik skoru

      for (final district in _districts) {
        final normalizedDistrictName = _normalizeTurkishText(
          district.name,
        ).toLowerCase();
        final searchName = districtName.toLowerCase();

        // Basit benzerlik hesaplama
        final similarity = _calculateSimilarity(
          normalizedDistrictName,
          searchName,
        );

        if (similarity > bestScore) {
          bestScore = similarity;
          bestMatch = district.id;
        }
      }

      return bestMatch;
    } catch (e) {
      return null;
    }
  }

  /// İki string arasındaki benzerliği hesaplar
  double _calculateSimilarity(String str1, String str2) {
    if (str1 == str2) return 1.0;
    if (str1.isEmpty || str2.isEmpty) return 0.0;

    // Basit benzerlik hesaplama (Jaccard similarity)
    final set1 = str1.split('').toSet();
    final set2 = str2.split('').toSet();

    final intersection = set1.intersection(set2).length;
    final union = set1.union(set2).length;

    return intersection / union;
  }

  /// Engellenen kullanıcıların ilanlarını filtreler
  List<product_model.Product> _filterBlockedUsersProducts(
    List<product_model.Product> products,
  ) {
    try {
      // Engellenen kullanıcıların ID'lerini al
      final blockedUserIds = _getBlockedUserIds();

      if (blockedUserIds.isEmpty) {
        return products;
      }

      // Engellenen kullanıcıların ilanlarını filtrele
      final filteredProducts = products.where((product) {
        try {
          final ownerId = int.tryParse(product.ownerId);
          if (ownerId == null) {
            return true; // Geçersiz ID'li ürünleri göster
          }

          final isBlocked = blockedUserIds.contains(ownerId);
          if (isBlocked) {}

          return !isBlocked;
        } catch (e) {
          return true; // Hata durumunda ürünü göster
        }
      }).toList();

      return filteredProducts;
    } catch (e) {
      return products; // Hata durumunda tüm ürünleri göster
    }
  }

  /// Engellenen kullanıcı ID'lerini döndürür
  List<int> _getBlockedUserIds() {
    try {
      // Cache'den engellenen kullanıcıları al
      final blockedUsersJson = _cacheService.getBlockedUsers();
      if (blockedUsersJson == null || blockedUsersJson.isEmpty) {
        return [];
      }

      final List<dynamic> blockedUsersList = jsonDecode(blockedUsersJson);
      final blockedUserIds = blockedUsersList
          .where(
            (user) =>
                user is Map<String, dynamic> &&
                user.containsKey('blockedUserID'),
          )
          .map((user) => int.tryParse(user['blockedUserID'].toString()))
          .where((id) => id != null)
          .cast<int>()
          .toList();

      return blockedUserIds;
    } catch (e) {
      return [];
    }
  }
}
