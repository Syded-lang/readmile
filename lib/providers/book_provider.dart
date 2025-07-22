import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../services/api_service.dart';

class BookProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Book> _books = [];
  bool _isLoading = false;
  String? _error;

  BookProvider(this._apiService);

  List<Book> get books => _books;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchBooks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _books = await _apiService.getBooks(); // Changed from fetchBooks to getBooks
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error fetching books: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Alternative method name for compatibility
  Future<void> loadBooks() async {
    await fetchBooks();
  }

  Book? getBookById(String bookId) {
    try {
      return _books.firstWhere((book) => book.id == bookId);
    } catch (e) {
      return null;
    }
  }

  List<Book> getBooksByCategory(String category) {
    if (category == 'All') {
      return _books;
    }
    return _books.where((book) => book.category == category).toList();
  }

  List<Book> searchBooks(String query) {
    final lowerQuery = query.toLowerCase();
    return _books.where((book) =>
    book.title.toLowerCase().contains(lowerQuery) ||
        book.author.toLowerCase().contains(lowerQuery) ||
        book.category.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  List<String> get categories {
    final categorySet = <String>{'All'};
    for (final book in _books) {
      if (book.category.isNotEmpty) {
        categorySet.add(book.category);
      }
    }
    return categorySet.toList();
  }
}