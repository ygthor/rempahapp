import 'package:intl/intl.dart';
import 'package:kanesanapp/models/order_item.dart';
import 'package:kanesanapp/shared/functions.dart'; // for parseDoubleFromStringOrNum

class Order {
  final String? id;
  final String? orderType; // Add this new property
  final String? referenceNo;
  final String? branchId;
  final String? customerId;
  final String? customerCode;
  final String? customerName;
  final DateTime? orderDate;
  final String? status;
  final String? description;
  final double? grossAmount;
  final double? tax1;
  final double? tax1Percentage;
  final double? grandAmount;
  final double? discount;
  final double? netAmount;
  final String? remarks;
  final int? createdBy;
  final int? updatedBy;
  final List<OrderItem>? items;

  Order({
    this.id,
    this.orderType, // Add this here
    this.referenceNo,
    this.branchId,
    this.customerId,
    this.customerCode,
    this.customerName,
    this.orderDate,
    this.status,
    this.description,
    this.grossAmount,
    this.tax1,
    this.tax1Percentage,
    this.grandAmount,
    this.discount,
    this.netAmount,
    this.remarks,
    this.createdBy,
    this.updatedBy,
    this.items,
  });

  double get calculatedTotalAmount {
    return (items ?? []).fold(0.0, (sum, item) => sum + (item.amount ?? 0.0));
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (orderType != null) 'type': orderType, // Add to toJson as well
      if (referenceNo != null) 'reference_no': referenceNo,
      if (branchId != null) 'branch_id': branchId,
      if (customerId != null) 'customer_id': customerId,
      if (customerCode != null) 'customer_code': customerCode,
      if (customerName != null) 'customer_name': customerName,
      if (orderDate != null) 'order_date': DateFormat("yyyy-MM-dd").format(orderDate!),
      if (status != null) 'status': status,
      if (description != null) 'description': description,
      if (grossAmount != null) 'gross_amount': grossAmount,
      if (tax1 != null) 'tax1': tax1,
      if (tax1Percentage != null) 'tax1_percentage': tax1Percentage,
      if (grandAmount != null) 'grand_amount': grandAmount,
      if (discount != null) 'discount': discount,
      if (netAmount != null) 'net_amount': netAmount,
      if (remarks != null) 'remarks': remarks,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (items != null) 'items': items!.map((item) => item.toJson()).toList(),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsFromJson = json['items'] as List<dynamic>?;

    return Order(
      id: json['id']?.toString(),
      orderType: json['type'] as String?, // Map the new API field
      referenceNo: json['reference_no'] as String?,
      branchId: json['branch_id'] as String?,
      customerId: json['customer_id']?.toString(),
      customerCode: json['customer_code'] as String?,
      customerName: json['customer_name'] as String?,
      orderDate: json['order_date'] != null ? DateTime.tryParse(json['order_date']) : null,
      status: json['status'] as String?,
      description: json['description'] as String?,
      grossAmount: parseDoubleFromStringOrNum(json['gross_amount']),
      tax1: parseDoubleFromStringOrNum(json['tax1']),
      tax1Percentage: parseDoubleFromStringOrNum(json['tax1_percentage']),
      grandAmount: parseDoubleFromStringOrNum(json['grand_amount']),
      discount: parseDoubleFromStringOrNum(json['discount']),
      netAmount: parseDoubleFromStringOrNum(json['net_amount']),
      remarks: json['remarks'] as String?,
      createdBy: json['created_by'] as int?,
      updatedBy: json['updated_by'] as int?,
      items:
          itemsFromJson != null
              ? itemsFromJson.map((item) => OrderItem.fromJson(item as Map<String, dynamic>)).toList()
              : null,
    );
  }
}
