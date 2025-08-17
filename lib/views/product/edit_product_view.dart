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
import 'package:takasly/services/admob_service.dart';
import 'package:takasly/services/auth_service.dart';
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
  bool _isShowContact = false;

  bool _isLoadingProductDetail = false;
  bool _isUpdating = false;
  Product? _currentProduct;

  // Sponsor ile ilgili değişkenler
  final AdMobService _adMobService = AdMobService();
  bool _isProcessingSponsor = false;

  // ExpansionTile durumları
  bool _isBasicInfoExpanded = false; // Temel bilgiler kapalı
  bool _isCategoryExpanded = false; // Kategorizasyon kapalı
  bool _isLocationExpanded = false; // Konum kapalı
  bool _isImagesExpanded = false; // Resimler kapalı
  bool _isContactExpanded = false; // İletişim ayarları kapalı
  bool _isSponsorExpanded = true; // Sponsor bölümü açık

  @override
  void initState() {
    super.initState();
    // Paralel veri yükleme ile performansı artır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataInParallel();
    });
  }

  /// Tüm verileri paralel olarak yükle - performans artışı
  Future<void> _loadDataInParallel() async {
    try {
      setState(() {
        _isLoadingProductDetail = true;
      });

      Logger.info('🚀 EditProductView - Parallel data loading started');

      final productViewModel = context.read<ProductViewModel>();

      // Tüm verileri paralel olarak yükle
      await Future.wait([
        _loadProductDetail(productViewModel),
        _loadInitialData(productViewModel),
        _initializeAdMob(), // AdMob'u da paralel olarak başlat
      ]);

      Logger.info('✅ EditProductView - All data loaded successfully');
    } catch (e) {
      Logger.error('💥 EditProductView - Error in parallel loading: $e');
      // Hata durumunda widget'tan gelen veriyi kullan
      setState(() {
        _currentProduct = widget.product;
      });
      _initializeFieldsWithProductData(widget.product);
    } finally {
      setState(() {
        _isLoadingProductDetail = false;
      });
    }
  }

  /// AdMob'u başlat ve ödüllü reklamı yükle
  Future<void> _initializeAdMob() async {
    try {
      await _adMobService.initialize();
      await _adMobService.loadRewardedAd();
      Logger.info(
        '✅ EditProductView - AdMob başlatıldı ve ödüllü reklam yüklendi',
      );
    } catch (e) {
      Logger.error('❌ EditProductView - AdMob başlatma hatası: $e');
    }
  }

  /// Ürün detaylarını yükle
  Future<void> _loadProductDetail(ProductViewModel productViewModel) async {
    try {
      final productDetail = await productViewModel.getProductDetail(
        widget.product.id,
      );

      if (productDetail != null) {
        setState(() {
          _currentProduct = productDetail;
        });
        _initializeFieldsWithProductData(productDetail);
      } else {
        setState(() {
          _currentProduct = widget.product;
        });
        _initializeFieldsWithProductData(widget.product);
      }
    } catch (e) {
      Logger.error('Error loading product detail: $e');
      setState(() {
        _currentProduct = widget.product;
      });
      _initializeFieldsWithProductData(widget.product);
    }
  }

  /// Şehirleri, kategorileri ve koşulları paralel yükle
  Future<void> _loadInitialData(ProductViewModel productViewModel) async {
    try {
      await Future.wait([
        productViewModel.loadCities(),
        productViewModel.loadConditions(),
        productViewModel.categories.isEmpty
            ? productViewModel.loadCategories()
            : Future.value(),
      ]);
    } catch (e) {
      Logger.error('Error loading initial data: $e');
    }
  }

  void _initializeFieldsWithProductData(Product product) {
    try {
      _titleController.text = product.title;
      _descriptionController.text = product.description;
      _tradePreferencesController.text = product.tradePreferences.join(', ');

      _selectedCategoryId = product.categoryId;
      _selectedSubCategoryId = product.subCategoryId?.isNotEmpty == true
          ? product.subCategoryId
          : null;
      _selectedSubSubCategoryId = product.subSubCategoryId?.isNotEmpty == true
          ? product.subSubCategoryId
          : null;
      _selectedSubSubSubCategoryId =
          product.subSubSubCategoryId?.isNotEmpty == true
          ? product.subSubSubCategoryId
          : null;
      _existingImages = List.from(product.images);

      _isShowContact = product.isShowContact ?? true;

      if (product.cityId.isNotEmpty) {
        _selectedCityId = product.cityId;
        _selectedDistrictId = product.districtId;

        // İlçeleri yükle
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

      // Kategorileri yükle ve seç
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _loadAndSelectCategories(product);
        });
      });

      // Condition'ı ayarla
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

      await productViewModel.loadCategories();

      if (product.categoryList == null ||
          product.categoryList?.isEmpty == true) {
        if (product.categoryId.isNotEmpty) {
          setState(() {
            _selectedCategoryId = product.categoryId;
          });
          return;
        }
      }

      if (product.categoryList != null &&
          product.categoryList?.isNotEmpty == true) {
        final productCategories = product.categoryList!;

        final mainCategory = productCategories.first;
        setState(() {
          _selectedCategoryId = mainCategory.id;
        });

        await productViewModel.loadSubCategories(mainCategory.id);

        if (productCategories.length > 1) {
          final subCategory = productCategories[1];
          final subCategoryExists = productViewModel.subCategories.any(
            (cat) => cat.id == subCategory.id,
          );

          if (subCategoryExists) {
            setState(() {
              _selectedSubCategoryId = subCategory.id;
            });

            await productViewModel.loadSubSubCategories(subCategory.id);

            if (productCategories.length > 2) {
              final subSubCategory = productCategories[2];
              final subSubCategoryExists = productViewModel.subSubCategories
                  .any((cat) => cat.id == subSubCategory.id);

              if (subSubCategoryExists) {
                setState(() {
                  _selectedSubSubCategoryId = subSubCategory.id;
                });

                await productViewModel.loadSubSubSubCategories(
                  subSubCategory.id,
                );

                if (productCategories.length > 3) {
                  final subSubSubCategory = productCategories[3];
                  final subSubSubCategoryExists = productViewModel
                      .subSubSubCategories
                      .any((cat) => cat.id == subSubSubCategory.id);

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
                      _buildSponsorSection(),
                      const SizedBox(height: 16),
                      _buildBasicInfoSection(),
                      const SizedBox(height: 16),
                      _buildCategorySection(),
                      const SizedBox(height: 16),
                      _buildLocationSection(),
                      const SizedBox(height: 16),
                      _buildImagesSection(),
                      const SizedBox(height: 16),
                      _buildContactSection(),
                      const SizedBox(height: 32),
                      _buildUpdateButton(),
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

  Widget _buildBasicInfoSection() {
    return ExpansionTile(
      initiallyExpanded: _isBasicInfoExpanded,
      onExpansionChanged: (expanded) {
        setState(() {
          _isBasicInfoExpanded = expanded;
        });
      },
      leading: Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
      title: Text(
        'Temel Bilgiler',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
          fontSize: 15,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'İlan Başlığı',
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                maxLength: 40,
                validator: (v) => v!.isEmpty ? 'Başlık zorunludur' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Açıklama zorunludur' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tradePreferencesController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Takas Tercihleri (virgülle ayırın)',
                  hintText: 'Örn: telefon, laptop, kitap',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return ExpansionTile(
      initiallyExpanded: _isCategoryExpanded,
      onExpansionChanged: (expanded) {
        setState(() {
          _isCategoryExpanded = expanded;
        });
      },
      leading: Icon(Icons.category, color: AppTheme.primary, size: 20),
      title: Text(
        'Kategorizasyon',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
          fontSize: 15,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              _buildCategoryDropdown(),
              const SizedBox(height: 12),
              Consumer<ProductViewModel>(
                builder: (context, vm, child) {
                  if (vm.subCategories.isNotEmpty) {
                    return Column(
                      children: [
                        _buildSubCategoryDropdown(),
                        const SizedBox(height: 12),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              Consumer<ProductViewModel>(
                builder: (context, vm, child) {
                  if (vm.subSubCategories.isNotEmpty) {
                    return Column(
                      children: [
                        _buildSubSubCategoryDropdown(),
                        const SizedBox(height: 12),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              Consumer<ProductViewModel>(
                builder: (context, vm, child) {
                  if (vm.subSubSubCategories.isNotEmpty) {
                    return Column(
                      children: [
                        _buildSubSubSubCategoryDropdown(),
                        const SizedBox(height: 12),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              _buildConditionDropdown(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return ExpansionTile(
      initiallyExpanded: _isLocationExpanded,
      onExpansionChanged: (expanded) {
        setState(() {
          _isLocationExpanded = expanded;
        });
      },
      leading: Icon(Icons.location_on, color: AppTheme.primary, size: 20),
      title: Text(
        'Konum',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
          fontSize: 15,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              _buildCityDropdown(),
              const SizedBox(height: 12),
              _buildDistrictDropdown(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagesSection() {
    return ExpansionTile(
      initiallyExpanded: _isImagesExpanded,
      onExpansionChanged: (expanded) {
        setState(() {
          _isImagesExpanded = expanded;
        });
      },
      leading: Icon(Icons.photo_library, color: AppTheme.primary, size: 20),
      title: Text(
        'Resimler',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
          fontSize: 15,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _buildImageSection(),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return ExpansionTile(
      initiallyExpanded: _isContactExpanded,
      onExpansionChanged: (expanded) {
        setState(() {
          _isContactExpanded = expanded;
        });
      },
      leading: Icon(Icons.contact_phone, color: AppTheme.primary, size: 20),
      title: Text(
        'İletişim Ayarları',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
          fontSize: 15,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _buildContactSettingsSection(),
        ),
      ],
    );
  }

  Widget _buildSponsorSection() {
    return ExpansionTile(
      initiallyExpanded: _isSponsorExpanded,
      onExpansionChanged: (expanded) {
        setState(() {
          _isSponsorExpanded = expanded;
        });
      },
      leading: Icon(Icons.star, color: Colors.blue.shade600, size: 20),
      title: Text(
        'İlanı Öne Çıkar',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.blue.shade600,
          fontSize: 15,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ÜCRETSİZ Premium Görünürlük',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade600,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'İlanınızı ödüllü reklam izleyerek 1 saat boyunca öne çıkarabilirsiniz.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isProcessingSponsor
                      ? null
                      : () => _handleSponsorProcess(),
                  icon: _isProcessingSponsor
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Icon(Icons.play_arrow, size: 18),
                  label: Text(
                    _isProcessingSponsor
                        ? 'İşleniyor...'
                        : 'Reklam İzle ve Öne Çıkar',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ÜCRETSİZ - Reklam izledikten sonra otomatik olarak öne çıkarılır',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        try {
          String? validValue = _selectedCategoryId;
          if (validValue != null) {
            final hasValidValue = vm.categories.any((c) => c.id == validValue);
            if (!hasValidValue) {
              validValue = null;
            }
          }

          return DropdownButtonFormField<String>(
            value: validValue,
            decoration: const InputDecoration(
              labelText: 'Ana Kategori',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: vm.categories
                .map(
                  (cat) =>
                      DropdownMenuItem(value: cat.id, child: Text(cat.name)),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategoryId = value;
                _selectedSubCategoryId = null;
              });
              if (value != null) {
                vm.loadSubCategories(value);
              }
            },
            validator: (v) =>
                v == null ? 'Ana kategori seçimi zorunludur' : null,
          );
        } catch (e) {
          Logger.error('Error building category dropdown: $e');
          return DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Ana Kategori',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
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
          String? validValue = _selectedSubCategoryId;
          if (validValue != null) {
            final hasValidValue = vm.subCategories.any(
              (c) => c.id == validValue,
            );
            if (!hasValidValue) {
              validValue = null;
            }
          }

          return DropdownButtonFormField<String>(
            value: validValue,
            decoration: InputDecoration(
              labelText: 'Alt Kategori',
              enabled: _selectedCategoryId != null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: vm.subCategories
                .map(
                  (cat) =>
                      DropdownMenuItem(value: cat.id, child: Text(cat.name)),
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
            validator: (v) =>
                v == null ? 'Alt kategori seçimi zorunludur' : null,
          );
        } catch (e) {
          Logger.error('Error building sub category dropdown: $e');
          return DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Alt Kategori',
              enabled: _selectedCategoryId != null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
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
          String? validValue = _selectedSubSubCategoryId;
          if (validValue != null) {
            final hasValidValue = vm.subSubCategories.any(
              (c) => c.id == validValue,
            );
            if (!hasValidValue) {
              validValue = null;
            }
          }

          return DropdownButtonFormField<String>(
            value: validValue,
            decoration: InputDecoration(
              labelText: 'Alt Alt Kategori',
              enabled:
                  _selectedSubCategoryId != null &&
                  vm.subSubCategories.isNotEmpty,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: vm.subSubCategories
                .map(
                  (cat) =>
                      DropdownMenuItem(value: cat.id, child: Text(cat.name)),
                )
                .toList(),
            onChanged:
                _selectedSubCategoryId == null || vm.subSubCategories.isEmpty
                ? null
                : (value) {
                    setState(() {
                      _selectedSubSubCategoryId = value;
                      _selectedSubSubSubCategoryId = null;
                    });
                    if (value != null) {
                      vm.loadSubSubSubCategories(value);
                    } else {
                      vm.clearSubSubCategories();
                    }
                  },
            validator: (v) =>
                v == null ? 'Alt alt kategori seçimi zorunludur' : null,
          );
        } catch (e) {
          Logger.error('Error building sub sub category dropdown: $e');
          return DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Alt Alt Kategori',
              enabled: _selectedSubCategoryId != null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
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
          String? validValue = _selectedSubSubSubCategoryId;
          if (validValue != null) {
            final hasValidValue = vm.subSubSubCategories.any(
              (c) => c.id == validValue,
            );
            if (!hasValidValue) {
              validValue = null;
            }
          }

          return DropdownButtonFormField<String>(
            value: validValue,
            decoration: InputDecoration(
              labelText: 'Ürün Kategorisi',
              enabled:
                  _selectedSubSubCategoryId != null &&
                  vm.subSubSubCategories.isNotEmpty,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: vm.subSubSubCategories
                .map(
                  (cat) =>
                      DropdownMenuItem(value: cat.id, child: Text(cat.name)),
                )
                .toList(),
            onChanged:
                _selectedSubSubCategoryId == null ||
                    vm.subSubSubCategories.isEmpty
                ? null
                : (value) {
                    setState(() => _selectedSubSubSubCategoryId = value);
                  },
            validator: (v) =>
                v == null ? 'Alt alt alt kategori seçimi zorunludur' : null,
          );
        } catch (e) {
          Logger.error('Error building sub sub sub category dropdown: $e');
          return DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Ürün Kategorisi',
              enabled: _selectedSubSubCategoryId != null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
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
          String? validValue = _selectedConditionId;
          if (validValue != null) {
            final hasValidValue = vm.conditions.any((c) => c.id == validValue);
            if (!hasValidValue) {
              validValue = null;
            }
          }

          return DropdownButtonFormField<String>(
            value: validValue,
            decoration: InputDecoration(
              labelText: 'Ürün Durumu',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: vm.conditions
                .map(
                  (con) =>
                      DropdownMenuItem(value: con.id, child: Text(con.name)),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedConditionId = value),
            validator: (v) => v == null ? 'Durum seçimi zorunludur' : null,
          );
        } catch (e) {
          Logger.error('Error building condition dropdown: $e');
          return DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Ürün Durumu',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
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
          String? validValue = _selectedCityId;
          if (validValue != null) {
            final hasValidValue = vm.cities.any((c) => c.id == validValue);
            if (!hasValidValue) {
              validValue = null;
            }
          }

          return DropdownButtonFormField<String>(
            value: validValue,
            decoration: InputDecoration(
              labelText: 'İl',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
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
            decoration: InputDecoration(
              labelText: 'İl',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
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
              child: SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_photo_alternate, size: 18),
                  label: const Text(
                    'Yeni Resim Ekle',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_existingImages.isNotEmpty || _newImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._existingImages.map(
                  (imageUrl) => _buildExistingImageItem(imageUrl),
                ),
                ..._newImages.map((imageFile) => _buildNewImageItem(imageFile)),
              ],
            ),
          ),
        if (_existingImages.isEmpty && _newImages.isEmpty)
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Henüz resim eklenmedi',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExistingImageItem(String imageUrl) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Builder(
              builder: (context) {
                if (imageUrl.isEmpty ||
                    imageUrl == 'null' ||
                    imageUrl == 'undefined') {
                  return Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 20),
                  );
                }

                return CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    return Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[300],
                      child: const Icon(Icons.error, size: 20),
                    );
                  },
                );
              },
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () => _removeExistingImage(imageUrl),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewImageItem(File imageFile) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(
              imageFile,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () => _removeNewImage(imageFile),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final int totalExistingImages =
          _existingImages.length + _newImages.length;
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
        final List<XFile> filesToAdd = pickedFiles
            .take(remainingSlots)
            .toList();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fotoğraflar optimize ediliyor...'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }

        Logger.debug(
          '🖼️ EditProductView - Optimizing ${filesToAdd.length} selected images...',
        );
        final List<File> optimizedFiles =
            await ImageOptimizationService.optimizeXFiles(
              filesToAdd,
              maxImages: remainingSlots,
            );

        setState(() {
          _newImages.addAll(optimizedFiles);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${optimizedFiles.length} fotoğraf optimize edilerek eklendi',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        if (pickedFiles.length > remainingSlots) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${pickedFiles.length} resim seçtiniz, ancak sadece $remainingSlots tanesi eklendi (maksimum 5 resim)',
              ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_phone, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'İletişim Bilgileri',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Telefon numaramı göster',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Açıksa, diğer kullanıcılar size arayabilir',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 12,
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

          const SizedBox(height: 12),

          Row(
            children: [
              Icon(
                _isShowContact ? Icons.check_circle : Icons.info_outline,
                color: _isShowContact ? Colors.green : Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isShowContact
                      ? 'Telefon numaranız görünür olacak. Kullanıcılar size arayabilecek.'
                      : 'Telefon numaranız gizli olacak. Sadece mesajlaşma ile iletişim kurulabilir.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _isShowContact
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Icon(Icons.security, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bu ayarı daha sonra ilan detay sayfasından değiştirebilirsiniz.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _updateProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Ürünü Güncelle',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
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

    // Login kontrolü - ürün güncellemek için giriş gerekli
    try {
      final authService = AuthService();
      final userToken = await authService.getToken();

      if (userToken == null || userToken.isEmpty) {
        Logger.warning(
          '⚠️ EditProductView - Kullanıcı giriş yapmamış, login sayfasına yönlendiriliyor',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.login, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Ürün güncellemek için giriş yapmanız gerekiyor.'),
                ],
              ),
              backgroundColor: AppTheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );

          // 2 saniye sonra login sayfasına yönlendir
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            }
          });
        }
        return;
      }
    } catch (e) {
      Logger.error('❌ EditProductView - Login kontrol hatası: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bir hata oluştu. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      setState(() {
        _isUpdating = true;
      });
      Logger.info('🔄 EditProductView - Product update started');
      final productViewModel = context.read<ProductViewModel>();

      List<String> existingImageUrls = List.from(_existingImages);
      List<String> newImagePaths = _newImages.map((file) => file.path).toList();

      Logger.info(
        '🖼️ EditProductView - Existing images: ${existingImageUrls.length}',
      );
      Logger.info('🆕 EditProductView - New images: ${newImagePaths.length}');

      List<String>? tradePreferences;
      if (_tradePreferencesController.text.trim().isNotEmpty) {
        tradePreferences = _tradePreferencesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }

      String? cityId;
      String? cityTitle;
      String? districtId;
      String? districtTitle;
      if (_selectedCityId != null && _selectedDistrictId != null) {
        cityId = _selectedCityId;
        final selectedCity = productViewModel.cities.firstWhere(
          (city) => city.id == _selectedCityId,
          orElse: () =>
              City(id: _selectedCityId!, name: '', plateCode: _selectedCityId!),
        );
        final selectedDistrict = productViewModel.districts.firstWhere(
          (district) => district.id == _selectedDistrictId,
          orElse: () => District(
            id: _selectedDistrictId!,
            name: '',
            cityId: _selectedCityId!,
          ),
        );
        cityTitle = selectedCity.name;
        districtId = _selectedDistrictId;
        districtTitle = selectedDistrict.name;
      }

      String? conditionId = _selectedConditionId;

      final success = await productViewModel.updateProduct(
        productId: _currentProduct?.id ?? widget.product.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        images: newImagePaths.isNotEmpty ? newImagePaths : null,
        existingImageUrls: existingImageUrls,
        categoryId:
            _selectedSubSubSubCategoryId ??
            _selectedSubSubCategoryId ??
            _selectedSubCategoryId ??
            _selectedCategoryId,
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
        Navigator.of(context).pop(true);
      } else {
        final errorMessage =
            productViewModel.errorMessage ?? 'İlan güncellenirken hata oluştu';

        if (errorMessage.contains('token') || errorMessage.contains('giriş')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );

          Future.delayed(const Duration(seconds: 2), () {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
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
        setState(() {
          _isUpdating = false;
        });
        Logger.info('🏁 EditProductView - Product update finished');
      }
    }
  }

  /// Sponsor işlemini yönet - ürün düzenleme için
  Future<void> _handleSponsorProcess() async {
    try {
      setState(() {
        _isProcessingSponsor = true;
      });

      Logger.info('🎁 EditProductView - Sponsor işlemi başlatılıyor...');

      final productId = _currentProduct?.id ?? widget.product.id;
      Logger.info('🎁 EditProductView - Ürün ID: $productId');

      // Onay dialog'u göster
      final shouldProceed = await _showSponsorConfirmationDialog();
      if (!shouldProceed) {
        Logger.info(
          '👤 EditProductView - Kullanıcı sponsor işlemini iptal etti',
        );
        return;
      }

      // Ödüllü reklamı göster
      final rewardEarned = await _adMobService.showRewardedAd();

      if (rewardEarned) {
        Logger.info(
          '🎉 EditProductView - Ödül kazanıldı, ürün sponsor ediliyor...',
        );

        // Ürünü sponsor et
        final vm = Provider.of<ProductViewModel>(context, listen: false);
        final sponsorSuccess = await vm.sponsorProduct(productId);

        if (sponsorSuccess) {
          Logger.info('✅ EditProductView - Ürün başarıyla sponsor edildi');
          _showSponsorSuccessMessage();
        } else {
          Logger.error('❌ EditProductView - Sponsor işlemi başarısız');

          // Spesifik hata mesajını kontrol et
          final vm = Provider.of<ProductViewModel>(context, listen: false);
          final errorMessage = vm.errorMessage ?? '';

          if (errorMessage.contains('Zaten aktif öne çıkarılmış') ||
              errorMessage.contains('Bir saat içinde sadece bir ürün')) {
            _showSponsorLimitErrorMessage(errorMessage);
          } else {
            _showSponsorErrorMessage();
          }
        }
      } else {
        Logger.warning(
          '⚠️ EditProductView - Ödül kazanılmadı, sponsor işlemi iptal edildi',
        );
        _showSponsorCancelledMessage();
      }
    } catch (e) {
      Logger.error('❌ EditProductView - Sponsor işlemi hatası: $e');
      _showSponsorErrorMessage();
    } finally {
      setState(() {
        _isProcessingSponsor = false;
      });
    }
  }

  /// Sponsor onay dialog'u
  Future<bool> _showSponsorConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.star, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 10),
              Text(
                'İlanı Öne Çıkar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade600,
                ),
              ),
            ],
          ),
          content: Text(
            'Ödüllü reklam izleyerek ilanınızı 1 saat boyunca öne çıkarmak istiyor musunuz?\n\nİlanınız anasayfada en üstte mavi çerçeve ile gösterilecek.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'İptal',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Reklam İzle',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        );
      },
    );

    return result ?? false;
  }

  /// Sponsor başarı mesajı
  void _showSponsorSuccessMessage() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.star, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'İlanınız başarıyla öne çıkarıldı! 1 saat boyunca en üstte görünecek.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Sponsor hata mesajı
  void _showSponsorErrorMessage() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Öne çıkarma işlemi başarısız oldu. Lütfen daha sonra tekrar deneyin.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Sponsor iptal mesajı
  void _showSponsorCancelledMessage() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Öne çıkarma işlemi iptal edildi.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Sponsor limit hatası mesajı (zaten aktif ürün var)
  void _showSponsorLimitErrorMessage(String errorMessage) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.schedule, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Öne Çıkarma Limiti',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Zaten aktif öne çıkarılmış ürününüz var. Bir saat içinde sadece bir ürün öne çıkarılabilir.',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Tamam',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }
}
