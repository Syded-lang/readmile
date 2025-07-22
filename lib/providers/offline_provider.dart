import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/offline_book.dart';
import '../services/offline_service.dart';

class OfflineProvider with ChangeNotifier {
  final Box<OfflineBook> _offlineBooksBox;
  final OfflineService _offlineService;
  bool _isLoading = false;

  OfflineProvider(this._offlineBooksBox, this._offlineService);

  List<OfflineBook> get offlineBooks => _offlineBooksBox.values.toList();
  bool get isLoading => _isLoading;

  // Initialize method
  Future<void> initialize() async {
    await loadOfflineBooks();
  }

  // Load offline books
  Future<void> loadOfflineBooks() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Update last access dates and clean up if needed
      await cleanupStorage();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading offline books: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isBookDownloaded(String bookId) {
    return _offlineBooksBox.values.any((book) => book.bookId == bookId);
  }

  Future<void> downloadBook(OfflineBook book) async {
    try {
      await _offlineBooksBox.add(book);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("Error downloading book: $e");
      }
      rethrow;
    }
  }

  Future<void> removeOfflineBook(String bookId) async {
    try {
      final index = _offlineBooksBox.values.toList().indexWhere((book) => book.bookId == bookId);

      if (index != -1) {
        final book = _offlineBooksBox.getAt(index)!;

        // Delete associated files
        if (book.localFilePath.isNotEmpty) {
          final file = File(book.localFilePath);
          if (await file.exists()) {
            await file.delete();
          }
        }

        if (book.coverPath.isNotEmpty) {
          final coverFile = File(book.coverPath);
          if (await coverFile.exists()) {
            await coverFile.delete();
          }
        }

        await _offlineBooksBox.deleteAt(index);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error removing offline book: $e");
      }
      rethrow;
    }
  }

  // Alternative method name for compatibility
  Future<void> removeBook(String bookId) async {
    await removeOfflineBook(bookId);
  }

  String getFormattedStorageUsed() {
    final totalBytes = getTotalStorageUsed();
    if (totalBytes < 1024) {
      return "$totalBytes B";
    } else if (totalBytes < 1024 * 1024) {
      return "${(totalBytes / 1024).toStringAsFixed(2)} KB";
    } else {
      return "${(totalBytes / (1024 * 1024)).toStringAsFixed(2)} MB";
    }
  }

  int getTotalStorageUsed() {
    int totalBytes = 0;
    for (final book in offlineBooks) {
      totalBytes += book.fileSizeBytes;
    }
    return totalBytes;
  }

  int getTotalOfflineBooks() {
    return offlineBooks.length;
  }

  Future<void> cleanupStorage() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final offlineDir = Directory('${appDir.path}/offline_books');

      if (await offlineDir.exists()) {
        final existingFiles = await offlineDir.list().toList();
        final validPaths = offlineBooks.map((e) => e.localFilePath).toList() +
            offlineBooks.map((e) => e.coverPath).toList();

        for (final entity in existingFiles) {
          if (entity is File && !validPaths.contains(entity.path)) {
            await entity.delete();
          }
        }
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("Error cleaning up storage: $e");
      }
    }
  }

  Future<void> removeAllOfflineBooks() async {
    try {
      final books = offlineBooks;

      for (final book in books) {
        if (book.localFilePath.isNotEmpty) {
          final file = File(book.localFilePath);
          if (await file.exists()) {
            await file.delete();
          }
        }

        if (book.coverPath.isNotEmpty) {
          final coverFile = File(book.coverPath);
          if (await coverFile.exists()) {
            await coverFile.delete();
          }
        }
      }

      await _offlineBooksBox.clear();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("Error removing all books: $e");
      }
      rethrow;
    }
  }
}