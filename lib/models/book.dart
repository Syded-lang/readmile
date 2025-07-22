import 'package:mongo_dart/mongo_dart.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String epubFilename;
  final String coverFilename;
  final String gridfsEpubId;
  final String gridfsCoverId;
  final List<String> categories;
  final int epubFileSizeBytes;
  final int coverFileSizeBytes;
  final DateTime uploadDate;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.epubFilename,
    required this.coverFilename,
    required this.gridfsEpubId,
    required this.gridfsCoverId,
    required this.categories,
    required this.epubFileSizeBytes,
    required this.coverFileSizeBytes,
    required this.uploadDate,
  });

  String get primaryCategory => categories.isNotEmpty ? categories.first : 'All';

  factory Book.fromJson(Map<String, dynamic> json) {
    try {
      return Book(
        id: json['_id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Unknown Title',
        author: json['author']?.toString() ?? 'Unknown Author',
        epubFilename: json['epub_filename']?.toString() ?? '',
        coverFilename: json['cover_filename']?.toString() ?? '',
        gridfsEpubId: _parseObjectId(json['gridfs_epub_id']),
        gridfsCoverId: _parseObjectId(json['gridfs_cover_id']),
        categories: _parseCategories(json['categories']),
        epubFileSizeBytes: _parseInt(json['epub_file_size_bytes']),
        coverFileSizeBytes: _parseInt(json['cover_file_size_bytes']),
        uploadDate: _parseDate(json['upload_date']),
      );
    } catch (e) {
      print('Error parsing book: $e');
      print('Raw JSON: $json');
      rethrow;
    }
  }

  static String _parseObjectId(dynamic value) {
    if (value == null) return '';
    if (value is ObjectId) return value.toHexString();
    return value.toString();
  }

  static List<String> _parseCategories(dynamic value) {
    if (value == null) return ['All'];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [value.toString()];
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'epubFilename': epubFilename,
      'coverFilename': coverFilename,
      'gridfsEpubId': gridfsEpubId,
      'gridfsCoverId': gridfsCoverId,
      'categories': categories,
      'epubFileSizeBytes': epubFileSizeBytes,
      'coverFileSizeBytes': coverFileSizeBytes,
      'uploadDate': uploadDate.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Book && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
