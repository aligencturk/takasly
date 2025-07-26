import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:takasly/core/app_theme.dart';
import 'package:takasly/models/city.dart';
import 'package:takasly/models/condition.dart';
import 'package:takasly/models/district.dart';
import 'package:takasly/viewmodels/product_viewmodel.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<ProductViewModel>(context, listen: false);
      vm.loadCities();
      vm.loadConditions();
      // Kategorileri de yükleyelim (eğer yüklü değilse)
      if (vm.categories.isEmpty) {
        vm.loadCategories();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tradeForController.dispose();
    super.dispose();
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;
    // Diğer validasyonlar...

    final success = await Provider.of<ProductViewModel>(context, listen: false)
        .addProductWithEndpoint(
          productTitle: _titleController.text.trim(),
          productDescription: _descriptionController.text.trim(),
          categoryId: _selectedCategoryId!,
          conditionId: _selectedConditionId!,
          tradeFor: _tradeForController.text.trim(),
          productImages: _selectedImages,
        );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ürün başarıyla eklendi!'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        final error = Provider.of<ProductViewModel>(
          context,
          listen: false,
        ).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${error ?? 'Bilinmeyen bir hata oluştu'}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün Ekle'),
        centerTitle: true,
        actions: [
          Consumer<ProductViewModel>(
            builder: (context, vm, child) {
              return TextButton(
                onPressed: vm.isLoading ? null : _submitProduct,
                child: vm.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Yayınla',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppTheme.primary,
                        ),
                      ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            _buildSectionTitle(context, 'Ürün Fotoğrafları'),
            const SizedBox(height: 16),
            _buildImagePicker(),
            const SizedBox(height: 24),

            _buildSectionTitle(context, 'Ürün Detayları'),
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
            _buildConditionDropdown(),
            const SizedBox(height: 24),

            _buildSectionTitle(context, 'Konum'),
            const SizedBox(height: 16),
            _buildCityDropdown(),
            const SizedBox(height: 16),
            _buildDistrictDropdown(),
            const SizedBox(height: 24),

            _buildSectionTitle(context, 'Takas Tercihleri'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tradeForController,
              decoration: const InputDecoration(
                labelText: 'Ne ile takas etmek istersin?',
              ),
              maxLines: 2,
              validator: (v) => v!.isEmpty ? 'Takas tercihi zorunludur' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }

  // -- Dropdown Widget'ları --

  Widget _buildCategoryDropdown() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        return DropdownButtonFormField<String>(
          value: _selectedCategoryId,
          decoration: const InputDecoration(labelText: 'Kategori'),
          items: vm.categories
              .map(
                (cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name)),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedCategoryId = value),
          validator: (v) => v == null ? 'Kategori seçimi zorunludur' : null,
        );
      },
    );
  }

  Widget _buildConditionDropdown() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        return DropdownButtonFormField<String>(
          value: _selectedConditionId,
          decoration: const InputDecoration(labelText: 'Ürün Durumu'),
          items: vm.conditions
              .map(
                (con) => DropdownMenuItem(value: con.id, child: Text(con.name)),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedConditionId = value),
          validator: (v) => v == null ? 'Durum seçimi zorunludur' : null,
        );
      },
    );
  }

  Widget _buildCityDropdown() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        return DropdownButtonFormField<String>(
          value: _selectedCityId,
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
            if (value != null) vm.loadDistricts(value);
          },
          validator: (v) => v == null ? 'İl seçimi zorunludur' : null,
        );
      },
    );
  }

  Widget _buildDistrictDropdown() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        return DropdownButtonFormField<String>(
          value: _selectedDistrictId,
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
          validator: (v) => _selectedCityId != null && v == null
              ? 'İlçe seçimi zorunludur'
              : null,
        );
      },
    );
  }

  // -- Resim Seçici Widget'ları --

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seçilen resimler grid'i
        if (_selectedImages.isNotEmpty) ...[
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length + 1, // +1 for add button
              itemBuilder: (context, index) {
                if (index == _selectedImages.length) {
                  // Add more images button
                  return _buildAddImageButton();
                }
                return _buildImagePreview(_selectedImages[index], index);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        // İlk resim ekleme butonu (eğer hiç resim yoksa)
        if (_selectedImages.isEmpty) _buildAddImageButton(),

        // Bilgi metni
        Text(
          'En fazla 5 fotoğraf ekleyebilirsiniz. İlk fotoğraf kapak resmi olacaktır.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: InkWell(
        onTap: _selectedImages.length < 5 ? _showImageSourceDialog : null,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: _selectedImages.length < 5
                  ? AppTheme.primary
                  : Colors.grey.shade400,
            ),
            const SizedBox(height: 4),
            Text(
              _selectedImages.isEmpty ? 'Fotoğraf\nEkle' : 'Ekle',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: _selectedImages.length < 5
                    ? AppTheme.primary
                    : Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(File image, int index) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          // Resim
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              image,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),

          // Kapak resmi badge'i (ilk resim için)
          if (index == 0)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Kapak',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Silme butonu
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Text(
                'Fotoğraf Seç',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 20),

              // Options
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt, color: AppTheme.primary),
                ),
                title: const Text('Kamera'),
                subtitle: const Text('Fotoğraf çek'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),

              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library, color: AppTheme.primary),
                ),
                title: const Text('Galeri'),
                subtitle: const Text('Tek veya birden fazla fotoğraf seç'),
                onTap: () {
                  Navigator.pop(context);
                  _pickMultipleImages();
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });

        print('📸 Image added: ${pickedFile.path}');
        print('📸 Total images: ${_selectedImages.length}');
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fotoğraf seçilirken hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      // Maksimum seçilebilecek resim sayısını hesapla
      final int remainingSlots = 5 - _selectedImages.length;
      if (remainingSlots <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maksimum 5 fotoğraf seçebilirsiniz'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // pickMultipleMedia kullanarak hem tek hem çoklu seçimi destekle
      final List<XFile> pickedFiles = await _imagePicker.pickMultipleMedia(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        // Sadece kalan slot kadar resim al
        final List<XFile> filesToAdd = pickedFiles.take(remainingSlots).toList();
        
        setState(() {
          for (final file in filesToAdd) {
            _selectedImages.add(File(file.path));
          }
        });

        print('📸 ${filesToAdd.length} images added');
        print('📸 Total images: ${_selectedImages.length}');

        // Eğer seçilen resim sayısı kalan slottan fazlaysa uyarı ver
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
      print('❌ Error picking multiple images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fotoğraflar seçilirken hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    print('🗑️ Image removed at index $index');
    print('📸 Remaining images: ${_selectedImages.length}');
  }
}
