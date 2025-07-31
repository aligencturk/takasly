import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/trade_viewmodel.dart';
import '../core/constants.dart';
import '../utils/logger.dart';

class TradeConfirmDialog extends StatefulWidget {
  final int offerID;
  final String tradeTitle;
  final String? currentStatus;

  const TradeConfirmDialog({
    super.key,
    required this.offerID,
    required this.tradeTitle,
    this.currentStatus,
  });

  @override
  State<TradeConfirmDialog> createState() => _TradeConfirmDialogState();
}

class _TradeConfirmDialogState extends State<TradeConfirmDialog> {
  bool _isConfirming = false;
  bool _isRejecting = false;
  final TextEditingController _cancelDescController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _cancelDescController.dispose();
    super.dispose();
  }

  Future<void> _confirmTrade() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isConfirming = true;
    });

    try {
      final tradeViewModel = Provider.of<TradeViewModel>(context, listen: false);
      
      // TODO: userToken'ı AuthService'ten al
      final userToken = "L1bArF7S7ydp7YJh1sSXuByKwVZLUGVy"; // Geçici token
      
      final success = await tradeViewModel.confirmTrade(
        userToken: userToken,
        offerID: widget.offerID,
        isConfirm: true,
        cancelDesc: '',
      );

      if (success) {
        Logger.info('Takas onaylama başarılı: ${widget.offerID}');
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Takas başarıyla onaylandı'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tradeViewModel.errorMessage ?? 'Takas onaylanamadı'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Logger.error('Takas onaylama hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bir hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });
      }
    }
  }

  Future<void> _rejectTrade() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isRejecting = true;
    });

    try {
      final tradeViewModel = Provider.of<TradeViewModel>(context, listen: false);
      
      // TODO: userToken'ı AuthService'ten al
      final userToken = "L1bArF7S7ydp7YJh1sSXuByKwVZLUGVy"; // Geçici token
      
      final success = await tradeViewModel.confirmTrade(
        userToken: userToken,
        offerID: widget.offerID,
        isConfirm: false,
        cancelDesc: _cancelDescController.text.trim(),
      );

      if (success) {
        Logger.info('Takas reddetme başarılı: ${widget.offerID}');
        if (mounted) {
          Navigator.of(context).pop(false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Takas reddedildi'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tradeViewModel.errorMessage ?? 'Takas reddedilemedi'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Logger.error('Takas reddetme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bir hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRejecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: Text(
                      'Takas Onaylama',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              
              const SizedBox(height: AppConstants.defaultPadding),
              
              // Trade Info
              Container(
                padding: const EdgeInsets.all(AppConstants.smallPadding),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Takas: ${widget.tradeTitle}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (widget.currentStatus != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Durum: ${widget.currentStatus}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Offer ID: ${widget.offerID}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppConstants.defaultPadding),
              
              // Reject Reason Field
              TextFormField(
                controller: _cancelDescController,
                decoration: const InputDecoration(
                  labelText: 'Reddetme Sebebi',
                  hintText: 'Takası neden reddettiğinizi belirtin...',
                  border: OutlineInputBorder(),
                  helperText: 'Takası reddetmek istiyorsanız sebep zorunludur',
                ),
                maxLines: 3,
                validator: (value) {
                  // Sadece reddetme durumunda zorunlu
                  return null;
                },
              ),
              
              const SizedBox(height: AppConstants.defaultPadding),
              
              // Action Buttons
              Row(
                children: [
                  // Reject Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isRejecting || _isConfirming
                          ? null
                          : () {
                              if (_cancelDescController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Reddetme sebebi zorunludur'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              _rejectTrade();
                            },
                      icon: _isRejecting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.close, size: 18),
                      label: Text(_isRejecting ? 'Reddediliyor...' : 'Reddet'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: AppConstants.smallPadding),
                  
                  // Confirm Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isRejecting || _isConfirming
                          ? null
                          : _confirmTrade,
                      icon: _isConfirming
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: Text(_isConfirming ? 'Onaylanıyor...' : 'Onayla'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 