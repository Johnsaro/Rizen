class ExpenseEntry {
  final String id;
  final double amount;
  final String tagId;
  final String tagLabel; // populated from JOIN, not stored
  final String note;
  final String receiptPath;
  final DateTime createdAt;

  const ExpenseEntry({
    required this.id,
    required this.amount,
    required this.tagId,
    this.tagLabel = '',
    this.note = '',
    this.receiptPath = '',
    required this.createdAt,
  });

  bool get hasReceipt => receiptPath.isNotEmpty;

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'tag_id': tagId,
        'note': note,
        'receipt_path': receiptPath,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  factory ExpenseEntry.fromMap(Map<String, dynamic> map) => ExpenseEntry(
        id: map['id'] as String,
        amount: (map['amount'] as num).toDouble(),
        tagId: map['tag_id'] as String,
        tagLabel: (map['tag_label'] as String?) ?? '',
        note: (map['note'] as String?) ?? '',
        receiptPath: (map['receipt_path'] as String?) ?? '',
        createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      );
}
