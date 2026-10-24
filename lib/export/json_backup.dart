import 'dart:convert';

import '../models/models.dart';

/// Cadangan JSON berversi skema; impor divalidasi sebelum menyentuh database.
class JsonBackup {
  JsonBackup._();

  static const appId = 'com.zsheesh.cashflow';
  static const schemaVersion = 1;

  static String encode(BackupData data) {
    final map = <String, Object?>{
      'app': appId,
      'schema_version': schemaVersion,
      'exported_at': data.exportedAt ?? DateTime.now().toIso8601String(),
      'categories': data.categories.map((c) => c.toJson()).toList(),
      'transactions': data.transactions.map((t) => t.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  /// Melempar [FormatException] dengan pesan yang dapat ditampilkan ke pengguna.
  static BackupData parse(String source) {
    Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const FormatException('Berkas bukan JSON yang valid.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Struktur cadangan tidak dikenali.');
    }
    if (decoded['app'] != appId) {
      throw const FormatException('Berkas ini bukan cadangan Cash Flow.');
    }
    final version = decoded['schema_version'];
    if (version is! int) {
      throw const FormatException('Versi skema cadangan tidak valid.');
    }
    if (version > schemaVersion) {
      throw const FormatException(
          'Cadangan dibuat oleh versi aplikasi yang lebih baru.');
    }
    final rawCats = decoded['categories'];
    final rawTxs = decoded['transactions'];
    if (rawCats is! List || rawTxs is! List) {
      throw const FormatException(
          'Daftar kategori atau transaksi tidak ditemukan.');
    }

    final categories = <Category>[];
    final ids = <int>{};
    for (var i = 0; i < rawCats.length; i++) {
      try {
        final c = Category.fromJson(rawCats[i]);
        if (!ids.add(c.id!)) {
          throw FormatException('ID kategori ganda: ${c.id}');
        }
        categories.add(c);
      } on FormatException catch (e) {
        throw FormatException('Kategori #${i + 1}: ${e.message}');
      }
    }

    final transactions = <CashTransaction>[];
    final txIds = <int>{};
    for (var i = 0; i < rawTxs.length; i++) {
      try {
        final t = CashTransaction.fromJson(rawTxs[i]);
        if (!txIds.add(t.id!)) {
          throw FormatException('ID transaksi ganda: ${t.id}');
        }
        // Referensi kategori yang tidak ada dijadikan null (ON DELETE SET NULL).
        transactions.add(CashTransaction(
          id: t.id,
          title: t.title,
          amount: t.amount,
          type: t.type,
          categoryId: ids.contains(t.categoryId) ? t.categoryId : null,
          categoryName: t.categoryName,
          dateMillis: t.dateMillis,
          note: t.note,
        ));
      } on FormatException catch (e) {
        throw FormatException('Transaksi #${i + 1}: ${e.message}');
      }
    }

    return BackupData(
      categories: categories,
      transactions: transactions,
      exportedAt: decoded['exported_at'] is String
          ? decoded['exported_at'] as String
          : null,
    );
  }
}
