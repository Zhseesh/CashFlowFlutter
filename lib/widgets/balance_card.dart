import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../l10n/app_localizations.dart';
import '../theme/neo_theme.dart';
import '../utils/app_state.dart';
import '../utils/formatters.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;
  const BalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ink = Neo.ink(context);

    return ValueListenableBuilder<bool>(
      valueListenable: AppState.hideBalance,
      builder: (context, isHidden, _) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: NeoColors.yellow,
            borderRadius: BorderRadius.circular(NeoRadius.lg),
            border: NeoBorders.thick(ink),
            boxShadow: NeoShadows.md(ink),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.translate('current_balance').toUpperCase(),
                    style: NeoText.label(11, color: NeoColors.inkLight),
                  ),
                  GestureDetector(
                    onTap: () => AppState.hideBalance.value = !isHidden,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: NeoColors.paperLight,
                        border: NeoBorders.thin(ink),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isHidden ? LucideIcons.eyeOff : LucideIcons.eye,
                        size: 16,
                        color: NeoColors.inkLight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                isHidden ? 'IDR ••••••••' : formatCurrency(balance),
                style: NeoText.display(30, color: NeoColors.inkLight),
              ),
              const SizedBox(height: 20),

              // Mini row income / expense
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: NeoColors.paperLight,
                  border: NeoBorders.thin(ink),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMini(
                        icon: LucideIcons.arrowDown,
                        label: l10n.translate('income'),
                        value: isHidden ? 'IDR ••••' : formatCurrency(income),
                        color: NeoColors.lime,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 36,
                      color: ink,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    Expanded(
                      child: _buildMini(
                        icon: LucideIcons.arrowUp,
                        label: l10n.translate('expense'),
                        value: isHidden ? 'IDR ••••' : formatCurrency(expense),
                        color: NeoColors.pink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMini({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            border: NeoBorders.thin(NeoColors.inkLight),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 12, color: NeoColors.inkLight),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: NeoText.label(9, color: NeoColors.inkLight),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: NeoText.body(12, weight: FontWeight.w700, color: NeoColors.inkLight),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}