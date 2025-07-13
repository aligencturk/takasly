import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/trade_viewmodel.dart';
import '../../core/constants.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class TradeView extends StatefulWidget {
  const TradeView({super.key});

  @override
  State<TradeView> createState() => _TradeViewState();
}

class _TradeViewState extends State<TradeView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final tradeViewModel = Provider.of<TradeViewModel>(context, listen: false);
    tradeViewModel.fetchMyTrades();
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
        title: const Text('Takaslar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Aktif'),
            Tab(text: 'Tamamlanan'),
            Tab(text: 'İptal Edilen'),
          ],
        ),
      ),
      body: Consumer<TradeViewModel>(
        builder: (context, tradeViewModel, child) {
          if (tradeViewModel.isLoading) {
            return const LoadingWidget();
          }

          if (tradeViewModel.hasError) {
            return CustomErrorWidget(
              message: tradeViewModel.errorMessage!,
              onRetry: _loadData,
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTradeList(tradeViewModel.activeTrades),
              _buildTradeList(tradeViewModel.completedTrades),
              _buildTradeList(tradeViewModel.cancelledTrades),
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
            SizedBox(height: 8),
            Text(
              'İlk takasınızı başlatmak için + butonuna tıklayın',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadData();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: trades.length,
        itemBuilder: (context, index) {
          final trade = trades[index];
          return _buildTradeCard(trade);
        },
      ),
    );
  }

  Widget _buildTradeCard(dynamic trade) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2196F3),
          child: Icon(
            Icons.swap_horiz,
            color: Colors.white,
          ),
        ),
        title: Text(
          'Takas #${trade['id'] ?? 'N/A'}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Durum: ${trade['status'] ?? 'Bilinmiyor'}'),
            Text('Tarih: ${trade['createdAt'] ?? 'Bilinmiyor'}'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showTradeDetails(trade),
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