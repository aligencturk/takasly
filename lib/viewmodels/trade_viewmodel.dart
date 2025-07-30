import 'package:flutter/foundation.dart';
import '../models/trade.dart';
import '../services/trade_service.dart';
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
    // Temporarily disable trade loading since endpoints don't exist
    // TODO: Implement when trade endpoints are available
    print(
      '🔄 TradeViewModel.loadInitialData - Trade endpoints not implemented yet',
    );
    _setLoading(false);
    _clearError();
  }

  // Alias for loadInitialData for backward compatibility
  Future<void> fetchMyTrades() async {
    print(
      '🔄 TradeViewModel.fetchMyTrades - Trade endpoints not implemented yet',
    );
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

  @override
  void dispose() {
    super.dispose();
  }
}
