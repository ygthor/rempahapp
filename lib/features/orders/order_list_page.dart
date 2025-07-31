import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rempahapp/features/orders/order_form_page.dart';

// Assuming your models and ApiV1 are in these locations. Adjust paths as needed.
import 'package:rempahapp/models/global_state.dart';
import 'package:rempahapp/api/api_v1.dart';
import 'package:rempahapp/shared/functions.dart';

import '../../models/order.dart'; // Assuming aLog and showVDialog are here

// --- Data Models with fromJson ---
// (Ideally, move these to their own files in your models directory)

class OrderItem {
  final String productId;
  final String productName;
  final String skuCode;
  double quantity;
  double unitPrice;
  double discount;
  bool isFreeGood;
  bool isTradeReturn;
  bool tradeReturnIsGood;

  OrderItem({
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
    return (quantity * unitPrice) - discount;
  }

  double get discountValue => discount;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id']?.toString() ?? 'unknown_pid',
      productName: json['product_name'] as String? ?? 'Unknown Product',
      skuCode: json['sku_code'] as String? ?? 'N/A',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      isFreeGood: json['is_free_good'] as bool? ?? false,
      isTradeReturn: json['is_trade_return'] as bool? ?? false,
      tradeReturnIsGood: json['trade_return_is_good'] as bool? ?? true,
    );
  }
}

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  late ApiV1 _api;
  final List<Order> _orders = [];
  bool _isLoadingFirstTime = true;
  bool _isLoadingMore = false;
  String _errorMessage = '';

  int _currentPage = 1;
  int? _lastPage;
  bool _hasMoreItems = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    GlobalState gs = Get.find<GlobalState>();
    _api = ApiV1(bearerToken: gs.token);
    _fetchOrders(page: 1, isRefresh: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          _hasMoreItems &&
          !_isLoadingMore) {
        _fetchOrders(page: _currentPage + 1);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders({required int page, bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _orders.clear();
      setState(() {
        _isLoadingFirstTime = true;
        _hasMoreItems = true;
        _errorMessage = '';
      });
    } else {
      // Prevent multiple simultaneous "load more" requests
      if (_isLoadingMore || !_hasMoreItems) return;
      setState(() {
        _isLoadingMore = true;
        _errorMessage = '';
      });
    }

    try {
      // ApiV1.getAllOrders() returns the full Map from Laravel's makeResponse.
      // The API log shows: {"error":0,"status":200,"message":"...","data":{"current_page":1,"data":[ORDER_LIST]}}
      final Map<String, dynamic>? responseMap = await _api.getAllOrders(
        page: _currentPage,
        perPage: 15,
      );
      aLog("FetchOrders (Page: $_currentPage) Response: $responseMap");

      if (responseMap == null) {
        _errorMessage = 'Failed to connect to the server.';
        _hasMoreItems = false;
      } else {
        // Check for explicit error flags from your API structure
        bool hasErrorFlag =
            responseMap['error'] == 1 || responseMap['error'] == true;
        int responseStatus = responseMap['status'] as int? ?? 0;

        if (hasErrorFlag || !(responseStatus >= 200 && responseStatus < 300)) {
          _errorMessage =
              responseMap['message']?.toString() ?? 'Failed to load orders.';
          _hasMoreItems = false; // Stop trying on error
        }
        // Check if 'data' (pagination wrapper) is a Map and contains 'data' (the list of orders)
        else if (responseMap.containsKey('data') &&
            responseMap['data'] is Map<String, dynamic> &&
            (responseMap['data'] as Map<String, dynamic>).containsKey('data') &&
            (responseMap['data'] as Map<String, dynamic>)['data'] is List) {
          final Map<String, dynamic> paginationWrapper = responseMap['data'];
          final List<dynamic> orderDataList = paginationWrapper['data'];

          final List<Order> newOrders =
              orderDataList
                  .map((data) {
                    return Order.fromJson(data as Map<String, dynamic>);
                    // try {

                    // } catch (e) {
                    //   aLog("Error parsing order item: $data, Error: $e");
                    //   return null;
                    // }
                  })
                  .whereType<Order>()
                  .toList();

          setState(() {
            if (isRefresh) {
              _orders.clear();
            }
            _orders.addAll(newOrders);
            // Sorting might be better done by API if dataset is large
            // _orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

            // Update pagination state from the paginationWrapper
            _currentPage =
                paginationWrapper['current_page'] as int? ?? _currentPage;
            _lastPage = paginationWrapper['last_page'] as int?;
            _hasMoreItems = _lastPage == null || _currentPage < _lastPage!;
          });
        } else {
          _errorMessage = 'Unexpected API response data format for orders.';
          _hasMoreItems = false;
        }
      }
    } catch (e, s) {
      aLog("Exception in _fetchOrders: $e\nStack trace: $s");
      _errorMessage = 'An application error occurred: ${e.toString()}';
      _hasMoreItems = false;
    } finally {
      setState(() {
        _isLoadingFirstTime = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchOrders(page: 1, isRefresh: true);
  }

  Future<void> _navigateToCreateOrderPage() async {
    final result = await Get.to(() => OrderFormPage());
    if (result == true) {
      _handleRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New order action complete! List refreshed.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _navigateToOrderDetailPage(Order order) async {
    final result = await Get.to(() => OrderFormPage(order: order));
    if (result == true) {
      _handleRefresh();
    }
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
        return FontAwesomeIcons.spinner;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Orders',
            onPressed:
                (_isLoadingFirstTime || _isLoadingMore) ? null : _handleRefresh,
          ),
        ],
      ),
      body:
          _isLoadingFirstTime
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text("Retry"),
                        onPressed: () => _fetchOrders(page: 1, isRefresh: true),
                      ),
                    ],
                  ),
                ),
              )
              : _orders.isEmpty && !_isLoadingMore
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      FontAwesomeIcons.fileCircleXmark,
                      size: 60,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No orders found.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the + button to create a new order or pull down to refresh.',
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _handleRefresh,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _orders.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _orders.length && _isLoadingMore) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (index >= _orders.length) return const SizedBox.shrink();

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
                        onTap: () => _navigateToOrderDetailPage(order),
                        borderRadius: BorderRadius.circular(12.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                        order.status ?? '',
                                      ).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getStatusIcon(order.status ?? ''),
                                          size: 14,
                                          color: _getStatusColor(
                                            order.status ?? '',
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          order.status ?? '',
                                          style: TextStyle(
                                            color: _getStatusColor(
                                              order.status ?? '',
                                            ),
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
                                order.customerName ?? '',
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
                                    'order.orderDate',
                                    // DateFormat(
                                    //   'dd MMM yy, hh:mm a',
                                    // ).format(order.orderDate),
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
                                  'Total: \$${order.calculatedTotalAmount.toStringAsFixed(2)}',
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
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateOrderPage,
        tooltip: 'Create New Order',
        icon: const Icon(Icons.add_shopping_cart_outlined),
        label: const Text('New Order'),
      ),
    );
  }
}
