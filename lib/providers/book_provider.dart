import 'package:flutter/material.dart';
import 'package:readmile/models/book.dart';
import 'package:readmile/services/api_service.dart';
import 'dart:async';

class BookProvider with ChangeNotifier {
  List<Book> _books = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String? _error;

  // Caching and optimization
  bool _isInitialized = false;
  DateTime? _lastLoadTime;
  static const Duration _cacheExpiration = Duration(minutes: 30);

  // Search optimization
  final Map<String, List<Book>> _searchCache = {};
  final Map<String, List<Book>> _categoryCache = {};
  Timer? _searchDebounce;

  // Getters
  List<Book> get books => List.unmodifiable(_books);
  List<String> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Smart loading with cache management
  Future<void> loadBooks() async {
    // Check if we already have fresh data
    if (_isInitialized && _books.isNotEmpty && _lastLoadTime != null) {
      final timeSinceLastLoad = DateTime.now().difference(_lastLoadTime!);
      if (timeSinceLastLoad < _cacheExpiration) {
        print('📚 Using cached books (${_books.length} books)');
        return;
      }
    }

    _isLoading = true;
    _error = null;

    try {
      final stopwatch = Stopwatch()..start();

      // Clear caches before loading new data
      _clearCaches();

      final newBooks = await ApiService.fetchBooks();
      stopwatch.stop();

      if (newBooks.isNotEmpty) {
        _books = newBooks;
        _extractCategories();
        _isInitialized = true;
        _lastLoadTime = DateTime.now();

        print('✅ Loaded ${_books.length} books in ${stopwatch.elapsedMilliseconds}ms');

        // Precompute popular categories for better performance
        _precomputePopularCategories();
      }

    } catch (e) {
      _error = e.toString();
      print('❌ Error loading books: $e');
    } finally {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Force refresh with cache invalidation
  Future<void> fetchBooks() async {
    _isInitialized = false;
    _lastLoadTime = null;
    await loadBooks();
  }

  /// Optimized category extraction with sorting
  void _extractCategories() {
    final Map<String, int> categoryCount = {'All': _books.length};

    // Count occurrences for sorting by popularity
    for (final book in _books) {
      for (final category in book.categories) {
        if (category.isNotEmpty) {
          categoryCount[category] = (categoryCount[category] ?? 0) + 1;
        }
      }
    }

    // Sort categories by popularity
    final sortedCategories = categoryCount.keys.toList()
      ..sort((a, b) {
        if (a == 'All') return -1;
        if (b == 'All') return 1;

        // Sort by count (popularity) then alphabetically
        final countComparison = categoryCount[b]!.compareTo(categoryCount[a]!);
        return countComparison != 0 ? countComparison : a.compareTo(b);
      });

    _categories = sortedCategories;
    print('📂 Extracted ${_categories.length - 1} categories');
  }

  /// Precompute popular categories for faster access
  void _precomputePopularCategories() {
    final popularCategories = _categories.take(5).toList();

    for (final category in popularCategories) {
      if (category != 'All') {
        _categoryCache[category] = _books.where((book) =>
            book.categories.contains(category)).toList();
      }
    }

    print('🚀 Precomputed ${popularCategories.length} popular categories');
  }

  /// Optimized category filtering with caching
  List<Book> getBooksInCategory(String category) {
    if (category == 'All') return _books;

    // Check cache first
    if (_categoryCache.containsKey(category)) {
      return _categoryCache[category]!;
    }

    // Compute and cache result
    final filteredBooks = _books.where((book) =>
        book.categories.contains(category)).toList();

    _categoryCache[category] = filteredBooks;
    return filteredBooks;
  }

  /// Fast book lookup with early termination
  Book? getBookById(String id) {
    if (id.isEmpty) return null;

    try {
      return _books.firstWhere((book) => book.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Optimized search with debouncing and caching
  List<Book> searchBooks(String query) {
    if (query.isEmpty) return _books;

    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) return _books;

    // Check cache first
    if (_searchCache.containsKey(normalizedQuery)) {
      return _searchCache[normalizedQuery]!;
    }

    // Perform search with optimized algorithm
    final results = <Book>[];
    final queryWords = normalizedQuery.split(' ');

    for (final book in _books) {
      if (_bookMatchesQuery(book, queryWords)) {
        results.add(book);
      }
    }

    // Cache result (limit cache size)
    if (_searchCache.length > 50) {
      _searchCache.clear();
    }
    _searchCache[normalizedQuery] = results;

    return results;
  }

  /// Efficient book matching algorithm
  bool _bookMatchesQuery(Book book, List<String> queryWords) {
    final titleLower = book.title.toLowerCase();
    final authorLower = book.author.toLowerCase();
    final categoriesLower = book.categories.map((c) => c.toLowerCase()).join(' ');

    // Score-based matching for better relevance
    int matchScore = 0;

    for (final word in queryWords) {
      if (titleLower.contains(word)) matchScore += 3; // Title matches are most important
      if (authorLower.contains(word)) matchScore += 2; // Author matches are important
      if (categoriesLower.contains(word)) matchScore += 1; // Category matches are less important
    }

    return matchScore > 0;
  }

  /// Debounced search for UI responsiveness
  void searchBooksDebounced(String query, Function(List<Book>) callback) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      final results = searchBooks(query);
      callback(results);
    });
  }

  /// Get books with reading progress (for continue reading section)
  List<Book> getBooksWithProgress(List<dynamic> progressList) {
    final booksWithProgress = <Book>[];

    for (final progress in progressList) {
      final book = getBookById(progress.bookId);
      if (book != null) {
        booksWithProgress.add(book);
      }
    }

    return booksWithProgress;
  }

  /// Get recently added books
  List<Book> getRecentBooks({int limit = 10}) {
    final sortedBooks = List<Book>.from(_books)
      ..sort((a, b) => b.publishedDate.compareTo(a.publishedDate));

    return sortedBooks.take(limit).toList();
  }

  /// Get popular books by category size
  List<Book> getPopularBooks({int limit = 10}) {
    final bookPopularity = <Book, int>{};

    for (final book in _books) {
      bookPopularity[book] = book.categories.length;
    }

    final sortedBooks = _books.toList()
      ..sort((a, b) => (bookPopularity[b] ?? 0).compareTo(bookPopularity[a] ?? 0));

    return sortedBooks.take(limit).toList();
  }

  /// Clear all caches
  void _clearCaches() {
    _searchCache.clear();
    _categoryCache.clear();
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Force refresh with cache invalidation
  Future<void> refresh() async {
    _clearCaches();
    await fetchBooks();
  }

  /// Get provider statistics
  Map<String, dynamic> getStats() {
    return {
      'totalBooks': _books.length,
      'totalCategories': _categories.length - 1, // Exclude 'All'
      'cacheInitialized': _isInitialized,
      'lastLoadTime': _lastLoadTime?.toIso8601String(),
      'searchCacheSize': _searchCache.length,
      'categoryCacheSize': _categoryCache.length,
    };
  }

  /// Cleanup
  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
