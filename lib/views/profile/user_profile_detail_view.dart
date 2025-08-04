import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/user_profile_detail_viewmodel.dart';
import '../../viewmodels/report_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/app_theme.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart' as custom_error;
import '../../models/user_profile_detail.dart';
import '../../widgets/report_dialog.dart';
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
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          title: const Text(
            'Kullanıcı Profili',
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
        body: Consumer<UserProfileDetailViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const LoadingWidget();
            }

            if (viewModel.hasError) {
              return custom_error.CustomErrorWidget(
                message: viewModel.errorMessage,
                onRetry: _loadProfileDetail,
              );
            }

            if (!viewModel.hasData) {
              return const Center(
                child: Text('Profil bilgisi bulunamadı'),
              );
            }

            final profile = viewModel.profileDetail!;
            
            return RefreshIndicator(
              onRefresh: () => _viewModel.refreshProfileDetail(
                userToken: widget.userToken,
                userId: widget.userId,
              ),
              child: Column(
                children: [
                  _buildProfileHeader(profile),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.white,
                    child: _tabController != null ? TabBar(
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
                    ) : const SizedBox.shrink(),
                  ),
                  Expanded(
                    child: _tabController != null ? TabBarView(
                      controller: _tabController!,
                      children: [
                        _buildProductsTab(profile),
                        _buildReviewsTab(profile),
                      ],
                    ) : const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          },
        ),
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
                  color: Colors.grey[100],
                ),
                child: profile.userImage != null && profile.userImage!.isNotEmpty
                    ? Image.network(
                        profile.userImage!,
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
                      profile.userFullname,
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
                               'Doğrulanmamış',
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
        itemCount: profile.products.length,
        itemBuilder: (context, index) {
          final product = profile.products[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(ProfileProduct product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailView(productId: product.productID.toString()),
          ),
        );
      },
                           child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[200]!),
          ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ürün resmi
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                ),
                child: product.mainImage != null && product.mainImage!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.zero,
                        child: Image.network(
                          product.mainImage!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                              ),
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                        ),
                        child: const Icon(
                          Icons.inventory_2,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            
            // Ürün bilgileri
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${product.productID}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (product.isFavorite) ...[
                      const SizedBox(height: 4),
                      const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: review.reviewerImage != null && review.reviewerImage!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
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
} 