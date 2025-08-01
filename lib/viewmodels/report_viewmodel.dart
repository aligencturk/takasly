import 'package:flutter/foundation.dart';
import '../services/report_service.dart';
import '../utils/logger.dart';

class ReportViewModel extends ChangeNotifier {
  final ReportService _reportService = ReportService();
  static const String _tag = 'ReportViewModel';

  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isReportSuccess = false;

  // Getters
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  bool get isReportSuccess => _isReportSuccess;

  /// Kullanıcı şikayet etme
  Future<bool> reportUser({
    required String userToken,
    required int reportedUserID,
    required String reason,
    int? productID,
    int? offerID,
  }) async {
    try {
      Logger.info('ReportViewModel: Kullanıcı şikayet başlatılıyor...', tag: _tag);
      
      _setLoading(true);
      _clearError();
      _isReportSuccess = false;

      final response = await _reportService.reportUser(
        userToken: userToken,
        reportedUserID: reportedUserID,
        reason: reason,
        productID: productID,
        offerID: offerID,
      );

      if (response.isSuccess) {
        Logger.info('ReportViewModel: Şikayet başarılı', tag: _tag);
        _isReportSuccess = true;
        _setLoading(false);
        return true;
      } else {
        Logger.error('ReportViewModel: Şikayet hatası - ${response.error}', tag: _tag);
        _setError(response.error ?? 'Şikayet gönderilemedi');
        return false;
      }
    } catch (e) {
      Logger.error('ReportViewModel: Şikayet exception - $e', tag: _tag);
      _setError('Beklenmeyen bir hata oluştu');
      return false;
    }
  }

  /// Loading durumunu ayarla
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Hata durumunu ayarla
  void _setError(String error) {
    _hasError = true;
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  /// Hata durumunu temizle
  void _clearError() {
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }

  /// Başarı durumunu sıfırla
  void resetSuccess() {
    _isReportSuccess = false;
    notifyListeners();
  }

  /// Tüm durumları sıfırla
  void reset() {
    _isLoading = false;
    _hasError = false;
    _errorMessage = '';
    _isReportSuccess = false;
    notifyListeners();
  }
} 