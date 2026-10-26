import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
final _date = DateFormat('dd MMM yyyy', 'id_ID');

String formatCurrency(num v) => _currency.format(v);
String formatDate(DateTime d) => _date.format(d);