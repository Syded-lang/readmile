import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:readmile/models/book.dart';
import 'package:readmile/models/offline_book.dart';
import 'package:readmile/services/epub_service.dart';
import 'package:readmile/services/storage_service.dart';

class OfflineService {
  static const String _offlineDir = 'readmile_offline_books';

  // Download book for offline reading
  static Future<bool> downloadBookForOffline(Book book, {Function(double)? onProgress}) async {
    try {
      print('📥 Starting offline download: ${book.title}');

      // Check if already offline
      if (StorageService.isBookOffline(book.id)) {
        print('📚 Book already offline: ${book.title}');
        return true;
      }

      // Create offline directory
      final appDir = await getApplicationDocumentsDirectory();
      final offlineDir = Directory('${appDir.path}/$_offlineDir');
      if (!await offlineDir.exists()) {
        await offlineDir.create(recursive: true);
      }

      // Download EPUB to permanent location
      final fileName = '${book.id}.epub';
      final localPath = '${offlineDir.path}/$fileName';

      // Use existing epub service to download
      final tempPath = await EpubService().downloadEpubToTemp(
        book.gridfsEpubId,
        book.epubFilename,
      );

      if (tempPath == null) {
        print('❌ Failed to download EPUB for offline storage');
        return false;
      }

      // Move from temp to permanent location
      final tempFile = File(tempPath);
      final permanentFile = File(localPath);
      await tempFile.copy(localPath);
      await tempFile.delete(); // Clean up temp file

      // Create offline book record
      final offlineBook = OfflineBook(
        bookId: book.id,
        title: book.title,
        author: book.author,
        localFilePath: localPath,
        downloadDate: DateTime.now(),
        fileSizeBytes: book.epubFileSizeBytes,
        categories: book.categories,
      );

      // Save to storage
      await StorageService.saveOfflineBook(offlineBook);

      print('✅ Successfully downloaded offline: ${book.title}');
      return true;

    } catch (e) {
      print('❌ Error downloading book offline: $e');
      return false;
    }
  }

  // Get offline book file path
  static String? getOfflineBookPath(String bookId) {
    final offlineBook = StorageService.getOfflineBook(bookId);
    return offlineBook?.localFilePath;
  }

  // Check if book is available offline
  static Future<bool> isBookAvailableOffline(String bookId) async {
    final offlineBook = StorageService.getOfflineBook(bookId);
    if (offlineBook == null) return false;

    // Verify file still exists
    final file = File(offlineBook.localFilePath);
    final exists = await file.exists();

    if (!exists) {
      // File missing, update record
      offlineBook.isAvailable = false;
      await StorageService.saveOfflineBook(offlineBook);
    }

    return exists;
  }

  // Get all offline books
  static List<OfflineBook> getOfflineBooks() {
    return StorageService.getAllOfflineBooks();
  }

  // Remove offline book
  static Future<void> removeOfflineBook(String bookId) async {
    await StorageService.removeOfflineBook(bookId);
  }

  // Get offline storage info
  static Future<Map<String, dynamic>> getStorageInfo() async {
    final offlineBooks = getOfflineBooks();
    final totalSize = offlineBooks.fold<int>(
      0,
          (sum, book) => sum + book.fileSizeBytes,
    );

    final appDir = await getApplicationDocumentsDirectory();
    final offlineDir = Directory('${appDir.path}/$_offlineDir');

    return {
      'totalBooks': offlineBooks.length,
      'totalSizeBytes': totalSize,
      'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(1),
      'storagePath': offlineDir.path,
    };
  }

  // Cleanup orphaned files
  static Future<void> cleanupOrphanedFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final offlineDir = Directory('${appDir.path}/$_offlineDir');

      if (!await offlineDir.exists()) return;

      final files = await offlineDir.list().toList();
      final offlineBooks = getOfflineBooks();
      final validPaths = offlineBooks.map((book) => book.localFilePath).toSet();

      for (var file in files) {
        if (file is File && !validPaths.contains(file.path)) {
          await file.delete();
          print('🗑️ Deleted orphaned file: ${file.path}');
        }
      }
    } catch (e) {
      print('❌ Error during cleanup: $e');
    }
  }
}
