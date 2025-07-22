import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/book.dart';
import '../../providers/offline_provider.dart';
import '../../providers/reading_provider.dart';
import '../../screens/reader/epub_reader_screen.dart';
import '../../widgets/book_cover_widget.dart';
import '../../utils/date_helpers.dart';

class BookDetailScreen extends StatelessWidget {
  final Book book;

  const BookDetailScreen({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: _buildBookDetails(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: const Color(0xFF730000),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF730000),
                const Color(0xFF730000).withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Container(
                  width: 150,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: book.coverUrl.isNotEmpty
                      ? BookCoverWidget(
                    gridfsId: book.coverUrl,
                    title: book.title,
                  )
                      : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book,
                            size: 60,
                            color: Color(0xFF730000),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'ReadMile',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF730000),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookDetails(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Author
          Text(
            book.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF730000),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'by ${book.author}',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Categories
          if (book.categories.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: book.categories.map((category) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5A880).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFC5A880),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF730000),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 24),

          // Description
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF730000),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // Book Info
          _buildInfoSection(),

          const SizedBox(height: 32),

          // Action Buttons
          _buildActionButtons(context),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Book Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF730000),
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoRow('Published', DateHelpers.formatDate(book.publishedDate)),
        if (book.epubFileSizeBytes != null)
          _buildInfoRow(
              'File Size',
              '${(book.epubFileSizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB'
          ),
        _buildInfoRow('Format', 'EPUB'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Consumer2<OfflineProvider, ReadingProvider>(
      builder: (context, offlineProvider, readingProvider, child) {
        final isDownloaded = offlineProvider.isBookOffline(book.id);
        final isDownloading = offlineProvider.isBookDownloading(book.id);
        final progress = readingProvider.getBookProgress(book.id);

        return Column(
          children: [
            // Read Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EpubReaderScreen(
                        book: book,
                        filePath: isDownloaded
                            ? offlineProvider.getOfflineBook(book.id)?.localFilePath
                            : null,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.menu_book, color: Colors.white),
                label: Text(
                  progress != null ? 'Continue Reading' : 'Start Reading',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF730000),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Download Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: isDownloading
                    ? null
                    : isDownloaded
                    ? () => _confirmRemoveDownload(context, offlineProvider)
                    : () => _downloadBook(context, offlineProvider),
                icon: isDownloading
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF730000),
                    ),
                  ),
                )
                    : Icon(
                  isDownloaded ? Icons.delete : Icons.download,
                  color: isDownloaded ? Colors.red : const Color(0xFF730000),
                ),
                label: Text(
                  isDownloading
                      ? 'Downloading...'
                      : isDownloaded
                      ? 'Remove Download'
                      : 'Download for Offline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDownloaded ? Colors.red : const Color(0xFF730000),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDownloaded ? Colors.red : const Color(0xFF730000),
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),

            if (progress != null) ...[
              const SizedBox(height: 16),
              _buildProgressIndicator(progress),
            ],
          ],
        );
      },
    );
  }

  Widget _buildProgressIndicator(dynamic progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF730000).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reading Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF730000),
                ),
              ),
              Text(
                '${progress.progressPercentage.toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF730000),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.progressPercentage / 100,
            backgroundColor: Colors.white,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF730000)),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadBook(BuildContext context, OfflineProvider offlineProvider) async {
    try {
      final success = await offlineProvider.downloadBook(book);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Book downloaded successfully' : 'Download failed'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmRemoveDownload(BuildContext context, OfflineProvider offlineProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Download'),
        content: Text('Remove "${book.title}" from your device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await offlineProvider.removeBook(book.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Download removed'),
                    backgroundColor: Color(0xFF730000),
                  ),
                );
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}