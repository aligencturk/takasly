import 'dart:io';
import '../core/http_client.dart';
import '../core/constants.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../models/city.dart';
import '../models/district.dart';

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
      final endpoint = 'service/user/product/$userId/productList';
      print('🌐 ProductService - Calling endpoint: $endpoint');
      print('🌐 ProductService - Full URL: ${ApiConstants.fullUrl}$endpoint');
      print('🌐 ProductService - Base URL: ${ApiConstants.baseUrl}');
      
      // Çalışan categories endpoint ile karşılaştırma için
      print('🔍 Categories endpoint for comparison: ${ApiConstants.categoriesList}');
      
      // Basic auth ile dene (endpoint basic auth gerektiriyor)
      final response = await _httpClient.getWithBasicAuth(
        endpoint,
        fromJson: (json) {
          print('🔍 ProductService - Raw response: $json');
          // API'den dönen response formatına göre parsing
          if (json case {'data': {'products': final List<dynamic> list}}) {
            print('🔍 ProductService - Found ${list.length} products in response');
            final products = list.map((item) => _transformApiProductToModel(item)).toList();
            print('🔍 ProductService - Successfully parsed ${products.length} products');
            return products;
          }
          // Fallback: Diğer olası formatlar
          if (json case {'data': {'userProductList': final List<dynamic> list}}) {
            print('🔍 ProductService - Found ${list.length} products in userProductList');
            final products = list.map((item) => _transformApiProductToModel(item)).toList();
            print('🔍 ProductService - Successfully parsed ${products.length} products');
            return products;
          }
          if (json case {'products': final List<dynamic> list}) {
            print('🔍 ProductService - Found ${list.length} products in root');
            final products = list.map((item) => _transformApiProductToModel(item)).toList();
            print('🔍 ProductService - Successfully parsed ${products.length} products');
            return products;
          }
          print('❌ ProductService - No products found in response');
          return <Product>[];
        },
      );

      return response;
    } catch (e) {
      print('💥 ProductService - Exception in getProductsByUserId: $e');
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  // API response'unu Product model formatına dönüştürür
  Product _transformApiProductToModel(Map<String, dynamic> apiProduct) {
    final categoryId = apiProduct['productCatID']?.toString() ?? '';
    final categoryName = apiProduct['productCatname'] ?? '';
    
    print('🏷️ Transforming product with category ID: $categoryId, name: $categoryName');
    
    return Product(
      id: apiProduct['productID']?.toString() ?? '',
      title: apiProduct['productTitle'] ?? '',
      description: apiProduct['productDesc'] ?? '',
      images: apiProduct['productImage'] != null && apiProduct['productImage'].isNotEmpty 
          ? [apiProduct['productImage']] 
          : [],
      categoryId: categoryId,
      category: Category(
        id: categoryId,
        name: categoryName,
        icon: '',
        isActive: true,
        order: 0,
      ),
      condition: apiProduct['productCondition'] ?? '',
      ownerId: '', // API'de owner bilgisi yok, boş bırakıyoruz
      owner: User(
        id: '',
        name: 'Kullanıcı',
        email: '',
        rating: 0.0,
        totalTrades: 0,
        isVerified: false,
        isOnline: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      tradePreferences: apiProduct['productTradeFor'] != null 
          ? [apiProduct['productTradeFor']] 
          : [],
      status: ProductStatus.active,
      viewCount: 0,
      favoriteCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
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

  Future<ApiResponse<List<City>>> getCities() async {
    print('🏙️ ProductService: Getting cities from service/general/general/cities/all');
    final fullUrl = '${ApiConstants.fullUrl}service/general/general/cities/all';
    print('🌐 Full URL: $fullUrl');
    
    try {
      final response = await _httpClient.getWithBasicAuth(
        'service/general/general/cities/all',
        fromJson: (json) {
          print('🔍 Raw Cities API Response: $json');
          
          // JSON yapısını kontrol et
          if (json == null) {
            print('❌ Cities API response is null');
            return <City>[];
          }
          
          if (json['data'] == null) {
            print('❌ Cities API response has no data field');
            print('🔍 Available fields: ${json.keys}');
            return <City>[];
          }
          
          if (json['data']['cities'] == null) {
            print('❌ Cities API response has no cities field in data');
            print('🔍 Available data fields: ${json['data'].keys}');
            return <City>[];
          }
          
          final citiesList = json['data']['cities'] as List;
          print('🏙️ Cities API returned ${citiesList.length} cities');
          
          // İlk birkaç şehri logla
          if (citiesList.isNotEmpty) {
            print('🏙️ First 5 cities in API response:');
            for (int i = 0; i < (citiesList.length > 5 ? 5 : citiesList.length); i++) {
              final city = citiesList[i];
              print('  ${i + 1}. ${city['cityName']} (ID: ${city['cityID']}, Plate: ${city['plateCode']})');
            }
          }
          
                     final cities = citiesList.map((item) => City.fromJson(item)).toList();
          
          print('🏙️ Parsed ${cities.length} cities successfully');
          return cities;
        },
      );

      return response;
    } catch (e) {
      print('❌ ProductService: Error getting cities: $e');
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<List<District>>> getDistricts(String cityId) async {
    print('🏘️ ProductService: Getting districts for city $cityId from service/general/general/districts/$cityId');
    try {
      final response = await _httpClient.getWithBasicAuth(
        'service/general/general/districts/$cityId',
        fromJson: (json) {
          print('🏘️ Raw districts response: $json');
          
          // Farklı yanıt formatlarını kontrol et
          if (json['data'] != null && json['data']['districts'] != null) {
            final districtsList = json['data']['districts'] as List;
            print('🏘️ Districts API returned ${districtsList.length} districts');
            
            // İlk birkaç ilçeyi logla
            if (districtsList.isNotEmpty) {
              print('🏘️ First 5 districts in API response:');
              for (int i = 0; i < (districtsList.length > 5 ? 5 : districtsList.length); i++) {
                final district = districtsList[i];
                print('  ${i + 1}. ${district['districtName']} (No: ${district['districtNo']})');
              }
            }
            
            return districtsList
                .map((item) => District.fromJson(item, cityId: cityId))
                .toList();
          } else if (json['districts'] != null) {
            final districtsList = json['districts'] as List;
            return districtsList
                .map((item) => District.fromJson(item, cityId: cityId))
                .toList();
          } else {
            print('🏘️ No districts found in response format');
            return <District>[];
          }
        },
      );

      return response;
    } catch (e) {
      print('❌ ProductService: Error getting districts for city $cityId: $e');
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
      final endpoint = '${ApiConstants.userProducts}/$userId/productList';
      print('🔄 ProductService.getUserProducts called with userId: $userId');
      print('🔄 ProductService - calling endpoint: $endpoint');
      
      final response = await _httpClient.getWithBasicAuth(
        endpoint,
        fromJson: (json) {
          print('🔍 ProductService - Raw response: $json');
          
          if (json == null) {
            print('❌ ProductService - Response is null');
            return <Product>[];
          }
          
          // API response'u data field'ının içinde products array'i var
          if (json['data'] == null) {
            print('❌ ProductService - No data field in response');
            return <Product>[];
          }
          
          final dataField = json['data'];
          if (dataField['products'] == null) {
            print('❌ ProductService - No products field in data');
            return <Product>[];
          }
          
          final productsList = dataField['products'] as List;
          print('🔍 ProductService - Found ${productsList.length} products in response');
          
          // API response'unu Product model'ine uygun hale getir
          return productsList.map((apiProduct) {
            print('🔄 ProductService - Converting API product: $apiProduct');
            
            // API field'larından Product model'i için gerekli field'ları oluştur
            final productData = {
              'id': apiProduct['productID']?.toString() ?? '',
              'title': apiProduct['productTitle'] ?? '',
              'description': apiProduct['productDesc'] ?? '',
              'images': [
                if (apiProduct['productImage'] != null && apiProduct['productImage'].toString().isNotEmpty)
                  apiProduct['productImage'].toString(),
                ...(apiProduct['extraImages'] as List? ?? []).map((img) => img.toString()),
              ],
              'categoryId': apiProduct['productCatID']?.toString() ?? '',
              'category': {
                'id': apiProduct['productCatID']?.toString() ?? '',
                'name': apiProduct['productCatname'] ?? '',
                'icon': 'category',
              },
              'condition': apiProduct['productCondition'] ?? '',
              'brand': null,
              'model': null,
              'estimatedValue': null,
              'ownerId': '2', // Kullanıcının kendi ürünü olduğu için
              'owner': {
                'id': '2',
                'name': 'Kullanıcı',
                'email': 'user@example.com',
                'rating': 0.0,
                'totalTrades': 0,
                'isVerified': false,
                'isOnline': true,
                'createdAt': DateTime.now().toIso8601String(),
                'updatedAt': DateTime.now().toIso8601String(),
              },
              'tradePreferences': [apiProduct['productTradeFor'] ?? ''],
              'status': 'active',
              'location': null,
              'viewCount': 0,
              'favoriteCount': 0,
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
              'expiresAt': null,
            };
            
            print('🔄 ProductService - Converted product data: $productData');
            return Product.fromJson(productData);
          }).toList();
        },
      );

      print('🔍 ProductService - Response isSuccess: ${response.isSuccess}');
      print('🔍 ProductService - Response error: ${response.error}');
      
      return response;
    } catch (e) {
      print('💥 ProductService - Exception in getUserProducts: $e');
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

} 