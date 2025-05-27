import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:rempahapp/models/order.dart'; // Ensure this path is correct
import 'package:rempahapp/models/order_item.dart'; // Ensure this path is correct
// Assuming the simple ApiProduct model is still relevant for product selection
// If not, and you have a richer Product model for local use, adjust accordingly.
// For this example, we'll keep ApiProduct for the product dropdown.
// import 'package:rempahapp/models/product.dart';
import 'package:rempahapp/models/global_state.dart'; // For token
import 'package:rempahapp/api/api_v1.dart'; // Your API service
import 'package:rempahapp/shared/functions.dart'; // For aLog, showVDialog

// Simplified Product model based on API response for product listing
class ApiProduct {
  final int id; // From API "Id"
  final String productName; // From API "ProductName"

  ApiProduct({required this.id, required this.productName});

  factory ApiProduct.fromJson(Map<String, dynamic> json) {
    return ApiProduct(
      id: json['Id'] as int,
      productName: json['ProductName'] as String? ?? 'Unknown Product',
    );
  }
}
// --- End of ApiProduct Model ---

// Customer model (as defined in your CustomerListPageFromApi or a shared models file)
// This should have an integer `id` field.
class Customer {
  final int id; // From API "id": 3 (integer)
  final String? customerCode;
  final String? name;
  final String? companyName;
  // Add other fields as necessary, matching your actual Customer model
  // For this example, id and companyName are most relevant for the form.

  Customer({
    required this.id,
    this.customerCode,
    this.name,
    this.companyName,
    // Initialize other fields
  });

  // Add fromJson if not already present in your shared Customer model
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int, // API sends 'id' as int
      customerCode: json['customer_code'] as String?,
      name: json['name'] as String?,
      companyName: json['company_name'] as String?,
      // Parse other fields from your Customer API response here
      // e.g., address1: json['address1'] as String?,
    );
  }
}

class OrderFormPage extends StatefulWidget {
  final Order? order; // To support editing later

  const OrderFormPage({super.key, this.order});

  @override
  State<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  final _formKey = GlobalKey<FormState>();
  late ApiV1 _api;
  bool _isLoading = false; // For submitting order
  bool _isLoadingProducts = true;
  bool _isLoadingCustomers = false; // For loading customers in dialog
  String _productLoadingErrorMessage = '';

  // --- Form State Variables ---
  Customer?
  _selectedCustomer; // Holds the selected customer object with an integer ID
  final TextEditingController _customerDisplayController =
      TextEditingController(text: "Tap to select customer");

  ApiProduct? _selectedApiProduct;

  final TextEditingController _quantityController = TextEditingController(
    text: "1",
  );
  bool _isFreeGood = false;
  bool _isTradeReturn = false;
  bool _tradeReturnGood = true;
  final TextEditingController _unitPriceController = TextEditingController(
    text: "0.00",
  );
  final TextEditingController _amountController = TextEditingController(
    text: "0.00",
  );
  final TextEditingController _discountController = TextEditingController(
    text: "0.00",
  );
  final TextEditingController _remarksController = TextEditingController();

  List<OrderItem> _currentOrderItems = [];
  List<ApiProduct> _apiProducts = [];

  bool get _isEditMode => widget.order != null;

