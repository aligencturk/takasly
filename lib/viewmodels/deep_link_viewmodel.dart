import 'package:flutter/material.dart';
import '../services/deep_link_service.dart';
import '../utils/logger.dart';

/// Deep Link ViewModel
/// Deep link işlemlerini yönetir ve UI'a bildirim gönderir
class DeepLinkViewModel extends ChangeNotifier {
  final DeepLinkService _deepLinkService = DeepLinkService();
  
  /// Deep link ile gelen product ID
  String? _pendingProductId;
  
  /// Deep link işleniyor mu?
  bool _isProcessing = false;
  
  /// Deep link hatası var mı?
  bool _hasError = false;
  
  /// Hata mesajı
  String? _errorMessage;
  
  // Getters
  String? get pendingProductId => _pendingProductId;
  bool get isProcessing => _isProcessing;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  
  /// ViewModel'i başlat
  Future<void> initialize() async {
    try {
      Logger.info('Deep Link ViewModel başlatılıyor...');
      
      // Deep link callback'ini ayarla
      _deepLinkService.onDeepLinkReceived = _handleDeepLinkReceived;
      
      // Deep link servisini başlat
      await _deepLinkService.initialize();
      
      Logger.info('Deep Link ViewModel başarıyla başlatıldı');
    } catch (e) {
      Logger.error('Deep Link ViewModel başlatılırken hata: $e');
      _setError('Deep link servisi başlatılamadı: $e');
    }
  }
  
  /// Deep link alındığında çağrılır
  void _handleDeepLinkReceived(String productId) {
    try {
      Logger.info('Deep link ViewModel\'de işleniyor. Product ID: $productId');
      
      _setProcessing(true);
      _pendingProductId = productId;
      _clearError();
      
      notifyListeners();
      
      Logger.info('Deep link başarıyla işlendi. Product ID: $productId');
    } catch (e) {
      Logger.error('Deep link işlenirken hata: $e');
      _setError('Deep link işlenirken hata oluştu: $e');
    } finally {
      _setProcessing(false);
    }
  }
  
  /// Pending product ID'yi temizle
  void clearPendingProductId() {
    _pendingProductId = null;
    notifyListeners();
  }
  
  /// Processing durumunu ayarla
  void _setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }
  
  /// Hata durumunu ayarla
  void _setError(String message) {
    _hasError = true;
    _errorMessage = message;
    notifyListeners();
  }
  
  /// Hata durumunu temizle
  void _clearError() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Hata durumunu manuel olarak temizle
  void clearError() {
    _clearError();
  }
  
  @override
  void dispose() {
    try {
      _deepLinkService.dispose();
      Logger.info('Deep Link ViewModel dispose edildi');
    } catch (e) {
      Logger.error('Deep Link ViewModel dispose edilirken hata: $e');
    }
    super.dispose();
  }
}
