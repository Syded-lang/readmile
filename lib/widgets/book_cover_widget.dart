import 'package:flutter/material.dart';
import 'package:readmile/services/gridfs_service.dart';
import 'dart:typed_data';

class BookCoverWidget extends StatefulWidget {
  final String gridfsId;
  final String title;

  const BookCoverWidget({
    super.key,
    required this.gridfsId,
    required this.title,
  });

  @override
  State<BookCoverWidget> createState() => _BookCoverWidgetState();
}

class _BookCoverWidgetState extends State<BookCoverWidget> {
  Uint8List? coverBytes;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadCover();
  }

  Future<void> _loadCover() async {
    try {
      final bytes = await GridFSService().getCoverImage(widget.gridfsId);
      if (mounted) {
        setState(() {
          coverBytes = bytes;
          isLoading = false;
          hasError = bytes == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF730000).withOpacity(0.1),
              Color(0xFFC5A880).withOpacity(0.1),
            ],
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF730000)),
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (hasError || coverBytes == null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF730000).withOpacity(0.1),
              Color(0xFFC5A880).withOpacity(0.1),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book,
                size: 40,
                color: Color(0xFF730000),
              ),
              SizedBox(height: 4),
              Text(
                'ReadMile',
                style: TextStyle(
                  fontSize: 8,
                  color: Color(0xFF730000),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        child: Image.memory(
          coverBytes!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Color(0xFF730000).withOpacity(0.1),
            child: Center(
              child: Icon(
                Icons.broken_image,
                size: 40,
                color: Color(0xFF730000),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
