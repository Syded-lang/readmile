import 'package:mongo_dart/mongo_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:readmile/core/constants.dart';
import 'dart:typed_data';
import 'dart:io';

class EpubService {
  static const String _connectionString = AppConstants.mongoDbConnectionString;

  Future<String?> downloadEpubToTemp(String gridfsId, String filename) async {
    try {
      print('📥 Starting EPUB download from GridFS...');
      print('📁 GridFS ID: $gridfsId');
      print('📄 Filename: $filename');

      final db = await Db.create(_connectionString);
      await db.open();

      // Use your actual GridFS collections
      final chunksCollection = db.collection('fs.chunks');
      final objectId = ObjectId.fromHexString(gridfsId);

      final cursor = chunksCollection.find(where.eq('files_id', objectId).sortBy('n'));
      final chunks = await cursor.toList();

      if (chunks.isEmpty) {
        print('❌ No chunks found for GridFS ID: $gridfsId');
        await db.close();
        return null;
      }

      print('📦 Found ${chunks.length} chunks in GridFS');

      List<int> allBytes = [];
      for (var chunk in chunks) {
        final data = chunk['data'];
        if (data is BsonBinary) {
          allBytes.addAll(data.byteList);
        }
      }

      await db.close();

      final tempDir = await getTemporaryDirectory();
      final readmileTempDir = Directory('${tempDir.path}/${AppConstants.tempDirectory}');
      if (!await readmileTempDir.exists()) {
        await readmileTempDir.create(recursive: true);
      }

      final tempFile = File('${readmileTempDir.path}/$filename');
      await tempFile.writeAsBytes(allBytes);

      print('✅ EPUB downloaded from MongoDB GridFS: ${tempFile.path}');
      print('📊 File size: ${allBytes.length} bytes');

      return tempFile.path;

    } catch (e) {
      print('❌ Error downloading EPUB from GridFS: $e');
      return null;
    }
  }

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
      final readmileTempDir = Directory('${tempDir.path}/${AppConstants.tempDirectory}');

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

  Future<bool> verifyEpubFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      final bytes = await file.readAsBytes();

      // Check if file starts with ZIP signature (EPUB is essentially a ZIP file)
      if (bytes.length < 4) return false;

      return bytes[0] == 0x50 && bytes[1] == 0x4B &&
          (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07);
    } catch (e) {
      print('❌ Error verifying EPUB file: $e');
      return false;
    }
  }
}
