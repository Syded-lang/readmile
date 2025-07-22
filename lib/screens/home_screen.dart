import 'package:flutter/material.dart';
import 'package:readmile/models/book.dart';
import 'package:readmile/widgets/book_cover_widget.dart';
import 'package:readmile/screens/reader/epub_reader_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<Book> books;
  const HomeScreen({super.key, required this.books});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> categories = [];

  @override
  void initState() {
    super.initState();
    _extractCategories();
    _tabController = TabController(length: categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _extractCategories() {
    Set<String> uniqueCategories = {'All'};

    for (Book book in widget.books) {
      uniqueCategories.addAll(book.categories);
    }

    categories = uniqueCategories.toList();
    categories.sort((a, b) {
      if (a == 'All') return -1;
      if (b == 'All') return 1;
      return a.compareTo(b);
    });

    print('Available categories: $categories');
  }

  List<Book> _filterBooks(String category) {
    if (category == 'All') return widget.books;
    return widget.books.where((book) =>
        book.categories.contains(category)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.menu_book, color: Color(0xFFC5A880)),
            SizedBox(width: 8),
            Text(
              'ReadMile',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF730000),
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Color(0xFFC5A880),
          indicatorWeight: 3,
          labelColor: Color(0xFFC5A880),
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          tabs: categories.map((category) => Tab(
            text: '$category (${_filterBooks(category).length})',
          )).toList(),
        ),
      ),
      body: widget.books.isEmpty
          ? _buildEmptyState()
          : TabBarView(
        controller: _tabController,
        children: categories.map((category) => _buildBookGrid(category)).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text('No books available', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          SizedBox(height: 8),
          Text('Check your internet connection and try again', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildBookGrid(String category) {
    final filteredBooks = _filterBooks(category);

    if (filteredBooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text('No books in $category', style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => await Future.delayed(Duration(seconds: 1)),
      child: GridView.builder(
        padding: EdgeInsets.all(16),
        physics: AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(context),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.65,
        ),
        itemCount: filteredBooks.length,
        itemBuilder: (context, index) => _buildBookCard(filteredBooks[index]),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 600) return 4;
    if (width > 400) return 3;
    return 2;
  }

  Widget _buildBookCard(Book book) {
    return Card(
      elevation: 3,
      shadowColor: Color(0xFF730000).withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _onBookTapped(book),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: BookCoverWidget(gridfsId: book.gridfsCoverId, title: book.title),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        book.title,
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF730000), fontSize: 11, height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      book.author,
                      style: TextStyle(color: Colors.grey[600], fontSize: 9, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        if (book.categories.isNotEmpty && book.categories.first != 'All' && book.categories.first != 'Uncategorised')
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(0xFFC5A880).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                book.categories.first,
                                style: TextStyle(fontSize: 8, color: Color(0xFF730000), fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        SizedBox(width: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(0xFF730000).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${(book.epubFileSizeBytes / 1024).round()}KB',
                            style: TextStyle(fontSize: 8, color: Color(0xFF730000), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
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

  // FIXED: Complete overflow-proof dialog
  void _onBookTapped(Book book) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with cover and info - FIXED OVERFLOW
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Cover and Title Row - COMPLETELY FIXED
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Book cover - fixed width
                        Container(
                          width: 60,
                          height: 80,
                          child: BookCoverWidget(
                            gridfsId: book.gridfsCoverId,
                            title: book.title,
                          ),
                        ),

                        SizedBox(width: 16),

                        // Text content - uses remaining space
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title - constrained and wrapping
                              Text(
                                book.title,
                                style: TextStyle(
                                  color: Color(0xFF730000),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),

                              SizedBox(height: 8),

                              // Author - constrained
                              Text(
                                'by ${book.author}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Book details container
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Categories:', book.categories.join(', ')),
                          SizedBox(height: 8),
                          _buildDetailRow('File Size:', '${(book.epubFileSizeBytes / 1024).round()}KB'),
                          SizedBox(height: 8),
                          _buildDetailRow('Upload Date:', book.uploadDate.toString().split(' ')[0]),
                          SizedBox(height: 8),
                          _buildDetailRow('Format:', 'EPUB'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    // Main action buttons row
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Close', style: TextStyle(color: Colors.grey[600])),
                          ),
                        ),

                        SizedBox(width: 12),

                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _downloadForOffline(book);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFC5A880),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.download, size: 16, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Download', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8),

                    // Read button - full width
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _startReading(book);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF730000),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book, size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Read Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF730000),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  void _downloadForOffline(Book book) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.download, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text('Downloading "${book.title}" for offline reading...')),
          ],
        ),
        backgroundColor: Color(0xFFC5A880),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _startReading(Book book) {
    print('🚀 Opening EPUB reader for: ${book.title}');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EpubReaderScreen(book: book)),
    );
  }
}
