import 'package:flutter/foundation.dart';
import '../models/trade.dart';
import '../services/trade_service.dart';
import '../services/auth_service.dart';
import '../core/constants.dart';
import '../utils/logger.dart';

class TradeViewModel extends ChangeNotifier {
  final TradeService _tradeService = TradeService();

  List<Trade> _trades = [];
  List<Trade> _pendingTrades = [];
  List<Trade> _completedTrades = [];
  List<Trade> _cancelledTrades = [];
  Trade? _selectedTrade;
  Map<String, int> _statistics = {};
  List<TradeStatusModel> _tradeStatuses = [];
  List<DeliveryType> _deliveryTypes = [];
  List<UserTrade> _userTrades = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  int _currentPage = 1;
  TradeStatus? _currentStatus;
  bool? _currentAsOfferer;

  // Getters
  List<Trade> get trades => _trades;
  List<Trade> get pendingTrades => _pendingTrades;
  List<Trade> get activeTrades =>
      _pendingTrades; // Aktif takaslar pending'le aynı
  List<Trade> get completedTrades => _completedTrades;
  List<Trade> get cancelledTrades => _cancelledTrades;
  Trade? get selectedTrade => _selectedTrade;
  Map<String, int> get statistics => _statistics;
  List<TradeStatusModel> get tradeStatuses => _tradeStatuses;
  List<DeliveryType> get deliveryTypes => _deliveryTypes;
  List<UserTrade> get userTrades => _userTrades;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  int get currentPage => _currentPage;
  TradeStatus? get currentStatus => _currentStatus;
  bool? get currentAsOfferer => _currentAsOfferer;

  TradeViewModel() {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    Logger.info('TradeViewModel başlatılıyor...', tag: 'TradeViewModel');
    
    // Takas durumlarını yükle
    await loadTradeStatuses();
    
    // Teslimat türlerini yükle
    await loadDeliveryTypes();
    
    // Kullanıcı takaslarını yükle (eğer kullanıcı giriş yapmışsa)
    // TODO: Kullanıcı ID'si alınıp loadUserTrades çağrılacak
    
    _setLoading(false);
    _clearError();
  }

  // Alias for loadInitialData for backward compatibility
  Future<void> fetchMyTrades() async {
    Logger.info('fetchMyTrades çağrıldı - Trade endpoints henüz implement edilmedi', tag: 'TradeViewModel');
    _setLoading(false);
    _clearError();
  }

  Future<void> loadTrades({
    TradeStatus? status,
    bool? asOfferer,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _trades.clear();
    }

    if (_isLoading || _isLoadingMore) return;

    _currentStatus = status;
    _currentAsOfferer = asOfferer;

    if (_currentPage == 1) {
      _setLoading(true);
    } else {
      _setLoadingMore(true);
    }

    _clearError();

    try {
      final response = await _tradeService.getMyTrades(
        page: _currentPage,
        limit: AppConstants.defaultPageSize,
        status: status,
        asOfferer: asOfferer,
      );

      if (response.isSuccess && response.data != null) {
        final newTrades = response.data!;

        if (_currentPage == 1) {
          _trades = newTrades;
        } else {
          _trades.addAll(newTrades);
        }

        _hasMore = newTrades.length == AppConstants.defaultPageSize;
        _currentPage++;
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);
      _setLoadingMore(false);
    }
  }

  Future<void> loadMoreTrades() async {
    if (!_hasMore || _isLoadingMore) return;

    await loadTrades(status: _currentStatus, asOfferer: _currentAsOfferer);
  }

  Future<void> refreshTrades() async {
    await loadTrades(
      status: _currentStatus,
      asOfferer: _currentAsOfferer,
      refresh: true,
    );
  }

  Future<void> loadPendingTrades() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _tradeService.getPendingTrades();

