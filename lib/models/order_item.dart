import 'package:intl/intl.dart'; // For date parsing/formatting if needed, though not directly used in fromJson/toJson here

// Assuming your Product model is defined elsewhere and imported if needed by OrderItem for richer data
// For example: import 'package:rempahapp/models/product.dart';

class OrderItem {
  final String
  productId; // In Flutter, this was 'p1', 'p2'. API expects integer ID.
  final String productName;
  final String skuCode;
  double quantity;
  double unitPrice;
  double discount;
  bool isFreeGood;
  bool isTradeReturn;
  bool tradeReturnIsGood;
  // Optional: Store the server-assigned ID for the order item if API returns it
  final String? id; // e.g., if order items have their own IDs in the database

  OrderItem({
    this.id, // Optional ID from server
    required this.productId,
    required this.productName,
    required this.skuCode,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
    this.isFreeGood = false,
    this.isTradeReturn = false,
    this.tradeReturnIsGood = true,
  });

  double get amount {
    if (isFreeGood) return 0.0;
    return (quantity * unitPrice) -
        discount; // Assuming discount is a fixed amount
  }

  // For sending to API
  Map<String, dynamic> toJson() {
    return {
      // 'id': id, // Usually not sent when creating new items, server assigns it
      'product_id': productId, // Ensure this is the integer ID your API expects
      'product_name': productName,
      'sku_code': skuCode,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discount,
      'is_free_good': isFreeGood,
      'is_trade_return': isTradeReturn,
      'trade_return_is_good': tradeReturnIsGood,
    };
  }

  // For creating from API response
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse numeric values that might be strings or numbers
    double parseDoubleSafe(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is String) return double.tryParse(value) ?? defaultValue;
      if (value is num) return value.toDouble();
      return defaultValue;
    }

    return OrderItem(
      id:
          json['id']
              ?.toString(), // Server might return an int ID for the order_item record
      productId: json['product_id']?.toString() ?? 'unknown_pid',
      productName: json['product_name'] as String? ?? 'Unknown Product',
      skuCode: json['sku_code'] as String? ?? 'N/A',
      quantity: parseDoubleSafe(json['quantity']),
      unitPrice: parseDoubleSafe(json['unit_price']),
      discount: parseDoubleSafe(json['discount']),
      isFreeGood: json['is_free_good'] as bool? ?? false,
      isTradeReturn: json['is_trade_return'] as bool? ?? false,
      tradeReturnIsGood: json['trade_return_is_good'] as bool? ?? true,
    );
  }
}
