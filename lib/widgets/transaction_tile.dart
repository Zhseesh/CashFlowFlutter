import 'package:flutter/material.dart';
import '../models/transaction.dart';
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
    final color = isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final sign = isIncome ? '+' : '-';
    final icon = isIncome ? Icons.south_west : Icons.north_east;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap != null ? () => onTap!(transaction) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${transaction.categoryName} • ${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                              style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade600, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (transaction.hasAttachment) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.attach_file, size: 11, color: Colors.grey.shade500),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$sign${formatCurrency(transaction.amount)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey.shade400),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}