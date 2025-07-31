import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takasly/core/app_theme.dart';
import 'package:takasly/models/user.dart';
import 'package:takasly/models/product.dart';
import 'package:takasly/viewmodels/auth_viewmodel.dart';
import 'package:takasly/viewmodels/product_viewmodel.dart';
import 'package:takasly/viewmodels/user_viewmodel.dart';
import 'package:takasly/widgets/loading_widget.dart';
import 'package:takasly/widgets/product_card.dart';
import 'edit_profile_view.dart';
import '../product/edit_product_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    // Sayfa ilk açıldığında verileri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final productViewModel = Provider.of<ProductViewModel>(
        context,
        listen: false,
      );

      // Kullanıcı verilerini yükle
      userViewModel.forceRefreshUser();

      // Kullanıcının ürünlerini yükle
      final userId = userViewModel.currentUser?.id;
      if (userId != null) {
        productViewModel.loadUserProducts(userId);
        // Favori ürünleri de yükle
        productViewModel.loadFavoriteProducts();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Consumer2<UserViewModel, ProductViewModel>(
        builder: (context, userVm, productVm, child) {
          if (userVm.isLoading || userVm.currentUser == null) {
            return const LoadingWidget();
          }

          final user = userVm.currentUser!;
          final productCount = productVm.myProducts.length;
          final favoriteCount = productVm.favoriteProducts.length;
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(context, user, productCount, favoriteCount),
                _buildSectionHeader(productCount),
                _buildProductsSection(user),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      title: const Text(
        'Profilim',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: Colors.black87,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // TODO: Ayarlar sayfasına yönlendir
          },
          icon: const Icon(Icons.settings_outlined, size: 24),
          tooltip: 'Ayarlar',
        ),
        IconButton(
          onPressed: () => _showLogoutConfirmDialog(),
          icon: const Icon(Icons.logout, size: 24, color: Colors.red),
          tooltip: 'Çıkış Yap',
        ),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context, User user, int productCount, int favoriteCount) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: user.avatar != null
                ? ClipOval(
                    child: Image.network(
                      user.avatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.grey,
                  ),
          ),
          const SizedBox(height: 20),
          
          // Kullanıcı Adı
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          
          // Email
          Text(
            user.email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          
          // Telefon (varsa)
          if (user.phone != null && user.phone!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.phone,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  user.phone!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
          
          // Doğrulanmış rozeti
          if (user.isVerified) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified,
                    size: 16,
                    color: Colors.green[700],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Doğrulanmış',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // İstatistikler
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  context,
                  icon: Icons.inventory_2_outlined,
                  count: productCount.toString(),
                  label: 'Aktif İlan',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                _buildStatItem(
                  context,
                  icon: Icons.favorite_border,
                  count: favoriteCount.toString(),
                  label: 'Favori',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                _buildStatItem(
                  context,
                  icon: Icons.star_outline,
                  count: '0',
                  label: 'Puan',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Profil Düzenle Butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final userViewModel = Provider.of<UserViewModel>(context, listen: false);
                
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileView(),
                  ),
                );
                
                if (result == true && mounted) {
                  userViewModel.forceRefreshUser();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Profili Düzenle',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String count,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.grey[700]),
        const SizedBox(height: 8),
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(int productCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: AppTheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'İlanlarım',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$productCount ürün',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection(User user) {
    return Consumer<ProductViewModel>(
      builder: (context, productViewModel, child) {
        if (productViewModel.isLoading) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(40.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Center(child: LoadingWidget()),
          );
        }

        if (productViewModel.myProducts.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(40.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: _buildEmptyTab(
              icon: Icons.inventory_2_outlined,
              title: 'Henüz Ürün Eklenmemiş',
              subtitle: 'İlk ürününüzü ekleyerek satışa başlayabilirsiniz.',
              actionButton: ElevatedButton(
                onPressed: () {
                  // TODO: Ürün ekleme sayfasına yönlendir
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Ürün Ekle'),
              ),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: productViewModel.myProducts.length,
            itemBuilder: (context, index) {
              final product = productViewModel.myProducts[index];
              return Stack(
                children: [
                  ProductCard(
                    product: product,
                    heroTag: 'profile_product_${product.id}_$index',
                    onTap: () {
                      // TODO: Ürün detay sayfasına yönlendir
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.title} ürününe tıklandı'),
                        ),
                      );
                    },
                  ),
                                     // İlanı Güncelle butonu (sol üst)
                   Positioned(
                     top: 7,
                     left: 7,
                     child: Material(
                       color: Colors.transparent,
                       child: InkWell(
                         onTap: () => _editProduct(product),
                         borderRadius: BorderRadius.circular(16),
                         child: const Padding(
                           padding: EdgeInsets.all(6),
                           child: Icon(
                             Icons.edit_outlined,
                             color: Colors.orange,
                             size: 18,
                           ),
                         ),
                       ),
                     ),
                   ),
                   // İlanı Sil butonu (sağ üst)
                   Positioned(
                     top: 7,
                     right: 7,
                     child: Material(
                       color: Colors.transparent,
                       child: InkWell(
                         onTap: () => _showDeleteConfirmDialog(product),
                         borderRadius: BorderRadius.circular(16),
                         child: const Padding(
                           padding: EdgeInsets.all(6),
                           child: Icon(
                             Icons.delete_outline,
                             color: Colors.red,
                             size: 18,
                           ),
                         ),
                       ),
                     ),
                   ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyTab({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? actionButton,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 64,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        if (actionButton != null) ...[
          const SizedBox(height: 20),
          actionButton,
        ],
      ],
    );
  }

  void _editProduct(Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductView(product: product),
      ),
    );

    // Eğer ürün güncellendiyse listeyi yenile
    if (result == true && mounted) {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final productViewModel = Provider.of<ProductViewModel>(context, listen: false);
      
      // Kullanıcı verilerini yenile
      userViewModel.forceRefreshUser();
      
      // Kullanıcının ürünlerini yenile
      final userId = userViewModel.currentUser?.id;
      if (userId != null) {
        productViewModel.loadUserProducts(userId);
      }
    }
  }

  void _showDeleteConfirmDialog(Product product) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete_outline, color: Colors.red[700], size: 20),
            ),
            const SizedBox(width: 12),
            const Text('İlanı Sil'),
          ],
        ),
        content: Text(
          '"${product.title}" adlı ilanı silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deleteProduct(product);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    // Loading dialog göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text('${product.title} siliniyor...'),
          ],
        ),
      ),
    );

    try {
      final productViewModel = Provider.of<ProductViewModel>(context, listen: false);
      final success = await productViewModel.deleteUserProduct(product.id);

      // Loading dialog'u kapat
      if (mounted) Navigator.pop(context);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('"${product.title}" başarıyla silindi'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          final errorMessage = productViewModel.errorMessage ?? 'İlan silinemedi';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Hata: $errorMessage'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Loading dialog'u kapat
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                const Text('İlan silinirken hata oluştu'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.logout, color: Colors.red[700], size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Çıkış Yap'),
          ],
        ),
        content: const Text(
          'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final authViewModel = Provider.of<AuthViewModel>(
                context,
                listen: false,
              );
              final userViewModel = Provider.of<UserViewModel>(
                context,
                listen: false,
              );

              Navigator.pop(dialogContext);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  content: Row(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: 16),
                      const Text('Çıkış yapılıyor...'),
                    ],
                  ),
                ),
              );

              try {
                await authViewModel.logout();
                await userViewModel.logout();

                if (mounted) {
                  navigator.pop();
                  navigator.pushNamedAndRemoveUntil('/login', (route) => false);

                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Başarıyla çıkış yapıldı'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Çıkış yapılırken hata oluştu: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}


