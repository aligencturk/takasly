import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/trade_viewmodel.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../services/auth_service.dart';
import '../../core/constants.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/product_card.dart';

class TradeView extends StatefulWidget {
  const TradeView({super.key});

  @override
  State<TradeView> createState() => _TradeViewState();
}

class _TradeViewState extends State<TradeView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    print('🔄 TradeView initState called');
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔄 TradeView postFrameCallback - calling _loadData');
      _loadData();
    });
  }

  Future<void> _loadData() async {
    print('🔄 TradeView _loadData started');
    
    // Önce kullanıcının login olup olmadığını kontrol et
    final isLoggedIn = await _authService.isLoggedIn();
    print('🔍 TradeView - Is user logged in: $isLoggedIn');
    
    if (!isLoggedIn) {
      print('❌ TradeView - User not logged in, showing error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oturum süresi doldu. Lütfen tekrar giriş yapın.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    final tradeViewModel = Provider.of<TradeViewModel>(context, listen: false);
    final productViewModel = Provider.of<ProductViewModel>(context, listen: false);
    
    print('🔄 TradeView - calling tradeViewModel.fetchMyTrades()');
    tradeViewModel.fetchMyTrades();
    
    // Dinamik kullanıcı ID'sini al
    print('🔄 TradeView - getting current user ID');
    final userId = await _authService.getCurrentUserId();
    print('🔍 TradeView - User ID: $userId');
    
    if (userId != null && userId.isNotEmpty) {
      print('🔄 TradeView - calling productViewModel.loadUserProducts($userId)');
      await productViewModel.loadUserProducts(userId);
    } else {
      print('❌ TradeView - User ID is null or empty, user might not be logged in');
      print('❌ TradeView - Redirecting to login or showing error');
      
      // Kullanıcı login olmamışsa hata göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen giriş yapın'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    print('🔄 TradeView _loadData completed');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Takaslarım'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Aktif'),
            Tab(text: 'Tamamlanan'),
            Tab(text: 'İptal Edilen'),
          ],
        ),
      ),
      body: Consumer2<TradeViewModel, ProductViewModel>(
        builder: (context, tradeViewModel, productViewModel, child) {
          print('🎨 TradeView Consumer2 builder called');
          print('🎨 TradeView - tradeViewModel.isLoading: ${tradeViewModel.isLoading}');
          print('🎨 TradeView - productViewModel.isLoading: ${productViewModel.isLoading}');
          print('🎨 TradeView - tradeViewModel.hasError: ${tradeViewModel.hasError}');
          print('🎨 TradeView - productViewModel.hasError: ${productViewModel.hasError}');
          print('🎨 TradeView - productViewModel.myProducts.length: ${productViewModel.myProducts.length}');
          
          if (tradeViewModel.isLoading || productViewModel.isLoading) {
            print('🎨 TradeView - Showing loading widget');
            return const LoadingWidget();
          }

          // Sadece her iki ViewModel'de de hata varsa error göster
          if (tradeViewModel.hasError && productViewModel.hasError) {
            print('🎨 TradeView - Showing error widget (both have errors)');
            return CustomErrorWidget(
              message: tradeViewModel.errorMessage ?? productViewModel.errorMessage!,
              onRetry: _loadData,
            );
          }

          print('🎨 TradeView - Building TabBarView');
          return TabBarView(
            controller: _tabController,
            children: [
              // Aktif tab - ProductViewModel kullan
              productViewModel.hasError 
                ? CustomErrorWidget(
                    message: productViewModel.errorMessage!,
                    onRetry: _loadData,
                  )
                : _buildUserProductsList(productViewModel.myProducts),
              
              // Tamamlanan tab - TradeViewModel kullan
              tradeViewModel.hasError 
                ? CustomErrorWidget(
                    message: tradeViewModel.errorMessage!,
                    onRetry: _loadData,
                  )
                : _buildTradeList(tradeViewModel.completedTrades),
              
              // İptal edilen tab - TradeViewModel kullan
              tradeViewModel.hasError 
                ? CustomErrorWidget(
                    message: tradeViewModel.errorMessage!,
                    onRetry: _loadData,
                  )
                : _buildTradeList(tradeViewModel.cancelledTrades),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewTradeDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUserProductsList(List<dynamic> products) {
    print('🎨 TradeView._buildUserProductsList called with ${products.length} products');
    
    if (products.isEmpty) {
      print('🎨 TradeView - No products, showing empty state');
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Henüz ürün eklemediniz',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Takas yapmak için ürün ekleyin',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    print('🎨 TradeView - Building grid with ${products.length} products');
    for (int i = 0; i < products.length; i++) {
      final product = products[i];
      print('🎨 Product $i: ${product.toString()}');
    }

    return RefreshIndicator(
      onRefresh: () async {
        final productViewModel = Provider.of<ProductViewModel>(context, listen: false);
        final userId = await _authService.getCurrentUserId();
        if (userId != null) {
          await productViewModel.loadUserProducts(userId);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            print('🎨 Building ProductCard for index $index: ${product.title}');
            return ProductCard(
              product: product,
              onTap: () {
                print('🎨 ProductCard tapped: ${product.title}');
                // Ürün detaylarını modal ile göster
                _showProductDetails(product);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTradeList(List<dynamic> trades) {
    if (trades.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swap_horiz,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Henüz takas yok',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final tradeViewModel = Provider.of<TradeViewModel>(context, listen: false);
        await tradeViewModel.fetchMyTrades();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: trades.length,
        itemBuilder: (context, index) {
          final trade = trades[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: ListTile(
              title: Text(trade.toString()),
              subtitle: Text('Takas #${index + 1}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Takas detayına git
              },
            ),
          );
        },
      ),
    );
  }

  void _showTradeDetails(dynamic trade) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Takas Detayları'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ID: ${trade['id'] ?? 'N/A'}'),
            Text('Durum: ${trade['status'] ?? 'Bilinmiyor'}'),
            Text('Tarih: ${trade['createdAt'] ?? 'Bilinmiyor'}'),
            Text('Açıklama: ${trade['description'] ?? 'Açıklama yok'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showProductDetails(dynamic product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          product.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ürün resmi (eğer varsa)
              if (product.images.isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade200,
                  ),
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              
              if (product.images.isNotEmpty) const SizedBox(height: 16),
              
              // Açıklama
              const Text(
                'Açıklama:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.description.isNotEmpty 
                    ? product.description 
                    : 'Açıklama belirtilmemiş',
                style: const TextStyle(fontSize: 14),
              ),
              
              const SizedBox(height: 12),
              
              // Durum
              const Text(
                'Durum:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  product.condition,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Kategori
              const Text(
                'Kategori:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.category.name,
                style: const TextStyle(fontSize: 14),
              ),
              
              const SizedBox(height: 12),
              
              // Takas tercihleri
              if (product.tradePreferences.isNotEmpty) ...[
                const Text(
                  'Takas Tercihi:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.tradePreferences.join(', '),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Takas teklifi gönderme işlemi
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Takas teklifi özelliği yakında aktif olacak'),
                ),
              );
            },
            child: const Text('Takas Teklifi Gönder'),
          ),
        ],
      ),
    );
  }

  void _showNewTradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Takas'),
        content: const Text('Yeni takas özelliği yakında aktif olacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
} 