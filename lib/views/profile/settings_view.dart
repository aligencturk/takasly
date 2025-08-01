import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../services/user_service.dart';
import '../../utils/logger.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../auth/reset_password_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final UserService _userService = UserService();
  bool _isDeletingAccount = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Ayarlar',
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildAccountSection(),
            const SizedBox(height: 16),
            _buildAppSection(),
            const SizedBox(height: 16),
            _buildDangerSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Hesap',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Container(
            height: 1,
            color: Colors.grey[200],
          ),
          _buildSettingItem(
            icon: Icons.person_outline,
            title: 'Profili Düzenle',
            subtitle: 'Kişisel bilgilerinizi güncelleyin',
            onTap: () {
              // TODO: Profil düzenleme sayfasına yönlendir
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profil düzenleme özelliği yakında eklenecek'),
                ),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.lock_outline,
            title: 'Şifre Değiştir',
            subtitle: 'Hesap güvenliğinizi artırın',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ResetPasswordView(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Uygulama',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Container(
            height: 1,
            color: Colors.grey[200],
          ),
          _buildSettingItem(
            icon: Icons.notifications_outlined,
            title: 'Bildirimler',
            subtitle: 'Bildirim ayarlarınızı yönetin',
            onTap: () {
              // TODO: Bildirim ayarları sayfasına yönlendir
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bildirim ayarları yakında eklenecek'),
                ),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Gizlilik',
            subtitle: 'Gizlilik ayarlarınızı yönetin',
            onTap: () {
              // TODO: Gizlilik ayarları sayfasına yönlendir
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Gizlilik ayarları yakında eklenecek'),
                ),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.info_outline,
            title: 'Hakkında',
            subtitle: 'Uygulama bilgileri ve lisans',
            onTap: () {
              // TODO: Hakkında sayfasına yönlendir
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hakkında sayfası yakında eklenecek'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDangerSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Hesabımı Sil',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
          ),
          Container(
            height: 1,
            color: Colors.grey[200],
          ),
          _buildSettingItem(
            icon: Icons.delete_forever_outlined,
            title: 'Hesabı Sil',
            subtitle: 'Hesabınızı kalıcı olarak silin',
            textColor: Colors.red[700],
            onTap: _showDeleteAccountDialog,
            showLoading: _isDeletingAccount,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
    bool showLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: showLoading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                icon,
                color: textColor ?? Colors.grey[700],
                size: 24,
              ),
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
                        color: textColor ?? Colors.black87,
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
              if (showLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete_forever, color: Colors.red[700], size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Hesabı Sil'),
          ],
        ),
        content: const Text(
          'Hesabınızı kalıcı olarak silmek istediğinizden emin misiniz?\n\n'
          'Bu işlem geri alınamaz ve tüm verileriniz silinecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hesabı Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isDeletingAccount = true;
    });

    try {
      Logger.debug('Hesap silme işlemi başlatılıyor...', tag: 'SettingsView');

      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      
      // UserViewModel üzerinden hesabı sil
      final success = await userViewModel.deleteUserAccountNew();

      if (success) {
        Logger.debug('Hesap başarıyla silindi', tag: 'SettingsView');

        if (mounted) {
          // Ana sayfaya yönlendir
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hesabınız başarıyla silindi'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception(userViewModel.errorMessage ?? 'Hesap silme işlemi başarısız');
      }
    } catch (e) {
      Logger.error('Hesap silme hatası: $e', tag: 'SettingsView');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hesap silme işlemi başarısız: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingAccount = false;
        });
      }
    }
  }
} 