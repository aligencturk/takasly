import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:takasly/core/app_theme.dart';
import 'package:takasly/viewmodels/product_viewmodel.dart';
import 'package:takasly/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

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
  String? _selectedSubCategoryId;
  String? _selectedSubSubCategoryId;
  String? _selectedSubSubSubCategoryId;
  String? _selectedConditionId;
  String? _selectedCityId;
  String? _selectedDistrictId;
  List<File> _selectedImages = [];
  int _coverImageIndex = 0; // Kapak fotoğrafı indeksi
  final ImagePicker _imagePicker = ImagePicker();
  bool _isShowContact = true; // İletişim bilgilerinin görünürlüğü
  
  // Konum servisi
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  bool _isGettingLocation = false;

  // Step management
  int _currentStep = 0;
  final int _totalSteps = 6;

  // Step titles
  final List<String> _stepTitles = [
    'Fotoğraflar',
    'Ürün Detayları',
    'Kategorizasyon',
    'Konum',
    'Takas Tercihleri',
    'İletişim Ayarları',
  ];

  // Step icons
  final List<IconData> _stepIcons = [
    Icons.photo_library,
    Icons.description,
    Icons.category,
    Icons.location_on,
    Icons.swap_horiz,
    Icons.contact_phone,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<ProductViewModel>(context, listen: false);
      vm.loadCities();
      vm.loadConditions();
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

  bool _canGoToNextStep() {
    bool canGo = false;
    switch (_currentStep) {
      case 0: // Fotoğraflar
        canGo = _selectedImages.isNotEmpty;
        break;
      case 1: // Ürün Detayları
        canGo = _titleController.text.trim().isNotEmpty && 
               _descriptionController.text.trim().isNotEmpty;
        break;
      case 2: // Kategorizasyon
        canGo = _selectedCategoryId != null && _selectedConditionId != null;
        break;
      case 3: // Konum
        // Sadece manuel seçim (il/ilçe) zorunlu
        canGo = _selectedCityId != null && _selectedDistrictId != null;
        break;
      case 4: // Takas Tercihleri
        canGo = _tradeForController.text.trim().isNotEmpty;
        break;
      case 5: // İletişim Ayarları
        canGo = true; // Bu adım her zaman geçilebilir
        break;
      default:
        canGo = false;
    }
    
    return canGo;
  }



  void _showValidationError() {
    String errorMessage = '';
    
    switch (_currentStep) {
      case 0: // Fotoğraflar
        errorMessage = 'Lütfen en az bir fotoğraf seçin';
        break;
      case 1: // Ürün Detayları
        if (_titleController.text.trim().isEmpty) {
          errorMessage = 'Lütfen ürün başlığını girin';
        } else if (_descriptionController.text.trim().isEmpty) {
          errorMessage = 'Lütfen ürün açıklamasını girin';
        }
        break;
      case 2: // Kategorizasyon
        if (_selectedCategoryId == null) {
          errorMessage = 'Lütfen bir kategori seçin';
        } else if (_selectedConditionId == null) {
          errorMessage = 'Lütfen ürün durumunu seçin';
        }
        break;
      case 3: // Konum
        if (_selectedCityId == null) {
          errorMessage = 'Lütfen bir il seçin';
        } else if (_selectedDistrictId == null) {
          errorMessage = 'Lütfen bir ilçe seçin';
        }
        break;
      case 4: // Takas Tercihleri
        errorMessage = 'Lütfen takas tercihlerini girin';
        break;
      case 5: // İletişim Ayarları
        errorMessage = 'Lütfen iletişim ayarlarını yapın';
        break;
      default:
        errorMessage = 'Lütfen tüm gerekli alanları doldurun';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                errorMessage,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
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

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Son validasyon kontrolü
    if (!_canGoToNextStep()) {
      _showValidationError();
      return;
    }



    final categoryId = _selectedSubSubSubCategoryId ?? _selectedSubSubCategoryId ?? _selectedSubCategoryId ?? _selectedCategoryId;
    
    // Yükleniyor durumunu göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'İlan ekleniyor...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lütfen bekleyin',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    
    // Şehir ve ilçe isimlerini al
    final vm = Provider.of<ProductViewModel>(context, listen: false);
    String? selectedCityTitle;
    String? selectedDistrictTitle;
    
    if (_selectedCityId != null) {
      final selectedCity = vm.cities.firstWhere(
        (city) => city.id == _selectedCityId,
        orElse: () => throw Exception('Şehir bulunamadı'),
      );
      selectedCityTitle = selectedCity.name;
    }
    
    if (_selectedDistrictId != null) {
      final selectedDistrict = vm.districts.firstWhere(
        (district) => district.id == _selectedDistrictId,
        orElse: () => throw Exception('İlçe bulunamadı'),
      );
      selectedDistrictTitle = selectedDistrict.name;
    }
    
    final success = await vm.addProductWithEndpoint(
          productTitle: _titleController.text.trim(),
          productDescription: _descriptionController.text.trim(),
          categoryId: categoryId!,
          conditionId: _selectedConditionId!,
          tradeFor: _tradeForController.text.trim(),
          productImages: _selectedImages,
          selectedCityId: _selectedCityId,
          selectedDistrictId: _selectedDistrictId,
          selectedCityTitle: selectedCityTitle,
          selectedDistrictTitle: selectedDistrictTitle,
          isShowContact: _isShowContact,
          userProvidedLatitude: _currentPosition?.latitude,
          userProvidedLongitude: _currentPosition?.longitude,
        );

    // Yükleniyor dialog'unu kapat
    if (mounted) {
      Navigator.of(context).pop(); // Dialog'u kapat
    }

    if (mounted) {
      if (success) {
        // Ana sayfaya dön ve başarı durumunu bildir
        Navigator.of(context).pop(true);
        
        // Başarı mesajını göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Ürün başarıyla eklendi!',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        final error = Provider.of<ProductViewModel>(
          context,
          listen: false,
        ).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hata: ${error ?? 'Bilinmeyen bir hata oluştu'}',
                    style: const TextStyle(fontSize: 16),
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
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlan Ekle'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Step Progress Header
          _buildStepProgressHeader(),
          
          // Main Content
          Expanded(
            child: Form(
              key: _formKey,
              child: _buildCurrentStep(),
            ),
          ),
          
          // Navigation Buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStepProgressHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Step indicator
          Row(
            children: [
              Text(
                'Adım ${_currentStep + 1} / $_totalSteps',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                _stepTitles[_currentStep],
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Progress bar
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            minHeight: 6,
          ),
          
          const SizedBox(height: 16),
          
          // Step dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalSteps, (index) {
              final isCompleted = _isStepCompleted(index);
              final isCurrent = index == _currentStep;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () {
                    if (index <= _currentStep || (index == _currentStep + 1 && _canGoToNextStep())) {
                      setState(() {
                        _currentStep = index;
                      });
                    }
                  },
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isCompleted 
                          ? Colors.green
                          : isCurrent 
                              ? AppTheme.primary
                              : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _currentStep > 0 ? _previousStep : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: _currentStep > 0 ? AppTheme.primary : Colors.grey.shade300,
                  width: 1.5,
                ),
                backgroundColor: _currentStep > 0 ? Colors.transparent : Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Geri',
                style: TextStyle(
                  color: _currentStep > 0 ? AppTheme.primary : Colors.grey.shade400,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_currentStep == _totalSteps - 1) {
                  if (_canGoToNextStep()) {
                    _submitProduct();
                  } else {
                    _showValidationError();
                  }
                } else {
                  if (_canGoToNextStep()) {
                    setState(() {
                      _currentStep++;
                    });
                  } else {
                    _showValidationError();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _canGoToNextStep() ? AppTheme.primary : Colors.grey.shade300,
                foregroundColor: _canGoToNextStep() ? Colors.white : Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: _canGoToNextStep() ? 2 : 0,
                shadowColor: _canGoToNextStep() ? AppTheme.primary.withOpacity(0.3) : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _currentStep == _totalSteps - 1 ? 'Tamamla' : 'İleri',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isStepCompleted(int step) {
    switch (step) {
      case 0: return _selectedImages.isNotEmpty;
      case 1: return _titleController.text.trim().isNotEmpty && 
                   _descriptionController.text.trim().isNotEmpty;
      case 2: return _selectedCategoryId != null && _selectedConditionId != null;
      case 3: return _selectedCityId != null && _selectedDistrictId != null;
      case 4: return _tradeForController.text.trim().isNotEmpty;
      case 5: return false; // Bu adım hiçbir zaman otomatik tamamlanmış sayılmaz
      default: return false;
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildPhotosStep();
      case 1:
        return _buildProductDetailsStep();
      case 2:
        return _buildCategorizationStep();
      case 3:
        return _buildLocationStep();
      case 4:
        return _buildTradePreferencesStep();
      case 5:
        return _buildContactSettingsStep();
      default:
        return const Center(child: Text('Bilinmeyen adım'));
    }
  }

  Widget _buildPhotosStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _stepIcons[0],
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ürün Fotoğrafları',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ürününüzün en iyi şekilde görünmesi için kaliteli fotoğraflar ekleyin',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Image picker
          _buildImagePicker(),
        ],
      ),
    );
  }

  Widget _buildProductDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _stepIcons[1],
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ürün Detayları',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ürününüzü en iyi şekilde tanımlayın',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Form fields
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Ürün Başlığı',
              hintText: 'Örn: iPhone 13 Pro Max 256GB',
              counterText: '',
            ),
            maxLength: 40,
            validator: (v) => v!.isEmpty ? 'Başlık zorunludur' : null,
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Açıklama',
              hintText: 'Ürününüzün detaylarını, özelliklerini ve durumunu açıklayın',
            ),
            maxLines: 6,
            validator: (v) => v!.isEmpty ? 'Açıklama zorunludur' : null,
            onChanged: (value) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorizationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _stepIcons[2],
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kategorizasyon',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ürününüzü doğru kategoride sınıflandırın',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Form fields
          _buildCategoryDropdown(),
          const SizedBox(height: 24),
          Consumer<ProductViewModel>(
            builder: (context, vm, child) {
              // Sadece alt kategorileri varsa 2. seviye dropdown'ı göster
              if (vm.subCategories.isNotEmpty) {
                return Column(
                  children: [
                    const SizedBox(height: 24),
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
                    const SizedBox(height: 24),
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
                    const SizedBox(height: 24),
                    _buildSubSubSubCategoryDropdown(),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 24),
          _buildConditionDropdown(),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _stepIcons[3],
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Konum',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ürününüzün bulunduğu yeri belirtin',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Otomatik konum alma butonu
          _buildAutoLocationButton(),
          const SizedBox(height: 24),
          
          // Manuel seçim
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_city, color: Colors.grey.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Manuel Konum Seçimi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'İl ve ilçe seçimi zorunludur',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Form fields
          _buildCityDropdown(),
          const SizedBox(height: 24),
          _buildDistrictDropdown(),
          const SizedBox(height: 16),
          
          // Info card

            
             Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child:                 Text(
                  'İl ve ilçe seçimi zorunludur. GPS konumu isteğe bağlıdır.',
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

  Widget _buildTradePreferencesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _stepIcons[4],
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Takas Tercihleri',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ne ile takas etmek istediğinizi belirtin',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Form fields
          TextFormField(
            controller: _tradeForController,
            decoration: const InputDecoration(
              labelText: 'Ne ile takas etmek istersin?',
              hintText: 'Örn: MacBook Pro, para, başka bir telefon...',
            ),
            maxLines: 4,
            validator: (v) => v!.isEmpty ? 'Takas tercihi zorunludur' : null,
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 24),
          
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Daha spesifik olursanız, uygun takas teklifleri alma şansınız artar',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -- Dropdown Widget'ları --

  Widget _buildCategoryDropdown() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        // Seçili değerin listede olup olmadığını kontrol et
        final validValue = vm.categories.any((cat) => cat.id == _selectedCategoryId) 
            ? _selectedCategoryId 
            : null;
            
        return DropdownButtonFormField<String>(
          value: validValue,
          decoration: const InputDecoration(labelText: 'Ana Kategori'),
          items: vm.categories
              .map(
                (cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name)),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategoryId = value;
              _selectedSubCategoryId = null;
            });
            if (value != null) {
              vm.loadSubCategories(value);
            } else {
              vm.clearSubCategories();
            }
          },
          validator: (v) => v == null ? 'Ana kategori seçimi zorunludur' : null,
        );
      },
    );
  }

  Widget _buildSubCategoryDropdown() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        // Seçili değerin listede olup olmadığını kontrol et
        final validValue = vm.subCategories.any((cat) => cat.id == _selectedSubCategoryId) 
            ? _selectedSubCategoryId 
            : null;
            
        return DropdownButtonFormField<String>(
          value: validValue,
          decoration: InputDecoration(
            labelText: 'Alt Kategori',
            enabled: _selectedCategoryId != null && vm.subCategories.isNotEmpty,
          ),
          items: vm.subCategories
              .map(
                (cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name)),
              )
              .toList(),
          onChanged: _selectedCategoryId == null || vm.subCategories.isEmpty
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
          validator: (v) {
            if (_selectedCategoryId != null && vm.subCategories.isNotEmpty && v == null) {
              return 'Alt kategori seçimi zorunludur';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildSubSubCategoryDropdown() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        // Seçili değerin listede olup olmadığını kontrol et
        final validValue = vm.subSubCategories.any((cat) => cat.id == _selectedSubSubCategoryId) 
            ? _selectedSubSubCategoryId 
            : null;
            
        return DropdownButtonFormField<String>(
          value: validValue,
          decoration: InputDecoration(
            labelText: 'Alt Alt Kategori',
            enabled: _selectedSubCategoryId != null && vm.subSubCategories.isNotEmpty,
          ),
          items: vm.subSubCategories
              .map(
                (cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name)),
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
          validator: (v) {
            if (_selectedSubCategoryId != null && vm.subSubCategories.isNotEmpty && v == null) {
              return 'Alt alt kategori seçimi zorunludur';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildSubSubSubCategoryDropdown() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        // Seçili değerin listede olup olmadığını kontrol et
        final validValue = vm.subSubSubCategories.any((cat) => cat.id == _selectedSubSubSubCategoryId) 
            ? _selectedSubSubSubCategoryId 
            : null;
            
        return DropdownButtonFormField<String>(
          value: validValue,
          decoration: InputDecoration(
            labelText: 'Ürün Kategorisi',
            enabled: _selectedSubSubCategoryId != null && vm.subSubSubCategories.isNotEmpty,
          ),
          items: vm.subSubSubCategories
              .map(
                (cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name)),
              )
              .toList(),
          onChanged: _selectedSubSubCategoryId == null || vm.subSubSubCategories.isEmpty
              ? null
                              : (value) {
                    setState(() => _selectedSubSubSubCategoryId = value);
                  },
          validator: (v) {
            if (_selectedSubSubCategoryId != null && vm.subSubSubCategories.isNotEmpty && v == null) {
              return 'Alt alt alt kategori seçimi zorunludur';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildConditionDropdown() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        // Seçili değerin listede olup olmadığını kontrol et
        final validValue = vm.conditions.any((con) => con.id == _selectedConditionId) 
            ? _selectedConditionId 
            : null;
            
        return DropdownButtonFormField<String>(
          value: validValue,
          decoration: const InputDecoration(labelText: 'Ürün Durumu'),
          items: vm.conditions
              .map(
                (con) => DropdownMenuItem(value: con.id, child: Text(con.name)),
              )
              .toList(),
          onChanged: (value) {
            setState(() => _selectedConditionId = value);
          },
          validator: (v) => v == null ? 'Durum seçimi zorunludur' : null,
        );
      },
    );
  }

  Widget _buildCityDropdown() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        // Seçili değerin listede olup olmadığını kontrol et
        final validValue = vm.cities.any((city) => city.id == _selectedCityId) 
            ? _selectedCityId 
            : null;
            
        return DropdownButtonFormField<String>(
          value: validValue,
          decoration: const InputDecoration(
            labelText: 'İl',
            hintText: 'İl seçiniz',
          ),
          hint: const Text('İl seçiniz'),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('İl seçiniz', style: TextStyle(color: Colors.grey)),
            ),
            ...vm.cities.map(
              (city) => DropdownMenuItem(value: city.id, child: Text(city.name)),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedCityId = value;
              _selectedDistrictId = null;
            });
            if (value != null) {
              vm.loadDistricts(value);
              // Seçilen şehrin konumunu haritada göster
              _showCityLocationOnMap(value, vm);
            }
          },
          validator: (v) => v == null ? 'İl seçimi zorunludur' : null,
        );
      },
    );
  }

  Widget _buildDistrictDropdown() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        // Seçili değerin listede olup olmadığını kontrol et
        final validValue = vm.districts.any((dist) => dist.id == _selectedDistrictId) 
            ? _selectedDistrictId 
            : null;
            
        return DropdownButtonFormField<String>(
          value: validValue,
          decoration: InputDecoration(
            labelText: 'İlçe',
            hintText: 'İlçe seçiniz',
            enabled: _selectedCityId != null,
          ),
          hint: const Text('İlçe seçiniz'),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('İlçe seçiniz', style: TextStyle(color: Colors.grey)),
            ),
            ...vm.districts.map(
              (dist) => DropdownMenuItem(value: dist.id, child: Text(dist.name)),
            ),
          ],
          onChanged: _selectedCityId == null
              ? null
              : (value) async {
                  setState(() => _selectedDistrictId = value);
                  
                  // İlçe seçildiğinde konum bilgisini güncelle
                  if (value != null) {
                    await _showDistrictLocationOnMap(value, vm);
                  }
                },
          validator: (v) => _selectedCityId != null && v == null
              ? 'İlçe seçimi zorunludur'
              : null,
        );
      },
    );
  }

  // -- Konum Widget'ları --

  Widget _buildAutoLocationButton() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _currentPosition != null ? Icons.location_on : Icons.my_location,
                color: _currentPosition != null ? Colors.green : AppTheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentPosition != null ? 'GPS Konumu Alındı' : 'GPS Konumu Al (İsteğe Bağlı)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _currentPosition != null ? Colors.green : AppTheme.primary,
                      ),
                    ),
                    if (_currentPosition != null)
                      Text(
                        '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              if (_isGettingLocation)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          
          if (_currentPosition != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _getCurrentLocation(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Yenile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: BorderSide(color: AppTheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _clearLocation(),
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Temizle'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGettingLocation ? null : () => _getCurrentLocation(),
                icon: const Icon(Icons.my_location),
                label: const Text('GPS Konumu Al'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      );
    
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      final position = await _locationService.getCurrentLocation();
      
      if (position != null) {
        setState(() {
          _currentPosition = position;
        });
        
        // Kullanıcıya başarı mesajı göster
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Text('Konum başarıyla alındı'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Hata durumunda kullanıcıya bilgi ver
        if (mounted) {
          _showLocationErrorDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konum alınırken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  void _clearLocation() {
    setState(() {
      _currentPosition = null;
    });
  }

  Future<void> _showCityLocationOnMap(String cityId, ProductViewModel vm) async {
    try {
      // Şehir ID'sine göre şehir adını bul
      final city = vm.cities.firstWhere((c) => c.id == cityId);
      final cityName = city.name;
      
      // Şehir konumunu al
      final position = await _locationService.getLocationFromCityName(cityName);
      
      if (position != null && mounted) {
        // Manuel konum olarak ayarla
        setState(() {
          _currentPosition = position;
        });
        
        // Kullanıcıya bilgi ver
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.location_city, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('$cityName konumu manuel olarak ayarlandı'),
              ],
            ),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('$cityName için konum bulunamadı'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Şehir konumu alınırken hata oluştu'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showLocationErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konum Alınamadı'),
        content: const Text(
          'Konumunuz alınamadı. Lütfen konum izinlerini kontrol edin veya GPS\'in açık olduğundan emin olun.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _locationService.openLocationSettings();
            },
            child: const Text('Ayarlar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _locationService.openGPSSettings();
            },
            child: const Text('GPS Ayarları'),
          ),
        ],
      ),
    );
  }

  // -- Resim Seçici Widget'ları --

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedImages.isEmpty) ...[
          _buildAddImageButton(),
          const SizedBox(height: 16),
        ],

        if (_selectedImages.isNotEmpty) ...[
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length + 1,
              itemBuilder: (context, index) {
                if (index == _selectedImages.length) {
                  return _buildAddImageButton();
                }
                return _buildImagePreview(_selectedImages[index], index);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        Text(
          'En az 1, en fazla 5 fotoğraf ekleyebilirsiniz. Yıldız ikonuna tıklayarak kapak resmi seçebilirsiniz.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
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
    final isCoverImage = index == _coverImageIndex;
    
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCoverImage ? AppTheme.primary : Colors.grey.shade300,
          width: isCoverImage ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              image,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),

          // Kapak resmi göstergesi
          if (isCoverImage)
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

          // Kapak resmi yapma butonu (kapak resmi değilse)
          if (!isCoverImage)
            Positioned(
              top: 4,
              left: 4,
              child: GestureDetector(
                onTap: () => _setCoverImage(index),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 14,
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
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Text(
                'Fotoğraf Seç',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

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
          // İlk fotoğraf eklendiğinde otomatik olarak kapak resmi yap
          if (_selectedImages.length == 1) {
            _coverImageIndex = 0;
          }
        });


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

      final List<XFile> pickedFiles = await _imagePicker.pickMultipleMedia(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        final List<XFile> filesToAdd = pickedFiles.take(remainingSlots).toList();
        
        setState(() {
          for (final file in filesToAdd) {
            _selectedImages.add(File(file.path));
          }
          // İlk fotoğraf eklendiğinde otomatik olarak kapak resmi yap
          if (_selectedImages.length == filesToAdd.length) {
            _coverImageIndex = 0;
          }
        });



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
      
      // Eğer silinen resim kapak resmiyse, ilk resmi kapak resmi yap
      if (index == _coverImageIndex) {
        _coverImageIndex = 0;
      } else if (index < _coverImageIndex) {
        // Eğer silinen resim kapak resminden önceyse, kapak resmi indeksini güncelle
        _coverImageIndex--;
      }
    });

  }

  void _setCoverImage(int index) {
    setState(() {
      _coverImageIndex = index;
    });

    
    // Kullanıcıya bilgi ver
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.star, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            const Text('Kapak resmi olarak ayarlandı'),
          ],
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildContactSettingsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _stepIcons[5],
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İletişim Ayarları',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'İletişim bilgilerinizin görünürlüğünü ayarlayın',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // İletişim ayarları kartı
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
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
                
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
     
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

  Future<void> _showDistrictLocationOnMap(String districtId, ProductViewModel vm) async {
    try {
      // İlçe ID'sine göre ilçe adını bul
      final district = vm.districts.firstWhere((d) => d.id == districtId);
      final districtName = district.name;
      
      // Şehir adını da al (daha doğru konum için)
      final city = vm.cities.firstWhere((c) => c.id == _selectedCityId);
      final cityName = city.name;
      
      // İlçe konumunu al (şehir + ilçe kombinasyonu ile)
      final position = await _locationService.getLocationFromCityName('$districtName, $cityName, Turkey');
      
      if (position != null && mounted) {
        // Manuel konum olarak ayarla
        setState(() {
          _currentPosition = position;
        });
        
        // Kullanıcıya bilgi ver
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('$districtName konumu manuel olarak ayarlandı'),
              ],
            ),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('$districtName için konum bulunamadı'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('İlçe konumu alınırken hata oluştu'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}