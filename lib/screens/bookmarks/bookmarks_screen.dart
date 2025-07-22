import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/reading_provider.dart';
import '../../providers/book_provider.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookmarks'),
      ),
      body: Consumer<ReadingProvider>(
        builder: (context, readingProvider, child) {
          final progress = readingProvider.readingProgress
              .where((p) => p.bookmarks.isNotEmpty)
              .toList();

          if (progress.isEmpty) {
            return const Center(
              child: Text('You have no bookmarks yet'),
            );
          }

          return ListView.builder(
            itemCount: progress.length,
            itemBuilder: (context, index) {
              final bookProgress = progress[index];
              final bookProvider = Provider.of<BookProvider>(context);
              final book = bookProvider.getBookById(bookProgress.bookId);

              if (book == null) {
                return const SizedBox.shrink();
              }

              return ExpansionTile(
                title: Text(book.title),
                subtitle: Text('${bookProgress.bookmarks.length} bookmarks'),
                children: bookProgress.bookmarks.map((chapterIndex) =>
                    ListTile(
                      leading: const Icon(Icons.bookmark),
                      title: Text('Chapter ${chapterIndex + 1}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          readingProvider.toggleBookmark(book.id, chapterIndex);
                        },
                      ),
                    ),
                ).toList(),
              );
            },
          );
        },
      ),
    );
  }
}