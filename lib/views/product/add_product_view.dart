import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../core/constants.dart';

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