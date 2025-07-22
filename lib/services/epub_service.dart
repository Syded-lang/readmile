import 'package:mongo_dart/mongo_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'dart:io';

class EpubService {
  static const String _connectionString =
      'mongodb+srv://mikiemillsyded:Fishpoder123%23@readmile.igbtpmz.mongodb.net/library?retryWrites=true&w=majority&appName=ReadMile';

  Future<String?> downloadEpubToTemp(String gridfsId, String filename) async {
    try {
      print('📥 Using working EPUB chunking method...');
      print('📁 GridFS ID: $gridfsId');

      final db = await Db.create(_connectionString);
      await db.open();

      final chunksCollection = db.collection('fs.chunks');
      final objectId = ObjectId.fromHexString(gridfsId);

      final cursor = chunksCollection.find(where.eq('files_id', objectId).sortBy('n'));
      final chunks = await cursor.toList();

      if (chunks.isEmpty) {
        print('❌ No chunks found for GridFS ID: $gridfsId');
        await db.close();
        return null;
      }

      print('📦 Found ${chunks.length} chunks (chunking method)');

      List<int> allBytes = [];
      for (var chunk in chunks) {
        final data = chunk['data'];
        if (data is BsonBinary) {
          allBytes.addAll(data.byteList);
        }
      }

      await db.close();

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$filename');
      await tempFile.writeAsBytes(allBytes);

      print('✅ EPUB downloaded using chunking: ${tempFile.path}');
      return tempFile.path;

    } catch (e) {
      print('❌ EPUB chunking error: $e');
      return null;
    }
  }

  // ADDED: Missing deleteTemp method
  Future<void> deleteTemp(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('🗑️ Deleted temp file: $filePath');
      }
    } catch (e) {
      print('⚠️ Error deleting temp file: $e');
    }
  }

  Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final readmileTempDir = Directory('${tempDir.path}/readmile_temp');

      if (await readmileTempDir.exists()) {
        final files = await readmileTempDir.list().toList();
        for (var file in files) {
          if (file is File) {
            await file.delete();
          }
        }
        print('🧹 Cleaned up ${files.length} temp files');
      }
    } catch (e) {
      print('⚠️ Error cleaning up temp files: $e');
    }
  }
}
