import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:takasly/services/pick_crop_service.dart';
import 'package:takasly/utils/logger.dart';

/// Birden fazla fotoğraf seçme widget'ı
/// Galeriden birden fazla fotoğraf seçer (crop olmadan)
class MultipleImagePickerWidget extends StatefulWidget {
  final int maxImages;
  final int maxImageSizeMB;
  final Function(List<Uint8List> imageBytesList)? onImagesSelected;
  final Function(String error)? onError;
  final List<String>? initialImageUrls;
  final bool showPreview;
  final double imageWidth;
  final double imageHeight;
  final String? placeholderText;

  const MultipleImagePickerWidget({
    super.key,
    this.maxImages = 5,
    this.maxImageSizeMB = 10,
    this.onImagesSelected,
    this.onError,
    this.initialImageUrls,
    this.showPreview = true,
    this.imageWidth = 120,
    this.imageHeight = 120,
    this.placeholderText,
  });

  @override
  State<MultipleImagePickerWidget> createState() =>
      _MultipleImagePickerWidgetState();
}

class _MultipleImagePickerWidgetState extends State<MultipleImagePickerWidget> {
  List<Uint8List> _selectedImageBytesList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Başlangıç görsellerini ekle
    if (widget.initialImageUrls != null) {
      _selectedImageBytesList = List.filled(
        widget.initialImageUrls!.length,
        Uint8List(0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fotoğraflar (${_selectedImageBytesList.length}/${widget.maxImages})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            if (_selectedImageBytesList.isNotEmpty)
              TextButton.icon(
                onPressed: _clearAllImages,
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Tümünü Temizle'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Görsel grid'i
        if (widget.showPreview) ...[
          _buildImageGrid(),
          const SizedBox(height: 16),
        ],

        // Fotoğraf ekleme butonu
        if (_selectedImageBytesList.length < widget.maxImages)
          _buildAddImageButton(),

        // Yükleniyor göstergesi
        if (_isLoading) ...[
          const SizedBox(height: 16),
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
        ],
      ],
    );
  }

  /// Görsel grid'i widget'ı
  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: widget.imageWidth / widget.imageHeight,
      ),
      itemCount: widget.maxImages,
      itemBuilder: (context, index) {
        if (index < _selectedImageBytesList.length) {
          return _buildImageItem(index);
        } else {
          return _buildEmptyImageItem(index);
        }
      },
    );
  }

  /// Görsel öğesi widget'ı
  Widget _buildImageItem(int index) {
    final Uint8List imageBytes = _selectedImageBytesList[index];

    return Stack(
      children: [
        Container(
          width: widget.imageWidth,
          height: widget.imageHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              imageBytes,
              fit: BoxFit.cover,
              width: widget.imageWidth,
              height: widget.imageHeight,
            ),
          ),
        ),
        // Silme butonu
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  /// Boş görsel öğesi widget'ı
  Widget _buildEmptyImageItem(int index) {
    return Container(
      width: widget.imageWidth,
      height: widget.imageHeight,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 32,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 4),
          Text(
            '${index + 1}',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Fotoğraf ekleme butonu
  Widget _buildAddImageButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _pickMultipleImages,
        icon: const Icon(Icons.add_photo_alternate, size: 20),
        label: Text(
          'Fotoğraf Ekle (${_selectedImageBytesList.length}/${widget.maxImages})',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
      ),
    );
  }

  /// Birden fazla fotoğraf seçme işlemi
  Future<void> _pickMultipleImages() async {
    try {
      setState(() {
        _isLoading = true;
      });

      Logger.debug(
        '🖼️ MultipleImagePickerWidget - Starting multiple image pick process',
      );

      final List<Uint8List> newImageBytesList =
          await PickCropService.pickMultipleImages(
            maxImages: widget.maxImages - _selectedImageBytesList.length,
            compressQuality: 85,
          );

      if (newImageBytesList.isNotEmpty) {
        // Boyut kontrolü
        final List<Uint8List> validImages = [];
        for (final Uint8List imageBytes in newImageBytesList) {
          if (PickCropService.isImageSizeAcceptable(
            imageBytes,
            maxSizeMB: widget.maxImageSizeMB.toDouble(),
          )) {
            validImages.add(imageBytes);
          } else {
            Logger.warning(
              '🖼️ MultipleImagePickerWidget - Image size too large: ${PickCropService.formatImageSize(imageBytes)}',
            );

            final String errorMessage =
                'Bazı fotoğraflar çok büyük. Maksimum ${widget.maxImageSizeMB}MB olmalı.';
            if (widget.onError != null) {
              widget.onError!(errorMessage);
            } else {
              _showErrorSnackBar(errorMessage);
            }
          }
        }

        if (validImages.isNotEmpty) {
          setState(() {
            _selectedImageBytesList.addAll(validImages);
          });

          Logger.debug(
            '🖼️ MultipleImagePickerWidget - ${validImages.length} images added successfully',
          );

          if (widget.onImagesSelected != null) {
            widget.onImagesSelected!(_selectedImageBytesList);
          }
        }
      } else {
        Logger.debug('🖼️ MultipleImagePickerWidget - No images selected');
      }
    } catch (e) {
      Logger.error(
        '🖼️ MultipleImagePickerWidget - Error picking multiple images: $e',
      );

      final String errorMessage =
          'Fotoğraflar seçilirken bir hata oluştu. Lütfen tekrar deneyin.';

      if (widget.onError != null) {
        widget.onError!(errorMessage);
      } else {
        _showErrorSnackBar(errorMessage);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Belirli bir görseli kaldır
  void _removeImage(int index) {
    setState(() {
      _selectedImageBytesList.removeAt(index);
    });

    Logger.debug(
      '🖼️ MultipleImagePickerWidget - Image removed at index $index',
    );

    if (widget.onImagesSelected != null) {
      widget.onImagesSelected!(_selectedImageBytesList);
    }
  }

  /// Tüm görselleri temizle
  void _clearAllImages() {
    setState(() {
      _selectedImageBytesList.clear();
    });

    Logger.debug('🖼️ MultipleImagePickerWidget - All images cleared');

    if (widget.onImagesSelected != null) {
      widget.onImagesSelected!(_selectedImageBytesList);
    }
  }

  /// Hata mesajı göster
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  /// Seçilen görselleri al
  List<Uint8List> get selectedImageBytesList =>
      List.unmodifiable(_selectedImageBytesList);

  /// Seçilen görsel sayısını al
  int get selectedImageCount => _selectedImageBytesList.length;

  /// Maksimum görsel sayısına ulaşıldı mı?
  bool get isMaxImagesReached =>
      _selectedImageBytesList.length >= widget.maxImages;
}


