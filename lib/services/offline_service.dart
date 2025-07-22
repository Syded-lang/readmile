import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../models/book.dart';
import '../models/offline_book.dart';
import '../services/gridfs_service.dart';

class OfflineService {
  final GridFSService _gridfsService = GridFSService();

  Future<OfflineBook> downloadBookForOffline(
      Book book,
      String gridfsEpubId, // Make non-nullable
      String epubFilename, // Make non-nullable
      ) async {
    try {
      // Get app directory
      final appDir = await getApplicationDocumentsDirectory();
      final offlineDir = Directory('${appDir.path}/offline_books');

      if (!await offlineDir.exists()) {
        await offlineDir.create(recursive: true);
      }

      // Create file paths
      final epubPath = '${offlineDir.path}/${book.id}.epub';
      final coverPath = '${offlineDir.path}/${book.id}_cover.jpg';

      // Download EPUB file
      final epubBytes = await _gridfsService.downloadFile(gridfsEpubId);
      await File(epubPath).writeAsBytes(epubBytes);

      // Download cover if available
      if (book.coverUrl.isNotEmpty) {
        try {
          // Assuming cover is also in GridFS or downloadable
          // You might need to adjust this based on your cover storage
          final coverBytes = await _gridfsService.downloadCover(book.id);
          await File(coverPath).writeAsBytes(coverBytes);
        } catch (e) {
          // Cover download failed, use empty path
          print('Cover download failed: $e');
        }
      }

      // Create OfflineBook with correct field names
      final offlineBook = OfflineBook(
        bookId: book.id, // Use bookId instead of id
        title: book.title,
        author: book.author,
        localFilePath: epubPath,
        coverPath: book.coverUrl.isNotEmpty ? coverPath : '', // Use coverPath instead of localCoverPath
        downloadDate: DateTime.now(), // Use downloadDate instead of downloadedAt
        fileSizeBytes: book.epubFileSizeBytes ?? 0,
        categories: book.categories,
        isAvailable: true,
        lastAccessDate: DateTime.now(),
      );

      return offlineBook;
    } catch (e) {
      throw Exception('Failed to download book for offline: $e');
    }
  }

  Future<void> markBookUnavailable(String bookId) async {
    // This method is referenced in your code
    try {
      // Find and mark book as unavailable instead of deleting
      // Implementation depends on your specific needs
      print('Marking book $bookId as unavailable');
    } catch (e) {
      throw Exception('Failed to mark book unavailable: $e');
    }
  }

  Future<Uint8List> getOfflineBookContent(String localFilePath) async {
    try {
      final file = File(localFilePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      } else {
        throw Exception('Offline book file not found');
      }
    } catch (e) {
      throw Exception('Failed to read offline book: $e');
    }
  }
}