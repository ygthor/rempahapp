import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:rempahapp/models/CustomerDebt.dart';
import 'package:rempahapp/models/debt_item.dart'; // For date formatting - add to pubspec.yaml

// --- Mock Data (Replace with your actual data fetching) ---
final List<CustomerDebt> _allCustomerDebts = [
  CustomerDebt(
    customerCode: '3000/S02',
    outletsCode: '3000/S02',
    companyName: 'AHS3185 S02 KANESAN',
    debtItems: [
      DebtItem(
        salesNo: 'INV00123',
        salesDate: DateTime(2024, 4, 1),
        paymentType: 'Credit',
        paymentTerm: '30 Days',
        dueDate: DateTime(2024, 5, 1),
        outstandingAmount: 150.75,
      ),
      DebtItem(
        salesNo: 'INV00128',
        salesDate: DateTime(2024, 4, 10),
        paymentType: 'Credit',
        paymentTerm: '30 Days',
        dueDate: DateTime(2024, 5, 10),
        outstandingAmount: 220.00,
      ),
      DebtItem(
        salesNo: 'INV00135',
        salesDate: DateTime(2024, 4, 20),
        paymentType: 'Cash',
        paymentTerm: 'COD',
        dueDate: DateTime(2024, 4, 20),
        outstandingAmount: 0.00,
      ),
      DebtItem(
        salesNo: 'INV00140',
        salesDate: DateTime(2024, 5, 1),
        paymentType: 'Credit',
        paymentTerm: '15 Days',
        dueDate: DateTime(2024, 5, 16),
        outstandingAmount: 300.50,
      ),
    ],
  ),
  CustomerDebt(
    customerCode: 'CUST1001',
    outletsCode: 'OUTLET005',
    companyName: 'Beta Wholesale Sdn Bhd',
    debtItems: [
      DebtItem(
        salesNo: 'INV00098',
        salesDate: DateTime(2024, 3, 15),
        paymentType: 'Credit',
        paymentTerm: '60 Days',
        dueDate: DateTime(2024, 5, 14),
        outstandingAmount: 1250.00,
      ),
      DebtItem(
        salesNo: 'INV00110',
        salesDate: DateTime(2024, 4, 2),
        paymentType: 'Credit',
        paymentTerm: '30 Days',
        dueDate: DateTime(2024, 5, 2),
        outstandingAmount: 875.20,
      ),
    ],
  ),
  CustomerDebt(
    customerCode: 'CUST2050',
    outletsCode: 'STOREFRONT01',
    companyName: 'Gamma Retail Enterprise',
    debtItems: [
      DebtItem(
        salesNo: 'CSH00501',
        salesDate: DateTime(2024, 5, 10),
        paymentType: 'Cash',
        paymentTerm: 'COD',
        dueDate: DateTime(2024, 5, 10),
        outstandingAmount: 0.00,
      ),
    ],
  ),
  CustomerDebt(
    customerCode: '3000/S03',
    outletsCode: '3000/S03',
    companyName: 'KUMAR ENTERPRISE',
    debtItems: [],
  ),
  CustomerDebt(
    customerCode: '3000/S04',
    outletsCode: '3000/S04',
    companyName: 'RAJU STORE',
    debtItems: [],
  ),
  CustomerDebt(
    customerCode: 'CUST1002',
    outletsCode: 'OUTLET006',
    companyName: 'Charlie Retail',
    debtItems: [],
  ),
  CustomerDebt(
    customerCode: 'CUST1003',
    outletsCode: 'OUTLET007',
    companyName: 'Delta Goods',
    debtItems: [],
  ),
  CustomerDebt(
    customerCode: 'CUST1004',
    outletsCode: 'OUTLET008',
    companyName: 'Echo Supplies',
    debtItems: [],
  ),
  CustomerDebt(
    customerCode: 'CUST1005',
    outletsCode: 'OUTLET009',
    companyName: 'Foxtrot Mart',
    debtItems: [],
  ),
  CustomerDebt(
    customerCode: 'CUST1006',
    outletsCode: 'OUTLET010',
    companyName: 'Golf Trading',
    debtItems: [],
  ),
  CustomerDebt(
    customerCode: 'CUST1007',
    outletsCode: 'OUTLET011',
    companyName: 'Hotel Supplies Inc.',
    debtItems: [],
  ),
  CustomerDebt(
    customerCode: 'CUST1008',
    outletsCode: 'OUTLET012',
    companyName: 'India Grocers',
    debtItems: [],
  ),
  CustomerDebt(
    customerCode: 'CUST1009',
    outletsCode: 'OUTLET013',
    companyName: 'Juliet Provisions',
    debtItems: [],
  ),
  CustomerDebt(
    customerCode: 'CUST1010',
    outletsCode: 'OUTLET014',
    companyName: 'Kilo General Store',
    debtItems: [],
  ),
];

