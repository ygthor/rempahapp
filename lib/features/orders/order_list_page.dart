import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // For date formatting - add to pubspec.yaml

// Assuming OrderPage is in a file named 'order_form_page.dart'
// You might need to adjust the import path based on your project structure.
// If OrderPage is in the same file (which is unlikely for a real app), you wouldn't need this import.
import './order_form_page.dart'; // Placeholder for your actual OrderPage import

// --- Data Models (Copied from order_form_page.dart for self-containment in this example) ---
// In a real app, these models should be in a separate file and imported by both pages.
class OrderItem {
  final String productId;
  final String productName;
  final String skuCode;
  double quantity;
  double unitPrice;
  double discount; // Could be a percentage or a fixed amount
  bool isFreeGood;
  // Trade Return specific fields
  bool isTradeReturn;
  bool
  tradeReturnIsGood; // true if Good, false if Bad (only if isTradeReturn is true)

  OrderItem({
    required this.productId,
    required this.productName,
    required this.skuCode,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
    this.isFreeGood = false,
    this.isTradeReturn = false,
    this.tradeReturnIsGood = true, // Default to good if it's a return
  });

  double get amount {
    if (isFreeGood) return 0.0;
    return (quantity * unitPrice) - discountValue;
  }

  double get discountValue {
    // Assuming discount is a fixed amount for simplicity here.
    return discount;
  }
}

class Order {
  String? id; // Optional: A unique ID for the order
  String customerId;
  String customerName;
  List<OrderItem> items;
  DateTime orderDate;
  String status; // Example: 'Pending', 'Processing', 'Completed', 'Cancelled'

  Order({
    this.id,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.orderDate,
    this.status = 'Pending', // Default status
  });

  double get totalAmount {
    return items.fold(0.0, (sum, item) => sum + item.amount);
  }
}
// --- End of Copied Data Models ---

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  // Sample list of orders - in a real app, this would come from a database or API
  final List<Order> _orders = [
    Order(
      id: 'ORD001',
      customerId: 'CUST001',
      customerName: 'AHS3185 S02 KANESAN',
      orderDate: DateTime.now().subtract(const Duration(days: 1)),
      status: 'Completed',
      items: [
        OrderItem(
          productId: 'p1',
          productName: 'Product A1',
          skuCode: 'SKU001',
          quantity: 2,
          unitPrice: 10.00,
        ),
        OrderItem(
          productId: 'p2',
          productName: 'Product A2',
          skuCode: 'SKU002',
          quantity: 1,
          unitPrice: 12.50,
          discount: 2.50,
        ),
      ],
    ),
    Order(
      id: 'ORD002',
      customerId: 'CUST002',
      customerName: 'Bita Retail Store',
      orderDate: DateTime.now().subtract(const Duration(hours: 5)),
      status: 'Processing',
      items: [
        OrderItem(
          productId: 'p4',
          productName: 'Product C1',
          skuCode: 'SKU004',
          quantity: 5,
          unitPrice: 20.00,
        ),
        OrderItem(
          productId: 'p5',
          productName: 'Product C2',
          skuCode: 'SKU005',
          quantity: 10,
          unitPrice: 22.00,
          isFreeGood: true,
        ),
      ],
    ),
    Order(
      id: 'ORD003',
      customerId: 'CUST001',
      customerName: 'AHS3185 S02 KANESAN',
      orderDate: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      status: 'Pending',
      items: [
        OrderItem(
          productId: 'p3',
          productName: 'Product B1',
          skuCode: 'SKU003',
          quantity: 3,
          unitPrice: 15.00,
        ),
      ],
    ),
    Order(
      id: 'ORD004',
      customerId: 'CUST003',
      customerName: 'Charlie Wholesale',
      orderDate: DateTime.now().subtract(const Duration(days: 5)),
      status: 'Cancelled',
      items: [
        OrderItem(
          productId: 'p1',
          productName: 'Product A1',
          skuCode: 'SKU001',
          quantity: 10,
          unitPrice: 10.00,
        ),
      ],
    ),
  ];

  void _navigateToCreateOrderPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OrderFormPage(),
      ), // Navigate to your Order Creation Page
    ).then((newOrder) {
      // Optional: Handle the result if the OrderPage returns a new order
      if (newOrder != null && newOrder is Order) {
        setState(() {
          _orders.insert(0, newOrder); // Add new order to the top of the list
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New order for ${newOrder.customerName} created!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _navigateToOrderDetailPage(Order order) {
    Get.to(() => OrderFormPage());
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return FontAwesomeIcons.circleCheck;
      case 'processing':
        return FontAwesomeIcons.spinner; // Or FontAwesomeIcons.arrowsRotate
      case 'pending':
        return FontAwesomeIcons.clock;
      case 'cancelled':
        return FontAwesomeIcons.circleXmark;
      default:
        return FontAwesomeIcons.circleQuestion;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort orders by date, newest first
    _orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order List'),
        // backgroundColor: Theme.of(context).primaryColor, // Example
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Orders',
            onPressed: () {
              // TODO: Implement refresh logic (e.g., re-fetch from API)
              setState(() {}); // Simple redraw for now
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Orders refreshed (mock data).'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body:
          _orders.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      FontAwesomeIcons.fileCircleXmark,
                      size: 60,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No orders found.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap the + button to create a new order.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  return Card(
                    elevation: 3.0,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 6.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: InkWell(
                      // Makes the card tappable
                      onTap: () => _navigateToOrderDetailPage(order),
                      borderRadius: BorderRadius.circular(12.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  order.id ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColorDark,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      order.status,
                                    ).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getStatusIcon(order.status),
                                        size: 14,
                                        color: _getStatusColor(order.status),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        order.status,
                                        style: TextStyle(
                                          color: _getStatusColor(order.status),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              order.customerName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  FontAwesomeIcons.calendarDay,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('dd MMM yyyy, hh:mm a').format(
                                    order.orderDate,
                                  ), // Using intl for formatting
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Total: \$${order.totalAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateOrderPage,
        tooltip: 'Create New Order',
        icon: const Icon(Icons.add_shopping_cart_outlined),
        label: const Text('New Order'),
        // backgroundColor: Theme.of(context).colorScheme.secondary, // Example
      ),
    );
  }
}

/*
To use this page:
1.  Ensure you have the `intl` package in your `pubspec.yaml` for date formatting:
    ```yaml
    dependencies:
      flutter:
        sdk: flutter
      font_awesome_flutter: ^latest_version # Check pub.dev
      intl: ^latest_version # Check pub.dev
    ```
    Then run `flutter pub get`.
2.  Make sure the `OrderPage` (your order creation form) is correctly imported.
    The current import is `import './order_form_page.dart';`. Adjust this path if your
    order creation page file is named differently or located elsewhere.
3.  In a real application, replace the `_orders` list with data fetched from your backend/API.
4.  Implement the `_navigateToOrderDetailPage` method to navigate to a page showing details of a selected order.
*/