      if (response.isSuccess && response.data != null) {
        _pendingTrades = response.data!;
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCompletedTrades() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _tradeService.getCompletedTrades();

      if (response.isSuccess && response.data != null) {
        _completedTrades = response.data!;
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCancelledTrades() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _tradeService.getMyTrades(
        status: TradeStatus.cancelled,
      );

      if (response.isSuccess && response.data != null) {
        _cancelledTrades = response.data!;
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadTradeById(String tradeId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _tradeService.getTradeById(tradeId);

      if (response.isSuccess && response.data != null) {
        _selectedTrade = response.data;
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadStatistics() async {
    try {
      final response = await _tradeService.getTradeStatistics();

      if (response.isSuccess && response.data != null) {
        _statistics = response.data!;
        notifyListeners();
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
    }
  }

  Future<bool> createTrade({
    required String receiverUserId,
    required List<String> offeredProductIds,
    required List<String> requestedProductIds,
    String? message,
  }) async {
    if (offeredProductIds.isEmpty) {
      _setError('Teklif ettiğiniz ürünleri seçmelisiniz');
      return false;
    }

    if (requestedProductIds.isEmpty) {
      _setError('Talep ettiğiniz ürünleri seçmelisiniz');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _tradeService.createTrade(
        receiverUserId: receiverUserId,
        offeredProductIds: offeredProductIds,
        requestedProductIds: requestedProductIds,
        message: message,
      );

      if (response.isSuccess && response.data != null) {
        _trades.insert(0, response.data!);
        _selectedTrade = response.data;
        _setLoading(false);
        return true;
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> acceptTrade(String tradeId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _tradeService.acceptTrade(tradeId);

      if (response.isSuccess && response.data != null) {
        final updatedTrade = response.data!;
        _updateTradeInLists(updatedTrade);
        _selectedTrade = updatedTrade;
        _setLoading(false);
        return true;
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> rejectTrade(String tradeId, {String? reason}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _tradeService.rejectTrade(tradeId, reason: reason);

      if (response.isSuccess && response.data != null) {
        final updatedTrade = response.data!;
        _updateTradeInLists(updatedTrade);
        _selectedTrade = updatedTrade;
        _setLoading(false);
        return true;
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> cancelTrade(String tradeId, {String? reason}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _tradeService.cancelTrade(tradeId, reason: reason);

      if (response.isSuccess && response.data != null) {
        final updatedTrade = response.data!;
        _updateTradeInLists(updatedTrade);
        _selectedTrade = updatedTrade;
        _setLoading(false);
        return true;
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> completeTrade(String tradeId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _tradeService.completeTrade(tradeId);

      if (response.isSuccess && response.data != null) {
        final updatedTrade = response.data!;
        _updateTradeInLists(updatedTrade);
        _completedTrades.insert(0, updatedTrade);
        _selectedTrade = updatedTrade;
        _setLoading(false);
        return true;
      } else {
        _setError(response.error ?? ErrorMessages.unknownError);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return false;
    }
  }

  /// Takas başlatma metodu
  Future<bool> startTrade({
    required String userToken,
    required int senderProductID,
    required int receiverProductID,
    required int deliveryTypeID,
    String? meetingLocation,
  }) async {
    Logger.info('Takas başlatma işlemi başlatılıyor...', tag: 'TradeViewModel');
    
    _setLoading(true);
    _clearError();

    try {
      final response = await _tradeService.startTrade(
        userToken: userToken,
        senderProductID: senderProductID,
        receiverProductID: receiverProductID,
        deliveryTypeID: deliveryTypeID,
        meetingLocation: meetingLocation,
      );

      if (response.isSuccess && response.data != null) {
        Logger.info('Takas başlatma başarılı: ${response.data!.data?.message}', tag: 'TradeViewModel');
        
        // Başarılı işlem sonrası kullanıcı takaslarını yenile
        await _refreshUserTrades();
        
        _setLoading(false);
        return true;
      } else {
        final errorMsg = response.error ?? ErrorMessages.unknownError;
        Logger.error('Takas başlatma hatası: $errorMsg', tag: 'TradeViewModel');
        _setError(errorMsg);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      Logger.error('Takas başlatma exception: $e', tag: 'TradeViewModel');
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return false;
    }
  }

  void _updateTradeInLists(Trade updatedTrade) {
    // Update in all trades list
    final index = _trades.indexWhere((t) => t.id == updatedTrade.id);
    if (index != -1) {
      _trades[index] = updatedTrade;
    }

    // Update in pending trades list
    final pendingIndex = _pendingTrades.indexWhere(
      (t) => t.id == updatedTrade.id,
    );
    if (pendingIndex != -1) {
      if (updatedTrade.status == TradeStatus.pending) {
        _pendingTrades[pendingIndex] = updatedTrade;
      } else {
        _pendingTrades.removeAt(pendingIndex);
      }
    }

    // Update in completed trades list
    final completedIndex = _completedTrades.indexWhere(
      (t) => t.id == updatedTrade.id,
    );
    if (completedIndex != -1) {
      _completedTrades[completedIndex] = updatedTrade;
    }
  }

  void clearSelectedTrade() {
    _selectedTrade = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setLoadingMore(bool loading) {
    _isLoadingMore = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Takas durumlarını yükle
  Future<void> loadTradeStatuses() async {
    try {
      Logger.info('Takas durumları yükleniyor...', tag: 'TradeViewModel');
      
      final response = await _tradeService.getTradeStatuses();

      if (response.isSuccess && response.data != null) {
        _tradeStatuses = response.data!.data?.statuses ?? [];
        Logger.info('Takas durumları başarıyla yüklendi: ${_tradeStatuses.length} durum', tag: 'TradeViewModel');
        notifyListeners();
      } else {
        final errorMsg = response.error ?? ErrorMessages.unknownError;
        Logger.error('Takas durumları yükleme hatası: $errorMsg', tag: 'TradeViewModel');
        _setError(errorMsg);
      }
    } catch (e) {
      Logger.error('Takas durumları exception: $e', tag: 'TradeViewModel');
      _setError(ErrorMessages.unknownError);
    }
  }

  /// Status ID'ye göre status title'ı getir
  String getStatusTitleById(int statusId) {
    final status = _tradeStatuses.firstWhere(
      (s) => s.statusID == statusId,
      orElse: () => const TradeStatusModel(statusID: 0, statusTitle: 'Bilinmeyen'),
    );
    return status.statusTitle;
  }

  /// Status title'a göre status ID'yi getir
  int getStatusIdByTitle(String statusTitle) {
    final status = _tradeStatuses.firstWhere(
      (s) => s.statusTitle == statusTitle,
      orElse: () => const TradeStatusModel(statusID: 0, statusTitle: 'Bilinmeyen'),
    );
    return status.statusID;
  }

  /// Teslimat türlerini yükle
  Future<void> loadDeliveryTypes() async {
    try {
      Logger.info('Teslimat türleri yükleniyor...', tag: 'TradeViewModel');
      
      final response = await _tradeService.getDeliveryTypes();

      if (response.isSuccess && response.data != null) {
        _deliveryTypes = response.data!.data?.deliveryTypes ?? [];
        Logger.info('Teslimat türleri başarıyla yüklendi: ${_deliveryTypes.length} tür', tag: 'TradeViewModel');
        notifyListeners();
      } else {
        final errorMsg = response.error ?? ErrorMessages.unknownError;
        Logger.error('Teslimat türleri yükleme hatası: $errorMsg', tag: 'TradeViewModel');
        _setError(errorMsg);
      }
    } catch (e) {
      Logger.error('Teslimat türleri exception: $e', tag: 'TradeViewModel');
      _setError(ErrorMessages.unknownError);
    }
  }

  /// Delivery ID'ye göre delivery title'ı getir
  String getDeliveryTitleById(int deliveryId) {
    final delivery = _deliveryTypes.firstWhere(
      (d) => d.deliveryID == deliveryId,
      orElse: () => const DeliveryType(deliveryID: 0, deliveryTitle: 'Bilinmeyen'),
    );
    return delivery.deliveryTitle;
  }

  /// Delivery title'a göre delivery ID'yi getir
  int getDeliveryIdByTitle(String deliveryTitle) {
    final delivery = _deliveryTypes.firstWhere(
      (d) => d.deliveryTitle == deliveryTitle,
      orElse: () => const DeliveryType(deliveryID: 0, deliveryTitle: 'Bilinmeyen'),
    );
    return delivery.deliveryID;
  }

  /// Takas durumunu güncelle ve tamamla
  Future<bool> completeTradeWithStatus({
    required String userToken,
    required int offerID,
    required int statusID,
    String? meetingLocation,
    TradeReview? review,
  }) async {
    Logger.info('Takas durumu güncelleme işlemi başlatılıyor...', tag: 'TradeViewModel');
    
    _setLoading(true);
    _clearError();

    try {
      final response = await _tradeService.completeTradeWithStatus(
        userToken: userToken,
        offerID: offerID,
        statusID: statusID,
        meetingLocation: meetingLocation,
        review: review,
      );

      if (response.isSuccess && response.data != null) {
        Logger.info('Takas durumu güncelleme başarılı: ${response.data!.data?.message}', tag: 'TradeViewModel');
        _setLoading(false);
        return true;
      } else {
        final errorMsg = response.error ?? ErrorMessages.unknownError;
        Logger.error('Takas durumu güncelleme hatası: $errorMsg', tag: 'TradeViewModel');
        _setError(errorMsg);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      Logger.error('Takas durumu güncelleme exception: $e', tag: 'TradeViewModel');
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return false;
    }
  }

  /// Kullanıcının takaslarını yükle
  Future<void> loadUserTrades(int userId) async {
    try {
      Logger.info('Kullanıcı takasları yükleniyor... UserID: $userId', tag: 'TradeViewModel');
      
      final response = await _tradeService.getUserTrades(userId);

      if (response.isSuccess) {
        // Response data null olabilir, güvenli şekilde kontrol et
        if (response.data != null) {
          _userTrades = response.data!.data?.trades ?? [];
          Logger.info('Kullanıcı takasları başarıyla yüklendi: ${_userTrades.length} takas', tag: 'TradeViewModel');
        } else {
          // 410 durumunda data null olabilir, boş liste kullan
          _userTrades = [];
          Logger.info('410 durumu - Boş takas listesi kullanılıyor', tag: 'TradeViewModel');
        }
        _clearError();
        notifyListeners();
      } else {
        final errorMsg = response.error ?? ErrorMessages.unknownError;
        Logger.error('Kullanıcı takasları yükleme hatası: $errorMsg', tag: 'TradeViewModel');
        _setError(errorMsg);
      }
    } catch (e) {
      Logger.error('Kullanıcı takasları exception: $e', tag: 'TradeViewModel');
      _setError(ErrorMessages.unknownError);
    }
  }

  /// Duruma göre takasları filtrele
  List<UserTrade> getTradesByStatus(int statusId) {
    return _userTrades.where((trade) => trade.statusID == statusId).toList();
  }

  /// Duruma göre takasları filtrele (title ile)
  List<UserTrade> getTradesByStatusTitle(String statusTitle) {
    return _userTrades.where((trade) => trade.statusTitle == statusTitle).toList();
  }

  /// Offer ID'ye göre takas getir
  UserTrade? getTradeByOfferId(int offerId) {
    try {
      return _userTrades.firstWhere((trade) => trade.offerID == offerId);
    } catch (e) {
      return null;
    }
  }

  /// Takas onaylama metodu
  Future<bool> confirmTrade({
    required String userToken,
    required int offerID,
    required bool isConfirm,
    String? cancelDesc,
  }) async {
    Logger.info('Takas onaylama işlemi başlatılıyor... OfferID: $offerID, Onay: $isConfirm', tag: 'TradeViewModel');
    
    // Validasyon kontrolleri
    if (!isConfirm && (cancelDesc == null || cancelDesc.trim().isEmpty)) {
      _setError('Reddetme sebebi zorunludur');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _tradeService.confirmTrade(
        userToken: userToken,
        offerID: offerID,
        isConfirm: isConfirm,
        cancelDesc: cancelDesc,
      );

      if (response.isSuccess && response.data != null) {
        Logger.info('Takas onaylama başarılı: ${response.data!.data?.message}', tag: 'TradeViewModel');
        
        // Başarılı işlem sonrası kullanıcı takaslarını yenile
        await _refreshUserTrades();
        
        _setLoading(false);
        return true;
      } else {
        final errorMsg = response.error ?? ErrorMessages.unknownError;
        Logger.error('Takas onaylama hatası: $errorMsg', tag: 'TradeViewModel');
        _setError(errorMsg);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      Logger.error('Takas onaylama exception: $e', tag: 'TradeViewModel');
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return false;
    }
  }

  /// Kullanıcı takaslarını yenile
  Future<void> _refreshUserTrades() async {
    try {
      // Kullanıcı ID'sini al
      final authService = AuthService();
      final userId = await authService.getCurrentUserId();
      
      if (userId != null && userId.isNotEmpty) {
        await loadUserTrades(int.parse(userId));
        Logger.info('Kullanıcı takasları yenilendi', tag: 'TradeViewModel');
      }
    } catch (e) {
      Logger.error('Kullanıcı takasları yenileme hatası: $e', tag: 'TradeViewModel');
    }
  }

  /// Takas durumunu değiştir
  Future<bool> updateTradeStatus({
    required String userToken,
    required int offerID,
    required int newStatusID,
  }) async {
    Logger.info('Takas durumu güncelleniyor... OfferID: $offerID, Yeni Durum: $newStatusID', tag: 'TradeViewModel');

    _setLoading(true);
    _clearError();

    try {
      final response = await _tradeService.updateTradeStatus(
        userToken: userToken,
        offerID: offerID,
        statusID: newStatusID,
      );

      if (response.isSuccess && response.data != null) {
        Logger.info('Takas durumu güncelleme başarılı: ${response.data!.data?.message}', tag: 'TradeViewModel');
        
        // Başarılı işlem sonrası kullanıcı takaslarını yenile
        await _refreshUserTrades();
        
        _setLoading(false);
        return true;
      } else {
        final errorMsg = response.error ?? ErrorMessages.unknownError;
        Logger.error('Takas durumu güncelleme hatası: $errorMsg', tag: 'TradeViewModel');
        _setError(errorMsg);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      Logger.error('Takas durumu güncelleme exception: $e', tag: 'TradeViewModel');
      _setError(ErrorMessages.unknownError);
      _setLoading(false);
      return false;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
