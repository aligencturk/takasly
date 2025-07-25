import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_filter.dart';
import '../models/city.dart';
import '../models/district.dart';
import '../models/condition.dart';
import '../models/product.dart' as product_model;
import '../viewmodels/product_viewmodel.dart';
import '../services/location_service.dart';
import '../core/app_theme.dart';

class FilterBottomSheet extends StatefulWidget {
  final ProductFilter currentFilter;
  final Function(ProductFilter) onApplyFilter;

  const FilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.onApplyFilter,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late ProductFilter _tempFilter;
  String? _selectedCityId;
  List<District> _districts = [];
  bool _isLoadingDistricts = false;

  @override
  void initState() {
    super.initState();
    _tempFilter = widget.currentFilter;
    _selectedCityId = widget.currentFilter.cityId;

    // Eğer şehir seçiliyse ilçeleri yükle
    if (_selectedCityId != null && _selectedCityId!.isNotEmpty) {
      _loadDistricts(_selectedCityId!);
    }
  }

  Future<void> _loadDistricts(String cityId) async {
    setState(() {
      _isLoadingDistricts = true;
    });

    final productViewModel = Provider.of<ProductViewModel>(
      context,
      listen: false,
    );
    await productViewModel.loadDistricts(cityId);

    setState(() {
      _districts = productViewModel.districts;
      _isLoadingDistricts = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtrele',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Temizle'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filter Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryFilter(),
                  const SizedBox(height: 24),
                  _buildConditionFilter(),
                  const SizedBox(height: 24),
                  _buildLocationFilter(),
                  const SizedBox(height: 24),
                  _buildSortFilter(),
                ],
              ),
            ),
          ),

          // Apply Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Filtreleri Uygula${_tempFilter.hasActiveFilters ? ' (${_getActiveFilterCount()})' : ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        if (vm.categories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kategori',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Tümü seçeneği
                _buildFilterChip(
                  label: 'Tümü',
                  isSelected: _tempFilter.categoryId == null,
                  onTap: () {
                    setState(() {
                      _tempFilter = _tempFilter.copyWith(categoryId: null);
                    });
                  },
                ),
                // Kategoriler
                ...vm.categories.map(
                  (category) => _buildFilterChip(
                    label: category.name,
                    isSelected: _tempFilter.categoryId == category.id,
                    onTap: () {
                      setState(() {
                        _tempFilter = _tempFilter.copyWith(
                          categoryId: category.id,
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildConditionFilter() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        if (vm.conditions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ürün Durumu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: vm.conditions.map((condition) {
                final isSelected = _tempFilter.conditionIds.contains(
                  condition.id,
                );
                return _buildFilterChip(
                  label: condition.name,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      final newConditionIds = List<String>.from(
                        _tempFilter.conditionIds,
                      );
                      if (isSelected) {
                        newConditionIds.remove(condition.id);
                      } else {
                        newConditionIds.add(condition.id);
                      }
                      _tempFilter = _tempFilter.copyWith(
                        conditionIds: newConditionIds,
                      );
                    });
                  },
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLocationFilter() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Konum',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // Şehir Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCityId,
              decoration: InputDecoration(
                labelText: 'Şehir Seçin',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Tüm Şehirler'),
                ),
                ...vm.cities.map(
                  (city) => DropdownMenuItem<String>(
                    value: city.id,
                    child: Text(city.name),
                  ),
                ),
              ],
              onChanged: (value) async {
                setState(() {
                  _selectedCityId = value;
                  _tempFilter = _tempFilter.copyWith(
                    cityId: value,
                    districtId: null, // Şehir değişince ilçeyi sıfırla
                  );
                  _districts.clear();
                });

                if (value != null && value.isNotEmpty) {
                  await _loadDistricts(value);
                }
              },
            ),

            const SizedBox(height: 16),

            // İlçe Dropdown
            DropdownButtonFormField<String>(
              value: _tempFilter.districtId,
              decoration: InputDecoration(
                labelText: 'İlçe Seçin',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Tüm İlçeler'),
                ),
                ..._districts.map(
                  (district) => DropdownMenuItem<String>(
                    value: district.id,
                    child: Text(district.name),
                  ),
                ),
              ],
              onChanged: _selectedCityId == null
                  ? null
                  : (value) {
                      setState(() {
                        _tempFilter = _tempFilter.copyWith(districtId: value);
                      });
                    },
            ),

            if (_isLoadingDistricts)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('İlçeler yükleniyor...'),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSortFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sıralama',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SortType.values
              .map(
                (sortType) => _buildFilterChip(
                  label: sortType.label,
                  isSelected: _tempFilter.sortType == sortType.value,
                  onTap: () async {
                    // Eğer "Bana En Yakın" seçiliyorsa konum izni iste
                    if (sortType.value == 'location') {
                      await _handleLocationSorting();
                    } else {
                      setState(() {
                        _tempFilter = _tempFilter.copyWith(
                          sortType: sortType.value,
                        );
                      });
                    }
                  },
                ),
              )
              .toList(),
        ),

        // Konum sıralaması seçiliyse bilgi mesajı göster
        if (_tempFilter.sortType == 'location')
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Konumunuza en yakın ürünler gösterilecek',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _handleLocationSorting() async {
    print('📍 FilterBottomSheet: Location sorting requested');

    // Loading dialog göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Konum izni isteniyor...'),
          ],
        ),
      ),
    );

    try {
      final locationService = LocationService();

      // Konum izni iste
      final hasPermission = await locationService.requestLocationPermission();

      // Loading dialog'u kapat
      if (mounted) Navigator.pop(context);

      if (hasPermission) {
        // Konum servisi aktif mi kontrol et
        final isServiceEnabled = await locationService
            .isLocationServiceEnabled();

        if (isServiceEnabled) {
          print('✅ Location permission granted and service enabled');
          setState(() {
            _tempFilter = _tempFilter.copyWith(sortType: 'location');
          });

          // Başarı mesajı göster
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Konum izni verildi. En yakın ürünler gösterilecek.'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          print('❌ Location service is disabled');
          _showLocationServiceDialog();
        }
      } else {
        print('❌ Location permission denied');
        _showLocationPermissionDialog();
      }
    } catch (e) {
      print('❌ Error handling location sorting: $e');

      // Loading dialog'u kapat (eğer hala açıksa)
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konum izni alınırken hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Konum İzni Gerekli'),
          ],
        ),
        content: const Text(
          'Size en yakın ürünleri gösterebilmek için konum izni gerekiyor. '
          'Lütfen ayarlardan konum iznini açın.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final locationService = LocationService();
              await locationService.requestLocationPermission();
            },
            child: const Text('Ayarlara Git'),
          ),
        ],
      ),
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_disabled, color: Colors.orange),
            SizedBox(width: 8),
            Text('Konum Servisi Kapalı'),
          ],
        ),
        content: const Text(
          'Size en yakın ürünleri gösterebilmek için konum servisini açmanız gerekiyor. '
          'Lütfen cihazınızın konum ayarlarını kontrol edin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _tempFilter = const ProductFilter();
      _selectedCityId = null;
      _districts.clear();
    });
  }

  void _applyFilters() {
    widget.onApplyFilter(_tempFilter);
    Navigator.pop(context);
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_tempFilter.categoryId != null) count++;
    if (_tempFilter.conditionIds.isNotEmpty) count++;
    if (_tempFilter.cityId != null) count++;
    if (_tempFilter.districtId != null) count++;
    if (_tempFilter.sortType != 'default') count++;
    return count;
  }
}
