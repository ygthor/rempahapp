import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// Assuming these are the correct paths in your project
import 'package:rempahapp/api/api_v1.dart';
import 'package:rempahapp/models/global_state.dart';
import 'package:rempahapp/models/receipt.dart';
import 'package:rempahapp/shared/functions.dart'; // For showVDialog

// --- Data Models ---
// Ideally, these would be in their own files (e.g., models/customer.dart, models/receipt.dart)
// and imported. Included here for a self-contained example.

class Customer {
  final int id;
  final String name;
  final String customerCode;

  Customer({required this.id, required this.name, required this.customerCode});

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int,
      name:
          json['company_name'] as String? ??
          json['name'] as String? ??
          'Unknown Customer',
      customerCode: json['customer_code'] as String? ?? 'N/A',
    );
  }
}

class ReceiptFormPage extends StatefulWidget {
  final Receipt? receiptToEdit;

  const ReceiptFormPage({super.key, this.receiptToEdit});

  @override
  State<ReceiptFormPage> createState() => _ReceiptFormPageState();
}

class _ReceiptFormPageState extends State<ReceiptFormPage> {
  final _formKey = GlobalKey<FormState>();
  late ApiV1 _api;
  bool _isLoading = false;

  // --- Controllers ---
  late TextEditingController _receiptNoController;
  Customer? _selectedCustomer;
  late TextEditingController _debtAmountController;
  late TextEditingController _transactionAmountController;
  late TextEditingController _paidAmountController;
  late TextEditingController _chequeNoController;
  late TextEditingController _bankNameController;
  late TextEditingController _paymentReferenceNoController;

  // --- Dropdown State Variables ---
  String? _selectedPaymentType;
  final List<String> _paymentTypeOptions = [
    'Cash',
    'Cheque',
    'Online Transfer',
    'Card',
    'Other',
  ];
  String? _selectedChequeType;
  final List<String> _chequeTypeOptions = ['Local', 'Outstation', 'Post-Dated'];

  DateTime _selectedReceiptDate = DateTime.now();

  bool get _isEditMode => widget.receiptToEdit != null;

  @override
  void initState() {
    super.initState();
    GlobalState gs = Get.find<GlobalState>();
    _api = ApiV1(bearerToken: gs.token);

    final receipt = widget.receiptToEdit;

    _receiptNoController = TextEditingController(
      text: receipt?.receiptNo ?? _generateNewReceiptNo(),
    );
    _debtAmountController = TextEditingController(
      text: receipt?.debtAmount!.toStringAsFixed(2) ?? '0.00',
    );
    _transactionAmountController = TextEditingController(
      text: receipt?.transactionAmount!.toStringAsFixed(2) ?? '0.00',
    );
    _paidAmountController = TextEditingController(
      text: receipt?.paidAmount.toStringAsFixed(2) ?? '0.00',
    );
    _chequeNoController = TextEditingController(text: receipt?.chequeNo ?? '');
    _bankNameController = TextEditingController(text: receipt?.bankName ?? '');
    _paymentReferenceNoController = TextEditingController(
      text: receipt?.paymentReferenceNo ?? '',
    );

    if (receipt != null) {
      _selectedReceiptDate = receipt.receiptDate;
      // Pre-populate the selected customer object
      _selectedCustomer = Customer(
        id: receipt.customerId,
        name: receipt.customerName,
        customerCode: receipt.customerCode,
      );
      if (_paymentTypeOptions.contains(receipt.paymentType)) {
        _selectedPaymentType = receipt.paymentType;
      }
      if (receipt.chequeType != null &&
          _chequeTypeOptions.contains(receipt.chequeType)) {
        _selectedChequeType = receipt.chequeType;
      }
    }

    _transactionAmountController.addListener(() {
      if (_paidAmountController.text.isEmpty ||
          _paidAmountController.text == '0.00') {
        _paidAmountController.text = _transactionAmountController.text;
      }
    });
  }

  @override
  void dispose() {
    _receiptNoController.dispose();
    _debtAmountController.dispose();
    _transactionAmountController.dispose();
    _paidAmountController.dispose();
    _chequeNoController.dispose();
    _bankNameController.dispose();
    _paymentReferenceNoController.dispose();
    super.dispose();
  }

  String _generateNewReceiptNo() {
    final timestamp = DateTime.now().millisecondsSinceEpoch
        .toString()
        .substring(7);
    return 'RCPT-$timestamp';
  }

