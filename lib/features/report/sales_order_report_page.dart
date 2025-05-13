import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart'; // For date formatting

// --- Data Models ---
// Assuming a simple Customer model for now.
// In a real app, this would likely be more detailed and fetched from a data source.
class Customer {
  final String id;
  final String name;
  final String customerCode;

  Customer({required this.id, required this.name, required this.customerCode});
}

class SalesOrderItem {
  final String salesOrderNo;
  final DateTime salesDate;
  final double salesAmount;
  final String customerId; // To link back to customer for filtering
  final String customerName; // For display
  final String customerCode; // For display

  SalesOrderItem({
    required this.salesOrderNo,
    required this.salesDate,
    required this.salesAmount,
    required this.customerId,
    required this.customerName,
    required this.customerCode,
  });
}

// --- Mock Data ---
final List<Customer> _mockCustomersForReport = [
  Customer(
    id: 'cust_001',
    name: 'AHS3185 S02 KANESAN',
    customerCode: '3000/S02',
  ),
  Customer(
    id: 'cust_002',
    name: 'Beta Wholesale Sdn Bhd',
    customerCode: 'CUST1001',
  ),
  Customer(
    id: 'cust_003',
    name: 'Gamma Retail Enterprise',
    customerCode: 'CUST2050',
  ),
  Customer(id: 'cust_004', name: 'KUMAR ENTERPRISE', customerCode: '3000/S03'),
];

final List<SalesOrderItem> _allSalesOrders = [
  SalesOrderItem(
    salesOrderNo: 'S02-073254',
    salesDate: DateTime(2025, 2, 27, 8, 13, 35),
    salesAmount: 38.00,
    customerId: 'cust_001',
    customerName: 'AHS3185 S02 KANESAN',
    customerCode: '3000/S02',
  ),
  SalesOrderItem(
    salesOrderNo: 'S02-073255',
    salesDate: DateTime(2025, 2, 27, 8, 59, 13),
    salesAmount: 3991.80,
    customerId: 'cust_001',
    customerName: 'AHS3185 S02 KANESAN',
    customerCode: '3000/S02',
  ),
  SalesOrderItem(
    salesOrderNo: 'S02-073256',
    salesDate: DateTime(2025, 2, 27, 9, 15, 38),
    salesAmount: 9.50,
    customerId: 'cust_002',
    customerName: 'Beta Wholesale Sdn Bhd',
    customerCode: 'CUST1001',
  ),
  SalesOrderItem(
    salesOrderNo: 'S02-073257',
    salesDate: DateTime(2025, 2, 27, 9, 18, 28),
    salesAmount: 24.00,
    customerId: 'cust_001',
    customerName: 'AHS3185 S02 KANESAN',
    customerCode: '3000/S02',
  ),
  SalesOrderItem(
    salesOrderNo: 'S03-001001',
    salesDate: DateTime(2025, 2, 26, 10, 30, 00),
    salesAmount: 150.00,
    customerId: 'cust_004',
    customerName: 'KUMAR ENTERPRISE',
    customerCode: '3000/S03',
  ),
  SalesOrderItem(
    salesOrderNo: 'S03-001002',
    salesDate: DateTime(2025, 2, 25, 14, 00, 00),
    salesAmount: 750.00,
    customerId: 'cust_002',
    customerName: 'Beta Wholesale Sdn Bhd',
    customerCode: 'CUST1001',
  ),
  SalesOrderItem(
    salesOrderNo: 'S04-002001',
    salesDate: DateTime(2025, 2, 27, 11, 00, 00),
    salesAmount: 120.00,
    customerId: 'cust_003',
    customerName: 'Gamma Retail Enterprise',
    customerCode: 'CUST2050',
  ),
];

// --- Sales Order Report Page ---
class SalesOrderReportPage extends StatefulWidget {
  const SalesOrderReportPage({super.key});

  @override
  State<SalesOrderReportPage> createState() => _SalesOrderReportPageState();
}

