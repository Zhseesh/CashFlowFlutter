enum TxType {
  income('INCOME'),
  expense('EXPENSE');

  const TxType(this.dbValue);
  final String dbValue;

  String get label => this == TxType.income ? 'Pemasukan' : 'Pengeluaran';

  static TxType fromDb(String value) {
    switch (value) {
      case 'INCOME':
        return TxType.income;
      case 'EXPENSE':
        return TxType.expense;
    }
    throw FormatException('Tipe tidak dikenal: $value');
  }
}

T _field<T>(Map<String, dynamic> m, String key) {
  final v = m[key];
  if (v is T) return v;
  throw FormatException('Kolom "$key" tidak valid.');
}

class Category {
  const Category({
    this.id,
    required this.name,
    required this.type,
    required this.iconName,
    required this.colorHex,
  });

  final int? id;
  final String name;
  final TxType type;
  final String iconName;
  final String colorHex;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'type': type.dbValue,
        'icon_name': iconName,
        'color_hex': colorHex,
      };

  factory Category.fromMap(Map<String, Object?> m) => Category(
        id: m['id'] as int?,
        name: m['name'] as String,
        type: TxType.fromDb(m['type'] as String),
        iconName: m['icon_name'] as String,
        colorHex: m['color_hex'] as String,
      );

  Map<String, Object?> toJson() => toMap();

  /// Memvalidasi struktur JSON cadangan; melempar [FormatException].
  factory Category.fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Entri kategori tidak valid.');
    }
    final name = _field<String>(raw, 'name').trim();
    if (name.isEmpty) throw const FormatException('Nama kategori kosong.');
    return Category(
      id: _field<int>(raw, 'id'),
      name: name,
      type: TxType.fromDb(_field<String>(raw, 'type')),
      iconName: _field<String>(raw, 'icon_name'),
      colorHex: _field<String>(raw, 'color_hex'),
    );
  }
}

class CashTransaction {
  const CashTransaction({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    this.categoryId,
    required this.categoryName,
    required this.dateMillis,
    this.note,
  });

  final int? id;
  final String title;
  final double amount;
  final TxType type;
  final int? categoryId;
  final String categoryName;
  final int dateMillis;
  final String? note;

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(dateMillis);

  /// Positif untuk pemasukan, negatif untuk pengeluaran.
  double get signedAmount => type == TxType.income ? amount : -amount;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'amount': amount,
        'type': type.dbValue,
        'category_id': categoryId,
        'category_name': categoryName,
        'date_millis': dateMillis,
        'note': note,
      };

  factory CashTransaction.fromMap(Map<String, Object?> m) => CashTransaction(
        id: m['id'] as int?,
        title: m['title'] as String,
        amount: (m['amount'] as num).toDouble(),
        type: TxType.fromDb(m['type'] as String),
        categoryId: m['category_id'] as int?,
        categoryName: m['category_name'] as String,
        dateMillis: m['date_millis'] as int,
        note: m['note'] as String?,
      );

  Map<String, Object?> toJson() => toMap();

  factory CashTransaction.fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Entri transaksi tidak valid.');
    }
    final amount = _field<num>(raw, 'amount').toDouble();
    if (!amount.isFinite || amount < 0) {
      throw const FormatException('Nominal transaksi tidak valid.');
    }
    final cid = raw['category_id'];
    if (cid != null && cid is! int) {
      throw const FormatException('Kolom "category_id" tidak valid.');
    }
    final note = raw['note'];
    if (note != null && note is! String) {
      throw const FormatException('Kolom "note" tidak valid.');
    }
    return CashTransaction(
      id: _field<int>(raw, 'id'),
      title: _field<String>(raw, 'title'),
      amount: amount,
      type: TxType.fromDb(_field<String>(raw, 'type')),
      categoryId: cid as int?,
      categoryName: _field<String>(raw, 'category_name'),
      dateMillis: _field<int>(raw, 'date_millis'),
      note: note as String?,
    );
  }
}

class BackupData {
  const BackupData({
    required this.categories,
    required this.transactions,
    this.exportedAt,
  });

  final List<Category> categories;
  final List<CashTransaction> transactions;
  final String? exportedAt;
}

class ImportResult {
  const ImportResult({
    required this.categories,
    required this.transactions,
    this.skipped = 0,
  });

  final int categories;
  final int transactions;
  final int skipped;
}

class MonthTotal {
  const MonthTotal({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final double income;
  final double expense;

  double get net => income - expense;
}

class CategoryTotal {
  const CategoryTotal({
    required this.name,
    required this.colorHex,
    required this.iconName,
    required this.total,
    required this.count,
  });

  final String name;
  final String colorHex;
  final String iconName;
  final double total;
  final int count;
}
