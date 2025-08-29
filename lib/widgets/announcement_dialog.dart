import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:takasly/widgets/app_network_image.dart';
import 'package:takasly/core/http_headers.dart';
import '../viewmodels/remote_config_viewmodel.dart';
import '../core/app_theme.dart';
import '../utils/logger.dart';

class AnnouncementDialog extends StatelessWidget {
  const AnnouncementDialog({Key? key}) : super(key: key);

  /// String'den BoxFit'e çevirir
  static BoxFit _parseBoxFit(String fitString) {
    switch (fitString.toLowerCase()) {
      case 'contain':
        return BoxFit.contain;
      case 'fill':
        return BoxFit.fill;
      case 'fitwidth':
        return BoxFit.fitWidth;
      case 'fitheight':
        return BoxFit.fitHeight;
      case 'scaledown':
        return BoxFit.scaleDown;
      case 'cover':
      default:
        return BoxFit.cover;
    }
  }

  /// Resim widget'ını oluşturur
  Widget _buildAnnouncementImage({
    required String imageUrl,
    required double width,
    required double height,
    required BoxFit fit,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: Colors.grey[100]),
      child: AppNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
      ),
    );
  }

  /// Duyuruyu gösterir ve kullanıcı kapatırsa marked as shown yapar
  static Future<void> showIfNeeded(BuildContext context) async {
    try {
      final remoteConfigViewModel = context.read<RemoteConfigViewModel>();

      // Duyuru kontrolü yap
      final shouldShow = await remoteConfigViewModel.checkForAnnouncement();

      if (shouldShow && context.mounted) {
        Logger.info('📢 Duyuru gösteriliyor...');
        // Görsel varsa öncelik: tam ekran görsel duyuru
        final hasImage =
            remoteConfigViewModel.announcementImageEnabled &&
            remoteConfigViewModel.announcementImageUrl.isNotEmpty;

        await showDialog<void>(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black26,
          builder: (BuildContext context) => hasImage
              ? const FullScreenImageAnnouncementDialog()
              : const AnnouncementDialog(),
        );

        // Dialog kapatıldıktan sonra gösterildi olarak işaretle
        remoteConfigViewModel.markAnnouncementAsShown();
        Logger.info('✅ Duyuru gösterildi olarak işaretlendi');
      }
    } catch (e) {
      Logger.error('❌ Duyuru gösterme hatası: $e', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RemoteConfigViewModel>(
      builder: (context, remoteConfigViewModel, child) {
        // Duyuru verilerini al
        final title = remoteConfigViewModel.announcementTitle;
        final text = remoteConfigViewModel.announcementText;
        final buttonText = remoteConfigViewModel.announcementButtonText;

        // Resim özelliklerini al
        final imageUrl = remoteConfigViewModel.announcementImageUrl;
        final imageEnabled = remoteConfigViewModel.announcementImageEnabled;
        final imagePosition = remoteConfigViewModel.announcementImagePosition;
        final imageWidth = remoteConfigViewModel.announcementImageWidth;
        final imageHeight = remoteConfigViewModel.announcementImageHeight;
        final imageFit = _parseBoxFit(
          remoteConfigViewModel.announcementImageFit,
        );

        // Resim gösterilecek mi?
        final showImage = imageEnabled && imageUrl.isNotEmpty;

        return Dialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // Tamamen köşeli
          ),
          elevation: 8,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 480),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.zero, // Tamamen köşeli
              border: Border.all(color: Colors.grey[200]!, width: 1),
              // Background image desteği
              image: showImage && imagePosition == 'background'
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(
                        imageUrl,
                        headers: HttpHeadersUtil.basicAuthHeaders(),
                      ),
                      fit: imageFit,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.3),
                        BlendMode.darken,
                      ),
                    )
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header - Sade ve kurumsal
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: showImage && imagePosition == 'background'
                        ? Colors.black.withOpacity(
                            0.7,
                          ) // Background resim varsa koyu overlay
                        : Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.zero, // Tamamen köşeli
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      // İkon - Sade ve köşeli
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(4), // Köşeli
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Başlık
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color:
                                    showImage && imagePosition == 'background'
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                                letterSpacing: -0.1,
                              ),
                        ),
                      ),

                      // Kapatma butonu - Minimal
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 0, 0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close,
                            color: const Color.fromARGB(255, 255, 255, 255),
                            size: 14,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content - Resim pozisyonuna göre layout
                Flexible(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: showImage && imagePosition == 'background'
                        ? BoxDecoration(
                            color: Colors.black.withOpacity(
                              0.6,
                            ), // Background resim varsa koyu overlay
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.zero, // Tamamen köşeli
                            ),
                          )
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Üst resim (position: top)
                        if (showImage && imagePosition == 'top') ...[
                          Center(
                            child: _buildAnnouncementImage(
                              imageUrl: imageUrl,
                              width: imageWidth,
                              height: imageHeight,
                              fit: imageFit,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Duyuru metni
                        Flexible(
                          child: SingleChildScrollView(
                            child: Text(
                              text,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color:
                                        showImage &&
                                            imagePosition == 'background'
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                    height: 1.5,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.1,
                                  ),
                            ),
                          ),
                        ),

                        // Alt resim (position: bottom)
                        if (showImage && imagePosition == 'bottom') ...[
                          const SizedBox(height: 16),
                          Center(
                            child: _buildAnnouncementImage(
                              imageUrl: imageUrl,
                              width: imageWidth,
                              height: imageHeight,
                              fit: imageFit,
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Footer - Buton alanı
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Primary Action Button - Küçük ve sade
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    6,
                                  ), // Köşeli
                                ),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                              ),
                              child: Text(
                                buttonText,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                      letterSpacing: 0.1,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Tam ekran görsel duyuru diyalogu (sadece resim)
class FullScreenImageAnnouncementDialog extends StatelessWidget {
  const FullScreenImageAnnouncementDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<RemoteConfigViewModel>(
      builder: (context, rc, child) {
        final imageUrl = rc.announcementImageUrl;

        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1)),
          elevation: 0,
          child: Stack(
            children: [
              // Kapatmak için herhangi bir yere dokunulabilir
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox.shrink(),
                ),
              ),

              // İçerik: Sadece görsel + çerçeve + görselin üzerinde X butonu
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width - 82,
                        maxHeight: MediaQuery.of(context).size.height - 82,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.primary, width: 4),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.transparent,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: AppNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -10,
                      right: -10,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: AppTheme.primary,
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: AppTheme.primary,
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
      },
    );
  }
}

