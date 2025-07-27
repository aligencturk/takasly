import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart';
import '../utils/logger.dart';

class FirebaseAuthService {
  static const String _tag = 'FirebaseAuthService';
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final Logger _logger = Logger();

  // Mevcut kullanıcıyı al
  firebase_auth.User? get currentUser => _auth.currentUser;

  // Auth state değişikliklerini dinle
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Email/Password ile giriş
  Future<firebase_auth.UserCredential> signInWithEmailAndPassword(
    String email, 
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      Logger.info('Firebase giriş başarılı: ${credential.user?.email}', tag: _tag);
      return credential;
    } catch (e) {
      Logger.error('Firebase giriş hatası: $e', tag: _tag);
      rethrow;
    }
  }

  // Email/Password ile kayıt
  Future<firebase_auth.UserCredential> createUserWithEmailAndPassword(
    String email, 
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      Logger.info('Firebase kayıt başarılı: ${credential.user?.email}', tag: _tag);
      return credential;
    } catch (e) {
      Logger.error('Firebase kayıt hatası: $e', tag: _tag);
      rethrow;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      Logger.info('Firebase çıkış başarılı', tag: _tag);
    } catch (e) {
      Logger.error('Firebase çıkış hatası: $e', tag: _tag);
      rethrow;
    }
  }

  // Kullanıcı ID token'ını al
  Future<String?> getIdToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        return token;
      }
      return null;
    } catch (e) {
      Logger.error('Token alma hatası: $e', tag: _tag);
      return null;
    }
  }

  // Kullanıcı profilini güncelle
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.updatePhotoURL(photoURL);
        Logger.info('Profil güncellendi', tag: _tag);
      }
    } catch (e) {
      Logger.error('Profil güncelleme hatası: $e', tag: _tag);
      rethrow;
    }
  }
} 