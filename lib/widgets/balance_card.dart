import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;
  const BalanceCard({super.key, required this.balance, required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF115E59), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF10B981).withValues(alpha:0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Saldo Saat Ini', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Icon(Icons.account_balance_wallet_outlined, color: Colors.white.withValues(alpha:0.7), size: 22),
            ],
          ),
          const SizedBox(height: 8),
          Text(formatCurrency(balance), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _mini(Icons.south_west, 'Pemasukan', income, Colors.greenAccent.shade100)),
              const SizedBox(width: 12),
              Expanded(child: _mini(Icons.north_east, 'Pengeluaran', expense, const Color(0xFFFCA5A5))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mini(IconData icon, String label, double val, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.12), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
          const SizedBox(height: 6),
          Text(formatCurrency(val),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}