import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/transaction.dart';
import '../theme/neo_theme.dart';
import '../utils/formatters.dart';

class TransactionTile extends StatelessWidget {
  final TransactionRecord transaction;
  final ValueChanged<TransactionRecord>? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    final ink = Neo.ink(context);
    final iconColor = isIncome ? NeoColors.lime : NeoColors.pink;
    final amountColor = isIncome ? NeoColors.green : NeoColors.red;
    final sign = isIncome ? '+' : '-';
    final icon = isIncome ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap != null ? () => onTap!(transaction) : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Neo.paper(context),
            borderRadius: BorderRadius.circular(NeoRadius.reg),
            border: NeoBorders.reg(ink),
            boxShadow: NeoShadows.sm(ink),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor,
                  border: NeoBorders.thin(ink),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: NeoColors.inkLight),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: NeoText.body(14, weight: FontWeight.w700, color: ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${transaction.categoryName} · ${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                            style: NeoText.label(9, color: ink.withValues(alpha: 0.6)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (transaction.hasAttachment) ...[
                          const SizedBox(width: 4),
                          Icon(LucideIcons.paperclip, size: 11,
                              color: ink.withValues(alpha: 0.6)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$sign${formatCurrency(transaction.amount)}',
                style: NeoText.display(13, color: amountColor),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(LucideIcons.chevronRight, size: 18,
                    color: ink.withValues(alpha: 0.5)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}