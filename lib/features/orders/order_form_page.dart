import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rempahapp/models/order.dart';
import 'package:rempahapp/models/order_item.dart';
import 'package:rempahapp/models/product.dart';

final List<Product> _allProducts = [
  Product(
    id: 'p1',
    name: 'Product A1',
    sku: 'SKU001',
    groupId: 'g1',
    subGroupId: 'sg1_1',
    price: 10.00,
  ),
  Product(
    id: 'p2',
    name: 'Product A2',
    sku: 'SKU002',
    groupId: 'g1',
    subGroupId: 'sg1_1',
    price: 12.50,
  ),
  Product(
    id: 'p3',
    name: 'Product B1',
    sku: 'SKU003',
    groupId: 'g1',
    subGroupId: 'sg1_2',
    price: 15.00,
  ),
  Product(
    id: 'p4',
    name: 'Product C1',
    sku: 'SKU004',
    groupId: 'g2',
    subGroupId: 'sg2_1',
    price: 20.00,
  ),
  Product(
    id: 'p5',
    name: 'Product C2',
    sku: 'SKU005',
    groupId: 'g2',
    subGroupId: 'sg2_1',
    price: 22.00,
  ),
];

final Map<String, String> _groups = {'g1': 'Group A', 'g2': 'Group B'};
final Map<String, String> _subGroups = {
  'sg1_1': 'Sub Group A1',
  'sg1_2': 'Sub Group A2',
  'sg2_1': 'Sub Group C1',
};
// Dependencies: Group -> SubGroups
final Map<String, List<String>> _groupSubGroupMap = {
  'g1': ['sg1_1', 'sg1_2'],
  'g2': ['sg2_1'],
};
// Dependencies: SubGroup -> Products
final Map<String, List<String>> _subGroupProductMap = {
  'sg1_1': ['p1', 'p2'],
  'sg1_2': ['p3'],
  'sg2_1': ['p4', 'p5'],
};

class OrderFormPage extends StatefulWidget {
  const OrderFormPage({super.key});

  @override
  State<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  final _formKey = GlobalKey<FormState>();

  // --- Form State Variables ---
  TextEditingController _customerController = TextEditingController(
    text: "AHS3185 S02 KANESAN",
  ); // Pre-filled
  String? _selectedGroupId;
  String? _selectedSubGroupId;
  String? _selectedProductId;

  TextEditingController _quantityController = TextEditingController(text: "0");
  bool _isFreeGood = false;
  bool _isTradeReturn = false;
  bool _tradeReturnGood = true; // Default to 'Good' for trade return
  TextEditingController _unitPriceController = TextEditingController(
    text: "0.00",
  );
  TextEditingController _amountController = TextEditingController(
    text: "0.00",
  ); // Calculated
  TextEditingController _discountController = TextEditingController(
    text: "0.00",
  );

  List<OrderItem> _currentOrderItems = [];

  // --- Dependent Dropdown Logic ---
  List<String> _availableSubGroupIds = [];
  List<String> _availableProductIds = [];

  @override
  void initState() {
    super.initState();
    // Add listeners to update calculated fields
    _quantityController.addListener(_calculateAmount);
    _unitPriceController.addListener(_calculateAmount);
    _discountController.addListener(
      _calculateAmount,
    ); // If discount affects line item amount directly
    _isFreeGood = false; // Ensure it's reset
  }

