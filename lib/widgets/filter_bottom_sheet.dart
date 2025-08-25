import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_filter.dart';
import '../models/district.dart';
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
  
  // Kategori seçimleri
  String? _selectedCategoryId;
  String? _selectedSubCategoryId;
  String? _selectedSubSubCategoryId;
  String? _selectedSubSubSubCategoryId;
  
  // Akordiyon durumları
  bool _isCategoryExpanded = false;
  bool _isConditionExpanded = false;
  bool _isLocationExpanded = false;
  bool _isSortExpanded = false;
  bool _isViewExpanded = false;

  @override
  void initState() {
    super.initState();
    _tempFilter = widget.currentFilter;
    _selectedCityId = widget.currentFilter.cityId;
    
    // Kategori seçimlerini başlat
    _selectedCategoryId = widget.currentFilter.categoryId;
    _selectedSubCategoryId = widget.currentFilter.subCategoryId;
    _selectedSubSubCategoryId = widget.currentFilter.subSubCategoryId;
    _selectedSubSubSubCategoryId = widget.currentFilter.subSubSubCategoryId;

    // Eğer şehir seçiliyse ilçeleri yükle
    if (_selectedCityId != null && _selectedCityId!.isNotEmpty) {
      _loadDistricts(_selectedCityId!);
    }
    
    // Alt kategorileri yükle
    _loadSubCategoriesIfNeeded();
    
    // Aktif filtreler varsa ilgili bölümleri aç
    _initializeExpandedSections();
  }

  void _initializeExpandedSections() {
    if (_tempFilter.categoryId != null || _tempFilter.subCategoryId != null || 
        _tempFilter.subSubCategoryId != null || _tempFilter.subSubSubCategoryId != null) {
      _isCategoryExpanded = true;
    }
    if (_tempFilter.conditionIds.isNotEmpty) _isConditionExpanded = true;
    if (_tempFilter.cityId != null || _tempFilter.districtId != null) _isLocationExpanded = true;
    if (_tempFilter.sortType != 'default') _isSortExpanded = true;
    if (_tempFilter.viewType != 'grid') _isViewExpanded = true;
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

  Future<void> _loadSubCategoriesIfNeeded() async {
    final productViewModel = Provider.of<ProductViewModel>(context, listen: false);
    
    // Ana kategoriler zaten yüklüyse, seçili kategoriler için alt kategorileri yükle
    if (_selectedCategoryId != null) {
      await productViewModel.loadSubCategories(_selectedCategoryId!);
      
      if (_selectedSubCategoryId != null) {
        await productViewModel.loadSubSubCategories(_selectedSubCategoryId!);
        
        if (_selectedSubSubCategoryId != null) {
          await productViewModel.loadSubSubSubCategories(_selectedSubSubCategoryId!);
        }
      }
    }
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
                children: [
                  _buildAccordionSection(
                    title: 'Kategori',
                    isExpanded: _isCategoryExpanded,
                    onToggle: () => setState(() => _isCategoryExpanded = !_isCategoryExpanded),
                    content: _buildCategoryFilter(),
                    hasActiveFilter: _tempFilter.categoryId != null || 
                                   _tempFilter.subCategoryId != null ||
                                   _tempFilter.subSubCategoryId != null ||
                                   _tempFilter.subSubSubCategoryId != null,
                  ),
                  const SizedBox(height: 12),
                  _buildAccordionSection(
                    title: 'Ürün Durumu',
                    isExpanded: _isConditionExpanded,
                    onToggle: () => setState(() => _isConditionExpanded = !_isConditionExpanded),
                    content: _buildConditionFilter(),
                    hasActiveFilter: _tempFilter.conditionIds.isNotEmpty,
                  ),
                  const SizedBox(height: 12),
                  _buildAccordionSection(
                    title: 'Konum',
                    isExpanded: _isLocationExpanded,
                    onToggle: () => setState(() => _isLocationExpanded = !_isLocationExpanded),
                    content: _buildLocationFilter(),
                    hasActiveFilter: _tempFilter.cityId != null || _tempFilter.districtId != null,
                  ),
                  const SizedBox(height: 12),
                  _buildAccordionSection(
                    title: 'Sıralama',
                    isExpanded: _isSortExpanded,
                    onToggle: () => setState(() => _isSortExpanded = !_isSortExpanded),
                    content: _buildSortFilter(),
                    hasActiveFilter: _tempFilter.sortType != 'default',
                  ),
                  const SizedBox(height: 12),
                  _buildAccordionSection(
                    title: 'Görünüm',
                    isExpanded: _isViewExpanded,
                    onToggle: () => setState(() => _isViewExpanded = !_isViewExpanded),
                    content: _buildViewTypeFilter(),
                    hasActiveFilter: _tempFilter.viewType != 'grid',
                  ),
                ],
              ),
            ),
          ),

          // Apply Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              
                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _tempFilter.hasActiveFilters 
                          ? 'Filtreleri Uygula (${_getActiveFilterCount()})'
                          : 'Filtreleri Uygula',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccordionSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget content,
    required bool hasActiveFilter,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasActiveFilter ? AppTheme.primary : Colors.grey.shade200,
          width: hasActiveFilter ? 2 : 1,
        ),
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
          // Header
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: hasActiveFilter ? AppTheme.primary : Colors.grey.shade800,
                          ),
                        ),
                        if (hasActiveFilter) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Aktif',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: hasActiveFilter ? AppTheme.primary : Colors.grey.shade600,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          
          // Content
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: content,
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ana Kategoriler - Chip tarzında
            const Text(
              'Ana Kategori',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            _buildMainCategoryChips(vm),
            
            // Alt Kategori
            if (_selectedCategoryId != null && vm.subCategories.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.keyboard_arrow_right, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  const Text(
                    'Alt Kategori',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildSubCategoryChips(vm),
            ],
            
            // Alt Alt Kategori
            if (_selectedSubCategoryId != null && vm.subSubCategories.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.keyboard_double_arrow_right, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  const Text(
                    'Alt Alt Kategori',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildSubSubCategoryChips(vm),
            ],
            
            // Ürün Kategorisi (4. seviye)
            if (_selectedSubSubCategoryId != null && vm.subSubSubCategories.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.label_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  const Text(
                    'Ürün Kategorisi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildSubSubSubCategoryChips(vm),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMainCategoryChips(ProductViewModel vm) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        // Tümü seçeneği
        _buildCategoryChip(
          label: 'Tümü',
          isSelected: _selectedCategoryId == null,
          onTap: () async {
            setState(() {
              _selectedCategoryId = null;
              _selectedSubCategoryId = null;
              _selectedSubSubCategoryId = null;
              _selectedSubSubSubCategoryId = null;
              _tempFilter = _tempFilter.copyWith(
                categoryId: null,
                subCategoryId: null,
                subSubCategoryId: null,
                subSubSubCategoryId: null,
              );
            });
            vm.clearSubCategories();
          },
          icon: Icons.apps_rounded,
        ),
        // Ana kategoriler
        ...vm.categories.map(
          (category) => _buildCategoryChip(
            label: category.name,
            isSelected: _selectedCategoryId == category.id,
            onTap: () async {
              setState(() {
                _selectedCategoryId = category.id;
                _selectedSubCategoryId = null;
                _selectedSubSubCategoryId = null;
                _selectedSubSubSubCategoryId = null;
                _tempFilter = _tempFilter.copyWith(
                  categoryId: category.id,
                  subCategoryId: null,
                  subSubCategoryId: null,
                  subSubSubCategoryId: null,
                );
              });
              await vm.loadSubCategories(category.id);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubCategoryChips(ProductViewModel vm) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        // Tümü seçeneği
        _buildCategoryChip(
          label: 'Tümü',
          isSelected: _selectedSubCategoryId == null,
          onTap: () async {
            setState(() {
              _selectedSubCategoryId = null;
              _selectedSubSubCategoryId = null;
              _selectedSubSubSubCategoryId = null;
              _tempFilter = _tempFilter.copyWith(
                subCategoryId: null,
                subSubCategoryId: null,
                subSubSubCategoryId: null,
              );
            });
            vm.clearSubSubCategories();
          },
          icon: Icons.clear_all,
        ),
        // Alt kategoriler
        ...vm.subCategories.map(
          (category) => _buildCategoryChip(
            label: category.name,
            isSelected: _selectedSubCategoryId == category.id,
            onTap: () async {
              setState(() {
                _selectedSubCategoryId = category.id;
                _selectedSubSubCategoryId = null;
                _selectedSubSubSubCategoryId = null;
                _tempFilter = _tempFilter.copyWith(
                  subCategoryId: category.id,
                  subSubCategoryId: null,
                  subSubSubCategoryId: null,
                );
              });
              await vm.loadSubSubCategories(category.id);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubSubCategoryChips(ProductViewModel vm) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        // Tümü seçeneği
        _buildCategoryChip(
          label: 'Tümü',
          isSelected: _selectedSubSubCategoryId == null,
          onTap: () async {
            setState(() {
              _selectedSubSubCategoryId = null;
              _selectedSubSubSubCategoryId = null;
              _tempFilter = _tempFilter.copyWith(
                subSubCategoryId: null,
                subSubSubCategoryId: null,
              );
            });
            vm.clearSubSubSubCategories();
          },
          icon: Icons.clear_all,
        ),
        // Alt alt kategoriler
        ...vm.subSubCategories.map(
          (category) => _buildCategoryChip(
            label: category.name,
            isSelected: _selectedSubSubCategoryId == category.id,
            onTap: () async {
              setState(() {
                _selectedSubSubCategoryId = category.id;
                _selectedSubSubSubCategoryId = null;
                _tempFilter = _tempFilter.copyWith(
                  subSubCategoryId: category.id,
                  subSubSubCategoryId: null,
                );
              });
              await vm.loadSubSubSubCategories(category.id);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubSubSubCategoryChips(ProductViewModel vm) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        // Tümü seçeneği
        _buildCategoryChip(
          label: 'Tümü',
          isSelected: _selectedSubSubSubCategoryId == null,
          onTap: () {
            setState(() {
              _selectedSubSubSubCategoryId = null;
              _tempFilter = _tempFilter.copyWith(
                subSubSubCategoryId: null,
              );
            });
          },
          icon: Icons.clear_all,
        ),
        // Ürün kategorileri
        ...vm.subSubSubCategories.map(
          (category) => _buildCategoryChip(
            label: category.name,
            isSelected: _selectedSubSubSubCategoryId == category.id,
            onTap: () {
              setState(() {
                _selectedSubSubSubCategoryId = category.id;
                _tempFilter = _tempFilter.copyWith(
                  subSubSubCategoryId: category.id,
                );
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConditionFilter() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        if (vm.conditions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: vm.conditions.map((condition) {
            final isSelected = _tempFilter.conditionIds.contains(
              condition.id,
            );
            return _buildConditionChip(
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
        );
      },
    );
  }

  Widget _buildConditionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    IconData? icon;
    switch (label.toLowerCase()) {
      case 'sıfır':
      case 'yeni':
        icon = Icons.new_releases;
        break;
      case 'az kullanılmış':
      case 'temiz':
        icon = Icons.star;
        break;
      case 'kullanılmış':
      case 'normal':
        icon = Icons.check_circle_outline;
        break;
      case 'eskimiş':
      case 'eski':
        icon = Icons.schedule;
        break;
      default:
        icon = Icons.category;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
            ? AppTheme.primary
            : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
              ? AppTheme.primary
              : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppTheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationFilter() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        return Column(
          children: [
            // Şehir Dropdown
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonFormField<String>(
                value: vm.cities.any((city) => city.id == _selectedCityId) 
                    ? _selectedCityId 
                    : null,                  decoration: InputDecoration(
                    labelText: 'Şehir Seçin',
                    prefixIcon: Icon(Icons.location_city, color: AppTheme.primary, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(Icons.public, size: 20, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Tüm Şehirler'),
                      ],
                    ),
                  ),
                  ...vm.cities.map(
                    (city) => DropdownMenuItem<String>(
                      value: city.id,
                      child: Row(
                        children: [
                          Icon(Icons.location_city, size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(city.name),
                        ],
                      ),
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
            ),

            const SizedBox(height: 12),

            // İlçe Dropdown
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonFormField<String>(
                value: _districts.any((district) => district.id == _tempFilter.districtId) 
                    ? _tempFilter.districtId 
                    : null,                  decoration: InputDecoration(
                    labelText: 'İlçe Seçin',
                    prefixIcon: Icon(
                      Icons.location_on, 
                      color: _selectedCityId != null ? AppTheme.primary : Colors.grey,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(Icons.map, size: 20, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Tüm İlçeler'),
                      ],
                    ),
                  ),
                  ..._districts.map(
                    (district) => DropdownMenuItem<String>(
                      value: district.id,
                      child: Row(
                        children: [
                          Icon(Icons.location_on, size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(district.name),
                        ],
                      ),
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
            ),

            if (_isLoadingDistricts)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'İlçeler yükleniyor...',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
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
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: SortType.values
              .map(
                (sortType) => _buildSortChip(
                  label: sortType.label,
                  value: sortType.value,
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
                Icon(
                  Icons.location_on, 
                  color: Colors.blue.shade700, 
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Konumunuza en yakın ürünler gösterilecek',
                    style: TextStyle(
                      color: Colors.blue.shade700, 
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildViewTypeFilter() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _buildSortChip(
          label: 'Grid',
          value: 'grid',
          isSelected: _tempFilter.viewType == 'grid',
          onTap: () {
            setState(() {
              _tempFilter = _tempFilter.copyWith(viewType: 'grid');
            });
          },
        ),
        _buildSortChip(
          label: 'Liste',
          value: 'list',
          isSelected: _tempFilter.viewType == 'list',
          onTap: () {
            setState(() {
              _tempFilter = _tempFilter.copyWith(viewType: 'list');
            });
          },
        ),
      ],
    );
  }

  Widget _buildSortChip({
    required String label,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    IconData? icon;
    switch (value) {
      case 'default':
        icon = Icons.sort;
        break;
      case 'newest':
        icon = Icons.schedule;
        break;
      case 'oldest':
        icon = Icons.history;
        break;
      case 'popular':
        icon = Icons.trending_up;
        break;
      case 'location':
        icon = Icons.near_me;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
            ? AppTheme.primary
            : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
              ? AppTheme.primary
              : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppTheme.primary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
            ? AppTheme.primary
            : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
              ? AppTheme.primary
              : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppTheme.primary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
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
      final hasPermission = await locationService.checkLocationPermission();

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
              await locationService.openLocationSettings();
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
      
      // Kategori seçimlerini temizle
      _selectedCategoryId = null;
      _selectedSubCategoryId = null;
      _selectedSubSubCategoryId = null;
      _selectedSubSubSubCategoryId = null;
      
      _isCategoryExpanded = false;
      _isConditionExpanded = false;
      _isLocationExpanded = false;
      _isSortExpanded = false;
      _isViewExpanded = false;
    });
    
    // Alt kategorileri temizle
    final productViewModel = Provider.of<ProductViewModel>(context, listen: false);
    productViewModel.clearSubCategories();
  }

  void _applyFilters() {
    widget.onApplyFilter(_tempFilter);
    Navigator.pop(context);
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_tempFilter.categoryId != null) count++;
    if (_tempFilter.subCategoryId != null) count++;
    if (_tempFilter.subSubCategoryId != null) count++;
    if (_tempFilter.subSubSubCategoryId != null) count++;
    if (_tempFilter.conditionIds.isNotEmpty) count++;
    if (_tempFilter.cityId != null) count++;
    if (_tempFilter.districtId != null) count++;
    if (_tempFilter.sortType != 'default') count++;
    if (_tempFilter.viewType != 'grid') count++;
    return count;
  }
}
