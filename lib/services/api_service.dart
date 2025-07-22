import 'package:mongo_dart/mongo_dart.dart';
import 'package:readmile/models/book.dart';
import 'package:readmile/core/constants.dart';

class ApiService {
  // CORRECTED: Include database name directly in connection string
  static const String _connectionString =
      'mongodb+srv://mikiemillsyded:Fishpoder123%23@readmile.igbtpmz.mongodb.net/library?retryWrites=true&w=majority&appName=ReadMile';

  // Add the getBooks method that book_provider expects
  Future<List<Book>> getBooks() async {
    return await fetchBooks();
  }

  static Future<List<Book>> fetchBooks() async {
    Db? db;
    try {
      print('🔄 Connecting to library database directly...');

      // Connect directly to the library database (no useDb needed)
      db = await Db.create(_connectionString);
      await db.open();

      print('✅ Connected to MongoDB Atlas library database');

      // Query the books collection directly
      final collection = db.collection('books');

      print('🔍 Querying books collection...');
      final docs = await collection.find().toList();

      print('📚 Found ${docs.length} books in collection');

      // Debug: Print first document structure if available
      if (docs.isNotEmpty) {
        print('📄 Sample document keys: ${docs.first.keys.toList()}');
        print('📄 Sample title: ${docs.first['title']}');
      }

      return docs.map((doc) => Book.fromJson(doc)).toList();

    } catch (e) {
      print('❌ MongoDB Error: $e');
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

      // Test with a simple count query
      final collection = db.collection('books');
      final count = await collection.count();

      print('✅ Connection test successful - found $count documents');
      return true;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    } finally {
      await db?.close();
    }
  }

  // Debug method to verify database contents
  static Future<void> debugDatabase() async {
    Db? db;
    try {
      db = await Db.create(_connectionString);
      await db.open();

      final collection = db.collection('books');

      // Get collection stats
      final count = await collection.count();
      print('📊 Total documents in books collection: $count');

      // Get first few documents
      final sampleDocs = await collection.find().take(3).toList();
      print('📄 Sample documents:');
      for (var doc in sampleDocs) {
        print('  - ${doc['title']} by ${doc['author']}');
      }

    } catch (e) {
      print('❌ Debug error: $e');
    } finally {
      await db?.close();
    }
  }
}