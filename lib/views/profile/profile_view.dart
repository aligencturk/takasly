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
    _tabController = TabController(length: 3, vsync: this);
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
      appBar: AppBar(
        title: const Text('Profilim'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Ayarlar sayfasına yönlendir
            },
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            onPressed: () => _showLogoutConfirmDialog(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Consumer<UserViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading || vm.currentUser == null) {
            return const LoadingWidget();
          }

          final user = vm.currentUser!;
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(child: _buildProfileHeader(context, user)),
                SliverPersistentHeader(
                  delegate: _SliverTabBarDelegate(_buildTabBar()),
                  pinned: true,
                ),
              ];
            },
            body: _buildTabBarView(user),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User user) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.background,
            backgroundImage: user.avatar != null
                ? NetworkImage(user.avatar!)
                : null,
            child: user.avatar == null
                ? const Icon(
                    Icons.person,
                    size: 50,
                    color: AppTheme.textSecondary,
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(user.name, style: textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
          ),

          // Telefon numarası (varsa)
          if (user.phone != null && user.phone!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.phone,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  user.phone!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          // Konum (varsa)
          if (user.location != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${user.location!.city}, ${user.location!.country}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          // Bio (varsa)
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                user.bio!,
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const SizedBox(height: 24),
          _buildStatsRow(context, user),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // TODO: Profili düzenle sayfasına yönlendir
            },
            child: const Text('Profili Düzenle'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, User user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          context,
          count: user.totalTrades.toString(),
          label: 'Takas',
        ),
        _buildStatItem(
          context,
          count: user.rating.toStringAsFixed(1),
          label: 'Puan',
        ),
        _buildStatItem(
          context,
          count: user.isVerified ? '✓' : '✗',
          label: 'Doğrulanmış',
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String count,
    required String label,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          count,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  TabBar _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: AppTheme.primary,
      unselectedLabelColor: AppTheme.textSecondary,
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorWeight: 3.0,
      indicatorColor: AppTheme.primary,
      tabs: const [
        Tab(text: 'İlanlarım'),
        Tab(text: 'Favoriler'),
        Tab(text: 'Değerlendirmeler'),
      ],
    );
  }

  Widget _buildTabBarView(User user) {
    return Consumer<ProductViewModel>(
      builder: (context, productViewModel, child) {
        return TabBarView(
          controller: _tabController,
          children: [
            // İlanlarım
            productViewModel.isLoading
                ? const LoadingWidget()
                : _buildProductGrid(productViewModel.myProducts),
            // Favoriler
            const Center(child: Text('Favori ürünler yakında!')),
            // Değerlendirmeler
            const Center(child: Text('Değerlendirmeler yakında!')),
          ],
        );
      },
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    if (products.isEmpty) {
      return const Center(child: Text('Henüz ürün eklenmemiş.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => ProductCard(
        product: products[index],
        onTap: () {
          // TODO: Ürün detay sayfasına yönlendir
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${products[index].title} ürününe tıklandı'),
            ),
          );
        },
      ),
    );
  }

  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.orange),
            SizedBox(width: 8),
            Text('Çıkış Yap'),
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

              Navigator.pop(dialogContext); // Dialog'u kapat

              // Loading göster
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Çıkış yapılıyor...'),
                    ],
                  ),
                ),
              );

              try {
                // Çıkış yap
                await authViewModel.logout();

                if (mounted) {
                  // Loading dialog'u kapat
                  navigator.pop();

                  // Login sayfasına yönlendir
                  navigator.pushNamedAndRemoveUntil('/login', (route) => false);

                  // Başarı mesajı göster
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Başarıyla çıkış yapıldı'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  // Loading dialog'u kapat
                  navigator.pop();

                  // Hata mesajı göster
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
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppTheme.background, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