class _SalesOrderReportPageState extends State<SalesOrderReportPage> {
  // --- Filter State Variables ---
  String _selectedReportType =
      'Sales Order'; // Default as per screenshot context
  final List<String> _reportTypeOptions = [
    'Sales Order',
    'Invoice',
    'Delivery Order',
    'Quotation',
  ];

  String _showCustomerOption =
      'All Customer'; // "All Customer" or "Select Customer"
  final List<String> _showCustomerOptions = ['All Customer', 'Select Customer'];
  Customer? _selectedCustomer;

  DateTime _fromDate = DateTime(2025, 2, 27); // Default from screenshot
  DateTime _toDate = DateTime(2025, 2, 27); // Default from screenshot

  List<SalesOrderItem> _filteredSalesOrders = [];
  bool _isLoading = false;

  final DateFormat _dateFormatter = DateFormat('dd-MM-yyyy');
  final DateFormat _dateTimeFormatter = DateFormat('yyyy-MM-dd hh:mm:ss a');

  @override
  void initState() {
    super.initState();
    // Initially load data based on default filters
    _fetchReportData();
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _fromDate : _toDate,
      firstDate: DateTime(2020), // Adjust as needed
      lastDate: DateTime(2030), // Adjust as needed
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          if (_toDate.isBefore(_fromDate)) _toDate = _fromDate;
        } else {
          _toDate = picked;
          if (_fromDate.isAfter(_toDate)) _fromDate = _toDate;
        }
      });
    }
  }

  Future<void> _fetchReportData() async {
    setState(() => _isLoading = true);

    // --- TODO: Replace with actual API call or data fetching logic ---
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate delay

    _filteredSalesOrders =
        _allSalesOrders.where((order) {
          bool reportTypeMatch =
              true; // Assuming _selectedReportType is handled by query if not 'Sales Order'
          // For this example, we only have SalesOrderItems, so this filter is illustrative.
          if (_selectedReportType != 'Sales Order') {
            // reportTypeMatch = order.type == _selectedReportType; // If your model had a 'type'
            reportTypeMatch = false; // No other types in mock data
          }

          bool customerMatch = true;
          if (_showCustomerOption == 'Select Customer' &&
              _selectedCustomer != null) {
            customerMatch = order.customerId == _selectedCustomer!.id;
          } else if (_showCustomerOption == 'Select Customer' &&
              _selectedCustomer == null) {
            customerMatch =
                false; // If "Select Customer" is chosen but no customer is selected, show nothing
          }

          final orderDateOnly = DateTime(
            order.salesDate.year,
            order.salesDate.month,
            order.salesDate.day,
          );
          final fromDateOnly = DateTime(
            _fromDate.year,
            _fromDate.month,
            _fromDate.day,
          );
          final toDateOnly = DateTime(_toDate.year, _toDate.month, _toDate.day);

          bool dateMatch =
              !orderDateOnly.isBefore(fromDateOnly) &&
              !orderDateOnly.isAfter(toDateOnly);

          return reportTypeMatch && customerMatch && dateMatch;
        }).toList();

    // Sort by date, then by sales order number
    _filteredSalesOrders.sort((a, b) {
      int dateComp = a.salesDate.compareTo(b.salesDate);
      if (dateComp != 0) return dateComp;
      return a.salesOrderNo.compareTo(b.salesOrderNo);
    });

    setState(() => _isLoading = false);
  }

  void _handlePreview() {
    _fetchReportData(); // Re-fetch data with current filters
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report preview updated.'),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  void _handlePrint() {
    if (_filteredSalesOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to print.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    // TODO: Implement actual print logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Print action tapped (not implemented).'),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sales Order Report',
        ), // Or "Batch Printing" as per image
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          const Divider(height: 1, thickness: 1),
          _buildReportListHeader(),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredSalesOrders.isEmpty
                    ? Center(
                      child: Text(
                        'No sales orders found for the selected criteria.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      itemCount: _filteredSalesOrders.length,
                      itemBuilder: (context, index) {
                        final order = _filteredSalesOrders[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  order.salesOrderNo,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  _dateTimeFormatter.format(order.salesDate),
                                  style: const TextStyle(fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  order.salesAmount.toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder:
                          (context, index) => const Divider(height: 1),
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(
                    FontAwesomeIcons.magnifyingGlassChart,
                    size: 16,
                  ),
                  label: const Text('Preview'),
                  onPressed: _handlePreview,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.print_outlined, size: 20),
                  label: const Text('Print'),
                  onPressed: _handlePrint,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report Type Dropdown
          DropdownButtonFormField<String>(
            value: _selectedReportType,
            decoration: const InputDecoration(
              labelText: 'Report Type',
              border: OutlineInputBorder(),
              prefixIcon: Icon(FontAwesomeIcons.fileLines, size: 18),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            items:
                _reportTypeOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedReportType = newValue!;
              });
            },
          ),
          const SizedBox(height: 12),

          // Show Customer Dropdown
          DropdownButtonFormField<String>(
            value: _showCustomerOption,
            decoration: const InputDecoration(
              labelText: 'Show Customer',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.people_outline, size: 20),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            items:
                _showCustomerOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _showCustomerOption = newValue!;
                if (_showCustomerOption == 'All Customer') {
                  _selectedCustomer = null; // Clear selected customer
                }
              });
            },
          ),
          const SizedBox(height: 12),

          // Customer Autocomplete (shown if "Select Customer" is chosen)
          if (_showCustomerOption == 'Select Customer')
            Autocomplete<Customer>(
              displayStringForOption:
                  (Customer option) =>
                      '${option.customerCode} - ${option.name}',
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<Customer>.empty();
                }
                return _mockCustomersForReport
                    .where((Customer option) {
                      return option.name.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          ) ||
                          option.customerCode.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          );
                    })
                    .take(5);
              },
              onSelected: (Customer selection) {
                setState(() {
                  _selectedCustomer = selection;
                });
                FocusScope.of(context).unfocus();
              },
              fieldViewBuilder: (
                BuildContext context,
                TextEditingController fieldTextEditingController,
                FocusNode fieldFocusNode,
                VoidCallback onFieldSubmitted,
              ) {
                // Pre-fill if a customer is already selected
                if (_selectedCustomer != null &&
                    fieldTextEditingController.text.isEmpty) {
                  fieldTextEditingController.text =
                      '${_selectedCustomer!.customerCode} - ${_selectedCustomer!.name}';
                } else if (_selectedCustomer == null) {
                  fieldTextEditingController
                      .clear(); // Clear if no customer is selected
                }
                return TextFormField(
                  controller: fieldTextEditingController,
                  focusNode: fieldFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Customer Code / Name',
                    hintText: 'Type to search customer',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(
                      Icons.person_search_outlined,
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    suffixIcon:
                        fieldTextEditingController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                fieldTextEditingController.clear();
                                setState(() => _selectedCustomer = null);
                              },
                            )
                            : null,
                  ),
                );
              },
              optionsViewBuilder: (
                BuildContext context,
                AutocompleteOnSelected<Customer> onSelected,
                Iterable<Customer> options,
              ) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Customer option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: ListTile(
                              title: Text(option.customerCode),
                              subtitle: Text(option.name),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          if (_showCustomerOption == 'Select Customer')
            const SizedBox(height: 12),

          // Date Range Pickers
          Row(
            children: <Widget>[
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, true),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'From Date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(
                        FontAwesomeIcons.calendarCheck,
                        size: 18,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      _dateFormatter.format(_fromDate),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, false),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'To Date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(
                        FontAwesomeIcons.calendarCheck,
                        size: 18,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      _dateFormatter.format(_toDate),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportListHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'SalesNo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              'SalesDate',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'S.Amt',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
