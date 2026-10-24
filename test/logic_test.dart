import 'package:cashflow/export/csv_exporter.dart';
import 'package:cashflow/export/json_backup.dart';
import 'package:cashflow/models/models.dart';
import 'package:cashflow/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RupiahInputFormatter', () {
    test('mengelompokkan ribuan dengan titik', () {
      expect(RupiahInputFormatter.group('1500000'), '1.500.000');
      expect(RupiahInputFormatter.group('999'), '999');
      expect(RupiahInputFormatter.group('1000'), '1.000');
    });

    test('parse menghapus titik', () {
      expect(RupiahInputFormatter.parse('1.500.000'), 1500000);
      expect(RupiahInputFormatter.parse(''), 0);
    });
  });

  group('CsvExporter', () {
    final txs = [
      CashTransaction(
        id: 1,
        title: 'Gaji; Oktober',
        amount: 5000000,
        type: TxType.income,
        categoryName: 'Gaji',
        dateMillis: DateTime(2026, 10, 1, 9, 30).millisecondsSinceEpoch,
      ),
      CashTransaction(
        id: 2,
        title: '=SUM(A1)',
        amount: 150000,
        type: TxType.expense,
        categoryName: 'Makanan',
        dateMillis: DateTime(2026, 10, 2, 12, 0).millisecondsSinceEpoch,
        note: 'makan "siang"',
      ),
    ];

    test('header, saldo berjalan, dan escaping', () {
      final csv = CsvExporter.build(
        transactions: txs,
        openingBalance: 1000000,
      );
      expect(csv.startsWith('﻿ID;Tanggal;Waktu;Tipe;Kategori;Judul;Catatan;Nominal;Saldo Berjalan'),
          isTrue);
      expect(csv.contains('"Gaji; Oktober"'), isTrue);
      expect(csv.contains(';6000000\r\n'), isTrue);
      expect(csv.contains(';5850000\r\n'), isTrue);
      expect(csv.contains("'=SUM(A1)"), isTrue);
      expect(csv.contains('"makan ""siang"""'), isTrue);
    });
  });

  group('JsonBackup', () {
    const cat = Category(
        id: 1,
        name: 'Gaji',
        type: TxType.income,
        iconName: 'payments',
        colorHex: '#10B981');
    const tx = CashTransaction(
      id: 7,
      title: 'Gaji',
      amount: 100,
      type: TxType.income,
      categoryId: 1,
      categoryName: 'Gaji',
      dateMillis: 1700000000000,
    );

    test('encode lalu parse menghasilkan data yang sama', () {
      final json = JsonBackup.encode(
          BackupData(categories: [cat], transactions: [tx]));
      final back = JsonBackup.parse(json);
      expect(back.categories.single.name, 'Gaji');
      expect(back.transactions.single.id, 7);
      expect(back.transactions.single.categoryId, 1);
    });

    test('menolak berkas tidak valid', () {
      expect(() => JsonBackup.parse('bukan json'), throwsFormatException);
      expect(() => JsonBackup.parse('{"app":"lain"}'), throwsFormatException);
      expect(
        () => JsonBackup.parse(
            '{"app":"com.zsheesh.cashflow","schema_version":99,"categories":[],"transactions":[]}'),
        throwsFormatException,
      );
    });
  });
}
