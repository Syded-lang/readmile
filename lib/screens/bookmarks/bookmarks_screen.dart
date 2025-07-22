import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/reading_provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/offline_provider.dart';
import '../reader/epub_reader_screen.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookmarks'),
        backgroundColor: const Color(0xFF730000),
        foregroundColor: Colors.white,
      ),
      body: Consumer<ReadingProvider>(
        builder: (context, readingProvider, child) {
          final progress = readingProvider.readingProgress
              .where((p) => p.bookmarks.isNotEmpty)
              .toList();

          if (progress.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No bookmarks yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Tap the bookmark icon while reading to save your place',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: progress.length,
            itemBuilder: (context, index) {
              final bookProgress = progress[index];
              final bookProvider = Provider.of<BookProvider>(context, listen: false);
              final offlineProvider = Provider.of<OfflineProvider>(context, listen: false);
              final book = bookProvider.getBookById(bookProgress.bookId);

              if (book == null) return const SizedBox.shrink();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: Container(
                    width: 40, height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF730000).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.menu_book, color: Color(0xFF730000)),
                  ),
                  title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('by ${book.author} • ${bookProgress.bookmarks.length} bookmarks'),
                  children: bookProgress.bookmarks.map<Widget>((chapterIndex) {
                    return ListTile(
                      leading: const Icon(Icons.bookmark, color: Color(0xFF730000)),
                      title: Text('Chapter ${chapterIndex + 1}'),
                      subtitle: Text('Last read: ${_formatDate(bookProgress.lastReadAt)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow, color: Color(0xFF730000)),
                            tooltip: 'Open chapter',
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => EpubReaderScreen(
                                  book: book,
                                  filePath: offlineProvider.isBookOffline(book.id)
                                      ? offlineProvider.getOfflineBook(book.id)?.localFilePath
                                      : null,
                                ),
                              ));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Remove bookmark',
                            onPressed: () {
                              readingProvider.toggleBookmark(book.id, chapterIndex);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Bookmark removed'), duration: Duration(seconds: 1)),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
