import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/user_profile_detail_viewmodel.dart';
import '../../viewmodels/report_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/app_theme.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart' as custom_error;
import '../../models/user_profile_detail.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../widgets/report_dialog.dart';
import '../../widgets/product_card.dart';
import '../../views/product/product_detail_view.dart';
import '../../utils/logger.dart';

class UserProfileDetailView extends StatefulWidget {
  final int userId;
  final String userToken;

  const UserProfileDetailView({
    Key? key,
    required this.userId,
    required this.userToken,
  }) : super(key: key);

  @override
  State<UserProfileDetailView> createState() => _UserProfileDetailViewState();
}

class _UserProfileDetailViewState extends State<UserProfileDetailView>
    with SingleTickerProviderStateMixin {
  late UserProfileDetailViewModel _viewModel;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    Logger.info('UserProfileDetailView initialized for userId: ${widget.userId}', tag: 'UserProfileDetailView');
    _viewModel = UserProfileDetailViewModel();
    _tabController = TabController(length: 2, vsync: this);
    _viewModel.setUserToken(widget.userToken);
    _loadProfileDetail();
  }

  Future<void> _loadProfileDetail() async {
    Logger.debug('Loading profile detail for userId: ${widget.userId}', tag: 'UserProfileDetailView');
    await _viewModel.loadProfileDetail(
      userToken: widget.userToken,
      userId: widget.userId,
    );
    
    // Debug: Profil detaylarını logla
    if (_viewModel.profileDetail != null) {
      Logger.debug('Profile loaded - userFullname: ${_viewModel.profileDetail!.userFullname}', tag: 'UserProfileDetailView');
      Logger.debug('Profile loaded - products count: ${_viewModel.profileDetail!.products.length}', tag: 'UserProfileDetailView');
      
      // İlk ürünün kategori bilgisini logla
      if (_viewModel.profileDetail!.products.isNotEmpty) {
        final firstProduct = _viewModel.profileDetail!.products.first;
        Logger.debug('First product - categoryId: ${firstProduct.categoryId}, categoryName: ${firstProduct.categoryName}', tag: 'UserProfileDetailView');
      }
    }
  }

  void _showReportDialog() {
    final authViewModel = context.read<AuthViewModel>();
    
    // Kullanıcı kendini şikayet etmeye çalışıyorsa uyarı göster
    if (authViewModel.currentUser?.id == widget.userId.toString()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kendinizi şikayet edemezsiniz'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        reportedUserID: widget.userId,
        reportedUserName: _viewModel.profileDetail?.userFullname ?? 'Bilinmeyen Kullanıcı',
      ),
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<UserProfileDetailViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              title: Text(
                viewModel.profileDetail?.userFullname?.isNotEmpty == true 
                    ? viewModel.profileDetail!.userFullname 
                    : 'Kullanıcı',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              actions: [
                // Şikayet butonu
                IconButton(
                  icon: const Icon(Icons.report_problem_outlined),
                  onPressed: () => _showReportDialog(),
                  tooltip: 'Kullanıcıyı Şikayet Et',
                ),
              ],
            ),
            body: viewModel.isLoading
                ? const LoadingWidget()
                : viewModel.hasError
                    ? custom_error.CustomErrorWidget(
                        message: viewModel.errorMessage,
                        onRetry: _loadProfileDetail,
                      )
                    : !viewModel.hasData
                        ? const Center(
                            child: Text('Profil bilgisi bulunamadı'),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _viewModel.refreshProfileDetail(
                              userToken: widget.userToken,
                              userId: widget.userId,
                            ),
                            child: Column(
                              children: [
                                _buildProfileHeader(viewModel.profileDetail!),
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 20),
                                  color: Colors.white,
                                  child: _tabController != null
                                      ? TabBar(
                                          controller: _tabController!,
                                          labelColor: AppTheme.primary,
                                          unselectedLabelColor: Colors.grey[600],
                                          indicatorColor: AppTheme.primary,
                                          indicatorWeight: 2,
                                          tabs: const [
                                            Tab(
                                              icon: Icon(Icons.inventory_2_outlined, size: 20),
                                              text: 'İlanlar',
                                            ),
                                            Tab(
                                              icon: Icon(Icons.rate_review_outlined, size: 20),
                                              text: 'Yorumlar',
                                            ),
                                          ],
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                Expanded(
                                  child: _tabController != null
                                      ? TabBarView(
                                          controller: _tabController!,
                                          children: [
                                            _buildProductsTab(viewModel.profileDetail!),
                                            _buildReviewsTab(viewModel.profileDetail!),
                                          ],
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserProfileDetail profile) {
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
                  borderRadius: BorderRadius.circular(100),
                  color: Colors.grey[100],
                ),
                child: profile.userImage != null && profile.userImage!.isNotEmpty
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Image.network(
                        profile.userImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildAvatarPlaceholder(profile.userFullname);
                        },
                        ),
                      )
                    : _buildAvatarPlaceholder(profile.userFullname),
              ),
              
              const SizedBox(width: 32),
              
              // İstatistikler - Kurumsal tasarım
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildKurumsalStatItem(
                      count: profile.products.length.toString(),
                      label: 'İlan',
                    ),
                    _buildKurumsalStatItem(
                      count: profile.totalReviews.toString(),
                      label: 'Yorum',
                    ),
                    _buildKurumsalStatItem(
                      count: profile.averageRating.toStringAsFixed(1),
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
              // Kullanıcı Adı ve Onay Durumu
              Row(
                children: [
                  Flexible(
                    child: Text(
                      profile.userFullname.isNotEmpty ? profile.userFullname : 'Kullanıcı',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                                     // Onay Durumu Badge'i
                   if (profile.isApproved) ...[
                     const SizedBox(width: 8),
                     Icon(
                       Icons.verified,
                       size: 18,
                       color: AppTheme.primary,
                     ),
                   ] else ...[
                     const SizedBox(width: 8),
                     GestureDetector(
                       onTap: () {
                         // Doğrulama işlemi için gerekirse buraya navigasyon eklenebilir
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(
                             content: Text('Bu kullanıcı henüz doğrulanmamış'),
                             backgroundColor: Colors.orange,
                             behavior: SnackBarBehavior.floating,
                           ),
                         );
                       },
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
                               Icons.warning_amber_outlined,
                               size: 14,
                               color: Colors.orange.shade700,
                             ),
                             const SizedBox(width: 4),
                             Text(
                               "${profile.isApproved ? ' Doğrulanmamış' : 'Doğrulanmış'}",
                               style: TextStyle(
                                 fontSize: 11,
                                 fontWeight: FontWeight.w500,
                                 color: Colors.orange.shade700,
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
              
              // Üyelik Tarihi
              if (profile.memberSince.isNotEmpty)
                Text(
                  profile.memberSince,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w400,
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

  // ProfileProduct'ı Product'a dönüştüren yardımcı fonksiyon
  Product _convertProfileProductToProduct(ProfileProduct profileProduct) {
    // Kategori ID'sini al
    String categoryId = '0';
    if (profileProduct.categoryId != null && 
        profileProduct.categoryId!.isNotEmpty && 
        profileProduct.categoryId != 'null' &&
        profileProduct.categoryId != '0') {
      categoryId = profileProduct.categoryId!;
    }
    
    // Kategori adını düzgün şekilde al
    String categoryName = 'Kategori';
    if (profileProduct.categoryName != null && 
        profileProduct.categoryName!.isNotEmpty && 
        profileProduct.categoryName != 'null' &&
        profileProduct.categoryName != 'Kategori') {
      categoryName = profileProduct.categoryName!;
    }
    
    Logger.debug('Converting product: ${profileProduct.title} - CategoryId: $categoryId - Original category: ${profileProduct.categoryName} - Final category: $categoryName', tag: 'UserProfileDetailView');
    
    // Kategori nesnesini oluştur
    final category = Category(
      id: categoryId,
      name: categoryName,
      icon: '',
      isActive: true,
      order: 0,
    );

    // Kullanıcı nesnesini oluştur
    final owner = User(
      id: '0', // ProfileProduct'ta userID yok
      name: 'Kullanıcı',
      firstName: '',
      lastName: '',
      email: '',
      isVerified: false,
      isOnline: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return Product(
      id: profileProduct.productID.toString(),
      title: profileProduct.title.isNotEmpty ? profileProduct.title : 'İsimsiz Ürün',
      description: profileProduct.description ?? '',
      images: profileProduct.mainImage != null && profileProduct.mainImage!.isNotEmpty 
          ? [profileProduct.mainImage!] 
          : [],
      categoryId: categoryId,
      catname: categoryName,
      category: category,
      condition: profileProduct.condition ?? '',
      brand: profileProduct.brand,
      model: profileProduct.model,
      estimatedValue: profileProduct.estimatedValue,
      ownerId: '0', // ProfileProduct'ta userID yok
      owner: owner,
      tradePreferences: [],
      status: ProductStatus.active,
      cityId: '0', // ProfileProduct'ta cityId yok
      cityTitle: profileProduct.cityTitle ?? '',
      districtId: '0', // ProfileProduct'ta districtId yok
      districtTitle: profileProduct.districtTitle ?? '',
      createdAt: profileProduct.createdAt ?? DateTime.now(),
      updatedAt: profileProduct.createdAt ?? DateTime.now(),
      // Yeni API alanları
      isFavorite: profileProduct.isFavorite,
      isSponsor: profileProduct.isSponsor,
      isTrade: profileProduct.isTrade,
      productCode: profileProduct.productCode,
      favoriteCount: profileProduct.favoriteCount,
    );
  }

  Widget _buildProductsTab(UserProfileDetail profile) {
    if (profile.products.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(40.0),
        color: Colors.white,
        child: _buildEmptyTab(
          icon: Icons.inventory_2_outlined,
          title: 'Henüz İlan Eklenmemiş',
          subtitle: 'Bu kullanıcının henüz ilanı bulunmuyor.',
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(5),
      color: Colors.white,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.7, // ProductCard için uygun oran
        ),
        itemCount: profile.products.length,
        itemBuilder: (context, index) {
          final profileProduct = profile.products[index];
          final product = _convertProfileProductToProduct(profileProduct);
          return ProductCard(
            product: product,
            heroTag: 'user_profile_product_${product.id}_$index',
            hideFavoriteIcon: false, // Kullanıcı profilinde favori ikonunu göster
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailView(productId: product.id),
                ),
              );
            },
          );
        },
      ),
    );
  }



  Widget _buildReviewsTab(UserProfileDetail profile) {
    if (profile.reviews.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(40.0),
        color: Colors.white,
        child: _buildEmptyTab(
          icon: Icons.rate_review_outlined,
          title: 'Henüz Yorum Yok',
          subtitle: 'Bu kullanıcı için henüz yorum yapılmamış.',
        ),
      );
    }

    return SingleChildScrollView(
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
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.white,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: profile.reviews.length,
              itemBuilder: (context, index) {
                final review = profile.reviews[index];
                return _buildReviewItem(review);
              },
            ),
          ),
        ],
      ),
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

  Widget _buildReviewItem(ProfileReview review) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Yorum yapan kişinin fotoğrafı
              Container(
                width: 50,
                height: 50,
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

  Widget _buildEmptyTab({
    required IconData icon,
    required String title,
    required String subtitle,
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
      ],
    );
  }

  Widget _buildAvatarPlaceholder(String? userName) {
    // Kullanıcı adından baş harfi al
    String initial = '';
    if (userName != null && userName.isNotEmpty) {
      initial = userName.trim().substring(0, 1).toUpperCase();
    } else {
      initial = '?';
    }

    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }



  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'yeni':
      case 'new':
        return Colors.green;
      case 'az kullanılmış':
      case 'like new':
      case 'çok az kullanılmış':
        return Colors.blue;
      case 'iyi':
      case 'good':
        return Colors.orange;
      case 'orta':
      case 'fair':
        return Colors.deepOrange;
      case 'kötü':
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
} 