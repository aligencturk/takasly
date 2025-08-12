import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/logger.dart';

class SocialAuthService {
  SocialAuthService._();
  static final SocialAuthService instance = SocialAuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      'profile',
    ],
    // iOS için özel konfigürasyon - iOS 14.0+ optimize edilmiş
    signInOption: SignInOption.standard,
    // iOS ve Android için clientId otomatik olarak GoogleService dosyalarından alınır
    clientId: null,
  );

  Future<String?> signInWithGoogleAndGetAccessToken() async {
    try {
      Logger.info('Google Sign-In başlatılıyor');

      // Önce mevcut oturumu temizle - güvenli başlangıç için
      await _googleSignIn.signOut();
      
      Logger.info('Google Sign-In oturumu başlatılıyor...');
      
      // Yeni oturum başlat - iOS 14.0+ optimize edilmiş
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        Logger.warning('Google Sign-In iptal edildi veya kullanıcı seçilmedi');
        return null;
      }

      Logger.info('Google hesabı seçildi: ${account.email}');

      // Authentication token alımı - iOS 14.0+ için optimize edilmiş
      final auth = await account.authentication;
      final accessToken = auth.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        Logger.error('Google accessToken alınamadı');
        return null;
      }

      Logger.info(
        'Google accessToken alındı (ilk 10): ${accessToken.substring(0, 10)}...',
      );
      return accessToken;
    } catch (e, s) {
      Logger.error('Google Sign-In hatası: $e', stackTrace: s);
      
      // Hata detaylarını logla - iOS 14.0+ için optimize edilmiş hata yönetimi
      String errorType = 'unknown';
      if (e.toString().contains('network') || e.toString().contains('Network')) {
        errorType = 'network';
        Logger.error('Ağ hatası - internet bağlantısını kontrol edin', stackTrace: s);
      } else if (e.toString().contains('cancelled') || e.toString().contains('cancel')) {
        errorType = 'cancelled';
        Logger.warning('Google Sign-In kullanıcı tarafından iptal edildi');
      } else if (e.toString().contains('popup_closed') || e.toString().contains('popup')) {
        errorType = 'popup_closed';
        Logger.warning('Google Sign-In popup kapatıldı');
      } else if (e.toString().contains('sign_in_failed') || e.toString().contains('configuration')) {
        errorType = 'config';
        Logger.error('Google Sign-In konfigürasyon hatası - GoogleService-Info.plist kontrol edin', stackTrace: s);
      } else if (Platform.isIOS && e.toString().contains('keychain')) {
        errorType = 'keychain';
        Logger.error('iOS Keychain hatası - cihaz ayarlarını kontrol edin', stackTrace: s);
      }
      
      Logger.info('Hata tipi belirlendi: $errorType');
      
      // Bir sonraki deneme için temiz bir oturum sağlamak adına signOut dene
      try {
        await _googleSignIn.signOut();
        Logger.debug('Google Sign-In oturumu temizlendi');
      } catch (cleanupError) {
        Logger.warning('Google Sign-In oturum temizleme hatası: $cleanupError');
      }
      
      return null;
    }
  }
}
