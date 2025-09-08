import 'package:flutter/material.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/logger.dart';

class AppUpdateService {
  AppUpdateService._internal();
  static final AppUpdateService instance = AppUpdateService._internal();

  Future<void> checkAndPromptUpdate(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final packageName = packageInfo.packageName;

      final newVersion = NewVersionPlus(
        androidId: packageName,
        iOSId: packageName,
      );

      final status = await newVersion.getVersionStatus();
      if (status == null) {
        Logger.info('Güncelleme durumu alınamadı (null)');
        return;
      }

      Logger.info(
        'Versiyon durumu: current=${status.localVersion} store=${status.storeVersion} canUpdate=${status.canUpdate}',
      );

      if (!status.canUpdate) return;

      if (!context.mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.system_update, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Yeni sürüm mevcut',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mevcut: ${status.localVersion}  •  Mağaza: ${status.storeVersion}',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).maybePop(),
                          child: const Text('Daha sonra'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final url = Uri.parse(status.appStoreLink);
                            try {
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              } else {
                                Logger.warning('Mağaza bağlantısı açılamadı: ${status.appStoreLink}');
                              }
                            } catch (e, s) {
                              Logger.error('Mağaza bağlantısı açılırken hata: $e', error: e, stackTrace: s);
                            }
                          },
                          child: const Text('Güncelle'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      );
    } catch (e, s) {
      Logger.error('Güncelleme kontrolünde hata: $e', error: e, stackTrace: s);
    }
  }
}


