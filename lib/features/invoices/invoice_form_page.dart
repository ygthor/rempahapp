// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rempahapp/models/invoice.dart';
import 'package:rempahapp/models/ar_trans_item.dart';
import 'package:rempahapp/models/global_state.dart';
import 'package:rempahapp/api/api_v1.dart';
import 'package:rempahapp/shared/functions.dart';

// Simplified Product model for selection
class ApiProduct {
  final String ITEMNO;
  final String DESP;

  ApiProduct({required this.DESP, required this.ITEMNO});

  factory ApiProduct.fromJson(Map<String, dynamic> json) {
    return ApiProduct(DESP: json['DESP'] as String? ?? 'Unknown Product', ITEMNO: json['ITEMNO'] as String? ?? '');
  }
}

// Customer model for selection
class Customer {
  final String? customerCode;
  final String? name;

  Customer({required this.customerCode, this.name});

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(customerCode: json['customer_code'] as String?, name: json['name'] as String?);
  }
}

class InvoiceFormPage extends StatefulWidget {
  final Invoice? invoice; // To support editing

  const InvoiceFormPage({super.key, this.invoice});

  @override
  State<InvoiceFormPage> createState() => _InvoiceFormPageState();
}

class _InvoiceFormPageState extends State<InvoiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  late ApiV1 _api;

  bool _isLoading = false;
  bool _isLoadingProducts = true;
  bool _isLoadingCustomers = false; // For loading customers in dialog
  String _productLoadingErrorMessage = '';

  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // --- Form State Variables ---
  Customer? _selectedCustomer;
  final TextEditingController _customerDisplayController = TextEditingController(text: "Tap to select customer");

  ApiProduct? _selectedApiProduct;
  final TextEditingController _quantityController = TextEditingController(text: "1");
  final TextEditingController _unitPriceController = TextEditingController(text: "0.00");
  final TextEditingController _amountController = TextEditingController(text: "0.00");

  final TextEditingController _remarksController = TextEditingController();
  DateTime? _selectedDate = DateTime.now();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _typeController = TextEditingController(text: 'IV'); // Default to Invoice
  final TextEditingController _referenceNoController = TextEditingController(text: 'SYSTEM AUTO ASSIGN');

  List<ArTransItem> _currentInvoiceItems = [];
  List<ApiProduct> _apiProducts = [];

  bool get _isEditMode => _invoice != null;
  Invoice? _invoice;

  @override
  void initState() {
    super.initState();
    GlobalState gs = Get.find<GlobalState>();
    _api = ApiV1(bearerToken: gs.token);
    _invoice = widget.invoice;

    _fetchProducts();

    _quantityController.addListener(_calculateAmount);
    _unitPriceController.addListener(_calculateAmount);
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);

    if (_isEditMode && _invoice != null) {
      Future.delayed(Duration.zero, () async {
        await _fetchInvoice();
      });
    }
  }

  Future<void> _fetchInvoice() async {
    if (_invoice == null) _loadInvoiceDetails();

    _customerDisplayController.text = _invoice!.name ?? '';
    _selectedCustomer = Customer(customerCode: _invoice!.custNo, name: _invoice!.name);
    _remarksController.text = _invoice!.note ?? '';
    _referenceNoController.text = _invoice!.refNo ?? '';
    // _discountController.text = _order!.discount.toString();
    // _taxPercentageController.text = _order!.tax1Percentage.toString();
  }

  void _loadInvoiceDetails() {
    final inv = _invoice!;
    _customerDisplayController.text = inv.name ?? '';
    _selectedCustomer = Customer(customerCode: inv.custNo, name: inv.name);
    _remarksController.text = inv.note ?? '';
    _referenceNoController.text = inv.refNo ?? 'N/A';
    _typeController.text = inv.type ?? 'IV';
    _selectedDate = inv.date;
    _dateController.text = inv.date != null ? DateFormat('yyyy-MM-dd').format(inv.date!) : '';
    _currentInvoiceItems = List<ArTransItem>.from(inv.items);
    setState(() {});
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _productLoadingErrorMessage = '';
    });
    try {
      // Assuming ApiV1.getProducts() returns the structure:
      // {"error":0,"status":200,"message":"...","data":[PRODUCT_LIST]}
      // OR a direct list on success for older ApiV1 versions.
      final dynamic response = await _api.getIcitem();
      aLog("GetProducts Response: $response");
      List<dynamic>? productDataList;
      bool responseError = false;
      String responseMessage = "Failed to load products.";

      if (response is List) {
        // Direct list from API (less likely with makeResponse)
        productDataList = response;
      } else if (response is Map<String, dynamic>) {
        responseError = response['error'] == 1 || response['error'] == true;
        responseMessage = response['message']?.toString() ?? responseMessage;
        if (!responseError && response['data'] is List) {
          productDataList = response['data'];
        } else if (responseError) {
          _productLoadingErrorMessage = responseMessage;
        } else {
          _productLoadingErrorMessage = "Products API response format is unexpected (Map without data list).";
        }
      } else if (response == null) {
        _productLoadingErrorMessage = "No response from product server.";
      } else {
        _productLoadingErrorMessage = "Products API returned an unknown format.";
      }

      if (productDataList != null) {
        _apiProducts =
            productDataList
                .map((data) {
                  try {
                    return ApiProduct.fromJson(data as Map<String, dynamic>);
                  } catch (e) {
                    aLog("Error parsing API product: $data, error: $e");
                    return null;
                  }
                })
                .whereType<ApiProduct>()
                .toList();
      } else if (!responseError && productDataList == null) {
        // If not an error but list is null/not found
        _productLoadingErrorMessage =
            _productLoadingErrorMessage.isEmpty ? "No product data found." : _productLoadingErrorMessage;
      }
    } catch (e, s) {
      aLog("Exception in _fetchProducts: $e\nStack trace: $s");
      _productLoadingErrorMessage = "Error fetching products.";
    } finally {
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _customerDisplayController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _amountController.dispose();
    _remarksController.dispose();
    _dateController.dispose();
    _typeController.dispose();
    _referenceNoController.dispose();
    super.dispose();
  }

  void _calculateAmount() {
    final double quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final double unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;
    _amountController.text = (quantity * unitPrice).toStringAsFixed(2);
  }

  void _onApiProductChanged(ApiProduct? product) {
    setState(() {
      _selectedApiProduct = product;
      if (product != null) {
        // You might fetch the product's default price here
        if (_quantityController.text == "0") _quantityController.text = "1";
      }
      _calculateAmount();
    });
  }

  void _addItemToInvoice() async {
    // ... (Validation logic similar to Order form)

    if (_invoice == null) {
      showVDialog(title: "Error", text: "Please save the invoice header first.");
      return;
    }

    setState(() => _isLoading = true);

    var body = {
      "artran_id": _invoice!.id,
      "product_id": _selectedApiProduct!.ITEMNO.toString(),
      "quantity": double.tryParse(_quantityController.text) ?? 0.0,
      "unit_price": double.tryParse(_unitPriceController.text) ?? 0.0,
    };

    try {
      final response = await _api.createInvoiceItem(body);
      // ... (Handle success/error response similar to your order form)
      // On success, refresh the invoice details to get the updated item list
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _deleteInvoiceItem(ArTransItem item) async {
    // ... (Logic similar to deleting an order item, calling `_api.deleteInvoiceItem`)
  }

  double get _totalInvoiceAmount => _currentInvoiceItems.fold(0.0, (sum, item) => sum + item.amountBilled);

  Future<void> _submitInvoice() async {
    if (_selectedCustomer == null) {
      showVDialog(title: "Validation Error", text: "Please select a customer.");
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> invoiceData = {
      'type': _typeController.text,
      'customer_code': _selectedCustomer!.customerCode,
      'date': _dateController.text,
      'remarks': _remarksController.text,
      // You can add other header fields here
      'items':
          _currentInvoiceItems
              .map(
                (item) => {
                  // This is for CREATE only
                  'product_id': item.tranCode, // This needs mapping from tranCode to product id
                  'quantity': item.quantity,
                  'unit_price': item.price,
                },
              )
              .toList(),
    };

    try {
      final Map<String, dynamic>? response;
      if (_isEditMode) {
        invoiceData.remove('items'); // Items are managed separately in edit mode
        response = await _api.updateInvoice(_invoice!.refNo, invoiceData);
      } else {
        response = await _api.createInvoice(invoiceData);
      }

      // ... (Handle success/error response from API)

      if (response != null && response['data'] is Map) {
        await showVDialog(title: "Success", text: response['message'] ?? "Success", type: 'success');
        final newInvoice = Invoice.fromJson(response['data']);
        if (!_isEditMode) {
          // In create mode, navigate to the edit page of the newly created invoice
          Get.off(() => InvoiceFormPage(invoice: newInvoice));
        } else {
          // In edit mode, just reload the data
          setState(() {
            _invoice = newInvoice;
            _loadInvoiceDetails();
          });
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Updated to fetch and allow selection of a customer
  Future<void> _showCustomerSelectionDialog() async {
    setState(() {
      _isLoadingCustomers = true;
    });
    List<Customer> fetchedCustomers = [];
    String? fetchError;

    try {
      // Assuming ApiV1.getCustomers() returns your makeResponse structure:
      // {"error":0, "status":200, "message":"...", "data":[CUSTOMER_LIST]}
      final dynamic response = await _api.getCustomers(); // Use the method name you provided
      aLog("Fetched Customers Response: $response");

      if (response != null && response is Map<String, dynamic>) {
        bool hasError = response['error'] == 1 || response['error'] == true;
        int status = response['status'] as int? ?? 0;

        if (!hasError && (status >= 200 && status < 300) && response['data'] is List) {
          final List<dynamic> customerDataList = response['data'];
          fetchedCustomers = customerDataList.map((data) => Customer.fromJson(data as Map<String, dynamic>)).toList();
        } else {
          fetchError = response['message']?.toString() ?? "Failed to fetch customers.";
        }
      } else if (response is List) {
        // Fallback if API returns list directly
        fetchedCustomers = response.map((data) => Customer.fromJson(data as Map<String, dynamic>)).toList();
      } else {
        fetchError = "Invalid response format from customer API.";
      }
    } catch (e) {
      fetchError = "Error fetching customers: $e";
    } finally {
      setState(() {
        _isLoadingCustomers = false;
      });
    }

    if (fetchError != null) {
      showVDialog(title: "Error Loading Customers", text: fetchError);
      return;
    }

    if (fetchedCustomers.isEmpty) {
      showVDialog(title: "No Customers", text: "No customers found to select.");
      return;
    }

    // --- Actual Dialog for Selection ---
    // This is a simplified dialog. You might want a more sophisticated searchable list.
    final Customer? selected = await Get.dialog<Customer>(
      AlertDialog(
        title: const Text('Select Customer'),
        content: SizedBox(
          width: double.maxFinite,
          child:
              _isLoadingCustomers
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                    shrinkWrap: true,
                    itemCount: fetchedCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = fetchedCustomers[index];
                      return ListTile(
                        title: Text(customer.name ?? customer.name ?? 'Unnamed Customer'),
                        subtitle: Text(customer.customerCode ?? 'ID: ${customer.customerCode}'),
                        onTap: () {
                          Get.back(result: customer); // Return the selected customer
                        },
                      );
                    },
                  ),
        ),
        actions: [TextButton(onPressed: () => Get.back(), child: const Text('Cancel'))],
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedCustomer = selected;
        _customerDisplayController.text = selected.name ?? selected.name ?? 'ID: ${selected.customerCode}';
      });
    }
  }

  void _onTabTapped(int index) {
    if (index == 1 && !_isEditMode) {
      showVDialog(title: 'Warning', text: 'Create Invoice first before adding items.');
      return;
    }
    setState(() => _currentIndex = index);
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  // --- BUILD METHODS ---

  @override
  Widget build(BuildContext context) {
    // ... (The main scaffold, PageView, and BottomNavigationBar structure remains the same)
    // Just change text from "Order" to "Invoice"
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Invoice #${_invoice!.refNo ?? ''}' : 'Create Invoice')),
      body: Form(
        key: _formKey,
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          children: [_buildInvoiceInfoTab(), _buildInvoiceItemsTab()],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: 'Invoice Info'),
          BottomNavigationBarItem(
            icon: Badge(label: Text('${_currentInvoiceItems.length}'), child: Icon(Icons.receipt_long_outlined)),
            label: 'Invoice Items',
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildFloatingActionButton() {
    if (_currentIndex == 0) {
      return FloatingActionButton.extended(
        onPressed: _submitInvoice,
        label: Text(_isEditMode ? 'Update Invoice' : 'Create Invoice & Add Items'),
        icon: Icon(Icons.check),
      );
    } else if (_currentIndex == 1) {
      return FloatingActionButton.extended(
        onPressed: () => _showProductModalSheet(context),
        label: Text('Add New Item'),
        icon: Icon(Icons.add),
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildInvoiceInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0), // Padding for FAB
      child: Column(
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invoice Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // --- ADDED: The missing fields are now here ---

                  // Reference No Field
                  TextFormField(
                    controller: _referenceNoController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Reference No',
                      prefixIcon: Icon(FontAwesomeIcons.hashtag),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Customer Selection Field
                  InkWell(
                    onTap: _showCustomerSelectionDialog,
                    child: IgnorePointer(
                      child: TextFormField(
                        controller: _customerDisplayController,
                        decoration: const InputDecoration(
                          labelText: 'Customer',
                          prefixIcon: Icon(FontAwesomeIcons.solidUser),
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date Selection Field
                  InkWell(
                    onTap: _selectDate,
                    child: IgnorePointer(
                      child: TextFormField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(FontAwesomeIcons.calendarDay),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Note/Remarks Field
                  TextFormField(
                    controller: _remarksController,
                    decoration: const InputDecoration(
                      labelText: 'Remarks / Note',
                      prefixIcon: Icon(FontAwesomeIcons.solidComment),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          if (_isEditMode && _invoice != null)
            Card(
              margin: const EdgeInsets.only(top: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Gross Amount', _invoice!.grossBill),
                    _buildSummaryRow('Grand Total', _invoice!.grandBil),
                    _buildSummaryRow('Net Amount', _invoice!.netBil, isBold: true),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      });
    }
  }

  Widget _buildInvoiceItemsTab() {
    return Column(
      children: [
        // ... (Header with customer name and total amount is similar)
        Expanded(
          child: ListView.builder(
            itemCount: _currentInvoiceItems.length,
            itemBuilder: (context, index) {
              final item = _currentInvoiceItems[index];
              return Card(
                child: ListTile(
                  title: Text(item.description),
                  subtitle: Text('Qty: ${item.quantity} @ ${item.price.toStringAsFixed(2)}'),
                  trailing: Text('Total: ${item.amountBilled.toStringAsFixed(2)}'),
                  // Add delete button here
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showProductModalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildProductForm(context), // extracted widget
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductForm(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Hides the keyboard
      },
      behavior: HitTestBehavior.opaque, // Ensures taps on empty space are detected

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          // Product Selection Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add New Item',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(), // Close the modal
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _isLoadingProducts
                  ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                  : _productLoadingErrorMessage.isNotEmpty
                  ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(_productLoadingErrorMessage, style: const TextStyle(color: Colors.red)),
                  )
                  : DropdownButtonFormField<ApiProduct>(
                    value: _selectedApiProduct,
                    decoration: const InputDecoration(
                      labelText: 'Product *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(FontAwesomeIcons.box),
                    ),
                    items:
                        _apiProducts
                            .map(
                              (ApiProduct product) =>
                                  DropdownMenuItem<ApiProduct>(value: product, child: Text(product.DESP)),
                            )
                            .toList(),
                    onChanged: _onApiProductChanged,
                    validator: (value) => value == null ? 'Please select a product' : null,
                    isExpanded: true,
                  ),
              const SizedBox(height: 12),
              _buildTextFormField(
                _quantityController,
                'Quantity *',
                FontAwesomeIcons.cubesStacked,
                TextInputType.number,
                (v) {
                  if (v == null || v.isEmpty) return 'Enter quantity';
                  if (double.tryParse(v) == null) return 'Invalid number';

                  return null;
                },
              ),

              const SizedBox(height: 12),
              _buildTextFormField(
                _unitPriceController,
                'Unit Price *',
                FontAwesomeIcons.dollarSign,
                const TextInputType.numberWithOptions(decimal: true),
                (v) {
                  if (v == null || v.isEmpty) return 'Enter unit price';
                  final price = double.tryParse(v);
                  if (price == null) return 'Invalid number';

                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildTextFormField(
                _amountController,
                'Amount',
                FontAwesomeIcons.moneyBillWave,
                TextInputType.number,
                null,
                readOnly: true,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          Container(
            padding: EdgeInsets.all(5),
            alignment: Alignment.center,
            child: ElevatedButton(onPressed: _addItemToInvoice, child: Text('Add To Order')),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double? value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value != null ? value.toStringAsFixed(2) : '0.00',
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField(
    TextEditingController controller,
    String label,
    IconData icon,
    TextInputType inputType,
    String? Function(String?)? validator, {
    bool readOnly = false,
    TextStyle? textStyle,
    VoidCallback? onTap, // Add this
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), prefixIcon: Icon(icon)),
      keyboardType: inputType,
      validator: validator,
      readOnly: readOnly,
      style: textStyle,
      onTap: readOnly ? onTap : null, // Only use onTap if readOnly
    );
  }
}
