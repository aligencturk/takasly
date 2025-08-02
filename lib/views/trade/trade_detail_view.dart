import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/trade_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/trade_detail.dart';
import '../../services/auth_service.dart';
import '../../core/app_theme.dart';
import '../../utils/logger.dart';

class TradeDetailView extends StatefulWidget {
  final int offerID;
  
  const TradeDetailView({
    super.key,
    required this.offerID,
  });

  @override
  State<TradeDetailView> createState() => _TradeDetailViewState();
}

class _TradeDetailViewState extends State<TradeDetailView> {
  @override
  void initState() {
    super.initState();
    Logger.info('🚀 TradeDetailView.initState() - Takas detayı başlatılıyor, OfferID: ${widget.offerID}', tag: 'TradeDetailView');
    _loadTradeDetail();
  }

  Future<void> _loadTradeDetail() async {
    final tradeViewModel = Provider.of<TradeViewModel>(context, listen: false);
    
    // AuthService'i direkt kullan
    final authService = AuthService();
    final userToken = await authService.getToken();
    if (userToken == null) {
      Logger.error('❌ User token bulunamadı', tag: 'TradeDetailView');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Kullanıcı oturumu bulunamadı'),
            backgroundColor: AppTheme.error,
          ),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    Logger.info('🔍 Takas detayı yükleniyor... OfferID: ${widget.offerID}', tag: 'TradeDetailView');
    
    final success = await tradeViewModel.getTradeDetail(
      userToken: userToken,
      offerID: widget.offerID,
    );

    if (!success && mounted) {
      Logger.error('❌ Takas detayı yüklenemedi', tag: 'TradeDetailView');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tradeViewModel.tradeDetailErrorMessage ?? 'Takas detayı yüklenemedi'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Consumer<TradeViewModel>(
        builder: (context, tradeViewModel, child) {
          if (tradeViewModel.isLoadingTradeDetail) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primary,
              ),
            );
          }

          if (tradeViewModel.hasTradeDetailError) {
            return _buildErrorWidget(tradeViewModel);
          }

          final tradeDetail = tradeViewModel.selectedTradeDetail;
          if (tradeDetail == null) {
            return _buildErrorWidget(tradeViewModel);
          }

          return _buildTradeDetailContent(tradeDetail);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Takas Detayı',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      centerTitle: true,
    );
  }

  Widget _buildErrorWidget(TradeViewModel tradeViewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Takas detayı yüklenemedi',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tradeViewModel.tradeDetailErrorMessage ?? 'Bilinmeyen hata',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadTradeDetail,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeDetailContent(TradeDetail tradeDetail) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Takas Durumu Kartı
          _buildStatusCard(tradeDetail),
          
          const SizedBox(height: 16),
          
          // Teslimat Bilgileri
          _buildDeliveryCard(tradeDetail),
          
          const SizedBox(height: 16),
          
          // Gönderen Kullanıcı ve Ürünü
          _buildParticipantCard(
            'Gönderen',
            tradeDetail.sender,
            Colors.blue,
          ),
          
          const SizedBox(height: 16),
          
          // Alıcı Kullanıcı ve Ürünü
          _buildParticipantCard(
            'Alıcı',
            tradeDetail.receiver,
            Colors.green,
          ),
          
          const SizedBox(height: 16),
          
          // Takas Tarihleri
          _buildDatesCard(tradeDetail),
        ],
      ),
    );
  }

  Widget _buildStatusCard(TradeDetail tradeDetail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.swap_horiz,
                color: AppTheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Takas Durumu',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(tradeDetail.statusID).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getStatusColor(tradeDetail.statusID),
                width: 1,
              ),
            ),
            child: Text(
              tradeDetail.statusTitle,
              style: TextStyle(
                color: _getStatusColor(tradeDetail.statusID),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(TradeDetail tradeDetail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                color: AppTheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Teslimat Bilgileri',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Teslimat Türü', tradeDetail.deliveryTypeTitle),
          if (tradeDetail.meetingLocation.isNotEmpty)
            _buildInfoRow('Buluşma Yeri', tradeDetail.meetingLocation),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(String title, TradeParticipant participant, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Kullanıcı Bilgileri
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(participant.profilePhoto),
                onBackgroundImageError: (exception, stackTrace) {
                  Logger.error('❌ Profil fotoğrafı yüklenemedi: $exception', tag: 'TradeDetailView');
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participant.userName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'ID: ${participant.userID}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Ürün Bilgileri
          _buildProductCard(participant.product),
        ],
      ),
    );
  }

  Widget _buildProductCard(TradeProduct product) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.productImage,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    Logger.error('❌ Ürün fotoğrafı yüklenemedi: $error', tag: 'TradeDetailView');
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.productCondition,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          if (product.productDesc.isNotEmpty) ...[
            Text(
              product.productDesc,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],
          
          // Kategori Listesi
          if (product.categoryList.isNotEmpty) ...[
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: product.categoryList.map((category) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    category.catName,
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
          
          // Konum Bilgisi
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${product.districtTitle}, ${product.cityTitle}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatesCard(TradeDetail tradeDetail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule_outlined,
                color: AppTheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Takas Tarihleri',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Oluşturulma', tradeDetail.createdAt),
          if (tradeDetail.completedAt.isNotEmpty)
            _buildInfoRow('Tamamlanma', tradeDetail.completedAt),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(int statusID) {
    switch (statusID) {
      case 1: // Beklemede
        return Colors.orange;
      case 2: // Takas Başlatıldı
        return Colors.blue;
      case 3: // Tamamlandı
        return Colors.green;
      case 4: // İptal Edildi
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
} 