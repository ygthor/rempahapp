import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart'; // For date formatting

// Assuming ReceiptFormPage and its models are in 'receipt_form_page.dart'
// Adjust the import path based on your project structure.
import './receipt_form_page.dart';

// --- Receipt List Page ---
class ReceiptListPage extends StatefulWidget {
  const ReceiptListPage({super.key});

  @override
  State<ReceiptListPage> createState() => _ReceiptListPageState();
}

class _ReceiptListPageState extends State<ReceiptListPage> {
  // --- Mock Data for Customer Selection ---
  final List<Customer> _mockCustomers = [
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
    Customer(
      id: 'cust_004',
      name: 'KUMAR ENTERPRISE',
      customerCode: '3000/S03',
    ),
  ];
  // --- Mock Data for Receipts (Replace with actual data source) ---
  final List<Receipt> _allReceipts = [
    Receipt(
      id: 'R001',
      receiptNo: 'RCPT-001',
      customerId: 'cust_001',
      customerName: 'AHS3185 S02 KANESAN',
      customerCode: '3000/S02',
      receiptDate: DateTime.now().subtract(const Duration(days: 1)),
      paymentType: 'Cash',
      debtAmount: 500.0,
      transactionAmount: 200.0,
      paidAmount: 200.0,
    ),
    Receipt(
      id: 'R002',
      receiptNo: 'RCPT-002',
      customerId: 'cust_002',
      customerName: 'Beta Wholesale Sdn Bhd',
      customerCode: 'CUST1001',
      receiptDate: DateTime.now().subtract(const Duration(hours: 5)),
      paymentType: 'Cheque',
      debtAmount: 1200.0,
      transactionAmount: 1000.0,
      paidAmount: 1000.0,
      chequeNo: 'CHK12345',
      bankName: 'MBB',
      chequeType: 'Local',
    ),
    Receipt(
      id: 'R003',
      receiptNo: 'RCPT-003',
      customerId: 'cust_001',
      customerName: 'AHS3185 S02 KANESAN',
      customerCode: '3000/S02',
      receiptDate: DateTime.now().subtract(const Duration(days: 2)),
      paymentType: 'Online Transfer',
      debtAmount: 300.0,
      transactionAmount: 300.0,
      paidAmount: 300.0,
      paymentReferenceNo: 'TRN98765',
    ),
    Receipt(
      id: 'R004',
      receiptNo: 'RCPT-004',
      customerId: 'cust_003',
      customerName: 'Gamma Retail Enterprise',
      customerCode: 'CUST2050',
      receiptDate: DateTime.now(),
      paymentType: 'Cash',
      debtAmount: 150.0,
      transactionAmount: 150.0,
      paidAmount: 150.0,
    ),
  ];

  List<Receipt> _filteredReceipts = [];
  String? _selectedCustomerFilterId; // Store customer ID for filtering
  DateTimeRange? _selectedDateRange;

