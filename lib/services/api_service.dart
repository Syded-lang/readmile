import 'package:mongo_dart/mongo_dart.dart';
import 'package:readmile/models/book.dart';
import 'package:readmile/core/constants.dart';

class ApiService {
  static const String _connectionString = AppConstants.mongoDbConnectionString;

  static Future<List<Book>> fetchBooks() async {
    Db? db;
    try {
      print('🔄 Connecting to MongoDB Atlas...');

      db = await Db.create(_connectionString);
      await db.open();

      // Test connection
      final adminDb = db.useDb('admin');
      await adminDb.runCommand({'ping': 1});
      print('✅ Successfully connected to MongoDB Atlas');

      // Switch to library database and fetch books
      final libraryDb = db.useDb(AppConstants.databaseName);
      final collection = libraryDb.collection(AppConstants.booksCollection);

      final docs = await collection.find().toList();

      print('📚 Found ${docs.length} books in ${AppConstants.databaseName} collection');

      return docs.map((doc) => Book.fromJson(doc)).toList();

    } catch (e) {
      print('❌ MongoDB Connection Error: $e');
      throw Exception('Failed to fetch books from MongoDB Atlas: ${_getErrorMessage(e)}');
    } finally {
      await db?.close();
    }
  }

  static Future<Book?> fetchBookById(String bookId) async {
    Db? db;
    try {
      db = await Db.create(_connectionString);
      await db.open();

      final libraryDb = db.useDb(AppConstants.databaseName);
      final collection = libraryDb.collection(AppConstants.booksCollection);

      final doc = await collection.findOne(where.eq('_id', bookId));

      return doc != null ? Book.fromJson(doc) : null;
    } catch (e) {
      print('❌ Error fetching book by ID: $e');
      return null;
    } finally {
      await db?.close();
    }
  }

  static Future<List<Book>> searchBooks(String query) async {
    if (query.trim().isEmpty) return [];

    Db? db;
    try {
      db = await Db.create(_connectionString);
      await db.open();

      final libraryDb = db.useDb(AppConstants.databaseName);
      final collection = libraryDb.collection(AppConstants.booksCollection);

      // Search in title and author fields (case-insensitive)
      final docs = await collection.find({
        '\$or': [
          {'title': RegExp(query, caseSensitive: false)},
          {'author': RegExp(query, caseSensitive: false)},
        ]
      }).toList();

      print('🔍 Found ${docs.length} books matching "$query"');
      return docs.map((doc) => Book.fromJson(doc)).toList();

    } catch (e) {
      print('❌ Error searching books: $e');
      return [];
    } finally {
      await db?.close();
    }
  }

  static Future<List<Book>> fetchBooksByCategory(String category) async {
    if (category == 'All') {
      return fetchBooks();
    }

    Db? db;
    try {
      db = await Db.create(_connectionString);
      await db.open();

      final libraryDb = db.useDb(AppConstants.databaseName);
      final collection = libraryDb.collection(AppConstants.booksCollection);

      final docs = await collection.find({'categories': category}).toList();

      print('📂 Found ${docs.length} books in category "$category"');
      return docs.map((doc) => Book.fromJson(doc)).toList();

    } catch (e) {
      print('❌ Error fetching books by category: $e');
      return [];
    } finally {
      await db?.close();
    }
  }

  static Future<bool> testConnection() async {
    Db? db;
    try {
      db = await Db.create(_connectionString);
      await db.open();

      // Test with ping command
      final adminDb = db.useDb('admin');
      final result = await adminDb.runCommand({'ping': 1});

      final isOk = result['ok'] == 1 || result['ok'] == 1.0;

      if (isOk) {
        print('✅ MongoDB Atlas connection test successful');
      } else {
        print('❌ MongoDB Atlas ping returned: $result');
      }

      return isOk;
    } catch (e) {
      print('❌ MongoDB Atlas connection test failed: $e');
      return false;
    } finally {
      await db?.close();
    }
  }

  static Future<Map<String, dynamic>> getDatabaseInfo() async {
    Db? db;
    try {
      db = await Db.create(_connectionString);
      await db.open();

      final libraryDb = db.useDb(AppConstants.databaseName);
      final collection = libraryDb.collection(AppConstants.booksCollection);

      final totalBooks = await collection.count();
      final collections = await libraryDb.getCollectionNames();

      return {
        'totalBooks': totalBooks,
        'collections': collections,
        'database': AppConstants.databaseName,
        'connectionStatus': 'connected',
      };
    } catch (e) {
      print('❌ Error getting database info: $e');
      return {
        'totalBooks': 0,
        'collections': [],
        'database': AppConstants.databaseName,
        'connectionStatus': 'error',
        'error': e.toString(),
      };
    } finally {
      await db?.close();
    }
  }

  static Future<List<String>> getAvailableCategories() async {
    Db? db;
    try {
      db = await Db.create(_connectionString);
      await db.open();

      final libraryDb = db.useDb(AppConstants.databaseName);
      final collection = libraryDb.collection(AppConstants.booksCollection);

      // Get distinct categories
      final categories = await collection.distinct('categories');

      final categoryList = <String>['All'];
      for (var category in categories) {
        if (category is String && category.isNotEmpty) {
          categoryList.add(category);
        }
      }

      categoryList.sort();
      return categoryList;
    } catch (e) {
      print('❌ Error getting categories: $e');
      return ['All', 'Uncategorised'];
    } finally {
      await db?.close();
    }
  }

  static String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('network') || errorStr.contains('socket')) {
      return 'Network connection failed. Check your internet connection.';
    } else if (errorStr.contains('timeout')) {
      return 'Connection timeout. Please try again.';
    } else if (errorStr.contains('authentication') || errorStr.contains('credential')) {
      return 'Authentication failed. Invalid database credentials.';
    } else if (errorStr.contains('dns') || errorStr.contains('host')) {
      return 'Cannot reach MongoDB server. Check your connection.';
    } else {
      return 'Database connection error. Please try again later.';
    }
  }
}
