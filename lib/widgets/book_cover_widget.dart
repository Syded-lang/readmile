import 'package:flutter/material.dart';
import 'package:readmile/services/gridfs_service.dart';

class BookCoverWidget extends StatefulWidget {
  final String gridfsId;
  final String title;

  const BookCoverWidget({
    Key? key,
    required this.gridfsId,
    required this.title,
  }) : super(key: key);

  @override
  State<BookCoverWidget> createState() => _BookCoverWidgetState();
}

class _BookCoverWidgetState extends State<BookCoverWidget> {
  bool _isLoading = true;
  bool _hasError = false;
  ImageProvider? _imageProvider;

  @override
  void initState() {
    super.initState();
    _loadCoverImage();
  }

  Future<void> _loadCoverImage() async {
    if (!mounted) return;

    try {
      final gridfsService = GridFSService();
      final imageBytes = await gridfsService.getCoverImage(widget.gridfsId);

      if (imageBytes != null && imageBytes.isNotEmpty && mounted) {
        setState(() {
          _imageProvider = MemoryImage(imageBytes);
          _isLoading = false;
          _hasError = false;
        });
      } else if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Cover loading error for ${widget.title}: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF730000),
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_hasError || _imageProvider == null) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF730000).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.menu_book,
              size: 24,
              color: Color(0xFF730000),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 8,
                  color: Color(0xFF730000),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: _imageProvider!,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
