import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../category_icons.dart';

/// Grafik batang berpasangan: pemasukan vs pengeluaran per bulan.
class ComparisonBarChart extends StatelessWidget {
  const ComparisonBarChart({
    super.key,
    required this.data,
    this.height = 200,
    this.showAxis = true,
  });

  final List<MonthTotal> data;
  final double height;
  final bool showAxis;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarPainter(
          data: data,
          gridColor: cs.outlineVariant.withAlpha(120),
          textColor: cs.onSurfaceVariant,
          showAxis: showAxis,
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.data,
    required this.gridColor,
    required this.textColor,
    required this.showAxis,
  });

  final List<MonthTotal> data;
  final Color gridColor;
  final Color textColor;
  final bool showAxis;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    const bottomPad = 22.0;
    const topPad = 8.0;
    final leftPad = showAxis ? 46.0 : 0.0;
    final chartH = size.height - bottomPad - topPad;
    final chartW = size.width - leftPad;

    var maxV = 0.0;
    for (final d in data) {
      maxV = math.max(maxV, math.max(d.income, d.expense));
    }
    final top = _niceMax(maxV);

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = topPad + chartH - chartH * i / 4;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), grid);
      if (showAxis) {
        _text(canvas, Fmt.compact(top * i / 4), Offset(leftPad - 6, y),
            align: TextAlign.right);
      }
    }

    final groupW = chartW / data.length;
    final barW = math.min(groupW * 0.28, 22.0);
    final incomePaint = Paint()..color = AppColors.income;
    final expensePaint = Paint()..color = AppColors.expense;
    const radius = Radius.circular(4);

    for (var i = 0; i < data.length; i++) {
      final d = data[i];
      final cx = leftPad + groupW * (i + 0.5);
      final incomeH = chartH * d.income / top;
      final expenseH = chartH * d.expense / top;
      final base = topPad + chartH;

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(cx - barW - 1.5, base - incomeH, barW, incomeH),
          topLeft: radius,
          topRight: radius,
        ),
        incomePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(cx + 1.5, base - expenseH, barW, expenseH),
          topLeft: radius,
          topRight: radius,
        ),
        expensePaint,
      );
      _text(canvas, Fmt.monthShort(d.month), Offset(cx, base + 6),
          align: TextAlign.center);
    }
  }

  void _text(Canvas canvas, String s, Offset anchor,
      {TextAlign align = TextAlign.left}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: textColor, fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    switch (align) {
      case TextAlign.right:
        tp.paint(canvas, Offset(anchor.dx - tp.width, anchor.dy - tp.height / 2));
      case TextAlign.center:
        tp.paint(canvas, Offset(anchor.dx - tp.width / 2, anchor.dy));
      default:
        tp.paint(canvas, anchor);
    }
  }

  static double _niceMax(double v) {
    if (v <= 0) return 1000;
    final exp = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    final f = v / exp;
    final double nf;
    if (f <= 1) {
      nf = 1;
    } else if (f <= 2) {
      nf = 2;
    } else if (f <= 2.5) {
      nf = 2.5;
    } else if (f <= 5) {
      nf = 5;
    } else {
      nf = 10;
    }
    return nf * exp;
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) => true;
}

class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String t) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(t, style: Theme.of(context).textTheme.labelMedium),
          ],
        );
    return Wrap(
      spacing: 16,
      children: [
        item(AppColors.income, 'Pemasukan'),
        item(AppColors.expense, 'Pengeluaran'),
      ],
    );
  }
}

/// Baris rincian kategori dengan progress bar persentase.
class CategoryBar extends StatelessWidget {
  const CategoryBar({super.key, required this.item, required this.fraction});

  final CategoryTotal item;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(item.colorHex);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withAlpha(40),
                child: Icon(iconFor(item.iconName), size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Text(Fmt.rupiah(item.total), style: amountStyle(context, size: 13)),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                child: Text(
                  '${(fraction * 100).toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 8,
              color: color,
              backgroundColor: color.withAlpha(35),
            ),
          ),
        ],
      ),
    );
  }
}
