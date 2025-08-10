// lib/models/invoice.dart

import 'ar_trans_item.dart';

class Invoice {
  final int id;
  final String? refNo;
  final String? type;
  final String? name;
  final String? custNo;
  final DateTime? date;
  final double netBil;
  final double grandBil;
  final double grossBill;
  final String? status;
  final String? note;
  final List<ArTransItem> items;

  Invoice({
    required this.id,
    this.refNo,
    this.type,
    this.name,
    this.custNo,
    this.date,
    required this.netBil,
    required this.grandBil,
    required this.grossBill,
    this.status,
    this.note,
    this.items = const [],
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    // Helper to parse items list safely
    List<ArTransItem> parseItems(dynamic itemsJson) {
      if (itemsJson is List) {
        return itemsJson.map((item) => ArTransItem.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    }

    // --- FIX: Robust parsing for numeric values ---
    double parseDoubleSafe(dynamic value) {
      if (value == null) return 0.0;
      if (value is String) return double.tryParse(value) ?? 0.0;
      if (value is num) return value.toDouble();
      return 0.0;
    }

    return Invoice(
      id: json['id'] as int? ?? 0,
      refNo: json['REFNO'] as String?,
      type: json['TYPE'] as String?,
      name: json['NAME'] as String?,
      custNo: json['CUSTNO'] as String?,
      date: json['DATE'] != null ? DateTime.tryParse(json['DATE']) : null,
      // Use the safe parser for all numeric fields
      netBil: parseDoubleSafe(json['NET_BIL']),
      grandBil: parseDoubleSafe(json['GRAND_BIL']),
      grossBill: parseDoubleSafe(json['GROSS_BILL']),
      status: json['status'] as String? ?? 'pending', // Default status
      note: json['NOTE'] as String?, // Default status
      items: parseItems(json['items']),
    );
  }
}
