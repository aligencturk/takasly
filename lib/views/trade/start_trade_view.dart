import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../viewmodels/trade_viewmodel.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../models/product.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../utils/logger.dart';
import '../../services/auth_service.dart';

class StartTradeView extends StatefulWidget {
  final Product receiverProduct;

  const StartTradeView({
    super.key,
    required this.receiverProduct,
  });

  @override
  State<StartTradeView> createState() => _StartTradeViewState();
}

class _StartTradeViewState extends State<StartTradeView> {
  Product? _selectedSenderProduct;
  int _selectedDeliveryType = 1; // Varsayılan: Elden Teslim
  final TextEditingController _meetingLocationController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Logger.info('StartTradeView başlatıldı', tag: 'StartTradeView');
    
    // Kullanıcının ürünlerini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProducts();
    });
  }

  Future<void> _loadUserProducts() async {
    try {
      final userId = await _authService.getCurrentUserId();
      if (userId != null) {
        final productViewModel = Provider.of<ProductViewModel>(context, listen: false);
        await productViewModel.loadUserProducts(userId);
        Logger.info('Kullanıcı ürünleri yüklendi: ${productViewModel.myProducts.length} ürün', tag: 'StartTradeView');
      } else {
        Logger.error('Kullanıcı ID bulunamadı', tag: 'StartTradeView');
      }
    } catch (e) {
      Logger.error('Kullanıcı ürünleri yükleme hatası: $e', tag: 'StartTradeView');
    }
  }

  @override
  void dispose() {
    _meetingLocationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
        ),
        title: Text(
          'Takas Başlat',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<ProductViewModel>(
        builder: (context, productViewModel, child) {
          if (productViewModel.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (productViewModel.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    productViewModel.errorMessage ?? 'Bir hata oluştu',
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadUserProducts(),
                    child: Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alıcı ürün kartı
                _buildReceiverProductCard(),
                
                SizedBox(height: 24),
                
                // Takas etmek istediğiniz ürün
                _buildSenderProductSection(productViewModel),
                
                SizedBox(height: 24),
                
                // Teslimat türü
                _buildDeliveryTypeSection(),
                
                SizedBox(height: 24),
                
                // Buluşma yeri (sadece elden teslim için)
                if (_selectedDeliveryType == 1) ...[
                  _buildMeetingLocationSection(),
                  SizedBox(height: 24),
                ],
                
                // Mesaj
                _buildMessageSection(),
                
                SizedBox(height: 32),
                
                // Takas başlat butonu
                _buildStartTradeButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReceiverProductCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.swap_horiz_outlined,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Takas Etmek İstediğiniz Ürün',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Ürün resmi
          if (widget.receiverProduct.images.isNotEmpty)
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade200,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.receiverProduct.images.first,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.image_not_supported,
                        color: AppTheme.primary,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
            ),
          
          SizedBox(height: 12),
          
          // Ürün bilgileri
          Text(
            widget.receiverProduct.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            widget.receiverProduct.description,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.receiverProduct.condition,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderProductSection(ProductViewModel productViewModel) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedSenderProduct != null 
                      ? 'Ürün Seçildi' 
                      : 'Takas Edeceğiniz Ürün',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _selectedSenderProduct != null 
                        ? AppTheme.primary 
                        : AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Seçili ürün gösterimi
          if (_selectedSenderProduct != null) ...[
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade200,
                    ),
                    child: _selectedSenderProduct!.images.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _selectedSenderProduct!.images.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.image_not_supported, color: Colors.grey.shade400);
                              },
                            ),
                          )
                        : Icon(Icons.image_not_supported, color: Colors.grey.shade400),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seçili Ürün:',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _selectedSenderProduct!.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedSenderProduct = null;
                      });
                    },
                    icon: Icon(Icons.close, color: AppTheme.textSecondary, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],
          
          if (_selectedSenderProduct == null) ...[
            if (productViewModel.myProducts.isEmpty)
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Henüz ürününüz yok',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Takas yapabilmek için önce ilan eklemelisiniz',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: productViewModel.myProducts.length,
              itemBuilder: (context, index) {
                final product = productViewModel.myProducts[index];
                final isSelected = _selectedSenderProduct?.id == product.id;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSenderProduct = product;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ürün resmi
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                              color: Colors.grey.shade200,
                            ),
                            child: product.images.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                    child: Image.network(
                                      product.images.first,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey.shade400,
                                        );
                                      },
                                    ),
                                  )
                                : Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey.shade400,
                                  ),
                          ),
                        ),
                        
                        // Ürün bilgileri
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.title,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  product.condition,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryTypeSection() {
    return Consumer<TradeViewModel>(
      builder: (context, tradeViewModel, child) {
        final deliveryTypes = tradeViewModel.deliveryTypes;
        
        if (deliveryTypes.isEmpty) {
          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  SizedBox(height: 12),
                  Text(
                    'Teslimat türleri yükleniyor...',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.local_shipping_outlined,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Teslimat Türü',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              
              // Dinamik teslimat türleri
              ...deliveryTypes.map((deliveryType) {
                final isSelected = _selectedDeliveryType == deliveryType.deliveryID;
                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDeliveryType = deliveryType.deliveryID;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.primary.withOpacity(0.1) 
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                              ? AppTheme.primary 
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getDeliveryTypeIcon(deliveryType.deliveryID),
                            color: isSelected 
                                ? AppTheme.primary 
                                : Colors.grey.shade600,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              deliveryType.deliveryTitle,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected 
                                    ? AppTheme.primary 
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: AppTheme.primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  IconData _getDeliveryTypeIcon(int deliveryId) {
    switch (deliveryId) {
      case 1: // Elden Teslim
        return Icons.people_outline;
      case 2: // Kapıya Teslim
        return Icons.home_outlined;
      default:
        return Icons.local_shipping_outlined;
    }
  }

  Widget _buildMeetingLocationSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Buluşma Yeri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          TextField(
            controller: _meetingLocationController,
            decoration: InputDecoration(
              hintText: 'Örn: İstanbul / Kadıköy',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primary),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.message_outlined,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Mesaj (İsteğe Bağlı)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Takas teklifinizle ilgili bir mesaj yazabilirsiniz...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primary),
              ),
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartTradeButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _startTrade,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                else
                  Icon(Icons.swap_horiz, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  _isLoading ? 'Takas Başlatılıyor...' : 'Takas Başlat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startTrade() async {
    // Validasyon
    if (_selectedSenderProduct == null) {
      _showError('Lütfen takas edeceğiniz ürünü seçin');
      return;
    }

    if (_selectedDeliveryType == 1 && _meetingLocationController.text.trim().isEmpty) {
      _showError('Elden teslim için buluşma yeri zorunludur');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // User token'ı al
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString(AppConstants.userTokenKey);

      if (userToken == null || userToken.isEmpty) {
        _showError('Kullanıcı oturumu bulunamadı. Lütfen tekrar giriş yapın.');
        return;
      }

      final tradeViewModel = Provider.of<TradeViewModel>(context, listen: false);
      
      final success = await tradeViewModel.startTrade(
        userToken: userToken,
        senderProductID: int.parse(_selectedSenderProduct!.id),
        receiverProductID: int.parse(widget.receiverProduct.id),
        deliveryTypeID: _selectedDeliveryType,
        meetingLocation: _selectedDeliveryType == 1 
            ? _meetingLocationController.text.trim() 
            : null,
      );

      if (success) {
        Logger.info('Takas başarıyla başlatıldı', tag: 'StartTradeView');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Takas teklifi başarıyla gönderildi'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          
          Navigator.pop(context, true); // Başarılı sonuç döndür
        }
      } else {
        final errorMsg = tradeViewModel.errorMessage ?? 'Takas başlatılamadı';
        _showError(errorMsg);
      }
    } catch (e) {
      Logger.error('Takas başlatma hatası: $e', tag: 'StartTradeView');
      _showError('Beklenmeyen bir hata oluştu');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
} 