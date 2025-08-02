import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:takasly/core/app_theme.dart';
import 'package:takasly/models/city.dart';
import 'package:takasly/models/condition.dart';
import 'package:takasly/models/district.dart';
import 'package:takasly/models/product.dart';
import 'package:takasly/models/location.dart';
import 'package:takasly/viewmodels/product_viewmodel.dart';

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
  String? _selectedConditionId;
  String? _selectedCityId;
  String? _selectedDistrictId;
  List<String> _existingImages = [];
  List<File> _newImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeFields();
    // Şehirleri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<ProductViewModel>().loadCities();
      } catch (e) {
        print('Error loading cities: $e');
      }
    });
  }

  void _initializeFields() {
    try {
      // Mevcut ürün bilgilerini form alanlarına yükle
      _titleController.text = widget.product.title;
      _descriptionController.text = widget.product.description;

      _tradePreferencesController.text = widget.product.tradePreferences?.join(', ') ?? '';
      
      _selectedCategoryId = widget.product.categoryId;
      _selectedSubCategoryId = null; // Product modelinde subCategoryId yok
      _existingImages = List.from(widget.product.images);
      
      // Location bilgilerini yükle
      if (widget.product.cityId != null) {
        _selectedCityId = widget.product.cityId;
        _selectedDistrictId = widget.product.districtId;
        
        // Eğer şehir seçili ise ilçeleri yükle
        if (_selectedCityId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              context.read<ProductViewModel>().loadDistricts(_selectedCityId!);
            } catch (e) {
              print('Error loading districts: $e');
            }
          });
        }
      }
      
      // Condition'ı name'den id'ye çevir
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final productViewModel = context.read<ProductViewModel>();
          if (productViewModel.conditions.isNotEmpty) {
            final condition = productViewModel.conditions.firstWhere(
              (c) => c.name == widget.product.condition,
              orElse: () => productViewModel.conditions.first,
            );
            setState(() {
              _selectedConditionId = condition.id;
            });
          }
        } catch (e) {
          print('Error setting condition: $e');
        }
      });
    } catch (e) {
      print('Error initializing fields: $e');
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
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürünü Düzenle'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ProductViewModel>(
        builder: (context, productViewModel, child) {
          if (productViewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Ürün Bilgileri'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Ürün Başlığı'),
                    validator: (v) => v!.isEmpty ? 'Başlık zorunludur' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Açıklama'),
                    maxLines: 4,
                    validator: (v) => v!.isEmpty ? 'Açıklama zorunludur' : null,
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle(context, 'Kategorizasyon'),
                  const SizedBox(height: 16),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 16),
                  _buildSubCategoryDropdown(),
                  const SizedBox(height: 16),
                  _buildSubSubCategoryDropdown(),
                  const SizedBox(height: 16),
                  _buildConditionDropdown(),
                  const SizedBox(height: 24),

                  _buildSectionTitle(context, 'Ek Bilgiler'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tradePreferencesController,
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
          print('Error building category dropdown: $e');
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
          print('Error building sub category dropdown: $e');
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
          print('🔍 EditProduct - SubSubCategory Dropdown Debug:');
          print('  - Selected SubCategory ID: $_selectedSubCategoryId');
          print('  - SubSubCategories count: ${vm.subSubCategories.length}');
          print('  - SubSubCategories items: ${vm.subSubCategories.map((c) => '${c.name}(${c.id})').join(', ')}');
          
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
              labelText: 'Ürün Kategorisi',
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
                    print('🔍 EditProduct - SubSubCategory selected: $value');
                    setState(() => _selectedSubSubCategoryId = value);
                  },
            validator: (v) => v == null ? 'Alt alt kategori seçimi zorunludur' : null,
          );
        } catch (e) {
          print('Error building sub sub category dropdown: $e');
          return DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Ürün Kategorisi',
              enabled: _selectedSubCategoryId != null,
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
          print('Error building condition dropdown: $e');
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
          print('Error building city dropdown: $e');
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
          print('Error building district dropdown: $e');
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
      final List<XFile> pickedFiles = await _imagePicker.pickMultipleMedia();
      
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _newImages.addAll(pickedFiles.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resim seçilirken hata oluştu: $e')),
      );
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
      final productViewModel = context.read<ProductViewModel>();
      
      // Tüm resimleri birleştir (mevcut + yeni)
      List<String> allImages = List.from(_existingImages);
      
      // Yeni resimler için URL'ler oluştur (gerçek uygulamada bunlar upload edilmeli)
      // Şimdilik dosya yollarını string olarak ekleyelim
      allImages.addAll(_newImages.map((file) => file.path));
      
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
        cityTitle = _selectedCityId;
        districtId = _selectedDistrictId;
        districtTitle = _selectedDistrictId;
      }
      
      // Condition ID'sini name'e çevir
      String? conditionName;
      if (_selectedConditionId != null) {
        final condition = productViewModel.conditions.firstWhere(
          (c) => c.id == _selectedConditionId,
          orElse: () => productViewModel.conditions.first,
        );
        conditionName = condition.name;
      }

      final success = await productViewModel.updateProduct(
        productId: widget.product.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        images: allImages.isNotEmpty ? allImages : null,
        categoryId: _selectedCategoryId,
        condition: conditionName,
        brand: null,
        model: null,
        estimatedValue: null,
        tradePreferences: tradePreferences,
        cityId: cityId,
        cityTitle: cityTitle,
        districtId: districtId,
        districtTitle: districtTitle,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ürün başarıyla güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Başarılı güncelleme sinyali gönder
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(productViewModel.errorMessage ?? 'Ürün güncellenirken hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Beklenmeyen hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}