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
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst kısım - Avatar ve İstatistikler
          Row(
            children: [
              // Avatar - Köşeli tasarım
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                ),
                child: user.avatar != null
                    ? Image.network(
                        user.avatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[100],
                            child: const Icon(
                              Icons.person,
                              size: 36,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[100],
                        child: const Icon(
                          Icons.person,
                          size: 36,
                          color: Colors.grey,
                        ),
                      ),
              ),
              
              const SizedBox(width: 32),
              
              // İstatistikler - Kurumsal tasarım
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildKurumsalStatItem(
                      count: productCount.toString(),
                      label: 'İlan',
                    ),
                    _buildKurumsalStatItem(
                      count: favoriteCount.toString(),
                      label: 'Favori',
                    ),
                    _buildKurumsalStatItem(
                      count: '0',
                      label: 'Puan',
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Kullanıcı Bilgileri
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kullanıcı Adı
              Row(
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (user.isVerified) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.verified,
                      size: 18,
                      color: AppTheme.primary,
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 6),
              
              // Email
              Text(
                user.email,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w400,
                ),
              ),
              
              // Telefon (varsa)
              if (user.phone != null && user.phone!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  user.phone!,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Butonlar - Kurumsal tasarım
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  color: Colors.grey[100],
                  child: TextButton(
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
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black87,
                      padding: EdgeInsets.zero,
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: const Text(
                      'Profili Düzenle',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: Container(
                  height: 40,
                  color: AppTheme.primary,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Ürün ekleme sayfasına yönlendir
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: const Text(
                      'Ürün Ekle',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
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

  Widget _buildKurumsalStatItem({
    required String count,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(int productCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      color: Colors.white,
      child: Row(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: AppTheme.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          const Text(
            'İlanlarım',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: Colors.grey[100],
            child: Text(
              '$productCount ürün',
              style: TextStyle(
                fontSize: 13,
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
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(40.0),
            color: Colors.white,
            child: const Center(child: LoadingWidget()),
          );
        }

        if (productViewModel.myProducts.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(40.0),
            color: Colors.white,
            child: _buildEmptyTab(
              icon: Icons.inventory_2_outlined,
              title: 'Henüz Ürün Eklenmemiş',
              subtitle: 'İlk ürününüzü ekleyerek satışa başlayabilirsiniz.',
              actionButton: Container(
                height: 40,
                color: AppTheme.primary,
                child: TextButton(
                  onPressed: () {
                    // TODO: Ürün ekleme sayfasına yönlendir
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: const Text(
                    'Ürün Ekle',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          color: Colors.white,
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
                    heroTag: 'profile_my_product_${product.id}_$index',
                    hideFavoriteIcon: true, // Kullanıcının kendi ilanlarında favori ikonunu gizle
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


