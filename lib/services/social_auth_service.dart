import 'package:google_sign_in/google_sign_in.dart';
import '../utils/logger.dart';

class SocialAuthService {
  SocialAuthService._();
  static final SocialAuthService instance = SocialAuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      'profile',
      // Gerekirse ek scope'lar buraya eklenebilir
    ],
  );

  Future<String?> signInWithGoogleAndGetAccessToken() async {
    try {
      Logger.info('Google Sign-In başlatılıyor');

      GoogleSignInAccount? account = _googleSignIn.currentUser;
      account ??= await _googleSignIn.signIn();
      if (account == null) {
        Logger.warning('Google Sign-In iptal edildi veya kullanıcı seçilmedi');
        return null;
      }

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
      // Bir sonraki deneme için temiz bir oturum sağlamak adına signOut dene
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      return null;
    }
  }
}