class DebtListPage extends StatefulWidget {
  const DebtListPage({super.key});

  @override
  State<DebtListPage> createState() => _DebtListPageState();
}

class _DebtListPageState extends State<DebtListPage> {
  CustomerDebt? _selectedCustomerDebt;
  List<DebtItem> _filteredDebtItems = [];
  String _currentSearchText =
      ""; // To keep track of the text field's content for messages

  // No need for _customerCodeFilterController as Autocomplete's fieldViewBuilder provides one.

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadCustomerDebts(String customerCodeQuery) {
    final query = customerCodeQuery.trim().toLowerCase();
    setState(() {
      _currentSearchText =
          customerCodeQuery.trim(); // Update current search text
      if (query.isEmpty) {
        _selectedCustomerDebt = null;
        _filteredDebtItems = [];
      } else {
        try {
          _selectedCustomerDebt = _allCustomerDebts.firstWhere(
            (custDebt) => custDebt.customerCode.toLowerCase() == query,
          );
          _filteredDebtItems =
              _selectedCustomerDebt!.debtItems
                  .where((item) => item.outstandingAmount > 0)
                  .toList();
          _filteredDebtItems.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        } catch (e) {
          _selectedCustomerDebt = null;
          _filteredDebtItems = [];
        }
      }
    });
  }

