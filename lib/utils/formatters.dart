import 'package:intl/intl.dart';

// Menggunakan locale 'en_US' untuk format koma (,) dan titik (.)
final _currency = NumberFormat.currency(locale: 'en_US', symbol: 'IDR ', decimalDigits: 2);
final _date = DateFormat('dd MMM yyyy', 'id_ID');

String formatCurrency(num v) => _currency.format(v);
String formatDate(DateTime d) => _date.format(d);