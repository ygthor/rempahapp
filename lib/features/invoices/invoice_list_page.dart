import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rempahapp/features/invoices/invoice_form_page.dart';

// CHANGED: Import the new Invoice model
import 'package:rempahapp/models/invoice.dart';
import 'package:rempahapp/models/global_state.dart';
import 'package:rempahapp/api/api_v1.dart';
import 'package:rempahapp/shared/functions.dart';

// CHANGED: Assuming you will create an InvoiceFormPage similar to OrderFormPage
// import 'package:rempahapp/features/invoices/invoice_form_page.dart';

// NOTE: The OrderItem class is now replaced by ArTransItem and Invoice models in separate files.

// CHANGED: Renamed class to InvoiceListPage
class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({super.key});

  @override
  // CHANGED: Renamed State class
  State<InvoiceListPage> createState() => _InvoiceListPageState();
}

// CHANGED: Renamed State class
class _InvoiceListPageState extends State<InvoiceListPage> {
  late ApiV1 _api;
  // CHANGED: Use a list of Invoice objects
  final List<Invoice> _invoices = [];
  bool _isLoadingFirstTime = true;
  bool _isLoadingMore = false;
  String _errorMessage = '';

  int _currentPage = 1;
  int? _lastPage;
  bool _hasMoreItems = true;

  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  // CHANGED: Filter for invoice types
  final List<String> _selectedInvoiceTypes = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    GlobalState gs = Get.find<GlobalState>();
    _api = ApiV1(bearerToken: gs.token);
    // CHANGED: Call the new fetch method
    _fetchInvoices(isRefresh: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          _hasMoreItems &&
          !_isLoadingMore) {
        setState(() {
          _currentPage += 1;
        });
        // CHANGED: Call the new fetch method
        _fetchInvoices();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // CHANGED: Renamed method and updated logic
  Future<void> _fetchInvoices({bool isRefresh = false}) async {
    if (isRefresh) {
      _invoices.clear();
      setState(() {
        _currentPage = 1;
        _isLoadingFirstTime = true;
        _hasMoreItems = true;
        _errorMessage = '';
      });
    } else {
      if (_isLoadingMore || !_hasMoreItems) return;
      setState(() {
        _isLoadingMore = true;
        _errorMessage = '';
      });
    }

    try {
      // CHANGED: Call the new API method for invoices
      final Map<String, dynamic>? responseMap = await _api.getAllInvoices(
        page: _currentPage,
        perPage: 15,
        customerName: _searchQuery,
        startDate: _startDate,
        endDate: _endDate,
        invoiceTypes: _selectedInvoiceTypes,
      );
      aLog("FetchInvoices (Page: $_currentPage) Response: $responseMap");

      if (responseMap == null) {
        _errorMessage = 'Failed to connect to the server.';
        _hasMoreItems = false;
      } else {
        bool hasErrorFlag = responseMap['error'] == 1 || responseMap['error'] == true;
        int responseStatus = responseMap['status'] as int? ?? 0;

        if (hasErrorFlag || !(responseStatus >= 200 && responseStatus < 300)) {
          // CHANGED: Updated error message
          _errorMessage = responseMap['message']?.toString() ?? 'Failed to load invoices.';
          _hasMoreItems = false;
        } else if (responseMap.containsKey('data') &&
            responseMap['data'] is Map<String, dynamic> &&
            (responseMap['data'] as Map<String, dynamic>).containsKey('data') &&
            (responseMap['data'] as Map<String, dynamic>)['data'] is List) {
          final Map<String, dynamic> paginationWrapper = responseMap['data'];
          final List<dynamic> invoiceDataList = paginationWrapper['data'];

          // CHANGED: Map to Invoice objects
          final List<Invoice> newInvoices =
              invoiceDataList.map((data) => Invoice.fromJson(data as Map<String, dynamic>)).toList();

          setState(() {
            if (isRefresh) {
              _invoices.clear();
            }
            _invoices.addAll(newInvoices);

            _currentPage = paginationWrapper['current_page'] as int? ?? _currentPage;
            _lastPage = paginationWrapper['last_page'] as int?;
            _hasMoreItems = _lastPage == null || _currentPage < _lastPage!;
          });
        } else {
          // CHANGED: Updated error message
          _errorMessage = 'Unexpected API response data format for invoices.';
          _hasMoreItems = false;
        }
      }
    } catch (e, s) {
      aLog("Exception in _fetchInvoices: $e\nStack trace: $s");
      _errorMessage = 'An application error occurred: ${e.toString()}';
      _hasMoreItems = false;
    } finally {
      setState(() {
        _isLoadingFirstTime = false;
        _isLoadingMore = false;
      });
    }
  }

  // CHANGED: Renamed method
  Future<void> _handleRefresh() async {
    await _fetchInvoices(isRefresh: true);
  }

  // CHANGED: Updated navigation logic
  Future<void> _navigateToCreateInvoicePage() async {
    final result = await Get.to(() => InvoiceFormPage()); // Assumes InvoiceFormPage exists
    if (result == true) {
      _handleRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New invoice action complete! List refreshed.'), backgroundColor: Colors.green),
      );
    }
    // showVDialog(title: "TODO", text: "Navigate to Invoice Form Page");
  }

