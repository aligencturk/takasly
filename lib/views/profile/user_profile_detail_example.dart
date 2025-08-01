import 'package:flutter/material.dart';
import 'user_profile_detail_view.dart';

/// Kullanıcı profil detayları sayfasının kullanım örneği
/// 
/// Bu sayfa, başka bir kullanıcının profilini görüntülemek için kullanılır.
/// Genellikle ürün detaylarından veya chat sayfalarından yönlendirilir.
/// 
/// Kullanım:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => UserProfileDetailView(
///       userId: 2,
///       userToken: "kullanici_token_buraya",
///     ),
///   ),
/// );
/// ```
class UserProfileDetailExample extends StatelessWidget {
  const UserProfileDetailExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Detayı Örneği'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Kullanıcı Profil Detayları',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bu sayfa, başka bir kullanıcının profilini görüntülemek için kullanılır.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Örnek kullanım - gerçek uygulamada userToken dinamik olarak alınır
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserProfileDetailView(
                      userId: 2, // Görüntülenecek kullanıcının ID'si
                      userToken: "example_token", // Gerçek uygulamada SharedPreferences'dan alınır
                    ),
                  ),
                );
              },
              child: const Text('Profil Detayını Görüntüle'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Not: Gerçek uygulamada userToken SharedPreferences\'dan alınmalıdır.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Gerçek uygulamada kullanım için helper fonksiyon
/// 
/// Bu fonksiyon, SharedPreferences'dan userToken'ı alır ve
/// profil detayları sayfasına yönlendirir.
/// 
/// Kullanım:
/// ```dart
/// await navigateToUserProfile(context, userId: 2);
/// ```
Future<void> navigateToUserProfile(
  BuildContext context, {
  required int userId,
}) async {
  // SharedPreferences'dan userToken'ı al
  // final prefs = await SharedPreferences.getInstance();
  // final userToken = prefs.getString('user_token');
  
  // Örnek için sabit token kullanıyoruz
  const userToken = "example_user_token";
  
  if (userToken != null && userToken.isNotEmpty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileDetailView(
          userId: userId,
          userToken: userToken,
        ),
      ),
    );
  } else {
    // Token yoksa login sayfasına yönlendir
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Oturum açmanız gerekiyor'),
      ),
    );
  }
} 