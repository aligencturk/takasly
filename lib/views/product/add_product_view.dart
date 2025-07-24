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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ürün başarıyla eklendi!'),
          backgroundColor: AppTheme.success,
        ));
      } else {
        final error = Provider.of<ProductViewModel>(context, listen: false).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Hata: ${error ?? 'Bilinmeyen bir hata oluştu'}'),
          backgroundColor: AppTheme.error,
        ));
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
                        style: textTheme.titleMedium?.copyWith(color: AppTheme.primary),
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
              decoration: const InputDecoration(labelText: 'Ne ile takas etmek istersin?'),
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
              .map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name)))
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
              .map((con) => DropdownMenuItem(value: con.id, child: Text(con.name)))
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
              .map((city) => DropdownMenuItem(value: city.id, child: Text(city.name)))
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
              .map((dist) => DropdownMenuItem(value: dist.id, child: Text(dist.name)))
              .toList(),
          onChanged: _selectedCityId == null
              ? null
              : (value) => setState(() => _selectedDistrictId = value),
          validator: (v) => _selectedCityId != null && v == null ? 'İlçe seçimi zorunludur' : null,
        );
      },
    );
  }
  
  // -- Resim Seçici Widget'ları --

  Widget _buildImagePicker() {
    // ... (Resim seçici widget'lar buraya gelecek)
    return const Center(child: Text('Resim seçici yakında...'));
  }
} 