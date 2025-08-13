import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:takasly/core/app_theme.dart';
import 'package:takasly/models/city.dart';
import 'package:takasly/models/district.dart';
import 'package:takasly/models/product.dart';
import 'package:takasly/viewmodels/product_viewmodel.dart';
import 'package:takasly/services/image_optimization_service.dart';
import 'package:takasly/utils/logger.dart';

class EditProductView extends StatefulWidget {
  final Product product;
  
  const EditProductView({super.key, required this.product});

  @override
  State<EditProductView> createState() => _EditProductViewState();
}

class _EditProductViewState extends State<EditProductView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _tradePreferencesController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedSubCategoryId;
  String? _selectedSubSubCategoryId;
  String? _selectedSubSubSubCategoryId;
  String? _selectedConditionId;
  String? _selectedCityId;
  String? _selectedDistrictId;
  List<String> _existingImages = [];
  List<File> _newImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isShowContact = false; // İletişim bilgilerinin görünürlüğü
  
  // Yeni state değişkenleri
  bool _isLoadingProductDetail = false;
  bool _isUpdating = false;
  Product? _currentProduct;

  @override
  void initState() {
    super.initState();
    // Önce güncel ürün detaylarını yükle, sonra form alanlarını initialize et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProductDetailAndInitialize();
    });
  }

  /// Ürün detaylarını API'den yükle ve form alanlarını initialize et
  Future<void> _loadProductDetailAndInitialize() async {
    try {
      setState(() {
        _isLoadingProductDetail = true;
      });
      
      Logger.info('🔄 EditProductView - Loading product detail for ID: ${widget.product.id}');
      
      final productViewModel = context.read<ProductViewModel>();
      
      // Güncel ürün detaylarını API'den yükle
      final productDetail = await productViewModel.getProductDetail(widget.product.id);
      
      if (productDetail != null) {
        Logger.info('✅ EditProductView - Product detail loaded successfully');
        setState(() {
          _currentProduct = productDetail;
        });
        
        // Form alanlarını güncel verilerle doldur
        _initializeFieldsWithProductData(productDetail);
        
        // Şehirleri, kategorileri ve koşulları yükle
        await _loadInitialData();
        
      } else {
        Logger.error('❌ EditProductView - Failed to load product detail, using widget product data');
        // API'den yüklenemezse widget'tan gelen veriyi kullan
        setState(() {
          _currentProduct = widget.product;
        });
        _initializeFieldsWithProductData(widget.product);
        await _loadInitialData();
      }
      
    } catch (e) {
      Logger.error('💥 EditProductView - Exception while loading product detail: $e');
      // Hata durumunda widget'tan gelen veriyi kullan
      setState(() {
        _currentProduct = widget.product;
      });
      _initializeFieldsWithProductData(widget.product);
      await _loadInitialData();
    } finally {
      setState(() {
        _isLoadingProductDetail = false;
      });
    }
  }

  /// Şehirleri, kategorileri ve koşulları yükle
  Future<void> _loadInitialData() async {
    try {
      final vm = context.read<ProductViewModel>();
      await Future.wait([
        vm.loadCities(),
        vm.loadConditions(),
        vm.categories.isEmpty ? vm.loadCategories() : Future.value(),
      ]);
    } catch (e) {
      Logger.error('Error loading initial data: $e');
    }
  }

  void _initializeFieldsWithProductData(Product product) {
    try {
      // Güncel ürün bilgilerini form alanlarına yükle
      _titleController.text = product.title;
      _descriptionController.text = product.description;

      _tradePreferencesController.text = product.tradePreferences.join(', ');
      
      _selectedCategoryId = product.categoryId;
      _selectedSubCategoryId = product.subCategoryId?.isNotEmpty == true ? product.subCategoryId : null;
      _selectedSubSubCategoryId = product.subSubCategoryId?.isNotEmpty == true ? product.subSubCategoryId : null;
      _selectedSubSubSubCategoryId = product.subSubSubCategoryId?.isNotEmpty == true ? product.subSubSubCategoryId : null;
      _existingImages = List.from(product.images);
      
      // İletişim bilgileri görünürlüğünü yükle
      _isShowContact = product.isShowContact ?? true;
      
      // Location bilgilerini yükle
      if (product.cityId.isNotEmpty) {
        _selectedCityId = product.cityId;
        _selectedDistrictId = product.districtId;
        
        // Eğer şehir seçili ise ilçeleri yükle
        if (_selectedCityId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              context.read<ProductViewModel>().loadDistricts(_selectedCityId!);
            } catch (e) {
              Logger.error('Error loading districts: $e');
            }
          });
        }
      }
      
      // Kategorileri yükle ve ürün kategorilerini seç - biraz gecikme ile
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _loadAndSelectCategories(product);
        });
      });
      
      // Condition'ı name'den id'ye çevir
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final productViewModel = context.read<ProductViewModel>();
          if (productViewModel.conditions.isNotEmpty) {
            final condition = productViewModel.conditions.firstWhere(
              (c) => c.name == product.condition,
              orElse: () => productViewModel.conditions.first,
            );
            setState(() {
              _selectedConditionId = condition.id;
            });
          }
        } catch (e) {
          Logger.error('Error setting condition: $e');
        }
      });
    } catch (e) {
      Logger.error('Error initializing fields: $e');
    }
  }

  Future<void> _loadAndSelectCategories(Product product) async {
    try {
      final productViewModel = context.read<ProductViewModel>();
      
      // Ana kategorileri yükle
      await productViewModel.loadCategories();
      
      // Eğer categoryList boşsa, categoryId'yi kullan
      if (product.categoryList == null || product.categoryList?.isEmpty == true) {
        if (product.categoryId.isNotEmpty) {
          setState(() {
            _selectedCategoryId = product.categoryId;
          });
          return;
        }
      }
      
      // Ürün kategori listesi varsa kategorileri seç
      if (product.categoryList != null && product.categoryList?.isNotEmpty == true) {
        final productCategories = product.categoryList!;
        
        // İlk kategori ana kategori
        final mainCategory = productCategories.first;
        setState(() {
          _selectedCategoryId = mainCategory.id;
        });
        
        // Ana kategorinin alt kategorilerini yükle
        await productViewModel.loadSubCategories(mainCategory.id);
        
        // İkinci kategori varsa alt kategori olarak seç
        if (productCategories.length > 1) {
          final subCategory = productCategories[1];
          final subCategoryExists = productViewModel.subCategories.any((cat) => cat.id == subCategory.id);
          
          if (subCategoryExists) {
            setState(() {
              _selectedSubCategoryId = subCategory.id;
            });
            
            // Alt kategorinin alt kategorilerini yükle
            await productViewModel.loadSubSubCategories(subCategory.id);
            
            // Üçüncü kategori varsa alt alt kategori olarak seç
            if (productCategories.length > 2) {
              final subSubCategory = productCategories[2];
              final subSubCategoryExists = productViewModel.subSubCategories.any((cat) => cat.id == subSubCategory.id);
              
              if (subSubCategoryExists) {
                setState(() {
                  _selectedSubSubCategoryId = subSubCategory.id;
                });
                
                // Alt alt kategorinin alt kategorilerini yükle
                await productViewModel.loadSubSubSubCategories(subSubCategory.id);
                
                // Dördüncü kategori varsa alt alt alt kategori olarak seç
                if (productCategories.length > 3) {
                  final subSubSubCategory = productCategories[3];
                  final subSubSubCategoryExists = productViewModel.subSubSubCategories.any((cat) => cat.id == subSubSubCategory.id);
                  
                  if (subSubSubCategoryExists) {
                    setState(() {
                      _selectedSubSubSubCategoryId = subSubSubCategory.id;
                    });
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      Logger.error('Error loading and selecting categories: $e');
      // Hata durumunda kullanıcıya bilgi ver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kategoriler yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tradePreferencesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlanı Düzenle'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ProductViewModel>(
        builder: (context, productViewModel, child) {
          // İlan detayları ilk kez yüklenirken tam ekran loader göster
          if (_isLoadingProductDetail) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'İlan detayları yükleniyor...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(context, 'İlan Bilgileri'),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                         textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'İlan Başlığı',
                          counterText: '',
                        ),
                        maxLength: 40,
                        validator: (v) => v!.isEmpty ? 'Başlık zorunludur' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                         textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(labelText: 'Açıklama'),
                        maxLines: 4,
                        validator: (v) => v!.isEmpty ? 'Açıklama zorunludur' : null,
                      ),
                      const SizedBox(height: 24),

                      _buildSectionTitle(context, 'Kategorizasyon'),
                      const SizedBox(height: 16),
                      _buildCategoryDropdown(),
                      const SizedBox(height: 16),
                      Consumer<ProductViewModel>(
                        builder: (context, vm, child) {
                          // Sadece alt kategorileri varsa 2. seviye dropdown'ı göster
                          if (vm.subCategories.isNotEmpty) {
                            return Column(
                              children: [
                                const SizedBox(height: 16),
                                _buildSubCategoryDropdown(),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      Consumer<ProductViewModel>(
                        builder: (context, vm, child) {
                          // Sadece alt kategorileri varsa 3. seviye dropdown'ı göster
                          if (vm.subSubCategories.isNotEmpty) {
                            return Column(
                              children: [
                                const SizedBox(height: 16),
                                _buildSubSubCategoryDropdown(),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      Consumer<ProductViewModel>(
                        builder: (context, vm, child) {
                          // Sadece alt kategorileri varsa 4. seviye dropdown'ı göster
                          if (vm.subSubSubCategories.isNotEmpty) {
                            return Column(
                              children: [
                                const SizedBox(height: 16),
                                _buildSubSubSubCategoryDropdown(),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildConditionDropdown(),
                      const SizedBox(height: 24),

                      _buildSectionTitle(context, 'Ek Bilgiler'),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tradePreferencesController,
                         textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Takas Tercihleri (virgülle ayırın)',
                          hintText: 'Örn: telefon, laptop, kitap',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),

                      _buildSectionTitle(context, 'Konum'),
                      const SizedBox(height: 16),
                      _buildCityDropdown(),
                      const SizedBox(height: 16),
                      _buildDistrictDropdown(),
                      const SizedBox(height: 24),

                      _buildSectionTitle(context, 'Resimler'),
                      const SizedBox(height: 16),
                      _buildImageSection(),
                      const SizedBox(height: 24),

                      _buildSectionTitle(context, 'İletişim Ayarları'),
                      const SizedBox(height: 16),
                      _buildContactSettingsSection(),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _updateProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Ürünü Güncelle',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_isUpdating)
                Positioned.fill(
                  child: Container(
                    color: Colors.black45,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'İlan güncelleniyor...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
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
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppTheme.primary,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        try {
          // Seçili değer geçerli mi kontrol et
          String? validValue = _selectedCategoryId;
          if (validValue != null) {
            final hasValidValue = vm.categories.any((c) => c.id == validValue);
            if (!hasValidValue) {
              validValue = null;
            }
          }

          return DropdownButtonFormField<String>(
            value: validValue,
            decoration: const InputDecoration(labelText: 'Ana Kategori'),
            items: vm.categories
                .map(
                  (cat) => DropdownMenuItem(
                    value: cat.id,
                    child: Text(cat.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategoryId = value;
                _selectedSubCategoryId = null; // Alt kategoriyi sıfırla
              });
              // Alt kategorileri yükle
              if (value != null) {
                vm.loadSubCategories(value);
              }
            },
            validator: (v) => v == null ? 'Ana kategori seçimi zorunludur' : null,
          );
        } catch (e) {
          Logger.error('Error building category dropdown: $e');
          return DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Ana Kategori'),
            items: const [],
            onChanged: (value) {},
          );
        }
      },
    );
  }

  Widget _buildSubCategoryDropdown() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        try {
          // Seçili değer geçerli mi kontrol et
          String? validValue = _selectedSubCategoryId;
          if (validValue != null) {
            final hasValidValue = vm.subCategories.any((c) => c.id == validValue);
            if (!hasValidValue) {
              validValue = null;
            }
          }

          return DropdownButtonFormField<String>(
            value: validValue,
            decoration: InputDecoration(
              labelText: 'Alt Kategori',
              enabled: _selectedCategoryId != null,
            ),
            items: vm.subCategories
                .map(
                  (cat) => DropdownMenuItem(
                    value: cat.id,
                    child: Text(cat.name),
                  ),
                )
                .toList(),
            onChanged: _selectedCategoryId == null
                ? null
                : (value) {
                    setState(() {
                      _selectedSubCategoryId = value;
                      _selectedSubSubCategoryId = null;
                    });
                    if (value != null) {
                      vm.loadSubSubCategories(value);
                    } else {
                      vm.clearSubSubCategories();
                    }
                  },
            validator: (v) => v == null ? 'Alt kategori seçimi zorunludur' : null,
          );
        } catch (e) {
          Logger.error('Error building sub category dropdown: $e');
          return DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Alt Kategori',
              enabled: _selectedCategoryId != null,
            ),
            items: const [],
            onChanged: (value) {},
          );
        }
      },
    );
  }

  Widget _buildSubSubCategoryDropdown() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        try {
          // Seçili değer geçerli mi kontrol et
          String? validValue = _selectedSubSubCategoryId;
          if (validValue != null) {
            final hasValidValue = vm.subSubCategories.any((c) => c.id == validValue);
            if (!hasValidValue) {
              validValue = null;
            }
          }

          return DropdownButtonFormField<String>(
            value: validValue,
            decoration: InputDecoration(
              labelText: 'Alt Alt Kategori',
              enabled: _selectedSubCategoryId != null && vm.subSubCategories.isNotEmpty,
            ),
            items: vm.subSubCategories
                .map(
                  (cat) => DropdownMenuItem(
                    value: cat.id,
                    child: Text(cat.name),
                  ),
                )
                .toList(),
            onChanged: _selectedSubCategoryId == null || vm.subSubCategories.isEmpty
                ? null
                : (value) {
                    setState(() {
                      _selectedSubSubCategoryId = value;
                      _selectedSubSubSubCategoryId = null; // 4. seviye kategoriyi sıfırla
                    });
                    if (value != null) {
                      vm.loadSubSubSubCategories(value);
                    } else {
                      vm.clearSubSubSubCategories();
                    }
                  },
            validator: (v) => v == null ? 'Alt alt kategori seçimi zorunludur' : null,
          );
        } catch (e) {
          Logger.error('Error building sub sub category dropdown: $e');
          return DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Alt Alt Kategori',
              enabled: _selectedSubCategoryId != null,
            ),
            items: const [],
            onChanged: (value) {},
          );
        }
      },
    );
  }

  Widget _buildSubSubSubCategoryDropdown() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        try {
          // Seçili değer geçerli mi kontrol et
          String? validValue = _selectedSubSubSubCategoryId;
          if (validValue != null) {
            final hasValidValue = vm.subSubSubCategories.any((c) => c.id == validValue);
            if (!hasValidValue) {
              validValue = null;
            }
          }

          return DropdownButtonFormField<String>(
            value: validValue,
            decoration: InputDecoration(
              labelText: 'Ürün Kategorisi',
              enabled: _selectedSubSubCategoryId != null && vm.subSubSubCategories.isNotEmpty,
            ),
            items: vm.subSubSubCategories
                .map(
                  (cat) => DropdownMenuItem(
                    value: cat.id,
                    child: Text(cat.name),
                  ),
                )
                .toList(),
            onChanged: _selectedSubSubCategoryId == null || vm.subSubSubCategories.isEmpty
                ? null
                : (value) {
                    setState(() => _selectedSubSubSubCategoryId = value);
                  },
            validator: (v) => v == null ? 'Alt alt alt kategori seçimi zorunludur' : null,
          );
        } catch (e) {
          Logger.error('Error building sub sub sub category dropdown: $e');
          return DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Ürün Kategorisi',
              enabled: _selectedSubSubCategoryId != null,
            ),
            items: const [],
            onChanged: (value) {},
          );
        }
      },
    );
  }

  Widget _buildConditionDropdown() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        try {
          // Seçili değer geçerli mi kontrol et
          String? validValue = _selectedConditionId;
          if (validValue != null) {
            final hasValidValue = vm.conditions.any((c) => c.id == validValue);
            if (!hasValidValue) {
              validValue = null;
            }
          }

          return DropdownButtonFormField<String>(
            value: validValue,
            decoration: const InputDecoration(labelText: 'Ürün Durumu'),
            items: vm.conditions
                .map(
                  (con) => DropdownMenuItem(value: con.id, child: Text(con.name)),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedConditionId = value),
            validator: (v) => v == null ? 'Durum seçimi zorunludur' : null,
          );
        } catch (e) {
          Logger.error('Error building condition dropdown: $e');
          return DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Ürün Durumu'),
            items: const [],
            onChanged: (value) {},
          );
        }
      },
    );
  }

  Widget _buildCityDropdown() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        try {
          // Seçili değer geçerli mi kontrol et
          String? validValue = _selectedCityId;
          if (validValue != null) {
            final hasValidValue = vm.cities.any((c) => c.id == validValue);
            if (!hasValidValue) {
              validValue = null;
            }
          }

          return DropdownButtonFormField<String>(
            value: validValue,
            decoration: const InputDecoration(labelText: 'İl'),
            items: vm.cities
                .map(
                  (city) =>
                      DropdownMenuItem(value: city.id, child: Text(city.name)),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedCityId = value;
                _selectedDistrictId = null;
              });
              if (value != null) {
                context.read<ProductViewModel>().loadDistricts(value);
              }
            },
            validator: (v) => v == null ? 'İl seçimi zorunludur' : null,
          );
        } catch (e) {
          Logger.error('Error building city dropdown: $e');
          return DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'İl'),
            items: const [],
            onChanged: (value) {},
          );
        }
      },
    );
  }

  Widget _buildDistrictDropdown() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        try {
          // Seçili değer geçerli mi kontrol et
          String? validValue = _selectedDistrictId;
          if (validValue != null) {
            final hasValidValue = vm.districts.any((c) => c.id == validValue);
            if (!hasValidValue) {
              validValue = null;
            }
          }

          return DropdownButtonFormField<String>(
            value: validValue,
            decoration: InputDecoration(
              labelText: 'İlçe',
              enabled: _selectedCityId != null,
            ),
            items: vm.districts
                .map(
                  (dist) =>
                      DropdownMenuItem(value: dist.id, child: Text(dist.name)),
                )
                .toList(),
            onChanged: _selectedCityId == null
                ? null
                : (value) => setState(() => _selectedDistrictId = value),
            validator: (v) => v == null ? 'İlçe seçimi zorunludur' : null,
          );
        } catch (e) {
          Logger.error('Error building district dropdown: $e');
          return DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'İlçe',
              enabled: _selectedCityId != null,
            ),
            items: const [],
            onChanged: (value) {},
          );
        }
      },
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Yeni Resim Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_existingImages.isNotEmpty || _newImages.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Mevcut resimler
                ..._existingImages.map((imageUrl) => _buildExistingImageItem(imageUrl)),
                // Yeni eklenen resimler
                ..._newImages.map((imageFile) => _buildNewImageItem(imageFile)),
              ],
            ),
          ),
        if (_existingImages.isEmpty && _newImages.isEmpty)
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Henüz resim eklenmedi',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExistingImageItem(String imageUrl) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Builder(
              builder: (context) {
                // Resim URL'si geçersizse placeholder göster
                if (imageUrl.isEmpty || imageUrl == 'null' || imageUrl == 'undefined') {
                  return Container(
                    width: 120,
                    height: 120,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  );
                }
                
                return CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 120,
                    height: 120,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    return Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    );
                  },
                );
              },
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeExistingImage(imageUrl),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewImageItem(File imageFile) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              imageFile,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeNewImage(imageFile),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final int totalExistingImages = _existingImages.length + _newImages.length;
      final int remainingSlots = 5 - totalExistingImages;
      
      if (remainingSlots <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maksimum 5 fotoğraf olabilir'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final List<XFile> pickedFiles = await _imagePicker.pickMultipleMedia();
      
      if (pickedFiles.isNotEmpty) {
        final List<XFile> filesToAdd = pickedFiles.take(remainingSlots).toList();
        
        // Kullanıcıya optimizasyon başladığını bildir
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fotoğraflar optimize ediliyor...'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        // Seçilen görselleri optimize et
        Logger.debug('🖼️ EditProductView - Optimizing ${filesToAdd.length} selected images...');
        final List<File> optimizedFiles = await ImageOptimizationService.optimizeXFiles(
          filesToAdd, 
          maxImages: remainingSlots,
        );
        
        setState(() {
          _newImages.addAll(optimizedFiles);
        });

        // Kullanıcıya optimizasyon tamamlandığını bildir
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${optimizedFiles.length} fotoğraf optimize edilerek eklendi'),
              backgroundColor: Colors.green,
            ),
          );
        }

        if (pickedFiles.length > remainingSlots) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${pickedFiles.length} resim seçtiniz, ancak sadece $remainingSlots tanesi eklendi (maksimum 5 resim)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      Logger.error('❌ EditProductView - Error picking images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resim seçilirken hata oluştu: $e')),
        );
      }
    }
  }

  void _removeExistingImage(String imageUrl) {
    setState(() {
      _existingImages.remove(imageUrl);
    });
  }

  void _removeNewImage(File imageFile) {
    setState(() {
      _newImages.remove(imageFile);
    });
  }

  Widget _buildContactSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.contact_phone,
                color: AppTheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'İletişim Bilgileri',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Switch
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Telefon numaramı göster',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Açıksa, diğer kullanıcılar size arayabilir',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isShowContact,
                onChanged: (value) {
                  setState(() {
                    _isShowContact = value;
                  });
                },
                activeColor: AppTheme.primary,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Icon(
                _isShowContact ? Icons.check_circle : Icons.info_outline,
                color: _isShowContact ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isShowContact 
                      ? 'Telefon numaranız görünür olacak. Kullanıcılar size arayabilecek.'
                      : 'Telefon numaranız gizli olacak. Sadece mesajlaşma ile iletişim kurulabilir.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _isShowContact ? Colors.green.shade700 : Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Icon(Icons.security, color: Colors.blue, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bu ayarı daha sonra ilan detay sayfasından değiştirebilirsiniz.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

    Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null || _selectedConditionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm zorunlu alanları doldurun')),
      );
      return;
    }

    try {
      setState(() { _isUpdating = true; });
      Logger.info('🔄 EditProductView - Product update started');
      final productViewModel = context.read<ProductViewModel>();
      
      // Resimleri ayır: mevcut resimler URL, yeni resimler dosya yolu
      List<String> existingImageUrls = List.from(_existingImages);
      List<String> newImagePaths = _newImages.map((file) => file.path).toList();
      
      Logger.info('🖼️ EditProductView - Existing images: ${existingImageUrls.length}');
      Logger.info('🆕 EditProductView - New images: ${newImagePaths.length}');
      
      // Trade preferences'ı liste haline getir
      List<String>? tradePreferences;
      if (_tradePreferencesController.text.trim().isNotEmpty) {
        tradePreferences = _tradePreferencesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      
      // Location oluştur
      String? cityId;
      String? cityTitle;
      String? districtId;
      String? districtTitle;
      if (_selectedCityId != null && _selectedDistrictId != null) {
        cityId = _selectedCityId;
        // City ve district title'larını ProductViewModel'den al
        final selectedCity = productViewModel.cities.firstWhere(
          (city) => city.id == _selectedCityId,
          orElse: () => City(id: _selectedCityId!, name: '', plateCode: _selectedCityId!),
        );
        final selectedDistrict = productViewModel.districts.firstWhere(
          (district) => district.id == _selectedDistrictId,
          orElse: () => District(id: _selectedDistrictId!, name: '', cityId: _selectedCityId!),
        );
        cityTitle = selectedCity.name;
        districtId = _selectedDistrictId;
        districtTitle = selectedDistrict.name;
      }
      
             // Condition ID'sini direkt gönder
       String? conditionId = _selectedConditionId;

      final success = await productViewModel.updateProduct(
        productId: _currentProduct?.id ?? widget.product.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        images: newImagePaths.isNotEmpty ? newImagePaths : null, // Sadece yeni dosya yolları
        existingImageUrls: existingImageUrls, // Mevcut URL'ler ayrı olarak
        categoryId: _selectedSubSubSubCategoryId ?? _selectedSubSubCategoryId ?? _selectedSubCategoryId ?? _selectedCategoryId,
        conditionId: conditionId,
        tradePreferences: tradePreferences,
        cityId: cityId,
        cityTitle: cityTitle,
        districtId: districtId,
        districtTitle: districtTitle,
        productLat: _currentProduct?.productLat ?? widget.product.productLat,
        productLong: _currentProduct?.productLong ?? widget.product.productLong,
        isShowContact: _isShowContact,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İlan başarıyla güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Başarılı güncelleme sinyali gönder
      } else {
        final errorMessage = productViewModel.errorMessage ?? 'İlan güncellenirken hata oluştu';
        
        // Token hatası durumunda kullanıcıyı login sayfasına yönlendir
        if (errorMessage.contains('token') || errorMessage.contains('giriş')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Kısa bir gecikme sonrası login sayfasına yönlendir
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Beklenmeyen hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() { _isUpdating = false; });
        Logger.info('🏁 EditProductView - Product update finished');
      }
    }
  }
}