import 'package:hive/hive.dart';

part 'book.g.dart';

@HiveType(typeId: 2)
class Book {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String author;

  @HiveField(3)
  final String coverUrl;

  @HiveField(4)
  final String filePath;

  @HiveField(5)
  final String category;

  @HiveField(6)
  final DateTime publishedDate;

  @HiveField(7)
  final String description;

  @HiveField(8)
  final String? gridfsEpubId;

  @HiveField(9)
  final String? epubFilename;

  @HiveField(10)
  final int? epubFileSizeBytes;

  @HiveField(11)
  final List<String> categories;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.filePath,
    required this.category,
    required this.publishedDate,
    required this.description,
    this.gridfsEpubId,
    this.epubFilename,
    this.epubFileSizeBytes,
    this.categories = const [],
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown Title',
      author: json['author']?.toString() ?? 'Unknown Author',
      // Use gridfs_cover_id for coverUrl
      coverUrl: json['gridfs_cover_id']?.toString() ?? '',
      filePath: json['filePath']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Uncategorized',
      publishedDate: json['publishedDate'] != null
          ? DateTime.tryParse(json['publishedDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      description: json['description']?.toString() ?? 'No description available',
      // Use correct field name from your MongoDB
      gridfsEpubId: json['gridfs_epub_id']?.toString(),
      epubFilename: json['epub_filename']?.toString(),
      epubFileSizeBytes: json['epub_file_size_bytes'] as int?,
      categories: json['categories'] != null
          ? List<String>.from(json['categories'])
          : [],
    );
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book.fromJson(map);
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'author': author,
      'gridfs_cover_id': coverUrl,
      'filePath': filePath,
      'category': category,
      'publishedDate': publishedDate.toIso8601String(),
      'description': description,
      'gridfs_epub_id': gridfsEpubId,
      'epub_filename': epubFilename,
      'epub_file_size_bytes': epubFileSizeBytes,
      'categories': categories,
    };
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }

  @override
  String toString() {
    return 'Book(id: $id, title: $title, author: $author)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Book && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
