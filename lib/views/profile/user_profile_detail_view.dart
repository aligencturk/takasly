import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/user_profile_detail_viewmodel.dart';
import '../../core/app_theme.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart' as custom_error;
import '../../models/user_profile_detail.dart';

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

class _UserProfileDetailViewState extends State<UserProfileDetailView> {
  late UserProfileDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = UserProfileDetailViewModel();
    _viewModel.setUserToken(widget.userToken);
    _loadProfileDetail();
  }

  Future<void> _loadProfileDetail() async {
    await _viewModel.loadProfileDetail(
      userToken: widget.userToken,
      userId: widget.userId,
    );
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

            return RefreshIndicator(
              onRefresh: () => _viewModel.refreshProfileDetail(
                userToken: widget.userToken,
                userId: widget.userId,
              ),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileHeader(viewModel.profileDetail!),
                    _buildSectionHeader(viewModel.profileDetail!.products.length),
                    _buildProductsSection(viewModel.profileDetail!),
                    const SizedBox(height: 16),
                    _buildReviewsSectionHeader(viewModel.profileDetail!.reviews.length),
                    _buildReviewsSection(viewModel.profileDetail!),
                    const SizedBox(height: 32),
                  ],
                ),
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
              // Kullanıcı Adı
              Text(
                profile.userFullname,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 6),
              
              // Üyelik Süresi
              if (profile.memberSince.isNotEmpty)
                Text(
                  'Üye olalı: ${profile.memberSince}',
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
            'İlanlar',
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

  Widget _buildReviewsSectionHeader(int reviewCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      color: Colors.white,
      child: Row(
        children: [
          Icon(
            Icons.rate_review_outlined,
            color: AppTheme.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          const Text(
            'Yorumlar',
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
              '$reviewCount yorum',
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

  Widget _buildProductsSection(UserProfileDetail profile) {
    if (profile.products.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(40.0),
        color: Colors.white,
        child: _buildEmptyTab(
          icon: Icons.inventory_2_outlined,
          title: 'Henüz Ürün Eklenmemiş',
          subtitle: 'Bu kullanıcının henüz ürünü bulunmuyor.',
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: product.mainImage != null && product.mainImage!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      child: Image.network(
                        product.mainImage!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
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
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
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
    );
  }

  Widget _buildReviewsSection(UserProfileDetail profile) {
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

    return Container(
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

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
} 