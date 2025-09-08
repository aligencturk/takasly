import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/http_client.dart';
import '../core/constants.dart';
import '../models/product.dart';
import '../models/product_filter.dart';
import '../models/user.dart';
import '../models/city.dart';
import '../models/district.dart';
import '../models/condition.dart';
import '../models/popular_category.dart';
import '../services/location_service.dart';
import '../models/live_search.dart';

class ProductService {
  final HttpClient _httpClient = HttpClient();

  /// Canlı arama (öneriler) servisi
  Future<ApiResponse<LiveSearchResponse>> liveSearch({
    required String searchText,
  }) async {
    try {
      final body = {'searchText': searchText};

      final response = await _httpClient.postWithBasicAuth<LiveSearchResponse>(
        ApiConstants.liveSearch,
        body: body,
        useBasicAuth: true,
        fromJson: (json) {
          try {
            return LiveSearchResponse.fromJson(json);
          } catch (e) {
            return LiveSearchResponse.empty(searchText);
          }
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<PaginatedProducts>> getAllProducts({
    int page = 1,
    int limit = AppConstants.defaultPageSize,
  }) async {
    try {
      final fullUrl = '${ApiConstants.fullUrl}${ApiConstants.allProducts}';

      // POST request ile dene (API POST method kullanıyor)

      // User token'ı al
      String userToken = '';
      try {
        final prefs = await SharedPreferences.getInstance();
        userToken = prefs.getString(AppConstants.userTokenKey) ?? '';

        // ignore: empty_catches
      } catch (e) {}

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

      final response = await _httpClient.postWithBasicAuth<PaginatedProducts>(
        ApiConstants.allProducts,
        body: body,
        useBasicAuth: true,
        fromJson: (json) {
          // JSON yapısını kontrol et
          if (json == null) {
            return PaginatedProducts(
              products: [],
              currentPage: page,
              totalPages: 1,
              totalItems: 0,
              hasMore: false,
            );
          }

          if (json['data'] == null) {
            // Alternatif formatları kontrol et
            if (json['products'] != null) {
              final productsList = json['products'] as List;

              final products = productsList
                  .map((item) => _transformApiProductToModel(item))
                  .toList();

              return PaginatedProducts.fromJson({
                'data': {
                  'products': productsList,
                  'page': page,
                  'totalPages': 1,
                  'totalItems': products.length,
                },
              });
            }

            // Eğer response direkt bir liste ise
            if (json is List) {
              final products = json
                  .map((item) => _transformApiProductToModel(item))
                  .toList();

              return PaginatedProducts.fromJson({
                'data': {
                  'products': json,
                  'page': page,
                  'totalPages': 1,
                  'totalItems': products.length,
                },
              });
            }

            return PaginatedProducts.fromJson({
              'data': {
                'products': [],
                'page': page,
                'totalPages': 1,
                'totalItems': 0,
              },
            });
          }

          if (json['data']['products'] == null) {
            return PaginatedProducts.fromJson({
              'data': {
                'products': [],
                'page': page,
                'totalPages': 1,
                'totalItems': 0,
              },
            });
          }

          final productsList = json['data']['products'] as List;

          // Sayfalama bilgilerini al
          final currentPage = json['data']['page'] as int? ?? page;
          final totalPages = json['data']['totalPages'] as int? ?? 1;
          final totalItems =
              json['data']['totalItems'] as int? ?? productsList.length;
          final hasMore = currentPage < totalPages;

          // İlk birkaç ürünü logla
          if (productsList.isNotEmpty) {
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

          // PaginatedProducts.fromJson kullanarak parse et
          return PaginatedProducts.fromJson(json as Map<String, dynamic>);
        },
      );

      return response;
    } catch (e) {
      return ApiResponse<PaginatedProducts>.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<PaginatedProducts>> getAllProductsWithFilter({
    required ProductFilter filter,
    int page = 1,
    int limit = AppConstants.defaultPageSize,
  }) async {
    try {
      final fullUrl = '${ApiConstants.fullUrl}${ApiConstants.allProducts}';

      // User token'ı al
      String userToken = '';
      try {
        final prefs = await SharedPreferences.getInstance();
        userToken = prefs.getString(AppConstants.userTokenKey) ?? '';
      } catch (e) {}

      // Konum bilgilerini al (eğer location sorting seçiliyse)
      String? userLat;
      String? userLong;

      if (filter.sortType == 'location') {
        final locationService = LocationService();

        try {
          // Önce konum izinlerini kontrol et
          final hasPermission = await locationService.checkLocationPermission();
          if (!hasPermission) {
            filter = filter.copyWith(sortType: 'default');
          } else {
            // GPS servisinin açık olup olmadığını kontrol et
            final isLocationEnabled = await locationService
                .isLocationServiceEnabled();
            if (!isLocationEnabled) {
              filter = filter.copyWith(sortType: 'default');
            } else {
              // Konumu al
              final locationData = await locationService
                  .getCurrentLocationAsStrings();
              if (locationData != null) {
                userLat = locationData['latitude'];
                userLong = locationData['longitude'];
              } else {
                filter = filter.copyWith(sortType: 'default');
              }
            }
          }
        } catch (e) {
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

      final response = await _httpClient.postWithBasicAuth<PaginatedProducts>(
        ApiConstants.allProducts,
        body: body,
        useBasicAuth: true,
        fromJson: (json) {
          // JSON yapısını kontrol et
          if (json == null) {
            return PaginatedProducts(
              products: [],
              currentPage: page,
              totalPages: 1,
              totalItems: 0,
              hasMore: false,
            );
          }

          // Yeni API formatını kontrol et
          if (json case {
            'success': true,
            'data': final Map<String, dynamic> data,
          }) {
            if (data['products'] case final List<dynamic> productsList) {
              final products = productsList
                  .map((item) => _transformNewApiProductToModel(item))
                  .toList();

              // PaginatedProducts.fromJson kullanarak parse et
              return PaginatedProducts.fromJson(json as Map<String, dynamic>);
            }
          }

          // 410 status code için özel handling
          if (json case {'error': false, '410': 'Gone'}) {
            if (json['data'] != null && json['data']['products'] != null) {
              final productsList = json['data']['products'] as List;

              final products = productsList
                  .map((item) => _transformNewApiProductToModel(item))
                  .toList();

              return PaginatedProducts.fromJson({
                'data': {
                  'products': productsList,
                  'page': page,
                  'totalPages': 1,
                  'totalItems': products.length,
                },
              });
            }
            return PaginatedProducts.fromJson({
              'data': {
                'products': [],
                'page': page,
                'totalPages': 1,
                'totalItems': 0,
              },
            });
          }

          // Boş success response
          if (json case {'error': false, '200': 'OK'}) {
            return PaginatedProducts.fromJson({
              'data': {
                'products': [],
                'page': page,
                'totalPages': 1,
                'totalItems': 0,
              },
            });
          }

          return PaginatedProducts.fromJson({
            'data': {
              'products': [],
              'page': page,
              'totalPages': 1,
              'totalItems': 0,
            },
          });
        },
      );

      return response;
    } catch (e) {
      return ApiResponse<PaginatedProducts>.error(ErrorMessages.unknownError);
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
        '🌐 ProductService - Full URL: ${ApiConstants.fullUrl}${ApiConstants.allProducts}',
      );

      final response = await _httpClient.getWithBasicAuth(
        ApiConstants.allProducts,
        queryParams: queryParams,
        fromJson: (json) {
          // Yeni API formatını kontrol et
          if (json case {
            'success': true,
            'data': final Map<String, dynamic> data,
          }) {
            if (data['products'] case final List<dynamic> productsList) {
              print(
                '🔍 ProductService - Page info: ${data['page']}/${data['totalPages']}, Total: ${data['totalItems']}',
              );

              final products = productsList
                  .map((item) => _transformNewApiProductToModel(item))
                  .toList();

              return products;
            }
          }

          // Eski format kontrolü (backward compatibility)
          if (json case {'data': {'products': final List<dynamic> list}}) {
            final products = list
                .map((item) => _transformApiProductToModel(item))
                .toList();
            return products;
          }

          // Eğer sadece success mesajı geliyorsa (ürün yok)
          if (json case {'error': false, '200': 'OK'}) {
            return <Product>[];
          }

          // 410 status code için özel handling
          if (json case {'error': false, '410': 'Gone'}) {
            // 410 response'unda da ürünler olabilir, kontrol et
            if (json['data'] != null && json['data']['products'] != null) {
              final productsList = json['data']['products'] as List;

              final products = productsList
                  .map((item) => _transformNewApiProductToModel(item))
                  .toList();

              return products;
            }
            return <Product>[];
          }

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
        body: {
          'productID': int.tryParse(productId) ?? productId,
        }, // Product ID'yi body'de gönder
        useBasicAuth: true,
        fromJson: (json) {
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
              throw Exception('Ürün verisi parse edilemedi');
            }
          }
          throw Exception('Geçersiz API yanıtı');
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  /// Ürün detayını getirir (410: başarı, 417: hata)
  /// Kullanıcının giriş durumuna göre API endpoint'ini dinamik olarak yönetir
  /// Giriş yapmış kullanıcı: /service/user/product/{productId}/productDetail?userToken={token}
  /// Giriş yapmamış kullanıcı: /service/user/product/{productId}/productDetail
  Future<ApiResponse<Product>> getProductDetail({
    String? userToken,
    required String productId,
  }) async {
    try {
      // Kullanıcının giriş durumuna göre endpoint'i hazırla
      String endpoint;
      Map<String, dynamic>? queryParams;

      if (userToken != null && userToken.isNotEmpty) {
        // Giriş yapmış kullanıcı - userToken query parameter olarak ekle
        endpoint = '${ApiConstants.productDetail}/$productId/productDetail';
        queryParams = {'userToken': userToken};
      } else {
        // Giriş yapmamış kullanıcı - sadece endpoint
        endpoint = '${ApiConstants.productDetail}/$productId/productDetail';
      }

      final response = await _httpClient.getWithBasicAuth(
        endpoint,
        queryParams: queryParams,
        fromJson: (json) {
          // Puan bilgilerini kontrol et
          if (json is Map<String, dynamic>) {}

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
            throw Exception(
              json['error_message'] ?? json['message'] ?? 'Beklenmeyen hata',
            );
          }
          // Diğer durumlar
          throw Exception('Ürün detayı alınamadı');
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<List<Product>>> getProductsByUserId(String userId) async {
    try {
      final endpoint = '${ApiConstants.userProducts}/$userId/productList';

      // Çalışan categories endpoint ile karşılaştırma için

      // Basic auth ile dene (endpoint basic auth gerektiriyor)
      final response = await _httpClient.getWithBasicAuth(
        endpoint,
        fromJson: (json) {
          // API'den dönen response formatına göre parsing
          if (json case {'data': {'products': final List<dynamic> list}}) {
            final products = list
                .map((item) => _transformApiProductToModel(item))
                .toList();

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
            print(
              '🔍 ProductService - Raw API data for first product (userProductList):',
            );
            if (list.isNotEmpty) {
              final firstProduct = list.first;
              print(
                '🔍 ProductService - First product keys: ${firstProduct.keys.toList()}',
              );
              print(
                '🔍 ProductService - First product cityTitle: ${firstProduct['cityTitle']}',
              );
              print(
                '🔍 ProductService - First product districtTitle: ${firstProduct['districtTitle']}',
              );
              print(
                '🔍 ProductService - First product cityID: ${firstProduct['cityID']}',
              );
              print(
                '🔍 ProductService - First product districtID: ${firstProduct['districtID']}',
              );
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
              print(
                '🔍 ProductService - First product keys: ${firstProduct.keys.toList()}',
              );
              print(
                '🔍 ProductService - First product cityTitle: ${firstProduct['cityTitle']}',
              );
              print(
                '🔍 ProductService - First product districtTitle: ${firstProduct['districtTitle']}',
              );
              print(
                '🔍 ProductService - First product cityID: ${firstProduct['cityID']}',
              );
              print(
                '🔍 ProductService - First product districtID: ${firstProduct['districtID']}',
              );
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
    // Kategori verilerini debug et

    apiProduct.forEach((key, value) {
      if (key.toString().toLowerCase().contains('categor') ||
          key.toString().toLowerCase().contains('cat')) {}
    });

    // 3 katmanlı kategori sistemi için tüm alanları kontrol et

    if (apiProduct['categoryList'] != null) {
      final categoryList = apiProduct['categoryList'] as List;

      for (int i = 0; i < categoryList.length; i++) {
        final category = categoryList[i];

        if (category is Map) {}
      }
    } else {}

    // Resim URL'ini debug et
    final imageUrl = apiProduct['productImage'];

    // Görsel URL'lerini tam URL'e dönüştür
    final images = <String>[];

    // Ana resim işleme
    final productImage = apiProduct['productImage']?.toString();
    if (productImage != null &&
        productImage.isNotEmpty &&
        productImage != 'null' &&
        productImage != 'undefined' &&
        !productImage.contains(
          'product_68852b20b6cac.png',
        ) && // Hatalı URL'yi filtrele
        Uri.tryParse(productImage) != null) {
      // URL formatını kontrol et
      // Eğer URL zaten tam URL ise olduğu gibi kullan, değilse base URL ile birleştir
      final fullImageUrl = productImage.startsWith('http')
          ? productImage
          : '${ApiConstants.baseUrl}$productImage';
      images.add(fullImageUrl);
    } else {}

    // extraImages varsa onları da ekle
    if (apiProduct['extraImages'] != null) {
      final extraImages = apiProduct['extraImages'] as List;

      for (final extraImage in extraImages) {
        final extraImageStr = extraImage?.toString();
        if (extraImageStr != null &&
            extraImageStr.isNotEmpty &&
            extraImageStr != 'null' &&
            extraImageStr != 'undefined' &&
            !extraImageStr.contains(
              'product_68852b20b6cac.png',
            ) && // Hatalı URL'yi filtrele
            Uri.tryParse(extraImageStr) != null) {
          // URL formatını kontrol et
          final fullImageUrl = extraImageStr.startsWith('http')
              ? extraImageStr
              : '${ApiConstants.baseUrl}$extraImageStr';
          images.add(fullImageUrl);
        } else {}
      }
    }

    // categoryList'ten kategori bilgilerini parse et
    String? mainCategoryName;
    String? parentCategoryName;
    String? subCategoryName;
    String? mainCategoryId;
    String? parentCategoryId;
    String? subCategoryId;

    if (apiProduct['categoryList'] != null) {
      final categoryList = apiProduct['categoryList'] as List;

      if (categoryList.length >= 1) {
        // İlk kategori ana kategori olarak kabul edilir
        final mainCat = categoryList[0];

        if (mainCat is Map) {
          mainCategoryId = mainCat['catID']?.toString();
          mainCategoryName = mainCat['catName']?.toString();
        }
      }

      if (categoryList.length >= 2) {
        // İkinci kategori üst kategori olarak kabul edilir
        final parentCat = categoryList[1];

        if (parentCat is Map) {
          parentCategoryId = parentCat['catID']?.toString();
          parentCategoryName = parentCat['catName']?.toString();
        }
      }

      if (categoryList.length >= 3) {
        // Üçüncü kategori alt kategori olarak kabul edilir
        final subCat = categoryList[2];

        if (subCat is Map) {
          subCategoryId = subCat['catID']?.toString();
          subCategoryName = subCat['catName']?.toString();
        }
      }

      // categoryId'yi categoryList'teki son kategorinin ID'si olarak ayarla
      // Bu, en spesifik kategoriyi temsil eder
      if (categoryList.isNotEmpty) {
        final lastCategory = categoryList.last;
        if (lastCategory is Map) {
          final lastCategoryId = lastCategory['catID']?.toString();
          final lastCategoryName = lastCategory['catName']?.toString();

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
      grandParentCategoryName: apiProduct['grandParentCategoryTitle']
          ?.toString(),
      mainCategoryId: mainCategoryId,
      mainCategoryName: mainCategoryName,
      subCategoryId: subCategoryId,
      subCategoryName: subCategoryName,
      category: Category(
        id: apiProduct['categoryID']?.toString() ?? '',
        name:
            mainCategoryName ??
            parentCategoryName ??
            subCategoryName ??
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
      // Sponsor bilgilerini ekle
      isSponsor: apiProduct['isSponsor'] as bool? ?? false,
      sponsorUntil: apiProduct['sponsorUntil']?.toString(),
    );

    // Adres bilgilerini debug et

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
    } catch (e) {}

    return DateTime.now();
  }

  // Eski API formatını Product model formatına dönüştürür (backward compatibility)
  Product _transformApiProductToModel(Map<String, dynamic> apiProduct) {
    final categoryId = apiProduct['productCatID']?.toString() ?? '';
    final categoryName = apiProduct['productCatname'] ?? '';

    // Görsel URL'lerini tam URL'e dönüştür
    final images = <String>[];

    // Ana resim işleme
    final productImage = apiProduct['productImage']?.toString();
    if (productImage != null &&
        productImage.isNotEmpty &&
        productImage != 'null' &&
        productImage != 'undefined' &&
        !productImage.contains(
          'product_68852b20b6cac.png',
        ) && // Hatalı URL'yi filtrele
        Uri.tryParse(productImage) != null) {
      // URL formatını kontrol et
      final fullImageUrl = productImage.startsWith('http')
          ? productImage
          : '${ApiConstants.baseUrl}$productImage';
      images.add(fullImageUrl);
    }

    // extraImages varsa onları da ekle
    if (apiProduct['extraImages'] != null) {
      final extraImages = apiProduct['extraImages'] as List;

      for (final extraImage in extraImages) {
        final extraImageStr = extraImage?.toString();
        if (extraImageStr != null &&
            extraImageStr.isNotEmpty &&
            extraImageStr != 'null' &&
            extraImageStr != 'undefined' &&
            !extraImageStr.contains(
              'product_68852b20b6cac.png',
            ) && // Hatalı URL'yi filtrele
            Uri.tryParse(extraImageStr) != null) {
          // URL formatını kontrol et
          final fullImageUrl = extraImageStr.startsWith('http')
              ? extraImageStr
              : '${ApiConstants.baseUrl}$extraImageStr';
          images.add(fullImageUrl);
        } else {}
      }
    }

    // Adres bilgilerini debug et
    final cityTitle = apiProduct['cityTitle'] ?? '';
    final districtTitle = apiProduct['districtTitle'] ?? '';

    // Sponsor bilgilerini kontrol et
    final isSponsor = apiProduct['isSponsor'] as bool? ?? false;
    final sponsorUntil = apiProduct['sponsorUntil']?.toString();

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
      // Sponsor bilgilerini ekle
      isSponsor: isSponsor,
      sponsorUntil: sponsorUntil,
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

  /// Mevcut URL'yi download edip temporary file'a yazar
  Future<File?> _downloadImageAsFile(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final tempDir = Directory.systemTemp;
        final fileName = imageUrl
            .split('/')
            .last
            .split('?')
            .first; // Query parametrelerini temizle
        final file = File('${tempDir.path}/temp_$fileName');
        await file.writeAsBytes(response.bodyBytes);
        print('📥 Downloaded image: ${file.path.split('/').last}');
        return file;
      }
    } catch (e) {
      print('❌ Failed to download image $imageUrl: $e');
    }
    return null;
  }

  /// Temporary dosyaları temizle
  void _cleanupTemporaryFiles(Map<String, File> files) {
    int cleanedCount = 0;
    for (final file in files.values) {
      if (file.path.contains('temp_')) {
        try {
          file.deleteSync();
          print('🧹 Cleaned temp file: ${file.path.split('/').last}');
          cleanedCount++;
        } catch (e) {
          print('⚠️ Failed to clean temp file: ${file.path.split('/').last}');
        }
      }
    }
    if (cleanedCount > 0) {
      print('🧹 Cleanup completed: $cleanedCount temporary files removed');
    }
  }

  Future<ApiResponse<Product?>> updateProduct(
    String productId, {
    required String userToken,
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
    // Token geçerliliğini kontrol et
    if (userToken.isEmpty) {
      return ApiResponse.error('Kullanıcı token\'ı bulunamadı');
    }

    // Files'ı dışarda declare et (cleanup için)
    final files = <String, File>{};

    try {
      // SharedPreferences'dan userId'yi al
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString(AppConstants.userIdKey);

      if (currentUserId == null || currentUserId.isEmpty) {
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
        return ApiResponse.error('Ürün başlığı zorunludur');
      }

      if (description != null && description.isNotEmpty) {
        body['productDesc'] = description;
      } else {
        return ApiResponse.error('Ürün açıklaması zorunludur');
      }

      if (categoryId != null && categoryId.isNotEmpty) {
        body['categoryID'] = int.tryParse(categoryId) ?? categoryId;
      } else {
        return ApiResponse.error('Kategori seçimi zorunludur');
      }

      if (conditionId != null && conditionId.isNotEmpty) {
        body['conditionID'] = int.tryParse(conditionId) ?? conditionId;
      } else {
        return ApiResponse.error('Ürün durumu seçimi zorunludur');
      }

      // Konum bilgileri - sadece sağlanırsa gönder
      if (cityId != null && cityId.isNotEmpty) {
        body['productCity'] = int.tryParse(cityId) ?? cityId;
      }
      if (districtId != null && districtId.isNotEmpty) {
        body['productDistrict'] = int.tryParse(districtId) ?? districtId;
      }

      // Koordinat bilgileri - sadece sağlanırsa gönder
      if (productLat != null && productLat.isNotEmpty) {
        body['productLat'] = productLat;
      }
      if (productLong != null && productLong.isNotEmpty) {
        body['productLong'] = productLong;
      }

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

      // Resimler için files hazırla (eğer varsa) - files zaten üstte tanımlı
      final newImageFiles = <File>[];

      // Sadece yeni dosyalar için file işleme (images artık sadece dosya yolları içeriyor)
      if (images != null && images.isNotEmpty) {
        for (int i = 0; i < images.length; i++) {
          final imagePath = images[i];
          // Dosya yolu kontrolü (URL değil, dosya yolu olmalı)
          if (imagePath.startsWith('/') ||
              imagePath.contains('\\') ||
              imagePath.contains('/')) {
            final file = File(imagePath);
            if (await file.exists()) {
              newImageFiles.add(file);
            } else {
              print('⚠️ File not found: $imagePath');
            }
          } else {
            print(
              '⚠️ Unexpected image format (should be file path): $imagePath',
            );
          }
        }
      }

      // STRATEJİ 2: Mevcut resimleri farklı field adı ile gönder
      final urlsToKeep = <String>{};
      if (existingImageUrls != null) {
        urlsToKeep.addAll(existingImageUrls.where((e) => e.trim().isNotEmpty));
      }

      // STRATEJİ 3: Mevcut URL'leri download edip file olarak gönder (keepImages[] çalışmadı!)
      int totalFileIndex = 0;

      // Önce mevcut resimleri download et ve file olarak ekle
      if (urlsToKeep.isNotEmpty) {
        for (final url in urlsToKeep) {
          final downloadedFile = await _downloadImageAsFile(url);
          if (downloadedFile != null) {
            files['productImages[$totalFileIndex]'] = downloadedFile;

            totalFileIndex++;
          } else {}
        }
      }

      // Sonra yeni dosyaları ekle
      if (newImageFiles.isNotEmpty) {
        for (final file in newImageFiles) {
          files['productImages[$totalFileIndex]'] = file;

          totalFileIndex++;
        }
      }

      // Final debug - artık sadece files var (field'larda resim yok)

      fields.forEach((key, value) {
        if (!key.startsWith('keepImages') &&
            !key.startsWith('productImages')) {}
      });

      files.forEach((key, file) {
        final isDownloaded = file.path.contains('temp_');
        final icon = isDownloaded ? '📥' : '📸';
        final type = isDownloaded ? 'downloaded' : 'new';
      });

      // Multipart form-data ile gönder (multipleFiles kullanmıyoruz artık)
      final response = await _httpClient.postMultipart<Product?>(
        endpoint,
        fields: fields,
        files: files.isNotEmpty ? files : null,
        multipleFiles: null, // artık kullanmıyoruz
        fromJson: (json) {
          // API response'unu detaylı analiz et

          // Özel format: {"error": false, "200": "OK"} - Bu başarılı güncelleme anlamına gelir
          if (json.containsKey('error') && json.containsKey('200')) {
            final errorValue = json['error'];
            final statusValue = json['200'];

            if (errorValue == false && statusValue == 'OK') {
              return null;
            }
          }

          // success field'ını kontrol et
          if (json.containsKey('success')) {
            final successValue = json['success'];
          }

          // message field'ını kontrol et
          if (json.containsKey('message')) {
            final messageValue = json['message'];
          }

          // data field'ını kontrol et
          if (json.containsKey('data')) {
            final dataValue = json['data'];

            // data her zaman Map olarak bekleniyor, tür kontrolü gereksiz
            try {
              return Product.fromJson(dataValue as Map<String, dynamic>);
            } catch (_) {}
          }

          // Eğer data field'ı yoksa, tüm response'u Product olarak parse etmeye çalış
          try {
            return Product.fromJson(Map<String, dynamic>.from(json));
          } catch (e) {
            print('❌ Failed to parse response as Product: $e');
            throw Exception('Ürün güncellenirken yanıt formatı hatalı');
          }
        },
        useBasicAuth: true,
      );

      // Cleanup: Download edilen temporary dosyaları sil
      _cleanupTemporaryFiles(files);

      return response;
    } catch (e) {
      // Exception durumunda da cleanup yap
      _cleanupTemporaryFiles(files);

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
    // Token geçerliliğini kontrol et
    if (userToken.isEmpty) {
      return ApiResponse.error('Kullanıcı token\'ı bulunamadı');
    }

    try {
      // Token'ı request body'de göndereceğiz
      final prefs = await SharedPreferences.getInstance();

      final currentUserId = prefs.getString(AppConstants.userIdKey);

      // Token'ın geçerliliğini kontrol et

      // Doğru endpoint formatını kullan - userId kullanılmalı
      final endpoint =
          '${ApiConstants.deleteProduct}/$currentUserId/deleteProduct';
      final fullUrl = '${ApiConstants.fullUrl}$endpoint';

      // API'nin beklediği format: {"userToken": "...", "productID": 1}
      final body = {
        'userToken': userToken,
        'productID': int.parse(productId), // API integer bekliyor
      };

      // Alternatif format 1: productId string olarak
      final bodyAlt1 = {
        'userToken': userToken,
        'productID': productId, // String olarak
      };

      // Alternatif format 2: productId yerine id
      final bodyAlt2 = {'userToken': userToken, 'id': int.parse(productId)};

      // DELETE HTTP metodunu basic auth ile kullan

      // Önce orijinal formatı dene
      var response = await _httpClient
          .deleteWithBasicAuth<Map<String, dynamic>>(
            endpoint,
            body: body,
            fromJson: (json) {
              // Hata mesajlarını özel olarak kontrol et
              if (json is Map<String, dynamic>) {
                if (json.containsKey('message')) {
                  final message = json['message']?.toString() ?? '';
                  if (message.contains('Erişim reddedildi') ||
                      message.contains('Access denied') ||
                      message.contains('Unauthorized') ||
                      message.contains('403')) {}
                }
              }

              // API response'unu detaylı analiz et
              if (json is Map<String, dynamic>) {
                // success field'ını kontrol et - type safety için
                if (json.containsKey('success')) {
                  final successValue = json['success'];
                }

                // error field'ını kontrol et - type safety için
                if (json.containsKey('error')) {
                  final errorValue = json['error'];
                }

                // message field'ını kontrol et - type safety için
                if (json.containsKey('message')) {
                  final messageValue = json['message'];
                }

                // data field'ını kontrol et
                if (json.containsKey('data')) {
                  final dataValue = json['data'];

                  if (dataValue is Map<String, dynamic>) {
                    return dataValue;
                  }
                }
              }

              // Safe casting
              if (json is Map<String, dynamic>) {
                return json;
              } else {
                return <String, dynamic>{'rawResponse': json};
              }
            },
          );

      // 403 hatası alındıysa alternatif formatları dene
      if (!response.isSuccess &&
          response.error != null &&
          (response.error!.contains('403') ||
              response.error!.contains('Forbidden') ||
              response.error!.contains('Invalid user token') ||
              response.error!.contains('Üye doğrulama bilgileri hatalı'))) {
        // Format 1: productID as string

        var altResponse1 = await _httpClient
            .deleteWithBasicAuth<Map<String, dynamic>>(
              endpoint,
              body: bodyAlt1,
              fromJson: (json) {
                if (json is Map<String, dynamic>) {
                  return json;
                } else {
                  return <String, dynamic>{'rawResponse': json};
                }
              },
            );

        if (altResponse1.isSuccess) {
          return altResponse1;
        }

        // Format 2: id instead of productID

        var altResponse2 = await _httpClient
            .deleteWithBasicAuth<Map<String, dynamic>>(
              endpoint,
              body: bodyAlt2,
              fromJson: (json) {
                if (json is Map<String, dynamic>) {
                  return json;
                } else {
                  return <String, dynamic>{'rawResponse': json};
                }
              },
            );

        if (altResponse2.isSuccess) {
          return altResponse2;
        }
      }

      // KRITIK: API response'unu detaylı analiz et
      if (response.isSuccess) {
        if (response.data != null) {
          final data = response.data!;

          // Başarı mesajlarını kontrol et - type safety ile
          if (data.containsKey('message')) {
            final message = data['message'];
          }
          if (data.containsKey('success')) {
            final success = data['success'];

            // Boolean veya string olabilir, her ikisini de kontrol et
            if (success == false || success == 'false' || success == '0') {
              final errorMsg = data['message']?.toString() ?? 'Ürün silinemedi';
              return ApiResponse.error(errorMsg);
            }
          }
        }
      } else {}

      return response;
    } catch (e, stackTrace) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<List<Category>>> getCategories() async {
    try {
      final response = await _httpClient.getWithBasicAuth(
        ApiConstants.categoriesList,
        fromJson: (json) {
          if (json['data'] == null || json['data']['categories'] == null) {
            return <Category>[];
          }

          final categoriesList = json['data']['categories'] as List;

          // Kategori verilerini detaylı logla

          for (int i = 0; i < categoriesList.length; i++) {
            final category = categoriesList[i];
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

          for (int i = 0; i < parsedCategories.length; i++) {
            final category = parsedCategories[i];
          }

          return parsedCategories;
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  /// Popüler kategorileri getirir
  Future<ApiResponse<List<PopularCategory>>> getPopularCategories() async {
    try {
      final response = await _httpClient
          .getWithBasicAuth<List<PopularCategory>>(
            ApiConstants.popularCategories,
            fromJson: (json) {
              try {
                // API response yapısına göre parse et
                final popularCategoriesResponse =
                    PopularCategoriesResponse.fromJson(json);

                if (!popularCategoriesResponse.success ||
                    popularCategoriesResponse.error) {
                  return <PopularCategory>[];
                }

                final categories = popularCategoriesResponse.data.categories;

                return categories;
              } catch (e) {
                return <PopularCategory>[];
              }
            },
          );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<List<Category>>> getSubCategories(
    String parentCategoryId,
  ) async {
    print(
      ' Getting sub-categories for parent $parentCategoryId from service/general/general/categories/$parentCategoryId',
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

  Future<ApiResponse<List<Category>>> getSubSubCategories(
    String parentSubCategoryId,
  ) async {
    try {
      final response = await _httpClient.getWithBasicAuth(
        '${ApiConstants.subSubCategories}/$parentSubCategoryId',
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

          final categories = categoriesList
              .map(
                (item) => Category(
                  id: item['catID'].toString(),
                  name: item['catName'],
                  icon: item['catImage'] ?? '',
                  parentId: parentSubCategoryId,
                  children: null,
                  isActive: true,
                  order: 0,
                ),
              )
              .toList();

          for (var cat in categories) {}

          return categories;
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<List<Category>>> getSubSubSubCategories(
    String parentSubSubCategoryId,
  ) async {
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

          final categories = categoriesList
              .map(
                (item) => Category(
                  id: item['catID'].toString(),
                  name: item['catName'],
                  icon: item['catImage'] ?? '',
                  parentId: parentSubSubCategoryId,
                  children: null,
                  isActive: true,
                  order: 0,
                ),
              )
              .toList();

          return categories;
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<List<City>>> getCities() async {
    final fullUrl = '${ApiConstants.fullUrl}service/general/general/cities/all';

    try {
      final response = await _httpClient.getWithBasicAuth(
        ApiConstants.cities,
        fromJson: (json) {
          // JSON yapısını kontrol et
          if (json == null) {
            return <City>[];
          }

          if (json['data'] == null) {
            return <City>[];
          }

          if (json['data']['cities'] == null) {
            return <City>[];
          }

          final citiesList = json['data']['cities'] as List;

          // İlk birkaç şehri logla
          if (citiesList.isNotEmpty) {
            for (
              int i = 0;
              i < (citiesList.length > 5 ? 5 : citiesList.length);
              i++
            ) {
              final city = citiesList[i];
            }
          }

          final cities = citiesList.map((item) => City.fromJson(item)).toList();

          return cities;
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<List<District>>> getDistricts(String cityId) async {
    try {
      final response = await _httpClient.getWithBasicAuth(
        '${ApiConstants.districts}/$cityId',
        fromJson: (json) {
          // Farklı yanıt formatlarını kontrol et
          if (json['data'] != null && json['data']['districts'] != null) {
            final districtsList = json['data']['districts'] as List;

            // İlk birkaç ilçeyi logla
            if (districtsList.isNotEmpty) {
              for (
                int i = 0;
                i < (districtsList.length > 5 ? 5 : districtsList.length);
                i++
              ) {
                final district = districtsList[i];
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
            return <District>[];
          }
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<List<Condition>>> getConditions() async {
    final fullUrl =
        '${ApiConstants.fullUrl}/service/general/general/productConditions';

    try {
      final response = await _httpClient.getWithBasicAuth(
        ApiConstants.productConditions,
        fromJson: (json) {
          // JSON yapısını kontrol et
          if (json == null) {
            return <Condition>[];
          }

          if (json['data'] == null) {
            return <Condition>[];
          }

          if (json['data']['conditions'] == null) {
            return <Condition>[];
          }

          final conditionsList = json['data']['conditions'] as List;

          // İlk birkaç durumu logla
          if (conditionsList.isNotEmpty) {
            for (int i = 0; i < conditionsList.length; i++) {
              final condition = conditionsList[i];
            }
          }

          final conditions = conditionsList
              .map((item) => Condition.fromJson(item))
              .toList();

          return conditions;
        },
      );

      return response;
    } catch (e) {
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

        // ignore: empty_catches
      } catch (e) {}

      // Kullanıcının kendi ürünü olup olmadığını kontrol et
      try {
        final productDetailResponse = await getProductDetail(
          userToken: userToken,
          productId: productId,
        );
        if (productDetailResponse.isSuccess &&
            productDetailResponse.data != null) {
          final product = productDetailResponse.data!;
          if (product.ownerId == userId) {
            return ApiResponse.error('Kendi ürününüzü favoriye ekleyemezsiniz');
          }
        }
      } catch (e) {
        // Ürün sahipliği kontrolü başarısız olsa bile devam et
      }

      // API body'sini hazırla
      final body = {'userToken': userToken, 'productID': productId};

      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.addFavorite,
        body: body,
        fromJson: (json) {
          return null;
        },
        useBasicAuth: true,
      );

      return response;
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  Future<ApiResponse<void>> removeFromFavorites(String productId) async {
    try {
      // User token ve userId'yi al
      String userToken = '';
      String userId = '';
      try {
        final prefs = await SharedPreferences.getInstance();
        userToken = prefs.getString(AppConstants.userTokenKey) ?? '';
        userId = prefs.getString(AppConstants.userIdKey) ?? '';
      } catch (e) {}

      // API body'sini hazırla
      final body = {'userToken': userToken, 'productID': productId};
      final response = await _httpClient.postWithBasicAuth(
        ApiConstants.removeFavorite,
        body: body,
        useBasicAuth: true,
        fromJson: (json) {
          print('📥 Remove from favorites response: $json');
          print('📊 Remove from favorites response type: ${json.runtimeType}');
          print(
            '📊 Remove from favorites response keys: ${json is Map ? json.keys.toList() : 'Not a map'}',
          );
          if (json is Map) {
            print('📊 Remove from favorites success: ${json['success']}');
            print('📊 Remove from favorites error: ${json['error']}');
            print('📊 Remove from favorites message: ${json['message']}');

            // API response'unu detaylı analiz et
            if (json.containsKey('error') && json.containsKey('200')) {
              final errorValue = json['error'];
              final statusValue = json['200'];
              print('📊 Remove from favorites - Special format detected');
              print(
                '📊 Remove from favorites - Error: $errorValue, Status: $statusValue',
              );

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
            if (json.containsKey('error') &&
                json['error'] == false &&
                json.containsKey('410')) {
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
        print(
          '🔑 User token retrieved: ${userToken.isNotEmpty ? "${userToken.substring(0, 20)}..." : "empty"}',
        );
        print('🔑 User ID retrieved: $userId');
      } catch (e) {
        print('⚠️ Error getting user token: $e');
      }

      // Query parametreleri hazırla
      final queryParams = {'userToken': userToken};
      print('🌐 Get favorites query params: $queryParams');

      print(
        '🌐 Calling getFavoriteProducts API with endpoint: ${ApiConstants.favoriteList}/$userId/favoriteList',
      );
      print(
        '🌐 Full URL: ${ApiConstants.fullUrl}${ApiConstants.favoriteList}/$userId/favoriteList',
      );
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
              print(
                '📦 410 response returned ${productsList.length} favorite products',
              );

              // Ürün detaylarını logla
              for (int i = 0; i < productsList.length; i++) {
                final product = productsList[i];
                print(
                  '📦 Favorite product $i: ${product['productTitle']} (ID: ${product['productID']})',
                );
              }

              final products = productsList
                  .map((item) => _transformNewApiProductToModel(item))
                  .toList();
              print(
                '📦 Parsed ${products.length} favorite products successfully from 410',
              );
              return products;
            }
            return <Product>[];
          }

          // Normal success response
          if (json case {'error': false, 'success': true}) {
            print('🔍 Get favorites - Normal success response');
            if (json['data'] != null && json['data']['products'] != null) {
              final productsList = json['data']['products'] as List;
              print(
                '📦 Success response returned ${productsList.length} favorite products',
              );
              final products = productsList
                  .map((item) => _transformNewApiProductToModel(item))
                  .toList();
              print(
                '📦 Parsed ${products.length} favorite products successfully',
              );
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
              print(
                '📦 Get favorites returned ${productsList.length} products',
              );
              final products = productsList
                  .map((item) => _transformNewApiProductToModel(item))
                  .toList();
              print(
                '📦 Parsed ${products.length} favorite products successfully',
              );
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
      final endpoint = '${ApiConstants.productView}/$productId/view';
      final fullUrl = '${ApiConstants.fullUrl}$endpoint';

      final response = await _httpClient.postWithBasicAuth(
        endpoint,
        fromJson: (json) => null,
        useBasicAuth: true,
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
    String? selectedCityTitle,
    String? selectedDistrictTitle,
    bool? isShowContact,
    double? userProvidedLatitude,
    double? userProvidedLongitude,
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

      // Konum bilgilerini kullan (sadece kullanıcı tarafından sağlanmışsa)
      double? latitude = userProvidedLatitude;
      double? longitude = userProvidedLongitude;

      if (latitude != null && longitude != null) {
        print('📍 Using user provided location: $latitude, $longitude');
      } else {
        print('📍 No GPS location provided by user');
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
        'productCityTitle': selectedCityTitle ?? '',
        'productDistrictTitle': selectedDistrictTitle ?? '',
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
            print(
              '🖼️ Processing images for product: ${apiProduct['productTitle']}',
            );
            print('🖼️ Raw productImage: ${apiProduct['productImage']}');
            print('🖼️ Raw extraImages: ${apiProduct['extraImages']}');

            // Ana resim işleme
            final productImage = apiProduct['productImage']?.toString();
            if (productImage != null &&
                productImage.isNotEmpty &&
                productImage != 'null' &&
                productImage != 'undefined' &&
                !productImage.contains(
                  'product_68852b20b6cac.png',
                ) && // Hatalı URL'yi filtrele
                Uri.tryParse(productImage) != null) {
              // URL formatını kontrol et
              final fullImageUrl = productImage.startsWith('http')
                  ? productImage
                  : '${ApiConstants.baseUrl}$productImage';
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
                    !extraImageStr.contains(
                      'product_68852b20b6cac.png',
                    ) && // Hatalı URL'yi filtrele
                    Uri.tryParse(extraImageStr) != null) {
                  // URL formatını kontrol et
                  final fullImageUrl = extraImageStr.startsWith('http')
                      ? extraImageStr
                      : '${ApiConstants.baseUrl}$extraImageStr';
                  images.add(fullImageUrl);
                  print('🖼️ Added extraImage: $fullImageUrl');
                } else {
                  print('⚠️ Skipping invalid extraImage: $extraImageStr');
                }
              }
            }

            print(
              '🖼️ Final images array for ${apiProduct['productTitle']}: $images',
            );
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

      return response;
    } catch (e) {
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

  /// Ürünü sponsor yapar (ödüllü reklam sonrası)
  Future<ApiResponse<Map<String, dynamic>>> sponsorProduct({
    required String userToken,
    required int productId,
  }) async {
    try {
      final body = {'userToken': userToken, 'productID': productId};

      final response = await _httpClient
          .postWithBasicAuth<Map<String, dynamic>>(
            ApiConstants.sponsorEdit,
            body: body,
            fromJson: (json) => json as Map<String, dynamic>,
            useBasicAuth: true,
          );

      if (response.isSuccess && response.data != null) {
        return response;
      } else {
        return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }
}
