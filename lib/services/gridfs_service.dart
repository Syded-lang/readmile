import 'package:mongo_dart/mongo_dart.dart';
import 'package:readmile/core/constants.dart';
import 'dart:typed_data';

class GridFSService {
  static const String _connectionString =
      'mongodb+srv://mikiemillsyded:Fishpoder123%23@readmile.igbtpmz.mongodb.net/library?retryWrites=true&w=majority&appName=ReadMile';

  Future<Uint8List?> getCoverImage(String gridfsId) async {
    try {
      print('📥 Using working chunking method for cover: $gridfsId');

      final db = await Db.create(_connectionString);
      await db.open();

      // This chunking method worked before
      final chunksCollection = db.collection('fs.chunks');
      final objectId = ObjectId.fromHexString(gridfsId);

      final cursor = chunksCollection.find(where.eq('files_id', objectId).sortBy('n'));
      final chunks = await cursor.toList();

      if (chunks.isEmpty) {
        await db.close();
        return null;
      }

      print('📦 Found ${chunks.length} chunks (chunking method working)');

      List<int> allBytes = [];
      for (var chunk in chunks) {
        final data = chunk['data'];
        if (data is BsonBinary) {
          allBytes.addAll(data.byteList);
        }
      }

      await db.close();
      return Uint8List.fromList(allBytes);

    } catch (e) {
      print('❌ GridFS chunking error: $e');
      return null;
    }
  }
}
