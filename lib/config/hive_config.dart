import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/offline_book.dart';
import '../models/reading_progress.dart';

class HiveConfig {
  static Future<void> init() async {
    await Hive.initFlutter();

    // Check if adapters are already registered to prevent duplicates
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(_TextAlignAdapter());
    }
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(OfflineBookAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ReadingProgressAdapter());
    }

    // Open boxes
    await Hive.openBox('offlineBooks');
    await Hive.openBox('readingProgress');
  }
}

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
