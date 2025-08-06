import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../viewmodels/trade_viewmodel.dart';
import '../../viewmodels/product_viewmodel.dart';

import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/trade.dart';

import '../../widgets/error_widget.dart';
import '../../widgets/product_card.dart';
import '../../widgets/trade_card.dart';
import '../../widgets/skeletons/trade_grid_skeleton.dart';
import '../../widgets/skeletons/favorite_grid_skeleton.dart';
import '../../core/app_theme.dart';
import '../../utils/logger.dart';
import 'trade_detail_view.dart';
import '../product/product_detail_view.dart';

class TradeView extends StatefulWidget {
  final int initialTabIndex;
  
  const TradeView({
    super.key,
    this.initialTabIndex = 0, // Varsayılan olarak ilk tab (Takaslar)
  });

  @override
  State<TradeView> createState() => _TradeViewState();
}

class _TradeViewState extends State<TradeView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  // Artık showButtons değerleri dinamik olarak hesaplanıyor
  String? _currentUserId;
  ScaffoldMessengerState? _scaffoldMessenger;
  
  // Provider referanslarını sakla
  TradeViewModel? _tradeViewModel;
  ProductViewModel? _productViewModel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2, 
      vsync: this,
      initialIndex: widget.initialTabIndex, // Başlangıç tab'ını ayarla
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Provider referanslarını sakla
    _tradeViewModel = Provider.of<TradeViewModel>(context, listen: false);
    _productViewModel = Provider.of<ProductViewModel>(context, listen: false);
  }

  Future<void> _loadData() async {
    // Artık showButtons değerleri dinamik olarak hesaplanıyor

    // Önce kullanıcının login olup olmadığını kontrol et
    final isLoggedIn = await _authService.isLoggedIn();

    if (!isLoggedIn) {
      if (mounted && _scaffoldMessenger != null) {
        _scaffoldMessenger!.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Oturum süresi doldu. Lütfen tekrar giriş yapın.'),
              ],
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    final tradeViewModel = _tradeViewModel;
    final productViewModel = _productViewModel;
    
    if (tradeViewModel == null || productViewModel == null) {
      Logger.error('Provider referansları bulunamadı', tag: 'TradeView');
      return;
    }

    // Dinamik kullanıcı ID'sini al
    final userId = await _authService.getCurrentUserId();
    _currentUserId = userId;

    if (userId != null && userId.isNotEmpty) {
      // Performans optimizasyonu: Hangi sekme açılacaksa ona göre veri yükle
      try {
        if (widget.initialTabIndex == 1) {
          // Favoriler sekmesi açılacaksa sadece favorileri yükle
          Logger.info('🚀 Favoriler sekmesi için optimize edilmiş yükleme başlatılıyor', tag: 'TradeView');
          
          if (productViewModel.favoriteProducts.isEmpty) {
            await productViewModel.loadFavoriteProducts();
          } else {
            Logger.info('✅ Favoriler zaten yüklü, tekrar yüklenmiyor', tag: 'TradeView');
          }
          
          // Kategoriler yüklenmemişse yükle (kategori adları için gerekli)
          if (productViewModel.categories.isEmpty) {
            Logger.info('🏷️ Kategoriler yükleniyor...', tag: 'TradeView');
            await productViewModel.loadCategories();
          }
          
          // Takas verilerini arka planda yükle (UI'ı bloklamasın)
          _loadTradeDataInBackground(tradeViewModel, userId);
          
        } else {
          // Takaslar sekmesi açılacaksa tüm verileri yükle
          Logger.info('🚀 Takaslar sekmesi için tam yükleme başlatılıyor', tag: 'TradeView');
          
          await Future.wait([
            // Kullanıcı takaslarını yükle
            tradeViewModel.loadUserTrades(int.parse(userId)),
            // Favorileri yükle (eğer yüklenmemişse)
            productViewModel.favoriteProducts.isEmpty 
                ? productViewModel.loadFavoriteProducts() 
                : Future.value(),
            // Kategorileri yükle (eğer yüklenmemişse)
            productViewModel.categories.isEmpty 
                ? productViewModel.loadCategories() 
                : Future.value(),
          ]);
          
          // Takaslar yüklendi, artık showButtons değerleri dinamik olarak hesaplanıyor
          Logger.info('✅ Takaslar yüklendi', tag: 'TradeView');
        }
        
      } catch (e) {
        Logger.error('Veri yükleme hatası: $e', tag: 'TradeView');
        // Hata durumunda sadece log'la, UI'ı bloklama
      }
    } else {
      if (mounted && _scaffoldMessenger != null) {
        _scaffoldMessenger!.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.login, color: Colors.white),
                SizedBox(width: 8),
                Text('Lütfen giriş yapın'),
              ],
            ),
            backgroundColor: Colors.orange.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Provider referanslarını temizle
    _tradeViewModel = null;
    _productViewModel = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text(
          'Takaslarım',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz_outlined, size: 16),
                  SizedBox(width: 4),
                  Text('Takaslar'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_outline, size: 16),
                  SizedBox(width: 4),
                  Text('Favoriler'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Consumer<ProductViewModel>(
        builder: (context, productViewModel, child) {
          if (productViewModel.isLoading) {
            return Container(
              color: AppTheme.background,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Yükleniyor...',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (productViewModel.hasError) {
            return CustomErrorWidget(
              message: productViewModel.errorMessage!,
              onRetry: _loadData,
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Takasladıklarım tab
              _buildTradedItemsTab(),

              // Favoriler tab
              _buildFavoritesTab(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTradedItemsTab() {
    return Consumer<TradeViewModel>(
      builder: (context, tradeViewModel, child) {
        
        // Test için geçici olarak skeleton'ı göster
        if (tradeViewModel.isLoading || tradeViewModel.userTrades.isEmpty) {
          return const TradeGridSkeleton();
        }

       if (tradeViewModel.hasError) {
          return Container(
            color: Color(0xFFF8FAFF),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 12),
                  Text(
                    tradeViewModel.errorMessage ?? 'Bir hata oluştu',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final userId = await _authService.getCurrentUserId();
                      if (userId != null && _tradeViewModel != null) {
                        try {
                          await _tradeViewModel!.loadUserTrades(int.parse(userId));
                        } catch (e) {
                          Logger.error('TradeView - Retry loadUserTrades exception: $e', tag: 'TradeView');
                        }
                      }
                    },
                    child: Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          );
        }

        final trades = tradeViewModel.userTrades;
        
        if (trades.isEmpty) {
          return Container(
            color: Color(0xFFF8FAFF),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF10B981).withOpacity(0.1),
                            Color(0xFF059669).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Icon(
                        Icons.swap_horiz_outlined,
                        size: 32,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Henüz takasınız yok',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'İlk takasınızı başlatarak takas yolculuğuna başlayın',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF718096),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Container(
          color: Color(0xFFF8FAFF),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  itemCount: trades.length,
                  itemBuilder: (context, index) {
                    final trade = trades[index];
                    
                    // TradeViewModel'den güncel trade bilgisini al
                    final updatedTrade = tradeViewModel.getTradeByOfferId(trade.offerID) ?? trade;
                    
                    // Debug: Tüm trade'lerin durumunu log'la
                    Logger.info('🔍 Trade #${updatedTrade.offerID} render ediliyor:', tag: 'TradeView');
                    Logger.info('  • senderStatusID: ${updatedTrade.senderStatusID}', tag: 'TradeView');
                    Logger.info('  • receiverStatusID: ${updatedTrade.receiverStatusID}', tag: 'TradeView');
                    Logger.info('  • senderStatusTitle: "${updatedTrade.senderStatusTitle}"', tag: 'TradeView');
                    Logger.info('  • receiverStatusTitle: "${updatedTrade.receiverStatusTitle}"', tag: 'TradeView');
                    Logger.info('  • isSenderConfirm: ${updatedTrade.isSenderConfirm}', tag: 'TradeView');
                    Logger.info('  • isReceiverConfirm: ${updatedTrade.isReceiverConfirm}', tag: 'TradeView');
                    
                    // Mevcut kullanıcının durumunu belirle
                    final currentUserId = tradeViewModel.currentUserId;
                    int currentUserStatusID;
                    bool currentUserConfirmStatus;
                    
                    final currentUserIdInt = int.tryParse(currentUserId ?? '0') ?? 0;
                    if (currentUserIdInt == updatedTrade.senderUserID) {
                      currentUserStatusID = updatedTrade.senderStatusID;
                      currentUserConfirmStatus = updatedTrade.isSenderConfirm;
                    } else if (currentUserIdInt == updatedTrade.receiverUserID) {
                      currentUserStatusID = updatedTrade.receiverStatusID;
                      currentUserConfirmStatus = updatedTrade.isReceiverConfirm;
                    } else {
                      // Varsayılan olarak receiver durumunu kullan
                      currentUserStatusID = updatedTrade.receiverStatusID;
                      currentUserConfirmStatus = updatedTrade.isReceiverConfirm;
                    }
                    
                    // Buton gösterme koşullarını kontrol et
                    bool shouldShowButtons = false;
                    
                    // StatusID=1 (Beklemede) olan trade'ler için kontrol
                    if (currentUserStatusID == 1) {
                      // Henüz onaylanmamışsa butonları göster
                      if (!currentUserConfirmStatus) {
                        shouldShowButtons = true;
                        Logger.info('✅ Trade #${updatedTrade.offerID} için henüz onaylanmamış, butonlar gösterilecek', tag: 'TradeView');
                      }
                      else {
                        shouldShowButtons = false; // Onaylanmışsa "onay bekliyor" mesajı gösterilecek
                        Logger.info('❌ Trade #${updatedTrade.offerID} için butonlar gösterilmeyecek (zaten onaylanmış), "onay bekliyor" mesajı gösterilecek', tag: 'TradeView');
                      }
                    }
                    // Diğer durumlar için butonlar TradeCard'da gösterilir
                    else {
                      shouldShowButtons = false;
                      Logger.info('✅ Trade #${updatedTrade.offerID} için statusID=$currentUserStatusID, butonlar TradeCard\'da gösterilecek', tag: 'TradeView');
                    }
                    
                    // Ürün bilgilerini kontrol et
                    final myProduct = _getMyProduct(updatedTrade);
                    final theirProduct = _getTheirProduct(updatedTrade);
                    Logger.info('  • MyProductID: ${myProduct?.productID}', tag: 'TradeView');
                    Logger.info('  • TheirProductID: ${theirProduct?.productID}', tag: 'TradeView');
                    Logger.info('  • ShouldShowButtons: $shouldShowButtons', tag: 'TradeView');
                    
                    // "Takası Tamamla" butonunun gösterilip gösterilmeyeceğini kontrol et
                    bool shouldShowCompleteButton = false;
                    if (currentUserStatusID == 2) {
                      // Karşı tarafın durumunu kontrol et
                      int otherUserStatusID;
                      if (currentUserIdInt == updatedTrade.senderUserID) {
                        otherUserStatusID = updatedTrade.receiverStatusID;
                      } else {
                        otherUserStatusID = updatedTrade.senderStatusID;
                      }
                      // Karşı taraf da onayladıysa (statusID >= 2) "Takası Tamamla" butonu göster
                      shouldShowCompleteButton = otherUserStatusID >= 2;
                    } else if (currentUserStatusID == 4) {
                      // Karşı tarafın durumunu kontrol et
                      int otherUserStatusID;
                      if (currentUserIdInt == updatedTrade.senderUserID) {
                        otherUserStatusID = updatedTrade.receiverStatusID;
                      } else {
                        otherUserStatusID = updatedTrade.senderStatusID;
                      }
                      // Karşı taraf henüz tamamlamamışsa (statusID < 4) "Takası Tamamla" butonu göster
                      // İki taraftan biri takası tamamladıktan sonra "Takası Tamamla" butonu kaybolacak
                      shouldShowCompleteButton = otherUserStatusID < 4;
                    }
                    Logger.info('  • ShouldShowCompleteButton: $shouldShowCompleteButton', tag: 'TradeView');
                    
                    // "Puan Ver" butonu artık TradeCard'da kendi mantığıyla kontrol ediliyor
                    Logger.info('  • Review button logic handled by TradeCard', tag: 'TradeView');
                    
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      child: TradeCard(
                        trade: updatedTrade,
                        currentUserId: currentUserId.toString(),
                        showButtons: shouldShowButtons, // Sadece shouldShowButtons değerini kullan
                        onTap: () {
                          // Takas detayına git
                          Logger.info('Takas detayına gidiliyor: ${updatedTrade.offerID}', tag: 'TradeView');
                        },
                        onDetailTap: () {
                          // Takas detay sayfasına git
                          Logger.info('Takas detay sayfasına gidiliyor: ${updatedTrade.offerID}', tag: 'TradeView');
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TradeDetailView(offerID: updatedTrade.offerID),
                            ),
                          );
                        },
                        onReject: (trade) {
                          // Reddetme sebebi dialog'unu göster
                          _showRejectReasonDialog(trade);
                        },
                        onReview: (UserTrade trade, int rating, String comment) async {
                          // Puan Ver butonu tıklandığında yorum yapma işlemini gerçekleştir
                          Logger.info('Puan Ver butonu tıklandı - Trade #${trade.offerID}, Rating: $rating, Comment: $comment', tag: 'TradeView');
                          await _reviewTrade(trade, rating, comment);
                        },
                        onCompleteSimple: (trade) {
                          // Takası Tamamla butonu tıklandığında takas tamamlama dialog'unu göster
                          Logger.info('Takası Tamamla butonu tıklandı - Trade #${trade.offerID}', tag: 'TradeView');
                          _showTradeCompleteDialog(trade);
                        },
                        onStatusChange: (newStatusId) async {
                          Logger.info('TradeCard onStatusChange çağrıldı: $newStatusId', tag: 'TradeView');
                          

                          
                          // AuthService'den userToken al
                          final authService = AuthService();
                          final userToken = await authService.getToken();
                          
                          if (userToken == null || userToken.isEmpty) {
                            Logger.error('UserToken bulunamadı', tag: 'TradeView');
                            if (mounted && _scaffoldMessenger != null) {
                              _scaffoldMessenger!.showSnackBar(
                                SnackBar(content: Text('Oturum bilgisi bulunamadı')),
                              );
                            }
                            return;
                          }
                          
                          if (!mounted) return;
                          final tradeViewModel = _tradeViewModel;
                          
                          if (tradeViewModel == null) {
                            Logger.error('TradeViewModel referansı bulunamadı', tag: 'TradeView');
                            return;
                          }
                          
                          try {
                            bool success = false;
                            
                            if (newStatusId == 2) {
                              // Onaylama işlemi
                              Logger.info('Trade #${updatedTrade.offerID} onaylanıyor...', tag: 'TradeView');
                              success = await tradeViewModel.confirmTrade(
                                userToken: userToken,
                                offerID: updatedTrade.offerID,
                                isConfirm: true,
                              );
                              
                              // Onaylama başarılıysa, takasları yeniden yükle
                              if (success) {
                                Logger.info('Trade #${updatedTrade.offerID} onaylandı, takaslar yeniden yükleniyor...', tag: 'TradeView');
                                
                                // Takasları yeniden yükle
                                final userId = await _authService.getCurrentUserId();
                                if (userId != null && tradeViewModel != null) {
                                  await tradeViewModel.loadUserTrades(int.parse(userId));
                                  Logger.info('✅ TradeViewModel yenilendi (onaylama sonrası)', tag: 'TradeView');
                                }
                                
                                // UI'ı güncelle
                                
                                // UI'ı güncelle
                                if (mounted) {
                                  setState(() {});
                                }
                                
                                // Başarı mesajını göster
                                if (mounted && _scaffoldMessenger != null) {
                                  _scaffoldMessenger!.showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.white),
                                          SizedBox(width: 8),
                                          Text('Takas onaylandı!'),
                                        ],
                                      ),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                                
                                // Başarı mesajını zaten gösterdik, success'i false yap
                                success = false;
                                return; // İşlem tamamlandı, return yap
                              }
                            } else if (newStatusId == 3) {
                              // Reddetme işlemi - artık onReject callback'i ile yapılıyor
                              Logger.info('Trade #${updatedTrade.offerID} reddetme işlemi onReject callback\'i ile yapılacak', tag: 'TradeView');
                              return; // Bu durumda işlem yapma, onReject callback'i kullanılacak
                            } else if (newStatusId == 4) {
                              // Tamamlama işlemi
                              Logger.info('Trade #${updatedTrade.offerID} tamamlanıyor...', tag: 'TradeView');
                              if (mounted) {
                                _showTradeCompleteDialog(updatedTrade);
                              }
                              return;
                            } else if (newStatusId == 5) {
                              // Yorum yapma işlemi (zaten tamamlanmış takas)
                              Logger.info('Trade #${updatedTrade.offerID} için yorum yapılıyor...', tag: 'TradeView');
                              if (mounted) {
                                _showTradeCompleteDialog(updatedTrade);
                              }
                              return;
                            } else {
                              // Diğer durum değişiklikleri için
                              Logger.info('Trade #${updatedTrade.offerID} durumu güncelleniyor: $newStatusId', tag: 'TradeView');
                              success = await tradeViewModel.updateTradeStatus(
                                userToken: userToken,
                                offerID: updatedTrade.offerID,
                                newStatusID: newStatusId,
                              );
                            }
                            
                            if (success) {
                              Logger.info('Trade #${updatedTrade.offerID} durumu başarıyla güncellendi', tag: 'TradeView');
                              if (mounted && _scaffoldMessenger != null) {
                                _scaffoldMessenger!.showSnackBar(
                                  SnackBar(
                                    content: Text(newStatusId == 2 ? 'Takas onaylandı' : newStatusId == 3 ? 'Takas reddedildi' : 'Durum güncellendi'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                              
                              // UI'ı güncelle
                              if (mounted) {
                                setState(() {});
                              }
                            } else {
                              Logger.error('Trade #${updatedTrade.offerID} durumu güncellenemedi', tag: 'TradeView');
                              if (mounted && _scaffoldMessenger != null) {
                                _scaffoldMessenger!.showSnackBar(
                                  SnackBar(
                                    content: Text(tradeViewModel.errorMessage ?? 'Bir hata oluştu'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            Logger.error('Trade durumu güncelleme hatası: $e', tag: 'TradeView');
                            if (mounted && _scaffoldMessenger != null) {
                              _scaffoldMessenger!.showSnackBar(
                                SnackBar(
                                  content: Text('Bir hata oluştu: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTradeCard(UserTrade trade) {
    // Cache'den showButtons değerini al
    final tradeViewModel = _tradeViewModel;
    
    if (tradeViewModel == null) {
      Logger.error('TradeViewModel referansı bulunamadı', tag: 'TradeView');
      return Container(); // Boş container döndür
    }
    final myProduct = _getMyProduct(trade);
    final theirProduct = _getTheirProduct(trade);
    
    bool? showButtons;
    if (myProduct != null && theirProduct != null) {
      final cachedStatus = tradeViewModel.getCachedTradeStatus(
        myProduct.productID, 
        theirProduct.productID
      );
      showButtons = cachedStatus?.showButtons;
    }
    
    return TradeCard(
      trade: trade,
      currentUserId: _currentUserId,
      showButtons: showButtons,
      onTap: () => _onTradeTap(trade),
      onStatusChange: (statusId) => _onStatusChange(trade, statusId),
      onDetailTap: () => _onDetailTap(trade),
      onReject: (trade) {
        // Reddetme sebebi dialog'unu göster
        _showRejectReasonDialog(trade);
      },
      onReview: (UserTrade trade, int rating, String comment) async {
        // Puan Ver butonu tıklandığında yorum yapma işlemini gerçekleştir
        Logger.info('Puan Ver butonu tıklandı - Trade #${trade.offerID}, Rating: $rating, Comment: $comment', tag: 'TradeView');
        await _reviewTrade(trade, rating, comment);
      },
      onCompleteSimple: (trade) {
        // Takası Tamamla butonu tıklandığında takas tamamlama dialog'unu göster
        Logger.info('Takası Tamamla butonu tıklandı - Trade #${trade.offerID}', tag: 'TradeView');
        _showTradeCompleteDialog(trade);
      },
    );
  }

  void _onTradeTap(UserTrade trade) {
    // Takas detayına git
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TradeDetailView(offerID: trade.offerID),
      ),
    );
  }

  void _onStatusChange(UserTrade trade, int statusId) async {
    Logger.info('Trade #${trade.offerID} durumu değiştiriliyor: $statusId', tag: 'TradeView');
    
    // Önce özel durumları kontrol et (4 ve 5 için yorum dialog'u)
    if (statusId == 4) {
      // Tamamlama işlemi
      Logger.info('Trade #${trade.offerID} tamamlanıyor...', tag: 'TradeView');
      if (mounted) {
        _showTradeCompleteDialog(trade);
      }
      return;
    } else if (statusId == 5) {
      // Yorum yapma işlemi (zaten tamamlanmış takas)
      Logger.info('Trade #${trade.offerID} için yorum yapılıyor...', tag: 'TradeView');
      if (mounted) {
        _showTradeCompleteDialog(trade);
      }
      return;
    }
    

    
    // AuthService'den userToken al
    final authService = AuthService();
    final userToken = await authService.getToken();
    
    if (userToken == null || userToken.isEmpty) {
      Logger.error('UserToken bulunamadı', tag: 'TradeView');
      if (mounted && _scaffoldMessenger != null) {
        _scaffoldMessenger!.showSnackBar(
          SnackBar(content: Text('Oturum bilgisi bulunamadı')),
        );
      }
      return;
    }
    
    if (!mounted) return;
    final tradeViewModel = _tradeViewModel;
    
    if (tradeViewModel == null) {
      Logger.error('TradeViewModel referansı bulunamadı', tag: 'TradeView');
      return;
    }
    
    try {
      bool success = false;
      
      if (statusId == 2) {
        // Onaylama işlemi
        Logger.info('Trade #${trade.offerID} onaylanıyor...', tag: 'TradeView');
        success = await tradeViewModel.confirmTrade(
          userToken: userToken,
          offerID: trade.offerID,
          isConfirm: true,
        );
        
        // Onaylama başarılıysa, takas durumunu güncelle ve "Takası Tamamla" butonunu göster
        if (success) {
          Logger.info('Trade #${trade.offerID} onaylandı, durum güncelleniyor...', tag: 'TradeView');
          
          // Takasları yeniden yükle
          final userId = await _authService.getCurrentUserId();
          if (userId != null && tradeViewModel != null) {
            await tradeViewModel.loadUserTrades(int.parse(userId));
            Logger.info('✅ TradeViewModel yenilendi (onaylama sonrası)', tag: 'TradeView');
          }
          
          // UI'ı güncelle
          if (mounted) {
            setState(() {});
          }
        }
      } else if (statusId == 3) {
        // Reddetme işlemi - artık onReject callback'i ile yapılıyor
        Logger.info('Trade #${trade.offerID} reddetme işlemi onReject callback\'i ile yapılacak', tag: 'TradeView');
        return; // Bu durumda işlem yapma, onReject callback'i kullanılacak
      } else {
        // Diğer durum değişiklikleri için
        Logger.info('Trade #${trade.offerID} durumu güncelleniyor: $statusId', tag: 'TradeView');
        success = await tradeViewModel.updateTradeStatus(
          userToken: userToken,
          offerID: trade.offerID,
          newStatusID: statusId,
        );
      }
      
      if (success) {
        Logger.info('Trade #${trade.offerID} durumu başarıyla güncellendi', tag: 'TradeView');
        if (mounted && _scaffoldMessenger != null) {
          _scaffoldMessenger!.showSnackBar(
            SnackBar(
              content: Text(statusId == 2 ? 'Takas onaylandı' : statusId == 3 ? 'Takas reddedildi' : 'Durum güncellendi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        Logger.error('Trade #${trade.offerID} durumu güncellenemedi', tag: 'TradeView');
        if (mounted && _scaffoldMessenger != null) {
          _scaffoldMessenger!.showSnackBar(
            SnackBar(
              content: Text(tradeViewModel.errorMessage ?? 'Durum güncellenirken hata oluştu'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Logger.error('Trade durumu güncelleme hatası: $e', tag: 'TradeView');
      if (mounted && _scaffoldMessenger != null) {
        _scaffoldMessenger!.showSnackBar(
          SnackBar(
            content: Text('Bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onDetailTap(UserTrade trade) {
    // Takas detayına git
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TradeDetailView(offerID: trade.offerID),
      ),
    );
  }

  Widget _buildProductCard(TradeProduct? product, String title) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF718096),
            ),
          ),
          SizedBox(height: 8),
          if (product != null) ...[
            if (product.productImage.isNotEmpty)
              Container(
                height: 60,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.productImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.image_not_supported, color: Colors.grey.shade400);
                    },
                  ),
                ),
              ),
            SizedBox(height: 8),
            Text(
              product.productTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                product.productCondition,
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ] else ...[
            // Ürün silinmiş durumu
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade200,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline, color: Colors.grey.shade400, size: 24),
                    SizedBox(height: 4),
                    Text(
                      'Ürün Silinmiş',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
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
  TradeProduct? _getMyProduct(UserTrade trade) {
    // myProduct her zaman benim ürünüm
    return trade.myProduct;
  }

  /// Karşı tarafın ürününü belirle (theirProduct her zaman karşı tarafın ürünü)
  TradeProduct? _getTheirProduct(UserTrade trade) {
    // theirProduct her zaman karşı tarafın ürünü
    return trade.theirProduct;
  }

  /// Benim ürünümün etiketini belirle
  String _getMyProductLabel(UserTrade trade) {
    return 'Benim Ürünüm';
  }

  /// Karşı tarafın ürününün etiketini belirle
  String _getTheirProductLabel(UserTrade trade) {
    return 'Karşı Tarafın Ürünü';
  }

  Widget _buildFavoritesTab() {
    return Consumer<ProductViewModel>(
      builder: (context, productViewModel, child) {
        // Loading durumunda skeleton göster (sadece favoriler boşsa ve loading ise)
        if (productViewModel.isLoadingFavorites && productViewModel.favoriteProducts.isEmpty) {
          return const FavoriteGridSkeleton();
        }

        if (productViewModel.hasErrorFavorites) {
          return CustomErrorWidget(
            message: productViewModel.favoriteErrorMessage ?? 'Favoriler yüklenirken hata oluştu',
            onRetry: () async {
              if (_productViewModel != null) {
                await _productViewModel!.loadFavoriteProducts();
              }
            },
          );
        }

        if (productViewModel.favoriteProducts.isEmpty) {
          return Container(
            color: Color(0xFFF8FAFF),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Container
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFF56565).withOpacity(0.1),
                            Color(0xFFE53E3E).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Icon(
                        Icons.favorite_outline,
                        size: 32,
                        color: Color(0xFFF56565),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Henüz favori ilanınız yok',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Beğendiğin ilanları favorilere ekleyerek burada görebilirsin',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF718096),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    // Yenile butonu ekle
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF56565).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Color(0xFFF56565).withOpacity(0.3),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            if (_productViewModel != null) {
                              await _productViewModel!.loadFavoriteProducts();
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.refresh, color: Color(0xFFF56565), size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Yenile',
                                  style: TextStyle(
                                    color: Color(0xFFF56565),
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

                    SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF10B981)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // Ana sayfaya yönlendir
                            Navigator.of(context).pushReplacementNamed('/home');
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.home, color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'İlanları Keşfet',
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
                  ],
                ),
              ),
            ),
          );
        }

        return Container(
          color: Color(0xFFF8FAFF),
          child: RefreshIndicator(
            onRefresh: () async {
              if (_productViewModel != null) {
                await _productViewModel!.loadFavoriteProducts();
              }
            },
            child: Padding(
              padding: EdgeInsets.all(12),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.62,
                ),
                itemCount: productViewModel.favoriteProducts.length,
                itemBuilder: (context, index) {
                  final product = productViewModel.favoriteProducts[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailView(productId: product.id),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: ProductCard(
                          product: product,
                          heroTag: 'favorite_${product.id}_$index',
                          hideFavoriteIcon: false, // Favori sayfasında favori ikonu gösterilmeli
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailView(productId: product.id),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFavoriteProductDetails(dynamic product) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Color(0xFFF8FAFF),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF56565), Color(0xFFE53E3E)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        product.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ürün resmi
                      if (product.images.isNotEmpty)
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey.shade200,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Builder(
                              builder: (context) {
                                final imageUrl = product.images.first;
                                
                                if (imageUrl.isEmpty || imageUrl == 'null' || imageUrl == 'undefined') {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFF56565).withOpacity(0.1),
                                          Color(0xFFE53E3E).withOpacity(0.1),
                                        ],
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 50,
                                      color: Color(0xFFF56565),
                                    ),
                                  );
                                }
                                
                                return CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFF56565).withOpacity(0.1),
                                          Color(0xFFE53E3E).withOpacity(0.1),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFFF56565),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFFF56565).withOpacity(0.1),
                                            Color(0xFFE53E3E).withOpacity(0.1),
                                          ],
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 50,
                                        color: Color(0xFFF56565),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),

                      if (product.images.isNotEmpty) SizedBox(height: 20),

                      // Açıklama
                      _buildDetailCard(
                        'Açıklama',
                        product.description.isNotEmpty
                            ? product.description
                            : 'Açıklama belirtilmemiş',
                        icon: Icons.description_outlined,
                      ),

                      SizedBox(height: 16),

                      // Durum
                      _buildDetailCard(
                        'Durum',
                        product.condition,
                        icon: Icons.info_outline,
                        isChip: true,
                        chipColor: Color(0xFF10B981),
                      ),

                      SizedBox(height: 16),

                      // Kategori
                      _buildDetailCard(
                        'Kategori',
                        product.category.name,
                        icon: Icons.category_outlined,
                      ),

                      SizedBox(height: 16),

                      // Takas tercihleri
                      if (product.tradePreferences.isNotEmpty)
                        _buildDetailCard(
                          'Takas Tercihi',
                          product.tradePreferences.join(', '),
                          icon: Icons.swap_horiz_outlined,
                        ),
                    ],
                  ),
                ),
              ),
              
              // Actions
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Favorilerden Çıkar butonu
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF56565), Color(0xFFE53E3E)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFF56565).withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            Navigator.pop(context);
                            await _removeFromFavorites(product.id);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.favorite_border, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Favorilerden Çıkar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    // İlanları Keşfet butonu
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Color(0xFF667EEA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Color(0xFF667EEA).withOpacity(0.3),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.of(context).pushReplacementNamed('/home');
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.home, color: Color(0xFF667EEA), size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'İlanları Keşfet',
                                  style: TextStyle(
                                    color: Color(0xFF667EEA),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, {
    required IconData icon,
    bool isChip = false,
    Color? chipColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF667EEA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Color(0xFF667EEA),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF718096),
                  ),
                ),
                SizedBox(height: 4),
                if (isChip)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (chipColor ?? Color(0xFF10B981)).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (chipColor ?? Color(0xFF10B981)).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        color: chipColor ?? Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2D3748),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFromFavorites(String productId) async {
    try {
      final productViewModel = _productViewModel;
      
      if (productViewModel == null) {
        Logger.error('ProductViewModel referansı bulunamadı', tag: 'TradeView');
        return;
      }
      final result = await productViewModel.toggleFavorite(productId);

      if (mounted) {
        setState(() {
          // UI'ı yenile
        });
        
        if (result['success'] == true) {
          if (_scaffoldMessenger != null) {
            _scaffoldMessenger!.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.favorite_border, color: Colors.white),
                    SizedBox(width: 8),
                    Text(result['message']),
                  ],
                ),
                backgroundColor: Color(0xFFF56565),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                action: SnackBarAction(
                  label: 'Tamam',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        } else {
          // 417 hatası veya diğer hatalar için API'den gelen mesajı göster
          if (_scaffoldMessenger != null) {
            _scaffoldMessenger!.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white),
                    SizedBox(width: 8),
                    Text(result['message']),
                  ],
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                action: SnackBarAction(
                  label: 'Tamam',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted && _scaffoldMessenger != null) {
        _scaffoldMessenger!.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Favorilerden çıkarılırken hata oluştu'),
              ],
            ),
            backgroundColor: Color(0xFFF56565),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }





  /// Puan Ver butonu için yorum ve yıldız verme dialog'u göster
  void _showTradeReviewDialog(UserTrade trade) {
    // StatefulBuilder kullanarak dialog içinde state yönetimi
    double rating = 0.0; // Başlangıçta boş yıldızlar
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
                    'Takasınız tamamlandı! Karşı tarafa yorum ve puan verin.',
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
                              Logger.info('Puan seçildi: $rating', tag: 'TradeView');
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
                        borderSide: BorderSide(color: Color(0xFF10B981), width: 2),
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
                    if (mounted && _scaffoldMessenger != null) {
                      _scaffoldMessenger!.showSnackBar(
                        SnackBar(
                          content: Text('Lütfen bir puan verin'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                    return;
                  }
                  
                  // Yorum alanı opsiyonel olduğu için kontrol kaldırıldı
                  
                  Navigator.pop(context);
                  
                  final finalRating = rating.toInt();
                  final finalComment = commentController.text.trim();
                  
                  Logger.info('Dialog kapatıldı - Rating: $finalRating, Comment: $finalComment', tag: 'TradeView');
                  final success = await _reviewTrade(trade, finalRating, finalComment);
                  if (success) {
                    // Başarılı işlem sonrası ek işlemler gerekebilir
                    Logger.info('Takas değerlendirmesi başarılı', tag: 'TradeView');
                    
                    // Kullanıcı takaslarını yenile
                    if (_currentUserId != null && _tradeViewModel != null) {
                      await _tradeViewModel!.loadUserTrades(int.parse(_currentUserId!));
                    }
                    
                    // UI'ı güncelle
                    if (mounted) {
                      setState(() {});
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
                child: Text('Değerlendir'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Takas tamamlandığında yorum ve yıldız verme dialog'u göster
  void _showTradeCompleteDialog(UserTrade trade) {
    // StatefulBuilder kullanarak dialog içinde state yönetimi
    double rating = 0.0; // Başlangıçta boş yıldızlar
    final TextEditingController commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          
          // Dialog başlığını duruma göre ayarla (API'den gelen yeni durumlara göre)
          String dialogTitle;
          String dialogSubtitle;
          
          // Mevcut kullanıcının durumunu belirle
          final currentUserId = _tradeViewModel?.currentUserId ?? '0';
          final currentUserIdInt = int.tryParse(currentUserId) ?? 0;
          int currentUserStatusID;
          
          if (currentUserIdInt == trade.senderUserID) {
            currentUserStatusID = trade.senderStatusID;
          } else if (currentUserIdInt == trade.receiverUserID) {
            currentUserStatusID = trade.receiverStatusID;
          } else {
            currentUserStatusID = trade.receiverStatusID;
          }
          
          // Her iki kullanıcının da takasını tamamlamış olup olmadığını kontrol et
          final senderCompleted = trade.senderStatusID >= 4;
          final receiverCompleted = trade.receiverStatusID >= 4;
          final bothCompleted = senderCompleted && receiverCompleted;
          
          // StatusID=2 durumunda sadece takas tamamlama yapılacak, yorum alanı gösterilmeyecek
          if (currentUserStatusID == 2) {
            dialogTitle = 'Takası Tamamla';
            dialogSubtitle = 'Takasınızı tamamlamak istediğinizden emin misiniz?';
          } else if (currentUserStatusID == 4) {
            if (bothCompleted) {
              dialogTitle = 'Takası Tamamla ve Değerlendir';
              dialogSubtitle = 'Her iki taraf da takasını tamamladı! Karşı tarafa yorum ve puan verin.';
            } else {
              dialogTitle = 'Takası Tamamla';
              dialogSubtitle = 'Takasınızı tamamlamak istediğinizden emin misiniz?';
            }
          } else if (currentUserStatusID == 5) {
            dialogTitle = 'Yorum Yap';
            dialogSubtitle = 'Takasınız tamamlandı! Karşı tarafa yorum ve puan verin.';
          } else {
            dialogTitle = 'Takas Tamamlandı';
            dialogSubtitle = 'Takasınızı tamamladınız! Karşı tarafa yorum ve puan verin.';
          }
          
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 24),
                SizedBox(width: 8),
                Text(dialogTitle),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dialogSubtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  
                  // StatusID=2 veya StatusID=4 (her iki taraf tamamlamamış) durumunda yorum alanı gösterilmez
                  if (currentUserStatusID != 2 && !(currentUserStatusID == 4 && !bothCompleted)) ...[
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
                                Logger.info('Puan seçildi: $rating', tag: 'TradeView');
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
                        hintText: 'Takas deneyiminizi paylaşın...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFF10B981), width: 2),
                        ),
                      ),
                    ),
                  ],
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
                  // StatusID=2 veya StatusID=4 (her iki taraf tamamlamamış) durumunda rating/comment kontrolü yapılmaz
                  if (currentUserStatusID != 2 && !(currentUserStatusID == 4 && !bothCompleted)) {
                    if (rating == 0) {
                      if (mounted && _scaffoldMessenger != null) {
                        _scaffoldMessenger!.showSnackBar(
                          SnackBar(
                            content: Text('Lütfen bir puan verin'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                      return;
                    }
                    
                    if (commentController.text.trim().isEmpty) {
                      if (mounted && _scaffoldMessenger != null) {
                        _scaffoldMessenger!.showSnackBar(
                          SnackBar(
                            content: Text('Lütfen bir yorum yazın'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                      return;
                    }
                  }
                  
                                    // StatusID=2 durumunda ek uyarı göster - KALDIRILDI
                  // İkinci dialog kaldırıldı, direkt işlem yapılıyor
                    
                    Navigator.pop(context);
                    
                    // StatusID=2 veya StatusID=4 (her iki taraf tamamlamamış) durumunda rating/comment değerleri 0/boş olarak gönderilir
                    final finalRating = (currentUserStatusID != 2 && !(currentUserStatusID == 4 && !bothCompleted)) ? rating.toInt() : 0;
                    final finalComment = (currentUserStatusID != 2 && !(currentUserStatusID == 4 && !bothCompleted)) ? commentController.text.trim() : '';
                    
                    Logger.info('Dialog kapatıldı - Rating: $finalRating, Comment: $finalComment, StatusID: $currentUserStatusID', tag: 'TradeView');
                    final success = await _completeTradeWithReview(trade, finalRating, finalComment);
                  if (success) {
                    // Başarılı işlem sonrası ek işlemler gerekebilir
                    Logger.info('Takas tamamlama ve yorum gönderme başarılı', tag: 'TradeView');
                    
                    // Kullanıcı takaslarını yenile
                    if (_currentUserId != null && _tradeViewModel != null) {
                      await _tradeViewModel!.loadUserTrades(int.parse(_currentUserId!));
                    }
                    
                    // showButtons değerlerini güncelle
                    // UI'ı güncelle
                    if (mounted) {
                      setState(() {});
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
                child: Text(currentUserStatusID == 2 ? 'Takası Tamamla' : 'Tamamla'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Takas durumunu güncelle
  Future<bool> _updateTradeStatus(UserTrade trade, int newStatusId) async {
    try {
      final tradeViewModel = _tradeViewModel;
      
      if (tradeViewModel == null) {
        Logger.error('TradeViewModel referansı bulunamadı', tag: 'TradeView');
        return false;
      }
      final userService = UserService();
      final userToken = await userService.getUserToken();
      
      if (userToken == null) {
        if (mounted && _scaffoldMessenger != null) {
          _scaffoldMessenger!.showSnackBar(
            SnackBar(content: Text('Kullanıcı token\'i bulunamadı')),
          );
        }
        return false;
      }

      // Eğer "Tamamlandı" durumu (statusID=5) ise, tradeComplete endpoint'ini kullan
      if (newStatusId == 5) {
        Logger.info('Trade #${trade.offerID} tamamlanıyor (tradeComplete endpoint)...', tag: 'TradeView');
        
        final success = await tradeViewModel.completeTradeWithStatus(
          userToken: userToken,
          offerID: trade.offerID,
          statusID: newStatusId,
        );

        if (success) {
          Logger.info('Trade #${trade.offerID} başarıyla tamamlandı', tag: 'TradeView');
          if (mounted && _scaffoldMessenger != null) {
            _scaffoldMessenger!.showSnackBar(
              SnackBar(
                content: Text('Takas başarıyla tamamlandı'),
                backgroundColor: Colors.green,
              ),
            );
          }
          return true;
        } else {
          Logger.error('Trade #${trade.offerID} tamamlama hatası: ${tradeViewModel.errorMessage}', tag: 'TradeView');
          if (mounted && _scaffoldMessenger != null) {
            _scaffoldMessenger!.showSnackBar(
              SnackBar(
                content: Text(tradeViewModel.errorMessage ?? 'Takas tamamlanırken hata oluştu'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;
        }
      }

      // Diğer durumlar için normal updateTradeStatus kullan
      Logger.info('Trade #${trade.offerID} durumu güncelleniyor: $newStatusId', tag: 'TradeView');
      
      final success = await tradeViewModel.updateTradeStatus(
        userToken: userToken,
        offerID: trade.offerID,
        newStatusID: newStatusId,
      );

      if (success) {
        if (mounted && _scaffoldMessenger != null) {
          _scaffoldMessenger!.showSnackBar(
            SnackBar(
              content: Text('Takas durumu basariyla guncellendi'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return true;
      } else {
        if (mounted && _scaffoldMessenger != null) {
          _scaffoldMessenger!.showSnackBar(
            SnackBar(
              content: Text(tradeViewModel.errorMessage ?? 'Durum güncellenirken hata oluştu'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    } catch (e) {
              if (mounted && _scaffoldMessenger != null) {
          _scaffoldMessenger!.showSnackBar(
            SnackBar(
              content: Text('Durum güncellenirken hata oluştu: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      return false;
    }
  }

  // Artık showButtons değerleri dinamik olarak hesaplanıyor, cache'e gerek yok

  /// Takas verilerini arka planda yükle (UI'ı bloklamasın)
  void _loadTradeDataInBackground(TradeViewModel tradeViewModel, String userId) {
    // Arka planda çalıştır, UI'ı bloklamasın
    Future.microtask(() async {
      try {
        Logger.info('🔄 Takas verileri arka planda yükleniyor...', tag: 'TradeView');
        
        await Future.wait([
          // Kullanıcı takaslarını yükle
          tradeViewModel.loadUserTrades(int.parse(userId)),
        ]);
        
        Logger.info('✅ Takas verileri arka planda yüklendi', tag: 'TradeView');
        
      } catch (e) {
        Logger.error('Arka plan takas veri yükleme hatası: $e', tag: 'TradeView');
      }
    });
  }





  /// Basit takas tamamlama işlemi (sadece userToken ve offerID)
  Future<bool> _completeTradeSimple(UserTrade trade) async {
    try {
      final tradeViewModel = _tradeViewModel;
      
      if (tradeViewModel == null) {
        Logger.error('TradeViewModel referansı bulunamadı', tag: 'TradeView');
        return false;
      }
      
      final userService = UserService();
      final userToken = await userService.getUserToken();
      
      if (userToken == null) {
        if (mounted && _scaffoldMessenger != null) {
          _scaffoldMessenger!.showSnackBar(
            SnackBar(content: Text('Kullanıcı token\'i bulunamadı')),
          );
        }
        return false;
      }

      Logger.info('Basit takas tamamlama işlemi başlatılıyor... Trade #${trade.offerID}', tag: 'TradeView');

      final success = await tradeViewModel.completeTradeSimple(
        userToken: userToken,
        offerID: trade.offerID,
      );

      if (success) {
        if (mounted && _scaffoldMessenger != null) {
          _scaffoldMessenger!.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Takas başarıyla tamamlandı'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        
        // Takasları yeniden yükle
        final userId = await _authService.getCurrentUserId();
        if (userId != null && tradeViewModel != null) {
          await tradeViewModel.loadUserTrades(int.parse(userId));
          Logger.info('✅ TradeViewModel manuel olarak yenilendi (completeTradeSimple)', tag: 'TradeView');
        }
        
        // UI'ı güncelle
        if (mounted) {
          setState(() {});
        }
        return true;
      } else {
        if (mounted && _scaffoldMessenger != null) {
          _scaffoldMessenger!.showSnackBar(
            SnackBar(
              content: Text(tradeViewModel.errorMessage ?? 'Takas tamamlanırken hata oluştu'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (mounted && _scaffoldMessenger != null) {
        _scaffoldMessenger!.showSnackBar(
          SnackBar(
            content: Text('Takas tamamlanırken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Takas değerlendirme işlemi (tradeReview endpoint'i ile)
  Future<bool> _reviewTrade(UserTrade trade, int rating, String comment) async {
    try {
      final tradeViewModel = _tradeViewModel;
      
      if (tradeViewModel == null) {
        Logger.error('TradeViewModel referansı bulunamadı', tag: 'TradeView');
        return false;
      }
      final userService = UserService();
      final userToken = await userService.getUserToken();
      
      if (userToken == null) {
        if (mounted && _scaffoldMessenger != null) {
          _scaffoldMessenger!.showSnackBar(
            SnackBar(content: Text('Kullanıcı token\'i bulunamadı')),
          );
        }
        return false;
      }

      Logger.info('Takas değerlendirme gönderiliyor... Trade #${trade.offerID}, Rating: $rating, Comment: $comment', tag: 'TradeView');

      final success = await tradeViewModel.reviewTrade(
        userToken: userToken,
        offerID: trade.offerID,
        rating: rating,
        comment: comment,
      );

      if (success) {
        if (mounted && _scaffoldMessenger != null) {
          _scaffoldMessenger!.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Değerlendirmeniz başarıyla gönderildi'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        
        // Takasları yeniden yükle - hasReview alanının güncellenmesi için
        final userId = await _authService.getCurrentUserId();
        if (userId != null && tradeViewModel != null) {
          Logger.info('🔄 Değerlendirme sonrası takaslar yeniden yükleniyor...', tag: 'TradeView');
          await tradeViewModel.loadUserTrades(int.parse(userId));
          Logger.info('✅ TradeViewModel yenilendi (reviewTrade sonrası)', tag: 'TradeView');
        }
        
        // UI'ı güncelle
        if (mounted) {
          setState(() {});
        }
        return true;
      } else {
        if (mounted && _scaffoldMessenger != null) {
          _scaffoldMessenger!.showSnackBar(
            SnackBar(
              content: Text(tradeViewModel.errorMessage ?? 'Takas değerlendirmesi gönderilirken hata oluştu'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (mounted && _scaffoldMessenger != null) {
        _scaffoldMessenger!.showSnackBar(
          SnackBar(
            content: Text('Takas değerlendirmesi gönderilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Takas değerlendirme işlemi (önce değerlendirme, sonra takas tamamlama)
  Future<bool> _completeTradeWithReview(UserTrade trade, int rating, String comment) async {
    try {
      final tradeViewModel = _tradeViewModel;
      
      if (tradeViewModel == null) {
        Logger.error('TradeViewModel referansı bulunamadı', tag: 'TradeView');
        return false;
      }
      final userService = UserService();
      final userToken = await userService.getUserToken();
      
      if (userToken == null) {
        if (mounted && _scaffoldMessenger != null) {
          _scaffoldMessenger!.showSnackBar(
            SnackBar(content: Text('Kullanıcı token\'i bulunamadı')),
          );
        }
        return false;
      }

      // Mevcut kullanıcının durumunu belirle
      final currentUserId = _tradeViewModel?.currentUserId ?? '0';
      final currentUserIdInt = int.tryParse(currentUserId) ?? 0;
      int currentUserStatusID;
      
      if (currentUserIdInt == trade.senderUserID) {
        currentUserStatusID = trade.senderStatusID;
      } else if (currentUserIdInt == trade.receiverUserID) {
        currentUserStatusID = trade.receiverStatusID;
      } else {
        currentUserStatusID = trade.receiverStatusID;
      }
      
      Logger.info('Takas işlemi başlatılıyor... Trade #${trade.offerID}, Rating: $rating, Comment: $comment, StatusID: $currentUserStatusID', tag: 'TradeView');

      // Her iki kullanıcının da takasını tamamlamış olup olmadığını kontrol et
      final senderCompleted = trade.senderStatusID >= 4;
      final receiverCompleted = trade.receiverStatusID >= 4;
      final bothCompleted = senderCompleted && receiverCompleted;
      
      // StatusID=2 (Onaylandı) durumunda sadece takas tamamlama yap
      if (currentUserStatusID == 2) {
        Logger.info('Trade #${trade.offerID} için takas tamamlama işlemi başlatılıyor (StatusID: $currentUserStatusID)', tag: 'TradeView');
        
        final success = await tradeViewModel.completeTradeWithStatus(
          userToken: userToken,
          offerID: trade.offerID,
          statusID: 4, // Teslim Edildi durumu
        );

        if (success) {
          if (mounted && _scaffoldMessenger != null) {
            // StatusID=2 durumunda karşı tarafın tamamlamasını bekliyorsunuz mesajı göster
            _scaffoldMessenger!.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Takasınız tamamlandı! Karşı tarafın takası tamamlamasını bekliyorsunuz.'),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
          
          // Takasları yeniden yükle
          final userId = await _authService.getCurrentUserId();
          if (userId != null && tradeViewModel != null) {
            await tradeViewModel.loadUserTrades(int.parse(userId));
            Logger.info('✅ TradeViewModel yenilendi (takas tamamlama sonrası)', tag: 'TradeView');
          }
          
          // UI'ı güncelle
          if (mounted) {
            setState(() {});
          }
          return true;
        } else {
          if (mounted && _scaffoldMessenger != null) {
            _scaffoldMessenger!.showSnackBar(
              SnackBar(
                content: Text(tradeViewModel.errorMessage ?? 'Takas tamamlanırken hata oluştu'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;
        }
      }
      // StatusID=4 (Teslim Edildi) durumunda ve her iki kullanıcı da tamamladıysa önce değerlendirme, sonra takas tamamlama
      else if (currentUserStatusID == 4 && bothCompleted) {
        Logger.info('Trade #${trade.offerID} için önce değerlendirme, sonra takas tamamlama işlemi başlatılıyor (StatusID: $currentUserStatusID, Her iki taraf tamamladı)', tag: 'TradeView');
        
        // ÖNCE: Değerlendirme yap
        Logger.info('🔄 1. Adım: Değerlendirme gönderiliyor...', tag: 'TradeView');
        final reviewSuccess = await tradeViewModel.reviewTrade(
          userToken: userToken,
          offerID: trade.offerID,
          rating: rating,
          comment: comment,
        );

        if (!reviewSuccess) {
          if (mounted && _scaffoldMessenger != null) {
            _scaffoldMessenger!.showSnackBar(
              SnackBar(
                content: Text(tradeViewModel.errorMessage ?? 'Değerlendirme gönderilirken hata oluştu'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;
        }

        // SONRA: Takas tamamlama yap
        Logger.info('🔄 2. Adım: Takas tamamlama gönderiliyor...', tag: 'TradeView');
        final completeSuccess = await tradeViewModel.completeTradeSimple(
          userToken: userToken,
          offerID: trade.offerID,
        );

        if (completeSuccess) {
          if (mounted && _scaffoldMessenger != null) {
            _scaffoldMessenger!.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Değerlendirmeniz gönderildi ve takas tamamlandı'),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
          
          // Takasları yeniden yükle - hasReview alanının güncellenmesi için
          final userId = await _authService.getCurrentUserId();
          if (userId != null && tradeViewModel != null) {
            Logger.info('🔄 Değerlendirme + takas tamamlama sonrası takaslar yeniden yükleniyor...', tag: 'TradeView');
            await tradeViewModel.loadUserTrades(int.parse(userId));
            Logger.info('✅ TradeViewModel yenilendi (değerlendirme + takas tamamlama sonrası)', tag: 'TradeView');
          }
          
          // UI'ı güncelle
          if (mounted) {
            setState(() {});
          }
          return true;
        } else {
          if (mounted && _scaffoldMessenger != null) {
            _scaffoldMessenger!.showSnackBar(
              SnackBar(
                content: Text(tradeViewModel.errorMessage ?? 'Takas tamamlanırken hata oluştu'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;
        }
      }
      // StatusID=4 (Teslim Edildi) durumunda ama her iki kullanıcı henüz tamamlamamışsa sadece takas tamamlama yap
      else if (currentUserStatusID == 4 && !bothCompleted) {
        Logger.info('Trade #${trade.offerID} için takas tamamlama işlemi başlatılıyor (StatusID: $currentUserStatusID, Karşı taraf henüz tamamlamamış)', tag: 'TradeView');
        
        final success = await tradeViewModel.completeTradeWithStatus(
          userToken: userToken,
          offerID: trade.offerID,
          statusID: 4, // Teslim Edildi durumu
        );

        if (success) {
          if (mounted && _scaffoldMessenger != null) {
            // StatusID=4 durumunda da karşı tarafın tamamlamasını bekliyorsunuz mesajı göster
            _scaffoldMessenger!.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Takasınız tamamlandı! Karşı tarafın takası tamamlamasını bekliyorsunuz.'),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
          
          // Takasları yeniden yükle
          final userId = await _authService.getCurrentUserId();
          if (userId != null && tradeViewModel != null) {
            await tradeViewModel.loadUserTrades(int.parse(userId));
            Logger.info('✅ TradeViewModel yenilendi (takas tamamlama sonrası)', tag: 'TradeView');
          }
          
          // UI'ı güncelle
          if (mounted) {
            setState(() {});
          }
          return true;
        } else {
          if (mounted && _scaffoldMessenger != null) {
            _scaffoldMessenger!.showSnackBar(
              SnackBar(
                content: Text(tradeViewModel.errorMessage ?? 'Takas tamamlanırken hata oluştu'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;
        }
      } else {
        // Diğer durumlar için sadece değerlendirme yap
        Logger.info('Trade #${trade.offerID} için sadece değerlendirme işlemi başlatılıyor', tag: 'TradeView');
        
        final success = await tradeViewModel.reviewTrade(
          userToken: userToken,
          offerID: trade.offerID,
          rating: rating,
          comment: comment,
        );

        if (success) {
          if (mounted && _scaffoldMessenger != null) {
            _scaffoldMessenger!.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Değerlendirmeniz başarıyla gönderildi'),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
          
          // Takasları yeniden yükle - hasReview alanının güncellenmesi için
          final userId = await _authService.getCurrentUserId();
          if (userId != null && tradeViewModel != null) {
            Logger.info('🔄 Değerlendirme sonrası takaslar yeniden yükleniyor...', tag: 'TradeView');
            await tradeViewModel.loadUserTrades(int.parse(userId));
            Logger.info('✅ TradeViewModel yenilendi (değerlendirme sonrası)', tag: 'TradeView');
          }
          
          // UI'ı güncelle
          if (mounted) {
            setState(() {});
          }
          return true;
        } else {
          if (mounted && _scaffoldMessenger != null) {
            _scaffoldMessenger!.showSnackBar(
              SnackBar(
                content: Text(tradeViewModel.errorMessage ?? 'Takas değerlendirmesi gönderilirken hata oluştu'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;
        }
      }
    } catch (e) {
      if (mounted && _scaffoldMessenger != null) {
        _scaffoldMessenger!.showSnackBar(
          SnackBar(
            content: Text('Takas tamamlanırken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }



  /// Debug bilgisi göster
  void _showDebugInfo() {
    final tradeViewModel = _tradeViewModel;
    
    if (tradeViewModel == null) {
      Logger.error('TradeViewModel referansı bulunamadı', tag: 'TradeView');
      return;
    }
    final trades = tradeViewModel.userTrades;
    
    String debugInfo = '🔍 DEBUG BİLGİSİ\n\n';
    debugInfo += '📊 Toplam Takas Sayısı: ${trades.length}\n\n';
    
    for (int i = 0; i < trades.length; i++) {
      final trade = trades[i];
      final myProduct = _getMyProduct(trade);
      final theirProduct = _getTheirProduct(trade);
      
      debugInfo += '📋 Trade #${i + 1}:\n';
      debugInfo += '  • OfferID: ${trade.offerID}\n';
      debugInfo += '  • SenderStatusID: ${trade.senderStatusID}\n';
      debugInfo += '  • ReceiverStatusID: ${trade.receiverStatusID}\n';
      debugInfo += '  • SenderStatusTitle: ${trade.senderStatusTitle}\n';
      debugInfo += '  • ReceiverStatusTitle: ${trade.receiverStatusTitle}\n';
      debugInfo += '  • SenderCancelDesc: "${trade.senderCancelDesc}"\n';
      debugInfo += '  • ReceiverCancelDesc: "${trade.receiverCancelDesc}"\n';
      debugInfo += '  • isSenderConfirm: ${trade.isSenderConfirm}\n';
      debugInfo += '  • isReceiverConfirm: ${trade.isReceiverConfirm}\n';
      debugInfo += '  • MyProductID: ${myProduct?.productID}\n';
      debugInfo += '  • TheirProductID: ${theirProduct?.productID}\n';
      
      // Buton gösterme koşullarını kontrol et
      final currentUserId = _tradeViewModel?.currentUserId ?? '0';
      final currentUserIdInt = int.tryParse(currentUserId) ?? 0;
      int currentUserStatusID;
      bool currentUserConfirmStatus;
      
      if (currentUserIdInt == trade.senderUserID) {
        currentUserStatusID = trade.senderStatusID;
        currentUserConfirmStatus = trade.isSenderConfirm;
      } else if (currentUserIdInt == trade.receiverUserID) {
        currentUserStatusID = trade.receiverStatusID;
        currentUserConfirmStatus = trade.isReceiverConfirm;
      } else {
        currentUserStatusID = trade.receiverStatusID;
        currentUserConfirmStatus = trade.isReceiverConfirm;
      }
      
      final shouldShowButtons = currentUserStatusID == 1 && !currentUserConfirmStatus;
      debugInfo += '  • ShouldShowButtons: $shouldShowButtons\n';
      debugInfo += '  • ShowButtons Açıklama: ${shouldShowButtons ? "Onay/Red butonları gösterilecek" : currentUserStatusID == 1 ? "\"Onay bekliyor\" mesajı gösterilecek" : "Diğer butonlar TradeCard\'da gösterilecek"}\n';
      debugInfo += '\n';
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Debug Bilgisi'),
        content: SingleChildScrollView(
          child: Text(debugInfo),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  /// Reddetme sebebi dialog'u göster
  void _showRejectReasonDialog(UserTrade trade) {
    final TextEditingController reasonController = TextEditingController();
    
    Logger.info('❌ Reddetme sebebi dialog\'u açılıyor - Trade #${trade.offerID}', tag: 'TradeView');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Takası Reddet'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Reddetme sebebinizi yazın:',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Reddetme sebebinizi buraya yazın...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.red, width: 2),
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
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                if (mounted && _scaffoldMessenger != null) {
                  _scaffoldMessenger!.showSnackBar(
                    SnackBar(
                      content: Text('Lütfen reddetme sebebinizi yazın'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }
              
              Navigator.pop(context);
              
              // Reddetme işlemini gerçekleştir
              await _rejectTradeWithReason(trade, reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Reddet'),
          ),
        ],
      ),
    );
  }

  /// Sebep ile birlikte takası reddet
  Future<void> _rejectTradeWithReason(UserTrade trade, String reason) async {
    try {
      final userToken = await _authService.getToken();
      
      if (userToken == null || userToken.isEmpty) {
        Logger.error('UserToken bulunamadı', tag: 'TradeView');
        if (mounted && _scaffoldMessenger != null) {
          _scaffoldMessenger!.showSnackBar(
            SnackBar(content: Text('Oturum bilgisi bulunamadı')),
          );
        }
        return;
      }
      
      if (!mounted) return;
      final tradeViewModel = _tradeViewModel;
      
      if (tradeViewModel == null) {
        Logger.error('TradeViewModel referansı bulunamadı', tag: 'TradeView');
        return;
      }
      
      Logger.info('❌ Takas reddediliyor - Trade #${trade.offerID}, Sebep: $reason', tag: 'TradeView');
      
      // confirmTrade metodunu isConfirm: false ile çağır (reddetme)
      final success = await tradeViewModel.confirmTrade(
        userToken: userToken,
        offerID: trade.offerID,
        isConfirm: false, // Reddetme
        cancelDesc: reason, // Reddetme sebebi
      );
      
      if (success) {
        if (mounted && _scaffoldMessenger != null) {
          _scaffoldMessenger!.showSnackBar(
            SnackBar(
              content: Text('Takas reddedildi'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // UI'ı yenile
        final userId = await _authService.getCurrentUserId();
        if (userId != null && tradeViewModel != null) {
          await tradeViewModel.loadUserTrades(int.parse(userId));
        }
        
        // UI'ı güncelle
        if (mounted) {
          setState(() {});
        }
      } else {
        if (mounted && _scaffoldMessenger != null) {
          _scaffoldMessenger!.showSnackBar(
            SnackBar(
              content: Text(tradeViewModel.errorMessage ?? 'Takas reddedilemedi'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && _scaffoldMessenger != null) {
        _scaffoldMessenger!.showSnackBar(
          SnackBar(
            content: Text('Bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

} 