  @override
  void dispose() {
    _customerController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _amountController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _calculateAmount() {
    if (_isFreeGood) {
      _amountController.text = "0.00";
      _unitPriceController.text = "0.00"; // Free goods have no price
      return;
    }
    final double quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final double unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;
    // Assuming discount is a fixed value for simplicity in this calculation
    final double discount = double.tryParse(_discountController.text) ?? 0.0;
    final double amount = (quantity * unitPrice) - discount;
    _amountController.text = amount.toStringAsFixed(2);
  }

  void _onGroupChanged(String? groupId) {
    setState(() {
      _selectedGroupId = groupId;
      _selectedSubGroupId = null;
      _selectedProductId = null;
      _unitPriceController.text = "0.00";
      _availableSubGroupIds =
          (groupId != null && _groupSubGroupMap.containsKey(groupId))
              ? _groupSubGroupMap[groupId]!
              : [];
      _availableProductIds = [];
      _resetProductDetails();
    });
  }

  void _onSubGroupChanged(String? subGroupId) {
    setState(() {
      _selectedSubGroupId = subGroupId;
      _selectedProductId = null;
      _unitPriceController.text = "0.00";
      _availableProductIds =
          (subGroupId != null && _subGroupProductMap.containsKey(subGroupId))
              ? _subGroupProductMap[subGroupId]!
              : [];
      _resetProductDetails();
    });
  }

  void _onProductChanged(String? productId) {
    setState(() {
      _selectedProductId = productId;
      if (productId != null) {
        final product = _allProducts.firstWhere((p) => p.id == productId);
        _unitPriceController.text =
            _isFreeGood ? "0.00" : product.price.toStringAsFixed(2);
      } else {
        _resetProductDetails();
      }
      _calculateAmount(); // Recalculate amount when product changes
    });
  }

  void _resetProductDetails() {
    _unitPriceController.text = "0.00";
    _quantityController.text = "0";
    _discountController.text = "0.00";
    _isFreeGood = false;
    _isTradeReturn = false;
    _tradeReturnGood = true;
    _calculateAmount();
  }

  void _addItemToOrder() {
    if (_formKey.currentState!.validate()) {
      if (_selectedProductId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a product.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      final double quantity = double.tryParse(_quantityController.text) ?? 0.0;
      if (quantity <= 0 && !_isFreeGood) {
        // Allow 0 quantity if it's a free good placeholder or specific scenario
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quantity must be greater than 0.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final product = _allProducts.firstWhere(
        (p) => p.id == _selectedProductId!,
      );
      final unitPrice =
          _isFreeGood
              ? 0.0
              : (double.tryParse(_unitPriceController.text) ?? product.price);

      setState(() {
        _currentOrderItems.add(
          OrderItem(
            productId: product.id,
            productName: product.name,
            skuCode: product.sku,
            quantity: quantity,
            unitPrice: unitPrice,
            discount: double.tryParse(_discountController.text) ?? 0.0,
            isFreeGood: _isFreeGood,
            isTradeReturn: _isTradeReturn,
            tradeReturnIsGood: _isTradeReturn ? _tradeReturnGood : true,
          ),
        );

        // Reset fields for next item
        _selectedProductId = null; // Keep group/subgroup or reset as needed
        _quantityController.text = "0";
        _discountController.text = "0.00";
        _unitPriceController.text = "0.00";
        _amountController.text = "0.00";
        _isFreeGood = false;
        _isTradeReturn = false;
        _tradeReturnGood = true;
        // Consider resetting _selectedGroupId and _selectedSubGroupId as well if desired
        // _selectedGroupId = null;
        // _selectedSubGroupId = null;
        // _availableSubGroupIds = [];
        // _availableProductIds = [];
      });
    }
  }

  void _cancelItemEntry() {
    setState(() {
      _selectedGroupId = null;
      _selectedSubGroupId = null;
      _selectedProductId = null;
      _availableSubGroupIds = [];
      _availableProductIds = [];
      _resetProductDetails();
    });
  }

  double get _totalOrderAmount {
    return _currentOrderItems.fold(0.0, (sum, item) => sum + item.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Order'),
        // backgroundColor: Theme.of(context).primaryColor, // Example
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Customer
              TextFormField(
                controller: _customerController,
                decoration: const InputDecoration(
                  labelText: 'Customer',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                // readOnly: true, // If customer is selected elsewhere
                validator:
                    (value) =>
                        (value == null || value.isEmpty)
                            ? 'Please enter customer'
                            : null,
              ),
              const SizedBox(height: 12),

              // Group Dropdown
              DropdownButtonFormField<String>(
                value: _selectedGroupId,
                decoration: const InputDecoration(
                  labelText: 'Group',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.layerGroup),
                ),
                items:
                    _groups.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                onChanged: _onGroupChanged,
                validator:
                    (value) => value == null ? 'Please select a group' : null,
              ),
              const SizedBox(height: 12),

              // Sub Group Dropdown
              DropdownButtonFormField<String>(
                value: _selectedSubGroupId,
                decoration: const InputDecoration(
                  labelText: 'Sub Group',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.objectUngroup),
                ),
                items:
                    _availableSubGroupIds.map((subGroupId) {
                      return DropdownMenuItem<String>(
                        value: subGroupId,
                        child: Text(_subGroups[subGroupId] ?? 'Unknown'),
                      );
                    }).toList(),
                onChanged: _onSubGroupChanged,
                validator:
                    (value) =>
                        _selectedGroupId != null && value == null
                            ? 'Please select a sub group'
                            : null,
                disabledHint:
                    _selectedGroupId == null
                        ? const Text("Select Group First")
                        : null,
              ),
              const SizedBox(height: 12),

              // Product Dropdown
              DropdownButtonFormField<String>(
                value: _selectedProductId,
                decoration: const InputDecoration(
                  labelText: 'Product',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.box),
                ),
                items:
                    _availableProductIds.map((productId) {
                      final product = _allProducts.firstWhere(
                        (p) => p.id == productId,
                      );
                      return DropdownMenuItem<String>(
                        value: productId,
                        child: Text(product.name),
                      );
                    }).toList(),
                onChanged: _onProductChanged,
                validator:
                    (value) =>
                        _selectedSubGroupId != null && value == null
                            ? 'Please select a product'
                            : null,
                disabledHint:
                    _selectedSubGroupId == null
                        ? const Text("Select Sub Group First")
                        : null,
              ),
              const SizedBox(height: 12),

              // Quantity
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.cubesStacked),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter quantity';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  if (!_isFreeGood && (double.tryParse(value) ?? 0) <= 0)
                    return 'Quantity > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Free Goods Checkbox
              CheckboxListTile(
                title: const Text("Free Goods"),
                value: _isFreeGood,
                onChanged: (bool? value) {
                  setState(() {
                    _isFreeGood = value ?? false;
                    if (_isFreeGood) {
                      _isTradeReturn =
                          false; // Cannot be both free and trade return
                      _unitPriceController.text =
                          "0.00"; // Free goods have no price
                    } else if (_selectedProductId != null) {
                      // Restore price if unchecked and product selected
                      final product = _allProducts.firstWhere(
                        (p) => p.id == _selectedProductId!,
                      );
                      _unitPriceController.text = product.price.toStringAsFixed(
                        2,
                      );
                    }
                    _calculateAmount();
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 0),

              // Trade Return Checkboxes
              CheckboxListTile(
                title: const Text("Trade Return"),
                value: _isTradeReturn,
                onChanged: (bool? value) {
                  setState(() {
                    _isTradeReturn = value ?? false;
                    if (_isTradeReturn) {
                      _isFreeGood =
                          false; // Cannot be both free and trade return
                    }
                    _calculateAmount(); // Recalculate if needed
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Theme.of(context).primaryColor,
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
                        onSelected: (selected) {
                          setState(() => _tradeReturnGood = true);
                        },
                        selectedColor: Colors.green.shade100,
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Bad'),
                        selected: !_tradeReturnGood,
                        onSelected: (selected) {
                          setState(() => _tradeReturnGood = false);
                        },
                        selectedColor: Colors.red.shade100,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Unit Price
              TextFormField(
                controller: _unitPriceController,
                decoration: const InputDecoration(
                  labelText: 'Unit Price',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.dollarSign),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                readOnly: _isFreeGood, // Price is 0 if free good
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter unit price';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Amount (Calculated)
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.moneyBillWave),
                ),
                readOnly: true,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Discount
              TextFormField(
                controller: _discountController,
                decoration: const InputDecoration(
                  labelText: 'Discount',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.tags),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Enter discount (0 if none)';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Add / Cancel Buttons
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

              // --- List of Added Items ---
              Text(
                'Order Items:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              _currentOrderItems.isEmpty
                  ? const Center(child: Text('No items added yet.'))
                  : ListView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(), // To use inside SingleChildScrollView
                    itemCount: _currentOrderItems.length,
                    itemBuilder: (context, index) {
                      final item = _currentOrderItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(item.skuCode.substring(0, 1)),
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
                                  'Disc: ${item.discountValue.toStringAsFixed(2)}',
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
                          // Add an option to remove or edit item if needed
                          onLongPress: () {
                            setState(() {
                              _currentOrderItems.removeAt(index);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${item.productName} removed'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
              const SizedBox(height: 16),
              // --- Total Amount ---
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
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Submit Order'),
                onPressed: () {
                  if (_currentOrderItems.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please add items to the order first.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  // TODO: Implement order submission logic
                  final orderToSubmit = Order(
                    customerId:
                        _customerController.text.split(
                          " ",
                        )[0], // Assuming ID is first part
                    customerName: _customerController.text, // Full name
                    items: _currentOrderItems,
                    orderDate: DateTime.now(),
                  );
                  print('Submitting Order:');
                  print('Customer: ${orderToSubmit.customerName}');
                  print('Total: ${orderToSubmit.totalAmount}');
                  orderToSubmit.items.forEach(
                    (item) => print(
                      '  - ${item.productName}: ${item.quantity} @ ${item.unitPrice}',
                    ),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Order submitted for ${orderToSubmit.customerName}!',
                      ),
                      backgroundColor: Colors.teal,
                    ),
                  );
                  // Potentially navigate away or clear the form
                },
                style: ElevatedButton.styleFrom(
                  // backgroundColor: Theme.of(context).primaryColor,
                  // foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
