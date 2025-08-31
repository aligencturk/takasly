import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../services/notification_service.dart';
import '../../utils/logger.dart';

class NotificationSettingsView extends StatefulWidget {
  const NotificationSettingsView({super.key});

  @override
  State<NotificationSettingsView> createState() => _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NotificationViewModel(),
      child: _NotificationSettingsContent(),
    );
  }
}

class _NotificationSettingsContent extends StatefulWidget {
  @override
  State<_NotificationSettingsContent> createState() => _NotificationSettingsContentState();
}

class _NotificationSettingsContentState extends State<_NotificationSettingsContent> {
  late NotificationViewModel _notificationViewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationViewModel = Provider.of<NotificationViewModel>(context, listen: false);
      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    try {
      // ViewModel'den ayarları yükle
      await _notificationViewModel.loadNotificationSettings();
      
      // İzin durumunu kontrol et
      await _notificationViewModel.checkNotificationPermission();
    } catch (e) {
      Logger.error('Bildirim ayarları yüklenirken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ayarlar yüklenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _requestPermission() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
                     settings.authorizationStatus == AuthorizationStatus.provisional;

      if (granted) {
        // iOS foreground notification presentation options
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        // NotificationService'i yeniden başlat
        await NotificationService.instance.init();

        // ViewModel'i güncelle
        await _notificationViewModel.checkNotificationPermission();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bildirim izni verildi'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bildirim izni reddedildi'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      Logger.error('Bildirim izni istenirken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İzin istenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openAppSettings() async {
    try {
      // Uygulama ayarlarına yönlendir
      // Bu işlem platform specific olabilir
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen cihaz ayarlarından bildirim iznini verin'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      Logger.error('Uygulama ayarları açılırken hata: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Bildirim Ayarları',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 20),
        ),
      ),
            body: Builder(
        builder: (context) {
          final viewModel = Provider.of<NotificationViewModel>(context);
          
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildPermissionSection(),
                const SizedBox(height: 16),
                _buildNotificationTypesSection(),
                const SizedBox(height: 16),
                _buildSoundVibrationSection(),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermissionSection() {
    return Builder(
      builder: (context) {
        final viewModel = Provider.of<NotificationViewModel>(context);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      viewModel.isPermissionGranted ? Icons.notifications_active : Icons.notifications_off,
                      color: viewModel.isPermissionGranted ? Colors.green : Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Bildirim İzni',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: Colors.grey[200]),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      viewModel.isPermissionGranted 
                          ? 'Bildirimler aktif'
                          : 'Bildirimler devre dışı',
                      style: TextStyle(
                        fontSize: 14,
                        color: viewModel.isPermissionGranted ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      viewModel.isPermissionGranted
                          ? 'Uygulama size bildirim gönderebilir'
                          : 'Bildirim almak için izin vermeniz gerekiyor',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!viewModel.isPermissionGranted) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: viewModel.isLoading ? null : _requestPermission,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: viewModel.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('İzin Ver'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _openAppSettings,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Cihaz Ayarları'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationTypesSection() {
    return Builder(
      builder: (context) {
        final viewModel = Provider.of<NotificationViewModel>(context);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Bildirim Türleri',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Container(height: 1, color: Colors.grey[200]),
              _buildNotificationTypeItem(
                title: 'Chat Bildirimleri',
                subtitle: 'Mesaj ve sohbet bildirimleri',
                icon: Icons.chat_bubble_outline,
                value: viewModel.isChatNotificationsEnabled,
                onChanged: (value) {
                  viewModel.updateNotificationSetting('notification_chat', value);
                },
              ),
              _buildNotificationTypeItem(
                title: 'Takas Bildirimleri',
                subtitle: 'Takas teklifleri ve güncellemeleri',
                icon: Icons.swap_horiz_outlined,
                value: viewModel.isTradeNotificationsEnabled,
                onChanged: (value) {
                  viewModel.updateNotificationSetting('notification_trade', value);
                },
              ),
              _buildNotificationTypeItem(
                title: 'Sistem Bildirimleri',
                subtitle: 'Uygulama güncellemeleri ve duyurular',
                icon: Icons.system_update_outlined,
                value: viewModel.isSystemNotificationsEnabled,
                onChanged: (value) {
                  viewModel.updateNotificationSetting('notification_system', value);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSoundVibrationSection() {
    return Builder(
      builder: (context) {
        final viewModel = Provider.of<NotificationViewModel>(context);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Ses ve Titreşim',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Container(height: 1, color: Colors.grey[200]),
              _buildNotificationTypeItem(
                title: 'Ses',
                subtitle: 'Bildirim sesi çal',
                icon: Icons.volume_up_outlined,
                value: viewModel.isSoundEnabled,
                onChanged: (value) {
                  viewModel.updateNotificationSetting('notification_sound', value);
                },
              ),
              _buildNotificationTypeItem(
                title: 'Titreşim',
                subtitle: 'Bildirim titreşimi',
                icon: Icons.vibration_outlined,
                value: viewModel.isVibrationEnabled,
                onChanged: (value) {
                  viewModel.updateNotificationSetting('notification_vibration', value);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationTypeItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[700], size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.blue,
                activeTrackColor: Colors.blue[100],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