  void _reviewAllSalesForCustomer() {
    if (_selectedCustomerDebt != null) {
      setState(() {
        _filteredDebtItems = _selectedCustomerDebt!.debtItems.toList();
        _filteredDebtItems.sort((a, b) => b.salesDate.compareTo(a.salesDate));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Showing all sales for ${_selectedCustomerDebt!.companyName}',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please search and select a customer first.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<Iterable<CustomerDebt>> _optionsBuilder(
    TextEditingValue textEditingValue,
  ) async {
    setState(() {
      // Update search text for UI messages as user types
      _currentSearchText = textEditingValue.text.trim();
    });
    if (textEditingValue.text.isEmpty) {
      return const Iterable<CustomerDebt>.empty();
    }
    return _allCustomerDebts
        .where((CustomerDebt customer) {
          return customer.customerCode.toLowerCase().startsWith(
                textEditingValue.text.toLowerCase(),
              ) ||
              customer.companyName.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              );
        })
        .take(10);
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd/MM/yy');

    return Scaffold(
      appBar: AppBar(title: const Text('Review Debts')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Autocomplete<CustomerDebt>(
              optionsBuilder: _optionsBuilder,
              displayStringForOption:
                  (CustomerDebt option) =>
                      '${option.customerCode} - ${option.companyName}',
              fieldViewBuilder: (
                BuildContext context,
                TextEditingController
                fieldTextEditingController, // Use this controller
                FocusNode fieldFocusNode,
                VoidCallback onFieldSubmitted,
              ) {
                return TextField(
                  controller:
                      fieldTextEditingController, // THIS IS THE KEY CHANGE
                  focusNode: fieldFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Customer Code / Name',
                    hintText: 'Type Customer Code or Name',
                    prefixIcon: const Icon(FontAwesomeIcons.magnifyingGlass),
                    border: const OutlineInputBorder(),
                    suffixIcon:
                        fieldTextEditingController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                fieldTextEditingController
                                    .clear(); // Clear this controller
                                _loadCustomerDebts(
                                  '',
                                ); // Update the list based on empty query
                                setState(() {
                                  _currentSearchText = "";
                                }); // Explicitly clear search text state
                              },
                            )
                            : null,
                  ),
                  onSubmitted: (String value) {
                    // Value is fieldTextEditingController.text
                    // If displayStringForOption includes name, value might be "code - name".
                    // For simplicity, assume _loadCustomerDebts might need to handle this or user types code directly.
                    // A more robust solution would be to search _allCustomerDebts for a match on `value` before calling _loadCustomerDebts.
                    _loadCustomerDebts(
                      value,
                    ); // Attempt to load based on what's typed.
                    // This might fail if 'value' is "CODE - NAME" and _loadCustomerDebts expects only CODE.
                    // For this fix, we assume _loadCustomerDebts handles it or user types just code.
                    onFieldSubmitted();
                  },
                );
              },
              onSelected: (CustomerDebt selection) {
                // This is called when the user selects an option from the dropdown.
                // Autocomplete sets the fieldTextEditingController's text to displayStringForOption by default.
                // We want the field to show just the code after selection.
                // So, get a reference to the controller used by fieldViewBuilder (which it doesn't directly give us back here)
                // The best way is to set the text of the controller passed TO fieldViewBuilder
                // However, fieldTextEditingController is local to fieldViewBuilder's scope.
                // A common pattern is to update it in the next frame or rely on Autocomplete's behavior.
                // For now, we'll ensure _loadCustomerDebts is called with the *actual code*.
                // The text field might momentarily show "CODE - NAME" then update if we could set controller here.
                // A cleaner way: have displayStringForOption return customerCode for direct use by Autocomplete setting text.
                // OR, in fieldViewBuilder, if you had access to the TextEdC, you'd set it.

                // Let's set fieldTextEditingController's text *after* selection.
                // To do this, we need a way to access it. We can't directly from onSelected.
                // So, the text field will display what displayStringForOption returns.
                // We'll make _loadCustomerDebts robust or change displayStringForOption.

                // Option A: Change displayStringForOption if field should only show code
                // displayStringForOption: (CustomerDebt option) => option.customerCode,
                // Then _loadCustomerDebts(selection.customerCode) is fine.

                // Option B: (Current) displayStringForOption is "CODE - NAME"
                // field will show "CODE - NAME".
                // _loadCustomerDebts MUST be called with actual code.
                _loadCustomerDebts(selection.customerCode);

                // If you want the field to show only the code AFTER selection:
                // This is tricky without direct access to fieldTextEditingController here.
                // One way is to rebuild with initialValue, but Autocomplete doesn't have easy "set text" API.
                // The simplest for now is that the field shows "CODE - NAME" (from displayStringForOption)
                // and your logic uses `selection.customerCode`.
                FocusScope.of(context).unfocus();
              },
              optionsViewBuilder: (
                BuildContext context,
                AutocompleteOnSelected<CustomerDebt> onSelected,
                Iterable<CustomerDebt> options,
              ) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    child: ConstrainedBox(
                      // Use ConstrainedBox for better control over dropdown height
                      constraints: const BoxConstraints(
                        maxHeight: 250,
                      ), // Max height for the suggestions
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true, // Important for ConstrainedBox
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final CustomerDebt option = options.elementAt(index);
                          return InkWell(
                            onTap: () {
                              onSelected(option);
                            },
                            child: ListTile(
                              title: Text(option.customerCode),
                              subtitle: Text(option.companyName),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Customer Details Section
            if (_selectedCustomerDebt != null)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        'Outlets Code:',
                        _selectedCustomerDebt!.outletsCode,
                      ),
                      const SizedBox(height: 4),
                      _buildDetailRow(
                        'Company Name:',
                        _selectedCustomerDebt!.companyName,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),

            if (_selectedCustomerDebt != null)
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  icon: const Icon(FontAwesomeIcons.fileInvoice, size: 16),
                  label: const Text('Review All Sales'),
                  onPressed: _reviewAllSalesForCustomer,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
            const SizedBox(height: 10),

            // Debt Items Header (only if items exist)
            if (_filteredDebtItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _headerText('Sales No', flex: 2),
                    _headerText('SalesDate', flex: 2),
                    _headerText('P.Type', flex: 1),
                    _headerText('P.Term', flex: 2),
                    _headerText('DueDate', flex: 2),
                    _headerText(
                      'OSTD Amt',
                      flex: 2,
                      alignment: TextAlign.right,
                    ),
                  ],
                ),
              ),
            if (_filteredDebtItems.isNotEmpty) const Divider(),

            // Debt Items List
            Expanded(
              child:
                  (_selectedCustomerDebt == null &&
                          _currentSearchText.isNotEmpty &&
                          _filteredDebtItems.isEmpty)
                      ? const Center(
                        child: Text('No customer found matching your search.'),
                      )
                      : (_filteredDebtItems.isEmpty &&
                          _selectedCustomerDebt != null)
                      ? const Center(
                        child: Text(
                          'No outstanding debts for this customer, or no sales found.',
                        ),
                      )
                      : (_filteredDebtItems.isEmpty &&
                          _currentSearchText.isEmpty)
                      ? const Center(
                        child: Text(
                          'Type customer code or name to view debts.',
                        ),
                      )
                      : ListView.separated(
                        itemCount: _filteredDebtItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredDebtItems[index];
                          final bool isOverdue =
                              item.outstandingAmount > 0 &&
                              item.dueDate.isBefore(DateTime.now());
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _itemText(
                                  item.salesNo,
                                  flex: 2,
                                  isBold: isOverdue,
                                ),
                                _itemText(
                                  dateFormat.format(item.salesDate),
                                  flex: 2,
                                  isBold: isOverdue,
                                ),
                                _itemText(
                                  item.paymentType,
                                  flex: 1,
                                  isBold: isOverdue,
                                ),
                                _itemText(
                                  item.paymentTerm,
                                  flex: 2,
                                  isBold: isOverdue,
                                ),
                                _itemText(
                                  dateFormat.format(item.dueDate),
                                  flex: 2,
                                  isBold: isOverdue,
                                  color: isOverdue ? Colors.red : null,
                                ),
                                _itemText(
                                  item.outstandingAmount.toStringAsFixed(2),
                                  flex: 2,
                                  alignment: TextAlign.right,
                                  isBold: isOverdue,
                                  color: isOverdue ? Colors.red : null,
                                ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder:
                            (context, index) => const Divider(height: 1),
                      ),
            ),
            const SizedBox(height: 10),

            // Total Outstanding Amount
            if (_selectedCustomerDebt != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Total OSTD Amount: ',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_selectedCustomerDebt!.totalOutstandingAmount.toStringAsFixed(2)} ${_selectedCustomerDebt!.debtItems.isNotEmpty ? _selectedCustomerDebt!.debtItems.first.currency : ''}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
      ],
    );
  }

  Widget _headerText(
    String text, {
    int flex = 1,
    TextAlign alignment = TextAlign.left,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.black54,
        ),
        textAlign: alignment,
      ),
    );
  }

  Widget _itemText(
    String text, {
    int flex = 1,
    TextAlign alignment = TextAlign.left,
    bool isBold = false,
    Color? color,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
        textAlign: alignment,
      ),
    );
  }
}
