import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/offline_provider.dart';
import '../../providers/book_provider.dart';
import '../../models/book.dart';
import '../reader/epub_reader_screen.dart';

class OfflineBooksScreen extends StatelessWidget {
  const OfflineBooksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloaded Books'),
        backgroundColor: const Color(0xFF730000),
        actions: [
          Consumer<OfflineProvider>(
            builder: (context, provider, child) {
              if (provider.offlineBooks.isEmpty) return const SizedBox();

              return PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Clear All Downloads'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'clear_all') {
                    _confirmClearAll(context, provider);
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Consumer2<OfflineProvider, BookProvider>(
        builder: (context, offlineProvider, bookProvider, child) {
          if (offlineProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF730000)),
            );
          }

          if (offlineProvider.offlineBooks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No downloaded books',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Download books for offline reading from the library',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: offlineProvider.offlineBooks.length,
            itemBuilder: (context, index) {
              final offlineBook = offlineProvider.offlineBooks[index];
              final book = bookProvider.getBookById(offlineBook.bookId);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF730000).withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.menu_book,
                      color: Color(0xFF730000),
                      size: 30,
                    ),
                  ),
                  title: Text(
                    offlineBook.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('by ${offlineBook.author}'),
                      const SizedBox(height: 4),
                      Text(
                        'Downloaded: ${offlineBook.downloadDateFormatted}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        'Size: ${offlineBook.fileSizeFormatted}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.play_arrow,
                          color: Color(0xFF730000),
                        ),
                        tooltip: 'Read offline',
                        onPressed: () {
                          if (book != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EpubReaderScreen(
                                  book: book,
                                  filePath: offlineBook.localFilePath, // Pass local file path
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Remove download',
                        onPressed: () => _confirmDelete(
                          context,
                          offlineProvider,
                          offlineBook.bookId,
                          offlineBook.title,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    if (book != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EpubReaderScreen(
                            book: book,
                            filePath: offlineBook.localFilePath, // Open with local file
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext context,
      OfflineProvider provider,
      String bookId,
      String title,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Download'),
        content: Text('Remove "$title" from your device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.removeBook(bookId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed "$title"'),
                  backgroundColor: const Color(0xFF730000),
                ),
              );
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, OfflineProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Downloads'),
        content: Text(
            'Remove all ${provider.offlineBooks.length} downloaded books from your device?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final books = [...provider.offlineBooks];
              for (final book in books) {
                await provider.removeBook(book.bookId);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All downloads cleared'),
                    backgroundColor: Color(0xFF730000),
                  ),
                );
              }
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
