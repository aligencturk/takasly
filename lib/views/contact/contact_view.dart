import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/contact_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../models/contact_subject.dart';
import '../../core/app_theme.dart';
import '../../utils/logger.dart';

class ContactView extends StatefulWidget {
  const ContactView({super.key});

  @override
  State<ContactView> createState() => _ContactViewState();
}

class _ContactViewState extends State<ContactView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  ContactSubject? _selectedSubject;

  @override
  void initState() {
    super.initState();
    Logger.info('ContactView initialized', tag: 'ContactView');
    _loadUserData();
  }

  void _loadUserData() {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final user = userViewModel.currentUser;

    if (user != null) {
      // Kullanıcı bilgilerini form alanlarına doldur
      String fullName = '';
      if (user.firstName != null && user.lastName != null) {
        fullName = '${user.firstName!} ${user.lastName!}'.trim();
      } else if (user.name.isNotEmpty) {
        fullName = user.name;
      }

      _nameController.text = fullName;
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'İletişim',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 20),
        ),
      ),
      body: Consumer<ContactViewModel>(
        builder: (context, contactViewModel, child) {
          if (contactViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildContactForm(contactViewModel),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.support_agent, color: AppTheme.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bizimle İletişime Geçin',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sorularınızı ve önerilerinizi bize iletebilirsiniz',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactForm(ContactViewModel contactViewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'İletişim Formu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // Konu Seçimi
            _buildSubjectDropdown(contactViewModel),
            const SizedBox(height: 16),

            // Ad Soyad
            _buildNameField(),
            const SizedBox(height: 16),

            // E-posta
            _buildEmailField(),
            const SizedBox(height: 16),

            // Mesaj
            _buildMessageField(),
            const SizedBox(height: 20),

            // Hata/Başarı Mesajları
            if (contactViewModel.hasError || contactViewModel.hasSuccess)
              _buildMessageAlert(contactViewModel),

            // Gönder Butonu
            _buildSendButton(contactViewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectDropdown(ContactViewModel contactViewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Konu',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ContactSubject>(
          value: _selectedSubject,
          decoration: InputDecoration(
            hintText: 'Konu seçiniz',
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          items: contactViewModel.subjects.map((subject) {
            return DropdownMenuItem<ContactSubject>(
              value: subject,
              child: Text(
                subject.subjectTitle,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            );
          }).toList(),
          onChanged: (ContactSubject? newValue) {
            setState(() {
              _selectedSubject = newValue;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Lütfen bir konu seçiniz';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ad Soyad',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Adınızı ve soyadınızı giriniz',
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ad soyad alanı zorunludur';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'E-posta',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'E-posta adresinizi giriniz',
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'E-posta alanı zorunludur';
            }
            if (!RegExp(
              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
            ).hasMatch(value)) {
              return 'Geçerli bir e-posta adresi giriniz';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mesaj',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _messageController,
          maxLines: 5,
          maxLength: 1000,
          decoration: InputDecoration(
            hintText: 'Mesajınızı buraya yazınız...',
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Mesaj alanı zorunludur';
            }
            if (value.trim().length < 10) {
              return 'Mesaj en az 10 karakter olmalıdır';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMessageAlert(ContactViewModel contactViewModel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: contactViewModel.hasError ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: contactViewModel.hasError
              ? Colors.red[200]!
              : Colors.green[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            contactViewModel.hasError
                ? Icons.error_outline
                : Icons.check_circle_outline,
            color: contactViewModel.hasError
                ? Colors.red[700]
                : Colors.green[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              contactViewModel.hasError
                  ? contactViewModel.errorMessage!
                  : contactViewModel.successMessage!,
              style: TextStyle(
                color: contactViewModel.hasError
                    ? Colors.red[700]
                    : Colors.green[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton(ContactViewModel contactViewModel) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: contactViewModel.isSending ? null : _sendMessage,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          disabledBackgroundColor: Colors.grey[300],
        ),
        child: contactViewModel.isSending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Mesajı Gönder',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  void _sendMessage() async {
    // Mesajları temizle
    final contactViewModel = Provider.of<ContactViewModel>(
      context,
      listen: false,
    );
    contactViewModel.clearMessages();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSubject == null) {
      contactViewModel.clearError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir konu seçiniz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await contactViewModel.sendMessage(
      subjectID: _selectedSubject!.subjectID,
      userName: _nameController.text.trim(),
      userEmail: _emailController.text.trim(),
      message: _messageController.text.trim(),
    );

    if (success) {
      // Form alanlarını temizle
      _messageController.clear();
      _selectedSubject = null;
      setState(() {});

      // Klavyeyi kapat
      FocusScope.of(context).unfocus();

      // 3 saniye sonra geri dön
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }
}
