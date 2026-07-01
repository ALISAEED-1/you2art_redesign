import 'package:flutter/material.dart';

import 'data/models/transaction.dart';
import 'data/repositories/misc_repository.dart';
import 'widgets/empty_state.dart';

/// Transaction History — payments grouped by day, loaded from Supabase.
class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  // ── Theme ────────────────────────────────────────────────────────────
  static const Color _blue = Color(0xFF2F80ED);
  static const Color _green = Color(0xFF1F8A4D);
  static const Color _greenBadge = Color(0xFFBFF4D6);
  static const Color _red = Color(0xFFE53935);
  static const Color _redBadge = Color(0xFFFFD9D9);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);

  final MiscRepository _repo = MiscRepository();
  late Future<List<Transaction>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<Transaction>>(
          future: _future,
          builder: (context, snapshot) {
            final txs = snapshot.data ?? const <Transaction>[];
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Text(
                    'Transaction History',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (txs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: EmptyState(message: 'No transactions yet.'),
                  )
                else
                  ..._buildGroups(txs),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  // Groups consecutive transactions by day label (data arrives day-ordered).
  List<Widget> _buildGroups(List<Transaction> txs) {
    final out = <Widget>[];
    var i = 0;
    while (i < txs.length) {
      final day = txs[i].dayLabel;
      final group = <Transaction>[];
      while (i < txs.length && txs[i].dayLabel == day) {
        group.add(txs[i]);
        i++;
      }
      final total = group
          .where((t) => t.success)
          .fold<int>(0, (sum, t) => sum + t.amount);
      final currency = group.isNotEmpty ? group.first.currency : '₹';
      out.addAll(_buildDay(day, '$currency$total', group));
    }
    return out;
  }

  List<Widget> _buildDay(String label, String total, List<Transaction> txs) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: _textSecondary, fontSize: 12),
              ),
            ),
            Text(
              total,
              style: const TextStyle(
                color: _blue,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      const Divider(color: Color(0xFFEFEFEF), thickness: 1, height: 1),
      for (final tx in txs)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: _txRow(tx),
        ),
    ];
  }

  Widget _txRow(Transaction t) {
    final statusText = t.success ? 'Successful!' : 'Failed!';
    final statusColor = t.success ? _green : _red;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: t.success ? _greenBadge : _redBadge,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: t.success
                ? Image.asset(
                    'assets/images/true_icon.png',
                    width: 18,
                    height: 18,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.check, color: _green, size: 18),
                  )
                : const Icon(Icons.block, color: _red, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                  children: [
                    TextSpan(text: '${t.description} '),
                    if (t.txId != null)
                      TextSpan(
                        text: t.txId,
                        style: const TextStyle(
                          color: _blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                t.timeLabel,
                style: const TextStyle(color: _textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          t.amountLabel,
          style: TextStyle(
            color: statusColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
