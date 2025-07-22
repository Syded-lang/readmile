import 'package:mongo_dart/mongo_dart.dart';
import 'package:readmile/models/book.dart';
import 'package:readmile/core/constants.dart';

class ApiService {
  static const String _connectionString = AppConstants.mongoDbConnectionString;

  // Fallback connections with different TLS configurations
  static const List<String> _fallbackConnections = [
    // Permissive TLS settings for Android compatibility
    'mongodb+srv://mikiemillsyded:Fishpoder123%23@readmile.igbtpmz.mongodb.net/library?retryWrites=true&w=majority&appName=ReadMile&tls=true&tlsInsecure=true&tlsAllowInvalidCertificates=true',

    // Alternative TLS configuration
    'mongodb+srv://mikiemillsyded:Fishpoder123%23@readmile.igbtpmz.mongodb.net/library?retryWrites=true&w=majority&appName=ReadMile&ssl=true&sslAllowInvalidCertificates=true',

    // Direct connection without SSL (last resort)
    'mongodb://mikiemillsyded:Fishpoder123%23@readmile-shard-00-00.igbtpmz.mongodb.net:27017/library?authSource=admin&ssl=false',

    // Local development fallback
    'mongodb+srv://mikiemillsyded:Fishpoder123%23@readmile.igbtpmz.mongodb.net/library?retryWrites=false&w=majority&appName=ReadMile',
  ];

  /// Fetch books from MongoDB with enhanced fallback support
  static Future<List<Book>> fetchBooks() async {
    print('🔄 Starting MongoDB connection...');

    // Try primary connection first
    var result = await _attemptConnection(_connectionString, 'Primary');
    if (result.isNotEmpty) return result;

    // Try fallback connections
    for (int i = 0; i < _fallbackConnections.length; i++) {
      result = await _attemptConnection(_fallbackConnections[i], 'Fallback ${i + 1}');
      if (result.isNotEmpty) return result;
    }

    print('❌ All connection attempts failed - switching to offline mode');
    return [];
  }

  static Future<List<Book>> _attemptConnection(String connectionString, String label) async {
    Db? db;
    try {
      print('🔄 Attempting $label connection...');

      db = await Db.create(connectionString);
      await db.open().timeout(const Duration(seconds: 20)); // Set timeout for connection

      print('✅ $label connection established successfully');

      final collection = db.collection(AppConstants.booksCollection);
      final docs = await collection.find().timeout(const Duration(seconds: 15)).toList();

      print('📚 $label: Retrieved ${docs.length} books');
      return docs.map((doc) => Book.fromJson(doc)).toList();
    } catch (e) {
      await _handleConnectionError(e, label);
      return [];
    } finally {
      await _closeConnection(db, label);
    }
  }

  static Future<void> _handleConnectionError(dynamic e, String label) async {
    final errorString = e.toString();

    if (errorString.contains('HandshakeException') || errorString.contains('TLS negotiation failed')) {
      print('🔐 $label TLS Handshake Error: TLS negotiation failed');
      print('💡 Suggestion: Test on a physical device or switch networks');
    } else if (errorString.contains('SocketException')) {
      print('🌐 $label Network Error: $errorString');
      print('💡 Check internet connection and DNS settings');
    } else {
      print('❌ $label Error: $e');
    }
  }

  static Future<void> _closeConnection(Db? db, String label) async {
    if (db != null) {
      try {
        await db.close();
        print('🔒 $label connection closed');
      } catch (e) {
        print('⚠️ Error closing $label connection: $e');
      }
    }
  }

  /// Compatibility method for fetching books
  static Future<List<Book>> getBooks() async {
    return await fetchBooks();
  }
}