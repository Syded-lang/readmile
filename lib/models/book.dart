class Book {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final String filePath;
  final String category;
  final DateTime publishedDate;
  final String description;
  final String? gridfsEpubId;
  final String? epubFilename;
  final int? epubFileSizeBytes;
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
      coverUrl: json['coverUrl']?.toString() ?? '',
      filePath: json['filePath']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Uncategorized',
      publishedDate: json['publishedDate'] != null
          ? DateTime.tryParse(json['publishedDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      description: json['description']?.toString() ?? 'No description available',
      gridfsEpubId: json['gridfsEpubId']?.toString(),
      epubFilename: json['epubFilename']?.toString(),
      epubFileSizeBytes: json['epubFileSizeBytes'] as int?,
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
      'coverUrl': coverUrl,
      'filePath': filePath,
      'category': category,
      'publishedDate': publishedDate.toIso8601String(),
      'description': description,
      'gridfsEpubId': gridfsEpubId,
      'epubFilename': epubFilename,
      'epubFileSizeBytes': epubFileSizeBytes,
      'categories': categories,
    };
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }
}