  @override
  void initState() {
    super.initState();
    GlobalState gs = Get.find<GlobalState>();
    _api = ApiV1(bearerToken: gs.token);

    _fetchProducts();

    _quantityController.addListener(_calculateAmount);
    _unitPriceController.addListener(_calculateAmount);
    _discountController.addListener(_calculateAmount);

    // No longer selecting dummy customer here, user will tap to select.

    if (_isEditMode && widget.order != null) {
      // If editing, try to find the customer by ID or use passed customerName
      // This part needs a robust way to get the full Customer object if only ID is passed in widget.order.customerId
      _customerDisplayController.text = widget.order!.customerName;
      // For simplicity, assuming widget.order.customerId is the INT ID as string, or you have a way to get it.
      // This is a placeholder; proper customer object loading for edit is needed.
      // You might need to fetch the customer from API if only ID is available.
      _selectedCustomer = Customer(
        id:
            int.tryParse(widget.order!.customerId) ??
            0, // This needs to be the actual int ID
        companyName: widget.order!.customerName,
      );

      _remarksController.text = widget.order!.remarks ?? '';
      _currentOrderItems = List<OrderItem>.from(widget.order!.items);
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
      final dynamic response = await _api.getProducts();
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
          _productLoadingErrorMessage =
              "Products API response format is unexpected (Map without data list).";
        }
      } else if (response == null) {
        _productLoadingErrorMessage = "No response from product server.";
      } else {
        _productLoadingErrorMessage =
            "Products API returned an unknown format.";
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
            _productLoadingErrorMessage.isEmpty
                ? "No product data found."
                : _productLoadingErrorMessage;
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
    _customerDisplayController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _amountController.dispose();
    _discountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _calculateAmount() {
    if (_isFreeGood) {
      _amountController.text = "0.00";
      return;
    }
    final double quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final double unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;
    final double discount = double.tryParse(_discountController.text) ?? 0.0;
    final double amount = (quantity * unitPrice) - discount;
    _amountController.text = amount.toStringAsFixed(2);
  }

  void _onApiProductChanged(ApiProduct? product) {
    setState(() {
      _selectedApiProduct = product;
      if (product != null) {
        if (_isFreeGood) _unitPriceController.text = "0.00";
        // Price needs to be manually entered or fetched if not in ApiProduct
        if (_quantityController.text == "0") _quantityController.text = "1";
      } else {
        _resetProductDetails();
      }
      _calculateAmount();
    });
  }

  void _resetProductDetails() {
    _selectedApiProduct = null;
    _unitPriceController.text = "0.00";
    _quantityController.text = "0"; // Or "1" if you prefer
    _discountController.text = "0.00";
    _isFreeGood = false;
    _isTradeReturn = false;
    _tradeReturnGood = true;
    _calculateAmount();
  }

  void _addItemToOrder() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedApiProduct == null) {
      showVDialog(title: "Validation Error", text: "Please select a product.");
      return;
    }
    final double quantity = double.tryParse(_quantityController.text) ?? 0.0;
    if (quantity <= 0 && !_isFreeGood) {
      showVDialog(
        title: "Validation Error",
        text: "Quantity must be > 0 unless free good.",
      );
      return;
    }
    final double unitPrice =
        _isFreeGood ? 0.0 : (double.tryParse(_unitPriceController.text) ?? 0.0);
    if (!_isFreeGood && unitPrice <= 0) {
      showVDialog(
        title: "Validation Error",
        text: "Unit price must be > 0 for non-free goods.",
      );
      return;
    }

