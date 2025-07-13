import 'dart:io';
import '../core/http_client.dart';
import '../core/constants.dart';
import '../models/product.dart';
import '../models/user.dart';

class ProductService {
  final HttpClient _httpClient = HttpClient();
  static const String _tag = 'ProductService';

  Future<ApiResponse<List<Product>>> getProducts({
    int page = 1,
    int limit = AppConstants.defaultPageSize,
    String? categoryId,
    String? searchQuery,
    String? city,
    String? condition,
    double? maxDistance,
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (searchQuery != null) queryParams['search'] = searchQuery;
      if (city != null) queryParams['city'] = city;
      if (condition != null) queryParams['condition'] = condition;
      if (maxDistance != null) queryParams['maxDistance'] = maxDistance;
      if (userLatitude != null) queryParams['userLatitude'] = userLatitude;
      if (userLongitude != null) queryParams['userLongitude'] = userLongitude;

      final response = await _httpClient.get(
        ApiConstants.products,
        queryParams: queryParams,
        fromJson: (json) => (json['products'] as List)
            .map((item) => Product.fromJson(item))
            .toList(),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<Product>> getProductById(String productId) async {
    try {
      final response = await _httpClient.get(
        '${ApiConstants.products}/$productId',
        fromJson: (json) => Product.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<List<Product>>> getProductsByUserId(String userId) async {
    try {
      final response = await _httpClient.get(
        '${ApiConstants.users}/$userId/products',
        fromJson: (json) => (json['products'] as List)
            .map((item) => Product.fromJson(item))
            .toList(),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<List<Product>>> getMyProducts() async {
    try {
      final response = await _httpClient.get(
        '${ApiConstants.products}/my',
        fromJson: (json) => (json['products'] as List)
            .map((item) => Product.fromJson(item))
            .toList(),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<Product>> createProduct({
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
    try {
      final body = {
        'title': title,
        'description': description,
        'images': images,
        'categoryId': categoryId,
        'condition': condition,
        'tradePreferences': tradePreferences,
      };

      if (brand != null) body['brand'] = brand;
      if (model != null) body['model'] = model;
      if (estimatedValue != null) body['estimatedValue'] = estimatedValue;
      if (location != null) body['location'] = location.toJson();

      final response = await _httpClient.post(
        ApiConstants.products,
        body: body,
        fromJson: (json) => Product.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<Product>> updateProduct(
    String productId, {
    String? title,
    String? description,
    List<String>? images,
    String? categoryId,
    String? condition,
    String? brand,
    String? model,
    double? estimatedValue,
    List<String>? tradePreferences,
    Location? location,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (images != null) body['images'] = images;
      if (categoryId != null) body['categoryId'] = categoryId;
      if (condition != null) body['condition'] = condition;
      if (brand != null) body['brand'] = brand;
      if (model != null) body['model'] = model;
      if (estimatedValue != null) body['estimatedValue'] = estimatedValue;
      if (tradePreferences != null) body['tradePreferences'] = tradePreferences;
      if (location != null) body['location'] = location.toJson();

      final response = await _httpClient.put(
        '${ApiConstants.products}/$productId',
        body: body,
        fromJson: (json) => Product.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<void>> deleteProduct(String productId) async {
    try {
      final response = await _httpClient.delete(
        '${ApiConstants.products}/$productId',
        fromJson: (json) => null,
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<List<Category>>> getCategories() async {
    print('🏷️ ProductService: Getting categories from ${ApiConstants.categoriesList}');
    try {
      final response = await _httpClient.getWithBasicAuth(
        ApiConstants.categoriesList,
        fromJson: (json) => (json['data']['categories'] as List)
            .map((item) => Category(
              id: item['catID'].toString(),
              name: item['catName'],
              icon: item['catImage'] ?? '',
              isActive: true,
              order: 0,
            ))
            .toList(),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<void>> addToFavorites(String productId) async {
    try {
      final response = await _httpClient.post(
        '${ApiConstants.products}/$productId/favorite',
        fromJson: (json) => null,
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<void>> removeFromFavorites(String productId) async {
    try {
      final response = await _httpClient.delete(
        '${ApiConstants.products}/$productId/favorite',
        fromJson: (json) => null,
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<List<Product>>> getFavoriteProducts() async {
    try {
      final response = await _httpClient.get(
        '${ApiConstants.products}/favorites',
        fromJson: (json) => (json['products'] as List)
            .map((item) => Product.fromJson(item))
            .toList(),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<void>> incrementViewCount(String productId) async {
    try {
      final response = await _httpClient.post(
        '${ApiConstants.products}/$productId/view',
        fromJson: (json) => null,
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> addProduct({
    required String userToken,
    required String userId,
    required String productTitle,
    required String productDescription,
    required String categoryId,
    required String conditionId,
    required String tradeFor,
    required List<File> productImages,
  }) async {
    try {
      // Form fields
      final fields = <String, String>{
        'userToken': userToken,
        'productTitle': productTitle,
        'productDesc': productDescription,
        'categoryID': categoryId,
        'conditionID': conditionId,
        'tradeFor': tradeFor,
      };

      // Multiple files için Map oluştur
      final multipleFiles = <String, List<File>>{};
      if (productImages.isNotEmpty) {
        multipleFiles['productImages'] = productImages;
      }

      print('📸 Uploading ${productImages.length} images with key "productImages"');

      final response = await _httpClient.postMultipart<Map<String, dynamic>>(
        '${ApiConstants.addProduct}/$userId/addProduct',
        fields: fields,
        multipleFiles: multipleFiles,
        fromJson: (json) {
          // API response'unda data field'ı varsa onu döndür, yoksa tüm json'u döndür
          if (json.containsKey('data') && json['data'] != null) {
            return json['data'] as Map<String, dynamic>;
          }
          return json;
        },
        useBasicAuth: true,
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<List<Product>>> getUserProducts(String userId) async {
    try {
      final response = await _httpClient.getWithBasicAuth(
        '${ApiConstants.userProducts}/$userId/productList',
        fromJson: (json) => (json['products'] as List)
            .map((item) => Product.fromJson(item))
            .toList(),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

} 