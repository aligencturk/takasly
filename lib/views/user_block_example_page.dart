import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_viewmodel.dart';
import '../widgets/user_block_button.dart';
import '../utils/logger.dart';

class UserBlockExamplePage extends StatefulWidget {
  const UserBlockExamplePage({Key? key}) : super(key: key);

  @override
  State<UserBlockExamplePage> createState() => _UserBlockExamplePageState();
}

class _UserBlockExamplePageState extends State<UserBlockExamplePage> {
  final List<Map<String, dynamic>> _exampleUsers = [
    {
      'id': 1,
      'name': 'Ahmet Yılmaz',
      'email': 'ahmet@example.com',
      'avatar': 'https://via.placeholder.com/50',
    },
    {
      'id': 2,
      'name': 'Fatma Demir',
      'email': 'fatma@example.com',
      'avatar': 'https://via.placeholder.com/50',
    },
    {
      'id': 3,
      'name': 'Mehmet Kaya',
      'email': 'mehmet@example.com',
      'avatar': 'https://via.placeholder.com/50',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kullanıcı Engelleme Örneği'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<UserViewModel>(
        builder: (context, userViewModel, child) {
          return Column(
            children: [
              // Bilgi kartı
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[600],
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kullanıcı Engelleme',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Bu sayfada kullanıcı engelleme özelliğini test edebilirsiniz. Engellenen kullanıcılar artık sizinle iletişim kuramayacak.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Hata mesajı
              if (userViewModel.hasError)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[600],
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          userViewModel.errorMessage ?? 'Bilinmeyen hata',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Kullanıcı listesi
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _exampleUsers.length,
                  itemBuilder: (context, index) {
                    final user = _exampleUsers[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 25,
                              backgroundImage: NetworkImage(user['avatar']),
                              onBackgroundImageError: (exception, stackTrace) {
                                Logger.error('Avatar loading error: $exception', tag: 'UserBlockExamplePage');
                              },
                            ),
                            SizedBox(width: 16),
                            
                            // Kullanıcı bilgileri
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['name'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    user['email'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Engelleme butonları
                            Column(
                              children: [
                                // Ana engelleme butonu
                                UserBlockButton(
                                  userId: user['id'],
                                  userName: user['name'],
                                  onUserBlocked: () {
                                    Logger.info('User ${user['name']} blocked successfully', tag: 'UserBlockExamplePage');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${user['name']} engellendi'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(height: 8),
                                
                                // Küçük engelleme butonu
                                UserBlockSmallButton(
                                  userId: user['id'],
                                  userName: user['name'],
                                  onUserBlocked: () {
                                    Logger.info('User ${user['name']} blocked via small button', tag: 'UserBlockExamplePage');
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      
      // Floating action button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Manuel test için
          final userViewModel = context.read<UserViewModel>();
          userViewModel.blockUser(
            blockedUserID: 999,
            reason: 'Test amaçlı engelleme',
          ).then((success) {
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Test kullanıcısı engellendi'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          });
        },
        icon: Icon(Icons.block),
        label: Text('Test Engelleme'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
    );
  }
}
