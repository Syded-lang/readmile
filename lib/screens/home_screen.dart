import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';
import '../providers/offline_provider.dart';
import '../screens/reader/epub_reader_screen.dart';
import '../screens/bookmarks/bookmarks_screen.dart';
import '../screens/stats/reading_stats_screen.dart';
import '../widgets/book_cover_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  List<String> _categories = ['All'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    await bookProvider.fetchBooks();

    setState(() {
      _categories = bookProvider.categories;
      _isLoading = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<Book> _getFilteredBooks() {
    final bookProvider = Provider.of<BookProvider>(context);

    List<Book> books;
    if (_selectedCategory == 'All') {
      books = bookProvider.books;
    } else {
      books = bookProvider.getBooksByCategory(_selectedCategory);
    }

    if (_searchQuery.isNotEmpty) {
      books = books.where((book) {
        return book.title.toLowerCase().contains(_searchQuery) ||
            book.author.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    return books;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReadMile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: BookSearchDelegate(
                  onSearch: _onSearch,
                  categories: _categories,
                  onCategoryFilter: _filterByCategory,
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBookGrid(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'My Books',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedIndex == 0) {
            _showCategoriesBottomSheet();
          } else if (_selectedIndex == 1) {
            Navigator.pushNamed(context, '/offline');
          } else if (_selectedIndex == 2) {
            _showMoreOptions();
          }
        },
        child: Icon(_getFloatingActionButtonIcon()),
      ),
    );
  }

  Widget _buildBookGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final books = _getFilteredBooks();

    if (books.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isNotEmpty
              ? 'No books found matching "$_searchQuery"'
              : 'No books available in $_selectedCategory category',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return GestureDetector(
          onTap: () => _openBookReader(book),
          child: BookCoverWidget(
            gridfsId: book.gridfsEpubId ?? book.id, // Use gridfsId parameter instead of coverUrl
            title: book.title,
          ),
        );
      },
    );
  }

  IconData _getFloatingActionButtonIcon() {
    switch (_selectedIndex) {
      case 0:
        return Icons.category;
      case 1:
        return Icons.download;
      case 2:
        return Icons.menu;
      default:
        return Icons.add;
    }
  }

  void _showCategoriesBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            return ListTile(
              title: Text(category),
              selected: _selectedCategory == category,
              onTap: () {
                _filterByCategory(category);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Bookmarks'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BookmarksScreen())
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Reading Stats'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReadingStatsScreen())
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Reading Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About ReadMile'),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About ReadMile'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ReadMile v1.0.0'),
            SizedBox(height: 8),
            Text('A digital library application with reading features.'),
            SizedBox(height: 16),
            Text('© 2025 ReadMile'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openBookReader(Book book) async {
    final offlineProvider = Provider.of<OfflineProvider>(context, listen: false);

    if (offlineProvider.isBookDownloaded(book.id)) {
      final offlineBook = offlineProvider.offlineBooks
          .firstWhere((offBook) => offBook.id == book.id);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EpubReaderScreen(
            book: book,
            filePath: offlineBook.localFilePath,
          ),
        ),
      );
    } else {
      // Open online reader without filePath
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EpubReaderScreen(
            book: book,
            // No filePath - will stream online
          ),
        ),
      );
    }
  }
}

class BookSearchDelegate extends SearchDelegate {
  final Function(String) onSearch;
  final List<String> categories;
  final Function(String) onCategoryFilter;

  BookSearchDelegate({
    required this.onSearch,
    required this.categories,
    required this.onCategoryFilter,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          onSearch('');
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onSearch(query);
    close(context, null);
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return ListTile(
            leading: const Icon(Icons.category),
            title: Text(category),
            onTap: () {
              onCategoryFilter(category);
              close(context, null);
            },
          );
        },
      );
    } else {
      onSearch(query);
      close(context, null);
      return Container();
    }
  }
}