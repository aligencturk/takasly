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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Profil Fotoğrafı
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            backgroundImage: profile.userImage != null && profile.userImage!.isNotEmpty
                ? NetworkImage(profile.userImage!)
                : null,
            child: profile.userImage == null || profile.userImage!.isEmpty
                ? const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.grey,
                  )
                : null,
          ),
          const SizedBox(height: 16),
          
          // Kullanıcı Adı
          Text(
            profile.userFullname,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
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
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(UserProfileDetail profile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
            color: Colors.grey.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.rate_review,
              value: profile.totalReviews.toString(),
              label: 'Toplam Yorum',
              color: Colors.blue,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.withOpacity(0.3),
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
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
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
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProductsSection(UserProfileDetail profile) {
    if (profile.products.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.inventory,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ürünler (${profile.products.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
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
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: product.mainImage != null && product.mainImage!.isNotEmpty
            ? Image.network(
                product.mainImage!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  );
                },
              )
            : Container(
                width: 50,
                height: 50,
                color: Colors.grey[300],
                child: const Icon(
                  Icons.inventory_2,
                  color: Colors.grey,
                ),
              ),
      ),
      title: Text(
        product.title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: product.isFavorite
          ? const Icon(
              Icons.favorite,
              color: Colors.red,
              size: 20,
            )
          : null,
      onTap: () {
        // Ürün detayına git
        // Navigator.push(context, MaterialPageRoute(
        //   builder: (context) => ProductDetailView(productId: product.productID),
        // ));
      },
    );
  }

  Widget _buildReviewsSection(UserProfileDetail profile) {
    if (profile.reviews.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.rate_review,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Yorumlar (${profile.reviews.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Yorum yapan kişinin fotoğrafı
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                backgroundImage: review.reviewerImage != null && review.reviewerImage!.isNotEmpty
                    ? NetworkImage(review.reviewerImage!)
                    : null,
                child: review.reviewerImage == null || review.reviewerImage!.isEmpty
                    ? const Icon(
                        Icons.person,
                        color: Colors.grey,
                      )
                    : null,
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
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      review.reviewDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
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
                    size: 16,
                    color: index < review.rating ? Colors.amber : Colors.grey,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Yorum metni
          if (review.comment.isNotEmpty)
            Text(
              review.comment,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
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