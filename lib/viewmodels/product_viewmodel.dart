import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/product.dart' as product_model;
import '../models/user.dart';
import '../models/city.dart';
import '../models/district.dart';
import '../models/condition.dart';
import '../models/product_filter.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../core/constants.dart';
import '../core/sort_options.dart';

class ProductViewModel extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();

  List<product_model.Product> _products = [];
  List<product_model.Product> _favoriteProducts = [];
  List<product_model.Product> _myProducts = [];
  List<product_model.Category> _categories = [];
  List<City> _cities = [];
  List<District> _districts = [];
  List<Condition> _conditions = [];
  product_model.Product? _selectedProduct;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  int _currentPage = 1;
  String? _currentCategoryId;
  String? _currentSearchQuery;
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
  List<product_model.Category> get categories => _categories;
  List<City> get cities => _cities;
  List<District> get districts => _districts;
  List<Condition> get conditions => _conditions;
  product_model.Product? get selectedProduct => _selectedProduct;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  int get currentPage => _currentPage;
  String? get currentCategoryId => _currentCategoryId;
  String? get currentSearchQuery => _currentSearchQuery;
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
    print(
      '🔄 ProductViewModel.loadAllProducts started - page: $page, refresh: $refresh',
    );

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _products.clear();
      print(
        '🔄 ProductViewModel.loadAllProducts - refresh mode, cleared products',
      );
    }

    if (_isLoading || _isLoadingMore) {
      print('⚠️ ProductViewModel.loadAllProducts - already loading, returning');
      return;
    }

    if (_currentPage == 1) {
      _setLoading(true);
      print(
        '🔄 ProductViewModel.loadAllProducts - set loading true for first page',
      );
    } else {
      _setLoadingMore(true);
      print(
        '🔄 ProductViewModel.loadAllProducts - set loading more true for page $_currentPage',
      );
    }

    _clearError();

    try {
      print(
        '🌐 ProductViewModel.loadAllProducts - calling getAllProducts with page: $page, limit: $limit',
      );
      final response = await _productService.getAllProducts(
        page: page,
        limit: limit,
      );

      print('📡 ProductViewModel.loadAllProducts - response received');
      print('📊 Response success: ${response.isSuccess}');
      print('📊 Response error: ${response.error}');
      print('📊 Response data length: ${response.data?.length ?? 0}');

      if (response.isSuccess && response.data != null) {
        final newProducts = response.data!;
        print(
          '✅ ProductViewModel.loadAllProducts - got ${newProducts.length} products',
        );

        if (_currentPage == 1) {
          _products = newProducts;
          print(
            '✅ ProductViewModel.loadAllProducts - set products for first page',
          );
        } else {
          _products.addAll(newProducts);
          print(
            '✅ ProductViewModel.loadAllProducts - added products to existing list',
          );
        }

        _hasMore = newProducts.length == AppConstants.defaultPageSize;
        _currentPage++;
        print(
          '✅ ProductViewModel.loadAllProducts - hasMore: $_hasMore, nextPage: $_currentPage',
        );
      } else {
        print(
          '❌ ProductViewModel.loadAllProducts - API error: ${response.error}',
        );
        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      print('💥 ProductViewModel.loadAllProducts - Exception: $e');
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);
      _setLoadingMore(false);
      print(
        '🏁 ProductViewModel.loadAllProducts completed - final products count: ${_products.length}',
      );
    }
  }

  Future<void> loadProducts({
    String? categoryId,
    String? searchQuery,
    String? city,
    String? condition,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _products.clear();
    }

    if (_isLoading || _isLoadingMore) return;

    _currentCategoryId = categoryId;
    _currentSearchQuery = searchQuery;
    _currentCity = city;
    _currentCondition = condition;

    if (_currentPage == 1) {
      _setLoading(true);
    } else {
      _setLoadingMore(true);
    }

    _clearError();

    try {
      final response = await _productService.getProducts(
        page: _currentPage,
        limit: AppConstants.defaultPageSize,
        categoryId: categoryId,
        searchQuery: searchQuery,
        city: city,
        condition: condition,
        sortBy: _currentSortOption.value,
      );

      if (response.isSuccess && response.data != null) {
        final newProducts = response.data!;

        if (_currentPage == 1) {
          _products = newProducts;
        } else {
          _products.addAll(newProducts);
        }

        _hasMore = newProducts.length == AppConstants.defaultPageSize;
        _currentPage++;
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);
      _setLoadingMore(false);
    }
  }

  Future<void> loadMoreProducts() async {
    if (!_hasMore || _isLoadingMore) return;

    await loadProducts(
      categoryId: _currentCategoryId,
      searchQuery: _currentSearchQuery,
      city: _currentCity,
      condition: _currentCondition,
    );
  }

  Future<void> refreshProducts() async {
    print('🔄 ProductViewModel.refreshProducts started');
    print(
      '🔄 ProductViewModel - Current _products.length: ${_products.length}',
    );
    try {
      await Future.wait([loadCategories(), loadAllProducts(refresh: true)]);
      print('✅ ProductViewModel.refreshProducts completed');
      print('✅ ProductViewModel - Final _products.length: ${_products.length}');
    } catch (e) {
      print('❌ refreshProducts error: $e');
      _errorMessage = 'Veri yenilenirken hata oluştu: $e';
      notifyListeners();
    }
  }

  Future<void> searchProducts(String query) async {
    _currentSearchQuery = query;
    notifyListeners();

    await loadProducts(
      categoryId: _currentCategoryId,
      searchQuery: query,
      city: _currentCity,
      condition: _currentCondition,
      refresh: true,
    );
  }

  Future<void> filterByCategory(String? categoryId) async {
    _currentCategoryId = categoryId;
    notifyListeners();

    await loadProducts(
      categoryId: categoryId,
      searchQuery: _currentSearchQuery,
      city: _currentCity,
      condition: _currentCondition,
      refresh: true,
    );
  }

  Future<void> sortProducts(SortOption sortOption) async {
    _currentSortOption = sortOption;
    notifyListeners();

    await loadProducts(
      categoryId: _currentCategoryId,
      searchQuery: _currentSearchQuery,
      city: _currentCity,
      condition: _currentCondition,
      refresh: true,
    );
  }

  Future<void> loadProductById(String productId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _productService.getProductById(productId);

      if (response.isSuccess && response.data != null) {
        _selectedProduct = response.data;

        // View count'u artır
        _productService.incrementViewCount(productId);
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMyProducts() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _productService.getMyProducts();

      if (response.isSuccess && response.data != null) {
        _myProducts = response.data!;
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);
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
    _setLoading(true);
    _clearError();

    try {
      final response = await _productService.getFavoriteProducts();

      if (response.isSuccess && response.data != null) {
        _favoriteProducts = response.data!;
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCategories() async {
    print('🏷️ Loading categories...');
    try {
      final response = await _productService.getCategories();
      print(
        '🏷️ Categories response: success=${response.isSuccess}, error=${response.error}',
      );

      if (response.isSuccess && response.data != null) {
        _categories = response.data ?? [];
        print('🏷️ Categories loaded: ${_categories.length} items');
        _categories.forEach((cat) => print('  - ${cat.name} (${cat.id})'));
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
    Location? location,
  }) async {
    if (title.trim().isEmpty || description.trim().isEmpty) {
      _setError(ErrorMessages.fieldRequired);
      return false;
    }

    if (images.isEmpty) {
      _setError('En az bir resim eklemelisiniz');
      return false;
    }

    if (tradePreferences.isEmpty) {
      _setError('Takas tercihlerinizi belirtmelisiniz');
      return false;
    }

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
        location: location,
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

  Future<bool> toggleFavorite(String productId) async {
    try {
      final isFavorite = _favoriteProducts.any((p) => p.id == productId);

      if (isFavorite) {
        final response = await _productService.removeFromFavorites(productId);
        if (response.isSuccess) {
          _favoriteProducts.removeWhere((p) => p.id == productId);
          notifyListeners();
          return true;
        }
      } else {
        final response = await _productService.addToFavorites(productId);
        if (response.isSuccess) {
          // Favorilere eklenen ürünü bulup listeye ekle
          final product = _products.firstWhere((p) => p.id == productId);
          _favoriteProducts.add(product);
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  bool isFavorite(String productId) {
    return _favoriteProducts.any((p) => p.id == productId);
  }

  void clearSelectedProduct() {
    _selectedProduct = null;
    notifyListeners();
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

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
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
        final message = responseData['message']?.toString() ?? 'Ürün eklendi';

        print('✅ Product added successfully!');
        print('🆔 Product ID: $productId');
        print('💬 Message: $message');

        // Başarılı olduktan sonra ürün listesini yenile
        print('🔄 Refreshing products...');
        await refreshProducts();
        return true;
      } else {
        print('❌ Product add failed: ${response.error}');
        _setError(response.error ?? 'Ürün eklenemedi');
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

  // Yeni addProductWithEndpoint method'u kullanıcının verdiği endpoint için
  Future<bool> addProductWithEndpoint({
    required String productTitle,
    required String productDescription,
    required String categoryId,
    required String conditionId,
    required String tradeFor,
    required List<File> productImages,
  }) async {
    print('🚀 addProductWithEndpoint başlatıldı');
    print('📝 Parametreler:');
    print('  - productTitle: $productTitle');
    print('  - productDescription: $productDescription');
    print('  - categoryId: $categoryId');
    print('  - conditionId: $conditionId');
    print('  - tradeFor: $tradeFor');
    print('  - productImages count: ${productImages.length}');

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

    // Resim durumu kontrolü
    if (productImages.isNotEmpty) {
      print('📸 ${productImages.length} resim yüklenecek:');
      for (int i = 0; i < productImages.length; i++) {
        print('  ${i + 1}. ${productImages[i].path.split('/').last}');
      }
    } else {
      print('⚠️ Warning: Resim yok, devam ediliyor...');
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
      );

      print('📡 API response alındı');
      print('📊 Response success: ${response.isSuccess}');
      print('📊 Response error: ${response.error}');
      print('📊 Response data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        final responseData = response.data!;
        final productId = responseData['productID']?.toString() ?? 'unknown';
        final message = responseData['message']?.toString() ?? 'Ürün eklendi';

        print('✅ Product added successfully!');
        print('🆔 Product ID: $productId');
        print('💬 Message: $message');

        // Başarılı olduktan sonra ürün listesini yenile
        print('🔄 Refreshing products...');
        await refreshProducts();
        return true;
      } else {
        print('❌ Product add failed: ${response.error}');
        _setError(response.error ?? 'Ürün eklenemedi');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Product add exception: $e');
      print('❌ Stack trace: $stackTrace');
      _setError('Ürün eklenirken hata oluştu: $e');
      return false;
    } finally {
      print('🏁 Loading state false yapılıyor...');
      _setLoading(false);
      print('🏁 addProductWithEndpoint tamamlandı');
    }
  }

  // Yeni filtreleme metodları
  Future<void> applyFilter(ProductFilter filter) async {
    print('🔍 ProductViewModel.applyFilter - New filter: $filter');
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

      print('📡 ProductViewModel.applyFilter - response received');
      print('📊 Response success: ${response.isSuccess}');
      print('📊 Response data length: ${response.data?.length ?? 0}');

      if (response.isSuccess && response.data != null) {
        final newProducts = response.data!;
        print(
          '✅ ProductViewModel.applyFilter - got ${newProducts.length} products',
        );

        _products = newProducts;
        _hasMore = newProducts.length == AppConstants.defaultPageSize;
        _currentPage = 2;

        print('✅ ProductViewModel.applyFilter - hasMore: $_hasMore');
      } else {
        print('❌ ProductViewModel.applyFilter - API error: ${response.error}');
        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      print('💥 ProductViewModel.applyFilter - Exception: $e');
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);
      print(
        '🏁 ProductViewModel.applyFilter completed - final products count: ${_products.length}',
      );
    }
  }

  Future<void> clearFilters() async {
    print('🔄 ProductViewModel.clearFilters - Clearing all filters');
    _currentFilter = const ProductFilter();
    await loadAllProducts(refresh: true);
  }

  Future<void> loadMoreFilteredProducts() async {
    if (!_hasMore || _isLoadingMore) return;

    print(
      '🔄 ProductViewModel.loadMoreFilteredProducts - Loading page $_currentPage',
    );
    _setLoadingMore(true);

    try {
      final response = await _productService.getAllProductsWithFilter(
        filter: _currentFilter,
        page: _currentPage,
        limit: AppConstants.defaultPageSize,
      );

      if (response.isSuccess && response.data != null) {
        final newProducts = response.data!;
        print(
          '✅ ProductViewModel.loadMoreFilteredProducts - got ${newProducts.length} more products',
        );

        _products.addAll(newProducts);
        _hasMore = newProducts.length == AppConstants.defaultPageSize;
        _currentPage++;
      } else {
        print(
          '❌ ProductViewModel.loadMoreFilteredProducts - API error: ${response.error}',
        );
        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      print('💥 ProductViewModel.loadMoreFilteredProducts - Exception: $e');
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoadingMore(false);
    }
  }

  Future<bool> _verifyDeletion(String productId, {int retries = 3, Duration delay = const Duration(seconds: 1)}) async {
    for (int i = 0; i < retries; i++) {
      print('🔍 Verification attempt #${i + 1} for product $productId...');
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) return false; // Should not happen

      await loadUserProducts(currentUser.id);
      final productStillExists = _myProducts.any((p) => p.id == productId);

      if (!productStillExists) {
        return true; // Verified!
      }

      print('⚠️ Product $productId still exists, waiting for ${delay * (i + 1)}...');
      await Future.delayed(delay * (i + 1)); // Increasing delay
    }
    return false; // Failed after all retries
  }

  @override
  void dispose() {
    super.dispose();
  }
}
