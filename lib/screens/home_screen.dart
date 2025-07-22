import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../providers/offline_provider.dart';
import '../providers/reading_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/book_grid.dart';
import '../widgets/category_filter.dart';
import '../widgets/search_bar.dart';
import '../screens/offline/offline_books_screen.dart';
import '../screens/bookmarks/bookmarks_screen.dart';
import '../screens/stats/reading_stats_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/book/book_detail_screen.dart';
import '../models/book.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isSearchVisible = false;
  late TabController _tabController;

  // Animation controllers for smooth transitions
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize search animation
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );

    // Load books when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookProvider>().loadBooks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigation(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF730000),
      foregroundColor: Colors.white,
      title: _isSearchVisible
          ? _buildSearchField()
          : const Text(
        'ReadMile',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      actions: [
        if (!_isSearchVisible)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _toggleSearch,
            tooltip: 'Search books',
          ),
        if (_isSearchVisible)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _toggleSearch,
            tooltip: 'Close search',
          ),
        if (!_isSearchVisible)
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh Library'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_cache',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear Cache'),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      autofocus: true,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        hintText: 'Search books, authors...',
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
      onChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
      },
    );
  }

  Widget _buildBody() {
    return Consumer3<BookProvider, OfflineProvider, ReadingProvider>(
      builder: (context, bookProvider, offlineProvider, readingProvider, child) {
        if (bookProvider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF730000)),
                SizedBox(height: 16),
                Text('Loading your library...'),
              ],
            ),
          );
        }

        if (bookProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading books',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  bookProvider.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => bookProvider.loadBooks(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF730000),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Category Filter
            if (!_isSearchVisible) _buildCategoryFilter(bookProvider),

            // Continue Reading Section
            if (!_isSearchVisible && _searchQuery.isEmpty)
              _buildContinueReadingSection(readingProvider, bookProvider),

            // Statistics Overview
            if (!_isSearchVisible && _searchQuery.isEmpty)
              _buildStatsOverview(readingProvider, offlineProvider),

            // Books Grid
            Expanded(
              child: _buildBooksGrid(bookProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryFilter(BookProvider bookProvider) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: bookProvider.categories.length,
        itemBuilder: (context, index) {
          final category = bookProvider.categories[index];
          final isSelected = category == _selectedCategory;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category : 'All';
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: const Color(0xFF730000).withOpacity(0.2),
              checkmarkColor: const Color(0xFF730000),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF730000) : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContinueReadingSection(ReadingProvider readingProvider, BookProvider bookProvider) {
    final recentProgress = readingProvider.readingProgress
        .where((p) => p.progressPercentage > 0 && p.progressPercentage < 100)
        .take(3)
        .toList();

    if (recentProgress.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Continue Reading',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF730000),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recentProgress.length,
              itemBuilder: (context, index) {
                final progress = recentProgress[index];
                final book = bookProvider.getBookById(progress.bookId);
                if (book == null) return const SizedBox();

                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  child: Card(
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF730000).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.menu_book,
                          color: Color(0xFF730000),
                        ),
                      ),
                      title: Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${progress.progressPercentage.toInt()}% complete',
                            style: const TextStyle(fontSize: 10),
                          ),
                          LinearProgressIndicator(
                            value: progress.progressPercentage / 100,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF730000)),
                          ),
                        ],
                      ),
                      onTap: () => _openBook(book),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(ReadingProvider readingProvider, OfflineProvider offlineProvider) {
    final stats = readingProvider.getReadingStats();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Books Read',
              '${stats['booksCompleted']}',
              Icons.library_books,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Downloaded',
              '${offlineProvider.offlineBooks.length}',
              Icons.download_done,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Bookmarks',
              '${readingProvider.readingProgress.where((p) => p.bookmarks.isNotEmpty).length}',
              Icons.bookmark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF730000), size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF730000),
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBooksGrid(BookProvider bookProvider) {
    List<Book> filteredBooks = bookProvider.books;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredBooks = filteredBooks
          .where((book) =>
      book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          book.author.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      filteredBooks = filteredBooks
          .where((book) => book.categories.contains(_selectedCategory))
          .toList();
    }

    if (filteredBooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.book_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No books found for "$_searchQuery"'
                  : 'No books in this category',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return BookGrid(books: filteredBooks);
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _handleNavigation,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF730000),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.library_books),
          label: 'Library',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.download),
          label: 'Downloads',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark),
          label: 'Bookmarks',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Stats',
        ),
      ],
    );
  }

  Widget? _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showQuickActions,
      backgroundColor: const Color(0xFF730000),
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  // Navigation Handlers
  void _handleNavigation(int index) {
    switch (index) {
      case 0:
      // Library - current screen
        break;
      case 1:
        _navigateToDownloads();
        break;
      case 2:
        _navigateToBookmarks();
        break;
      case 3:
        _navigateToStats();
        break;
    }

    // Reset to library tab after navigation
    if (index != 0) {
      setState(() => _currentIndex = 0);
    }
  }

  void _navigateToDownloads() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OfflineBooksScreen(),
      ),
    ).then((_) {
      // Refresh offline provider when returning
      context.read<OfflineProvider>().loadOfflineBooks();
    });
  }

  void _navigateToBookmarks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BookmarksScreen(),
      ),
    ).then((_) {
      // Refresh reading provider when returning
      context.read<ReadingProvider>().initialize();
    });
  }

  void _navigateToStats() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReadingStatsScreen(),
      ),
    );
  }

  // Action Handlers
  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchQuery = '';
      }
    });

    if (_isSearchVisible) {
      _searchAnimationController.forward();
    } else {
      _searchAnimationController.reverse();
    }
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
      case 'refresh':
        context.read<BookProvider>().fetchBooks();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refreshing library...'),
            backgroundColor: Color(0xFF730000),
          ),
        );
        break;
      case 'clear_cache':
        _confirmClearCache();
        break;
    }
  }

  void _openBook(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailScreen(book: book),
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.refresh, color: Color(0xFF730000)),
              title: const Text('Refresh Library'),
              onTap: () {
                Navigator.pop(context);
                context.read<BookProvider>().fetchBooks();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark, color: Color(0xFF730000)),
              title: const Text('View Bookmarks'),
              onTap: () {
                Navigator.pop(context);
                _navigateToBookmarks();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Color(0xFF730000)),
              title: const Text('Downloaded Books'),
              onTap: () {
                Navigator.pop(context);
                _navigateToDownloads();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Color(0xFF730000)),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all cached book covers and temporary files. '
              'Downloaded books will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Clear various caches
              context.read<BookProvider>().refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared'),
                  backgroundColor: Color(0xFF730000),
                ),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
