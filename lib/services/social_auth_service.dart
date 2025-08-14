import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../utils/logger.dart';

class SocialAuthService {
  SocialAuthService._();
  static final SocialAuthService instance = SocialAuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      'profile',
      'openid', // idToken için gerekli
    ],
    // iOS için özel konfigürasyon - iOS 14.0+ optimize edilmiş
    signInOption: SignInOption.standard,
    // iOS için clientId belirtilmeli - GoogleService-Info.plist'ten CLIENT_ID değeri
    clientId: Platform.isIOS 
        ? '422264804561-llio284tijfqkh873at3ci09fna2epl0.apps.googleusercontent.com'
        : null, // Android için null bırak
  );

  Future<Map<String, String?>?> signInWithGoogleAndGetTokens() async {
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
      final idToken = auth.idToken;
      
      if (accessToken == null || accessToken.isEmpty) {
        Logger.error('Google accessToken alınamadı');
        return null;
      }

      if (idToken == null || idToken.isEmpty) {
        Logger.error('Google idToken alınamadı');
        return null;
      }

      Logger.info(
        'Google tokenları alındı - accessToken (ilk 10): ${accessToken.substring(0, 10)}..., idToken (ilk 10): ${idToken.substring(0, 10)}...',
      );
      
      return {
        'accessToken': accessToken,
        'idToken': idToken,
        'email': account.email,
        'displayName': account.displayName,
      };
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

  Future<Map<String, String?>?> signInWithAppleAndGetTokens() async {
    try {
      if (!Platform.isIOS) {
        Logger.warning('Apple Sign-In yalnızca iOS üzerinde desteklenir');
        return null;
      }

      Logger.info('Apple Sign-In başlatılıyor');

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final String? identityToken = credential.identityToken;

      if (identityToken == null || identityToken.isEmpty) {
        Logger.error('Apple idToken alınamadı');
        return null;
      }

      final String? email = credential.email;
      final String? givenName = credential.givenName;
      final String? familyName = credential.familyName;
      final String displayName = [givenName, familyName]
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .join(' ');

      Logger.info(
        'Apple token alındı - idToken (ilk 10): ${identityToken.substring(0, 10)}...',
      );

      return {
        'idToken': identityToken,
        'email': email,
        'displayName': displayName.isEmpty ? null : displayName,
      };
    } catch (e, s) {
      Logger.error('Apple Sign-In hatası: $e', stackTrace: s);
      return null;
    }
  }
}
