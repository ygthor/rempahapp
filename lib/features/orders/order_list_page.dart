import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kanesanapp/features/orders/order_form_page.dart';

// Assuming your models and ApiV1 are in these locations. Adjust paths as needed.
import 'package:kanesanappp/models/global_state.dart';
import 'package:kanesanappp/api/api_v1.dart';
import 'package:kanesanappp/shared/functions.dart';

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

  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  final List<String> _selectedOrderTypes = []; // e.g., ['PO', 'SO']

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    GlobalState gs = Get.find<GlobalState>();
    _api = ApiV1(bearerToken: gs.token);
    _fetchOrders(isRefresh: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          _hasMoreItems &&
          !_isLoadingMore) {
        setState(() {
          _currentPage += 1;
        });
        _fetchOrders();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders({bool isRefresh = false}) async {
    if (isRefresh) {
      _orders.clear();
      setState(() {
        _currentPage = 1;
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
        customerName: _searchQuery, // Pass the filter values
        startDate: _startDate,
        endDate: _endDate,
        orderTypes: _selectedOrderTypes,
      );
      aLog("FetchOrders (Page: $_currentPage) Response: $responseMap");

      if (responseMap == null) {
        _errorMessage = 'Failed to connect to the server.';
        _hasMoreItems = false;
      } else {
        // Check for explicit error flags from your API structure
        bool hasErrorFlag = responseMap['error'] == 1 || responseMap['error'] == true;
        int responseStatus = responseMap['status'] as int? ?? 0;

        if (hasErrorFlag || !(responseStatus >= 200 && responseStatus < 300)) {
          _errorMessage = responseMap['message']?.toString() ?? 'Failed to load orders.';
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
            _currentPage = paginationWrapper['current_page'] as int? ?? _currentPage;
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
    await _fetchOrders(isRefresh: true);
  }

  Future<void> _navigateToCreateOrderPage() async {
    final result = await Get.to(() => OrderFormPage());
    if (result == true) {
      _handleRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New order action complete! List refreshed.'), backgroundColor: Colors.green),
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
            icon: const FaIcon(FontAwesomeIcons.filter), // Add this filter icon
            tooltip: 'Filter Orders',
            onPressed: _showFilterBottomSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Orders',
            onPressed: (_isLoadingFirstTime || _isLoadingMore) ? null : _handleRefresh,
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
                        onPressed: () => _fetchOrders(isRefresh: true),
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
                    const Icon(FontAwesomeIcons.fileCircleXmark, size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No orders found.', style: TextStyle(fontSize: 18, color: Colors.grey)),
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
                    return orderCard(order);
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

  // Inside _OrderListPageState class

  Future<void> _showFilterBottomSheet() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: FilterOptions(
              initialSearchQuery: _searchQuery,
              initialStartDate: _startDate,
              initialEndDate: _endDate,
              initialOrderTypes: _selectedOrderTypes,
            ),
          ),
        );
      },
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _searchQuery = result['searchQuery'] as String;
        _startDate = result['startDate'] as DateTime?;
        _endDate = result['endDate'] as DateTime?;
        _selectedOrderTypes.clear();
        _selectedOrderTypes.addAll(result['orderTypes'] as List<String>);
      });
      // Trigger a refresh with the new filters
      _fetchOrders(isRefresh: true);
    }
  }

  Widget orderCard(Order order) {
    // A helper function to get the color for the order type chip
    Color _getOrderTypeColor(String orderType) {
      switch (orderType.toUpperCase()) {
        case 'PO': // Purchase Order
          return Colors.blue.shade700;
        case 'SO': // Sales Order
          return Colors.green.shade700;
        case 'QO': // Quotation Order
          return Colors.orange.shade700;
        default:
          return Colors.grey;
      }
    }

    return Card(
      elevation: 4.0, // Slightly higher elevation for a better shadow
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: InkWell(
        onTap: () => _navigateToOrderDetailPage(order),
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0), // More padding for a spacious feel
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Reference, Order Type, and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      order.referenceNo ?? 'N/A',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (order.orderType != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0),
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: _getOrderTypeColor(order.orderType!).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        order.orderType!,
                        style: TextStyle(
                          color: _getOrderTypeColor(order.orderType!),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  // Status Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status ?? '').withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getStatusIcon(order.status ?? ''), size: 14, color: _getStatusColor(order.status ?? '')),
                        const SizedBox(width: 4),
                        Text(
                          order.status ?? 'Unknown',
                          style: TextStyle(
                            color: _getStatusColor(order.status ?? ''),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 1), // A divider to separate sections
              // Customer Details and Date
              Row(
                children: [
                  const Icon(FontAwesomeIcons.solidUser, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.customerName ?? 'No Customer',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(FontAwesomeIcons.calendarDay, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    order.orderDate != null ? DateFormat('dd MMM yy, hh:mm a').format(order.orderDate!) : 'No Date',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Total Amount
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Total: \$${order.calculatedTotalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20, // Larger font size
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
  }
}

// Create a new widget for your filter options
class FilterOptions extends StatefulWidget {
  final String initialSearchQuery;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final List<String> initialOrderTypes;

  const FilterOptions({
    super.key,
    required this.initialSearchQuery,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.initialOrderTypes,
  });

  @override
  State<FilterOptions> createState() => _FilterOptionsState();
}

class _FilterOptionsState extends State<FilterOptions> {
  late TextEditingController _searchController;
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;
  late List<String> _tempSelectedOrderTypes;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchQuery);
    _tempStartDate = widget.initialStartDate;
    _tempEndDate = widget.initialEndDate;
    _tempSelectedOrderTypes = List.from(widget.initialOrderTypes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    Navigator.of(context).pop({
      'searchQuery': _searchController.text.trim(),
      'startDate': _tempStartDate,
      'endDate': _tempEndDate,
      'orderTypes': _tempSelectedOrderTypes,
    });
  }

  void _clearFilters() {
    Navigator.of(context).pop({'searchQuery': '', 'startDate': null, 'endDate': null, 'orderTypes': <String>[]});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Filter Orders', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Customer Name',
              hintText: 'Enter customer name',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          // Date Range Picker
          // ... (You'll need to implement this with a button that calls showDatePicker)
          ListTile(
            title: const Text('Start Date'),
            subtitle: Text(_tempStartDate != null ? DateFormat('dd MMM yyyy').format(_tempStartDate!) : 'Not set'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: _tempStartDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (pickedDate != null) {
                setState(() => _tempStartDate = pickedDate);
              }
            },
          ),
          ListTile(
            title: const Text('End Date'),
            subtitle: Text(_tempEndDate != null ? DateFormat('dd MMM yyyy').format(_tempEndDate!) : 'Not set'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: _tempEndDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (pickedDate != null) {
                setState(() => _tempEndDate = pickedDate);
              }
            },
          ),
          const SizedBox(height: 20),
          Text('Order Type', style: Theme.of(context).textTheme.titleMedium),
          Wrap(
            spacing: 8.0,
            children:
                ['PO', 'SO', 'QO'].map((type) {
                  final isSelected = _tempSelectedOrderTypes.contains(type);
                  return FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _tempSelectedOrderTypes.add(type);
                        } else {
                          _tempSelectedOrderTypes.remove(type);
                        }
                      });
                    },
                  );
                }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(onPressed: _clearFilters, child: const Text('Clear Filters')),
              ElevatedButton(onPressed: _applyFilters, child: const Text('Apply Filters')),
            ],
          ),
        ],
      ),
    );
  }
}
