import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../core/constants.dart';
import '../../models/user.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  int _selectedTabIndex = 0;

  User _createDummyUser() {
    return User(
      id: 'dummy_001',
      name: 'Test Kullanıcı',
      firstName: 'Test',
      lastName: 'Kullanıcı',
      email: 'test@takasly.com',
      phone: '0555 123 45 67',
      avatar: null,
      bio: 'Bu bir test kullanıcısıdır.',
      location: null,
      rating: 4.5,
      totalTrades: 12,
      isVerified: true,
      isOnline: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
      lastSeenAt: DateTime.now(),
      birthday: '01.01.1990',
      gender: 1, // Erkek
    );
  }

  @override
  void initState() {
    super.initState();
    // Profil sayfası açıldığında kullanıcı bilgilerini kontrol et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      if (userViewModel.currentUser == null) {
        userViewModel.forceRefreshUser();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Profil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer<UserViewModel>(
            builder: (context, userViewModel, child) {
              return IconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                ),
                onPressed: userViewModel.isLoading 
                    ? null 
                    : () async {
                        await userViewModel.forceRefreshUser();
                      },
              );
            },
          ),
        ],
      ),
      body: Consumer<UserViewModel>(
        builder: (context, userViewModel, child) {
          // Debug bilgisi
          print('🔍 ProfileView - User: ${userViewModel.currentUser?.name}, IsLoading: ${userViewModel.isLoading}');
          print('🔍 ProfileView - Error: ${userViewModel.errorMessage}');
          print('🔍 ProfileView - Selected Tab: $_selectedTabIndex');
          
          if (userViewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF10B981),
              ),
            );
          }

          var user = userViewModel.currentUser;
          
          // Eğer user null ise dummy user kullan
          if (user == null) {
            print('⚠️ ProfileView - Using dummy user for display');
            user = _createDummyUser();
          }
          
          // User hala null ise (bu durumda olmaz ama safety için)
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_off,
                    size: 64,
                    color: Colors.white70,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Kullanıcı bilgileri yüklenemedi',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  if (userViewModel.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Hata: ${userViewModel.errorMessage}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      await userViewModel.forceRefreshUser();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Yeniden Dene'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Test kullanıcısı oluştur
                      userViewModel.setCurrentUser(_createDummyUser());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Test Kullanıcısı Yükle'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Profil Header
              _buildProfileHeader(user, userViewModel),
              
              // Tab Bar
              _buildTabBar(),
              
              // Tab Content
              Expanded(
                child: _buildTabContent(user, userViewModel),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(User user, UserViewModel userViewModel) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFF374151),
                backgroundImage: user.avatar != null 
                    ? NetworkImage(user.avatar!)
                    : null,
                child: user.avatar == null
                    ? const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white70,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      // Fotoğraf güncelleme
                    },
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Kullanıcı bilgileri
          Text(
            user.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            user.email,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // İstatistikler
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('Takas', user.totalTrades.toString()),
              _buildStatCard('Puan', user.rating.toStringAsFixed(1)),
              _buildStatCard(
                'Durum', 
                user.isVerified ? 'Doğrulanmış' : 'Beklemede'
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabButton('Profil', 0, Icons.person),
          _buildTabButton('Şifre', 1, Icons.lock),
          _buildTabButton('Hesap', 2, Icons.settings),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white70,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(User user, UserViewModel userViewModel) {
    print('🔍 ProfileView - Building tab content for index: $_selectedTabIndex');
    print('🔍 ProfileView - User for tab: ${user.name}');
    
    switch (_selectedTabIndex) {
      case 0:
        print('🔍 ProfileView - Rendering ProfileEditTab');
        return _ProfileEditTab(user: user, userViewModel: userViewModel);
      case 1:
        print('🔍 ProfileView - Rendering PasswordUpdateTab');
        return _PasswordUpdateTab(userViewModel: userViewModel);
      case 2:
        print('🔍 ProfileView - Rendering AccountSettingsTab');
        return _AccountSettingsTab(userViewModel: userViewModel);
      default:
        print('🔍 ProfileView - Rendering default SizedBox');
        return const SizedBox();
    }
  }
}

// Profil Düzenleme Tab'ı
class _ProfileEditTab extends StatefulWidget {
  final User user;
  final UserViewModel userViewModel;

  const _ProfileEditTab({
    required this.user,
    required this.userViewModel,
  });

  @override
  State<_ProfileEditTab> createState() => _ProfileEditTabState();
}

class _ProfileEditTabState extends State<_ProfileEditTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _birthdayController;
  int? _selectedGender;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.user.lastName ?? '');
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _birthdayController = TextEditingController(text: widget.user.birthday ?? '');
    _selectedGender = widget.user.gender;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 ProfileEditTab - Building with user: ${widget.user.name}');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            // Ad alanı
            _buildTextFormField(
              controller: _firstNameController,
              label: 'Ad',
              icon: Icons.person_outline,
            ),
            
            const SizedBox(height: 16),
            
            // Soyad alanı
            _buildTextFormField(
              controller: _lastNameController,
              label: 'Soyad',
              icon: Icons.person_outline,
            ),
            
            const SizedBox(height: 16),
            
            // E-posta alanı
            _buildTextFormField(
              controller: _emailController,
              label: 'E-posta',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            
            const SizedBox(height: 16),
            
            // Telefon alanı
            _buildTextFormField(
              controller: _phoneController,
              label: 'Telefon',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            
            const SizedBox(height: 16),
            
            // Doğum tarihi alanı
            _buildTextFormField(
              controller: _birthdayController,
              label: 'Doğum Tarihi (DD.MM.YYYY)',
              icon: Icons.calendar_today,
              readOnly: true,
              onTap: () => _selectBirthday(),
            ),
            
            const SizedBox(height: 16),
            
            // Cinsiyet dropdown
            _buildGenderDropdown(),
            
            const SizedBox(height: 32),
            
            // Güncelle butonu
            Container(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: widget.userViewModel.isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: widget.userViewModel.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Profili Güncelle',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white70),
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF374151),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedGender,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Cinsiyet',
        prefixIcon: const Icon(Icons.wc, color: Colors.white70),
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF374151),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
      ),
      dropdownColor: const Color(0xFF374151),
      items: Gender.getGenderOptions().map((option) {
        return DropdownMenuItem<int>(
          value: option['value'],
          child: Text(
            option['text'],
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedGender = value;
        });
      },
    );
  }

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981),
              surface: Color(0xFF374151),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate = '${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}';
      _birthdayController.text = formattedDate;
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      final success = await widget.userViewModel.updateAccount(
        userFirstname: _firstNameController.text.trim(),
        userLastname: _lastNameController.text.trim(),
        userEmail: _emailController.text.trim(),
        userPhone: _phoneController.text.trim(),
        userBirthday: _birthdayController.text.trim(),
        userGender: _selectedGender,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil başarıyla güncellendi'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.userViewModel.errorMessage ?? 'Güncelleme başarısız'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Şifre Güncelleme Tab'ı
class _PasswordUpdateTab extends StatefulWidget {
  final UserViewModel userViewModel;

  const _PasswordUpdateTab({required this.userViewModel});

  @override
  State<_PasswordUpdateTab> createState() => _PasswordUpdateTabState();
}

class _PasswordUpdateTabState extends State<_PasswordUpdateTab> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isOldPasswordObscure = true;
  bool _isNewPasswordObscure = true;
  bool _isConfirmPasswordObscure = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 PasswordUpdateTab - Building tab');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            const Text(
              'Şifre Değiştir',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Mevcut şifre alanı
            _buildPasswordField(
              controller: _oldPasswordController,
              label: 'Mevcut Şifre',
              isObscure: _isOldPasswordObscure,
              onToggleVisibility: () {
                setState(() {
                  _isOldPasswordObscure = !_isOldPasswordObscure;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Mevcut şifre gereklidir';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Yeni şifre alanı
            _buildPasswordField(
              controller: _newPasswordController,
              label: 'Yeni Şifre',
              isObscure: _isNewPasswordObscure,
              onToggleVisibility: () {
                setState(() {
                  _isNewPasswordObscure = !_isNewPasswordObscure;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Yeni şifre gereklidir';
                }
                if (value.length < 6) {
                  return 'Şifre en az 6 karakter olmalıdır';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Şifre onay alanı
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'Yeni Şifre (Tekrar)',
              isObscure: _isConfirmPasswordObscure,
              onToggleVisibility: () {
                setState(() {
                  _isConfirmPasswordObscure = !_isConfirmPasswordObscure;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Şifre onayı gereklidir';
                }
                if (value != _newPasswordController.text) {
                  return 'Şifreler eşleşmiyor';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 32),
            
            // Şifre güncelle butonu
            Container(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: widget.userViewModel.isLoading ? null : _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: widget.userViewModel.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Şifreyi Güncelle',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isObscure,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      obscureText: isObscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
        suffixIcon: IconButton(
          icon: Icon(
            isObscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.white70,
          ),
          onPressed: onToggleVisibility,
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF374151),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
      ),
    );
  }

  Future<void> _updatePassword() async {
    if (_formKey.currentState!.validate()) {
      final success = await widget.userViewModel.updateUserPassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifre başarıyla güncellendi'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        
        // Alanları temizle
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.userViewModel.errorMessage ?? 'Şifre güncelleme başarısız'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Hesap Ayarları Tab'ı
class _AccountSettingsTab extends StatelessWidget {
  final UserViewModel userViewModel;

  const _AccountSettingsTab({required this.userViewModel});

  @override
  Widget build(BuildContext context) {
    print('🔍 AccountSettingsTab - Building tab');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          
          const Text(
            'Hesap Ayarları',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Çıkış yap butonu
          _buildActionButton(
            icon: Icons.logout,
            title: 'Çıkış Yap',
            subtitle: 'Hesabınızdan güvenli şekilde çıkış yapın',
            color: Colors.orange,
            onTap: () => _showLogoutDialog(context),
          ),
          
          const SizedBox(height: 16),
          
          // Hesabı sil butonu
          _buildActionButton(
            icon: Icons.delete_forever,
            title: 'Hesabı Sil',
            subtitle: 'Hesabınızı kalıcı olarak silin',
            color: Colors.red,
            onTap: () => _showDeleteAccountDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF374151),
          title: const Text(
            'Çıkış Yap',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await userViewModel.logout();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              child: const Text(
                'Çıkış Yap',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF374151),
          title: const Text(
            'Hesabı Sil',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bu işlem geri alınamaz! Hesabınızı silmek için şifrenizi girin.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                style: const TextStyle(color: Colors.white),
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                if (passwordController.text.isNotEmpty) {
                  Navigator.pop(context);
                  
                  final success = await userViewModel.deleteUserAccount(
                    password: passwordController.text,
                  );
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hesap başarıyla silindi'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(userViewModel.errorMessage ?? 'Hesap silme başarısız'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Hesabı Sil',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
} 