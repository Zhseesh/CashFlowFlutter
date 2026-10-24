import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Pemformat angka dan tanggal (locale Indonesia).
class Fmt {
  Fmt._();

  static final NumberFormat _rp = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  static final NumberFormat _num = NumberFormat.decimalPattern('id_ID');

  /// Contoh: Rp 1.500.000
  static String rupiah(num v) => _rp.format(v);

  /// Contoh: 1.500.000
  static String number(num v) => _num.format(v);

  /// Ringkas untuk label sumbu grafik: 1,5 jt / 250 rb.
  static String compact(double v) {
    String s(double x) {
      final t = x.toStringAsFixed(1);
      return t.endsWith('.0') ? t.substring(0, t.length - 2) : t;
    }

    final a = v.abs();
    if (a >= 1e12) return '${s(v / 1e12)} T';
    if (a >= 1e9) return '${s(v / 1e9)} M';
    if (a >= 1e6) return '${s(v / 1e6)} jt';
    if (a >= 1e3) return '${s(v / 1e3)} rb';
    return v.round().toString();
  }

  static String date(DateTime d) => DateFormat('d MMM yyyy', 'id_ID').format(d);
  static String dateShort(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  static String time(DateTime d) => DateFormat('HH:mm').format(d);
  static String monthYear(DateTime d) =>
      DateFormat('MMMM yyyy', 'id_ID').format(d);
  static String monthShort(DateTime d) => DateFormat('MMM', 'id_ID').format(d);
  static String monthYearShort(DateTime d) =>
      DateFormat('MMM yy', 'id_ID').format(d);
  static String stamp([DateTime? d]) =>
      DateFormat('yyyyMMdd_HHmm').format(d ?? DateTime.now());
}

/// Input nominal dengan pemisah ribuan titik otomatis (1.500.000).
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (digits.length > 15) digits = digits.substring(0, 15);
    final text = group(digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// Menyisipkan titik tiap tiga digit dari kanan.
  static String group(String digits) {
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      b.write(digits[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) b.write('.');
    }
    return b.toString();
  }

  static double parse(String text) =>
      double.tryParse(text.replaceAll('.', '')) ?? 0;
}
