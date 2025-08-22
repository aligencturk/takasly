import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takasly/core/app_theme.dart';
import 'package:takasly/viewmodels/user_viewmodel.dart';
import 'package:takasly/widgets/loading_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:takasly/services/image_optimization_service.dart';
import 'package:takasly/utils/phone_formatter.dart';
import 'package:takasly/utils/logger.dart';
import 'dart:io';
import 'dart:convert';
import 'package:takasly/widgets/profanity_check_text_field.dart';
import '../auth/login_view.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({Key? key}) : super(key: key);

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;
  // Telefon numarası görünürlüğü ayarı kaldırıldı

  final ImagePicker _picker = ImagePicker();

  /// Profil fotoğrafını base64 formatına dönüştürür
  String? _convertImageToBase64(File imageFile) {
    try {
      final bytes = imageFile.readAsBytesSync();
      final base64String = base64Encode(bytes);

      // Dosya uzantısını belirle
      String mimeType = 'image/jpeg'; // Varsayılan
      final fileName = imageFile.path.toLowerCase();
      if (fileName.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (fileName.endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (fileName.endsWith('.webp')) {
        mimeType = 'image/webp';
      }

      final dataUrl = 'data:$mimeType;base64,$base64String';
      Logger.debug(
        'Image converted to base64, size: ${bytes.length} bytes',
        tag: 'EditProfile',
      );
      return dataUrl;
    } catch (e) {
      Logger.error('Error converting image to base64: $e', tag: 'EditProfile');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    // Widget oluşturulduktan sonra veri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final user = userViewModel.currentUser;

    if (user != null) {
      Logger.debug('Loading user data: ${user.name}', tag: 'EditProfile');
      Logger.debug('firstName: ${user.firstName}', tag: 'EditProfile');
      Logger.debug('lastName: ${user.lastName}', tag: 'EditProfile');
      Logger.debug('email: ${user.email}', tag: 'EditProfile');
      // gender alanı uygulamadan kaldırıldı

      setState(() {
        _firstNameController.text = user.firstName ?? '';
        _lastNameController.text = user.lastName ?? '';
        _emailController.text = user.email;
        _phoneController.text = user.phone != null && user.phone!.isNotEmpty
            ? PhoneFormatter.formatPhoneNumber(user.phone!)
            : '';

        // Telefon numarası görünürlük ayarı kaldırıldığı için yüklenmiyor
      });
    } else {
      Logger.warning(
        'No user data available, refreshing...',
        tag: 'EditProfile',
      );
      // Kullanıcı verisi yoksa yenile
      userViewModel.forceRefreshUser().then((_) {
        if (mounted) {
          _loadUserData();
        }
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        // Backend optimizasyon yapacağı için yüksek kalite seçiliyor
        imageQuality: 100,
      );

      if (image != null) {
        // Kullanıcıya dönüşüm başladığını bildir
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil fotoğrafı seçiliyor...'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Seçilen görseli optimize et
        Logger.debug(
          '🖼️ EditProfileView - Converting profile image...',
          tag: 'EditProfile',
        );
        final File convertedFile =
            await ImageOptimizationService.convertSingleXFileToFile(image);

        setState(() {
          _selectedImage = convertedFile;
        });

        // Kullanıcıya dönüşüm tamamlandığını bildir
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil fotoğrafı seçildi'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        Logger.debug(
          'Profile image converted and selected: ${convertedFile.path}',
          tag: 'EditProfile',
        );
      }
    } catch (e) {
      Logger.error(
        'Error selecting and optimizing image: $e',
        tag: 'EditProfile',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resim seçilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);

      Logger.debug('Updating account with:', tag: 'EditProfile');
      Logger.debug(
        'firstName: ${_firstNameController.text}',
        tag: 'EditProfile',
      );
      Logger.debug('lastName: ${_lastNameController.text}', tag: 'EditProfile');
      Logger.debug('email: ${_emailController.text}', tag: 'EditProfile');

      // Profil fotoğrafını base64 formatına dönüştür
      String? profilePhotoBase64;
      if (_selectedImage != null) {
        Logger.debug(
          'Converting selected image to base64...',
          tag: 'EditProfile',
        );
        profilePhotoBase64 = _convertImageToBase64(_selectedImage!);
        if (profilePhotoBase64 == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil fotoğrafı işlenirken hata oluştu'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        Logger.info(
          'Image successfully converted to base64',
          tag: 'EditProfile',
        );
        Logger.debug(
          'Base64 string length: ${profilePhotoBase64.length}',
          tag: 'EditProfile',
        );
      } else {
        Logger.info(
          'No new image selected, keeping existing photo',
          tag: 'EditProfile',
        );
      }

      final result = await userViewModel.updateAccount(
        userFirstname: _firstNameController.text,
        userLastname: _lastNameController.text,
        userEmail: _emailController.text,
        userPhone: PhoneFormatter.prepareForApi(_phoneController.text),
        profilePhoto: profilePhotoBase64,
        // Telefon numarası görünürlüğü kaldırıldığı için gönderilmiyor
      );

      if (mounted) {
        if (result) {
          // Profil güncellemesi başarılı olduğunda kullanıcı verilerini yenile
          await userViewModel.forceRefreshUser();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil başarıyla güncellendi'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Başarılı güncelleme sinyali gönder
        } else {
          // Güncelleme başarısız - hata mesajını kontrol et
          final errorMessage = userViewModel.errorMessage;

          // 401 hatası veya oturum süresi dolmuş hatası kontrolü
          if (errorMessage != null &&
              (errorMessage.contains('Kimlik doğrulama hatası') ||
                  errorMessage.contains('Oturum süresi doldu') ||
                  errorMessage.contains('Yetkisiz giriş'))) {
            // Login sayfasına yönlendir
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  errorMessage ?? 'Profil güncellenirken hata oluştu',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil güncellenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.delete_forever,
                color: Colors.red[700],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Hesabı Sil'),
          ],
        ),
        content: const Text(
          'Hesabınızı kalıcı olarak silmek istediğinizden emin misiniz?\n\n'
          'Bu işlem geri alınamaz ve tüm verileriniz silinecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    Navigator.pop(dialogContext);
                    await _deleteAccount();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hesabı Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Logger.debug('Hesap silme işlemi başlatılıyor...', tag: 'EditProfile');

      final userViewModel = Provider.of<UserViewModel>(context, listen: false);

      final success = await userViewModel.deleteUserAccountNew();

      if (success) {
        Logger.debug('Hesap başarıyla silindi', tag: 'EditProfile');

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const LoginView(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOutCubic,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
              transitionDuration: const Duration(milliseconds: 400),
            ),
            (route) => false,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hesabınız başarıyla silindi'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception(
          userViewModel.errorMessage ?? 'Hesap silme işlemi başarısız',
        );
      }
    } catch (e) {
      Logger.error('Hesap silme hatası: $e', tag: 'EditProfile');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hesap silme işlemi başarısız: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<UserViewModel>(
        builder: (context, userViewModel, child) {
          return _isLoading || userViewModel.isLoading
              ? const LoadingWidget()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildProfileImageSection(),
                        const SizedBox(height: 24),
                        _buildTextFormField(
                          controller: _firstNameController,
                          label: 'Ad',
                          icon: Icons.person,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ad alanı boş bırakılamaz';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                          controller: _lastNameController,
                          label: 'Soyad',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Soyad alanı boş bırakılamaz';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                          controller: _emailController,
                          label: 'E-posta',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'E-posta alanı boş bırakılamaz';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Geçerli bir e-posta adresi girin';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                          controller: _phoneController,
                          label: 'Telefon',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            onTap: _isLoading ? null : _showDeleteAccountDialog,
                            child: Text(
                              'Hesabı Sil',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildUpdateButton(),
                      ],
                    ),
                  ),
                );
        },
      ),
    );
  }

  Widget _buildProfileImageSection() {
    final userViewModel = Provider.of<UserViewModel>(context);
    final user = userViewModel.currentUser;

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[300],
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!)
                : (user?.avatar != null && user!.avatar!.isNotEmpty)
                ? NetworkImage(user.avatar!)
                : null,
            child:
                _selectedImage == null &&
                    (user?.avatar == null || user!.avatar!.isEmpty)
                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _pickImage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    // Telefon alanı için özel widget
    if (label == 'Telefon') {
      return TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: TextCapitalization.none,
        inputFormatters: const [],
        validator:
            validator ??
            (value) {
              if (value != null &&
                  value.isNotEmpty &&
                  !PhoneFormatter.isValidPhoneNumber(value)) {
                return 'Geçerli bir telefon numarası girin (0(5XX) XXX XX XX)';
              }
              return null;
            },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          hintText: '05XXXXXXXXX',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primary, width: 2),
          ),
        ),
      );
    }

    // E-posta alanı için özel widget
    if (label == 'E-posta') {
      return TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: TextCapitalization.none,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primary, width: 2),
          ),
        ),
      );
    }

    // Ad ve soyad alanları için ProfanityCheckTextField
    return ProfanityCheckTextField(
      controller: controller,
      labelText: label,
      prefixIcon: Icon(icon),
      textCapitalization: TextCapitalization.words,
      sensitivity: 'medium',
      validator: validator,
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Profili Güncelle',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
