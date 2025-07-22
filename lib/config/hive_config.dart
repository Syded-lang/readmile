import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/offline_book.dart';
import '../models/reading_progress.dart';

class HiveConfig {
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register TextAlign adapter for ReadingSettings
    Hive.registerAdapter(_TextAlignAdapter());

    // Register models
    Hive.registerAdapter(OfflineBookAdapter());
    Hive.registerAdapter(ReadingProgressAdapter());
    // REMOVED: ReadingSettingsAdapter() - not needed since we use SharedPreferences

    // Open boxes
    await Hive.openBox<OfflineBook>('offlineBooks');
    await Hive.openBox<ReadingProgress>('readingProgress');
    // REMOVED: readingSettings box - not needed since we use SharedPreferences
  }
}

// Custom adapter for TextAlign enum
class _TextAlignAdapter extends TypeAdapter<TextAlign> {
  @override
  final int typeId = 10;

  @override
  TextAlign read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TextAlign.left;
      case 1:
        return TextAlign.right;
      case 2:
        return TextAlign.center;
      case 3:
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  @override
  void write(BinaryWriter writer, TextAlign obj) {
    switch (obj) {
      case TextAlign.left:
        writer.writeByte(0);
        break;
      case TextAlign.right:
        writer.writeByte(1);
        break;
      case TextAlign.center:
        writer.writeByte(2);
        break;
      case TextAlign.justify:
        writer.writeByte(3);
        break;
      default:
        writer.writeByte(0);
    }
  }
}