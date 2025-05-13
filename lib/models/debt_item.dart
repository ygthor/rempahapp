class DebtItem {
  final String salesNo;
  final DateTime salesDate;
  final String paymentType; // P.Type
  final String paymentTerm; // P.Term
  final DateTime dueDate;
  final double outstandingAmount;
  final String? currency; // e.g., "MYR", "USD"

  DebtItem({
    required this.salesNo,
    required this.salesDate,
    required this.paymentType,
    required this.paymentTerm,
    required this.dueDate,
    required this.outstandingAmount,
    this.currency = 'MYR',
  });
}
