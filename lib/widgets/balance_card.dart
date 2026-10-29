import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../utils/app_state.dart';
import '../utils/formatters.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;
  const BalanceCard({super.key, required this.balance, required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<bool>(
      valueListenable: AppState.hideBalance,
      builder: (context, isHidden, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark 
                  ? [const Color(0xFF059669), const Color(0xFF064E3B)] 
                  : [const Color(0xFF34D399), const Color(0xFF059669)], 
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.translate('current_balance'), // <-- DINAMIS
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)
                  ),
                  GestureDetector(
                    onTap: () => AppState.hideBalance.value = !isHidden,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined, 
                        color: Colors.white, 
                        size: 18
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isHidden ? 'Rp ••••••••' : formatCurrency(balance), 
                style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: -1)
              ),
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMini(Icons.arrow_downward, l10n.translate('income'), isHidden ? 'Rp ••••••' : formatCurrency(income))
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: Colors.white.withValues(alpha: 0.3),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    Expanded(
                      child: _buildMini(Icons.arrow_upward, l10n.translate('expense'), isHidden ? 'Rp ••••••' : formatCurrency(expense))
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildMini(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 12),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}