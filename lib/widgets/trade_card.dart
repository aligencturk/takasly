import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:takasly/core/app_theme.dart';
import 'package:takasly/models/trade.dart';
import 'package:takasly/viewmodels/trade_viewmodel.dart';

import 'package:takasly/utils/logger.dart';

class TradeCard extends StatelessWidget {
  final UserTrade trade;
  final String? currentUserId;
  final VoidCallback? onTap;
  final Function(int)? onStatusChange;
  final bool? showButtons; // API'den gelen showButtons değeri
  final VoidCallback? onDetailTap; // Takas detayı için callback
  final Function(UserTrade)? onReject; // Reddetme için callback
  final Future<void> Function(UserTrade, int rating, String comment)? onReview; // Yorum yapma için callback (rating ve comment ile)
  final Function(UserTrade)? onCompleteSimple; // Basit takas tamamlama için callback

  const TradeCard({
    super.key,
    required this.trade,
    required this.currentUserId,
    this.onTap,
    this.onStatusChange,
    this.showButtons, // API'den gelen showButtons değeri
    this.onDetailTap, // Takas detayı için callback
    this.onReject, // Reddetme için callback
    this.onReview, // Yorum yapma için callback
    this.onCompleteSimple, // Basit takas tamamlama için callback
  });

  /// Mevcut kullanıcının durumunu belirle
  int _getCurrentUserStatusID() {
    // currentUserId'yi constructor'dan al
    final currentUserId = int.tryParse(this.currentUserId ?? '0') ?? 0;
    
    if (currentUserId == trade.senderUserID) {
      return trade.senderStatusID; // Gönderen ise sender durumu
    } else if (currentUserId == trade.receiverUserID) {
      return trade.receiverStatusID; // Alıcı ise receiver durumu
    }
    
    // Varsayılan olarak receiver durumunu döndür
    return trade.receiverStatusID;
  }

  /// Mevcut kullanıcının durum başlığını belirle
  String _getCurrentUserStatusTitle() {
    final currentUserId = int.tryParse(this.currentUserId ?? '0') ?? 0;
    
    if (currentUserId == trade.senderUserID) {
      return trade.senderStatusTitle; // Gönderen ise sender durumu
    } else if (currentUserId == trade.receiverUserID) {
      return trade.receiverStatusTitle; // Alıcı ise receiver durumu
    }
    
    // Varsayılan olarak receiver durumunu döndür
    return trade.receiverStatusTitle;
  }

  /// Mevcut kullanıcının reddetme sebebini belirle
  String? _getCurrentUserCancelDesc() {
    final currentUserId = int.tryParse(this.currentUserId ?? '0') ?? 0;
    
    if (currentUserId == trade.senderUserID) {
      return trade.senderCancelDesc; // Gönderen ise sender reddetme sebebi
    } else if (currentUserId == trade.receiverUserID) {
      return trade.receiverCancelDesc; // Alıcı ise receiver reddetme sebebi
    }
    
    // Varsayılan olarak receiver reddetme sebebini döndür
    return trade.receiverCancelDesc;
  }

  /// Mevcut kullanıcının onay durumunu belirle
  bool _getCurrentUserConfirmStatus() {
    final currentUserId = int.tryParse(this.currentUserId ?? '0') ?? 0;
    
    if (currentUserId == trade.senderUserID) {
      return trade.isSenderConfirm; // Gönderen ise sender onay durumu
    } else if (currentUserId == trade.receiverUserID) {
      return trade.isReceiverConfirm; // Alıcı ise receiver onay durumu
    }
    
    // Varsayılan olarak receiver onay durumunu döndür
    return trade.isReceiverConfirm;
  }

