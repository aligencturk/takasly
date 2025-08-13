import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../models/notification.dart' as app_notification;
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart' as custom_error;
import '../../utils/logger.dart';
import 'package:flutter/services.dart';

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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Bildirimler',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final viewModel = Provider.of<NotificationViewModel>(context, listen: false);
              viewModel.refreshNotifications();
            },
          ),
          IconButton(
            icon: const Icon(Icons.vpn_key_outlined),
            tooltip: 'Bearer ile Test Gönder',
            onPressed: () async {
              final controller = TextEditingController();
              bool toDevice = true;
              await showDialog(
                context: context,
                builder: (ctx) {
                  return StatefulBuilder(
                    builder: (ctx, setState) => AlertDialog(
                      title: const Text('Bearer ile Test Bildirimi'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: controller,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'OAuth 2.0 Bearer Access Token',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Switch(
                                value: toDevice,
                                onChanged: (v) => setState(() => toDevice = v),
                              ),
                              const SizedBox(width: 8),
                              Text(toDevice ? 'Cihaza Gönder' : 'Topic: test_topic'),
                            ],
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('İptal'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final bearer = controller.text.trim();
                            if (bearer.isEmpty) {
                              Navigator.of(ctx).pop();
                              return;
                            }
                            final vm = Provider.of<NotificationViewModel>(context, listen: false);
                            await vm.sendTestNotificationWithBearer(bearer: bearer);
                            if (mounted) Navigator.of(ctx).pop();
                          },
                          child: const Text('Gönder'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.key),
            tooltip: 'FCM Token Kopyala',
            onPressed: () async {
              final vm = Provider.of<NotificationViewModel>(context, listen: false);
              final token = vm.fcmToken ?? 'FCM token henüz alınamadı';
              await Clipboard.setData(ClipboardData(text: token));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(token.length > 60 ? '${token.substring(0,60)}...' : token)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: () {
              final viewModel = Provider.of<NotificationViewModel>(context, listen: false);
              viewModel.sendTestNotification();
            },
            tooltip: 'Test Bildirimi Gönder',
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
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: AppTheme.textPrimary.withOpacity(0.5),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            'Henüz bildiriminiz yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Yeni takas teklifleri ve güncellemeler burada görünecek',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(app_notification.Notification notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: InkWell(
        onTap: () => _onNotificationTap(notification),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık ve tarih
              Row(
                children: [
                  Expanded(
                    child: Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  Text(
                    notification.createDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textPrimary.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.smallPadding),
              
              // İçerik
              Text(
                notification.body,
                style: TextStyle(
                  fontSize: 14,
                                     color: AppTheme.textPrimary.withOpacity(0.8),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              
              // Bildirim tipi badge'i
              _buildNotificationTypeBadge(notification.type),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTypeBadge(String type) {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (type) {
      case 'new_trade_offer':
        badgeColor = Colors.blue;
        badgeText = 'Yeni Takas';
        badgeIcon = Icons.swap_horiz;
        break;
      case 'trade_completed':
        badgeColor = Colors.green;
        badgeText = 'Takas Tamamlandı';
        badgeIcon = Icons.check_circle;
        break;
      default:
        badgeColor = Colors.grey;
        badgeText = 'Bildirim';
        badgeIcon = Icons.notifications;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.smallPadding,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            size: 14,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
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