  Future<void> _selectReceiptDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedReceiptDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedReceiptDate) {
      setState(() => _selectedReceiptDate = picked);
    }
  }

  // Method to search for customers using the API
  Future<Iterable<Customer>> _searchCustomers(String query) async {
    if (query.isEmpty) {
      return const Iterable<Customer>.empty();
    }
    // Assuming ApiV1.getCustomers() returns a List or a Map with a 'data' key holding the List
    final response =
        await _api
            .getCustomers(); // You might want to add a search query parameter here
    if (response != null) {
      List<dynamic>? customerDataList;
      if (response is List) {
        customerDataList = response;
      } else if (response is Map<String, dynamic> && response['data'] is List) {
        customerDataList = response['data'];
      }

      if (customerDataList != null) {
        return customerDataList
            .map((json) => Customer.fromJson(json as Map<String, dynamic>))
            .where(
              (customer) =>
                  customer.name.toLowerCase().contains(query.toLowerCase()) ||
                  customer.customerCode.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            );
      }
    }
    return const Iterable<Customer>.empty();
  }

  Future<void> _saveReceipt() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCustomer == null) {
      showVDialog(title: "Validation Error", text: "Please select a customer.");
      return;
    }
    if (_selectedPaymentType == null) {
      showVDialog(
        title: "Validation Error",
        text: "Please select a payment type.",
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final receiptToSave = Receipt(
      id: widget.receiptToEdit?.id,
      receiptNo: _receiptNoController.text,
      customerId: _selectedCustomer!.id,
      customerName: _selectedCustomer!.name,
      customerCode: _selectedCustomer!.customerCode,
      receiptDate: _selectedReceiptDate,
      paymentType: _selectedPaymentType!,
      debtAmount: double.tryParse(_debtAmountController.text) ?? 0.0,
      transactionAmount:
          double.tryParse(_transactionAmountController.text) ?? 0.0,
      paidAmount: double.tryParse(_paidAmountController.text) ?? 0.0,
      chequeNo:
          _chequeNoController.text.isNotEmpty ? _chequeNoController.text : null,
      chequeType: _selectedPaymentType == 'Cheque' ? _selectedChequeType : null,
      bankName:
          _bankNameController.text.isNotEmpty ? _bankNameController.text : null,
      paymentReferenceNo:
          _paymentReferenceNoController.text.isNotEmpty
              ? _paymentReferenceNoController.text
              : null,
    );

    try {
      Map<String, dynamic>? response;
      if (_isEditMode) {
        // You'll need an updateReceipt method in ApiV1
        response = await _api.updateReceipt(
          receiptToSave.id ?? 0,
          receiptToSave.toJson(),
        );
      } else {
        // You'll need a createReceipt method in ApiV1
        response = await _api.createReceipt(receiptToSave.toJson());
      }

      setState(() {
        _isLoading = false;
      });

      if (response != null &&
          (response['error'] != true &&
              (response['status'] == 200 || response['status'] == 201))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ??
                  (_isEditMode
                      ? 'Customer updated successfully!'
                      : 'Customer created successfully!'),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Get.back(
          result: true,
        ); // Pop and indicate success to refresh list on previous page
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response?['message']?.toString() ??
                  'An error occurred. Please try again.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showVDialog(
        title: "Application Error",
        text: "An error occurred: ${e.toString()}",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Customer Receipt' : 'Create Customer Receipt',
        ),
        actions: [
          // Simplified to a single save button
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save_alt_outlined),
              onPressed: _saveReceipt,
              tooltip: 'Save Receipt',
            )
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
          _isLoading
              ? FloatingActionButton(
                onPressed: null,
                child: CircularProgressIndicator(color: Colors.white),
                backgroundColor: theme.primaryColor,
              )
              : FloatingActionButton.extended(
                onPressed: _saveReceipt,
                icon: Icon(Icons.save_alt_outlined),
                label: Text(_isEditMode ? 'Save Changes' : 'Create Customer'),
                // style: theme.floatingActionButtonTheme.extendedStyle, // Use themed FAB style
              ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _receiptNoController,
                decoration: const InputDecoration(
                  labelText: 'Receipt No',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.hashtag),
                ),
                readOnly: _isEditMode,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectReceiptDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Receipt Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(FontAwesomeIcons.calendarDay),
                  ),
                  child: Text(
                    DateFormat('dd MMM yyyy').format(_selectedReceiptDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Autocomplete<Customer>(
                displayStringForOption:
                    (Customer option) =>
                        '${option.customerCode} - ${option.name}',
                optionsBuilder:
                    (TextEditingValue textEditingValue) =>
                        _searchCustomers(textEditingValue.text),
                onSelected: (Customer selection) {
                  setState(() {
                    _selectedCustomer = selection;
                  });
                  FocusScope.of(context).unfocus();
                },
                fieldViewBuilder: (
                  context,
                  fieldTextEditingController,
                  fieldFocusNode,
                  onFieldSubmitted,
                ) {
                  if (_selectedCustomer != null &&
                      fieldTextEditingController.text.isEmpty) {
                    fieldTextEditingController.text =
                        '${_selectedCustomer!.customerCode} - ${_selectedCustomer!.name}';
                  }
                  return TextFormField(
                    controller: fieldTextEditingController,
                    focusNode: fieldFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Customer *',
                      hintText: 'Type to search Customer Code or Name',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person_search_outlined),
                      suffixIcon:
                          fieldTextEditingController.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  fieldTextEditingController.clear();
                                  setState(() {
                                    _selectedCustomer = null;
                                    _debtAmountController.text = '0.00';
                                  });
                                },
                              )
                              : null,
                    ),
                    validator:
                        (value) =>
                            (_selectedCustomer == null &&
                                    (value?.isNotEmpty ?? false))
                                ? 'Please select a valid customer'
                                : null,
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
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
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPaymentType,
                decoration: const InputDecoration(
                  labelText: 'Payment Type *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.creditCard),
                ),
                items:
                    _paymentTypeOptions
                        .map(
                          (String type) => DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          ),
                        )
                        .toList(),
                onChanged:
                    (String? newValue) =>
                        setState(() => _selectedPaymentType = newValue),
                validator:
                    (value) =>
                        value == null ? 'Please select a payment type' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _debtAmountController,
                decoration: const InputDecoration(
                  labelText: 'Debt Amount (Outstanding)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.fileInvoiceDollar),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator:
                    (v) =>
                        (v == null || v.isEmpty || double.tryParse(v) == null)
                            ? 'Invalid amount'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _transactionAmountController,
                decoration: const InputDecoration(
                  labelText: 'Transaction Amount *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.moneyBillTransfer),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final amount = double.tryParse(v);
                  if (amount == null) return 'Invalid number';
                  if (amount <= 0) return 'Amount must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _paidAmountController,
                decoration: const InputDecoration(
                  labelText: 'Paid Amount *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.handHoldingDollar),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final amount = double.tryParse(v);
                  if (amount == null) return 'Invalid number';
                  if (amount <= 0) return 'Amount must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_selectedPaymentType == 'Cheque') ...[
                TextFormField(
                  controller: _chequeNoController,
                  decoration: const InputDecoration(
                    labelText: 'Cheque No *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(FontAwesomeIcons.moneyCheck),
                  ),
                  validator:
                      (v) =>
                          (_selectedPaymentType == 'Cheque' &&
                                  (v == null || v.isEmpty))
                              ? 'Required for cheque'
                              : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedChequeType,
                  decoration: const InputDecoration(
                    labelText: 'Cheque Type *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(FontAwesomeIcons.moneyCheckDollar),
                  ),
                  items:
                      _chequeTypeOptions
                          .map(
                            (String type) => DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                  onChanged:
                      (String? newValue) =>
                          setState(() => _selectedChequeType = newValue),
                  validator:
                      (value) =>
                          (_selectedPaymentType == 'Cheque' && value == null)
                              ? 'Required'
                              : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bankNameController,
                  decoration: const InputDecoration(
                    labelText: 'Bank Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(FontAwesomeIcons.buildingColumns),
                  ),
                  validator:
                      (v) =>
                          (_selectedPaymentType == 'Cheque' &&
                                  (v == null || v.isEmpty))
                              ? 'Required for cheque'
                              : null,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _paymentReferenceNoController,
                decoration: const InputDecoration(
                  labelText: 'Payment Ref No',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.receipt),
                ),
              ),
              const SizedBox(height: 24),
              // Save button is now in the AppBar
            ],
          ),
        ),
      ),
    );
  }
}
