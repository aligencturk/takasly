import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../models/notification.dart' as app_notification;
import '../../core/app_theme.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart' as custom_error;
import '../../utils/logger.dart';

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
    Logger.debug('NotificationListView initialized', tag: _tag);
    
    // Widget oluşturulduktan sonra bildirimleri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<NotificationViewModel>(context, listen: false);
      viewModel.loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Bildirimler',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.black.withOpacity(0.05),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                size: 20,
                color: Colors.grey[600],
              ),
              onPressed: () {
                final viewModel = Provider.of<NotificationViewModel>(context, listen: false);
                viewModel.refreshNotifications();
              },
              tooltip: 'Yenile',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
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
            color: const Color(0xFF2563EB),
            backgroundColor: Colors.white,
            strokeWidth: 2,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
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
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Minimalist icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 32,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Henüz bildiriminiz yok',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Subtitle
            Text(
              'Yeni takas teklifleri ve güncellemeler burada görünecek',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.grey[500],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Minimal refresh button
            TextButton.icon(
              onPressed: () {
                final viewModel = Provider.of<NotificationViewModel>(context, listen: false);
                viewModel.refreshNotifications();
              },
              icon: Icon(
                Icons.refresh_rounded,
                size: 16,
                color: Colors.grey[600],
              ),
              label: Text(
                'Yenile',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: Colors.grey[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey[200]!),
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[100]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onNotificationTap(notification),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sol taraf - Icon ve indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    size: 18,
                    color: _getNotificationColor(notification.type),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Orta kısım - İçerik
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Başlık ve tarih
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                                height: 1.3,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            notification.createDate,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // İçerik
                      Text(
                        notification.body,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      
                      // Alt kısım - Tip badge
                      _buildMinimalistBadge(notification.type),
                    ],
                  ),
                ),
                
                // Sağ taraf - Arrow
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalistBadge(String type) {
    final color = _getNotificationColor(type);
    final text = _getNotificationTypeText(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.15), width: 0.5),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'new_trade_offer':
        return const Color(0xFF2563EB); // Blue
      case 'trade_completed':
        return const Color(0xFF059669); // Green
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'new_trade_offer':
        return Icons.swap_horiz_rounded;
      case 'trade_completed':
        return Icons.check_circle_rounded;
      default:
        return Icons.notifications_rounded;
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
    Logger.debug('Notification tapped: ${notification.id} - ${notification.type}', tag: _tag);
    
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
      default:
        // Varsayılan olarak hiçbir şey yapma
        Logger.debug('Unknown notification type: ${notification.type}', tag: _tag);
    }
  }
} 