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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Takas Durumu Kartı
          _buildStatusCard(tradeDetail),
          
          const SizedBox(height: 12),
          
          // Teslimat Bilgileri
          _buildDeliveryCard(tradeDetail),
          
          const SizedBox(height: 12),
          
          // Gönderen Kullanıcı ve Ürünü
          _buildParticipantCard(
            'Gönderen',
            tradeDetail.sender,
            Colors.blue,
          ),
          
          const SizedBox(height: 12),
          
          // Alıcı Kullanıcı ve Ürünü
          _buildParticipantCard(
            'Alıcı',
            tradeDetail.receiver,
            Colors.green,
          ),
          
          const SizedBox(height: 12),
          
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
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.zero,
                ),
                child: Icon(
                  Icons.swap_horiz,
                  color: AppTheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'TAKAS DURUMU',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(tradeDetail.statusID).withOpacity(0.1),
              borderRadius: BorderRadius.zero,
              border: Border.all(
                color: _getStatusColor(tradeDetail.statusID),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(tradeDetail.statusID),
                  color: _getStatusColor(tradeDetail.statusID),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  tradeDetail.statusTitle,
                  style: TextStyle(
                    color: _getStatusColor(tradeDetail.statusID),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
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
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.zero,
                ),
                child: Icon(
                  Icons.local_shipping_outlined,
                  color: AppTheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'TESLİMAT BİLGİLERİ',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.5,
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
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.zero,
                ),
                child: Icon(
                  Icons.person_outline,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Kullanıcı Bilgileri
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(participant.profilePhoto),
                onBackgroundImageError: (exception, stackTrace) {
                  Logger.error('❌ Profil fotoğrafı yüklenemedi: $exception', tag: 'TradeDetailView');
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participant.userName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'ID: ${participant.userID}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
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
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  product.productImage,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    Logger.error('❌ Ürün fotoğrafı yüklenemedi: $error', tag: 'TradeDetailView');
                    return Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.productCondition,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 6),
          
          if (product.productDesc.isNotEmpty) ...[
            Text(
              product.productDesc,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
          ],
          
          // Kategori Listesi
          if (product.categoryList.isNotEmpty) ...[
            Wrap(
              spacing: 3,
              runSpacing: 3,
              children: product.categoryList.map((category) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    category.catName,
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
          ],
          
          // Konum Bilgisi
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  '${product.districtTitle}, ${product.cityTitle}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 11,
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
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.zero,
                ),
                child: Icon(
                  Icons.schedule_outlined,
                  color: AppTheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'TAKAS TARİHLERİ',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.5,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Colors.black87,
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

  IconData _getStatusIcon(int statusID) {
    switch (statusID) {
      case 1: // Beklemede
        return Icons.pending;
      case 2: // Takas Başlatıldı
        return Icons.swap_horiz;
      case 3: // Tamamlandı
        return Icons.check_circle;
      case 4: // İptal Edildi
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
} 