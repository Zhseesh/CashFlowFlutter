import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AttachmentService {
  static const _subDir = 'attachments';

  static Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$_subDir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Buka picker, kembalikan path file sementara (null jika user cancel).
  static Future<({String path, String name})?> pick() async {
    final res = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (res.isEmpty) return null;
    final file = res.first;
    if (file.path == null) return null;
    return (path: file.path!, name: file.name);
  }

  /// Copy file dari [tempPath] ke direktori permanen aplikasi.
  /// Mengembalikan nama file yang disimpan (bukan path penuh).
  static Future<String> copyToPermanent(String tempPath) async {
    final dir = await _dir();
    final ext = p.extension(tempPath).toLowerCase();
    final filename =
        'att_${DateTime.now().microsecondsSinceEpoch}$ext';
    final dest = File('${dir.path}/$filename');
    await File(tempPath).copy(dest.path);
    return filename;
  }

  /// Resolve nama file menjadi [File] jika ada.
  static Future<File?> resolve(String? filename) async {
    if (filename == null) return null;
    final dir = await _dir();
    final f = File('${dir.path}/$filename');
    if (!await f.exists()) return null;
    return f;
  }

  /// Hapus file permanen berdasarkan nama.
  static Future<void> delete(String? filename) async {
    if (filename == null) return;
    final f = await resolve(filename);
    if (f != null) await f.delete();
  }

  /// Buka file dengan aplikasi yang sesuai.
  static Future<void> open(String filename) async {
    final f = await resolve(filename);
    if (f == null) throw Exception('File tidak ditemukan');
    final result = await OpenFilex.open(f.path);
    if (result.type != ResultType.done) {
      throw Exception(result.message);
    }
  }
}