import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takasly/core/app_theme.dart';
import 'package:takasly/models/user.dart';
import 'package:takasly/viewmodels/user_viewmodel.dart';
import 'package:takasly/widgets/loading_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:takasly/utils/phone_formatter.dart';
import 'dart:io';
import 'dart:convert';

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
  final _birthdayController = TextEditingController();
  
  String? _selectedGender;
  File? _selectedImage;
  bool _isLoading = false;
  
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
      print('🔄 EditProfile - Image converted to base64, size: ${bytes.length} bytes');
      return dataUrl;
    } catch (e) {
      print('❌ EditProfile - Error converting image to base64: $e');
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
      print('🔄 EditProfile - Loading user data: ${user.name}');
      print('🔄 EditProfile - firstName: ${user.firstName}');
      print('🔄 EditProfile - lastName: ${user.lastName}');
      print('🔄 EditProfile - email: ${user.email}');
      
      setState(() {
        _firstNameController.text = user.firstName ?? '';
        _lastNameController.text = user.lastName ?? '';
        _emailController.text = user.email;
        _phoneController.text = user.phone != null && user.phone!.isNotEmpty 
            ? PhoneFormatter.formatPhoneNumber(user.phone!) 
            : '';
        _birthdayController.text = user.birthday ?? '';
        _selectedGender = user.gender?.toString();
      });
    } else {
      print('⚠️ EditProfile - No user data available, refreshing...');
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
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        
        // Kullanıcıya bilgi ver
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil fotoğrafı seçildi: ${image.path.split('/').last}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        print('🔄 EditProfile - Image selected: ${image.path}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resim seçilirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _birthdayController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
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
      
      print('🔄 EditProfile - Updating account with:');
      print('🔄 firstName: ${_firstNameController.text}');
      print('🔄 lastName: ${_lastNameController.text}');
      print('🔄 email: ${_emailController.text}');
      
      // Profil fotoğrafını base64 formatına dönüştür
      String? profilePhotoBase64;
      if (_selectedImage != null) {
        print('🔄 EditProfile - Converting selected image to base64...');
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
        print('✅ EditProfile - Image successfully converted to base64');
        print('📏 EditProfile - Base64 string length: ${profilePhotoBase64.length}');
      } else {
        print('ℹ️ EditProfile - No new image selected, keeping existing photo');
      }
      
      final result = await userViewModel.updateAccount(
        userFirstname: _firstNameController.text,
        userLastname: _lastNameController.text,
        userEmail: _emailController.text,
        userPhone: PhoneFormatter.prepareForApi(_phoneController.text),
        userBirthday: _birthdayController.text,
        userGender: _selectedGender != null ? int.tryParse(_selectedGender!) : null,
        profilePhoto: profilePhotoBase64,
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
             Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
             
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(
                 content: Text('Oturum süresi doldu. Lütfen tekrar giriş yapın.'),
                 backgroundColor: Colors.orange,
               ),
             );
           } else {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text(errorMessage ?? 'Profil güncellenirken hata oluştu'),
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
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
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
                    _buildDateField(),
                    const SizedBox(height: 16),
                    _buildGenderDropdown(),
                    const SizedBox(height: 32),
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
            child: _selectedImage == null && (user?.avatar == null || user!.avatar!.isEmpty)
                ? const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.grey,
                  )
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
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: label == 'Telefon' ? [PhoneFormatter.phoneMask] : null,
      validator: validator ?? (label == 'Telefon' ? (value) {
        if (value != null && value.isNotEmpty && !PhoneFormatter.isValidPhoneNumber(value)) {
          return 'Geçerli bir telefon numarası girin (0(5XX) XXX XX XX)';
        }
        return null;
      } : null),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        hintText: label == 'Telefon' ? '0(5XX) XXX XX XX' : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _birthdayController,
      readOnly: true,
      onTap: _selectDate,
      decoration: InputDecoration(
        labelText: 'Doğum Tarihi',
        prefixIcon: const Icon(Icons.calendar_today),
        suffixIcon: const Icon(Icons.arrow_drop_down),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      onChanged: (String? newValue) {
        setState(() {
          _selectedGender = newValue;
        });
      },
      decoration: InputDecoration(
        labelText: 'Cinsiyet',
        prefixIcon: const Icon(Icons.person_pin),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primary, width: 2),
        ),
      ),
      items: const [
        DropdownMenuItem(
          value: 'Erkek',
          child: Text('Erkek'),
        ),
        DropdownMenuItem(
          value: 'Kadın',
          child: Text('Kadın'),
        ),
        DropdownMenuItem(
          value: 'Belirtilmemiş',
          child: Text('Belirtilmemiş'),
        ),
      ],
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}