  /// "Puan Ver" butonunun gösterilip gösterilmeyeceğini belirle
  bool _shouldShowReviewButton() {
    final currentUserId = int.tryParse(this.currentUserId ?? '0') ?? 0;
    final currentUserStatusID = _getCurrentUserStatusID();
    
    // Her iki kullanıcının da takasını tamamlamış olup olmadığını kontrol et
    final senderCompleted = trade.senderStatusID >= 4;
    final receiverCompleted = trade.receiverStatusID >= 4;
    final bothCompleted = senderCompleted && receiverCompleted;
    
    Logger.debug('🔍 Trade #${trade.offerID} - Review button check:', tag: 'TradeCard');
    Logger.debug('  • currentUserStatusID: $currentUserStatusID', tag: 'TradeCard');
    Logger.debug('  • senderStatusID: ${trade.senderStatusID}, receiverStatusID: ${trade.receiverStatusID}', tag: 'TradeCard');
    Logger.debug('  • bothCompleted: $bothCompleted', tag: 'TradeCard');
    Logger.debug('  • canGiveReview: ${trade.canGiveReview}', tag: 'TradeCard');
    Logger.debug('  • hasReview: ${trade.hasReview}', tag: 'TradeCard');
    Logger.debug('  • rating: ${trade.rating}', tag: 'TradeCard');
    Logger.debug('  • comment: ${trade.comment}', tag: 'TradeCard');
    
    // Önce değerlendirme yapılıp yapılmadığını kontrol et
    // hasReview, rating veya comment varsa değerlendirme yapılmış demektir
    final hasReviewData = trade.hasReview == true || 
                         (trade.rating != null && trade.rating! > 0) || 
                         (trade.comment != null && trade.comment!.isNotEmpty);
    
    if (hasReviewData) {
      Logger.debug('🔍 Trade #${trade.offerID} - Daha önce değerlendirme yapılmış, buton gösterilmeyecek', tag: 'TradeCard');
      Logger.debug('🔍 Trade #${trade.offerID} - hasReview: ${trade.hasReview}, rating: ${trade.rating}, comment: ${trade.comment}', tag: 'TradeCard');
      return false;
    }
    
    // API'den gelen canGiveReview değerini kontrol et
    if (trade.canGiveReview == true) {
      Logger.debug('🔍 Trade #${trade.offerID} - canGiveReview=true ve değerlendirme yapılmamış, buton gösterilecek', tag: 'TradeCard');
      return true;
    }
    
    // Eğer canGiveReview false ise veya null ise, manuel kontrol yap
    // StatusID=5 (Tamamlandı) durumunda ve her iki taraf da tamamladıysa yorum yapılabilir
    // StatusID=4 durumunda sadece karşı taraf henüz tamamlamamışsa yorum yapılabilir
    if (currentUserStatusID == 5 && bothCompleted) {
      Logger.debug('🔍 Trade #${trade.offerID} - StatusID=5 ve her iki taraf tamamladı, değerlendirme yapılabilir', tag: 'TradeCard');
      return true;
    }
    
    // StatusID=4 durumunda sadece karşı taraf henüz tamamlamamışsa değerlendirme yapılabilir
    if (currentUserStatusID == 4 && !bothCompleted) {
      Logger.debug('🔍 Trade #${trade.offerID} - StatusID=4 ama karşı taraf henüz tamamlamadı, değerlendirme yapılamaz', tag: 'TradeCard');
      return false;
    }
    
    Logger.debug('🔍 Trade #${trade.offerID} - canGiveReview=false, buton gösterilmeyecek', tag: 'TradeCard');
    Logger.debug('🔍 Trade #${trade.offerID} - currentStatusID=$currentUserStatusID, bothCompleted=$bothCompleted', tag: 'TradeCard');
    return false;
  }

  /// "Takası Tamamla" butonunun gösterilip gösterilmeyeceğini belirle
  bool _shouldShowCompleteButton() {
    final currentUserId = int.tryParse(this.currentUserId ?? '0') ?? 0;
    final currentUserStatusID = _getCurrentUserStatusID();
    
    // StatusID=2 (Onaylandı) durumunda "Takası Tamamla" butonu göster
    // ANCAK: Eğer karşı taraf henüz onaylamamışsa (statusID < 2) buton gösterilmez
    // İki taraftan biri takası tamamladıktan sonra "Takası Tamamla" butonu kaybolacak
    if (currentUserStatusID == 2) {
      // Karşı tarafın durumunu kontrol et
      int otherUserStatusID;
      if (currentUserId == trade.senderUserID) {
        otherUserStatusID = trade.receiverStatusID;
      } else {
        otherUserStatusID = trade.senderStatusID;
      }
      
      // Eğer karşı taraf henüz onaylamamışsa (statusID < 2) "Takası Tamamla" butonu gösterilmez
      // İki taraftan biri takası tamamladıktan sonra "Takası Tamamla" butonu kaybolacak
      return otherUserStatusID >= 2;
    }
    
    // StatusID=4 (Teslim Edildi) durumunda, eğer karşı taraf henüz tamamlamamışsa göster
    // İki taraftan biri takası tamamladıktan sonra "Takası Tamamla" butonu kaybolacak
    if (currentUserStatusID == 4) {
      // Karşı tarafın durumunu kontrol et
      int otherUserStatusID;
      if (currentUserId == trade.senderUserID) {
        otherUserStatusID = trade.receiverStatusID;
      } else {
        otherUserStatusID = trade.senderStatusID;
      }
      
      // Eğer karşı taraf henüz takasını tamamlamamışsa (statusID < 4) "Takası Tamamla" butonu göster
      // İki taraftan biri takası tamamladıktan sonra "Takası Tamamla" butonu kaybolacak
      return otherUserStatusID < 4;
    }
    
    // StatusID=5 (Tamamlandı) durumunda buton gösterilmez
    // İki taraftan biri takası tamamladıktan sonra "Takası Tamamla" butonu kaybolacak
    if (currentUserStatusID == 5) {
      return false;
    }
    
    return false;
  }

