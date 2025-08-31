import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../core/app_theme.dart';
import '../../utils/logger.dart';

class AboutView extends StatefulWidget {
  const AboutView({super.key});

  @override
  State<AboutView> createState() => _AboutViewState();
}

class _AboutViewState extends State<AboutView> {
  PackageInfo? _packageInfo;
  DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  String _platformInfo = '';
  bool _isLoading = true;
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    Logger.info('AboutView initialized', tag: 'AboutView');
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final platformInfo = await _getPlatformInfo();
      
      setState(() {
        _packageInfo = packageInfo;
        _platformInfo = platformInfo;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Failed to load app info: $e', tag: 'AboutView');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _getPlatformInfo() async {
    try {
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return 'iOS ${iosInfo.systemVersion}';
      } else if (Theme.of(context).platform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        return 'Android ${androidInfo.version.release}';
      }
      return 'Platform Bilinmiyor';
    } catch (e) {
      Logger.error('Failed to get platform info: $e', tag: 'AboutView');
      return 'Platform Bilinmiyor';
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingUpdate = true;
    });

    try {
      // Basit güncelleme kontrolü - gerçek implementasyon için upgrader'ın kendi dialog'u kullanılabilir
      // Şimdilik manuel kontrol yapıyoruz
      await Future.delayed(const Duration(seconds: 2)); // Simüle edilmiş kontrol
      
      // Burada gerçek güncelleme kontrolü yapılacak
      // Şimdilik rastgele güncelleme var gibi gösteriyoruz
      final random = DateTime.now().millisecond % 2;
      if (random == 0) {
        _showUpdateDialog();
      } else {
        _showNoUpdateDialog();
      }
    } catch (e) {
      Logger.error('Failed to check for updates: $e', tag: 'AboutView');
      _showErrorDialog();
    } finally {
      setState(() {
        _isCheckingUpdate = false;
      });
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.system_update, color: AppTheme.primary),
            const SizedBox(width: 8),
            const Text('Güncelleme Mevcut'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yeni bir güncelleme mevcut!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mağazadan en son versiyonu indirebilirsiniz.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Daha Sonra'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Mağazaya yönlendir
              _launchStore();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  void _showNoUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.success),
            const SizedBox(width: 8),
            const Text('Güncel'),
          ],
        ),
        content: const Text(
          'Uygulamanız güncel! En son versiyonu kullanıyorsunuz.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.error),
            const SizedBox(width: 8),
            const Text('Hata'),
          ],
        ),
        content: const Text(
          'Güncelleme kontrolü sırasında bir hata oluştu. Lütfen daha sonra tekrar deneyin.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _launchStore() {
    // Mağaza URL'lerini platform'a göre ayarla
    final packageName = _packageInfo?.packageName ?? 'com.rivorya.takaslyapp';
    
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      // iOS App Store
      _launchUrl('https://apps.apple.com/app/id6749484217');
    } else {
      // Google Play Store
      _launchUrl('https://play.google.com/store/apps/details?id=$packageName');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Hakkında',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAppInfo,
              color: AppTheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _buildAppHeader(),
                    const SizedBox(height: 24),
                    _buildAppInfo(),
                    const SizedBox(height: 24),
                    _buildUpdateSection(),
                    const SizedBox(height: 24),
                    _buildCompanyInfo(),
                    const SizedBox(height: 24),
                    _buildLegalInfo(),
                    const SizedBox(height: 24),
                    _buildContactInfo(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAppHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadius,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.15),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/logo/takasly image.png',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.swap_horiz,
                      size: 40,
                      color: AppTheme.primary,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Takasly',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Güvenli Takas Platformu',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_packageInfo != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'v${_packageInfo!.version}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadius,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Uygulama Bilgileri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey[200]),
          _buildInfoItem(
            icon: Icons.tag_outlined,
            title: 'Versiyon',
            subtitle: _packageInfo?.version ?? 'Bilinmiyor',
            isVersion: true,
          ),
          _buildInfoItem(
            icon: Icons.build_outlined,
            title: 'Build Number',
            subtitle: _packageInfo?.buildNumber ?? 'Bilinmiyor',
          ),
          _buildInfoItem(
            icon: Icons.android_outlined,
            title: 'Platform',
            subtitle: _platformInfo.isNotEmpty ? _platformInfo : 'Android & iOS',
          ),
          _buildInfoItem(
            icon: Icons.update_outlined,
            title: 'Son Güncelleme',
            subtitle: 'Aralık 2024',
          ),
          _buildInfoItem(
            icon: Icons.apps_outlined,
            title: 'Paket Adı',
            subtitle: _packageInfo?.packageName ?? 'Bilinmiyor',
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadius,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.system_update,
                  color: AppTheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Güncelleme',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey[200]),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Uygulama güncellemelerini kontrol edin',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isCheckingUpdate ? null : _checkForUpdates,
                    icon: _isCheckingUpdate
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.system_update, size: 20),
                    label: Text(
                      _isCheckingUpdate ? 'Kontrol Ediliyor...' : 'Güncelleme Kontrol Et',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadius,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.business_outlined,
                  color: AppTheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Geliştirici',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey[200]),
          _buildInfoItem(
            icon: Icons.business_outlined,
            title: 'Şirket',
            subtitle: 'Rivorya Yazılım',
          ),
          _buildInfoItem(
            icon: Icons.web_outlined,
            title: 'Website',
            subtitle: 'www.rivorya.com',
            isClickable: true,
            onTap: () => _launchUrl('https://www.rivorya.com'),
          ),
          _buildInfoItem(
            icon: Icons.email_outlined,
            title: 'E-posta',
            subtitle: 'info@rivorya.com',
            isClickable: true,
            onTap: () => _launchEmail('info@rivorya.com'),
          ),
          _buildInfoItem(
            icon: Icons.location_on_outlined,
            title: 'Konum',
            subtitle: 'Türkiye',
          ),
        ],
      ),
    );
  }

  Widget _buildLegalInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadius,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.gavel_outlined,
                  color: AppTheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Yasal Bilgiler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey[200]),
          _buildInfoItem(
            icon: Icons.description_outlined,
            title: 'Lisans',
            subtitle: 'Ticari Lisans',
          ),
          _buildInfoItem(
            icon: Icons.copyright_outlined,
            title: 'Telif Hakkı',
            subtitle: '© 2024 Rivorya Yazılım',
          ),
          _buildInfoItem(
            icon: Icons.security_outlined,
            title: 'Gizlilik',
            subtitle: 'KVKK Uyumlu',
          ),
          _buildInfoItem(
            icon: Icons.policy_outlined,
            title: 'Kullanım Şartları',
            subtitle: 'Kullanıcı Sözleşmesi',
            isClickable: true,
            onTap: () => _showTermsDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadius,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.support_agent_outlined,
                  color: AppTheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Destek',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey[200]),
          _buildInfoItem(
            icon: Icons.help_outline,
            title: 'Yardım',
            subtitle: 'Sık Sorulan Sorular',
            isClickable: true,
            onTap: () => _showHelpDialog(),
          ),
          _buildInfoItem(
            icon: Icons.bug_report_outlined,
            title: 'Hata Bildir',
            subtitle: 'Sorun bildirmek için tıklayın',
            isClickable: true,
            onTap: () => _launchEmail('support@rivorya.com'),
          ),
          _buildInfoItem(
            icon: Icons.feedback_outlined,
            title: 'Geri Bildirim',
            subtitle: 'Önerilerinizi paylaşın',
            isClickable: true,
            onTap: () => _launchEmail('feedback@rivorya.com'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isVersion = false,
    bool isClickable = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: isClickable ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              icon,
              color: isVersion ? AppTheme.success : AppTheme.primary,
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
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (isClickable)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  void _launchUrl(String url) {
    // URL launcher implementasyonu burada yapılacak
    Logger.info('Launching URL: $url', tag: 'AboutView');
  }

  void _launchEmail(String email) {
    // Email launcher implementasyonu burada yapılacak
    Logger.info('Launching email: $email', tag: 'AboutView');
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanım Şartları'),
        content: const Text(
          'Takasly uygulamasını kullanarak, kullanım şartlarını kabul etmiş sayılırsınız. '
          'Detaylı bilgi için www.rivorya.com adresini ziyaret ediniz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yardım'),
        content: const Text(
          'Takasly uygulaması hakkında yardım için info@rivorya.com '
          'adresine e-posta gönderebilir veya www.rivorya.com adresini ziyaret edebilirsiniz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
