import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:takasly/core/app_theme.dart';
import 'package:takasly/models/product.dart';
import 'package:takasly/models/product_filter.dart';
import 'package:takasly/viewmodels/product_viewmodel.dart';
import 'package:takasly/utils/logger.dart';

class CategoryList extends StatelessWidget {
  const CategoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return SliverToBoxAdapter(
      child: Consumer<ProductViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading && vm.categories.isEmpty) {
            // TODO: Skeleton loader (Shimmer) eklenecek
            return SizedBox(
              height: isSmallScreen ? 90 : 100,
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          
          return SizedBox(
            height: isSmallScreen ? 90 : 100, // Yüksekliği artırdım çünkü metin 2 satıra çıkabilir
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 20,
              ),
              itemCount: vm.categories.length + 1, // "Tümü" için +1
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildCategoryItem(
                    context: context,
                    label: 'Tümü',
                    iconData: Icons.apps_rounded,
                    isSelected: vm.currentFilter.categoryId == null,
                    onTap: () => _applyCategoryFilter(vm, null),
                    isSmallScreen: isSmallScreen,
                  );
                }
                final category = vm.categories[index - 1];
                return _buildCategoryItem(
                  context: context,
                  label: category.name,
                  iconData: _getCategoryIcon(category.icon),
                  iconUrl: _isImageUrl(category.icon) ? category.icon : null,
                  isSelected: vm.currentFilter.categoryId == category.id,
                  onTap: () => _applyCategoryFilter(vm, category.id),
                  isSmallScreen: isSmallScreen,
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _applyCategoryFilter(ProductViewModel vm, String? categoryId) {
    // Mevcut filtreyi koruyarak sadece kategoriyi değiştir
    final newFilter = vm.currentFilter.copyWith(categoryId: categoryId);
    vm.applyFilter(newFilter);
  }

  Widget _buildCategoryItem({
    required BuildContext context,
    required String label,
    required IconData iconData,
    String? iconUrl,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    final color = isSelected ? AppTheme.surface : AppTheme.primary;
    final bgColor = isSelected ? AppTheme.primary : AppTheme.surface;
    
    // Responsive boyutlar
    final iconSize = isSmallScreen ? 20.0 : 24.0;
    final containerSize = isSmallScreen ? 45.0 : 50.0;
    final spacing = isSmallScreen ? 6.0 : 8.0;
    final horizontalPadding = isSmallScreen ? 8.0 : 10.0;
    
    return Container(
      width: isSmallScreen ? 70.0 : 80.0, // Sabit genişlik
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding / 2),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min, // Minimum boyut kullan
          children: [
            // İkon container'ı - sabit yükseklik
            Container(
              height: containerSize + spacing + 32, // İkon + spacing + metin için sabit yükseklik
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start, // Üstten başla
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: containerSize,
                    height: containerSize,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                      boxShadow: isSelected ? AppTheme.cardShadow : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                      child: iconUrl != null
                          ? _buildNetworkIcon(iconUrl, iconSize, color, iconData)
                          : Icon(iconData, color: color, size: iconSize),
                    ),
                  ),
                  SizedBox(height: spacing),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: AppTheme.textPrimary,
                          fontSize: isSmallScreen ? 11 : 12,
                        ),
                    maxLines: 2, // İki satıra kadar izin ver
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center, // Metni ortala
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isImageUrl(String? iconName) {
    if (iconName == null || iconName.isEmpty) return false;
    return iconName.startsWith('http://') || iconName.startsWith('https://');
  }

  Future<String> _loadSvgFromNetwork(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('SVG yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('SVG yüklenirken hata: $e');
    }
  }

  Widget _buildNetworkIcon(String iconUrl, double iconSize, Color color, IconData fallbackIcon) {
    // SVG dosyaları için özel işlem
    if (iconUrl.toLowerCase().endsWith('.svg')) {
      Logger.info('SVG yükleniyor: $iconUrl');
      return FutureBuilder<String>(
        future: _loadSvgFromNetwork(iconUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Icon(fallbackIcon, color: color, size: iconSize);
          }
          if (snapshot.hasError || !snapshot.hasData) {
            Logger.error('SVG yüklenemedi: $iconUrl', error: snapshot.error);
            return Icon(fallbackIcon, color: color, size: iconSize);
          }
          return SvgPicture.string(
            snapshot.data!,
            width: iconSize,
            height: iconSize,
          );
        },
      );
    }
    
    // PNG, JPG gibi dosyalar için normal Image.network
    return Image.network(
      iconUrl,
      width: iconSize,
      height: iconSize,
      fit: BoxFit.contain,
      color: color,
      errorBuilder: (context, error, stackTrace) {
        Logger.error('Kategori icon yüklenemedi: $iconUrl', error: error);
        return Icon(fallbackIcon, color: color, size: iconSize);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Icon(fallbackIcon, color: color, size: iconSize);
      },
    );
  }
  
  // Bu ikon eşleştirme, API'den gelen string'lere göre düzenlenmeli
  IconData _getCategoryIcon(String? iconName) {
    if (iconName == null || iconName.isEmpty) return Icons.category_sharp;
    
    // Eğer URL ise, fallback icon döndür
    if (_isImageUrl(iconName)) {
      return Icons.category_sharp;
    }
    
    switch (iconName.toLowerCase()) {
      // Debug loglarından gelen kategoriler
      case 'araba': return Icons.directions_car_rounded;
      case 'pet shop': return Icons.pets_rounded;
      case 'anne & bebek & oyuncak': return Icons.child_care_rounded;
      case 'telefon': return Icons.phone_android_rounded;
      case 'antika': return Icons.collections_rounded;
      case 'giyim & aksesuar': return Icons.checkroom_rounded;
      case 'elektronik': return Icons.phone_iphone_rounded;
      case 'hobi & kitap & müzik': return Icons.music_note_rounded;
      case 'ofis & kırtasiye': return Icons.work_rounded;
      case 'ev & yaşam': return Icons.home_rounded;
      case 'spor & outdoor': return Icons.sports_soccer_rounded;
      case 'diğer araçlar': return Icons.directions_car_rounded;
      case 'kişisel bakım & kozmetik': return Icons.face_rounded;
      case 'yapı market & bahçe': return Icons.yard_rounded;
      case 'motosiklet': return Icons.motorcycle_rounded;
      
      // Genel kategoriler
      case 'giyim': return Icons.checkroom_rounded;
      case 'kitap': return Icons.menu_book_rounded;
      case 'ev & yaşam': return Icons.chair_rounded;
      case 'spor': return Icons.sports_soccer_rounded;
      case 'motosiklet': return Icons.motorcycle_rounded;
      case 'bisiklet': return Icons.pedal_bike_rounded;
      case 'ev eşyaları': return Icons.home_rounded;
      case 'mobilya': return Icons.chair_rounded;
      case 'dekorasyon': return Icons.photo_rounded;
      case 'bahçe': return Icons.yard_rounded;
      case 'hobi': return Icons.sports_esports_rounded;
      case 'oyuncak': return Icons.toys_rounded;
      case 'koleksiyon': return Icons.collections_rounded;
      case 'sanat': return Icons.palette_rounded;
      case 'müzik': return Icons.music_note_rounded;
      case 'film': return Icons.movie_rounded;
      case 'bilgisayar': return Icons.computer_rounded;
      case 'tablet': return Icons.tablet_android_rounded;
      case 'laptop': return Icons.laptop_rounded;
      case 'aksesuar': return Icons.watch_rounded;
      case 'saat': return Icons.access_time_rounded;
      case 'takı': return Icons.diamond_rounded;
      case 'kozmetik': return Icons.face_rounded;
      case 'sağlık': return Icons.local_hospital_rounded;
      case 'bebek': return Icons.child_care_rounded;
      case 'çocuk': return Icons.child_friendly_rounded;
      case 'kadın': return Icons.person_rounded;
      case 'erkek': return Icons.person_rounded;
      case 'unisex': return Icons.person_rounded;
      case 'ayakkabı': return Icons.sports_soccer_rounded;
      case 'çanta': return Icons.work_rounded;
      case 'gözlük': return Icons.remove_red_eye_rounded;
      case 'şapka': return Icons.face_rounded;
      case 'çorap': return Icons.sports_soccer_rounded;
      case 'iç çamaşırı': return Icons.checkroom_rounded;
      case 'mayo': return Icons.beach_access_rounded;
      case 'mont': return Icons.ac_unit_rounded;
      case 'ceket': return Icons.checkroom_rounded;
      case 'elbise': return Icons.checkroom_rounded;
      case 'pantolon': return Icons.checkroom_rounded;
      case 'etek': return Icons.checkroom_rounded;
      case 'gömlek': return Icons.checkroom_rounded;
      case 'tişört': return Icons.checkroom_rounded;
      case 'kazak': return Icons.checkroom_rounded;
      case 'hırka': return Icons.checkroom_rounded;
      case 'sweatshirt': return Icons.checkroom_rounded;
      case 'kapüşonlu': return Icons.checkroom_rounded;
      case 'bluz': return Icons.checkroom_rounded;
      case 'tunik': return Icons.checkroom_rounded;
      case 'tayt': return Icons.checkroom_rounded;
      case 'şort': return Icons.beach_access_rounded;
      case 'bermuda': return Icons.beach_access_rounded;
      case 'kargo': return Icons.checkroom_rounded;
      case 'kot': return Icons.checkroom_rounded;
      case 'deri': return Icons.checkroom_rounded;
      case 'kadife': return Icons.checkroom_rounded;
      case 'ipek': return Icons.checkroom_rounded;
      case 'keten': return Icons.checkroom_rounded;
      case 'yün': return Icons.checkroom_rounded;
      case 'polar': return Icons.ac_unit_rounded;
      default: return Icons.category_sharp;
    }
  }
} 