/// A payment row, mirroring `public.transactions`.
class Transaction {
  const Transaction({
    required this.id,
    required this.success,
    required this.description,
    required this.amount,
    required this.currency,
    required this.dayLabel,
    required this.timeLabel,
    this.txId,
  });

  final String id;
  final bool success;
  final String description;
  final int amount;
  final String currency;
  final String dayLabel;
  final String timeLabel;
  final String? txId;

  String get amountLabel => '$currency$amount';

  factory Transaction.fromMap(Map<String, dynamic> m) {
    return Transaction(
      id: m['id'] as String,
      success: m['success'] == true,
      description: (m['description'] as String?) ?? '',
      amount: (m['amount'] as int?) ?? 0,
      currency: (m['currency'] as String?) ?? '₹',
      dayLabel: (m['day_label'] as String?) ?? '',
      timeLabel: (m['time_label'] as String?) ?? '',
      txId: m['tx_id'] as String?,
    );
  }
}
