import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/controller_scope.dart';
import '../utils/format.dart';
import 'add_transaction_sheet.dart';
import 'widgets/transaction_tile.dart';

/// Riwayat seluruh transaksi dengan filter tipe, ubah, dan hapus.
class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  TxType? _filter;

  Future<void> _confirmDelete(CashTransaction tx) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus transaksi?'),
        content: Text('"${tx.title}" sebesar ${Fmt.rupiah(tx.amount)} akan dihapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true && tx.id != null && mounted) {
      await ControllerScope.of(context).deleteTransaction(tx.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final theme = Theme.of(context);
    final list = c.allTransactions
        .where((t) => _filter == null || t.type == _filter)
        .toList();

    final items = <Object>[];
    DateTime? last;
    for (final t in list) {
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      if (last != d) {
        items.add(d);
        last = d;
      }
      items.add(t);
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Riwayat',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                ChoiceChip(
                  label: const Text('Pemasukan'),
                  selected: _filter == TxType.income,
                  onSelected: (_) => setState(() => _filter = TxType.income),
                ),
                ChoiceChip(
                  label: const Text('Pengeluaran'),
                  selected: _filter == TxType.expense,
                  onSelected: (_) => setState(() => _filter = TxType.expense),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text('Tidak ada transaksi.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 96),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      if (item is DateTime) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 14, bottom: 2),
                          child: Text(Fmt.date(item),
                              style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.primary)),
                        );
                      }
                      final tx = item as CashTransaction;
                      return TransactionTile(
                        tx: tx,
                        onTap: () =>
                            showTransactionSheet(context, existing: tx),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'edit') {
                              showTransactionSheet(context, existing: tx);
                            } else {
                              _confirmDelete(tx);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Ubah')),
                            PopupMenuItem(value: 'delete', child: Text('Hapus')),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
