import 'dart:typed_data';
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:readmile/core/constants.dart';
import 'package:readmile/services/gridfs_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class EpubService {
  static const String _connectionString = AppConstants.mongoDbConnectionString;
  final GridFSService _gridfsService = GridFSService();

  // Session cache for performance
  static final Map<String, String> _epubCache = {};
  static final Map<String, List<String>> _chapterCache = {};
  static final Map<String, Map<int, String>> _contentCache = {};

  /// Get chapters with smart caching for faster loading
  Future<List<String>> getOnlineChapters(String bookId) async {
    // Check cache first
    if (_chapterCache.containsKey(bookId)) {
      print('📚 Using cached chapters for $bookId');
      return _chapterCache[bookId]!;
    }

    try {
      final db = await Db.create(_connectionString);
      await db.open();

      final booksCollection = db.collection(AppConstants.booksCollection);
      final bookDoc = await booksCollection.findOne(where.eq('_id', bookId));

      if (bookDoc == null) {
        await db.close();
        throw Exception('Book not found: $bookId');
      }

      final gridfsEpubId = bookDoc['gridfs_epub_id'];
      if (gridfsEpubId == null) {
        await db.close();
        throw Exception('EPUB file not found for book: $bookId');
      }

      await db.close();

      // Download and cache EPUB once
      final chapters = await _downloadAndCacheEpub(
          gridfsEpubId.toString(),
          bookDoc['epub_filename'] ?? 'book.epub',
          bookId
      );

      _chapterCache[bookId] = chapters;
      return chapters;

    } catch (e) {
      print('❌ Error getting chapters: $e');
      return ['Chapter 1'];
    }
  }

  /// Fast chapter content loading with pre-cached EPUB
  Future<String> getOnlineChapterContent(String bookId, int chapterIndex) async {
    try {
      // Check content cache first
      if (_contentCache[bookId]?.containsKey(chapterIndex) == true) {
        print('⚡ Using cached content for chapter $chapterIndex');
        return _contentCache[bookId]![chapterIndex]!;
      }

      // Use cached EPUB file
      final epubPath = _epubCache[bookId];
      if (epubPath == null) {
        // Fallback: load chapters first (which caches the EPUB)
        await getOnlineChapters(bookId);
        return getOnlineChapterContent(bookId, chapterIndex);
      }

      // Extract content from cached EPUB
      final content = await _extractChapterContent(epubPath, chapterIndex);

      // Cache the content
      _contentCache[bookId] ??= {};
      _contentCache[bookId]![chapterIndex] = content;

      return content;

    } catch (e) {
      print('❌ Error getting chapter content: $e');
      return 'Error loading chapter content. Please try again.';
    }
  }

  /// Download EPUB once and cache for session
  Future<List<String>> _downloadAndCacheEpub(String gridfsEpubId, String filename, String bookId) async {
    try {
      // Extract hex string if needed
      String hexString = gridfsEpubId;
      if (gridfsEpubId.startsWith('ObjectId("') && gridfsEpubId.endsWith('")')) {
        hexString = gridfsEpubId.substring(10, gridfsEpubId.length - 2);
      }

      print('📥 Caching EPUB for session: $bookId');

      final db = await Db.create(_connectionString);
      await db.open();

      final chunksCollection = db.collection('fs.chunks');
      final objectId = ObjectId.fromHexString(hexString);

      final cursor = chunksCollection.find(where.eq('files_id', objectId).sortBy('n'));
      final chunks = await cursor.toList();

      if (chunks.isEmpty) {
        await db.close();
        return ['Chapter 1'];
      }

      List<int> allBytes = [];
      for (var chunk in chunks) {
        final data = chunk['data'];
        if (data is BsonBinary) {
          allBytes.addAll(data.byteList);
        }
      }

      await db.close();

      // Save to temp file and cache path
      final tempDir = await getTemporaryDirectory();
      final readmileTempDir = Directory('${tempDir.path}/readmile_temp');
      if (!await readmileTempDir.exists()) {
        await readmileTempDir.create(recursive: true);
      }

      final tempFile = File('${readmileTempDir.path}/cached_$bookId.epub');
      await tempFile.writeAsBytes(allBytes);

      _epubCache[bookId] = tempFile.path;

      // Extract chapters
      final chapters = await _parseEpubChapters(tempFile.path);

      print('⚡ EPUB cached for fast access: ${chapters.length} chapters');
      return chapters;

    } catch (e) {
      print('❌ Error caching EPUB: $e');
      return ['Chapter 1'];
    }
  }

  /// Parse EPUB structure (optimized version)
  Future<List<String>> _parseEpubChapters(String epubPath) async {
    try {
      final file = File(epubPath);
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final List<String> chapters = [];

      // Find content.opf file
      ArchiveFile? contentOpf;
      for (final archiveFile in archive) {
        if (archiveFile.name.endsWith('.opf') || archiveFile.name.contains('content')) {
          contentOpf = archiveFile;
          break;
        }
      }

      if (contentOpf != null) {
        final opfContent = String.fromCharCodes(contentOpf.content as List<int>);
        try {
          final opfDoc = XmlDocument.parse(opfContent);

          // Extract spine items
          final spineItems = opfDoc.findAllElements('itemref');
          int chapterNum = 1;

          for (final item in spineItems) {
            final idref = item.getAttribute('idref');
            if (idref != null) {
              chapters.add('Chapter $chapterNum');
              chapterNum++;
            }
          }
        } catch (xmlError) {
          print('⚠️ XML parsing error: $xmlError');
        }
      }

      // Fallback: scan for HTML files
      if (chapters.isEmpty) {
        int chapterNum = 1;
        for (final archiveFile in archive) {
          if (archiveFile.name.endsWith('.html') || archiveFile.name.endsWith('.xhtml')) {
            chapters.add('Chapter $chapterNum');
            chapterNum++;
          }
        }
      }

      return chapters.isEmpty ? ['Chapter 1'] : chapters;

    } catch (e) {
      print('❌ Error parsing EPUB: $e');
      return ['Chapter 1'];
    }
  }

  /// Extract content from cached EPUB (fast)
  Future<String> _extractChapterContent(String epubPath, int chapterIndex) async {
    try {
      final file = File(epubPath);
      if (!await file.exists() || epubPath.isEmpty) {
        print('❌ EPUB file not found: $epubPath');
        return 'EPUB file not found. Please try downloading the book again.';
      }

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find HTML files
      final htmlFiles = <ArchiveFile>[];
      for (final archiveFile in archive) {
        if (archiveFile.name.endsWith('.html') || archiveFile.name.endsWith('.xhtml')) {
          htmlFiles.add(archiveFile);
        }
      }

      if (htmlFiles.isEmpty) {
        return 'No readable content found.';
      }

      // Get specific chapter
      final chapterFile = htmlFiles[chapterIndex % htmlFiles.length];
      final htmlContent = String.fromCharCodes(chapterFile.content as List<int>);

      // Parse and clean content
      try {
        final doc = XmlDocument.parse(htmlContent);
        final bodyElements = doc.findAllElements('body');

        if (bodyElements.isNotEmpty) {
          String textContent = bodyElements.first.innerText;

          // Clean up text
          textContent = textContent
              .replaceAll(RegExp(r'\s+'), ' ')
              .replaceAll(RegExp(r'\n+'), '\n\n')
              .trim();

          // Reasonable length for mobile reading
          if (textContent.length > 8000) {
            textContent = textContent.substring(0, 8000) + '...\n\n[Content continues...]';
          }

          return textContent.isEmpty ? 'Chapter content not available.' : textContent;
        }
      } catch (xmlError) {
        // Fallback text extraction
        return _simpleTextExtraction(htmlContent);
      }

      return 'Unable to extract chapter content.';

    } catch (e) {
      print('❌ Content extraction error: $e');
      return 'Error reading chapter from EPUB file.';
    }
  }

  /// Simple text extraction fallback
  String _simpleTextExtraction(String htmlContent) {
    String text = htmlContent
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (text.length > 8000) {
      text = text.substring(0, 8000) + '...\n\n[Content continues...]';
    }

    return text.isEmpty ? 'No readable text found.' : text;
  }

  /// Offline chapters (same caching logic)
  Future<List<String>> getOfflineChapters(String filePath) async {
    try {
      if (filePath.isEmpty) {
        print('❌ Empty file path provided to getOfflineChapters');
        return ['Chapter 1'];
      }
      return await _parseEpubChapters(filePath);
    } catch (e) {
      print('❌ Error getting offline chapters: $e');
      return ['Chapter 1'];
    }
  }

  Future<String> getOfflineChapterContent(String filePath, int chapterIndex) async {
    try {
      if (filePath.isEmpty) {
        print('❌ Empty file path provided to getOfflineChapterContent');
        return 'Offline file not available. Please download the book again.';
      }
      return await _extractChapterContent(filePath, chapterIndex);
    } catch (e) {
      print('❌ Error getting offline content: $e');
      return 'Error loading offline content.';
    }
  }

  /// Clear cache when needed
  static void clearCache() {
    _epubCache.clear();
    _chapterCache.clear();
    _contentCache.clear();
    print('🧹 EPUB cache cleared');
  }
}
