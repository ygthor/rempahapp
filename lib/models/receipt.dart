// lib/models/receipt.dart

import 'package:intl/intl.dart';

// The single, authoritative definition for the Receipt class.
class Receipt {
  final int? id;
  final String receiptNo;
  final int customerId;
  final String customerName;
  final String customerCode;
  final DateTime receiptDate;
  final String paymentType;
  final double paidAmount;
  // Other fields from the full model if needed for detail view
  final double? debtAmount;
  final double? transactionAmount;
  final String? chequeNo;
  final String? chequeType;
  final String? bankName;
  final String? paymentReferenceNo;

  Receipt({
    required this.id,
    required this.receiptNo,
    required this.customerId,
    required this.customerName,
    required this.customerCode,
    required this.receiptDate,
    required this.paymentType,
    required this.paidAmount,
    this.debtAmount,
    this.transactionAmount,
    this.chequeNo,
    this.chequeType,
    this.bankName,
    this.paymentReferenceNo,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse numeric values that might be strings or numbers
    double? parseDoubleSafe(dynamic value) {
      if (value == null) return null;
      if (value is String) return double.tryParse(value);
      if (value is num) return value.toDouble();
      return null;
    }

    // Helper function to safely parse integer values
    int? parseIntSafe(dynamic value) {
      if (value == null) return null;
      if (value is String) return int.tryParse(value);
      if (value is num) return value.toInt();
      return null;
    }

    return Receipt(
      id: json['id'],
      receiptNo: json['receipt_no'] as String? ?? 'N/A',
      customerId:
          parseIntSafe(json['customer_id']) ?? 0, // Safely parse customer_id
      customerName: json['customer_name'] as String? ?? 'Unknown Customer',
      customerCode: json['customer_code'] as String? ?? 'N/A',
      receiptDate:
          json['receipt_date'] != null
              ? DateTime.parse(json['receipt_date'] as String)
              : DateTime.now(),
      paymentType: json['payment_type'] as String? ?? 'N/A',
      paidAmount:
          parseDoubleSafe(json['paid_amount']) ?? 0.0, // Use safe parser
      debtAmount: parseDoubleSafe(json['debt_amount']), // Use safe parser
      transactionAmount: parseDoubleSafe(
        json['transaction_amount'],
      ), // Use safe parser
      chequeNo: json['cheque_no'] as String?,
      chequeType: json['cheque_type'] as String?,
      bankName: json['bank_name'] as String?,
      paymentReferenceNo: json['payment_reference_no'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receipt_no': receiptNo,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_code': customerCode,
      'receipt_date': DateFormat("yyyy-MM-dd HH:mm:ss").format(receiptDate),
      'payment_type': paymentType,
      'debt_amount': debtAmount,
      'transaction_amount': transactionAmount,
      'paid_amount': paidAmount,
      'cheque_no': chequeNo,
      'cheque_type': chequeType,
      'bank_name': bankName,
      'payment_reference_no': paymentReferenceNo,
    };
  }
}
