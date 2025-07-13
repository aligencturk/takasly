import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../core/constants.dart';
import '../../models/city.dart';
import '../../models/district.dart';

class AddProductView extends StatefulWidget {
  const AddProductView({super.key});

  @override
  State<AddProductView> createState() => _AddProductViewState();
}

class _AddProductViewState extends State<AddProductView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tradeForController = TextEditingController();
  
  String? _selectedCategoryId;
  String? _selectedConditionId;
  String? _selectedCityId;
  String? _selectedDistrictId;
  List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  // Geçici kategoriler - API'den gelecek
  final List<Map<String, String>> _categories = [
    {'id': '1', 'name': 'Elektronik'},
    {'id': '2', 'name': 'Giyim'},
    {'id': '3', 'name': 'Kitap'},
    {'id': '4', 'name': 'Ev & Yaşam'},
    {'id': '5', 'name': 'Spor'},
  ];

  // Geçici durumlar
  final List<Map<String, String>> _conditions = [
    {'id': '1', 'name': 'Sıfır'},
    {'id': '2', 'name': 'Çok İyi'},
    {'id': '3', 'name': 'İyi'},
    {'id': '4', 'name': 'Orta'},
    {'id': '5', 'name': 'Kötü'},
  ];

  @override
  void initState() {
    super.initState();
    // İlleri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productViewModel = Provider.of<ProductViewModel>(context, listen: false);
      productViewModel.loadCities();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tradeForController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images.map((image) => File(image.path)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resim seçme hatası: $e')),
      );
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf çekme hatası: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen kategori seçin')),
      );
      return;
    }

    if (_selectedConditionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen ürün durumu seçin')),
      );
      return;
    }

    final productViewModel = Provider.of<ProductViewModel>(context, listen: false);

    final success = await productViewModel.addProductWithEndpoint(
      productTitle: _titleController.text.trim(),
      productDescription: _descriptionController.text.trim(),
      categoryId: _selectedCategoryId!,
      conditionId: _selectedConditionId!,
      tradeFor: _tradeForController.text.trim(),
      productImages: _selectedImages,
    );

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ürün başarıyla eklendi!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${productViewModel.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün Ekle'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<ProductViewModel>(
            builder: (context, productViewModel, child) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: productViewModel.isLoading ? null : _submitProduct,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: const Size(80, 36),
                  ),
                  child: productViewModel.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                          ),
                        )
                      : const Text(
                          'Kaydet',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Ürün Fotoğrafları
            _buildImageSection(),
            const SizedBox(height: 24),
            
            // Ürün Başlığı
            _buildTextField(
              controller: _titleController,
              label: 'Ürün Başlığı',
              hint: 'Ürününüzün başlığını girin',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ürün başlığı gereklidir';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Ürün Açıklaması
            _buildTextField(
              controller: _descriptionController,
              label: 'Ürün Açıklaması',
              hint: 'Ürününüzü detaylı olarak açıklayın',
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ürün açıklaması gereklidir';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Kategori Seçimi
            _buildDropdown(
              label: 'Kategori',
              value: _selectedCategoryId,
              items: _categories,
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Durum Seçimi
            _buildDropdown(
              label: 'Ürün Durumu',
              value: _selectedConditionId,
              items: _conditions,
              onChanged: (value) {
                setState(() {
                  _selectedConditionId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // İl Seçimi
            Consumer<ProductViewModel>(
              builder: (context, productViewModel, child) {
                print('🏙️ UI: Cities count: ${productViewModel.cities.length}');
                print('🏙️ UI: Is loading: ${productViewModel.isLoading}');
                print('🏙️ UI: Error: ${productViewModel.errorMessage}');
                if (productViewModel.cities.isNotEmpty) {
                  print('🏙️ UI: All cities: ${productViewModel.cities.map((c) => '${c.name}(${c.id})').join(', ')}');
                  print('🏙️ UI: City names only: ${productViewModel.cities.map((c) => c.name).join(', ')}');
                }
                
                if (productViewModel.isLoading) {
                  return const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'İl',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: CircularProgressIndicator(),
                      ),
                    ],
                  );
                }
                
                if (productViewModel.hasError && productViewModel.cities.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'İl',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          productViewModel.errorMessage ?? 'Hata oluştu',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                }
                
                return _buildCityDropdown(
                  label: 'İl',
                  value: _selectedCityId,
                  cities: productViewModel.cities,
                  onChanged: (value) {
                    setState(() {
                      _selectedCityId = value;
                      _selectedDistrictId = null; // İl değiştiğinde ilçeyi sıfırla
                    });
                    
                    if (value != null) {
                      // Seçilen ile ait ilçeleri yükle
                      productViewModel.loadDistricts(value);
                    } else {
                      // İl seçimi temizlendiğinde ilçeleri temizle
                      productViewModel.clearDistricts();
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            
            // İlçe Seçimi
            Consumer<ProductViewModel>(
              builder: (context, productViewModel, child) {
                return _buildDistrictDropdown(
                  label: 'İlçe',
                  value: _selectedDistrictId,
                  districts: productViewModel.districts,
                  enabled: _selectedCityId != null,
                  onChanged: (value) {
                    setState(() {
                      _selectedDistrictId = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Takas Tercihi
            _buildTextField(
              controller: _tradeForController,
              label: 'Takas Tercihi',
              hint: 'Hangi ürünlerle takas yapmak istiyorsunuz?',
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Takas tercihi gereklidir';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCityDropdown({
    required String label,
    required String? value,
    required List<City> cities,
    required void Function(String?) onChanged,
  }) {
    // Duplicate ID'leri temizle ve sadece unique olanları al
    final uniqueCities = <String, City>{};
    for (final city in cities) {
      uniqueCities[city.id] = city;
    }
    final uniqueCityList = uniqueCities.values.toList();
    
    // Şehirleri alfabetik sıraya göre sırala
    uniqueCityList.sort((a, b) => a.name.compareTo(b.name));
    
    // Seçili şehri bul
    City? selectedCity;
    if (value != null) {
      selectedCity = uniqueCityList.firstWhere(
        (city) => city.id == value,
        orElse: () => City(id: '', name: '', plateCode: ''),
      );
      if (selectedCity.id.isEmpty) selectedCity = null;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            _showCityPicker(context, uniqueCityList, selectedCity, onChanged);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedCity?.name ?? '$label seçin (${uniqueCityList.length} şehir)',
                  style: TextStyle(
                    color: selectedCity != null ? Colors.black : Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCityPicker(BuildContext context, List<City> cities, City? selectedCity, void Function(String?) onChanged) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'İl Seçin',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: cities.length,
                      itemBuilder: (context, index) {
                        final city = cities[index];
                        final isSelected = selectedCity?.id == city.id;
                        
                        return ListTile(
                          title: Text(city.name),
                          trailing: isSelected 
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          selected: isSelected,
                          onTap: () {
                            onChanged(city.id);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDistrictDropdown({
    required String label,
    required String? value,
    required List<District> districts,
    required bool enabled,
    required void Function(String?) onChanged,
  }) {
    // Duplicate ID'leri temizle ve sadece unique olanları al
    final uniqueDistricts = <String, District>{};
    for (final district in districts) {
      uniqueDistricts[district.id] = district;
    }
    final uniqueDistrictList = uniqueDistricts.values.toList();
    
    // İlçeleri alfabetik sıraya göre sırala
    uniqueDistrictList.sort((a, b) => a.name.compareTo(b.name));
    
    // Seçili ilçeyi bul
    District? selectedDistrict;
    if (value != null && enabled) {
      selectedDistrict = uniqueDistrictList.firstWhere(
        (district) => district.id == value,
        orElse: () => District(id: '', name: '', cityId: ''),
      );
      if (selectedDistrict.id.isEmpty) selectedDistrict = null;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: enabled ? Colors.black : Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: enabled ? () {
            _showDistrictPicker(context, uniqueDistrictList, selectedDistrict, onChanged);
          } : null,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: enabled ? Colors.grey : Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  enabled 
                      ? (selectedDistrict?.name ?? '$label seçin (${uniqueDistrictList.length} ilçe)')
                      : 'Önce il seçin',
                  style: TextStyle(
                    color: enabled 
                        ? (selectedDistrict != null ? Colors.black : Colors.grey[600])
                        : Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down, 
                  color: enabled ? Colors.grey : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDistrictPicker(BuildContext context, List<District> districts, District? selectedDistrict, void Function(String?) onChanged) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'İlçe Seçin',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: districts.isEmpty
                        ? const Center(
                            child: Text(
                              'Bu il için ilçe bilgisi bulunamadı',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: districts.length,
                            itemBuilder: (context, index) {
                              final district = districts[index];
                              final isSelected = selectedDistrict?.id == district.id;
                              
                              return ListTile(
                                title: Text(district.name),
                                trailing: isSelected 
                                    ? const Icon(Icons.check, color: Colors.green)
                                    : null,
                                selected: isSelected,
                                onTap: () {
                                  onChanged(district.id);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ürün Fotoğrafları',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        // Seçilen resimler
        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(_selectedImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
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
              },
            ),
          ),
        
        const SizedBox(height: 12),
        
        // Resim ekleme butonları
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library),
                label: const Text('Galeriden Seç'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _takePicture,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Fotoğraf Çek'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<Map<String, String>> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          hint: Text('$label seçin'),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item['id'],
              child: Text(item['name']!),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
} 