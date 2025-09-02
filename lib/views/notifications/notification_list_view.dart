import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../models/notification.dart' as app_notification;
import '../../core/app_theme.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart' as custom_error;

class NotificationListView extends StatefulWidget {
  const NotificationListView({Key? key}) : super(key: key);

  @override
  State<NotificationListView> createState() => _NotificationListViewState();
}

class _NotificationListViewState extends State<NotificationListView> {
  static const String _tag = 'NotificationListView';

  @override
  void initState() {
    super.initState();

    // Widget oluşturulduktan sonra bildirimleri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<NotificationViewModel>(context, listen: false);
      viewModel.loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Bildirimler',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppTheme.surface,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary, size: 20),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          // Tümünü Sil butonu
          IconButton(
            icon: Icon(
              Icons.delete_sweep_outlined,
              size: 18,
              color: AppTheme.error,
            ),
            onPressed: () async {
              // Onay dialog'u göster
              final shouldDelete = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Tüm Bildirimleri Sil'),
                  content: Text('Tüm bildirimleri silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                      child: Text('Sil'),
                    ),
                  ],
                ),
              );

              if (shouldDelete == true) {
                final viewModel = Provider.of<NotificationViewModel>(context, listen: false);
                await viewModel.deleteAllNotifications();
              }
            },
            tooltip: 'Tümünü Sil',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
          // Tümünü Okundu İşaretle butonu
          IconButton(
            icon: Icon(
              Icons.mark_email_read_outlined,
              size: 18,
              color: AppTheme.primary,
            ),
            onPressed: () async {
              final viewModel = Provider.of<NotificationViewModel>(context, listen: false);
              await viewModel.markAllAsRead();
            },
            tooltip: 'Tümünü Okundu İşaretle',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
          // Yenile butonu
          IconButton(
            icon: Icon(
              Icons.refresh_outlined,
              size: 18,
              color: AppTheme.textSecondary,
            ),
            onPressed: () {
              final viewModel = Provider.of<NotificationViewModel>(context, listen: false);
              viewModel.refreshNotifications();
            },
            tooltip: 'Yenile',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
      body: Consumer<NotificationViewModel>(
        builder: (context, viewModel, child) {
          // Loading durumu
          if (viewModel.isLoading && viewModel.notifications.isEmpty) {
            return const LoadingWidget();
          }

          // Error durumu
          if (viewModel.hasError && viewModel.notifications.isEmpty) {
            return custom_error.CustomErrorWidget(
              message: viewModel.errorMessage,
              onRetry: () => viewModel.loadNotifications(),
            );
          }

          // Boş durum
          if (!viewModel.hasNotifications) {
            return _buildEmptyState();
          }

          // Bildirim listesi
          return RefreshIndicator(
            onRefresh: viewModel.refreshNotifications,
            color: AppTheme.primary,
            backgroundColor: AppTheme.surface,
            strokeWidth: 2,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: viewModel.notifications.length,
              itemBuilder: (context, index) {
                final notification = viewModel.notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Minimal icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.notifications_none_outlined,
                size: 24,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              'Henüz bildiriminiz yok',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            
            // Subtitle
            Text(
              'Yeni takas teklifleri ve güncellemeler burada görünecek',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Minimal refresh button
            TextButton.icon(
              onPressed: () {
                final viewModel = Provider.of<NotificationViewModel>(context, listen: false);
                viewModel.refreshNotifications();
              },
              icon: Icon(
                Icons.refresh_outlined,
                size: 14,
                color: AppTheme.primary,
              ),
              label: Text(
                'Yenile',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primary,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: AppTheme.primary.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(app_notification.Notification notification) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[100]!, width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onNotificationTap(notification),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sol taraf - Icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    size: 16,
                    color: _getNotificationColor(notification.type),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Orta kısım - İçerik
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Başlık
                      Text(
                        notification.title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                          height: 1.2,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // İçerik
                      Text(
                        notification.body,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textSecondary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // Alt kısım - Tip ve tarih
                      Row(
                        children: [
                          _buildMinimalBadge(notification.type),
                          const SizedBox(width: 8),
                          Text(
                            notification.createDate,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textSecondary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Sağ taraf - Silme butonu
                IconButton(
                  onPressed: () async {
                    // Onay dialog'u göster
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Bildirimi Sil'),
                        content: Text('Bu bildirimi silmek istediğinizden emin misiniz?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('İptal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                            child: Text('Sil'),
                          ),
                        ],
                      ),
                    );

                    if (shouldDelete == true) {
                      final viewModel = Provider.of<NotificationViewModel>(context, listen: false);
                      await viewModel.deleteNotification(notification.id);
                    }
                  },
                  icon: Icon(
                    Icons.close,
                    size: 14,
                    color: AppTheme.textSecondary.withOpacity(0.6),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalBadge(String type) {
    final color = _getNotificationColor(type);
    final text = _getNotificationTypeText(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: color,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'new_trade_offer':
        return AppTheme.primary; // App tema primary rengi
      case 'trade_completed':
        return AppTheme.success; // App tema success rengi
      default:
        return AppTheme.textSecondary; // App tema text secondary rengi
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'new_trade_offer':
        return Icons.swap_horiz_outlined;
      case 'trade_completed':
        return Icons.check_circle_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _getNotificationTypeText(String type) {
    switch (type) {
      case 'new_trade_offer':
        return 'Yeni Takas';
      case 'trade_completed':
        return 'Tamamlandı';
      default:
        return 'Bildirim';
    }
  }

  void _onNotificationTap(app_notification.Notification notification) {
    
    // Bildirim tipine göre yönlendirme
    switch (notification.type) {
      case 'new_trade_offer':
        // Takas detay sayfasına yönlendir
        if (notification.typeId.isNotEmpty) {
          Navigator.pushNamed(
            context,
            '/trade-detail',
            arguments: {'offerID': int.tryParse(notification.typeId) ?? 0},
          );
        }
        break;
      case 'trade_completed':
        // Takas detay sayfasına yönlendir
        if (notification.typeId.isNotEmpty) {
          Navigator.pushNamed(
            context,
            '/trade-detail',
            arguments: {'offerID': int.tryParse(notification.typeId) ?? 0},
          );
        }
        break;
      case 'sponsor_expired':
        // Ürün detay sayfasına yönlendir
        if (notification.typeId.isNotEmpty) {
          Navigator.pushNamed(
            context,
            '/product-detail',
            arguments: {'productId': notification.typeId},
          );
        }
        break;
      default:
        // Varsayılan olarak hiçbir şey yapma
    }
  }
} 