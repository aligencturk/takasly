import 'package:flutter/foundation.dart';
import '../models/product.dart' as product_model;
import '../models/user.dart';
import '../services/product_service.dart';
import '../core/constants.dart';

class ProductViewModel extends ChangeNotifier {
  final ProductService _productService = ProductService();
  
  List<product_model.Product> _products = [];
  List<product_model.Product> _favoriteProducts = [];
  List<product_model.Product> _myProducts = [];
  List<product_model.Category> _categories = [];
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

  // Getters
  List<product_model.Product> get products => _products;
  List<product_model.Product> get favoriteProducts => _favoriteProducts;
  List<product_model.Product> get myProducts => _myProducts;
  List<product_model.Category> get categories => _categories;
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

  ProductViewModel() {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await Future.wait([
      loadProducts(),
      loadCategories(),
    ]);
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
    await loadProducts(
      categoryId: _currentCategoryId,
      searchQuery: _currentSearchQuery,
      city: _currentCity,
      condition: _currentCondition,
      refresh: true,
    );
  }

  Future<void> searchProducts(String query) async {
    await loadProducts(
      categoryId: _currentCategoryId,
      searchQuery: query,
      city: _currentCity,
      condition: _currentCondition,
      refresh: true,
    );
  }

  Future<void> filterByCategory(String? categoryId) async {
    await loadProducts(
      categoryId: categoryId,
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
    try {
      final response = await _productService.getCategories();

      if (response.isSuccess && response.data != null) {
        _categories = response.data!;
        notifyListeners();
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
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

  @override
  void dispose() {
    super.dispose();
  }
} 