import 'package:rempahapp/models/order_item.dart';

class Order {
  String? id;
  String customerId;
  String customerName;
  List<OrderItem> items;
  DateTime orderDate;

  Order({
    this.id,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.orderDate,
  });

  double get totalAmount {
    return items.fold(0.0, (sum, item) => sum + item.amount);
  }
}