  /// Karşı tarafın takası tamamlaması bekleniyor mesajı
  Widget _buildWaitingMessageWidget(BuildContext context) {
    final currentUserId = int.tryParse(this.currentUserId ?? '0') ?? 0;
    final currentUserStatusID = _getCurrentUserStatusID();
    
    // Sadece mevcut kullanıcının statusID'si 4 (Teslim Edildi) olduğunda göster
    if (currentUserStatusID == 4) {
      // Karşı tarafın durumunu kontrol et
      int otherUserStatusID;
      if (currentUserId == trade.senderUserID) {
        otherUserStatusID = trade.receiverStatusID;
      } else {
        otherUserStatusID = trade.senderStatusID;
      }
      
      // Eğer karşı taraf henüz takasını tamamlamamışsa (statusID < 4) mesajı göster
      if (otherUserStatusID < 4) {
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.hourglass_empty,
                  color: Colors.orange[600],
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Karşı tarafın takası tamamlaması bekleniyor',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    }
    
    // Mesaj gösterilmeyecekse boş container döndür
    return Container();
  }

  /// "Onay bekliyor" mesajını gösteren widget
  Widget _buildPendingMessageWidget(BuildContext context) {
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
                'Onay bekliyor',
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

  String _getStatusText(int statusId, {TradeViewModel? tradeViewModel}) {
    // Sabit değerler kullan
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
        return 'Reddedildi'; // 7 artık "Reddedildi" olarak değiştirildi
      case 8:
        return 'Reddedildi';
      default:
        return 'Bilinmiyor';
    }
  }

  /// API'den gelen mesajı al
  String _getApiMessage(TradeViewModel? tradeViewModel) {
    if (tradeViewModel == null) {
      Logger.debug('TradeViewModel null, API mesajı alınamıyor', tag: 'TradeCard');
      return '';
    }
    
    final myProduct = _getMyProduct();
    final theirProduct = _getTheirProduct();
    
    if (myProduct == null || theirProduct == null) {
      Logger.debug('Ürün bilgileri eksik, API mesajı alınamıyor', tag: 'TradeCard');
      return '';
    }
    
    // Cache key'i oluştur
    final cacheKey = '${myProduct.productID}_${theirProduct.productID}';
    
    // Cache'den mesajı al
    final cachedStatus = tradeViewModel.getCachedTradeStatus(
      myProduct.productID, 
      theirProduct.productID
    );
    
    if (cachedStatus != null) {
      if (cachedStatus.message.isNotEmpty) {
        return cachedStatus.message;
      }
    }
    
    // Cache'de yoksa varsayılan mesaj
    return '';
  }

  /// API mesajını gösteren widget
  Widget _buildApiMessageWidget(BuildContext context, TradeViewModel? tradeViewModel) {
    final apiMessage = _getApiMessage(tradeViewModel);
    
    if (apiMessage.isEmpty) {
      // API mesajı yoksa varsayılan mesaj göster
      return _buildPendingMessageWidget(context);
    }
    
    // API'den gelen mesajı göster
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.blue.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.blue,
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                apiMessage,
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Reddetme sebebini gösteren widget
  Widget _buildRejectionReasonWidget(BuildContext context) {
    final currentStatusID = _getCurrentUserStatusID();
    final currentCancelDesc = _getCurrentUserCancelDesc();
    
    Logger.debug('🔍 _buildRejectionReasonWidget çağrıldı - statusID: $currentStatusID, cancelDesc: "$currentCancelDesc"', tag: 'TradeCard');
    Logger.debug('🔍 cancelDesc tipi: ${currentCancelDesc.runtimeType}', tag: 'TradeCard');
    Logger.debug('🔍 cancelDesc == null: ${currentCancelDesc == null}', tag: 'TradeCard');
    Logger.debug('🔍 cancelDesc.isEmpty: ${currentCancelDesc?.isEmpty}', tag: 'TradeCard');
    Logger.debug('🔍 cancelDesc.trim().isEmpty: ${currentCancelDesc?.trim().isEmpty}', tag: 'TradeCard');
    
    if (currentCancelDesc == null || currentCancelDesc.isEmpty || currentCancelDesc.trim().isEmpty) {
      Logger.debug('❌ Reddetme sebebi null, boş veya sadece boşluk, widget gösterilmeyecek', tag: 'TradeCard');
      return Container(); // Reddetme sebebi yoksa boş container döndür
    }
    
    Logger.debug('✅ Reddetme sebebi gösteriliyor: "$currentCancelDesc"', tag: 'TradeCard');
    
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cancel_outlined,
              color: Colors.red[600],
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reddetme Sebebi:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red[700],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                                     Text(
                     currentCancelDesc!,
                     style: Theme.of(context).textTheme.bodySmall?.copyWith(
                       color: Colors.red[700],
                       fontSize: 12,
                     ),
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(int statusId) {
    switch (statusId) {
      case 1: // Onay Bekliyor
        return Colors.orange;
      case 2: // Takas Başlatıldı
        return Colors.blue;
      case 3: // Kargoya Verildi
        return Colors.purple;
      case 4: // Teslim Edildi / Alındı
        return Color(0xFF10B981);
      case 5: // Tamamlandı
        return Colors.green;
      case 6: // Beklemede
        return Colors.grey;
      case 7: // İptal Edildi
        return Colors.red;
      case 8: // Reddedildi
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(int statusId) {
    switch (statusId) {
      case 1: // Onay Bekliyor
        return Icons.pending;
      case 2: // Takas Başlatıldı
        return Icons.play_arrow;
      case 3: // Kargoya Verildi
        return Icons.local_shipping;
      case 4: // Teslim Edildi / Alındı
        return Icons.done_all;
      case 5: // Tamamlandı
        return Icons.check_circle;
      case 6: // Beklemede
        return Icons.pause;
      case 7: // İptal Edildi
        return Icons.cancel;
      case 8: // Reddedildi
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  /// Benim ürünümü belirle (myProduct her zaman benim ürünüm)
  TradeProduct? _getMyProduct() {
    // myProduct her zaman benim ürünüm
    return trade.myProduct;
  }

  /// Karşı tarafın ürününü belirle (theirProduct her zaman karşı tarafın ürünü)
  TradeProduct? _getTheirProduct() {
    // theirProduct her zaman karşı tarafın ürünü
    return trade.theirProduct;
  }

  /// Benim ürünümün etiketini belirle
  String _getMyProductLabel() {
    return 'Benim Ürünüm';
  }

  /// Karşı tarafın ürününün etiketini belirle
  String _getTheirProductLabel() {
    return 'Karşı Tarafın Ürünü';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
         // Mevcut kullanıcının onay durumunu belirle
     final hasConfirmed = _getCurrentUserConfirmStatus();
     final hasRejected = !_getCurrentUserConfirmStatus() && (_getCurrentUserStatusID() == 7 || _getCurrentUserStatusID() == 8);
    
    // Debug log'lar sürekli tekrarlanmasını önlemek için kaldırıldı
    
    // Buton gösterme mantığı - log'lar sürekli tekrarlanmasını önlemek için kaldırıldı

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
          child: Stack(
            children: [
              // Ana içerik
              InkWell(
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
                          // Benim ürünüm (isConfirm'e göre belirlenir)
                          Expanded(
                            child: _buildProductInfo(
                              context,
                              _getMyProduct(),
                              _getMyProductLabel(),
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
                          // Karşı tarafın ürünü (isConfirm'e göre belirlenir)
                          Expanded(
                            child: _buildProductInfo(
                              context,
                              _getTheirProduct(),
                              _getTheirProductLabel(),
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
                             _getStatusIcon(_getCurrentUserStatusID()),
                             color: _getStatusColor(_getCurrentUserStatusID()),
                             size: 16,
                           ),
                           const SizedBox(width: 6),
                           Text(
                             _getCurrentUserStatusTitle(),
                             style: textTheme.bodySmall?.copyWith(
                               color: _getStatusColor(_getCurrentUserStatusID()),
                               fontWeight: FontWeight.w600,
                               fontSize: 13,
                             ),
                           ),
                          const Spacer(),
                          // Takas numarası kaldırıldı
                        ],
                      ),
                      
                      // Karşı tarafın takası tamamlaması bekleniyor mesajı (sadece statusID=4 olan kullanıcıya göster)
                      _buildWaitingMessageWidget(context),
                      
                      // Reddetme sebebi gösterimi (statusID=3, 7 veya 8 ise)
                      if ((_getCurrentUserStatusID() == 3 || _getCurrentUserStatusID() == 7 || _getCurrentUserStatusID() == 8) && _getCurrentUserCancelDesc()?.isNotEmpty == true) ...[
                        Builder(
                          builder: (context) {
                            Logger.debug('🔍 Reddetme sebebi widget\'ı gösteriliyor', tag: 'TradeCard');
                            Logger.debug('🔍 cancelDesc null mu?: ${_getCurrentUserCancelDesc() == null}', tag: 'TradeCard');
                            Logger.debug('🔍 cancelDesc boş mu?: ${_getCurrentUserCancelDesc()?.isEmpty}', tag: 'TradeCard');
                            Logger.debug('🔍 cancelDesc uzunluğu: ${_getCurrentUserCancelDesc()?.length}', tag: 'TradeCard');
                            return _buildRejectionReasonWidget(context);
                          },
                        ),
                      ],
                      
                      // Alt kısım - Aksiyon butonları
                      // YENİ MANTIK: Kullanıcının istediği şekilde düzenlendi
                      
                      // If "Takası Tamamla" button should be shown based on the comprehensive logic
                      Builder(
                        builder: (context) {
                          final shouldShow = _shouldShowCompleteButton();
                          Logger.debug('🔍 Trade #${trade.offerID} - ShouldShowCompleteButton: $shouldShow', tag: 'TradeCard');
                          Logger.debug('🔍 Trade #${trade.offerID} - CurrentUserStatusID: ${_getCurrentUserStatusID()}', tag: 'TradeCard');
                          Logger.debug('🔍 Trade #${trade.offerID} - SenderStatusID: ${trade.senderStatusID}, ReceiverStatusID: ${trade.receiverStatusID}', tag: 'TradeCard');
                          return shouldShow ? _buildCompleteTradeButton(context) : Container();
                        },
                      ),
                      
                      // StatusID=1 (Beklemede) durumunda sadece onay/red butonları veya "onay bekliyor" mesajı
                      if (_getCurrentUserStatusID() == 1) ...[
                        if (showButtons == true) // This showButtons comes from TradeView
                          _buildActionButtons(context)
                        else
                          _buildApiMessageWidget(context, tradeViewModel) // This is the "Onay bekliyor" message
                      ],
                      
                      // StatusID=4 veya 5 durumunda "Puan Ver" butonu (eğer her iki taraf da tamamladıysa)
                      Builder(
                        builder: (context) {
                          final currentStatusID = _getCurrentUserStatusID();
                          final shouldShowReview = _shouldShowReviewButton();
                          Logger.debug('🔍 Trade #${trade.offerID} - Review button check: currentStatusID=$currentStatusID, shouldShowReview=$shouldShowReview', tag: 'TradeCard');
                          Logger.debug('🔍 Trade #${trade.offerID} - Trade data: hasReview=${trade.hasReview}, rating=${trade.rating}, comment=${trade.comment}', tag: 'TradeCard');
                          Logger.debug('🔍 Trade #${trade.offerID} - canGiveReview=${trade.canGiveReview}', tag: 'TradeCard');
                          
                          // Yorum butonu gösterilme koşulları:
                          // 1. StatusID=4 veya 5 olmalı
                          // 2. shouldShowReview true olmalı (canGiveReview=true veya manuel kontrol geçmeli)
                          // 3. Daha önce yorum yapılmamış olmalı
                          if ((currentStatusID == 4 || currentStatusID == 5) && shouldShowReview) {
                            Logger.debug('🔍 Trade #${trade.offerID} - Review button gösteriliyor!', tag: 'TradeCard');
                            return _buildReviewButton(context);
                          }
                          
                          Logger.debug('🔍 Trade #${trade.offerID} - Review button gösterilmiyor. currentStatusID=$currentStatusID, shouldShowReview=$shouldShowReview, hasReview=${trade.hasReview}', tag: 'TradeCard');
                          return Container();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Üst köşe detay butonu
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onDetailTap,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
        const SizedBox(height: 4),
        Text(
          product?.productTitle ?? 'Ürün bulunamadı',
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (product?.productCondition != null) ...[
          const SizedBox(height: 2),
          Text(
            product!.productCondition,
            style: textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _confirmTrade(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Onayla',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _rejectTrade(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Reddet',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildReviewButton(BuildContext context) {
    // Buton metnini duruma göre ayarla
    String buttonText = 'Değerlendir';
    
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _completeTradeWithReview(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(
            buttonText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteTradeButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _completeTradeSimple(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: const Text(
            'Takası Tamamla',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _confirmTrade(BuildContext context) {
          Logger.info('Trade onaylanıyor...', tag: 'TradeCard');
    
    // Bu metod sadece buton gösterimi için, gerçek işlem TradeView'da yapılıyor
    // Burada sadece log atıyoruz
    Logger.debug('Trade onaylama butonu tıklandı, işlem TradeView\'da yapılacak', tag: 'TradeCard');
    
    if (onStatusChange != null) {
      onStatusChange!(2); // Onaylandı durumu
    }
  }

  void _rejectTrade(BuildContext context) {
          Logger.info('Trade reddediliyor...', tag: 'TradeCard');
    
    // Eğer onReject callback'i varsa onu kullan (reddetme sebebi dialog'u için)
    if (onReject != null) {
      onReject!(trade);
    } else if (onStatusChange != null) {
      // Eski yöntem (geriye uyumluluk için)
      onStatusChange!(3); // Reddedildi durumu
    }
  }



  void _completeTradeWithReview(BuildContext context) {
    Logger.info('Trade puan veriliyor...', tag: 'TradeCard');
    
    // Yıldız ve yorum ile birlikte değerlendirme dialog'u göster
    _showTradeReviewDialog(context);
  }

  /// Yıldız ve yorum ile birlikte değerlendirme dialog'u
  void _showTradeReviewDialog(BuildContext context) {
    double rating = 0.0;
    final TextEditingController commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 24),
                SizedBox(width: 8),
                Text('Değerlendir'),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Takasınız tamamlandı! Karşı tarafa değerlendirme yapın.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Yıldız değerlendirmesi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Puan: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      SizedBox(width: 8),
                      ...List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              rating = index + 1.0;
                              Logger.info('Puan seçildi: $rating', tag: 'TradeCard');
                            });
                          },
                          child: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: index < rating ? Colors.amber : Colors.grey.shade400,
                            size: 32,
                          ),
                        );
                      }),
                    ],
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Yorum alanı
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Takas deneyiminizi paylaşın... (İsteğe bağlı)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primary, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (rating == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lütfen bir puan verin'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  
                  Navigator.pop(context);
                  
                  final finalRating = rating.toInt();
                  final finalComment = commentController.text.trim();
                  
                  Logger.info('Dialog kapatıldı - Rating: $finalRating, Comment: $finalComment', tag: 'TradeCard');
                  
                  // onReview callback'ini çağır ve yıldız/yorum bilgilerini geçir
                  if (onReview != null) {
                    Logger.info('onReview callback çağrılıyor - Rating: $finalRating, Comment: $finalComment', tag: 'TradeCard');
                    await onReview!(trade, finalRating, finalComment);
                    
                    // Başarı mesajı göster
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.star, color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text('Değerlendirmeniz gönderildi'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } else {
                    Logger.warning('onReview callback tanımlanmamış!', tag: 'TradeCard');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text('Değerlendir ve Gönder'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _completeTradeSimple(BuildContext context) {
    Logger.info('Trade basit tamamlanıyor...', tag: 'TradeCard');
    Logger.debug('Trade basit tamamlama butonu tıklandı, işlem TradeView\'da yapılacak', tag: 'TradeCard');

    // Bu metod sadece basit tamamlama için, gerçek işlem TradeView'da yapılıyor
    // Burada sadece log atıyoruz
    if (onCompleteSimple != null) {
      Logger.info('onCompleteSimple callback çağrılıyor', tag: 'TradeCard');
      onCompleteSimple!(trade);
    } else {
      Logger.warning('onCompleteSimple callback tanımlanmamış!', tag: 'TradeCard');
    }
  }
}