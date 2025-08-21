import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // For debounce

// Assuming models and services are in these paths
import 'package:kanesanapp/api/api_v1.dart';
import 'package:kanesanappp/models/global_state.dart';
import 'package:kanesanappp/shared/functions.dart';
import 'package:get/get.dart';

// --- Data Models (should be in separate files) ---

class DebtItem {
  final String salesNo;
  final DateTime salesDate;
  final String paymentType;
  final String paymentTerm;
  final DateTime dueDate;
  final double outstandingAmount;
  final String currency;

  DebtItem({
    required this.salesNo,
    required this.salesDate,
    required this.paymentType,
    required this.paymentTerm,
    required this.dueDate,
    required this.outstandingAmount,
    this.currency = 'RM',
  });

  factory DebtItem.fromJson(Map<String, dynamic> json) {
    return DebtItem(
      salesNo: json['salesNo'] as String? ?? 'N/A',
      salesDate: DateTime.parse(json['salesDate'] as String),
      paymentType: json['paymentType'] as String? ?? 'N/A',
      paymentTerm: json['paymentTerm'] as String? ?? 'N/A',
      dueDate: DateTime.parse(json['dueDate'] as String),
      outstandingAmount: (json['outstandingAmount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'RM',
    );
  }
}

class CustomerDebt {
  final String customerCode;
  final String outletsCode;
  final String companyName;
  final List<DebtItem> debtItems;
  final double totalOutstandingAmount;

  CustomerDebt({
    required this.customerCode,
    required this.outletsCode,
    required this.companyName,
    required this.debtItems,
    required this.totalOutstandingAmount,
  });

  factory CustomerDebt.fromJson(Map<String, dynamic> json) {
    var itemsFromJson = json['debtItems'] as List<dynamic>?;
    List<DebtItem> parsedItems = [];
    if (itemsFromJson != null) {
      parsedItems =
          itemsFromJson
              .map((item) => DebtItem.fromJson(item as Map<String, dynamic>))
              .toList();
    }
    return CustomerDebt(
      customerCode: json['customerCode'] as String? ?? 'N/A',
      outletsCode: json['outletsCode'] as String? ?? 'N/A',
      companyName: json['companyName'] as String? ?? 'Unknown Customer',
      debtItems: parsedItems,
      totalOutstandingAmount:
          (json['totalOutstandingAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// --- Debt List Page ---

class DebtListPage extends StatefulWidget {
  const DebtListPage({super.key});

  @override
  State<DebtListPage> createState() => _DebtListPageState();
}

class _DebtListPageState extends State<DebtListPage> {
  late ApiV1 _api;
  CustomerDebt? _selectedCustomerDebt;
  List<DebtItem> _filteredDebtItems = [];
  bool _isLoading = false;
  String _errorMessage = '';
  final TextEditingController _autocompleteController = TextEditingController();

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    GlobalState gs = Get.find<GlobalState>();
    _api = ApiV1(bearerToken: gs.token);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _autocompleteController.dispose();
    super.dispose();
  }

  Future<void> _fetchAndLoadCustomerDebts(String searchTerm) async {
    if (searchTerm.isEmpty) {
      setState(() {
        _selectedCustomerDebt = null;
        _filteredDebtItems = [];
        _errorMessage = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _api.getDebts(searchTerm: searchTerm);
      aLog("Fetch on select/submit: $response");
      if (response != null &&
          response['error'] != true &&
          response['data'] is List) {
        final List<CustomerDebt> results =
            (response['data'] as List)
                .map(
                  (data) => CustomerDebt.fromJson(data as Map<String, dynamic>),
                )
                .toList();

        if (results.isNotEmpty) {
          // Assuming the first result is the one we want for a specific search
          final customerDebt = results.first;
          setState(() {
            _selectedCustomerDebt = customerDebt;
            _filteredDebtItems =
                customerDebt.debtItems
                    .where((item) => item.outstandingAmount > 0)
                    .toList();
            _filteredDebtItems.sort((a, b) => a.dueDate.compareTo(b.dueDate));
          });
        } else {
          setState(() {
            _selectedCustomerDebt = null;
            _filteredDebtItems = [];
            _errorMessage = 'No customer found matching your search.';
          });
        }
      } else {
        setState(() {
          _selectedCustomerDebt = null;
          _filteredDebtItems = [];
          _errorMessage =
              response?['message']?.toString() ??
              'Failed to load debt information.';
        });
      }
    } catch (e) {
      setState(() {
        _selectedCustomerDebt = null;
        _filteredDebtItems = [];
        _errorMessage = 'An application error occurred.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
      showVDialog(
        title: "Info",
        text: "Please search and select a customer first.",
      );
    }
  }

  Future<Iterable<CustomerDebt>> _optionsBuilder(
    TextEditingValue textEditingValue,
  ) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (textEditingValue.text.length < 2) {
      return const Iterable<CustomerDebt>.empty();
    }

    final completer = Completer<Iterable<CustomerDebt>>();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final response = await _api.getDebts(searchTerm: textEditingValue.text);

      if (response != null &&
          response['error'] != true &&
          response['data'] is List) {
        final List<CustomerDebt> results =
            (response['data'] as List)
                .map(
                  (data) => CustomerDebt.fromJson(data as Map<String, dynamic>),
                )
                .toList();

        completer.complete(results);
      } else {
        completer.complete(const Iterable<CustomerDebt>.empty());
      }
    });
    return completer.future;
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
                context,
                fieldTextEditingController,
                fieldFocusNode,
                onFieldSubmitted,
              ) {
                // Keep a reference to the controller if needed outside this builder
                // For this case, it's self-contained.

                return TextField(
                  controller: fieldTextEditingController,
                  focusNode: fieldFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Customer Code / Name',
                    hintText: 'Type to search for a customer...',
                    prefixIcon: const Icon(FontAwesomeIcons.magnifyingGlass),
                    border: const OutlineInputBorder(),
                    suffixIcon:
                        fieldTextEditingController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                fieldTextEditingController.clear();
                                _fetchAndLoadCustomerDebts(
                                  '',
                                ); // Clear the list
                              },
                            )
                            : null,
                  ),
                  onSubmitted: (String value) {
                    // **THE FIX IS HERE**: Call the correct API fetch method
                    _fetchAndLoadCustomerDebts(
                      value.split(' - ')[0],
                    ); // Try to get code if format is "CODE - NAME"
                    onFieldSubmitted();
                  },
                );
              },
              onSelected: (CustomerDebt selection) {
                // When user selects from dropdown, update the list
                _autocompleteController.text =
                    '${selection.customerCode} - ${selection.companyName}';
                _fetchAndLoadCustomerDebts(selection.customerCode);
                FocusScope.of(context).unfocus();
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final CustomerDebt option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
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
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage.isNotEmpty)
              Center(
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (_selectedCustomerDebt != null) ...[
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
            ],
            const SizedBox(height: 10),
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
            Expanded(
              child:
                  _selectedCustomerDebt != null &&
                          _filteredDebtItems.isEmpty &&
                          !_isLoading
                      ? const Center(
                        child: Text(
                          'No outstanding debts found for this customer.',
                        ),
                      )
                      : _selectedCustomerDebt == null && !_isLoading
                      ? const Center(
                        child: Text(
                          'Type and select a customer to view debts.',
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
                      '${_selectedCustomerDebt!.totalOutstandingAmount.toStringAsFixed(2)}',
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
