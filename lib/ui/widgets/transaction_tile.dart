import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/controller_scope.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../category_icons.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.tx,
    this.onTap,
    this.trailing,
  });

  final CashTransaction tx;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cat = ControllerScope.of(context).categoryFor(tx);
    final color = hexToColor(cat?.colorHex ?? '#64748B');
    final isIncome = tx.type == TxType.income;
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withAlpha(40),
              child: Icon(iconFor(cat?.iconName ?? 'category'), color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${tx.categoryName} • ${Fmt.date(tx.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${isIncome ? '+' : '-'}${Fmt.rupiah(tx.amount)}',
              style: amountStyle(
                context,
                size: 14,
                color: isIncome ? AppColors.income : AppColors.expense,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
