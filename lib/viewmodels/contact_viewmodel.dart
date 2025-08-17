import 'package:flutter/foundation.dart';
import '../models/contact_subject.dart';
import '../services/contact_service.dart';
import '../services/user_service.dart';
import '../core/constants.dart';
import '../utils/logger.dart';

class ContactViewModel extends ChangeNotifier {
  final ContactService _contactService = ContactService();
  final UserService _userService = UserService();

  List<ContactSubject> _subjects = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  String? _successMessage;

  // Getters
  List<ContactSubject> get subjects => _subjects;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasError => _errorMessage != null;
  bool get hasSuccess => _successMessage != null;

  ContactViewModel() {
    _loadContactSubjects();
  }

  /// İletişim konularını yükler
  Future<void> _loadContactSubjects() async {
    _setLoading(true);
    _clearMessages();

    try {
      Logger.debug(
        'ContactViewModel - Loading contact subjects...',
        tag: 'ContactViewModel',
      );

      final response = await _contactService.getContactSubjects();

      if (response.isSuccess && response.data != null) {
        _subjects = response.data!;
        Logger.info(
          'ContactViewModel - ${_subjects.length} subjects loaded',
          tag: 'ContactViewModel',
        );
      } else {
        Logger.error(
          'ContactViewModel - Failed to load subjects: ${response.error}',
          tag: 'ContactViewModel',
        );
        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      Logger.error(
        'ContactViewModel - Load subjects exception: $e',
        tag: 'ContactViewModel',
      );
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);
    }
  }

  /// İletişim konularını yeniden yükler
  Future<void> refreshSubjects() async {
    await _loadContactSubjects();
  }

  /// İletişim mesajı gönderir
  Future<bool> sendMessage({
    required int subjectID,
    required String userName,
    required String userEmail,
    required String message,
  }) async {
    Logger.debug(
      'ContactViewModel - Sending message...',
      tag: 'ContactViewModel',
    );
    Logger.debug(
      'Parameters: subjectID=$subjectID, userName=$userName, userEmail=$userEmail',
      tag: 'ContactViewModel',
    );

    // Validation
    if (userName.trim().isEmpty) {
      _setError('İsim alanı zorunludur');
      return false;
    }

    if (userEmail.trim().isEmpty) {
      _setError('E-posta alanı zorunludur');
      return false;
    }

    if (!_isValidEmail(userEmail)) {
      _setError('Geçerli bir e-posta adresi giriniz');
      return false;
    }

    if (message.trim().isEmpty) {
      _setError('Mesaj alanı zorunludur');
      return false;
    }

    if (message.trim().length < 10) {
      _setError('Mesaj en az 10 karakter olmalıdır');
      return false;
    }

    if (message.trim().length > 1000) {
      _setError('Mesaj en fazla 1000 karakter olabilir');
      return false;
    }

    // Konu kontrolü
    if (!_subjects.any((subject) => subject.subjectID == subjectID)) {
      _setError('Geçerli bir konu seçiniz');
      return false;
    }

    final token = await _userService.getUserToken();
    if (token == null || token.isEmpty) {
      _setError(ErrorMessages.sessionExpired);
      return false;
    }

    _setSending(true);
    _clearMessages();

    try {
      final response = await _contactService.sendContactMessage(
        userToken: token,
        subjectID: subjectID,
        userName: userName.trim(),
        userEmail: userEmail.trim(),
        message: message.trim(),
      );

      if (response.isSuccess &&
          response.data != null &&
          response.data!.isNotEmpty) {
        final responseData = response.data!;
        final successMessage =
            responseData['success_message']?.toString() ??
            'Mesajınız başarıyla gönderildi. En kısa sürede size dönüş yapacağız.';
        final messageId = responseData['message_id']?.toString() ?? '';

        Logger.info(
          'ContactViewModel - Message sent successfully with ID: $messageId',
          tag: 'ContactViewModel',
        );

        _setSuccess(successMessage);
        return true;
      } else {
        Logger.error(
          'ContactViewModel - Failed to send message: ${response.error}',
          tag: 'ContactViewModel',
        );
        _setError(
          response.error ?? 'Mesaj gönderilemedi. Lütfen tekrar deneyin.',
        );
        return false;
      }
    } catch (e) {
      Logger.error(
        'ContactViewModel - Send message exception: $e',
        tag: 'ContactViewModel',
      );
      _setError('Mesaj gönderilemedi. Lütfen tekrar deneyin.');
      return false;
    } finally {
      _setSending(false);
    }
  }

  /// E-posta formatını kontrol eder
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Subject ID'den subject nesnesini bulur
  ContactSubject? getSubjectById(int subjectID) {
    try {
      return _subjects.firstWhere((subject) => subject.subjectID == subjectID);
    } catch (e) {
      return null;
    }
  }

  /// Subject title'ından subject nesnesini bulur
  ContactSubject? getSubjectByTitle(String title) {
    try {
      return _subjects.firstWhere(
        (subject) => subject.subjectTitle.toLowerCase() == title.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Mesajları temizler
  void clearMessages() {
    _clearMessages();
  }

  /// Hata mesajını temizler
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Başarı mesajını temizler
  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setSending(bool sending) {
    _isSending = sending;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _successMessage = null; // Clear success when setting error
    notifyListeners();
  }

  void _setSuccess(String success) {
    _successMessage = success;
    _errorMessage = null; // Clear error when setting success
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
