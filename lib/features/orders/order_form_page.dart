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
    return ApiProduct(id: json['Id'] as int, productName: json['ProductName'] as String? ?? 'Unknown Product');
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

  // Bottom Navigation State
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // --- Form State Variables ---
  Customer? _selectedCustomer; // Holds the selected customer object with an integer ID
  final TextEditingController _customerDisplayController = TextEditingController(text: "Tap to select customer");

  ApiProduct? _selectedApiProduct;

  final TextEditingController _quantityController = TextEditingController(text: "1");
  bool _isFreeGood = false;
  bool _isTradeReturn = false;
  bool _tradeReturnGood = true;
  final TextEditingController _unitPriceController = TextEditingController(text: "0.00");
  final TextEditingController _amountController = TextEditingController(text: "0.00");
  final TextEditingController _discountController = TextEditingController(text: "0.00");
  final TextEditingController _taxPercentageController = TextEditingController(text: "0.00");
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _orderDateController = TextEditingController();
  DateTime? _selectedOrderDate;
  final TextEditingController _referenceNoController = TextEditingController(
    text: 'SYSTEM AUTO ASSIGN', // Default value
  );

  List<OrderItem> _currentOrderItems = [];
  List<ApiProduct> _apiProducts = [];

  bool get _isEditMode => _order != null;

  late Order? _order;

  @override
  void initState() {
    super.initState();
    GlobalState gs = Get.find<GlobalState>();
    _api = ApiV1(bearerToken: gs.token);
    _order = widget.order;

    _fetchProducts();

    _quantityController.addListener(_calculateAmount);
    _unitPriceController.addListener(_calculateAmount);

    // No longer selecting dummy customer here, user will tap to select.

    if (_isEditMode && _order != null) {
      Future.delayed(Duration.zero, () async {
        await _fetchOrder();
        _customerDisplayController.text = _order!.customerName ?? '';
        _selectedCustomer = Customer(
          id: int.tryParse(_order!.customerId ?? '') ?? 0, // This needs to be the actual int ID
          companyName: _order!.customerName,
        );
        _remarksController.text = _order!.remarks ?? '';
        _referenceNoController.text = _order!.referenceNo ?? '';
        _discountController.text = _order!.discount.toString();
        _taxPercentageController.text = _order!.tax1Percentage.toString();
      });
    }
  }

  Future<void> _fetchOrder() async {
    if (_order == null) return;

    try {
      // Assuming ApiV1.getProducts() returns the structure:
      // {"error":0,"status":200,"message":"...","data":[PRODUCT_LIST]}
      // OR a direct list on success for older ApiV1 versions.
      final dynamic response = await _api.getOrderById(_order!.id ?? '');
      aLog("Order Response: $response");

      bool responseError = false;
      _order = Order.fromJson(response['data']);
      _currentOrderItems = List<OrderItem>.from(_order!.items ?? []);

      if (response is List) {
      } else if (response is Map<String, dynamic>) {
        responseError = response['error'] == 1 || response['error'] == true;

        if (!responseError && response['data'] is List) {
        } else if (responseError) {
        } else {}
      } else if (response == null) {
      } else {}
    } catch (e, s) {
      aLog("Exception in _fetchOrder: $e\nStack trace: $s");
      _productLoadingErrorMessage = "Error fetching order.";
    } finally {
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
    _customerDisplayController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _amountController.dispose();
    _discountController.dispose();
    _remarksController.dispose();
    _pageController.dispose();

    _taxPercentageController.dispose();
    super.dispose();
  }

  void _calculateAmount() {
    if (_isFreeGood) {
      _amountController.text = "0.00";
      return;
    }
    final double quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final double unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;
    final double amount = (quantity * unitPrice);
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
    _isFreeGood = false;
    _isTradeReturn = false;
    _tradeReturnGood = true;
    _calculateAmount();
  }

  void _addItemToOrder() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedApiProduct == null) {
      showVDialog(title: "Validation Error", text: "Please select a product.");
      return;
    }
    final double quantity = double.tryParse(_quantityController.text) ?? 0.0;
    if (quantity <= 0 && !_isFreeGood) {
      showVDialog(title: "Validation Error", text: "Quantity must be > 0 unless free good.");
      return;
    }
    final double unitPrice = _isFreeGood ? 0.0 : (double.tryParse(_unitPriceController.text) ?? 0.0);
    if (!_isFreeGood && unitPrice <= 0) {
      showVDialog(title: "Validation Error", text: "Unit price must be > 0 for non-free goods.");
      return;
    }

    final confirmed = await showConfirmationDialog(context: context);
    if (!confirmed) return;

    var body = {
      "order_id": _order!.id,
      "product_id": _selectedApiProduct!.id.toString(),
      "quantity": quantity,
      "unit_price": unitPrice,
    };

    try {
      final Map<String, dynamic>? response = await _api.createOrderItem(body);
      setState(() {
        _isLoading = false;
      });

      if (response != null) {
        bool hasErrorFlag = response['error'] == 1 || response['error'] == true;
        int responseStatus = response['status'] as int? ?? 0;

        if (!hasErrorFlag && (responseStatus >= 200 && responseStatus < 300)) {
          await showVDialog(title: "Success", text: response['message'] ?? "Success");
          _fetchOrder();
        } else {
          String errorMessage = response['message']?.toString() ?? 'Failed to create order.';
          if (responseStatus == 422 && response['data'] is Map && response['data']['errors'] is Map) {
            Map<String, dynamic> validationErrors = response['data']['errors'];
            StringBuffer errorsBuffer = StringBuffer(errorMessage + "\n");
            validationErrors.forEach((field, messages) {
              if (messages is List && messages.isNotEmpty) errorsBuffer.writeln("- $field: ${messages.join(', ')}");
            });
            errorMessage = errorsBuffer.toString().trim();
          }
          showVDialog(title: "Order Submission Failed (Status: $responseStatus)", text: errorMessage);
        }
      } else {
        showVDialog(title: "Error", text: "No response from server.");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showVDialog(title: "Application Error", text: "An error occurred: ${e.toString()}");
    }

    // setState(() {
    //   _currentOrderItems.add(
    //     OrderItem(
    //       productId: _selectedApiProduct!.id.toString(), // API expects integer product ID
    //       productName: _selectedApiProduct!.productName,
    //       skuCode: 'N/A', // SKU not available from this simplified product API
    //       quantity: quantity,
    //       unitPrice: unitPrice,
    //       isFreeGood: _isFreeGood,
    //       isTradeReturn: _isTradeReturn,
    //       tradeReturnIsGood: _isTradeReturn ? _tradeReturnGood : true,
    //     ),
    //   );
    //   _resetProductDetails();
    //   _quantityController.text = "1";
    // });
    setState(() {
      _isLoading = false;
    });
  }

  _deleteOrderItem(OrderItem item) async {
    if (item.id == null) return;

    final confirmed = await showConfirmationDialog(context: context);
    if (!confirmed) return;

    try {
      final Map<String, dynamic>? response = await _api.deleteOrderItem(item.id ?? '');
      setState(() {
        _isLoading = false;
      });

      if (response != null) {
        bool hasErrorFlag = response['error'] == 1 || response['error'] == true;
        int responseStatus = response['status'] as int? ?? 0;

        if (!hasErrorFlag && (responseStatus >= 200 && responseStatus < 300)) {
          await showVDialog(title: "Success", text: response['message'] ?? "Success");
          _fetchOrder();
        } else {
          String errorMessage = response['message']?.toString() ?? 'Failed to create order.';
          if (responseStatus == 422 && response['data'] is Map && response['data']['errors'] is Map) {
            Map<String, dynamic> validationErrors = response['data']['errors'];
            StringBuffer errorsBuffer = StringBuffer(errorMessage + "\n");
            validationErrors.forEach((field, messages) {
              if (messages is List && messages.isNotEmpty) errorsBuffer.writeln("- $field: ${messages.join(', ')}");
            });
            errorMessage = errorsBuffer.toString().trim();
          }
          showVDialog(title: "Order Submission Failed (Status: $responseStatus)", text: errorMessage);
        }
      } else {
        showVDialog(title: "Error", text: "No response from server.");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showVDialog(title: "Application Error", text: "An error occurred: ${e.toString()}");
    }
  }

  double get _totalOrderAmount => _currentOrderItems.fold(0.0, (sum, item) => sum + (item.amount ?? 0));

  Future<void> _submitOrder() async {
    if (_selectedCustomer == null || _selectedCustomer!.id == 0) {
      showVDialog(title: "Validation Error", text: "Please select a valid customer.");
      return;
    }

    final confirmed = await showConfirmationDialog(context: context);

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    GlobalState gs = Get.find();

    Order orderToSubmit;
    if (_isEditMode) {
      orderToSubmit = Order(
        id: _order?.id,
        customerId: _selectedCustomer!.id.toString(), // Use the integer ID, converted to string for the model
        customerName: _selectedCustomer!.companyName ?? _selectedCustomer!.name ?? 'N/A',
        orderDate: parseDateFromString(_orderDateController.text),
        remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
        discount: double.tryParse(_discountController.text),
        tax1Percentage: double.tryParse(_taxPercentageController.text),
      );
    } else {
      orderToSubmit = Order(
        branchId: gs.selectedBranch,
        customerId: _selectedCustomer!.id.toString(), // Use the integer ID, converted to string for the model
        customerName: _selectedCustomer!.companyName ?? _selectedCustomer!.name ?? 'N/A',
        orderDate: parseDateFromString(_orderDateController.text),
        remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
        status: 'pending',
        discount: double.tryParse(_discountController.text),
        tax1Percentage: double.tryParse(_taxPercentageController.text),
      );
    }

    try {
      final Map<String, dynamic>? response;
      if (_isEditMode) {
        aLog(orderToSubmit.toJson());
        response = await _api.updateOrder(orderToSubmit.toJson());
      } else {
        response = await _api.createOrder(orderToSubmit.toJson());
      }

      setState(() {
        _isLoading = false;
      });

      if (response != null) {
        bool hasErrorFlag = response['error'] == 1 || response['error'] == true;
        int responseStatus = response['status'] as int? ?? 0;

        if (!hasErrorFlag && (responseStatus >= 200 && responseStatus < 300)) {
          await showVDialog(title: "Success", text: response['message'] ?? "Success");
          if (_isEditMode) {
            await _fetchOrder();
          } else {
            Order order = Order.fromJson((response['data']));
            Get.back();
            Get.to(() => OrderFormPage(order: order));
          }
        } else {
          String errorMessage = response['message']?.toString() ?? 'Failed to create order.';
          if (responseStatus == 422 && response['data'] is Map && response['data']['errors'] is Map) {
            Map<String, dynamic> validationErrors = response['data']['errors'];
            StringBuffer errorsBuffer = StringBuffer(errorMessage + "\n");
            validationErrors.forEach((field, messages) {
              if (messages is List && messages.isNotEmpty) errorsBuffer.writeln("- $field: ${messages.join(', ')}");
            });
            errorMessage = errorsBuffer.toString().trim();
          }
          showVDialog(title: "Order Submission Failed (Status: $responseStatus)", text: errorMessage);
        }
      } else {
        showVDialog(title: "Error", text: "No response from server.");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showVDialog(title: "Application Error", text: "An error occurred: ${e.toString()}");
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
                        subtitle: Text(customer.customerCode ?? 'ID: ${customer.id}'),
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
        _customerDisplayController.text = selected.name ?? selected.name ?? 'ID: ${selected.id}';
      });
    }
  }

  void _onTabTapped(int index) {
    if (index == 1 && !_isEditMode) {
      showVDialog(title: 'Warning', text: 'Create Order first');
      return;
    }
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Order #' + (_order!.id ?? '') : 'Create Order'),
        // actions: [
        //   if (_isEditMode)
        //     _isLoading
        //         ? const Padding(
        //           padding: EdgeInsets.all(16.0),
        //           child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)),
        //         )
        //         : IconButton(
        //           icon: const Icon(Icons.save_alt_outlined),
        //           onPressed: _submitOrder,
        //           tooltip: 'Save Changes',
        //         ),
        // ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Hides the keyboard
        },
        behavior: HitTestBehavior.opaque, // Ensures taps on empty space are detected

        child: Form(
          key: _formKey,
          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [_buildOrderInfoTab(), _buildOrderItemsTab()],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.info_outline),
            activeIcon: const Icon(Icons.info),
            label: 'Order Info',
          ),
          BottomNavigationBarItem(
            icon: Badge(label: Text('${_currentOrderItems.length}'), child: const Icon(Icons.shopping_cart_outlined)),
            activeIcon: Badge(label: Text('${_currentOrderItems.length}'), child: const Icon(Icons.shopping_cart)),
            label: 'Order Items',
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
        onPressed: _submitOrder,
        // icon: const Icon(Icons.check_circle_outline),
        label: Text(_isEditMode ? 'Update Order' : 'Create Order'),
      );
    } else if (_currentIndex == 1) {
      return FloatingActionButton.extended(
        onPressed: () => _showProductModalSheet(context),
        icon: const Icon(Icons.add),
        label: Text('Add Items'),
      );

      /*
     ElevatedButton.icon(
                    onPressed: () => _showProductModalSheet(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add More'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
     */
    }
    return SizedBox();
  }

  Widget _buildOrderInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Customer Selection Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildTextFormField(
                    _referenceNoController,
                    'Reference No',
                    FontAwesomeIcons.file,
                    TextInputType.text,
                    readOnly: true,
                    (v) {
                      if (v == null || v.isEmpty) return '';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _showCustomerSelectionDialog,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Customer *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_search_outlined),
                      ),
                      child: Text(
                        _customerDisplayController.text,
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedCustomer == null ? Colors.grey.shade700 : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTextFormField(
                    _orderDateController,
                    'Order Date',
                    Icons.calendar_today,
                    TextInputType.none,
                    (value) {
                      if (value == null || value.isEmpty) return 'Please select a date';
                      return null;
                    },
                    readOnly: true,
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedOrderDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );

                      if (picked != null) {
                        setState(() {
                          _selectedOrderDate = picked;
                          _orderDateController.text =
                              "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _remarksController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Remarks Section
          if (_isEditMode)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _buildTextFormField(
                      _taxPercentageController,
                      'Tax (%)',
                      FontAwesomeIcons.cubesStacked,
                      TextInputType.number,
                      (v) {
                        if (v == null || v.isEmpty) return '';
                        if (double.tryParse(v) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextFormField(
                      _discountController,
                      'Discount (RM)',
                      FontAwesomeIcons.cubesStacked,
                      TextInputType.number,
                      (v) {
                        if (v == null || v.isEmpty) return '';
                        if (double.tryParse(v) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          if (!_isEditMode) Center(child: Text('Create order first before can assign order items.')),

          // Summary Totals
          if (_isEditMode)
            Card(
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
                    _buildSummaryRow('Gross Amount', _order!.grossAmount),
                    _buildSummaryRow('Tax (${_order!.tax1Percentage}%)', _order!.tax1),
                    Divider(),
                    _buildSummaryRow('Grand Total', _order!.grandAmount, isBold: true),
                    _buildSummaryRow('Discount', _order!.discount),
                    Divider(),
                    _buildSummaryRow('Net Amount', _order!.netAmount, isBold: true),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsTab() {
    return Column(
      children: [
        // Order Summary Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Summary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentOrderItems.length} items',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_selectedCustomer != null)
                Text('${_order!.customerName ?? 'N/A'}', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Amount:', style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    '${_totalOrderAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Order Items List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _currentOrderItems.length,
            itemBuilder: (context, index) {
              final item = _currentOrderItems[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName ?? '',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'delete') {
                                await _deleteOrderItem(item);
                              }
                            },
                            itemBuilder:
                                (context) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Remove Item'),
                                      ],
                                    ),
                                  ),
                                ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Item Details
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Quantity:', style: Theme.of(context).textTheme.bodyMedium),
                                Text(
                                  item.quantity.toString(),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Unit Price:', style: Theme.of(context).textTheme.bodyMedium),
                                Text(
                                  '${item.unitPrice?.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Amount:',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${item.amount?.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Special Tags
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (item.isFreeGood ?? false)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: Text(
                                'Free Good',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (item.isTradeReturn ?? false)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade300),
                              ),
                              child: Text(
                                'Trade Return: ${(item.tradeReturnIsGood ?? false) ? "Good" : "Bad"}',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom Summary (always visible when items exist)
        if (_currentOrderItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, -2))],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total: ${_totalOrderAmount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_currentOrderItems.length} item${_currentOrderItems.length != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
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
                                  DropdownMenuItem<ApiProduct>(value: product, child: Text(product.productName)),
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
                  if (!_isFreeGood && (double.tryParse(v) ?? 0) <= 0) return 'Quantity > 0';
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
                  if (!_isFreeGood && price <= 0) return 'Price must be > 0 for non-free goods';
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
            ],
          ),

          Container(
            padding: EdgeInsets.all(5),
            alignment: Alignment.center,
            child: ElevatedButton(onPressed: _addItemToOrder, child: Text('Add To Order')),
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
}
