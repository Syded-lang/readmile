import 'package:flutter/material.dart';
import 'package:readmile/models/book.dart';
import 'package:readmile/services/api_service.dart';

class BookProvider with ChangeNotifier {
  List<Book> _books = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Book> get books => _books;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadBooks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _books = await ApiService.fetchBooks();
      _extractCategories();
      print('✅ Loaded ${_books.length} books successfully');
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading books: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _extractCategories() {
    final Set<String> categorySet = {'All'};
    for (final book in _books) {
      categorySet.addAll(book.categories);
    }
    _categories = categorySet.toList()..sort((a, b) {
      if (a == 'All') return -1;
      if (b == 'All') return 1;
      return a.compareTo(b);
    });
  }

  List<Book> getBooksInCategory(String category) {
    if (category == 'All') return _books;
    return _books.where((book) => book.categories.contains(category)).toList();
  }

  Book? getBookById(String id) {
    try {
      return _books.firstWhere((book) => book.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Book> searchBooks(String query) {
    if (query.isEmpty) return _books;

    final lowercaseQuery = query.toLowerCase();
    return _books.where((book) =>
    book.title.toLowerCase().contains(lowercaseQuery) ||
        book.author.toLowerCase().contains(lowercaseQuery) ||
        book.categories.any((category) => category.toLowerCase().contains(lowercaseQuery))
    ).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadBooks();
  }
}
