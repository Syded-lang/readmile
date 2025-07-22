import 'package:mongo_dart/mongo_dart.dart';
import 'package:readmile/core/constants.dart';
import 'dart:typed_data';

class GridFSService {
  static const String _connectionString = AppConstants.mongoDbConnectionString;

  Future<Uint8List?> getCoverImage(String gridfsId) async {
    try {
      print('📥 Downloading cover image from GridFS: $gridfsId');

      final db = await Db.create(_connectionString);
      await db.open();

      final chunksCollection = db.collection('fs.chunks');
      final objectId = ObjectId.fromHexString(gridfsId);

      final cursor = chunksCollection.find(where.eq('files_id', objectId).sortBy('n'));
      final chunks = await cursor.toList();

      if (chunks.isEmpty) {
        print('❌ No cover image chunks found for: $gridfsId');
        await db.close();
        return null;
      }

      List<int> allBytes = [];
      for (var chunk in chunks) {
        final data = chunk['data'];
        if (data is BsonBinary) {
          allBytes.addAll(data.byteList);
        }
      }

      await db.close();

      print('✅ Cover image downloaded: ${allBytes.length} bytes');
      return Uint8List.fromList(allBytes);

    } catch (e) {
      print('❌ Error fetching cover from GridFS: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getFileInfo(String gridfsId) async {
    try {
      final db = await Db.create(_connectionString);
      await db.open();

      final filesCollection = db.collection('fs.files');
      final objectId = ObjectId.fromHexString(gridfsId);

      final fileInfo = await filesCollection.findOne(where.eq('_id', objectId));
      await db.close();

      return fileInfo;
    } catch (e) {
      print('❌ Error fetching GridFS file info: $e');
      return null;
    }
  }

  Future<bool> fileExists(String gridfsId) async {
    try {
      final db = await Db.create(_connectionString);
      await db.open();

      final filesCollection = db.collection('fs.files');
      final objectId = ObjectId.fromHexString(gridfsId);

      final count = await filesCollection.count(where.eq('_id', objectId));
      await db.close();

      return count > 0;
    } catch (e) {
      print('❌ Error checking GridFS file existence: $e');
      return false;
    }
  }
}
