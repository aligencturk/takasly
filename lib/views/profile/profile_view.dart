import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takasly/core/app_theme.dart';
import 'package:takasly/models/user.dart';
import 'package:takasly/models/product.dart';
import 'package:takasly/viewmodels/auth_viewmodel.dart';
import 'package:takasly/viewmodels/product_viewmodel.dart';
import 'package:takasly/viewmodels/user_viewmodel.dart';
import 'package:takasly/viewmodels/user_profile_detail_viewmodel.dart';
import 'package:takasly/widgets/loading_widget.dart';
import 'package:takasly/widgets/product_card.dart';
import 'package:takasly/utils/logger.dart';
import 'package:takasly/services/user_service.dart';
import 'package:takasly/utils/phone_formatter.dart';
import 'edit_profile_view.dart';
import 'settings_view.dart';
import '../product/edit_product_view.dart';
import '../product/product_detail_view.dart';

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
    // Widget build edildikten sonra veri yükleme işlemini yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final productViewModel = Provider.of<ProductViewModel>(
      context,
      listen: false,
    );

    // Eğer kullanıcı henüz yüklenmemişse, UserViewModel'in initialize olmasını bekle
    if (userViewModel.currentUser == null && !userViewModel.isLoading) {
      Logger.info('👤 ProfileView - User not loaded yet, waiting for initialization...');
      // UserViewModel'in initialize olmasını bekle
      await Future.delayed(Duration(milliseconds: 500));
      if (!mounted) return;
    }

    // Önce kullanıcı verilerini yükle
    await userViewModel.forceRefreshUser();
    if (!mounted) return;

    // Kullanıcı verileri yüklendikten sonra diğer verileri yükle
    final userId = userViewModel.currentUser?.id;
    if (userId != null) {
      Logger.info('👤 ProfileView - Loading data for user ID: $userId');
      
      // Kullanıcının ürünlerini yükle
      Logger.info('👤 ProfileView - Loading user products for user ID: $userId');
      await productViewModel.loadUserProducts(userId);
      if (!mounted) return;
      
      // Yüklenen ürünlerin adres bilgilerini kontrol et
      Logger.info('👤 ProfileView - Loaded ${productViewModel.myProducts.length} products');
      for (int i = 0; i < productViewModel.myProducts.length; i++) {
        final product = productViewModel.myProducts[i];
        Logger.debug('👤 ProfileView - Product $i: ${product.title}');
        Logger.debug('👤 ProfileView - Product $i location: cityTitle="${product.cityTitle}", districtTitle="${product.districtTitle}"');
      }
      
      // Kullanıcının favori ürünlerini yükle
      await productViewModel.loadFavoriteProducts();
      if (!mounted) return;
      
      // Kullanıcının profil detaylarını yükle (değerlendirmeler için)
      await _loadUserProfileDetail(int.parse(userId));
    } else {
      Logger.warning('⚠️ ProfileView - User ID is null, cannot load profile data');
      Logger.warning('⚠️ ProfileView - UserViewModel state: isLoading=${userViewModel.isLoading}, hasError=${userViewModel.hasError}');
    }

}

