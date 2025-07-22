import 'package:flutter/material.dart';
import 'package:readmile/models/book.dart';
import 'package:readmile/widgets/book_cover_widget.dart';
import 'package:readmile/screens/book/book_detail_screen.dart';

class BookGrid extends StatelessWidget {
  final List<Book> books;

  const BookGrid({
    Key? key,
    required this.books,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75, // Slightly taller cards to prevent overflow
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return _buildBookCard(context, book);
      },
    );
  }

  Widget _buildBookCard(BuildContext context, Book book) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailScreen(book: book),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover with flexible height
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: book.coverUrl.isNotEmpty
                      ? BookCoverWidget(
                    gridfsId: book.coverUrl,
                    title: book.title,
                  )
                      : Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF730000).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.menu_book,
                        size: 40,
                        color: Color(0xFF730000),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // FIXED: Text content - this prevents the 4px overflow
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Title with flexible height
                    Expanded(
                      flex: 3,
                      child: Text(
                        book.title,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF730000),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Author with flexible height
                    Expanded(
                      flex: 2,
                      child: Text(
                        book.author,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}