import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readmile/providers/offline_provider.dart';
import 'package:readmile/providers/reading_provider.dart';
import 'package:readmile/models/offline_book.dart';
import 'package:readmile/screens/reader/epub_reader_screen.dart';

class OfflineBooksScreen extends StatefulWidget {
  @override
  State<OfflineBooksScreen> createState() => _OfflineBooksScreenState();
}

class _OfflineBooksScreenState extends State<OfflineBooksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OfflineProvider>(context, listen: false).loadOfflineBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Downloaded Books', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF730000),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          Consumer<OfflineProvider>(
            builder: (context, provider, child) {
              return PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, provider),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'storage', child: Row(children: [Icon(Icons.storage, color: Color(0xFF730000)), SizedBox(width: 8), Text('Storage Info')])),
                  PopupMenuItem(value: 'cleanup', child: Row(children: [Icon(Icons.cleaning_services, color: Color(0xFF730000)), SizedBox(width: 8), Text('Cleanup')])),
                  PopupMenuItem(value: 'delete_all', child: Row(children: [Icon(Icons.delete_forever, color: Colors.red), SizedBox(width: 8), Text('Delete All')])),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<OfflineProvider>(
        builder: (context, offlineProvider, child) {
          if (offlineProvider.isLoading) {
            return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF730000))));
          }

          final offlineBooks = offlineProvider.offlineBooks;

          if (offlineBooks.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildStorageInfo(offlineProvider),
              Expanded(child: _buildOfflineBooksList(offlineBooks)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStorageInfo(OfflineProvider provider) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF730000).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF730000).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Downloaded Books', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF730000))),
              Text('${provider.offlineBooks.length} books', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Storage Used', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF730000))),
              Text(provider.getFormattedStorageUsed(), style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBooksList(List<OfflineBook> books) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return _buildOfflineBookCard(book);
      },
    );
  }

  Widget _buildOfflineBookCard(OfflineBook book) {
    return Consumer<ReadingProvider>(
      builder: (context, readingProvider, child) {
        final progress = readingProvider.getBookProgress(book.bookId);

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 70,
              decoration: BoxDecoration(
                color: Color(0xFF730000).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.offline_bolt, color: Color(0xFF730000), size: 20),
                  SizedBox(height: 4),
                  Text('EPUB', style: TextStyle(color: Color(0xFF730000), fontSize: 8, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            title: Text(book.title, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF730000)), maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text('by ${book.author}', style: TextStyle(color: Colors.grey[600])),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.download_done, size: 14, color: Colors.green),
                    SizedBox(width: 4),
                    Text(book.downloadDateFormatted, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    SizedBox(width: 16),
                    Text(book.fileSizeFormatted, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
                if (progress != null) ...[
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress.progressPercentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF730000)),
                  ),
                  SizedBox(height: 4),
                  Text('${progress.progressPercentage.toInt()}% complete', style: TextStyle(fontSize: 12, color: Color(0xFF730000))),
                ]
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleBookAction(value, book),
              itemBuilder: (context) => [
                PopupMenuItem(value: 'read', child: Row(children: [Icon(Icons.menu_book, color: Color(0xFF730000)), SizedBox(width: 8), Text('Read')])),
                PopupMenuItem(value: 'info', child: Row(children: [Icon(Icons.info, color: Color(0xFF730000)), SizedBox(width: 8), Text('Details')])),
                PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete')])),
              ],
            ),
            onTap: () => _openBook(book),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_download, size: 80, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text('No Downloaded Books', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600])),
            SizedBox(height: 8),
            Text('Download books from your library to read offline', style: TextStyle(fontSize: 14, color: Colors.grey[500]), textAlign: TextAlign.center),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.library_books, color: Colors.white),
              label: Text('Browse Library', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF730000)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, OfflineProvider provider) async {
    switch (action) {
      case 'storage':
        _showStorageInfo(provider);
        break;
      case 'cleanup':
        await provider.cleanupStorage();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Storage cleanup completed'), backgroundColor: Color(0xFF730000)));
        break;
      case 'delete_all':
        _confirmDeleteAll(provider);
        break;
    }
  }

  void _handleBookAction(String action, OfflineBook book) {
    switch (action) {
      case 'read':
        _openBook(book);
        break;
      case 'info':
        _showBookInfo(book);
        break;
      case 'delete':
        _confirmDeleteBook(book);
        break;
    }
  }

  void _openBook(OfflineBook book) {
    // Convert OfflineBook to Book model for reader
    final bookForReader = Book(
      id: book.bookId,
      title: book.title,
      author: book.author,
      epubFilename: '',
      coverFilename: '',
      gridfsEpubId: '',
      gridfsCoverId: '',
      categories: book.categories,
      epubFileSizeBytes: book.fileSizeBytes,
      coverFileSizeBytes: 0,
      uploadDate: book.downloadDate,
    );

    Navigator.push(context, MaterialPageRoute(builder: (context) => EpubReaderScreen(book: bookForReader)));
  }

  void _showStorageInfo(OfflineProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Storage Information', style: TextStyle(color: Color(0xFF730000))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoRow('Total Books', '${provider.getTotalOfflineBooks()}'),
            _buildInfoRow('Storage Used', provider.getFormattedStorageUsed()),
            _buildInfoRow('Average Size', '${(provider.getTotalStorageUsed() / (provider.getTotalOfflineBooks() * 1024)).toStringAsFixed(1)} KB per book'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close', style: TextStyle(color: Color(0xFF730000)))),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _showBookInfo(OfflineBook book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(book.title, style: TextStyle(color: Color(0xFF730000))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Author', book.author),
            _buildInfoRow('Downloaded', book.downloadDateFormatted),
            _buildInfoRow('File Size', book.fileSizeFormatted),
            _buildInfoRow('Categories', book.categories.join(', ')),
            _buildInfoRow('Local Path', book.localFilePath),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close', style: TextStyle(color: Color(0xFF730000)))),
        ],
      ),
    );
  }

  void _confirmDeleteBook(OfflineBook book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Downloaded Book?'),
        content: Text('This will remove "${book.title}" from your device. You can download it again later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<OfflineProvider>(context, listen: false).removeBook(book.bookId);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Book deleted'), backgroundColor: Color(0xFF730000)));
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll(OfflineProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete All Downloads?'),
        content: Text('This will remove all downloaded books from your device. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.removeAllOfflineBooks();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('All downloads deleted'), backgroundColor: Color(0xFF730000)));
            },
            child: Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
