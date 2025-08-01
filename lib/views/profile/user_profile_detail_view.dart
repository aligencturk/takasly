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
        appBar: AppBar(
          title: const Text('Kullanıcı Profili'),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
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
                    const SizedBox(height: 16),
                    _buildStatsSection(viewModel.profileDetail!),
                    const SizedBox(height: 16),
                    _buildProductsSection(viewModel.profileDetail!),
                    const SizedBox(height: 16),
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
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: AppTheme.primary,
      child: Column(
        children: [
          // Profil Fotoğrafı - Köşeli tasarım
          Container(
            width: 80,
            height: 80,
            color: Colors.white,
            child: profile.userImage != null && profile.userImage!.isNotEmpty
                ? Image.network(
                    profile.userImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[100],
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey,
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey[100],
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          
          // Kullanıcı Adı
          Text(
            profile.userFullname,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Üyelik Süresi
          if (profile.memberSince.isNotEmpty)
            Text(
              'Üye olalı: ${profile.memberSince}',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(UserProfileDetail profile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.star,
              value: profile.averageRating.toStringAsFixed(1),
              label: 'Ortalama Puan',
              color: Colors.amber,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.rate_review,
              value: profile.totalReviews.toString(),
              label: 'Toplam Yorum',
              color: AppTheme.primary,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.inventory,
              value: profile.products.length.toString(),
              label: 'Ürün Sayısı',
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
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

  Widget _buildProductsSection(UserProfileDetail profile) {
    if (profile.products.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(32),
        color: Colors.white,
        child: const Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Henüz ürün yok',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(
                  Icons.inventory,
                  color: AppTheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Ürünler (${profile.products.length})',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: Colors.grey[200],
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: profile.products.length,
            itemBuilder: (context, index) {
              final product = profile.products[index];
              return _buildProductItem(product);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(ProfileProduct product) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Ürün resmi - Köşeli tasarım
          Container(
            width: 60,
            height: 60,
            color: Colors.grey[100],
            child: product.mainImage != null && product.mainImage!.isNotEmpty
                ? Image.network(
                    product.mainImage!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[100],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      );
                    },
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[100],
                    child: const Icon(
                      Icons.inventory_2,
                      color: Colors.grey,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          
          // Ürün bilgileri
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ürün ID: ${product.productID}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          
          // Favori ikonu
          if (product.isFavorite)
            const Icon(
              Icons.favorite,
              color: Colors.red,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(UserProfileDetail profile) {
    if (profile.reviews.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(32),
        color: Colors.white,
        child: const Column(
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Henüz yorum yok',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(
                  Icons.rate_review,
                  color: AppTheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Yorumlar (${profile.reviews.length})',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: Colors.grey[200],
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: profile.reviews.length,
            itemBuilder: (context, index) {
              final review = profile.reviews[index];
              return _buildReviewItem(review);
            },
          ),
        ],
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
              // Yorum yapan kişinin fotoğrafı - Köşeli tasarım
              Container(
                width: 40,
                height: 40,
                color: Colors.grey[100],
                child: review.reviewerImage != null && review.reviewerImage!.isNotEmpty
                    ? Image.network(
                        review.reviewerImage!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey[100],
                            child: const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 20,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        color: Colors.grey[100],
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

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
} 