  // Controller for customer filter text field (if using text input for filter)
  final TextEditingController _customerFilterController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _applyFilters(); // Initial load, sorted by date
  }

  @override
  void dispose() {
    _customerFilterController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _filteredReceipts =
          _allReceipts.where((receipt) {
            bool customerMatch = true;
            if (_selectedCustomerFilterId != null &&
                _selectedCustomerFilterId!.isNotEmpty) {
              customerMatch = receipt.customerId == _selectedCustomerFilterId;
            }

            bool dateMatch = true;
            if (_selectedDateRange != null) {
              // Ensure receiptDate is compared correctly (ignoring time for start/end of day)
              final receiptDayStart = DateTime(
                receipt.receiptDate.year,
                receipt.receiptDate.month,
                receipt.receiptDate.day,
              );
              final rangeStartDay = DateTime(
                _selectedDateRange!.start.year,
                _selectedDateRange!.start.month,
                _selectedDateRange!.start.day,
              );
              final rangeEndDay = DateTime(
                _selectedDateRange!.end.year,
                _selectedDateRange!.end.month,
                _selectedDateRange!.end.day,
                23,
                59,
                59,
              ); // End of day

              dateMatch =
                  !receiptDayStart.isBefore(rangeStartDay) &&
                  !receiptDayStart.isAfter(rangeEndDay);
            }
            return customerMatch && dateMatch;
          }).toList();

      // Sort by receipt date, latest first
      _filteredReceipts.sort((a, b) => b.receiptDate.compareTo(a.receiptDate));
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange:
          _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
      _applyFilters();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCustomerFilterId = null;
      _selectedDateRange = null;
      _customerFilterController.clear(); // Clear customer filter text
    });
    _applyFilters();
  }

  void _navigateToReceiptForm({Receipt? receipt}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptFormPage(receiptToEdit: receipt),
      ),
    );

    if (result != null && result is Receipt) {
      setState(() {
        if (receipt != null) {
          // Editing existing
          final index = _allReceipts.indexWhere((r) => r.id == result.id);
          if (index != -1) {
            _allReceipts[index] = result;
          }
        } else {
          // Adding new
          // Assign a mock ID if not provided by form (in real app, backend would do this)
          result.id ??= 'R${_allReceipts.length + 100}';
          _allReceipts.add(result);
        }
        _applyFilters(); // Re-apply filters and sort
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            receipt == null ? 'Receipt created!' : 'Receipt updated!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildFilterSection() {
    // Using the same mock customers as in ReceiptFormPage for consistency
    // In a real app, this list would be fetched.
    final List<Customer> filterCustomerOptions = _mockCustomers;

    return ExpansionTile(
      leading: const Icon(FontAwesomeIcons.filter),
      title: const Text('Filters'),
      subtitle: Text(
        _selectedCustomerFilterId == null && _selectedDateRange == null
            ? 'Tap to expand'
            : 'Active Filters: ${(_selectedCustomerFilterId != null ? "Customer" : "")}${(_selectedCustomerFilterId != null && _selectedDateRange != null ? ", " : "")}${(_selectedDateRange != null ? "Date Range" : "")}',
      ),
      childrenPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      children: [
        // Customer Filter Dropdown
        DropdownButtonFormField<String>(
          value: _selectedCustomerFilterId,
          decoration: InputDecoration(
            labelText: 'Filter by Customer',
            hintText: 'All Customers',
            prefixIcon: const Icon(Icons.person_outline),
            border: const OutlineInputBorder(),
            suffixIcon:
                _selectedCustomerFilterId != null
                    ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _selectedCustomerFilterId = null;
                          _customerFilterController
                              .clear(); // If you were using a text controller
                        });
                        _applyFilters();
                      },
                    )
                    : null,
          ),
          isExpanded: true,
          items: [
            const DropdownMenuItem<String>(
              value: null, // Represents "All Customers"
              child: Text('All Customers'),
            ),
            ...filterCustomerOptions.map((Customer customer) {
              return DropdownMenuItem<String>(
                value: customer.id,
                child: Text('${customer.customerCode} - ${customer.name}'),
              );
            }).toList(),
          ],
          onChanged: (String? newValue) {
            setState(() {
              _selectedCustomerFilterId = newValue;
            });
            _applyFilters();
          },
        ),
        const SizedBox(height: 12),

        // Date Range Filter
        ListTile(
          leading: const Icon(FontAwesomeIcons.calendarDays),
          title: const Text('Filter by Date Range'),
          subtitle: Text(
            _selectedDateRange == null
                ? 'Not set'
                : '${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}',
          ),
          trailing:
              _selectedDateRange != null
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedDateRange = null;
                      });
                      _applyFilters();
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade300,
            foregroundColor: Colors.black87,
          ),
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
            onPressed: () {
              // TODO: Implement actual refresh logic (e.g., re-fetch from API)
              _applyFilters(); // Re-apply filters with current mock data
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Receipts refreshed (mock data).'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          const Divider(height: 1),
          Expanded(
            child:
                _filteredReceipts.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            FontAwesomeIcons.fileCircleXmark,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No receipts found.',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          if (_selectedCustomerFilterId != null ||
                              _selectedDateRange != null)
                            const Text(
                              'Try adjusting your filters.',
                              style: TextStyle(color: Colors.grey),
                            ),
                        ],
                      ),
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.all(12.0),
                      itemCount: _filteredReceipts.length,
                      itemBuilder: (context, index) {
                        final receipt = _filteredReceipts[index];
                        return Card(
                          elevation: 2.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 10.0,
                            ),
                            leading: CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).primaryColorLight,
                              child: Icon(
                                FontAwesomeIcons.receipt,
                                color: Theme.of(context).primaryColorDark,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              receipt.receiptNo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '${receipt.customerCode} - ${receipt.customerName}',
                                  style: const TextStyle(fontSize: 13.5),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Date: ${DateFormat('dd MMM yyyy').format(receipt.receiptDate)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Text(
                                  'Type: ${receipt.paymentType}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'RM ${receipt.paidAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                            onTap:
                                () => _navigateToReceiptForm(
                                  receipt: receipt,
                                ), // Navigate to edit form
                          ),
                        );
                      },
                      separatorBuilder:
                          (context, index) => const SizedBox(height: 8),
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
