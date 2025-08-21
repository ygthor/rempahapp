// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kanesanapp/models/customer.dart';
import 'package:kanesanappp/models/invoice.dart';
import 'package:kanesanappp/models/ar_trans_item.dart';
import 'package:kanesanappp/models/global_state.dart';
import 'package:kanesanappp/api/api_v1.dart';
import 'package:kanesanappp/shared/functions.dart';

// Simplified Product model for selection
class ApiProduct {
  final String ITEMNO;
  final String DESP;

  ApiProduct({required this.DESP, required this.ITEMNO});

  factory ApiProduct.fromJson(Map<String, dynamic> json) {
    return ApiProduct(DESP: json['DESP'] as String? ?? 'Unknown Product', ITEMNO: json['ITEMNO'] as String? ?? '');
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

  // NEW: Add a state variable for the selected invoice type
  String? _selectedInvoiceType;

  // NEW: Define the available invoice type options
  final Map<String, String> _invoiceTypeOptions = {'INV': 'Invoice', 'CB': 'Cash Bill', 'CN': 'Credit Note'};

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
      // MODIFIED: In edit mode, set the type from the existing invoice data
      _selectedInvoiceType = _invoice!.type;

      Future.delayed(Duration.zero, () async {
        await _fetchInvoice();
      });
    } else {
      // MODIFIED: In create mode, set a default type
      _selectedInvoiceType = 'INV'; // Default to 'Invoice'
    }
  }

  Future<void> _fetchInvoice() async {
    await _loadInvoiceDetails();

    _customerDisplayController.text = _invoice!.name ?? '';
    _selectedCustomer = Customer(customerCode: _invoice!.custNo, name: _invoice!.name);
    _remarksController.text = _invoice!.note ?? '';
    _referenceNoController.text = _invoice!.refNo ?? '';
    // _discountController.text = _order!.discount.toString();
    // _taxPercentageController.text = _order!.tax1Percentage.toString();
  }

  Future _loadInvoiceDetails() async {
    aLog("load invoice");
    if (_invoice!.refNo != null) {
      var res = await _api.getInvoiceByRefNo(_invoice!.refNo!);

      _invoice = Invoice.fromJson(res!['data']);
      Invoice inv = _invoice!;

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
        final rawProducts =
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

        // --- FIX: De-duplicate the list to prevent the assertion error ---
        // We use a Map to ensure every ITEMNO is unique.
        // If a duplicate ITEMNO is found, it will overwrite the previous one.
        final uniqueProductMap = <String, ApiProduct>{};
        for (final product in rawProducts) {
          uniqueProductMap[product.ITEMNO] = product;
        }

        // Assign the clean, de-duplicated list of products.
        _apiProducts = uniqueProductMap.values.toList();
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
    _customerDisplayController.removeListener(_calculateAmount);
    _unitPriceController.removeListener(_calculateAmount);
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

  Future<void> _saveInvoiceItem({ArTransItem? itemToEdit}) async {
    // Basic Validation
    if (_selectedApiProduct == null) {
      showVDialog(title: "Validation Error", text: "Please select a product.");
      return;
    }
    final double? quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      showVDialog(title: "Validation Error", text: "Please enter a valid quantity.");
      return;
    }
    final double? unitPrice = double.tryParse(_unitPriceController.text);
    if (unitPrice == null || unitPrice < 0) {
      showVDialog(title: "Validation Error", text: "Please enter a valid unit price.");
      return;
    }

    setState(() => _isLoading = true);
    Get.back(); // Close the modal sheet first

    final body = {
      "reference_code": _invoice!.refNo, // Required for create
      "product_code": _selectedApiProduct!.ITEMNO.toString(),
      "quantity": quantity,
      "unit_price": unitPrice,
    };

    try {
      final bool isEditing = itemToEdit != null;
      final response;

      if (isEditing) {
        body.remove("artran_id"); // Not needed for an update call
        response = await _api.updateInvoiceItem(itemToEdit.refNo, body);
      } else {
        response = await _api.createInvoiceItem(body);
      }

      if (response != null && (response['error'] == 0 || response['error'] == false)) {
        await showVDialog(
          title: "Success",
          text: response['message'] ?? (isEditing ? "Item updated successfully." : "Item added successfully."),
          type: 'success',
        );
        // Refresh the entire invoice to get updated totals and the correct item list
        await _loadInvoiceDetails();
      } else {
        showVDialog(title: "Error", text: response?['message'] ?? "An unknown error occurred while saving the item.");
      }
    } catch (e) {
      aLog("Error saving invoice item: $e");
      showVDialog(title: "Error", text: "Failed to save the item due to an exception.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

    // NEW: Add validation for invoice type
    if (_selectedInvoiceType == null) {
      showVDialog(title: "Validation Error", text: "Please select an invoice type.");
      return;
    }

    setState(() => _isLoading = true);
    showVDialog(title: "CUSTOM", text: _selectedCustomer!.customerCode);

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
        response = await _api.updateInvoice(_invoice!.refNo!, invoiceData);
      } else {
        response = await _api.createInvoice(invoiceData);
      }

      // --- MODIFIED: Added comprehensive error handling ---

      if (response == null) {
        // Handle cases where the server is unreachable or returns nothing
        showVDialog(title: "Error", text: "No response from server. Please check your connection.");
      } else {
        // Safely extract response data
        final bool hasError = response['error'] == 1 || response['error'] == true;
        final int status = response['status'] as int? ?? 0; // Default to 0 if status is missing
        final String message = response['message']?.toString() ?? "An unknown error occurred.";

        if (!hasError && isSuccessCode(status) && response['data'] is Map<String, dynamic>) {
          // This is the original success path
          await showVDialog(title: "Success", text: message, type: 'success');

          final newInvoice = Invoice.fromJson(response['data'] as Map<String, dynamic>);

          if (!_isEditMode) {
            // In create mode, navigate to the edit page of the newly created invoice
            // Using Get.off ensures the user can't go back to the now-obsolete create form.
            Get.off(() => InvoiceFormPage(invoice: newInvoice));
          } else {
            // In edit mode, just reload the data to show any server-side updates
            setState(() {
              _invoice = newInvoice;
            });
            // Use a separate await to ensure the state is set before loading details
            await _loadInvoiceDetails();
          }
        } else {
          // NEW: This block handles API-level errors (e.g., status 404, 500, validation error)
          showVDialog(title: "Operation Failed", text: "Error (Status $status): $message");
        }
      }
    } catch (e) {
      // This existing catch block handles exceptions like parsing errors or other unexpected issues
      aLog("Exception during submit invoice: $e");
      showVDialog(title: "Application Error", text: "An unexpected error occurred: ${e.toString()}");
    } finally {
      // This ensures the loading indicator is always hidden after the operation completes
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Updated to fetch and allow selection of a customer
  // Future<void> _showCustomerSelectionDialog() async {
  //   setState(() {
  //     _isLoadingCustomers = true;
  //   });
  //   List<Customer> fetchedCustomers = [];
  //   String? fetchError;

  //   try {
  //     // Assuming ApiV1.getCustomers() returns your makeResponse structure:
  //     // {"error":0, "status":200, "message":"...", "data":[CUSTOMER_LIST]}
  //     final dynamic response = await _api.getCustomers(); // Use the method name you provided
  //     aLog("Fetched Customers Response: $response");

  //     if (response != null && response is Map<String, dynamic>) {
  //       bool hasError = response['error'] == 1 || response['error'] == true;
  //       int status = response['status'] as int? ?? 0;

  //       if (!hasError && (status >= 200 && status < 300) && response['data'] is List) {
  //         final List<dynamic> customerDataList = response['data'];
  //         fetchedCustomers = customerDataList.map((data) => Customer.fromJson(data as Map<String, dynamic>)).toList();
  //       } else {
  //         fetchError = response['message']?.toString() ?? "Failed to fetch customers.";
  //       }
  //     } else if (response is List) {
  //       // Fallback if API returns list directly
  //       fetchedCustomers = response.map((data) => Customer.fromJson(data as Map<String, dynamic>)).toList();
  //     } else {
  //       fetchError = "Invalid response format from customer API.";
  //     }
  //   } catch (e) {
  //     fetchError = "Error fetching customers: $e";
  //   } finally {
  //     setState(() {
  //       _isLoadingCustomers = false;
  //     });
  //   }

  //   if (fetchError != null) {
  //     showVDialog(title: "Error Loading Customers", text: fetchError);
  //     return;
  //   }

  //   if (fetchedCustomers.isEmpty) {
  //     showVDialog(title: "No Customers", text: "No customers found to select.");
  //     return;
  //   }

  //   // --- Actual Dialog for Selection ---
  //   // This is a simplified dialog. You might want a more sophisticated searchable list.
  //   final Customer? selected = await Get.dialog<Customer>(
  //     AlertDialog(
  //       title: const Text('Select Customer'),
  //       content: SizedBox(
  //         width: double.maxFinite,
  //         child:
  //             _isLoadingCustomers
  //                 ? const Center(child: CircularProgressIndicator())
  //                 : ListView.builder(
  //                   shrinkWrap: true,
  //                   itemCount: fetchedCustomers.length,
  //                   itemBuilder: (context, index) {
  //                     final customer = fetchedCustomers[index];
  //                     return ListTile(
  //                       title: Text(customer.name ?? customer.name ?? 'Unnamed Customer'),
  //                       subtitle: Text(customer.customerCode ?? 'ID: ${customer.customerCode}'),
  //                       onTap: () {
  //                         Get.back(result: customer); // Return the selected customer
  //                       },
  //                     );
  //                   },
  //                 ),
  //       ),
  //       actions: [TextButton(onPressed: () => Get.back(), child: const Text('Cancel'))],
  //     ),
  //   );

  //   if (selected != null) {
  //     setState(() {
  //       _selectedCustomer = selected;
  //       _customerDisplayController.text = selected.name ?? selected.name ?? 'ID: ${selected.customerCode}';
  //     });
  //   }
  // }

  Future<void> _showCustomerSelectionSheet() async {
    // Hide keyboard if it's open
    FocusScope.of(context).unfocus();

    final Customer? selected = await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true, // Important for the modal to resize when the keyboard appears
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return const _CustomerSelectionSheet();
      },
    );

    if (selected != null) {
      setState(() {
        _selectedCustomer = selected;
        _customerDisplayController.text = selected.name ?? 'ID: ${selected.customerCode}';
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
        label: Text(_isEditMode ? 'Update Invoice' : 'Create Invoice'),
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

                  // Reference No Field (existing)
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

                  // NEW: Invoice Type Dropdown
                  if (!_isEditMode)
                    DropdownButtonFormField<String>(
                      value: _selectedInvoiceType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        prefixIcon: Icon(FontAwesomeIcons.fileInvoice),
                        border: OutlineInputBorder(),
                      ),
                      // Disable the dropdown in edit mode
                      onChanged:
                          _isEditMode
                              ? null
                              : (String? newValue) {
                                setState(() {
                                  _selectedInvoiceType = newValue;
                                });
                              },
                      items:
                          _invoiceTypeOptions.entries.map((MapEntry<String, String> entry) {
                            return DropdownMenuItem<String>(value: entry.key, child: Text(entry.value));
                          }).toList(),
                      validator: (value) => value == null ? 'Please select an invoice type' : null,
                    ),

                  if (_isEditMode)
                    TextFormField(
                      controller: _typeController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        prefixIcon: Icon(FontAwesomeIcons.layerGroup),
                        filled: true,
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Customer Selection Field
                  InkWell(
                    onTap: _showCustomerSelectionSheet,
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
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Items: ${_currentInvoiceItems.length}', style: Theme.of(context).textTheme.titleMedium),
              Text(
                'RM ${_totalInvoiceAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _currentInvoiceItems.isEmpty
                  ? const Center(
                    child: Text(
                      "No items have been added yet.\nUse the 'Add New Item' button below.",
                      textAlign: TextAlign.center,
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 80), // Padding for FAB
                    itemCount: _currentInvoiceItems.length,
                    itemBuilder: (context, index) {
                      final item = _currentInvoiceItems[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: InkWell(
                          onTap: () => _showEditItemForm(item), // EDIT ACTION
                          borderRadius: BorderRadius.circular(12),
                          child: ListTile(
                            title: Text(item.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Qty: ${item.quantity} @ RM ${item.price.toStringAsFixed(2)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'RM ${item.amountBilled.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _deleteInvoiceItem(item), // DELETE ACTION
                                  tooltip: 'Delete Item',
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  // --- NEW: Helper method to show modal for adding a new item ---
  void _showAddItemForm() {
    // Reset form fields before showing
    setState(() {
      _selectedApiProduct = null;
      _quantityController.text = '1';
      _unitPriceController.text = '0.00';
      _calculateAmount();
    });
    _showProductModalSheet(context); // Call without itemToEdit
  }

  // --- NEW: Helper method to show modal for editing an existing item ---
  void _showEditItemForm(ArTransItem item) {
    // Pre-fill form fields with existing item data
    setState(() {
      // Find the corresponding ApiProduct in our list
      _selectedApiProduct = _apiProducts.firstWhere(
        (p) => p.ITEMNO == item.tranCode,
        orElse: () => ApiProduct(DESP: item.description, ITEMNO: item.tranCode),
      );
      _quantityController.text = item.quantity.toString();
      _unitPriceController.text = item.price.toStringAsFixed(2);
      _calculateAmount();
    });
    _showProductModalSheet(context, itemToEdit: item); // Call with itemToEdit
  }

  // --- MODIFIED: Now accepts an optional item for editing ---
  void _showProductModalSheet(BuildContext context, {ArTransItem? itemToEdit}) {
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
              child: _buildProductForm(context, itemToEdit: itemToEdit), // Pass item to form
            ),
          ),
        );
      },
    );
  }

  // --- MODIFIED: Now accepts an optional item to change its behavior ---
  Widget _buildProductForm(BuildContext context, {ArTransItem? itemToEdit}) {
    final bool isEditing = itemToEdit != null;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Hides the keyboard
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEditing ? 'Edit Item' : 'Add New Item',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop(), tooltip: 'Close'),
            ],
          ),
          const SizedBox(height: 20),
          _isLoadingProducts
              ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
              : _productLoadingErrorMessage.isNotEmpty
              ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(_productLoadingErrorMessage, style: const TextStyle(color: Colors.red)),
              )
              : DropdownButtonFormField<ApiProduct>(
                // value: _selectedApiProduct,
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
          const SizedBox(height: 16),
          _buildTextFormField(_quantityController, 'Quantity *', FontAwesomeIcons.cubesStacked, TextInputType.number, (
            v,
          ) {
            if (v == null || v.isEmpty) return 'Enter quantity';
            if (double.tryParse(v) == null) return 'Invalid number';
            return null;
          }),
          const SizedBox(height: 16),
          _buildTextFormField(
            _unitPriceController,
            'Unit Price *',
            FontAwesomeIcons.dollarSign,
            const TextInputType.numberWithOptions(decimal: true),
            (v) {
              if (v == null || v.isEmpty) return 'Enter unit price';
              if (double.tryParse(v) == null) return 'Invalid number';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            _amountController,
            'Amount',
            FontAwesomeIcons.moneyBillWave,
            TextInputType.number,
            null,
            readOnly: true,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _saveInvoiceItem(itemToEdit: itemToEdit), // Pass item to save method
              icon: Icon(isEditing ? Icons.save_as_outlined : Icons.add_shopping_cart_outlined),
              label: Text(isEditing ? 'Update Item' : 'Add Item to Invoice'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
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

// NEW: A dedicated widget for the customer selection bottom sheet
class _CustomerSelectionSheet extends StatefulWidget {
  const _CustomerSelectionSheet();

  @override
  State<_CustomerSelectionSheet> createState() => _CustomerSelectionSheetState();
}

class _CustomerSelectionSheetState extends State<_CustomerSelectionSheet> {
  late ApiV1 _api;
  final TextEditingController _searchController = TextEditingController();

  // State variables for this widget
  bool _isLoading = true;
  String? _errorMessage;
  List<Customer> _allCustomers = [];
  List<Customer> _filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    GlobalState gs = Get.find<GlobalState>();
    _api = ApiV1(bearerToken: gs.token);

    _fetchCustomers();

    // Add a listener to the search controller to filter the list on text change
    _searchController.addListener(_filterCustomers);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCustomers);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dynamic response = await _api.getCustomers();
      if (response != null && response is Map<String, dynamic> && response['data'] is List) {
        final List<dynamic> customerDataList = response['data'];
        _allCustomers = customerDataList.map((data) => Customer.fromJson(data as Map<String, dynamic>)).toList();
        _filteredCustomers = _allCustomers; // Initially, show all customers
      } else {
        _errorMessage = response?['message']?.toString() ?? "Failed to fetch customers in an expected format.";
      }
    } catch (e) {
      _errorMessage = "An error occurred: ${e.toString()}";
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterCustomers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = _allCustomers;
      } else {
        _filteredCustomers =
            _allCustomers.where((customer) {
              final nameMatches = customer.name?.toLowerCase().contains(query) ?? false;
              final codeMatches = customer.customerCode?.toLowerCase().contains(query) ?? false;
              return nameMatches || codeMatches;
            }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // This padding handles the space for the on-screen keyboard
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75, // Take up 75% of screen height
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Customer', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Search by name or code',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())
                        : null,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildCustomerList()),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)));
    }
    if (_filteredCustomers.isEmpty) {
      return const Center(child: Text('No customers found.'));
    }

    return ListView.builder(
      itemCount: _filteredCustomers.length,
      itemBuilder: (context, index) {
        final customer = _filteredCustomers[index];
        return ListTile(
          title: Text(customer.name ?? 'Unnamed Customer'),
          subtitle: Text(customer.customerCode ?? 'No Code'),
          onTap: () {
            // When a customer is tapped, pop the modal and return the selected customer object
            Navigator.of(context).pop(customer);
          },
        );
      },
    );
  }
}