// (Taşındı) No-stretch davranış sınıfı bu dosyanın en altına taşındı

  Future<void> _loadUserProfileDetail(int userId) async {
    if (!mounted) return;
    
    Logger.info('👤 ProfileView - _loadUserProfileDetail - Starting for user ID: $userId');
    
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final profileDetailViewModel = Provider.of<UserProfileDetailViewModel>(context, listen: false);
    final userToken = userViewModel.currentUser?.token;
    
    Logger.debug('👤 ProfileView - _loadUserProfileDetail - User token: ${userToken?.substring(0, 10)}...');
    
    if (userToken != null) {
      profileDetailViewModel.setUserToken(userToken);
      Logger.info('👤 ProfileView - _loadUserProfileDetail - Loading profile detail...');
      
      await profileDetailViewModel.loadProfileDetail(
        userToken: userToken,
        userId: userId,
      );
      
      Logger.info('👤 ProfileView - _loadUserProfileDetail - Profile detail loading completed');
      Logger.debug('👤 ProfileView - _loadUserProfileDetail - Has data: ${profileDetailViewModel.hasData}');
      Logger.debug('👤 ProfileView - _loadUserProfileDetail - Has error: ${profileDetailViewModel.hasError}');
      Logger.debug('👤 ProfileView - _loadUserProfileDetail - Error message: ${profileDetailViewModel.errorMessage}');
      
      if (profileDetailViewModel.hasData && profileDetailViewModel.profileDetail != null) {
        final profile = profileDetailViewModel.profileDetail!;
        Logger.info('👤 ProfileView - _loadUserProfileDetail - Profile loaded successfully');
        Logger.debug('👤 ProfileView - _loadUserProfileDetail - User: ${profile.userFullname}');
        Logger.debug('👤 ProfileView - _loadUserProfileDetail - MyReviews count: ${profile.myReviews.length}');
        Logger.debug('👤 ProfileView - _loadUserProfileDetail - Reviews count: ${profile.reviews.length}');
        
        // MyReviews detaylarını daha detaylı logla
        if (profile.myReviews.isEmpty) {
          Logger.warning('⚠️ ProfileView - _loadUserProfileDetail - MyReviews array is empty!');
          Logger.debug('👤 ProfileView - _loadUserProfileDetail - This might indicate:');
          Logger.debug('👤 ProfileView - _loadUserProfileDetail - 1. User has not made any reviews yet');
          Logger.debug('👤 ProfileView - _loadUserProfileDetail - 2. API is not returning myReviews field');
          Logger.debug('👤 ProfileView - _loadUserProfileDetail - 3. Field name mismatch in API response');
        } else {
          Logger.info('👤 ProfileView - _loadUserProfileDetail - MyReviews found:');
          for (int i = 0; i < profile.myReviews.length; i++) {
            final review = profile.myReviews[i];
            Logger.debug('👤 ProfileView - _loadUserProfileDetail - MyReview $i: ID=${review.reviewID}, Name="${review.reviewerName}", Rating=${review.rating}, Comment="${review.comment}"');
          }
        }
        
        // Reviews detaylarını da logla
        if (profile.reviews.isNotEmpty) {
          Logger.info('👤 ProfileView - _loadUserProfileDetail - Reviews found:');
          for (int i = 0; i < profile.reviews.length; i++) {
            final review = profile.reviews[i];
            Logger.debug('👤 ProfileView - _loadUserProfileDetail - Review $i: ID=${review.reviewID}, Name="${review.reviewerName}", Rating=${review.rating}, Comment="${review.comment}"');
          }
        }
      }
    } else {
      Logger.error('❌ ProfileView - _loadUserProfileDetail - User token is null');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double _calculateChildAspectRatio(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    
    // Responsive aspect ratio hesaplama
    if (screenWidth < 360) {
      return 0.75; // Küçük ekranlar için daha yüksek oran
    } else if (screenWidth < 400) {
      return 0.72; // Orta-küçük ekranlar
    } else if (screenWidth < 600) {
      return 0.7; // Orta ekranlar
    } else {
      return 0.68; // Büyük ekranlar için daha düşük oran
    }
  }

  double _calculateGridSpacing(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    
    // Responsive grid spacing hesaplama
    if (screenWidth < 360) {
      return 6.0; // Küçük ekranlar için daha az spacing
    } else if (screenWidth < 400) {
      return 8.0; // Orta-küçük ekranlar
    } else {
      return 10.0; // Normal ve büyük ekranlar
    }
  }

  double _calculateHorizontalPadding(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    
    // Responsive horizontal padding hesaplama
    if (screenWidth < 360) {
      return 12.0; // Küçük ekranlar için daha az padding
    } else if (screenWidth < 400) {
      return 16.0; // Orta-küçük ekranlar
    } else {
      return 20.0; // Normal ve büyük ekranlar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Consumer3<UserViewModel, ProductViewModel, UserProfileDetailViewModel>(
        builder: (context, userVm, productVm, profileDetailVm, child) {
          if (userVm.isLoading || userVm.currentUser == null) {
            return const LoadingWidget();
          }

          final user = userVm.currentUser!;
          final productCount = productVm.myProducts.length;
          final favoriteCount = productVm.favoriteProducts.length;
          String score = '0';
          if (profileDetailVm.hasData && profileDetailVm.profileDetail != null) {
            score = profileDetailVm.profileDetail!.averageRating.toStringAsFixed(1);
          }

          Logger.debug('👤 ProfileView - User: ${user.name} (ID: ${user.id})');
          Logger.debug('👤 ProfileView - User isVerified: ${user.isVerified}');
          Logger.debug('👤 ProfileView - Product count: $productCount, Favorite count: $favoriteCount, Score: $score');

          return ScrollConfiguration(
            behavior: const _NoStretchScrollBehavior(),
            child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: _buildProfileHeader(context, user, productCount, favoriteCount, score),
                ),
              ),
              SliverAppBar(
                backgroundColor: Colors.white,
                pinned: true,
                primary: false,
                automaticallyImplyLeading: false,
                toolbarHeight: 0,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(74),
                  child: Container
                  (
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.center,
                      labelColor: AppTheme.primary,
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: AppTheme.primary,
                      indicatorWeight: 2,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.inventory_2_outlined, size: 20),
                          text: 'İlanlarım',
                        ),
                        Tab(
                          icon: Icon(Icons.rate_review_outlined, size: 20),
                          text: 'Yorumlar',
                        ),
                          Tab(
                            icon: Icon(Icons.rate_review, size: 20),
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 2),
                              child: Text(
                                'Puanlarım',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(user),
                _buildReviewsTab(),
                _buildMyReviewsTab(),
              ],
            ),
          ));
        },
      ),
    );
  }


  Widget _buildProductsTab(User user) {
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
              title: 'Henüz İlan Eklenmemiş',
              subtitle: 'İlk ilanınızı ekleyerek takasa başlayabilirsiniz.',
              actionButton: Container(
                height: 40,
                color: AppTheme.primary,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/add-product');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: const Text(
                    'İlan Ekle',
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
          margin: EdgeInsets.symmetric(horizontal: _calculateHorizontalPadding(context)),
          padding: const EdgeInsets.all(5),
          color: Colors.white,
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: _calculateGridSpacing(context),
              mainAxisSpacing: _calculateGridSpacing(context),
              childAspectRatio: _calculateChildAspectRatio(context),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailView(productId: product.id),
                        ),
                      );
                    },
                  ),
                    // İlanı Güncelle butonu (sol üst)
                    Positioned(
                      top: 7,
                      left: 7,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
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
                    ),
                    // İlanı Sil butonu (sağ üst)
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
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
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    return Consumer<UserProfileDetailViewModel>(
      builder: (context, profileDetailVm, child) {
        if (profileDetailVm.isLoading) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(40.0),
            color: Colors.white,
            child: const Center(child: LoadingWidget()),
          );
        }

        if (profileDetailVm.hasError) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(40.0),
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Değerlendirmeler yüklenemedi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    if (!mounted) return;
                    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
                    final userId = userViewModel.currentUser?.id;
                    if (userId != null) {
                      _loadUserProfileDetail(int.parse(userId));
                    }
                  },
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }

        if (!profileDetailVm.hasData || profileDetailVm.profileDetail == null) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(40.0),
            color: Colors.white,
            child: _buildEmptyTab(
              icon: Icons.rate_review_outlined,
              title: 'Henüz Değerlendirme Yok',
              subtitle: 'Henüz hiç değerlendirme almamışsınız.',
            ),
          );
        }

        final profile = profileDetailVm.profileDetail!;
        
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Ortalama puan ve toplam yorum sayısı
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildReviewStatItem(
                      icon: Icons.star,
                      value: profile.averageRating.toStringAsFixed(1),
                      label: 'Ortalama Puan',
                      color: Colors.amber,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey[300],
                    ),
                    _buildReviewStatItem(
                      icon: Icons.rate_review,
                      value: profile.totalReviews.toString(),
                      label: 'Toplam Yorum',
                      color: AppTheme.primary,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Yorumlar listesi
              if (profile.reviews.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.white,
                  child: Column(
                    children: profile.reviews.map((review) => _buildReviewItem(review)).toList(),
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(40.0),
                  color: Colors.white,
                  child: _buildEmptyTab(
                    icon: Icons.rate_review_outlined,
                    title: 'Henüz Yorum Yok',
                    subtitle: 'Henüz hiç yorum almamışsınız.',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 26,
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildReviewItem(dynamic review) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Yorum yapan kişinin fotoğrafı
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: review.reviewerImage != null && review.reviewerImage!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Image.network(
                          review.reviewerImage!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.grey,
                                size: 20,
                              ),
                            );
                          },
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              
              // Yorum yapan kişinin adı ve tarih
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      review.reviewDate,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Yıldızlar
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    size: 18,
                    color: index < review.rating ? Colors.amber : Colors.grey,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Yorum metni
          if (review.comment.isNotEmpty)
            Text(
              review.comment,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMyReviewsTab() {
    return Consumer2<UserViewModel, UserProfileDetailViewModel>(
      builder: (context, userVm, profileDetailVm, child) {
        // Debug logları ekle
        Logger.debug('👤 ProfileView - _buildMyReviewsTab - State: isLoading=${profileDetailVm.isLoading}, hasError=${profileDetailVm.hasError}, hasData=${profileDetailVm.hasData}');
        
        // Önce User modelindeki myReviews'i kontrol et
        final user = userVm.currentUser;
        if (user != null && user.myReviews.isNotEmpty) {
          Logger.debug('👤 ProfileView - _buildMyReviewsTab - Found myReviews in User model: ${user.myReviews.length}');
          return _buildMyReviewsContent(user.myReviews, 'User Model');
        }
        
        // Eğer User modelinde yoksa UserProfileDetailViewModel'i kullan
        if (profileDetailVm.isLoading) {
          Logger.debug('👤 ProfileView - _buildMyReviewsTab - Loading state');
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(40.0),
            color: Colors.white,
            child: const Center(child: LoadingWidget()),
          );
        }

        if (profileDetailVm.hasError) {
          Logger.debug('👤 ProfileView - _buildMyReviewsTab - Error state: ${profileDetailVm.errorMessage}');
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(40.0),
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Değerlendirmeleriniz yüklenemedi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    if (!mounted) return;
                    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
                    final userId = userViewModel.currentUser?.id;
                    if (userId != null) {
                      _loadUserProfileDetail(int.parse(userId));
                    }
                  },
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }

        if (!profileDetailVm.hasData || profileDetailVm.profileDetail == null) {
          Logger.debug('👤 ProfileView - _buildMyReviewsTab - No data available');
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(40.0),
            color: Colors.white,
            child: _buildEmptyTab(
              icon: Icons.rate_review_outlined,
              title: 'Henüz Değerlendirme Yapmamışsınız',
              subtitle: 'Henüz hiç değerlendirme yapmamışsınız.',
            ),
          );
        }

        final profile = profileDetailVm.profileDetail!;
        
        // Profile detaylarını logla
        Logger.debug('👤 ProfileView - _buildMyReviewsTab - Profile loaded');
        Logger.debug('👤 ProfileView - _buildMyReviewsTab - User: ${profile.userFullname} (ID: ${profile.userID})');
        Logger.debug('👤 ProfileView - _buildMyReviewsTab - MyReviews count: ${profile.myReviews.length}');
        Logger.debug('👤 ProfileView - _buildMyReviewsTab - Reviews count: ${profile.reviews.length}');
        Logger.debug('👤 ProfileView - _buildMyReviewsTab - Products count: ${profile.products.length}');
        
        // MyReviews detaylarını logla
        for (int i = 0; i < profile.myReviews.length; i++) {
          final review = profile.myReviews[i];
          Logger.debug('👤 ProfileView - _buildMyReviewsTab - MyReview $i: ID=${review.reviewID}, Rating=${review.rating}, Comment="${review.comment}"');
        }
        
        return _buildMyReviewsContent(profile.myReviews, 'Profile Detail');
      },
    );
  }

  Widget _buildMyReviewsContent(List<dynamic> myReviews, String source) {
    Logger.debug('👤 ProfileView - _buildMyReviewsContent - Building content from $source with ${myReviews.length} reviews');
    
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Değerlendirme sayısı
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildReviewStatItem(
                  icon: Icons.rate_review,
                  value: myReviews.length.toString(),
                  label: 'Yaptığınız Değerlendirme',
                  color: AppTheme.primary,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Değerlendirmeler listesi
          if (myReviews.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: Colors.white,
              child: Column(
                children: myReviews.map((review) => _buildReviewItem(review)).toList(),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(40.0),
              color: Colors.white,
              child: _buildEmptyTab(
                icon: Icons.rate_review_outlined,
                title: 'Henüz Değerlendirme Yapmamışsınız',
                subtitle: 'Henüz hiç değerlendirme yapmamışsınız.',
              ),
            ),
        ],
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
          onPressed: () async {
            // Tüm profil verilerini yenile
            Logger.info('🔄 ProfileView - Manually refreshing all profile data...');
            await _loadProfileData();
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profil verileri yenilendi'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          icon: const Icon(Icons.refresh, size: 24),
          tooltip: 'Verileri Yenile',
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsView(),
              ),
            );
          },
          icon: const Icon(Icons.settings_outlined, size: 24),
          tooltip: 'Ayarlar',
        ),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context, User user, int productCount, int favoriteCount, String score) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst kısım - Avatar ve Kullanıcı Bilgileri
          Row(
            children: [
              // Avatar - Köşeli tasarım
              Container(
                width: 72,
                height: 72,
                child: user.avatar != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Image.network(
                        user.avatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Center(
                              child: Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                    : Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Center(
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
              ),
              
              const SizedBox(width: 32),
              
              // Kullanıcı Bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kullanıcı Adı ve Doğrulama Durumu
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isVerified) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.verified,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                        ] else ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _navigateToEmailVerification(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    user.isVerified 
                                      ? Icons.verified_outlined
                                      : Icons.warning_amber_outlined,
                                    size: 14,
                                    color: user.isVerified 
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    user.isVerified 
                                      ? 'Doğrulandı'
                                      : 'Doğrulanmamış',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: user.isVerified 
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                        PhoneFormatter.formatPhoneNumber(user.phone!),
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // İstatistikler - Kurumsal tasarım
          Row(
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
                count: score,
                label: 'Puan',
              ),
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
                      if (!mounted) return;
                      
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
                      Navigator.pushNamed(context, '/add-product');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: const Text(
                      'İlan Ekle',
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
    if (!mounted) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductView(product: product),
      ),
    );

    // Eğer ürün güncellendiyse tüm profil verilerini yenile
    if (result == true && mounted) {
      await _loadProfileData();
    }
  }

  void _showDeleteConfirmDialog(Product product) {
    if (!mounted) return;
    
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
    if (!mounted) return;
    
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
        // Başarılı silme işleminden sonra profil verilerini yenile
        await _loadProfileData();
        
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



  void _navigateToEmailVerification() async {
    if (!mounted) return;
    
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    // Önce UserViewModel'den user'ı al
    User? user = userViewModel.currentUser;
    
    // Eğer UserViewModel'de user yoksa AuthViewModel'den al
    if (user == null) {
      Logger.warning('⚠️ ProfileView: User not found in UserViewModel, trying AuthViewModel...');
      user = authViewModel.currentUser;
    }
    
    if (user == null) {
      Logger.error('❌ ProfileView: User is null in both ViewModels, cannot proceed with email verification');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı bilgileri bulunamadı. Lütfen tekrar giriş yapın.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    
    Logger.info('📧 ProfileView: Starting email verification for user: ${user.email}');
    Logger.debug('📧 ProfileView: User details - ID: ${user.id}, Name: ${user.name}, Email: ${user.email}');
    Logger.debug('📧 ProfileView: User token: ${user.token?.substring(0, 10)}...');
    Logger.debug('📧 ProfileView: User token length: ${user.token?.length}');
    Logger.debug('📧 ProfileView: User token is null: ${user.token == null}');
    Logger.debug('📧 ProfileView: User token is empty: ${user.token?.isEmpty}');
    
    // Token validation
    if (user.token == null || user.token!.trim().isEmpty) {
      Logger.error('❌ ProfileView: User token is empty');
      
      // Token'ı UserService'den almaya çalış
      final userService = UserService();
      final tokenFromService = await userService.getUserToken();
      Logger.debug('📧 ProfileView: Token from UserService: ${tokenFromService?.substring(0, 10)}...');
      
      if (tokenFromService != null && tokenFromService.isNotEmpty) {
        Logger.info('📧 ProfileView: Using token from UserService');
        // UserService'den alınan token ile devam et
        await _sendEmailVerificationWithToken(tokenFromService);
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı token\'ı bulunamadı. Lütfen tekrar giriş yapın.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Loading dialog göster
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
            const Text('E-posta gönderiliyor...'),
          ],
        ),
      ),
    );

    try {
      print('📧 ProfileView: Sending email verification code with token');
      
      // Önce e-posta doğrulama kodunu gönder (userToken ile)
      final response = await authViewModel.resendEmailVerificationCodeWithToken(
        userToken: user.token ?? '',
      );
      
      Logger.debug('📧 ProfileView: Email verification response received');
      Logger.debug('📧 ProfileView: Response is null: ${response == null}');
      if (response != null) {
        Logger.debug('📧 ProfileView: Response keys: ${response.keys.toList()}');
        Logger.debug('📧 ProfileView: Response contains codeToken: ${response.containsKey('codeToken')}');
      }

      // Loading dialog'u kapat
      if (mounted) Navigator.pop(context);

      if (response != null) {
        // Başarılı mesajı göster
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Doğrulama kodu e-posta adresinize gönderildi'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // API'den gelen codeToken'ı al veya geçici değer kullan
        String codeToken = 'temp_code_token';
        if (response.containsKey('codeToken') && response['codeToken'] != null) {
          codeToken = response['codeToken'].toString();
        }

        // E-posta doğrulama sayfasına yönlendir
        if (mounted) {
          Navigator.pushNamed(
            context,
            '/email-verification',
            arguments: {
              'email': user.email,
              'codeToken': codeToken,
            },
          );
        }
      } else {
        // Token hatası varsa login sayfasına yönlendir
        if (authViewModel.errorMessage?.contains('oturum') == true || 
            authViewModel.errorMessage?.contains('token') == true ||
            authViewModel.errorMessage?.contains('giriş') == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            
            // Login sayfasına yönlendir
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          }
        } else {
          // Diğer hatalar için e-posta doğrulama sayfasına yönlendir
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authViewModel.errorMessage ?? 'E-posta gönderilemedi'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
            
            // E-posta doğrulama sayfasına yönlendir (hata olsa bile)
            Navigator.pushNamed(
              context,
              '/email-verification',
              arguments: {
                'email': user.email,
                'codeToken': 'temp_code_token',
              },
            );
          }
        }
      }
    } catch (e) {
      // Loading dialog'u kapat
      if (mounted) Navigator.pop(context);

      // Hata mesajı göster ve e-posta doğrulama sayfasına yönlendir
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('E-posta gönderilirken hata oluştu: $e'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // E-posta doğrulama sayfasına yönlendir
        Navigator.pushNamed(
          context,
          '/email-verification',
          arguments: {
            'email': user.email,
            'codeToken': 'temp_code_token',
          },
        );
      }
    }
  }

  Future<void> _sendEmailVerificationWithToken(String userToken) async {
    if (!mounted) return;
    
    // Loading dialog göster
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
            const Text('E-posta gönderiliyor...'),
          ],
        ),
      ),
    );

    try {
      Logger.debug('📧 ProfileView: Sending email verification code with token');
      
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      
      // E-posta doğrulama kodunu gönder (userToken ile)
      final response = await authViewModel.resendEmailVerificationCodeWithToken(
        userToken: userToken,
      );
      
      Logger.debug('📧 ProfileView: Email verification response received');
      Logger.debug('📧 ProfileView: Response is null: ${response == null}');
      if (response != null) {
        Logger.debug('📧 ProfileView: Response keys: ${response.keys.toList()}');
        Logger.debug('📧 ProfileView: Response contains codeToken: ${response.containsKey('codeToken')}');
      }

      // Loading dialog'u kapat
      if (mounted) Navigator.pop(context);

      if (response != null) {
        // Başarılı mesajı göster
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Doğrulama kodu e-posta adresinize gönderildi'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // API'den gelen codeToken'ı al veya geçici değer kullan
        String codeToken = 'temp_code_token';
        if (response.containsKey('codeToken') && response['codeToken'] != null) {
          codeToken = response['codeToken'].toString();
        }

        // E-posta doğrulama sayfasına yönlendir
        if (mounted) {
          Navigator.pushNamed(
            context,
            '/email-verification',
            arguments: {
              'email': authViewModel.currentUser?.email ?? '',
              'codeToken': codeToken,
            },
          );
        }
      } else {
        // Token hatası varsa login sayfasına yönlendir
        if (authViewModel.errorMessage?.contains('oturum') == true || 
            authViewModel.errorMessage?.contains('token') == true ||
            authViewModel.errorMessage?.contains('giriş') == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            
            // Login sayfasına yönlendir
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          }
        } else {
          // Diğer hatalar için e-posta doğrulama sayfasına yönlendir
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authViewModel.errorMessage ?? 'E-posta gönderilemedi'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
            
            // E-posta doğrulama sayfasına yönlendir (hata olsa bile)
            Navigator.pushNamed(
              context,
              '/email-verification',
              arguments: {
                'email': authViewModel.currentUser?.email ?? '',
                'codeToken': 'temp_code_token',
              },
            );
          }
        }
      }
    } catch (e) {
      // Loading dialog'u kapat
      if (mounted) Navigator.pop(context);

      // Hata mesajı göster ve e-posta doğrulama sayfasına yönlendir
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('E-posta gönderilirken hata oluştu: $e'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // E-posta doğrulama sayfasına yönlendir
        Navigator.pushNamed(
          context,
          '/email-verification',
          arguments: {
            'email': Provider.of<AuthViewModel>(context, listen: false).currentUser?.email ?? '',
            'codeToken': 'temp_code_token',
          },
        );
      }
    }
  }


}

class _NoStretchScrollBehavior extends ScrollBehavior {
  const _NoStretchScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (notification) {
        notification.disallowIndicator();
        return false;
      },
      child: child,
    );
  }
}
