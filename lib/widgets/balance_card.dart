import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;
  const BalanceCard({super.key, required this.balance, required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Gradient hijau sesuai prototipe
        gradient: LinearGradient(
          colors: isDark 
              ? [const Color(0xFF059669), const Color(0xFF064E3B)] // Dark Mode: emerald-600 ke emerald-900
              : [const Color(0xFF34D399), const Color(0xFF059669)], // Light Mode: emerald-400 ke emerald-600
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
              const Text(
                'Saldo Saat Ini', 
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)
              ),
              Icon(Icons.account_balance_wallet_outlined, color: Colors.white.withValues(alpha: 0.8), size: 22),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatCurrency(balance), 
            style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: -1)
          ),
          const SizedBox(height: 24),
          
          // Glassmorphism container untuk Pemasukan & Pengeluaran
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
                  child: _buildMini(Icons.arrow_downward, 'Pemasukan', income)
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withValues(alpha: 0.3),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  child: _buildMini(Icons.arrow_upward, 'Pengeluaran', expense)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMini(IconData icon, String label, double val) {
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
              Text(formatCurrency(val), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}