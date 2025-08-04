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
import '../models/location.dart';
import '../services/location_service.dart';
import '../utils/logger.dart';

class ProductService {
  final HttpClient _httpClient = HttpClient();
  static const String _tag = 'ProductService';

  Future<ApiResponse<List<Product>>> getAllProducts({
    int page = 1,
    int limit = AppConstants.defaultPageSize,
  }) async {
    try {
      Logger.info(
        'Getting all products from ${ApiConstants.allProducts}',
        tag: _tag,
      );
      final fullUrl = '${ApiConstants.fullUrl}${ApiConstants.allProducts}';
      Logger.debug('Full URL: $fullUrl', tag: _tag);

      // POST request ile dene (API POST method kullanıyor)
      Logger.debug('Using POST method with Basic Auth', tag: _tag);

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
        'userLat': null,
        'userLong': null,
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
              // Kategori bilgilerini detaylı logla
              print('  🏷️ categoryID: ${product['categoryID']}');
              print('  🏷️ categoryTitle: ${product['categoryTitle']}');
              print('  🏷️ categoryList: ${product['categoryList']}');
              if (product['categoryList'] != null) {
                final categoryList = product['categoryList'] as List;
                print('  🏷️ categoryList length: ${categoryList.length}');
                for (int j = 0; j < categoryList.length; j++) {
                  final category = categoryList[j];
                  print('  🏷️ categoryList[$j]: $category');
                }
              }
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
      Logger.debug('POST Body with filter: $body', tag: _tag);

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
    String? searchText,
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
      if (searchText != null) queryParams['search'] = searchText;
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
      // POST ile ürün detayını al (API POST istiyor)
      final response = await _httpClient.postWithBasicAuth(
        '${ApiConstants.getProductById}/$productId',
        body: {'productID': int.tryParse(productId) ?? productId}, // Product ID'yi body'de gönder
        useBasicAuth: true,
        fromJson: (json) {
          print('🔍 getProductById - Raw response: $json');
          
          // API response formatını kontrol et
          if (json is Map<String, dynamic>) {
            // Eğer data field'ı varsa ve içinde product varsa
            if (json['data'] != null && json['data']['product'] != null) {
              return Product.fromJson(json['data']['product']);
            }
            // Eğer direkt product data'sı varsa
            if (json['product'] != null) {
              return Product.fromJson(json['product']);
            }
            // Eğer response direkt product data'sı ise
            try {
              return Product.fromJson(json);
            } catch (e) {
              print('❌ getProductById - Failed to parse as Product: $e');
              throw Exception('Ürün verisi parse edilemedi');
            }
          }
          throw Exception('Geçersiz API yanıtı');
        },
      );

      return response;
    } catch (e) {
      print('❌ getProductById - Exception: $e');
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  /// Ürün detayını getirir (410: başarı, 417: hata)
  Future<ApiResponse<Product>> getProductDetail({
    required String userToken,
    required String productId,
  }) async {
    try {
      final endpoint = '${ApiConstants.productDetail}/$productId/productDetail';
      
      // userToken'ı query parameter olarak değil, Authorization header'ında gönder
      // Basic auth kullanıyoruz, bu yüzden query parameter'a gerek yok
      final response = await _httpClient.getWithBasicAuth(
        endpoint,
        fromJson: (json) {
          print('🔍 Product Detail API Response: $json');
          
          // 410: Gone -> başarı
          if (json is Map<String, dynamic> &&
              (json['410'] == 'Gone' || json['success'] == true)) {
            final productJson = json['data']?['product'];
            if (productJson != null) {
              // Yeni API yanıtını Product modeline dönüştür
              return Product.fromJson(productJson);
            }
            throw Exception('Ürün detayı bulunamadı');
          }
          // 417: Hata
          if (json is Map<String, dynamic> && json['417'] != null) {
            throw Exception(json['error_message'] ?? json['message'] ?? 'Beklenmeyen hata');
          }
          // Diğer durumlar
          throw Exception('Ürün detayı alınamadı');
        },
      );
      return response;
    } catch (e) {
      print('❌ Product Detail Error: $e');
      return ApiResponse.error(e.toString());
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
            
            // API'den gelen ham verileri kontrol et
            print('🔍 ProductService - Raw API data for first product:');
            if (list.isNotEmpty) {
              final firstProduct = list.first;
              print('🔍 ProductService - First product keys: ${firstProduct.keys.toList()}');
              print('🔍 ProductService - First product cityTitle: ${firstProduct['cityTitle']}');
              print('🔍 ProductService - First product districtTitle: ${firstProduct['districtTitle']}');
              print('🔍 ProductService - First product cityID: ${firstProduct['cityID']}');
              print('🔍 ProductService - First product districtID: ${firstProduct['districtID']}');
            }
            
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
            
            // API'den gelen ham verileri kontrol et
            print('🔍 ProductService - Raw API data for first product (userProductList):');
            if (list.isNotEmpty) {
              final firstProduct = list.first;
              print('🔍 ProductService - First product keys: ${firstProduct.keys.toList()}');
              print('🔍 ProductService - First product cityTitle: ${firstProduct['cityTitle']}');
              print('🔍 ProductService - First product districtTitle: ${firstProduct['districtTitle']}');
              print('🔍 ProductService - First product cityID: ${firstProduct['cityID']}');
              print('🔍 ProductService - First product districtID: ${firstProduct['districtID']}');
            }
            
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
            
            // API'den gelen ham verileri kontrol et
            print('🔍 ProductService - Raw API data for first product (root):');
            if (list.isNotEmpty) {
              final firstProduct = list.first;
              print('🔍 ProductService - First product keys: ${firstProduct.keys.toList()}');
              print('🔍 ProductService - First product cityTitle: ${firstProduct['cityTitle']}');
              print('🔍 ProductService - First product districtTitle: ${firstProduct['districtTitle']}');
              print('🔍 ProductService - First product cityID: ${firstProduct['cityID']}');
              print('🔍 ProductService - First product districtID: ${firstProduct['districtID']}');
            }
            
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

    // Kategori verilerini debug et
    print('🏷️ Category debug for product ${apiProduct['productID']}:');
    print('🏷️ categoryID: ${apiProduct['categoryID']}');
    print('🏷️ categoryTitle: ${apiProduct['categoryTitle']}');
    print('🏷️ categoryTitle type: ${apiProduct['categoryTitle']?.runtimeType}');
    print('🏷️ categoryTitle isEmpty: ${apiProduct['categoryTitle']?.toString().isEmpty ?? true}');
    print('🏷️ All category-related fields:');
    apiProduct.forEach((key, value) {
      if (key.toString().toLowerCase().contains('categor') || key.toString().toLowerCase().contains('cat')) {
        print('🏷️ $key: $value');
      }
    });
    
    // 3 katmanlı kategori sistemi için tüm alanları kontrol et
    print('🏷️ 3-Layer Category System Check:');
    print('🏷️ categoryID: ${apiProduct['categoryID']}');
    print('🏷️ categoryTitle: ${apiProduct['categoryTitle']}');
    print('🏷️ parentCategoryID: ${apiProduct['parentCategoryID']}');
    print('🏷️ parentCategoryTitle: ${apiProduct['parentCategoryTitle']}');
    print('🏷️ grandParentCategoryID: ${apiProduct['grandParentCategoryID']}');
    print('🏷️ grandParentCategoryTitle: ${apiProduct['grandParentCategoryTitle']}');
    print('🏷️ mainCategoryID: ${apiProduct['mainCategoryID']}');
    print('🏷️ mainCategoryTitle: ${apiProduct['mainCategoryTitle']}');
    print('🏷️ subCategoryID: ${apiProduct['subCategoryID']}');
    print('🏷️ subCategoryTitle: ${apiProduct['subCategoryTitle']}');
    
    // categoryList alanını kontrol et
    print('🏷️ categoryList check:');
    print('🏷️ Raw categoryList: ${apiProduct['categoryList']}');
    print('🏷️ categoryList type: ${apiProduct['categoryList']?.runtimeType}');
    
    if (apiProduct['categoryList'] != null) {
      final categoryList = apiProduct['categoryList'] as List;
      print('🏷️ categoryList length: ${categoryList.length}');
      for (int i = 0; i < categoryList.length; i++) {
        final category = categoryList[i];
        print('🏷️ categoryList[$i] raw: $category');
        print('🏷️ categoryList[$i] type: ${category.runtimeType}');
        if (category is Map) {
          print('🏷️ categoryList[$i] keys: ${category.keys}');
          print('🏷️ categoryList[$i]: catID=${category['catID']}, catName=${category['catName']}');
        }
      }
    } else {
      print('🏷️ categoryList is null');
    }

    // Resim URL'ini debug et
    final imageUrl = apiProduct['productImage'];
    print('🖼️ Product image URL: $imageUrl');
    print('🖼️ Image URL type: ${imageUrl.runtimeType}');
    print('🖼️ Image URL isEmpty: ${imageUrl?.toString().isEmpty ?? true}');

    // Görsel URL'lerini tam URL'e dönüştür
    final images = <String>[];
    print('🖼️ [NEW API] Processing images for product: ${apiProduct['productTitle']}');
    print('🖼️ [NEW API] Raw productImage: ${apiProduct['productImage']}');
    print('🖼️ [NEW API] Raw extraImages: ${apiProduct['extraImages']}');
    
    // Ana resim işleme
    final productImage = apiProduct['productImage']?.toString();
    if (productImage != null &&
        productImage.isNotEmpty &&
        productImage != 'null' &&
        productImage != 'undefined' &&
        !productImage.contains('product_68852b20b6cac.png') && // Hatalı URL'yi filtrele
        Uri.tryParse(productImage) != null) { // URL formatını kontrol et
      // Eğer URL zaten tam URL ise olduğu gibi kullan, değilse base URL ile birleştir
      final fullImageUrl = productImage.startsWith('http') ? productImage : '${ApiConstants.baseUrl}$productImage';
      images.add(fullImageUrl);
      print('🖼️ [NEW API] Added productImage: $fullImageUrl');
    } else {
      print('⚠️ [NEW API] Skipping invalid productImage: $productImage');
    }
    
    // extraImages varsa onları da ekle
    if (apiProduct['extraImages'] != null) {
      final extraImages = apiProduct['extraImages'] as List;
      print('🖼️ [NEW API] Processing ${extraImages.length} extra images');
      for (final extraImage in extraImages) {
        final extraImageStr = extraImage?.toString();
        if (extraImageStr != null && 
            extraImageStr.isNotEmpty &&
            extraImageStr != 'null' &&
            extraImageStr != 'undefined' &&
            !extraImageStr.contains('product_68852b20b6cac.png') && // Hatalı URL'yi filtrele
            Uri.tryParse(extraImageStr) != null) { // URL formatını kontrol et
          final fullImageUrl = extraImageStr.startsWith('http') ? extraImageStr : '${ApiConstants.baseUrl}$extraImageStr';
          images.add(fullImageUrl);
          print('🖼️ [NEW API] Added extraImage: $fullImageUrl');
        } else {
          print('⚠️ [NEW API] Skipping invalid extraImage: $extraImageStr');
        }
      }
    }
    
    print('🖼️ [NEW API] Final images array for ${apiProduct['productTitle']}: $images');
    print('🖼️ [NEW API] Total images count: ${images.length}');

    print('🖼️ Final images array: $images');

    // categoryList'ten kategori bilgilerini parse et
    String? mainCategoryName;
    String? parentCategoryName;
    String? subCategoryName;
    String? mainCategoryId;
    String? parentCategoryId;
    String? subCategoryId;
    
    if (apiProduct['categoryList'] != null) {
      final categoryList = apiProduct['categoryList'] as List;
      print('🏷️ Parsing categoryList with ${categoryList.length} items');
      
      if (categoryList.length >= 1) {
        // İlk kategori ana kategori olarak kabul edilir
        final mainCat = categoryList[0];
        print('🏷️ Main cat raw: $mainCat');
        if (mainCat is Map) {
          mainCategoryId = mainCat['catID']?.toString();
          mainCategoryName = mainCat['catName']?.toString();
          print('🏷️ Main category: $mainCategoryName (ID: $mainCategoryId)');
        }
      }
      
      if (categoryList.length >= 2) {
        // İkinci kategori üst kategori olarak kabul edilir
        final parentCat = categoryList[1];
        print('🏷️ Parent cat raw: $parentCat');
        if (parentCat is Map) {
          parentCategoryId = parentCat['catID']?.toString();
          parentCategoryName = parentCat['catName']?.toString();
          print('🏷️ Parent category: $parentCategoryName (ID: $parentCategoryId)');
        }
      }
      
      if (categoryList.length >= 3) {
        // Üçüncü kategori alt kategori olarak kabul edilir
        final subCat = categoryList[2];
        print('🏷️ Sub cat raw: $subCat');
        if (subCat is Map) {
          subCategoryId = subCat['catID']?.toString();
          subCategoryName = subCat['catName']?.toString();
          print('🏷️ Sub category: $subCategoryName (ID: $subCategoryId)');
        }
      }
      
      // categoryId'yi categoryList'teki son kategorinin ID'si olarak ayarla
      // Bu, en spesifik kategoriyi temsil eder
      if (categoryList.isNotEmpty) {
        final lastCategory = categoryList.last;
        if (lastCategory is Map) {
          final lastCategoryId = lastCategory['catID']?.toString();
          final lastCategoryName = lastCategory['catName']?.toString();
          print('🏷️ Setting categoryId to last category: $lastCategoryName (ID: $lastCategoryId)');
          // categoryId'yi güncelle (Product modelinde bu alan var)
          apiProduct['categoryID'] = lastCategoryId;
          // categoryTitle'ı da güncelle
          apiProduct['categoryTitle'] = lastCategoryName;
        }
      }
    }
    
    // Eğer categoryList'ten kategori bilgileri alınamadıysa, diğer alanları kontrol et
    if (mainCategoryName == null || mainCategoryName == 'null') {
      mainCategoryName = apiProduct['mainCategoryTitle']?.toString();
      mainCategoryId = apiProduct['mainCategoryID']?.toString();
    }
    
    if (parentCategoryName == null || parentCategoryName == 'null') {
      parentCategoryName = apiProduct['parentCategoryTitle']?.toString();
      parentCategoryId = apiProduct['parentCategoryID']?.toString();
    }
    
    if (subCategoryName == null || subCategoryName == 'null') {
      subCategoryName = apiProduct['subCategoryTitle']?.toString();
      subCategoryId = apiProduct['subCategoryID']?.toString();
    }
    
    print('🏷️ Final parsed categories:');
    print('🏷️ Main: $mainCategoryName (ID: $mainCategoryId)');
    print('🏷️ Parent: $parentCategoryName (ID: $parentCategoryId)');
    print('🏷️ Sub: $subCategoryName (ID: $subCategoryId)');
    print('🏷️ Final categoryId: ${apiProduct['categoryID']}');
    print('🏷️ Final categoryTitle: ${apiProduct['categoryTitle']}');


    
    final product = Product(
      id: apiProduct['productID']?.toString() ?? '',
      title: apiProduct['productTitle']?.toString() ?? '',
      description: apiProduct['productDesc']?.toString() ?? '',
      images: images,
      categoryId: apiProduct['categoryID']?.toString() ?? '',
      catname: apiProduct['catname']?.toString() ?? '',
      parentCategoryId: parentCategoryId,
      parentCategoryName: parentCategoryName,
      grandParentCategoryId: apiProduct['grandParentCategoryID']?.toString(),
      grandParentCategoryName: apiProduct['grandParentCategoryTitle']?.toString(),
      mainCategoryId: mainCategoryId,
      mainCategoryName: mainCategoryName,
      subCategoryId: subCategoryId,
      subCategoryName: subCategoryName,
      category: Category(
        id: apiProduct['categoryID']?.toString() ?? '',
        name: mainCategoryName ?? parentCategoryName ?? subCategoryName ?? 
              (apiProduct['categoryTitle']?.toString().isNotEmpty == true 
                  ? apiProduct['categoryTitle']?.toString() ?? 'Kategori'
                  : 'Kategori Yok'),
        icon: '',
        parentId: parentCategoryId,
        parentName: parentCategoryName,
        grandParentId: apiProduct['grandParentCategoryID']?.toString(),
        grandParentName: apiProduct['grandParentCategoryTitle']?.toString(),
        mainCategoryId: mainCategoryId,
        mainCategoryName: mainCategoryName,
        subCategoryId: subCategoryId,
        subCategoryName: subCategoryName,
        children: null,
        isActive: true,
        order: 0,
        level: _determineCategoryLevel(apiProduct),
      ),
      condition: apiProduct['productCondition']?.toString() ?? '',
      ownerId: apiProduct['userID']?.toString() ?? '',
      owner: User(
        id: apiProduct['userID']?.toString() ?? '',
        name: apiProduct['userFullname']?.toString() ?? 'Kullanıcı',
        firstName: apiProduct['userFirstname']?.toString(),
        lastName: apiProduct['userLastname']?.toString(),
        email: '', // API'de email yok
        isVerified: false,
        isOnline: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      tradePreferences: [], // API'de trade preferences yok
      status: ProductStatus.active,
      cityId: apiProduct['cityID']?.toString() ?? '',
      cityTitle: apiProduct['cityTitle']?.toString() ?? '',
      districtId: apiProduct['districtID']?.toString() ?? '',
      districtTitle: apiProduct['districtTitle']?.toString() ?? '',
      createdAt: _parseDate(apiProduct['createdAt']?.toString()),
      updatedAt: DateTime.now(),
    );
    
    // Adres bilgilerini debug et
    print('📍 [NEW API] Location debug for product ${apiProduct['productTitle']}:');
    print('📍 [NEW API] cityTitle: "${apiProduct['cityTitle']?.toString() ?? ''}"');
    print('📍 [NEW API] districtTitle: "${apiProduct['districtTitle']?.toString() ?? ''}"');
    print('📍 [NEW API] cityID: ${apiProduct['cityID']}');
    print('📍 [NEW API] districtID: ${apiProduct['districtID']}');
    
    return product;
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

    // Görsel URL'lerini tam URL'e dönüştür
    final images = <String>[];
    print('🖼️ [OLD API] Processing images for product: ${apiProduct['productTitle'] ?? 'Unknown'}');
    print('🖼️ [OLD API] Raw productImage: ${apiProduct['productImage']}');
    print('🖼️ [OLD API] Raw extraImages: ${apiProduct['extraImages']}');
    
    // Ana resim işleme
    final productImage = apiProduct['productImage']?.toString();
    if (productImage != null &&
        productImage.isNotEmpty &&
        productImage != 'null' &&
        productImage != 'undefined' &&
        !productImage.contains('product_68852b20b6cac.png') && // Hatalı URL'yi filtrele
        Uri.tryParse(productImage) != null) { // URL formatını kontrol et
      final fullImageUrl = productImage.startsWith('http') ? productImage : '${ApiConstants.baseUrl}$productImage';
      images.add(fullImageUrl);
      print('🖼️ [OLD API] Added productImage: $fullImageUrl');
    } else {
      print('⚠️ [OLD API] Skipping invalid productImage: $productImage');
    }
    
    // extraImages varsa onları da ekle
    if (apiProduct['extraImages'] != null) {
      final extraImages = apiProduct['extraImages'] as List;
      print('🖼️ [OLD API] Processing ${extraImages.length} extra images');
      for (final extraImage in extraImages) {
        final extraImageStr = extraImage?.toString();
        if (extraImageStr != null && 
            extraImageStr.isNotEmpty &&
            extraImageStr != 'null' &&
            extraImageStr != 'undefined' &&
            !extraImageStr.contains('product_68852b20b6cac.png') && // Hatalı URL'yi filtrele
            Uri.tryParse(extraImageStr) != null) { // URL formatını kontrol et
          final fullImageUrl = extraImageStr.startsWith('http') ? extraImageStr : '${ApiConstants.baseUrl}$extraImageStr';
          images.add(fullImageUrl);
          print('🖼️ [OLD API] Added extraImage: $fullImageUrl');
        } else {
          print('⚠️ [OLD API] Skipping invalid extraImage: $extraImageStr');
        }
      }
    }
    
    print('🖼️ [OLD API] Final images array: $images');
    print('🖼️ [OLD API] Total images count: ${images.length}');

    // Adres bilgilerini debug et
    final cityTitle = apiProduct['cityTitle'] ?? '';
    final districtTitle = apiProduct['districtTitle'] ?? '';
    print('📍 [OLD API] Location debug for product ${apiProduct['productTitle']}:');
    print('📍 [OLD API] cityTitle: "$cityTitle"');
    print('📍 [OLD API] districtTitle: "$districtTitle"');
    print('📍 [OLD API] cityID: ${apiProduct['cityID']}');
    print('📍 [OLD API] districtID: ${apiProduct['districtID']}');
    
    return Product(
      id: apiProduct['productID']?.toString() ?? '',
      title: apiProduct['productTitle'] ?? '',
      description: apiProduct['productDesc'] ?? '',
      images: images,
      categoryId: categoryId,
      catname: categoryName,
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
        id: apiProduct['userID']?.toString() ?? '',
        name: 'Kullanıcı',
        email: '',
        isVerified: false,
        isOnline: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      tradePreferences: apiProduct['productTradeFor'] != null
          ? [apiProduct['productTradeFor']]
          : [],
      status: ProductStatus.active,
      cityId: apiProduct['cityID']?.toString() ?? '',
      cityTitle: cityTitle,
      districtId: apiProduct['districtID']?.toString() ?? '',
      districtTitle: districtTitle,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
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
    String? cityId,
    String? cityTitle,
    String? districtId,
    String? districtTitle,
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
      if (cityId != null) body['cityId'] = cityId;
      if (cityTitle != null) body['cityTitle'] = cityTitle;
      if (districtId != null) body['districtId'] = districtId;
      if (districtTitle != null) body['districtTitle'] = districtTitle;

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

  Future<ApiResponse<Product?>> updateProduct(
    String productId, {
    required String userToken,
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
    print('🔄 ProductService.updateProduct called');
    print('📝 Parameters:');
    print('  - productId: $productId');
    print('  - userToken: ${userToken.substring(0, 20)}...');
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

    // Token geçerliliğini kontrol et
    if (userToken.isEmpty) {
      print('❌ User token is empty!');
      return ApiResponse.error('Kullanıcı token\'ı bulunamadı');
    }

    try {
      // SharedPreferences'dan userId'yi al
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString(AppConstants.userIdKey);
      print('🔍 Current user ID: $currentUserId');

      if (currentUserId == null || currentUserId.isEmpty) {
        print('❌ User ID not found in SharedPreferences!');
        return ApiResponse.error('Kullanıcı ID\'si bulunamadı');
      }

      // API'nin beklediği form-data formatında body hazırla
      final body = <String, dynamic>{
        'userToken': userToken,
        'productID': int.tryParse(productId) ?? productId,
      };

      // Zorunlu alanları kontrol et ve API'nin beklediği formatta gönder
      if (title != null && title.isNotEmpty) {
        body['productTitle'] = title;
      } else {
        print('❌ Product title is required!');
        return ApiResponse.error('Ürün başlığı zorunludur');
      }

      if (description != null && description.isNotEmpty) {
        body['productDesc'] = description;
      } else {
        print('❌ Product description is required!');
        return ApiResponse.error('Ürün açıklaması zorunludur');
      }

      if (categoryId != null && categoryId.isNotEmpty) {
        body['categoryID'] = int.tryParse(categoryId) ?? categoryId;
      } else {
        print('❌ Category ID is required!');
        return ApiResponse.error('Kategori seçimi zorunludur');
      }

      if (conditionId != null && conditionId.isNotEmpty) {
        body['conditionID'] = int.tryParse(conditionId) ?? conditionId;
      } else {
        print('❌ Condition ID is required!');
        return ApiResponse.error('Ürün durumu seçimi zorunludur');
      }

      // Konum bilgileri - API integer bekliyor
      if (cityId != null && cityId.isNotEmpty) {
        body['productCity'] = int.tryParse(cityId) ?? 35;
      } else {
        body['productCity'] = 35; // Varsayılan İzmir
      }

      if (districtId != null && districtId.isNotEmpty) {
        body['productDistrict'] = int.tryParse(districtId) ?? 4158;
      } else {
        body['productDistrict'] = 4158; // Varsayılan ilçe
      }

      // Koordinat bilgileri - API string bekliyor
      body['productLat'] = productLat ?? '38.4192'; // İzmir varsayılan enlem
      body['productLong'] = productLong ?? '27.1287'; // İzmir varsayılan boylam

      // İletişim bilgisi - API integer bekliyor (1 veya 0)
      body['isShowContact'] = isShowContact == true ? 1 : 0;

      // Takas edilecek ürün - API string bekliyor
      if (tradePreferences != null && tradePreferences.isNotEmpty) {
        body['tradeFor'] = tradePreferences.join(', ');
      } else {
        body['tradeFor'] = 'Takas edilebilir';
      }

      // Endpoint: service/user/product/{userId}/editProduct
      final endpoint = '${ApiConstants.editProduct}/$currentUserId/editProduct';
      final fullUrl = '${ApiConstants.fullUrl}$endpoint';
      print('🌐 Full URL: $fullUrl');

      // Form-data için fields hazırla - API'nin beklediği formatta
      final fields = <String, String>{};
      body.forEach((key, value) {
        if (value != null) {
          // API'nin beklediği formatta string'e çevir
          if (value is int) {
            fields[key] = value.toString();
          } else if (value is String) {
            fields[key] = value;
          } else {
            fields[key] = value.toString();
          }
        }
      });

      // Resimler için files hazırla (eğer varsa)
      final files = <String, File>{};
      final multipleFiles = <String, List<File>>{};
      final newImageFiles = <File>[];

      print('🌐 Update Body: $body');
      print('📋 Form Fields: $fields');
      print('📎 Files: ${files.keys.toList()}');
      print('📎 Multiple Files: ${multipleFiles.keys.toList()}');
      if (multipleFiles.isNotEmpty) {
        multipleFiles.forEach((key, files) {
          print('📎 $key: ${files.length} files');
          for (int i = 0; i < files.length; i++) {
            print('  - ${files[i].path.split('/').last}');
          }
        });
      }
      
      if (images != null && images.isNotEmpty) {
        for (int i = 0; i < images.length; i++) {
          final imagePath = images[i];
          // Eğer dosya yolu ise (yeni yüklenen resim) File objesi oluştur
          if (imagePath.startsWith('/') || imagePath.contains('\\')) {
            final file = File(imagePath);
            if (await file.exists()) {
              newImageFiles.add(file);
              print('📸 Added new image file: ${file.path.split('/').last}');
            }
          }
          // Eğer URL ise (mevcut resim) fields'a ekle
          else if (imagePath.startsWith('http')) {
            fields['existingImage[$i]'] = imagePath;
            print('📸 Added existing image URL: ${imagePath.substring(0, 50)}...');
          }
        }
        
        // Yeni resimleri multipleFiles'a ekle
        if (newImageFiles.isNotEmpty) {
          multipleFiles['productimages'] = newImageFiles;
          print('📸 Added ${newImageFiles.length} new image files to multipleFiles');
        }
      }

      // Multipart form-data ile gönder
      final response = await _httpClient.postMultipart<Product?>(
        endpoint,
        fields: fields,
        files: files.isNotEmpty ? files : null,
        multipleFiles: multipleFiles.isNotEmpty ? multipleFiles : null,
        fromJson: (json) {
          print('📥 ProductService.updateProduct - Raw response: $json');
          print('📥 ProductService.updateProduct - Response type: ${json.runtimeType}');

          // API response'unu detaylı analiz et
          if (json is Map<String, dynamic>) {
            print('📥 ProductService.updateProduct - Response keys: ${json.keys.toList()}');

            // Özel format: {"error": false, "200": "OK"} - Bu başarılı güncelleme anlamına gelir
            if (json.containsKey('error') && json.containsKey('200')) {
              final errorValue = json['error'];
              final statusValue = json['200'];
              print('📥 ProductService.updateProduct - Special format detected');
              print('📥 ProductService.updateProduct - Error: $errorValue, Status: $statusValue');
              
              if (errorValue == false && statusValue == 'OK') {
                print('✅ Success - Product updated successfully with special format');
                return null;
              }
            }

            // success field'ını kontrol et
            if (json.containsKey('success')) {
              final successValue = json['success'];
              print('📥 ProductService.updateProduct - Success field: $successValue');
            }

            // message field'ını kontrol et
            if (json.containsKey('message')) {
              final messageValue = json['message'];
              print('📥 ProductService.updateProduct - Message field: $messageValue');
            }

            // data field'ını kontrol et
            if (json.containsKey('data')) {
              final dataValue = json['data'];
              print('📥 ProductService.updateProduct - Data field: $dataValue');
              if (dataValue is Map<String, dynamic>) {
                return Product.fromJson(dataValue);
              }
            }

            // Eğer data field'ı yoksa, tüm response'u Product olarak parse etmeye çalış
            try {
              return Product.fromJson(json);
            } catch (e) {
              print('❌ Failed to parse response as Product: $e');
              throw Exception('Ürün güncellenirken yanıt formatı hatalı');
            }
          }

          throw Exception('Geçersiz API yanıtı');
        },
        useBasicAuth: true,
      );

      print('📡 ProductService.updateProduct - Response received');
      print('📊 Response success: ${response.isSuccess}');
      print('📊 Response error: ${response.error}');
      print('📊 Response data: ${response.data}');

      return response;
    } catch (e) {
      print('❌ ProductService.updateProduct - Exception: $e');
      return ApiResponse.error('Ürün güncellenirken hata oluştu: $e');
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

    // Token geçerliliğini kontrol et
    if (userToken.isEmpty) {
      print('❌ User token is empty!');
      return ApiResponse.error('Kullanıcı token\'ı bulunamadı');
    }

    try {
      // Token'ı request body'de göndereceğiz
      final prefs = await SharedPreferences.getInstance();
      
      final currentUserId = prefs.getString(AppConstants.userIdKey);
      print('🔍 Current user ID: $currentUserId');

      // Token'ın geçerliliğini kontrol et
      print('🔍 Token validation:');
      print('  - Token starts with: ${userToken.substring(0, 10)}...');
      print('  - Token length: ${userToken.length}');
      print('  - Expected token length: ~100+ characters');

      // Doğru endpoint formatını kullan - userId kullanılmalı
      final endpoint = '${ApiConstants.deleteProduct}/$currentUserId/deleteProduct';
      final fullUrl = '${ApiConstants.fullUrl}$endpoint';
      print('🌐 Full URL: $fullUrl');
      


      // API'nin beklediği format: {"userToken": "...", "productID": 1}
      final body = {
        'userToken': userToken,
        'productID': int.parse(productId), // API integer bekliyor
      };
      print('🌐 DELETE Body: $body');

      // Alternatif format 1: productId string olarak
      final bodyAlt1 = {
        'userToken': userToken,
        'productID': productId, // String olarak
      };
      print('🌐 DELETE Body Alt1 (string productID): $bodyAlt1');

      // Alternatif format 2: productId yerine id
      final bodyAlt2 = {
        'userToken': userToken,
        'id': int.parse(productId),
      };
      print('🌐 DELETE Body Alt2 (id field): $bodyAlt2');

      // DELETE HTTP metodunu basic auth ile kullan
      print('🔄 Using DELETE method with basic auth...');
      print('📤 DELETE Body: {"userToken": "...", "productID": $productId}');
      
      // Önce orijinal formatı dene
      var response = await _httpClient.deleteWithBasicAuth<Map<String, dynamic>>(
        endpoint,
        body: body,
        fromJson: (json) {
          print('📥 ProductService.deleteUserProduct - Raw response: $json');
          print(
            '📥 ProductService.deleteUserProduct - Response type: ${json.runtimeType}',
          );

          // Hata mesajlarını özel olarak kontrol et
          if (json is Map<String, dynamic>) {
            if (json.containsKey('message')) {
              final message = json['message']?.toString() ?? '';
              if (message.contains('Erişim reddedildi') ||
                  message.contains('Access denied') ||
                  message.contains('Unauthorized') ||
                  message.contains('403')) {
                print('❌ Access denied error detected: $message');
              }
            }
          }

          // API response'unu detaylı analiz et
          if (json is Map<String, dynamic>) {
            print(
              '📥 ProductService.deleteUserProduct - Response keys: ${json.keys.toList()}',
            );

            // success field'ını kontrol et - type safety için
            if (json.containsKey('success')) {
              final successValue = json['success'];
              print(
                '📥 ProductService.deleteUserProduct - Success field: $successValue (${successValue.runtimeType})',
              );
            }

            // error field'ını kontrol et - type safety için
            if (json.containsKey('error')) {
              final errorValue = json['error'];
              print(
                '📥 ProductService.deleteUserProduct - Error field: $errorValue (${errorValue.runtimeType})',
              );
            }

            // message field'ını kontrol et - type safety için
            if (json.containsKey('message')) {
              final messageValue = json['message'];
              print(
                '📥 ProductService.deleteUserProduct - Message field: $messageValue (${messageValue.runtimeType})',
              );
            }

            // data field'ını kontrol et
            if (json.containsKey('data')) {
              final dataValue = json['data'];
              print(
                '📥 ProductService.deleteUserProduct - Data field: $dataValue (${dataValue.runtimeType})',
              );
              if (dataValue is Map<String, dynamic>) {
                return dataValue;
              }
            }
          }

          print(
            '📥 ProductService.deleteUserProduct - Using full json as response',
          );

          // Safe casting
          if (json is Map<String, dynamic>) {
            return json;
          } else {
            return <String, dynamic>{'rawResponse': json};
          }
        },
      );

      print('📡 ProductService.deleteUserProduct - Response received');
      print('📊 Response success: ${response.isSuccess}');
      print('📊 Response error: ${response.error}');
      print('📊 Response data: ${response.data}');

      // 403 hatası alındıysa alternatif formatları dene
      if (!response.isSuccess && response.error != null && 
          (response.error!.contains('403') || 
           response.error!.contains('Forbidden') ||
           response.error!.contains('Invalid user token') ||
           response.error!.contains('Üye doğrulama bilgileri hatalı'))) {
        
        print('⚠️ 403 error detected, trying alternative formats...');
        
        // Format 1: productID as string
        print('🔄 Trying format 1: productID as string');
        var altResponse1 = await _httpClient.deleteWithBasicAuth<Map<String, dynamic>>(
          endpoint,
          body: bodyAlt1,
          fromJson: (json) {
            print('📥 Alt1 Response: $json');
            if (json is Map<String, dynamic>) {
              return json;
            } else {
              return <String, dynamic>{'rawResponse': json};
            }
          },
        );
        
        if (altResponse1.isSuccess) {
          print('✅ Alternative format 1 worked!');
          return altResponse1;
        }
        
        // Format 2: id instead of productID
        print('🔄 Trying format 2: id field instead of productID');
        var altResponse2 = await _httpClient.deleteWithBasicAuth<Map<String, dynamic>>(
          endpoint,
          body: bodyAlt2,
          fromJson: (json) {
            print('📥 Alt2 Response: $json');
            if (json is Map<String, dynamic>) {
              return json;
            } else {
              return <String, dynamic>{'rawResponse': json};
            }
          },
        );
        
        if (altResponse2.isSuccess) {
          print('✅ Alternative format 2 worked!');
          return altResponse2;
        }
        
        print('❌ All alternative formats failed, trying different endpoints...');
         
         print('❌ All alternative formats failed');
       }

      // KRITIK: API response'unu detaylı analiz et
      if (response.isSuccess) {
        print('✅ API claims deletion was successful');
        if (response.data != null) {
          final data = response.data!;
          print('✅ Response data keys: ${data.keys.toList()}');

          // Başarı mesajlarını kontrol et - type safety ile
          if (data.containsKey('message')) {
            final message = data['message'];
            print('✅ API Message: "$message"');
          }
          if (data.containsKey('success')) {
            final success = data['success'];
            print('✅ API Success flag: $success');

            // Boolean veya string olabilir, her ikisini de kontrol et
            if (success == false || success == 'false' || success == '0') {
              print('❌ API returned success=false, treating as error');
              final errorMsg = data['message']?.toString() ?? 'Ürün silinemedi';
              return ApiResponse.error(errorMsg);
            }
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
        fromJson: (json) {
          print('🔍 Raw Categories API Response: $json');
          
          if (json['data'] == null || json['data']['categories'] == null) {
            print('❌ Categories API response has no data or categories field');
            return <Category>[];
          }
          
          final categoriesList = json['data']['categories'] as List;
          print('🏷️ Categories API returned ${categoriesList.length} categories');
          
          // Kategori verilerini detaylı logla
          print('🏷️ Raw category data from API:');
          for (int i = 0; i < categoriesList.length; i++) {
            final category = categoriesList[i];
            print('🏷️ Category $i raw data: $category');
            print('🏷️ Category $i: catID="${category['catID']}" (type: ${category['catID'].runtimeType}), catName="${category['catName']}", catImage="${category['catImage']}"');
          }
          
          final parsedCategories = categoriesList
              .map(
                (item) => Category(
                  id: item['catID'].toString(),
                  name: item['catName'],
                  icon: item['catImage'] ?? '',
                  parentId: null, // Ana kategoriler için parentId null
                  children: null, // Alt kategoriler ayrı yüklenecek
                  isActive: true,
                  order: 0,
                ),
              )
              .toList();
          
          print('🏷️ Parsed categories:');
          for (int i = 0; i < parsedCategories.length; i++) {
            final category = parsedCategories[i];
            print('🏷️ Parsed Category $i: ID="${category.id}" -> Name="${category.name}"');
          }
          
          return parsedCategories;
        },
      );

      return response;
    } catch (e) {
      print('❌ ProductService: Error getting categories: $e');
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<List<Category>>> getSubCategories(String parentCategoryId) async {
    print(
      '🏷️ ProductService: Getting sub-categories for parent $parentCategoryId from service/general/general/categories/$parentCategoryId',
    );
    try {
      final response = await _httpClient.getWithBasicAuth(
        '${ApiConstants.subCategories}/$parentCategoryId',
        fromJson: (json) => (json['data']['categories'] as List)
            .map(
              (item) => Category(
                id: item['catID'].toString(),
                name: item['catName'],
                icon: item['catImage'] ?? '',
                parentId: parentCategoryId,
                children: null,
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

  Future<ApiResponse<List<Category>>> getSubSubCategories(String parentSubCategoryId) async {
    print(
      '🏷️ ProductService: Getting sub-sub-categories for parent $parentSubCategoryId from service/general/general/categories/$parentSubCategoryId',
    );
    try {
      final response = await _httpClient.getWithBasicAuth(
        '${ApiConstants.subSubCategories}/$parentSubCategoryId',
        fromJson: (json) {
          print('🏷️ ProductService: Raw sub-sub-categories response: $json');
          
          if (json == null) {
            print('❌ Sub-sub-categories API response is null');
            return <Category>[];
          }
          
          if (json['data'] == null) {
            print('❌ Sub-sub-categories API response has no data field');
            return <Category>[];
          }
          
          if (json['data']['categories'] == null) {
            print('❌ Sub-sub-categories API response has no categories field in data');
            return <Category>[];
          }
          
          final categoriesList = json['data']['categories'] as List;
          print('🏷️ Sub-sub-categories API returned ${categoriesList.length} categories');
          
          final categories = categoriesList.map((item) => Category(
            id: item['catID'].toString(),
            name: item['catName'],
            icon: item['catImage'] ?? '',
            parentId: parentSubCategoryId,
            children: null,
            isActive: true,
            order: 0,
          )).toList();
          
          print('🏷️ Parsed ${categories.length} sub-sub-categories successfully');
          categories.forEach((cat) => print('  - ${cat.name} (${cat.id})'));
          
          return categories;
        },
      );

      print('🏷️ ProductService: Sub-sub-categories API response: success=${response.isSuccess}, error=${response.error}');
      return response;
    } catch (e) {
      print('❌ ProductService: Error getting sub-sub-categories: $e');
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<List<Category>>> getSubSubSubCategories(String parentSubSubCategoryId) async {
    try {
      final response = await _httpClient.getWithBasicAuth(
        '${ApiConstants.subSubSubCategories}/$parentSubSubCategoryId',
        fromJson: (json) {
          if (json == null) {
            return <Category>[];
          }
          
          if (json['data'] == null) {
            return <Category>[];
          }
          
          if (json['data']['categories'] == null) {
            return <Category>[];
          }
          
          final categoriesList = json['data']['categories'] as List;
          
          final categories = categoriesList.map((item) => Category(
            id: item['catID'].toString(),
            name: item['catName'],
            icon: item['catImage'] ?? '',
            parentId: parentSubSubCategoryId,
            children: null,
            isActive: true,
            order: 0,
          )).toList();
          
          return categories;
        },
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
        ApiConstants.cities,
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
        '${ApiConstants.districts}/$cityId',
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
    print('ProductService: Getting conditions from /service/general/general/productConditions');
    final fullUrl = '${ApiConstants.fullUrl}/service/general/general/productConditions';
    print('Full URL: $fullUrl');

    try {
      final response = await _httpClient.getWithBasicAuth(
        ApiConstants.productConditions,
        fromJson: (json) {
          print('Raw Conditions API Response: $json');

          // JSON yapısını kontrol et
          if (json == null) {
            print('Conditions API response is null');
            return <Condition>[];
          }

          if (json['data'] == null) {
            print('Conditions API response has no data field');
            print('Available fields: ${json.keys}');
            return <Condition>[];
          }

          if (json['data']['conditions'] == null) {
            print('Conditions API response has no conditions field in data');
            print('Available data fields: ${json['data'].keys}');
            return <Condition>[];
          }

          final conditionsList = json['data']['conditions'] as List;
          print('Conditions API returned ${conditionsList.length} conditions');

          // İlk birkaç durumu logla
          if (conditionsList.isNotEmpty) {
            print('All conditions in API response:');
            for (int i = 0; i < conditionsList.length; i++) {
              final condition = conditionsList[i];
              print('  ${i + 1}. ${condition['conditionName']} (ID: ${condition['conditionID']})');
            }
          }

          final conditions = conditionsList
              .map((item) => Condition.fromJson(item))
              .toList();

          print('Parsed ${conditions.length} conditions successfully');
          return conditions;
        },
      );

      return response;
    } catch (e) {
      Logger.error('Error getting conditions: $e', tag: _tag);
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<void>> addToFavorites(String productId) async {
    try {
      // User token ve userId'yi al
      String userToken = '';
      String userId = '';
      try {
        final prefs = await SharedPreferences.getInstance();
        userToken = prefs.getString(AppConstants.userTokenKey) ?? '';
        userId = prefs.getString(AppConstants.userIdKey) ?? '';
        print('🔑 User token retrieved: ${userToken.isNotEmpty ? "${userToken.substring(0, 20)}..." : "empty"}');
        print('🔑 User ID retrieved: $userId');
      } catch (e) {
        print('⚠️ Error getting user data: $e');
      }

      // Kullanıcının kendi ürünü olup olmadığını kontrol et
      try {
        final productDetailResponse = await getProductDetail(
          userToken: userToken,
          productId: productId,
        );
        if (productDetailResponse.isSuccess && productDetailResponse.data != null) {
          final product = productDetailResponse.data!;
          if (product.ownerId == userId) {
            print('❌ ProductService.addToFavorites - User cannot favorite their own product: $productId');
            return ApiResponse.error('Kendi ürününüzü favoriye ekleyemezsiniz');
          }
        }
      } catch (e) {
        print('⚠️ ProductService.addToFavorites - Error checking product ownership: $e');
        // Ürün sahipliği kontrolü başarısız olsa bile devam et
      }

      // API body'sini hazırla
      final body = {
        'userToken': userToken,
        'productID': productId,
      };
      print('🌐 Add to favorites body: $body');

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.addFavorite,
        body: body,
        fromJson: (json) {
          print('📥 Add to favorites response: $json');
          return null;
        },
        useBasicAuth: true,
      );

      return response;
    } catch (e) {
      print('❌ Error adding to favorites: $e');
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<void>> removeFromFavorites(String productId) async {
    print('🔄 ProductService.removeFromFavorites - Starting for product ID: $productId');
    try {
      // User token ve userId'yi al
      String userToken = '';
      String userId = '';
      try {
        final prefs = await SharedPreferences.getInstance();
        userToken = prefs.getString(AppConstants.userTokenKey) ?? '';
        userId = prefs.getString(AppConstants.userIdKey) ?? '';
        print('🔑 User token retrieved: ${userToken.isNotEmpty ? "${userToken.substring(0, 20)}..." : "empty"}');
        print('🔑 User ID retrieved: $userId');
      } catch (e) {
        print('⚠️ Error getting user data: $e');
      }

      // API body'sini hazırla
      final body = {
        'userToken': userToken,
        'productID': productId,
      };
      print('🌐 Remove from favorites body: $body');

      print('🌐 Calling removeFromFavorites API with endpoint: ${ApiConstants.removeFavorite}');
      print('🌐 Full URL: ${ApiConstants.fullUrl}${ApiConstants.removeFavorite}');
      print('🌐 Request body: $body');
      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.removeFavorite,
        body: body,
        useBasicAuth: true,
        fromJson: (json) {
          print('📥 Remove from favorites response: $json');
          print('📊 Remove from favorites response type: ${json.runtimeType}');
          print('📊 Remove from favorites response keys: ${json is Map ? json.keys.toList() : 'Not a map'}');
          if (json is Map) {
            print('📊 Remove from favorites success: ${json['success']}');
            print('📊 Remove from favorites error: ${json['error']}');
            print('📊 Remove from favorites message: ${json['message']}');
            
            // API response'unu detaylı analiz et
            if (json.containsKey('error') && json.containsKey('200')) {
              final errorValue = json['error'];
              final statusValue = json['200'];
              print('📊 Remove from favorites - Special format detected');
              print('📊 Remove from favorites - Error: $errorValue, Status: $statusValue');
              
              if (errorValue == false && statusValue == 'OK') {
                print('✅ Remove from favorites - Success with special format');
                return null;
              }
            }
            
            // Normal success response
            if (json.containsKey('success') && json['success'] == true) {
              print('✅ Remove from favorites - Success with normal format');
              return null;
            }
            
            // 410 status code için özel handling
            if (json.containsKey('error') && json['error'] == false && json.containsKey('410')) {
              print('✅ Remove from favorites - Success with 410 format');
              return null;
            }
          }
          return null;
        },
      );
      
      print('📡 Remove from favorites API call completed');
      print('📡 Response isSuccess: ${response.isSuccess}');
      print('📡 Response error: ${response.error}');
      
      // API response'unu detaylı analiz et
      if (response.isSuccess) {
        print('✅ Remove from favorites - API call was successful');
      } else {
        print('❌ Remove from favorites - API call failed: ${response.error}');
      }

      return response;
    } catch (e) {
      print('❌ Error removing from favorites: $e');
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<List<Product>>> getFavoriteProducts() async {
    try {
      // User token'ı al
      String userToken = '';
      String userId = '';
      try {
        final prefs = await SharedPreferences.getInstance();
        userToken = prefs.getString(AppConstants.userTokenKey) ?? '';
        userId = prefs.getString(AppConstants.userIdKey) ?? '';
        print('🔑 User token retrieved: ${userToken.isNotEmpty ? "${userToken.substring(0, 20)}..." : "empty"}');
        print('🔑 User ID retrieved: $userId');
      } catch (e) {
        print('⚠️ Error getting user token: $e');
      }

      // Query parametreleri hazırla
      final queryParams = {'userToken': userToken};
      print('🌐 Get favorites query params: $queryParams');

      print('🌐 Calling getFavoriteProducts API with endpoint: ${ApiConstants.favoriteList}/$userId/favoriteList');
      print('🌐 Full URL: ${ApiConstants.fullUrl}${ApiConstants.favoriteList}/$userId/favoriteList');
      print('🌐 Query params: $queryParams');
      final response = await _httpClient.getWithBasicAuth(
        '${ApiConstants.favoriteList}/$userId/favoriteList',
        queryParams: queryParams,
        fromJson: (json) {
          print('📥 Get favorites response: $json');
          print('📊 Get favorites response type: ${json.runtimeType}');
          if (json is Map) {
            print('📊 Get favorites response keys: ${json.keys.toList()}');
            print('📊 Get favorites success: ${json['success']}');
            print('📊 Get favorites error: ${json['error']}');
          }
          
          // API response formatını kontrol et
          if (json == null) {
            print('❌ Get favorites response is null');
            return <Product>[];
          }

          // 410 status code için özel handling (başarılı response)
          if (json case {'error': false, '410': 'Gone'}) {
            print('🔍 Get favorites - 410 Gone response (success)');
            if (json['data'] != null && json['data']['products'] != null) {
              final productsList = json['data']['products'] as List;
              print('📦 410 response returned ${productsList.length} favorite products');
              
              // Ürün detaylarını logla
              for (int i = 0; i < productsList.length; i++) {
                final product = productsList[i];
                print('📦 Favorite product $i: ${product['productTitle']} (ID: ${product['productID']})');
              }
              
              final products = productsList
                  .map((item) => _transformNewApiProductToModel(item))
                  .toList();
              print('📦 Parsed ${products.length} favorite products successfully from 410');
              return products;
            }
            return <Product>[];
          }

          // Normal success response
          if (json case {'error': false, 'success': true}) {
            print('🔍 Get favorites - Normal success response');
            if (json['data'] != null && json['data']['products'] != null) {
              final productsList = json['data']['products'] as List;
              print('📦 Success response returned ${productsList.length} favorite products');
              final products = productsList
                  .map((item) => _transformNewApiProductToModel(item))
                  .toList();
              print('📦 Parsed ${products.length} favorite products successfully');
              return products;
            }
            return <Product>[];
          }

          // Boş success response
          if (json case {'error': false, '200': 'OK'}) {
            print('🔍 Get favorites - Empty success response');
            return <Product>[];
          }

          // Diğer response formatları
          if (json['data'] != null) {
            if (json['data']['products'] != null) {
              final productsList = json['data']['products'] as List;
              print('📦 Get favorites returned ${productsList.length} products');
              final products = productsList
                  .map((item) => _transformNewApiProductToModel(item))
                  .toList();
              print('📦 Parsed ${products.length} favorite products successfully');
              return products;
            }
          }

          print('❌ Get favorites - No products found in response');
          print('❌ Available keys: ${json.keys.toList()}');
          return <Product>[];
        },
      );

      return response;
    } catch (e) {
      print('❌ Error getting favorite products: $e');
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<void>> incrementViewCount(String productId) async {
    try {
      final response = await _httpClient.post(
        '${ApiConstants.productView}/$productId/view',
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
    String? selectedCityId,
    String? selectedDistrictId,
    bool? isShowContact,
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
    print('  - selectedCityId: $selectedCityId');
    print('  - selectedDistrictId: $selectedDistrictId');
    print('  - isShowContact: $isShowContact');

    try {
      // Kategori bilgilerini al
      String catImage = '';
      try {
        final categoriesResponse = await getCategories();
        if (categoriesResponse.isSuccess && categoriesResponse.data != null) {
          final selectedCategory = categoriesResponse.data!.firstWhere(
            (cat) => cat.id == categoryId,
            orElse: () => Category(
              id: categoryId,
              name: 'Bilinmeyen Kategori',
              icon: '',
              isActive: true,
              order: 0,
            ),
          );
          catImage = selectedCategory.icon;
          print('🏷️ Selected category: ${selectedCategory.name}');
          print('🏷️ Category icon: $catImage');
        }
      } catch (e) {
        print('⚠️ Error getting category info: $e');
        catImage = '';
      }

      // Konum bilgilerini al
      double? latitude;
      double? longitude;
      
      try {
        final locationService = LocationService();
        final position = await locationService.getCurrentLocation();
        if (position != null) {
          latitude = position.latitude;
          longitude = position.longitude;
          print('📍 Location obtained: $latitude, $longitude');
        } else {
          print('⚠️ Could not get current location, using default values');
        }
      } catch (e) {
        print('⚠️ Error getting location: $e');
      }

      // Form fields - Postman form/data formatına uygun
      final fields = <String, String>{
        'userToken': userToken,
        'productTitle': productTitle,
        'productDesc': productDescription,
        'categoryID': categoryId,
        'conditionID': conditionId,
        'tradeFor': tradeFor,
        'catImage': catImage, // Kategori icon'u eklendi
        'productCity': selectedCityId ?? '',
        'productDistrict': selectedDistrictId ?? '',
        'productLat': latitude?.toString() ?? '',
        'productLong': longitude?.toString() ?? '',
        'isShowContact': (isShowContact ?? true) ? '1' : '0',
      };

      print('📋 Form fields prepared:');
      fields.forEach((key, value) {
        if (key == 'userToken') {
          print('  - $key: ${value.substring(0, 20)}...');
        } else {
          print('  - $key: $value');
        }
      });

      // Görselleri dizi olarak hazırla - Postman form/data formatı
      final files = <String, File>{};
      if (productImages.isNotEmpty) {
        // Her görsel için ayrı key kullan (productImages[0], productImages[1], ...)
        for (int i = 0; i < productImages.length; i++) {
          files['productImages[$i]'] = productImages[i];
          print('📸 Image ${i + 1}: ${productImages[i].path.split('/').last}');
        }
        print('📸 Total images prepared: ${productImages.length}');
      } else {
        print('📸 No images to upload');
      }

      final endpoint = '${ApiConstants.addProduct}/$userId/addProduct';
      final fullUrl = '${ApiConstants.fullUrl}$endpoint';
      print('🌐 Full URL: $fullUrl');

      final response = await _httpClient.postMultipart<Map<String, dynamic>>(
        endpoint,
        fields: fields,
        files: files, // Dizi formatında görseller
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

            // Görsel URL'lerini tam URL'e dönüştür
            final images = <String>[];
            print('🖼️ Processing images for product: ${apiProduct['productTitle']}');
            print('🖼️ Raw productImage: ${apiProduct['productImage']}');
            print('🖼️ Raw extraImages: ${apiProduct['extraImages']}');
            
            // Ana resim işleme
            final productImage = apiProduct['productImage']?.toString();
            if (productImage != null &&
                productImage.isNotEmpty &&
                productImage != 'null' &&
                productImage != 'undefined' &&
                !productImage.contains('product_68852b20b6cac.png') && // Hatalı URL'yi filtrele
                Uri.tryParse(productImage) != null) { // URL formatını kontrol et
              final fullImageUrl = productImage.startsWith('http') ? productImage : '${ApiConstants.baseUrl}$productImage';
              images.add(fullImageUrl);
              print('🖼️ Added productImage: $fullImageUrl');
            } else {
              print('⚠️ Skipping invalid productImage: $productImage');
            }
            
            // extraImages varsa onları da ekle
            if (apiProduct['extraImages'] != null) {
              final extraImages = apiProduct['extraImages'] as List;
              print('🖼️ Processing ${extraImages.length} extra images');
              for (final extraImage in extraImages) {
                final extraImageStr = extraImage?.toString();
                if (extraImageStr != null && 
                    extraImageStr.isNotEmpty &&
                    extraImageStr != 'null' &&
                    extraImageStr != 'undefined' &&
                    !extraImageStr.contains('product_68852b20b6cac.png') && // Hatalı URL'yi filtrele
                    Uri.tryParse(extraImageStr) != null) { // URL formatını kontrol et
                  final fullImageUrl = extraImageStr.startsWith('http') ? extraImageStr : '${ApiConstants.baseUrl}$extraImageStr';
                  images.add(fullImageUrl);
                  print('🖼️ Added extraImage: $fullImageUrl');
                } else {
                  print('⚠️ Skipping invalid extraImage: $extraImageStr');
                }
              }
            }
            
            print('🖼️ Final images array for ${apiProduct['productTitle']}: $images');
            print('🖼️ Total images count: ${images.length}');

            // API field'larından Product model'i için gerekli field'ları oluştur
            final productData = {
              'id': apiProduct['productID']?.toString() ?? '',
              'title': apiProduct['productTitle'] ?? '',
              'description': apiProduct['productDesc'] ?? '',
              'images': images,
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
              'ownerId': userId, // Gerçek kullanıcı ID'sini kullan
              'owner': {
                'id': userId,
                'name': 'Kullanıcı',
                'email': 'user@example.com',
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

  // 3 katmanlı kategori sisteminde kategori seviyesini belirler
  int _determineCategoryLevel(Map<String, dynamic> apiProduct) {
    // Önce categoryList alanını kontrol et
    if (apiProduct['categoryList'] != null) {
      final categoryList = apiProduct['categoryList'] as List;
      if (categoryList.length >= 3) {
        return 3; // Alt-alt kategori
      } else if (categoryList.length >= 2) {
        return 2; // Alt kategori
      } else if (categoryList.length >= 1) {
        return 1; // Ana kategori
      }
    }
    
    // Ana kategori varsa (mainCategoryID ve mainCategoryTitle)
    if (apiProduct['mainCategoryID'] != null && 
        apiProduct['mainCategoryID'].toString().isNotEmpty &&
        apiProduct['mainCategoryTitle'] != null && 
        apiProduct['mainCategoryTitle'].toString().isNotEmpty) {
      return 1; // Ana kategori
    }
    
    // Alt kategori varsa (parentCategoryID ve parentCategoryTitle)
    if (apiProduct['parentCategoryID'] != null && 
        apiProduct['parentCategoryID'].toString().isNotEmpty &&
        apiProduct['parentCategoryTitle'] != null && 
        apiProduct['parentCategoryTitle'].toString().isNotEmpty) {
      return 2; // Alt kategori
    }
    
    // Alt-alt kategori varsa (grandParentCategoryID ve grandParentCategoryTitle)
    if (apiProduct['grandParentCategoryID'] != null && 
        apiProduct['grandParentCategoryID'].toString().isNotEmpty &&
        apiProduct['grandParentCategoryTitle'] != null && 
        apiProduct['grandParentCategoryTitle'].toString().isNotEmpty) {
      return 3; // Alt-alt kategori
    }
    
    // Varsayılan olarak 1. seviye
    return 1;
  }
}