  // CHANGED: Updated navigation logic
  Future<void> _navigateToInvoiceDetailPage(Invoice invoice) async {
    final result = await Get.to(() => InvoiceFormPage(invoice: invoice)); // Assumes InvoiceFormPage exists
    if (result == true) {
      _handleRefresh();
    }
    // showVDialog(title: "TODO", text: "Navigate to Invoice Form Page for invoice: ${invoice.refNo}");
  }

  // These helper methods for color and icon can remain the same
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'pending':
      case 'unpaid':
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
      case 'paid':
        return FontAwesomeIcons.circleCheck;
      case 'processing':
        return FontAwesomeIcons.spinner;
      case 'pending':
      case 'unpaid':
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
        // CHANGED: Updated title
        title: const Text('Invoice List'),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.filter),
            // CHANGED: Updated tooltip
            tooltip: 'Filter Invoices',
            onPressed: _showFilterBottomSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Invoices',
            onPressed: (_isLoadingFirstTime || _isLoadingMore) ? null : _handleRefresh,
          ),
        ],
      ),
      body:
          _isLoadingFirstTime
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(/* ... Error UI remains the same ... */)
              : _invoices.isEmpty && !_isLoadingMore
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(FontAwesomeIcons.fileInvoiceDollar, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    // CHANGED: Updated empty state text
                    Text('No invoices found.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text(
                      'Tap the + button to create a new invoice or pull down to refresh.',
                      style: TextStyle(color: Colors.grey),
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
                  // CHANGED: Use the invoices list
                  itemCount: _invoices.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _invoices.length && _isLoadingMore) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (index >= _invoices.length) return const SizedBox.shrink();

                    // CHANGED: Use the invoice object
                    final invoice = _invoices[index];
                    // CHANGED: Call the new invoiceCard widget
                    return invoiceCard(invoice);
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        // CHANGED: Call the new navigation method
        onPressed: _navigateToCreateInvoicePage,
        tooltip: 'Create New Invoice',
        icon: const Icon(FontAwesomeIcons.fileCirclePlus),
        label: const Text('New Invoice'),
      ),
    );
  }

  // CHANGED: Renamed method and updated parameter
  Future<void> _showFilterBottomSheet() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            // CHANGED: Pass invoice types to the filter widget
            child: FilterOptions(
              initialSearchQuery: _searchQuery,
              initialStartDate: _startDate,
              initialEndDate: _endDate,
              initialInvoiceTypes: _selectedInvoiceTypes, // Pass invoice types
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
        // CHANGED: Get invoice types from the filter result
        _selectedInvoiceTypes.clear();
        _selectedInvoiceTypes.addAll(result['invoiceTypes'] as List<String>);
      });
      // CHANGED: Call the new fetch method
      _fetchInvoices(isRefresh: true);
    }
  }

  // CHANGED: Renamed widget from orderCard to invoiceCard
  Widget invoiceCard(Invoice invoice) {
    Color getInvoiceTypeColor(String invoiceType) {
      switch (invoiceType.toUpperCase()) {
        case 'IV': // Invoice
          return Colors.blue.shade700;
        case 'CN': // Credit Note
          return Colors.red.shade700;
        case 'DN': // Debit Note
          return Colors.orange.shade700;
        default:
          return Colors.grey;
      }
    }

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: InkWell(
        // CHANGED: Pass the invoice object to the detail page navigator
        onTap: () => _navigateToInvoiceDetailPage(invoice),
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    // CHANGED: Display invoice refNo
                    child: Text(
                      invoice.refNo ?? 'N/A',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (invoice.type != null)
                    Container(
                      // ... (Type chip UI remains similar, but uses new logic)
                      margin: const EdgeInsets.symmetric(horizontal: 8.0),
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: getInvoiceTypeColor(invoice.type!).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        invoice.type!,
                        style: TextStyle(
                          color: getInvoiceTypeColor(invoice.type!),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  Container(
                    // ... (Status chip UI remains similar)
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: _getStatusColor(invoice.status ?? '').withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(invoice.status ?? ''),
                          size: 14,
                          color: _getStatusColor(invoice.status ?? ''),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          invoice.status ?? 'Unknown',
                          style: TextStyle(
                            color: _getStatusColor(invoice.status ?? ''),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 1),
              Row(
                children: [
                  const Icon(FontAwesomeIcons.solidUser, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    // CHANGED: Display invoice customer name
                    child: Text(
                      invoice.name ?? 'No Customer',
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
                  // CHANGED: Display invoice date
                  Text(
                    invoice.date != null ? DateFormat('dd MMM yyyy, hh:mm a').format(invoice.date!) : 'No Date',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                // CHANGED: Display invoice total amount from netBil
                child: Text(
                  'Total: \$${invoice.netBil.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// NOTE: The FilterOptions widget also needs to be adapted to handle invoice types.
// I've made the necessary changes below.

// CHANGED: Create a new widget for your filter options
class FilterOptions extends StatefulWidget {
  final String initialSearchQuery;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  // CHANGED: Pass invoice types
  final List<String> initialInvoiceTypes;

  const FilterOptions({
    super.key,
    required this.initialSearchQuery,
    required this.initialStartDate,
    required this.initialEndDate,
    // CHANGED: Accept invoice types
    required this.initialInvoiceTypes,
  });

  @override
  State<FilterOptions> createState() => _FilterOptionsState();
}

class _FilterOptionsState extends State<FilterOptions> {
  late TextEditingController _searchController;
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;
  // CHANGED: State for invoice types
  late List<String> _tempSelectedInvoiceTypes;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchQuery);
    _tempStartDate = widget.initialStartDate;
    _tempEndDate = widget.initialEndDate;
    // CHANGED: Initialize from widget
    _tempSelectedInvoiceTypes = List.from(widget.initialInvoiceTypes);
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
      // CHANGED: Return invoice types
      'invoiceTypes': _tempSelectedInvoiceTypes,
    });
  }

  void _clearFilters() {
    Navigator.of(context).pop({'searchQuery': '', 'startDate': null, 'endDate': null, 'invoiceTypes': <String>[]});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // CHANGED: Title
          Text('Filter Invoices', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          // ... (Search and Date fields remain the same)
          TextField(/* ... */),
          const SizedBox(height: 20),
          ListTile(/* ... Start Date ... */),
          ListTile(/* ... End Date ... */),
          const SizedBox(height: 20),
          // CHANGED: Invoice Type filter
          Text('Invoice Type', style: Theme.of(context).textTheme.titleMedium),
          Wrap(
            spacing: 8.0,
            // CHANGED: Use invoice types like IV, CN, DN
            children:
                ['IV', 'CN', 'DN'].map((type) {
                  final isSelected = _tempSelectedInvoiceTypes.contains(type);
                  return FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _tempSelectedInvoiceTypes.add(type);
                        } else {
                          _tempSelectedInvoiceTypes.remove(type);
                        }
                      });
                    },
                  );
                }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            // ... (Buttons remain the same)
          ),
        ],
      ),
    );
  }
}
