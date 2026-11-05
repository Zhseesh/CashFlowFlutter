import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// Format standar dengan IDR
final _currency = NumberFormat.currency(locale: 'en_US', symbol: 'IDR ', decimalDigits: 2);
// Format pendek tanpa IDR (khusus untuk widget mini)
final _currencyShort = NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 2);
final _date = DateFormat('dd MMM yyyy', 'id_ID');

String formatCurrency(num v) => _currency.format(v);
String formatCurrencyShort(num v) => _currencyShort.format(v).trim();
String formatDate(DateTime d) => _date.format(d);

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    String raw = newValue.text;
    int cursorPos = newValue.selection.baseOffset;

    bool isUserTypingDecimal = false;
    if (cursorPos > 0 && cursorPos <= raw.length) {
      String charBeforeCursor = raw.substring(cursorPos - 1, cursorPos);
      if (charBeforeCursor == ',' || charBeforeCursor == '.') {
        isUserTypingDecimal = true;
      }
    }

    if (isUserTypingDecimal) {
      int commaIdx = raw.lastIndexOf(',');
      if (commaIdx != -1 && commaIdx == cursorPos - 1) {
        raw = '${raw.substring(0, commaIdx)}.${raw.substring(commaIdx + 1)}';
      }
    }

    String noThousands = raw.replaceAll(',', '');

    int lastDot = noThousands.lastIndexOf('.');
    String integerPart = '';
    String decimalPart = '';

    if (lastDot != -1) {
      integerPart = noThousands.substring(0, lastDot);
      decimalPart = noThousands.substring(lastDot + 1);
    } else {
      integerPart = noThousands;
    }

    integerPart = integerPart.replaceAll(RegExp(r'[^0-9]'), '');

    if (decimalPart.length > 2) {
      decimalPart = decimalPart.substring(0, 2);
    }

    String formattedInteger = '';
    if (integerPart.isNotEmpty) {
      try {
        formattedInteger = NumberFormat.decimalPattern('en_US').format(int.parse(integerPart));
      } catch (e) {
        formattedInteger = integerPart;
      }
    }

    String formattedText = formattedInteger;
    if (lastDot != -1) {
      formattedText = '$formattedText.$decimalPart';
    }

    int digitsBeforeCursor = 0;
    for (int i = 0; i < cursorPos && i < raw.length; i++) {
      if (RegExp(r'[0-9]').hasMatch(raw[i])) digitsBeforeCursor++;
    }

    int newCursorPos = formattedText.length;
    if (digitsBeforeCursor < formattedText.replaceAll(RegExp(r'[^0-9]'), '').length) {
      int count = 0;
      for (int i = 0; i < formattedText.length; i++) {
        if (RegExp(r'[0-9]').hasMatch(formattedText[i])) {
          count++;
          if (count == digitsBeforeCursor) {
            newCursorPos = i + 1;
            if (newCursorPos < formattedText.length && formattedText[newCursorPos] == '.') {
              newCursorPos++;
            }
            break;
          }
        }
      }
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
  }
}