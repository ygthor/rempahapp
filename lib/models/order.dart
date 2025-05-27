import 'package:rempahapp/models/order_item.dart';
import 'package:intl/intl.dart';
import 'package:rempahapp/shared/functions.dart'; // For date parsing/formatting if needed, though not directly used in fromJson/toJson here

class Order {
  final String? id; // Server-assigned order ID
  final String
  customerId; // This is the string ID like "AHS3185" from your form
  final String customerName;
  final List<OrderItem> items;
  final DateTime orderDate;
  final String status; // e.g., 'pending', 'processing', 'completed'
  final double? totalAmountFromApi; // If API calculates and returns total
  final String? remarks; // Added from Laravel model

  Order({
    this.id,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.orderDate,
    this.status = 'pending', // Default status
    this.totalAmountFromApi,
    this.remarks,
  });

  // Calculated total amount on the client-side
  double get calculatedTotalAmount {
    return items.fold(0.0, (sum, item) => sum + item.amount);
  }

  // For sending to API (when creating a new order)
  Map<String, dynamic> toJson() {
    return {
      // 'id': id, // Usually not sent when creating, server assigns it
      'customer_id': customerId, // Send the string ID from Flutter form
      'customer_name': customerName,
      'order_date': DateFormat(
        "yyyy-MM-dd HH:mm:ss",
      ).format(orderDate), // Format for API
      'status': status,
      'remarks': remarks,
      // 'total_amount': calculatedTotalAmount, // API calculates this on the backend
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  // For creating from API response
  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsFromJson = json['items'] as List<dynamic>?;
    List<OrderItem> parsedItems = [];
    if (itemsFromJson != null) {
      parsedItems =
          itemsFromJson
              .map(
                (itemJson) =>
                    OrderItem.fromJson(itemJson as Map<String, dynamic>),
              )
              .toList();
    }

    return Order(
      id: json['id']?.toString(),
      // Assuming API returns customer_id as the same string identifier used by Flutter
      // If API returns an integer foreign key for customer, this needs adjustment
      customerId: json['customer_id']?.toString() ?? 'unknown_cust_id',
      customerName: json['customer_name'] as String? ?? 'Unknown Customer',
      items: parsedItems,
      orderDate:
          json['order_date'] != null
              ? DateTime.parse(json['order_date'] as String)
              : DateTime.now(),
      status: json['status'] as String? ?? 'Pending',
      totalAmountFromApi: parseDoubleFromStringOrNum(
        json['total_amount'],
      ), // Corrected parsing
      remarks: json['remarks'] as String?,
    );
  }
}