    setState(() {
      _currentOrderItems.add(
        OrderItem(
          productId:
              _selectedApiProduct!.id
                  .toString(), // API expects integer product ID
          productName: _selectedApiProduct!.productName,
          skuCode: 'N/A', // SKU not available from this simplified product API
          quantity: quantity,
          unitPrice: unitPrice,
          discount: double.tryParse(_discountController.text) ?? 0.0,
          isFreeGood: _isFreeGood,
          isTradeReturn: _isTradeReturn,
          tradeReturnIsGood: _isTradeReturn ? _tradeReturnGood : true,
        ),
      );
      _resetProductDetails();
      _quantityController.text = "1";
    });
  }

  void _cancelItemEntry() {
    setState(() {
      _resetProductDetails();
    });
  }

  double get _totalOrderAmount =>
      _currentOrderItems.fold(0.0, (sum, item) => sum + item.amount);

  Future<void> _submitOrder() async {
    if (_selectedCustomer == null || _selectedCustomer!.id == 0) {
      showVDialog(
        title: "Validation Error",
        text: "Please select a valid customer.",
      );
      return;
    }
    if (_currentOrderItems.isEmpty) {
      showVDialog(
        title: "Validation Error",
        text: "Please add at least one item to the order.",
      );
      return;
    }
    // Additional form validation for the whole form if needed
    // if (!(_formKey.currentState?.validate() ?? false)) {
    //   return;
    // }

    setState(() {
      _isLoading = true;
    });

    final orderToSubmit = Order(
      customerId:
          _selectedCustomer!.id
              .toString(), // Use the integer ID, converted to string for the model
      customerName:
          _selectedCustomer!.companyName ?? _selectedCustomer!.name ?? 'N/A',
      items: _currentOrderItems,
      orderDate: DateTime.now(),
      remarks:
          _remarksController.text.trim().isEmpty
              ? null
              : _remarksController.text.trim(),
      status: 'pending',
    );

    try {
      final Map<String, dynamic>? response = await _api.createOrder(
        orderToSubmit.toJson(),
      );
      setState(() {
        _isLoading = false;
      });

      if (response != null) {
        bool hasErrorFlag = response['error'] == 1 || response['error'] == true;
        int responseStatus = response['status'] as int? ?? 0;

        if (!hasErrorFlag && (responseStatus >= 200 && responseStatus < 300)) {
          await showVDialog(
            title: "Success",
            text: response['message'] ?? "Order created successfully!",
          );
          Get.back(result: true);
        } else {
          String errorMessage =
              response['message']?.toString() ?? 'Failed to create order.';
          if (responseStatus == 422 &&
              response['data'] is Map &&
              response['data']['errors'] is Map) {
            Map<String, dynamic> validationErrors = response['data']['errors'];
            StringBuffer errorsBuffer = StringBuffer(errorMessage + "\n");
            validationErrors.forEach((field, messages) {
              if (messages is List && messages.isNotEmpty)
                errorsBuffer.writeln("- $field: ${messages.join(', ')}");
            });
            errorMessage = errorsBuffer.toString().trim();
          }
          showVDialog(
            title: "Order Submission Failed (Status: $responseStatus)",
            text: errorMessage,
          );
        }
      } else {
        showVDialog(title: "Error", text: "No response from server.");
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
      final dynamic response =
          await _api.getCustomers(); // Use the method name you provided
      aLog("Fetched Customers Response: $response");

      if (response != null && response is Map<String, dynamic>) {
        bool hasError = response['error'] == 1 || response['error'] == true;
        int status = response['status'] as int? ?? 0;

        if (!hasError &&
            (status >= 200 && status < 300) &&
            response['data'] is List) {
          final List<dynamic> customerDataList = response['data'];
          fetchedCustomers =
              customerDataList
                  .map(
                    (data) => Customer.fromJson(data as Map<String, dynamic>),
                  )
                  .toList();
        } else {
          fetchError =
              response['message']?.toString() ?? "Failed to fetch customers.";
        }
      } else if (response is List) {
        // Fallback if API returns list directly
        fetchedCustomers =
            response
                .map((data) => Customer.fromJson(data as Map<String, dynamic>))
                .toList();
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
                        title: Text(
                          customer.companyName ??
                              customer.name ??
                              'Unnamed Customer',
                        ),
                        subtitle: Text(
                          customer.customerCode ?? 'ID: ${customer.id}',
                        ),
                        onTap: () {
                          Get.back(
                            result: customer,
                          ); // Return the selected customer
                        },
                      );
                    },
                  ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ],
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedCustomer = selected;
        _customerDisplayController.text =
            selected.companyName ?? selected.name ?? 'ID: ${selected.id}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Order' : 'Create Order'),
        actions: [
          if (_isEditMode)
            _isLoading
                ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
                : IconButton(
                  icon: const Icon(Icons.save_alt_outlined),
                  onPressed: _submitOrder,
                  tooltip: 'Save Changes',
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              InkWell(
                onTap: _showCustomerSelectionDialog,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Customer *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person_search_outlined),
                  ),
                  child: Text(
                    _customerDisplayController
                        .text, // Updated to use controller
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          _selectedCustomer == null
                              ? Colors.grey.shade700
                              : Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _isLoadingProducts
                  ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                  : _productLoadingErrorMessage.isNotEmpty
                  ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _productLoadingErrorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
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
                                  DropdownMenuItem<ApiProduct>(
                                    value: product,
                                    child: Text(product.productName),
                                  ),
                            )
                            .toList(),
                    onChanged: _onApiProductChanged,
                    validator:
                        (value) =>
                            value == null ? 'Please select a product' : null,
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
                  if (!_isFreeGood && (double.tryParse(v) ?? 0) <= 0)
                    return 'Quantity > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text("Free Goods"),
                value: _isFreeGood,
                onChanged:
                    (val) => setState(() {
                      _isFreeGood = val ?? false;
                      if (_isFreeGood) {
                        _isTradeReturn = false;
                        _unitPriceController.text = "0.00";
                      }
                      _calculateAmount();
                    }),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: const Text("Trade Return"),
                value: _isTradeReturn,
                onChanged:
                    (val) => setState(() {
                      _isTradeReturn = val ?? false;
                      if (_isTradeReturn) _isFreeGood = false;
                    }),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_isTradeReturn)
                Padding(
                  padding: const EdgeInsets.only(left: 24.0, right: 16.0),
                  child: Row(
                    children: [
                      const Text("Condition:"),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Good'),
                        selected: _tradeReturnGood,
                        onSelected:
                            (s) => setState(() => _tradeReturnGood = true),
                        selectedColor: Colors.green.shade100,
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Bad'),
                        selected: !_tradeReturnGood,
                        onSelected:
                            (s) => setState(() => _tradeReturnGood = false),
                        selectedColor: Colors.red.shade100,
                      ),
                    ],
                  ),
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
                  if (!_isFreeGood && price <= 0)
                    return 'Price must be > 0 for non-free goods';
                  return null;
                },
                readOnly: _isFreeGood,
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
              const SizedBox(height: 12),
              _buildTextFormField(
                _discountController,
                'Discount',
                FontAwesomeIcons.tags,
                const TextInputType.numberWithOptions(decimal: true),
                (v) {
                  if (v == null || v.isEmpty)
                    return 'Enter discount (0 if none)';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Add Item'),
                    onPressed: _addItemToOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel Entry'),
                    onPressed: _cancelItemEntry,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(thickness: 1),
              const SizedBox(height: 16),
              Text(
                'Order Items:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              _currentOrderItems.isEmpty
                  ? const Center(child: Text('No items added yet.'))
                  : _buildOrderItemsList(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Total Order Amount: ',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    _totalOrderAmount.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
          _isLoading
              ? FloatingActionButton(
                onPressed: null,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.0,
                ),
                backgroundColor: Theme.of(context).colorScheme.secondary,
              )
              : FloatingActionButton.extended(
                onPressed: _submitOrder,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(_isEditMode ? 'Update Order' : 'Submit Order'),
              ),
    );
  }

  Widget _buildOrderItemsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _currentOrderItems.length,
      itemBuilder: (context, index) {
        final item = _currentOrderItems[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(item.skuCode.isNotEmpty ? item.skuCode[0] : 'P'),
            ),
            title: Text("${item.productName} (${item.skuCode})"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Qty: ${item.quantity}, Price: ${item.unitPrice.toStringAsFixed(2)}',
                ),
                if (item.discount > 0)
                  Text(
                    'Disc: ${item.discount.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.orange),
                  ),
                if (item.isFreeGood)
                  const Text(
                    'Free Good',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (item.isTradeReturn)
                  Text(
                    'Trade Return: ${item.tradeReturnIsGood ? "Good" : "Bad"}',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            trailing: Text(
              'Amt: ${item.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onLongPress:
                () => setState(() {
                  _currentOrderItems.removeAt(index);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item.productName} removed'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }),
          ),
        );
      },
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
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      keyboardType: inputType,
      validator: validator,
      readOnly: readOnly,
      style: textStyle,
    );
  }
}
