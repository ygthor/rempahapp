import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// Assuming these are the correct paths in your project
import 'package:kanesanapp/api/api_v1.dart';
import 'package:kanesanapp/models/global_state.dart';
import 'package:kanesanapp/models/receipt.dart';
import 'package:kanesanapp/shared/functions.dart';

// Import your actual form page
import 'package:kanesanapp/features/receipts/receipt_form_page.dart'; // Adjust path if needed

// --- Data Models (These should be in their own files and imported) ---
class Customer {
  final int id;
  final String name;
  final String customerCode;

  Customer({required this.id, required this.name, required this.customerCode});

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int,
      name: json['company_name'] as String? ?? json['name'] as String? ?? 'Unknown Customer',
      customerCode: json['customer_code'] as String? ?? 'N/A',
    );
  }
}

class ReceiptListPage extends StatefulWidget {
  const ReceiptListPage({super.key});

  @override
  State<ReceiptListPage> createState() => _ReceiptListPageState();
}

class _ReceiptListPageState extends State<ReceiptListPage> {
  late ApiV1 _api;
  final List<Receipt> _receipts = [];
  bool _isLoadingFirstTime = true;
  bool _isLoadingMore = false;
  String _errorMessage = '';

  // Pagination state
  int _currentPage = 1;
  bool _hasMoreItems = true;

  // Filter state
  Customer? _selectedCustomerFilter;
  DateTimeRange? _selectedDateRange;

  // Data for filter dropdowns
  List<Customer> _filterCustomerOptions = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    GlobalState gs = Get.find<GlobalState>();
    _api = ApiV1(bearerToken: gs.token);
    _fetchInitialData(); // Fetch receipts and customers

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          _hasMoreItems &&
          !_isLoadingMore) {
        _fetchReceipts();
        // _fetchReceipts(page: _currentPage + 1);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    _fetchCustomersForFilter();
    _fetchReceipts(isRefresh: true);
  }

  Future<void> _fetchCustomersForFilter() async {
    final response = await _api.getCustomers();
    if (response != null && response is Map<String, dynamic> && response['data'] is List) {
      setState(() {
        _filterCustomerOptions =
            (response['data'] as List).map((c) => Customer.fromJson(c as Map<String, dynamic>)).toList();
      });
    }
  }

  Future<void> _fetchReceipts({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _receipts.clear();
      _hasMoreItems = true;
      setState(() {
        _isLoadingFirstTime = true;
        _errorMessage = '';
      });
    } else {
      if (_isLoadingMore || !_hasMoreItems) return;
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final response = await _api.getAllReceipts(
        page: _currentPage,
        customerId: _selectedCustomerFilter?.id.toString(),
        dateFrom: _selectedDateRange?.start != null ? DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start) : null,
        dateTo: _selectedDateRange?.end != null ? DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end) : null,
      );

      if (response != null && response['error'] != true && response['data']?['data'] is List) {
        final List<dynamic> receiptDataList = response['data']['data'];
        final List<Receipt> newReceipts =
            receiptDataList.map((data) => Receipt.fromJson(data as Map<String, dynamic>)).toList();
        final paginationData = response['data'] as Map<String, dynamic>;

        setState(() {
          _receipts.addAll(newReceipts);
          _currentPage = paginationData['current_page'] as int? ?? _currentPage;
          final lastPage = paginationData['last_page'] as int?;
          _hasMoreItems = lastPage == null || _currentPage < lastPage;
        });
      } else {
        setState(() {
          _errorMessage = response?['message']?.toString() ?? 'Failed to load receipts.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An application error occurred.';
      });
    } finally {
      setState(() {
        _isLoadingFirstTime = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange:
          _selectedDateRange ??
          DateTimeRange(start: DateTime.now().subtract(const Duration(days: 7)), end: DateTime.now()),
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() => _selectedDateRange = picked);
      _fetchReceipts(isRefresh: true);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCustomerFilter = null;
      _selectedDateRange = null;
    });
    _fetchReceipts(isRefresh: true);
  }

  Future<void> _navigateToReceiptForm({Receipt? receipt}) async {
    final result = await Get.to(() => ReceiptFormPage(receiptToEdit: receipt));
    if (result == true) {
      _fetchReceipts(isRefresh: true);
    }
  }

  Widget _buildFilterSection() {
    return ExpansionTile(
      leading: const Icon(FontAwesomeIcons.filter),
      title: const Text('Filters'),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      children: [
        DropdownButtonFormField<Customer>(
          value: _selectedCustomerFilter,
          decoration: InputDecoration(
            labelText: 'Filter by Customer',
            hintText: 'All Customers',
            prefixIcon: const Icon(Icons.person_outline),
            border: const OutlineInputBorder(),
            suffixIcon:
                _selectedCustomerFilter != null
                    ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() => _selectedCustomerFilter = null);
                        _fetchReceipts(isRefresh: true);
                      },
                    )
                    : null,
          ),
          isExpanded: true,
          items:
              _filterCustomerOptions.map((Customer customer) {
                return DropdownMenuItem<Customer>(
                  value: customer,
                  child: Text('${customer.customerCode} - ${customer.name}'),
                );
              }).toList(),
          onChanged: (Customer? newValue) {
            setState(() => _selectedCustomerFilter = newValue);
            _fetchReceipts(isRefresh: true);
          },
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(FontAwesomeIcons.calendarDays),
          title: const Text('Filter by Date Range'),
          subtitle: Text(
            _selectedDateRange == null
                ? 'Not set'
                : '${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}',
          ),
          trailing:
              _selectedDateRange != null
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() => _selectedDateRange = null);
                      _fetchReceipts(isRefresh: true);
                    },
                  )
                  : const Icon(Icons.edit_calendar_outlined),
          onTap: () => _selectDateRange(context),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.filter_alt_off_outlined),
          label: const Text('Clear All Filters'),
          onPressed: _clearFilters,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade300, foregroundColor: Colors.black87),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Receipts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Receipts',
            onPressed: (_isLoadingFirstTime || _isLoadingMore) ? null : () => _fetchReceipts(isRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          const Divider(height: 1),
          Expanded(
            child:
                _isLoadingFirstTime
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
                    : _receipts.isEmpty
                    ? const Center(child: Text('No receipts found.'))
                    : RefreshIndicator(
                      onRefresh: () => _fetchReceipts(isRefresh: true),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12.0),
                        itemCount: _receipts.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _receipts.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final receipt = _receipts[index];
                          return Card(
                            elevation: 2.5,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                              leading: CircleAvatar(child: Icon(FontAwesomeIcons.receipt, size: 20)),
                              title: Text(receipt.receiptNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('${receipt.customerCode} - ${receipt.customerName}'),
                                  const SizedBox(height: 2),
                                  Text('Date: ${DateFormat('dd MMM yyyy').format(receipt.receiptDate)}'),
                                ],
                              ),
                              trailing: Text(
                                'RM ${receipt.paidAmount.toStringAsFixed(2)}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                              ),
                              onTap: () => _navigateToReceiptForm(receipt: receipt),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToReceiptForm(),
        tooltip: 'Create New Receipt',
        icon: const Icon(Icons.add_card_outlined),
        label: const Text('New Receipt'),
      ),
    );
  }
}