/// Minimal announcement dialog - sadece metin ve tamam butonu
class SimpleAnnouncementDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;

  const SimpleAnnouncementDialog({
    Key? key,
    required this.title,
    required this.message,
    this.buttonText = 'Tamam',
  }) : super(key: key);

  /// Basit duyuru dialog'u gösterir
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'Tamam',
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => SimpleAnnouncementDialog(
        title: title,
        message: message,
        buttonText: buttonText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // Tamamen köşeli
      ),
      backgroundColor: AppTheme.surface,
      elevation: 6,
      titlePadding: const EdgeInsets.all(16),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(4), // Köşeli
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textPrimary,
          height: 1.5,
          letterSpacing: 0.1,
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6), // Köşeli
            ),
            elevation: 0,
          ),
          child: Text(
            buttonText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom Sheet style announcement
class AnnouncementBottomSheet extends StatelessWidget {
  const AnnouncementBottomSheet({Key? key}) : super(key: key);

  /// Bottom sheet olarak duyuru gösterir
  static Future<void> showIfNeeded(BuildContext context) async {
    try {
      final remoteConfigViewModel = context.read<RemoteConfigViewModel>();

      // Duyuru kontrolü yap
      final shouldShow = await remoteConfigViewModel.checkForAnnouncement();

      if (shouldShow && context.mounted) {
        Logger.info('📢 Duyuru bottom sheet gösteriliyor...');

        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) => const AnnouncementBottomSheet(),
        );

        // Bottom sheet kapatıldıktan sonra gösterildi olarak işaretle
        remoteConfigViewModel.markAnnouncementAsShown();
        Logger.info('✅ Duyuru gösterildi olarak işaretlendi');
      } else {
        Logger.debug('ℹ️ Gösterilecek duyuru yok veya kullanıcı zaten görmüş');
      }
    } catch (e) {
      Logger.error('❌ Duyuru bottom sheet gösterme hatası: $e', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RemoteConfigViewModel>(
      builder: (context, remoteConfigViewModel, child) {
        final title = remoteConfigViewModel.announcementTitle;
        final text = remoteConfigViewModel.announcementText;
        final buttonText = remoteConfigViewModel.announcementButtonText;

        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.zero, // Tamamen köşeli
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle - Sade
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 32,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header - Kurumsal ve sade
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(4), // Köşeli
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: -0.1,
                                  ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Message - Temiz tipografi
                      Text(
                        text,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textPrimary,
                          height: 1.5,
                          letterSpacing: 0.1,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Button - Sade ve köşeli
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6), // Köşeli
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            buttonText,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  letterSpacing: 0.1,
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
        );
      },
    );
  }
}
