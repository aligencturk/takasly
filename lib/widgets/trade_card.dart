import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:takasly/core/app_theme.dart';
import 'package:takasly/models/trade.dart';
import 'package:takasly/viewmodels/trade_viewmodel.dart';
import 'package:takasly/services/user_service.dart';
import 'package:takasly/utils/logger.dart';

class TradeCard extends StatelessWidget {
  final UserTrade trade;
  final VoidCallback? onTap;
  final Function(int)? onStatusChange;

  const TradeCard({
    super.key,
    required this.trade,
    this.onTap,
    this.onStatusChange,
  });

  String _getStatusText(int statusId) {
    switch (statusId) {
      case 1:
        return 'Beklemede';
      case 2:
        return 'Onaylandı';
      case 3:
        return 'Reddedildi';
      case 4:
        return 'Tamamlandı';
      case 5:
        return 'İptal Edildi';
      default:
        return 'Bilinmiyor';
    }
  }

  Color _getStatusColor(int statusId) {
    switch (statusId) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.green;
      case 3:
        return Colors.red;
      case 4:
        return Colors.blue;
      case 5:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(int statusId) {
    switch (statusId) {
      case 1:
        return Icons.pending;
      case 2:
        return Icons.check_circle;
      case 3:
        return Icons.cancel;
      case 4:
        return Icons.done_all;
      case 5:
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst kısım - Ürün bilgileri
              Row(
                children: [
                  // Benim ürünüm
                  Expanded(
                    child: _buildProductInfo(
                      context,
                      trade.myProduct,
                      'Benim Ürünüm',
                      Colors.blue,
                    ),
                  ),
                  // Takas ikonu
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.swap_horiz,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  // Karşı tarafın ürünü
                  Expanded(
                    child: _buildProductInfo(
                      context,
                      trade.theirProduct,
                      'Karşı Taraf',
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Orta kısım - Takas durumu
              Row(
                children: [
                  Icon(
                    _getStatusIcon(trade.statusID),
                    color: _getStatusColor(trade.statusID),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusText(trade.statusID),
                    style: textTheme.bodyMedium?.copyWith(
                      color: _getStatusColor(trade.statusID),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Teklif #${trade.offerID}',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              // Alt kısım - Aksiyon butonları
              if (trade.statusID == 1) // Sadece bekleyen takaslar için
                _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfo(
    BuildContext context,
    TradeProduct? product,
    String label,
    Color color,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 80,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
          ),
          child: ClipRRect(
            child: product?.productImage.isNotEmpty == true
                ? CachedNetworkImage(
                    imageUrl: product!.productImage,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  )
                : Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product?.productTitle ?? 'Ürün bilgisi yok',
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _confirmTrade(context, true),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Onayla'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _confirmTrade(context, false),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Reddet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmTrade(BuildContext context, bool isConfirm) async {
    final tradeViewModel = Provider.of<TradeViewModel>(context, listen: false);
    
    Logger.info(
      'Takas onaylama işlemi başlatılıyor... OfferID: ${trade.offerID}, Onay: $isConfirm',
      tag: 'TradeCard',
    );

    String? cancelDesc;
    if (!isConfirm) {
      // Reddetme durumunda açıklama iste
      cancelDesc = await _showCancelDialog(context);
      if (cancelDesc == null) return; // Kullanıcı iptal etti
    }

    // Kullanıcı token'ını al
    final userService = UserService();
    final userToken = await userService.getUserToken();
    
    if (userToken == null || userToken.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oturum bilgisi bulunamadı. Lütfen tekrar giriş yapın.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final success = await tradeViewModel.confirmTrade(
      userToken: userToken,
      offerID: trade.offerID,
      isConfirm: isConfirm,
      cancelDesc: cancelDesc,
    );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isConfirm ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                isConfirm 
                    ? 'Takas başarıyla onaylandı' 
                    : 'Takas reddedildi',
              ),
            ],
          ),
          backgroundColor: isConfirm ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                tradeViewModel.errorMessage ?? 'İşlem başarısız oldu',
              ),
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

  Future<String?> _showCancelDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reddetme Nedeni'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Lütfen takası reddetme nedeninizi belirtin:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Reddetme nedeninizi yazın...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.of(context).pop(controller.text.trim());
                }
              },
              child: const Text('Reddet'),
            ),
          ],
        );
      },
    );
  }
} 