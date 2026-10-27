import 'dart:typed_data';
import 'package:better_download_saver/better_download_saver.dart';

class ExportService {
  static final _saver = BetterDownloadSaver();

  /// Menyimpan file ke folder Download/Cash Flow/ (Publik)
  static Future<String?> saveToPublicDownloads({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    try {
      return await _saver.saveToDownloads(
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
      );
    } catch (e) {
      return null;
    }
  }

  /// Membersihkan nama file
  static String sanitizeName(String name) {
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }
}