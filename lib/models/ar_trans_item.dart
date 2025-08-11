// lib/models/ar_trans_item.dart

class ArTransItem {
  final String refNo;
  final String tranCode;
  final String description;
  final double quantity;
  final double price;
  final double amountBilled;

  ArTransItem({
    required this.refNo,
    required this.tranCode,
    required this.description,
    required this.quantity,
    required this.price,
    required this.amountBilled,
  });

  factory ArTransItem.fromJson(Map<String, dynamic> json) {
    // --- FIX: Robust parsing for numeric values ---
    double parseDoubleSafe(dynamic value) {
      if (value == null) return 0.0;
      if (value is String) return double.tryParse(value) ?? 0.0;
      if (value is num) return value.toDouble();
      return 0.0;
    }

    return ArTransItem(
      refNo: json['REFNO'] as String? ?? '',
      tranCode: json['TRANCODE'] as String? ?? 'N/A',
      description: json['DESP'] as String? ?? 'Unknown Item',
      // Use the safe parser here as well
      quantity: parseDoubleSafe(json['QTY']),
      price: parseDoubleSafe(json['PRICE']),
      amountBilled: parseDoubleSafe(json['AMT_BIL']),
    );
  }
}
