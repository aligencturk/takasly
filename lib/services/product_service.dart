import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/http_client.dart';
import '../core/constants.dart';
import '../models/product.dart';
import '../models/product_filter.dart';
import '../models/user.dart';
import '../models/city.dart';
import '../models/district.dart';
import '../models/condition.dart';
import '../services/location_service.dart';

class ProductService {
  final HttpClient _httpClient = HttpClient();
  static const String _tag = 'ProductService';

  Future<ApiResponse<List<Product>>> getAllProducts({
    int page = 1,
    int limit = AppConstants.defaultPageSize,
  }) async {
    try {
      print(
        '🌐 ProductService: Getting all products from ${ApiConstants.allProducts}',
      );
      final fullUrl = '${ApiConstants.fullUrl}${ApiConstants.allProducts}';
      print('🌐 Full URL: $fullUrl');

      // POST request ile dene (API POST method kullanıyor)
      print('🌐 Using POST method with Basic Auth');

      // User token'ı al
      String userToken = '';
      try {
        final prefs = await SharedPreferences.getInstance();
        userToken = prefs.getString(AppConstants.userTokenKey) ?? '';
        print(
          '🔑 User token retrieved: ${userToken.isNotEmpty ? "${userToken.substring(0, 20)}..." : "empty"}',
        );
      } catch (e) {
        print('⚠️ Error getting user token: $e');
      }

      // POST body hazırla
      final body = {
        'userToken': userToken,
        'categoryID': 0,
        'conditionIDs': [],
        'cityID': 0,
        'districtID': 0,
        'userLat': '',
        'userLong': '',
        'sortType': 'default',
        'page': page,
      };
      print('🌐 POST Body: $body');

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.allProducts,
        body: body,
        useBasicAuth: true,
        fromJson: (json) {
          print('🔍 Raw All Products API Response: $json');
          print('🔍 Response type: ${json.runtimeType}');
          print(
            '🔍 Response keys: ${json is Map ? json.keys.toList() : 'Not a Map'}',
          );

          // JSON yapısını kontrol et
          if (json == null) {
            print('❌ All Products API response is null');
            return <Product>[];
          }

          if (json['data'] == null) {
            print('❌ All Products API response has no data field');
            print('🔍 Available fields: ${json.keys}');

            // Alternatif formatları kontrol et
            if (json['products'] != null) {
              print('🔍 Found products field directly in root');
              final productsList = json['products'] as List;
              print(
                '📦 Direct products API returned ${productsList.length} products',
              );
              final products = productsList
                  .map((item) => _transformApiProductToModel(item))
                  .toList();
              print('📦 Parsed ${products.length} products successfully');
              return products;
            }

            // Eğer response direkt bir liste ise
            if (json is List) {
              print('🔍 Response is directly a list with ${json.length} items');
              final products = json
                  .map((item) => _transformApiProductToModel(item))
                  .toList();
              print('📦 Parsed ${products.length} products successfully');
              return products;
            }

            return <Product>[];
          }

          if (json['data']['products'] == null) {
            print('❌ All Products API response has no products field in data');
            print('🔍 Available data fields: ${json['data'].keys}');
            return <Product>[];
          }

          final productsList = json['data']['products'] as List;
          print('📦 All Products API returned ${productsList.length} products');

          // İlk birkaç ürünü logla
          if (productsList.isNotEmpty) {
            print('📦 First 3 products in API response:');
            for (
              int i = 0;
              i < (productsList.length > 3 ? 3 : productsList.length);
              i++
            ) {
              final product = productsList[i];
              print(
                '  ${i + 1}. ${product['productTitle']} (ID: ${product['productID']})',
              );
            }
          }

          final products = productsList
              .map((item) => _transformNewApiProductToModel(item))
              .toList();

          print('📦 Parsed ${products.length} products successfully');
          return products;
        },
      );

      return response;
    } catch (e) {
      print('❌ ProductService: Error getting all products: $e');
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<List<Product>>> getAllProductsWithFilter({
    required ProductFilter filter,
    int page = 1,
    int limit = AppConstants.defaultPageSize,
  }) async {
    try {
      print('🔍 ProductService: Getting filtered products');
      print('🔍 Filter: $filter');
      final fullUrl = '${ApiConstants.fullUrl}${ApiConstants.allProducts}';
      print('🌐 Full URL: $fullUrl');

      // User token'ı al
      String userToken = '';
      try {
        final prefs = await SharedPreferences.getInstance();
        userToken = prefs.getString(AppConstants.userTokenKey) ?? '';
        print(
          '🔑 User token retrieved: ${userToken.isNotEmpty ? "${userToken.substring(0, 20)}..." : "empty"}',
        );
      } catch (e) {
        print('⚠️ Error getting user token: $e');
      }

      // Konum bilgilerini al (eğer location sorting seçiliyse)
      String? userLat;
      String? userLong;

      if (filter.sortType == 'location') {
        print('📍 Location sorting requested, getting user location...');
        final locationService = LocationService();
        final locationData = await locationService
            .getCurrentLocationAsStrings();

        if (locationData != null) {
          userLat = locationData['latitude'];
          userLong = locationData['longitude'];
          print('📍 Location obtained: $userLat, $userLong');
        } else {
          print('❌ Could not get user location, using default sorting');
          // Konum alınamazsa varsayılan sıralamaya geç
          filter = filter.copyWith(sortType: 'default');
        }
      }

      // Filter'dan API body'sini oluştur
      final body = filter.toApiBody(
        userToken: userToken,
        page: page,
        userLat: userLat,
        userLong: userLong,
      );
      print('🌐 POST Body with filter: $body');

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.allProducts,
        body: body,
        useBasicAuth: true,
        fromJson: (json) {
          print('🔍 Raw Filtered Products API Response: $json');

          // JSON yapısını kontrol et
          if (json == null) {
            print('❌ Filtered Products API response is null');
            return <Product>[];
          }

          // Yeni API formatını kontrol et
          if (json case {
            'success': true,
            'data': final Map<String, dynamic> data,
          }) {
            if (data['products'] case final List<dynamic> productsList) {
              print(
                '📦 Filtered Products API returned ${productsList.length} products (new format)',
              );
              print(
                '📦 Page info: ${data['page']}/${data['totalPages']}, Total: ${data['totalItems']}',
              );

              final products = productsList
                  .map((item) => _transformNewApiProductToModel(item))
                  .toList();

              print(
                '📦 Parsed ${products.length} filtered products successfully',
              );
              return products;
            }
          }

          // 410 status code için özel handling
          if (json case {'error': false, '410': 'Gone'}) {
            print(
              '🔍 ProductService - 410 Gone response for filtered products',
            );
            if (json['data'] != null && json['data']['products'] != null) {
              final productsList = json['data']['products'] as List;
              print(
                '📦 410 response returned ${productsList.length} filtered products',
              );
              final products = productsList
                  .map((item) => _transformNewApiProductToModel(item))
                  .toList();
              print(
                '📦 Parsed ${products.length} filtered products successfully from 410',
              );
              return products;
            }
            return <Product>[];
          }

          // Boş success response
          if (json case {'error': false, '200': 'OK'}) {
            print(
              '🔍 ProductService - Empty success response for filtered products',
            );
            return <Product>[];
          }

          print('❌ Filtered Products API - No products found in response');
          print('❌ Available keys: ${json.keys.toList()}');
          return <Product>[];
        },
      );

      return response;
    } catch (e) {
      print('❌ ProductService: Error getting filtered products: $e');
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<List<Product>>> getProducts({
    int page = 1,
    int limit = AppConstants.defaultPageSize,
    String? categoryId,
    String? searchQuery,
    String? city,
    String? condition,
    String? sortBy, // Sıralama parametresi eklendi
    double? maxDistance,
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (searchQuery != null) queryParams['search'] = searchQuery;
      if (city != null) queryParams['city'] = city;
      if (condition != null) queryParams['condition'] = condition;
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (maxDistance != null) queryParams['maxDistance'] = maxDistance;
      if (userLatitude != null) queryParams['userLatitude'] = userLatitude;
      if (userLongitude != null) queryParams['userLongitude'] = userLongitude;

      print(
        '🌐 ProductService - Getting all products from ${ApiConstants.allProducts}',
      );
      print(
        '🌐 ProductService - Full URL: ${ApiConstants.fullUrl}${ApiConstants.allProducts}',
      );
      print('🌐 ProductService - Query params: $queryParams');
      final response = await _httpClient.getWithBasicAuth(
        ApiConstants.allProducts,
        queryParams: queryParams,
        fromJson: (json) {
          print('🔍 ProductService - All products raw response: $json');

          // Yeni API formatını kontrol et
          if (json case {
            'success': true,
            'data': final Map<String, dynamic> data,
          }) {
            if (data['products'] case final List<dynamic> productsList) {
              print(
                '🔍 ProductService - Found ${productsList.length} products in new format',
              );
              print(
                '🔍 ProductService - Page info: ${data['page']}/${data['totalPages']}, Total: ${data['totalItems']}',
              );

              final products = productsList
                  .map((item) => _transformNewApiProductToModel(item))
                  .toList();

              print(
                '🔍 ProductService - Successfully parsed ${products.length} products',
              );
              return products;
            }
          }

          // Eski format kontrolü (backward compatibility)
          if (json case {'data': {'products': final List<dynamic> list}}) {
            print(
              '🔍 ProductService - Found ${list.length} products in old format',
            );
            final products = list
                .map((item) => _transformApiProductToModel(item))
                .toList();
            return products;
          }

          // Eğer sadece success mesajı geliyorsa (ürün yok)
          if (json case {'error': false, '200': 'OK'}) {
            print(
              '🔍 ProductService - Empty success response, no products available',
            );
            return <Product>[];
          }

          // 410 status code için özel handling
          if (json case {'error': false, '410': 'Gone'}) {
            print(
              '🔍 ProductService - 410 Gone response, checking for products',
            );
            // 410 response'unda da ürünler olabilir, kontrol et
            if (json['data'] != null && json['data']['products'] != null) {
              final productsList = json['data']['products'] as List;
              print('📦 410 response returned ${productsList.length} products');
              final products = productsList
                  .map((item) => _transformNewApiProductToModel(item))
                  .toList();
              print(
                '📦 Parsed ${products.length} products successfully from 410',
              );
              return products;
            }
            return <Product>[];
          }

          print('❌ ProductService - No products found in response');
          print('❌ ProductService - Available keys: ${json.keys.toList()}');
          return <Product>[];
        },
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
      final endpoint = '${ApiConstants.userProducts}/$userId/productList';
      print(
        '🌐 ProductService - ApiConstants.userProducts: ${ApiConstants.userProducts}',
      );
      print('🌐 ProductService - User ID: $userId');
      print('🌐 ProductService - Calling endpoint: $endpoint');
      print('🌐 ProductService - Base URL: ${ApiConstants.baseUrl}');
      print('🌐 ProductService - Full URL: ${ApiConstants.fullUrl}$endpoint');
      print(
        '🌐 ProductService - Expected Postman URL: https://api.rivorya.com/takasly/service/user/product/$userId/productList',
      );

      // Çalışan categories endpoint ile karşılaştırma için
      print(
        '🔍 Categories endpoint for comparison: ${ApiConstants.categoriesList}',
      );

      // Basic auth ile dene (endpoint basic auth gerektiriyor)
      final response = await _httpClient.getWithBasicAuth(
        endpoint,
        fromJson: (json) {
          print('🔍 ProductService - Raw response: $json');
          // API'den dönen response formatına göre parsing
          if (json case {'data': {'products': final List<dynamic> list}}) {
            print(
              '🔍 ProductService - Found ${list.length} products in response',
            );
            final products = list
                .map((item) => _transformApiProductToModel(item))
                .toList();
            print(
              '🔍 ProductService - Successfully parsed ${products.length} products',
            );
            return products;
          }
          // Fallback: Diğer olası formatlar
          if (json case {
            'data': {'userProductList': final List<dynamic> list},
          }) {
            print(
              '🔍 ProductService - Found ${list.length} products in userProductList',
            );
            final products = list
                .map((item) => _transformApiProductToModel(item))
                .toList();
            print(
              '🔍 ProductService - Successfully parsed ${products.length} products',
            );
            return products;
          }
          if (json case {'products': final List<dynamic> list}) {
            print('🔍 ProductService - Found ${list.length} products in root');
            final products = list
                .map((item) => _transformApiProductToModel(item))
                .toList();
            print(
              '🔍 ProductService - Successfully parsed ${products.length} products',
            );
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

  // Yeni API formatını Product model formatına dönüştürür
  Product _transformNewApiProductToModel(Map<String, dynamic> apiProduct) {
    print(
      '🔄 Transforming new API product: ${apiProduct['productTitle']} (ID: ${apiProduct['productID']})',
    );

    // Resim URL'ini debug et
    final imageUrl = apiProduct['productImage'];
    print('🖼️ Product image URL: $imageUrl');
    print('🖼️ Image URL type: ${imageUrl.runtimeType}');
    print('🖼️ Image URL isEmpty: ${imageUrl?.toString().isEmpty ?? true}');

    final images =
        apiProduct['productImage'] != null &&
            apiProduct['productImage'].toString().isNotEmpty
        ? <String>[apiProduct['productImage'].toString()]
        : <String>[];

    print('🖼️ Final images array: $images');

    return Product(
      id: apiProduct['productID']?.toString() ?? '',
      title: apiProduct['productTitle'] ?? '',
      description: apiProduct['productDesc'] ?? '',
      images: images,
      categoryId: apiProduct['categoryID']?.toString() ?? '',
      category: Category(
        id: apiProduct['categoryID']?.toString() ?? '',
        name: '', // Kategori adı ayrı endpoint'ten gelecek
        icon: '',
        isActive: true,
        order: 0,
      ),
      condition: apiProduct['productCondition'] ?? '',
      ownerId: apiProduct['userID']?.toString() ?? '',
      owner: User(
        id: apiProduct['userID']?.toString() ?? '',
        name: apiProduct['userFullname'] ?? 'Kullanıcı',
        firstName: apiProduct['userFirstname'],
        lastName: apiProduct['userLastname'],
        email: '', // API'de email yok
        rating: 0.0,
        totalTrades: 0,
        isVerified: false,
        isOnline: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      tradePreferences: [], // API'de trade preferences yok
      status: ProductStatus.active,
      location:
          apiProduct['cityTitle'] != null || apiProduct['districtTitle'] != null
          ? Location(
              address:
                  '${apiProduct['cityTitle'] ?? ''} ${apiProduct['districtTitle'] ?? ''}'
                      .trim(),
              city: apiProduct['cityTitle'] ?? '',
              district: apiProduct['districtTitle'] ?? '',
              country: 'Türkiye',
              latitude: apiProduct['productLat']?.toDouble(),
              longitude: apiProduct['productLong']?.toDouble(),
            )
          : null,
      viewCount: 0,
      favoriteCount: 0,
      createdAt: _parseDate(apiProduct['createdAt']),
      updatedAt: DateTime.now(),
    );
  }

  // Tarih parsing metodu
  DateTime _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return DateTime.now();
    }

    try {
      // API'den gelen format: "13.07.2025"
      final parts = dateString.split('.');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      print('⚠️ Error parsing date: $dateString, error: $e');
    }

    return DateTime.now();
  }

  // Eski API formatını Product model formatına dönüştürür (backward compatibility)
  Product _transformApiProductToModel(Map<String, dynamic> apiProduct) {
    final categoryId = apiProduct['productCatID']?.toString() ?? '';
    final categoryName = apiProduct['productCatname'] ?? '';

    print(
      '🏷️ Transforming product with category ID: $categoryId, name: $categoryName',
    );

    return Product(
      id: apiProduct['productID']?.toString() ?? '',
      title: apiProduct['productTitle'] ?? '',
      description: apiProduct['productDesc'] ?? '',
      images:
          apiProduct['productImage'] != null &&
              apiProduct['productImage'].isNotEmpty
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

  Future<ApiResponse<Map<String, dynamic>>> deleteUserProduct({
    required String userToken,
    required String productId,
  }) async {
    print('🗑️ ProductService.deleteUserProduct called');
    print('📝 Parameters:');
    print('  - userToken: ${userToken.substring(0, 20)}...');
    print('  - userToken length: ${userToken.length}');
    print('  - userToken isEmpty: ${userToken.isEmpty}');
    print('  - productId: $productId');

    try {
      // Farklı endpoint formatlarını dene
      final List<String> possibleEndpoints = [
        'service/user/product/$productId/deleteProduct',
        'service/user/product/delete/$productId',
        'service/user/product/$productId/delete',
        'service/user/product/remove/$productId',
      ];

      final endpoint = possibleEndpoints[0]; // Şimdilik ilkini kullan
      print('🔍 Trying endpoint: $endpoint');
      print('🔍 Other possible endpoints to try:');
      for (int i = 1; i < possibleEndpoints.length; i++) {
        print('  - ${possibleEndpoints[i]}');
      }
      final fullUrl = '${ApiConstants.fullUrl}$endpoint';
      print('🌐 Full URL: $fullUrl');

      // API'nin beklediği format: {"userToken": "token", "productID": 1}
      final body = {
        'userToken': userToken,
        'productID': int.parse(productId), // API integer bekliyor
      };
      print('🌐 DELETE Body: $body');

      // DELETE method ile dene
      print('🔄 Trying DELETE method...');
      var response = await _httpClient.deleteWithBasicAuth<Map<String, dynamic>>(
        endpoint,
        body: body,
        fromJson: (json) {
          print('📥 ProductService.deleteUserProduct - Raw response: $json');
          print(
            '📥 ProductService.deleteUserProduct - Response type: ${json.runtimeType}',
          );

          // API response'unu detaylı analiz et
          if (json is Map<String, dynamic>) {
            print(
              '📥 ProductService.deleteUserProduct - Response keys: ${json.keys.toList()}',
            );

            // success field'ını kontrol et
            if (json.containsKey('success')) {
              print(
                '📥 ProductService.deleteUserProduct - Success field: ${json['success']}',
              );
            }

            // error field'ını kontrol et
            if (json.containsKey('error')) {
              print(
                '📥 ProductService.deleteUserProduct - Error field: ${json['error']}',
              );
            }

            // message field'ını kontrol et
            if (json.containsKey('message')) {
              print(
                '📥 ProductService.deleteUserProduct - Message field: ${json['message']}',
              );
            }

            // data field'ını kontrol et
            if (json.containsKey('data')) {
              print(
                '📥 ProductService.deleteUserProduct - Data field: ${json['data']}',
              );
              return json['data'] as Map<String, dynamic>;
            }
          }

          print(
            '📥 ProductService.deleteUserProduct - Using full json as response',
          );
          return json as Map<String, dynamic>;
        },
      );

      print('📡 ProductService.deleteUserProduct - Response received');
      print('📊 Response success: ${response.isSuccess}');
      print('📊 Response error: ${response.error}');
      print('📊 Response data: ${response.data}');

      // KRITIK: API response'unu detaylı analiz et
      if (response.isSuccess) {
        print('✅ API claims deletion was successful');
        if (response.data != null) {
          final data = response.data!;
          print('✅ Response data keys: ${data.keys.toList()}');

          // Başarı mesajlarını kontrol et
          if (data.containsKey('message')) {
            print('✅ API Message: "${data['message']}"');
          }
          if (data.containsKey('success')) {
            print('✅ API Success flag: ${data['success']}');
          }

          // Eğer API false success döndürüyorsa hata olarak işle
          if (data['success'] == false) {
            print('❌ API returned success=false, treating as error');
            final errorMsg = data['message'] ?? 'Ürün silinemedi';
            return ApiResponse.error(errorMsg.toString());
          }
        }
      } else {
        print('❌ API reports deletion failed');
      }

      return response;
    } catch (e, stackTrace) {
      print('❌ ProductService.deleteUserProduct - Exception: $e');
      print('❌ Stack trace: $stackTrace');
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<List<Category>>> getCategories() async {
    print(
      '🏷️ ProductService: Getting categories from ${ApiConstants.categoriesList}',
    );
    try {
      final response = await _httpClient.getWithBasicAuth(
        ApiConstants.categoriesList,
        fromJson: (json) => (json['data']['categories'] as List)
            .map(
              (item) => Category(
                id: item['catID'].toString(),
                name: item['catName'],
                icon: item['catImage'] ?? '',
                isActive: true,
                order: 0,
              ),
            )
            .toList(),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<List<City>>> getCities() async {
    print(
      '🏙️ ProductService: Getting cities from service/general/general/cities/all',
    );
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
            for (
              int i = 0;
              i < (citiesList.length > 5 ? 5 : citiesList.length);
              i++
            ) {
              final city = citiesList[i];
              print(
                '  ${i + 1}. ${city['cityName']} (ID: ${city['cityID']}, Plate: ${city['plateCode']})',
              );
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
    print(
      '🏘️ ProductService: Getting districts for city $cityId from service/general/general/districts/$cityId',
    );
    try {
      final response = await _httpClient.getWithBasicAuth(
        'service/general/general/districts/$cityId',
        fromJson: (json) {
          print('🏘️ Raw districts response: $json');

          // Farklı yanıt formatlarını kontrol et
          if (json['data'] != null && json['data']['districts'] != null) {
            final districtsList = json['data']['districts'] as List;
            print(
              '🏘️ Districts API returned ${districtsList.length} districts',
            );

            // İlk birkaç ilçeyi logla
            if (districtsList.isNotEmpty) {
              print('🏘️ First 5 districts in API response:');
              for (
                int i = 0;
                i < (districtsList.length > 5 ? 5 : districtsList.length);
                i++
              ) {
                final district = districtsList[i];
                print(
                  '  ${i + 1}. ${district['districtName']} (No: ${district['districtNo']})',
                );
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

  Future<ApiResponse<List<Condition>>> getConditions() async {
    print(
      '🏷️ ProductService: Getting conditions from service/general/general/productConditions',
    );
    final fullUrl =
        '${ApiConstants.fullUrl}service/general/general/productConditions';
    print('🌐 Full URL: $fullUrl');

    try {
      final response = await _httpClient.getWithBasicAuth(
        'service/general/general/productConditions',
        fromJson: (json) {
          print('🔍 Raw Conditions API Response: $json');

          // JSON yapısını kontrol et
          if (json == null) {
            print('❌ Conditions API response is null');
            return <Condition>[];
          }

          if (json['data'] == null) {
            print('❌ Conditions API response has no data field');
            print('🔍 Available fields: ${json.keys}');
            return <Condition>[];
          }

          if (json['data']['conditions'] == null) {
            print('❌ Conditions API response has no conditions field in data');
            print('🔍 Available data fields: ${json['data'].keys}');
            return <Condition>[];
          }

          final conditionsList = json['data']['conditions'] as List;
          print(
            '🏷️ Conditions API returned ${conditionsList.length} conditions',
          );

          // İlk birkaç durumu logla
          if (conditionsList.isNotEmpty) {
            print('🏷️ All conditions in API response:');
            for (int i = 0; i < conditionsList.length; i++) {
              final condition = conditionsList[i];
              print(
                '  ${i + 1}. ${condition['conditionName']} (ID: ${condition['conditionID']})',
              );
            }
          }

          final conditions = conditionsList
              .map((item) => Condition.fromJson(item))
              .toList();

          print('🏷️ Parsed ${conditions.length} conditions successfully');
          return conditions;
        },
      );

      return response;
    } catch (e) {
      print('❌ ProductService: Error getting conditions: $e');
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
    print('🚀 ProductService.addProduct called');
    print('📝 Parameters:');
    print('  - userToken: ${userToken.substring(0, 20)}...');
    print('  - userId: $userId');
    print('  - productTitle: $productTitle');
    print('  - productDescription: $productDescription');
    print('  - categoryId: $categoryId');
    print('  - conditionId: $conditionId');
    print('  - tradeFor: $tradeFor');
    print('  - productImages count: ${productImages.length}');

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

      print('📋 Form fields prepared:');
      fields.forEach((key, value) {
        if (key == 'userToken') {
          print('  - $key: ${value.substring(0, 20)}...');
        } else {
          print('  - $key: $value');
        }
      });

      // Multiple files için Map oluştur
      final multipleFiles = <String, List<File>>{};
      if (productImages.isNotEmpty) {
        multipleFiles['productImages'] = productImages;
        print('📸 Multiple files prepared:');
        for (int i = 0; i < productImages.length; i++) {
          print('  - Image ${i + 1}: ${productImages[i].path.split('/').last}');
        }
      } else {
        print('📸 No images to upload');
      }

      print(
        '📸 Uploading ${productImages.length} images with key "productImages"',
      );

      final endpoint = '${ApiConstants.addProduct}/$userId/addProduct';
      final fullUrl = '${ApiConstants.fullUrl}$endpoint';
      print('🌐 Full URL: $fullUrl');

      final response = await _httpClient.postMultipart<Map<String, dynamic>>(
        endpoint,
        fields: fields,
        multipleFiles: multipleFiles,
        fromJson: (json) {
          print('📥 ProductService.addProduct - Raw response: $json');

          // API response'unda data field'ı varsa onu döndür, yoksa tüm json'u döndür
          if (json.containsKey('data') && json['data'] != null) {
            print('📥 ProductService.addProduct - Using data field');
            return json['data'] as Map<String, dynamic>;
          }
          print('📥 ProductService.addProduct - Using full json');
          return json;
        },
        useBasicAuth: true,
      );

      print('📡 ProductService.addProduct - Response received');
      print('📊 Response success: ${response.isSuccess}');
      print('📊 Response error: ${response.error}');
      print('📊 Response data: ${response.data}');

      return response;
    } catch (e, stackTrace) {
      print('❌ ProductService.addProduct - Exception: $e');
      print('❌ Stack trace: $stackTrace');
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
          print(
            '🔍 ProductService - Found ${productsList.length} products in response',
          );

          // API response'unu Product model'ine uygun hale getir
          return productsList.map((apiProduct) {
            print('🔄 ProductService - Converting API product: $apiProduct');

            // API field'larından Product model'i için gerekli field'ları oluştur
            final productData = {
              'id': apiProduct['productID']?.toString() ?? '',
              'title': apiProduct['productTitle'] ?? '',
              'description': apiProduct['productDesc'] ?? '',
              'images': [
                if (apiProduct['productImage'] != null &&
                    apiProduct['productImage'].toString().isNotEmpty)
                  apiProduct['productImage'].toString(),
                ...(apiProduct['extraImages'] as List? ?? []).map(
                  (img) => img.toString(),
                ),
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
