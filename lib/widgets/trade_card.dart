import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:takasly/core/app_theme.dart';
import 'package:takasly/models/trade.dart';
import 'package:takasly/viewmodels/trade_viewmodel.dart';
import 'package:takasly/services/user_service.dart';
import 'package:takasly/services/auth_service.dart';
import 'package:takasly/utils/logger.dart';

class TradeCard extends StatelessWidget {
  final UserTrade trade;
  final String? currentUserId;
  final VoidCallback? onTap;
  final Function(int)? onStatusChange;

  const TradeCard({
    super.key,
    required this.trade,
    required this.currentUserId,
    this.onTap,
    this.onStatusChange,
  });

  String _getStatusText(int statusId, {TradeViewModel? tradeViewModel}) {
    // API'den gelen durumları kullanmak için TradeViewModel'e erişim sağla
    if (tradeViewModel != null && tradeViewModel.tradeStatuses.isNotEmpty) {
      final status = tradeViewModel.tradeStatuses.firstWhere(
        (s) => s.statusID == statusId,
        orElse: () => const TradeStatusModel(statusID: 0, statusTitle: 'Bilinmiyor'),
      );
      return status.statusTitle;
    }
    
    // Fallback olarak sabit değerler
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
      case 6:
        return 'Beklemede';
      case 7:
        return 'İptal Edildi';
      case 8:
        return 'Reddedildi';
      default:
        return 'Bilinmiyor';
    }
  }

  Color _getStatusColor(int statusId) {
    switch (statusId) {
      case 1: // Beklemede / Pending
        return Colors.orange;
      case 2: // Onaylandı / Approved
        return Colors.green;
      case 3: // İptal Edildi / Cancelled
        return Colors.red;
      case 4: // Tamamlandı / Completed
        return Color(0xFF10B981);
      case 5: // Reddedildi / Rejected
        return Colors.red;
      case 6: // Beklemede / Pending (alternatif)
        return Colors.grey;
      case 7: // Engellendi / Blocked
        return Colors.red;
      case 8: // İptal / Cancel (alternatif)
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(int statusId) {
    switch (statusId) {
      case 1: // Beklemede / Pending
        return Icons.pending;
      case 2: // Onaylandı / Approved
        return Icons.check_circle;
      case 3: // İptal Edildi / Cancelled
        return Icons.cancel;
      case 4: // Tamamlandı / Completed
        return Icons.done_all;
      case 5: // Reddedildi / Rejected
        return Icons.block;
      case 6: // Beklemede / Pending (alternatif)
        return Icons.pause;
      case 7: // Engellendi / Blocked
        return Icons.block;
      case 8: // İptal / Cancel (alternatif)
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  /// Kullanıcının takas teklifini gönderen taraf olup olmadığını kontrol eder
  Future<bool> _isUserSender() async {
    try {
      final authService = AuthService();
      final currentUserId = await authService.getCurrentUserId();
      
      if (currentUserId == null || currentUserId.isEmpty) {
        Logger.warning('⚠️ TradeCard - Current user ID is null or empty');
        return false;
      }

      // myProduct varsa ve userID'si mevcut kullanıcının ID'si ile eşleşiyorsa
      // kullanıcı takas teklifini gönderen taraftır
      if (trade.myProduct != null) {
        final isSender = trade.myProduct!.userID.toString() == currentUserId;
        Logger.debug('🔍 TradeCard - User is sender: $isSender (myProduct.userID: ${trade.myProduct!.userID}, currentUserId: $currentUserId)');
        return isSender;
      }
      
      Logger.debug('🔍 TradeCard - No myProduct found, assuming user is receiver');
      return false;
    } catch (e) {
      Logger.error('❌ TradeCard - Error checking if user is sender: $e', error: e);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isSender = trade.myProduct?.userID.toString() == currentUserId;
    
    Logger.debug('🔄 TradeCard build called - Trade #${trade.offerID}: statusID=${trade.statusID}, statusTitle=${trade.statusTitle}', tag: 'TradeCard');

    return Consumer<TradeViewModel>(
      builder: (context, tradeViewModel, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.swap_horiz,
                          color: AppTheme.primary,
                          size: 20,
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
                  const SizedBox(height: 12),
                  
                  // Orta kısım - Takas durumu
                  Row(
                    children: [
                      Icon(
                        _getStatusIcon(trade.statusID),
                        color: _getStatusColor(trade.statusID),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getStatusText(trade.statusID, tradeViewModel: tradeViewModel),
                        style: textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(trade.statusID),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '#${trade.offerID}',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  
                  // Alt kısım - Aksiyon butonları
                  FutureBuilder<bool>(
                    future: _isUserSender(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        );
                      }
                      
                      final isSender = snapshot.data ?? false;
                      
                      // Bekleyen takaslar için onay/red butonları
                      if (trade.statusID == 1 && !isSender) {
                        return _buildActionButtons(context);
                      } 
                      // Bekleyen takaslar için alıcı mesajı
                      else if (trade.statusID == 1 && isSender) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.pending_actions,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Karşı tarafın teklifini bekliyorsunuz',
                                    style: TextStyle(
                                      color: Colors.orange[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      // Teslim edildi durumu için yorum butonu
                      else if (trade.statusID == 4) {
                        return _buildReviewButton(context);
                      }
                      // Diğer durumlar için durum değiştirme butonu
                      else if (trade.statusID != 5 && trade.statusID != 7 && trade.statusID != 8) {
                        return _buildStatusChangeButton(context);
                      }
                      
                      return SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 60,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: product?.productImage.isNotEmpty == true
                ? CachedNetworkImage(
                    imageUrl: product!.productImage,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, size: 20),
                    ),
                  )
                : Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 20),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          product?.productTitle ?? 'Ürün bilgisi yok',
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _confirmTrade(context, true),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Onayla', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _confirmTrade(context, false),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Reddet', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
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

  /// Durum değiştirme butonu
  Widget _buildStatusChangeButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF10B981).withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showStatusChangeDialog(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.update, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Durum Değiştir',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Yorum yapma butonu
  Widget _buildReviewButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFE55A2B)],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFFF6B35).withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showReviewDialog(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Yorum Yap',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Durum değiştirme dialog'u
  void _showStatusChangeDialog(BuildContext context) {
    // TradeView'daki dropdown dialog'u çağır
    if (onStatusChange != null) {
      // TradeView'daki _showStatusChangeDialog metodunu çağırmak için
      // onStatusChange callback'ini kullanarak TradeView'a sinyal gönder
      // Mevcut durumu gönder, TradeView dropdown'ı açacak
      onStatusChange!(trade.statusID);
    }
  }

  /// Yorum yapma dialog'u
  void _showReviewDialog(BuildContext context) {
    // TradeView'daki yorum dialog'unu çağır
    if (onStatusChange != null) {
      // StatusID 4 (Teslim Edildi) için yorum dialog'unu aç
      onStatusChange!(4); // TradeView'da yorum dialog'u açılacak
    }
  }
} 