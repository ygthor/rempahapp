import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rempahapp/models/customer.dart';

class CustomerFormPage extends StatefulWidget {
  final Customer?
  customer; // Optional: Pass a customer to pre-fill the form for editing

  const CustomerFormPage({super.key, this.customer});

  @override
  State<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>(); // Key to manage the Form state

  // Controllers for each text field
  late TextEditingController
  _customerCodeController; // Renamed from _nameController
  late TextEditingController _companyNameController;
  late TextEditingController _addressController;
  late TextEditingController _paymentTermController;
  late TextEditingController _maxDiscountController;

  // Controllers for fields that were in your original code but not in the new form structure.
  // Add TextFormFields for these if they are still needed.
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _avatarUrlController;

  // State variables for dropdowns
  String? _selectedCustomerType;
  String? _selectedSegment;
  String? _selectedPaymentType;

  // Item lists for dropdowns
  final List<String> _customerTypeOptions = [
    'Wholesale',
    'Retail',
    'Corporate',
    'Online',
  ];
  final List<String> _segmentOptions = [
    'Premium',
    'Mid-Range',
    'Budget',
    'Niche',
  ];
  final List<String> _paymentTypeOptions = [
    'Cash on Delivery (COD)',
    'Bank Transfer',
    'Credit Card',
    'E-Wallet',
  ];
  // The _cities list from your code, you might want to rename or repurpose it if it's for a different field.
  // For now, I'll assume it's not used by the new dropdowns.
  // final List<String> _cities = [
  //   'New York',
  //   'London',
  //   'Paris',
  //   'Tokyo',
  //   'Kuala Lumpur',
  //   'Singapore',
  //   'Bayan Lepas',
  // ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers, pre-filling if a customer is provided (for editing)
    _customerCodeController = TextEditingController(
      text: widget.customer?.customerCode ?? '',
    );
    _companyNameController = TextEditingController(
      text: widget.customer?.companyName ?? '',
    );
    _addressController = TextEditingController(
      text: widget.customer?.address ?? '',
    );
    _paymentTermController = TextEditingController(
      text: widget.customer?.paymentTerm ?? '',
    );
    _maxDiscountController = TextEditingController(
      text: widget.customer?.maxDiscount ?? '',
    );

    // Initialize controllers for other fields (if you add them back to the form)
    _emailController = TextEditingController(
      text: widget.customer?.email ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.customer?.phone ?? '',
    );
    _avatarUrlController = TextEditingController(
      text: widget.customer?.avatarUrl ?? '',
    );

    // Initialize selected values for dropdowns if a customer is provided
    if (widget.customer != null) {
      if (widget.customer!.customerType != null &&
          _customerTypeOptions.contains(widget.customer!.customerType)) {
        _selectedCustomerType = widget.customer!.customerType;
      }
      if (widget.customer!.segment != null &&
          _segmentOptions.contains(widget.customer!.segment)) {
        _selectedSegment = widget.customer!.segment;
      }
      if (widget.customer!.paymentType != null &&
          _paymentTypeOptions.contains(widget.customer!.paymentType)) {
        _selectedPaymentType = widget.customer!.paymentType;
      }
    }
  }

  @override
  void dispose() {
    // Dispose controllers when the widget is removed from the widget tree
    _customerCodeController.dispose();
    _companyNameController.dispose();
    _addressController.dispose();
    _paymentTermController.dispose();
    _maxDiscountController.dispose();

    _emailController.dispose();
    _phoneController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  void _saveForm() {
    // Validate the form
    if (_formKey.currentState!.validate()) {
      // If the form is valid, proceed with saving the data
      _formKey.currentState!.save(); // Calls onSaved for each TextFormField

      final newCustomer = Customer(
        id: widget.customer?.id, // Keep existing ID if editing
        customerCode: _customerCodeController.text,
        companyName: _companyNameController.text,
        address: _addressController.text,
        customerType: _selectedCustomerType,
        segment: _selectedSegment,
        paymentType: _selectedPaymentType,
        paymentTerm: _paymentTermController.text,
        maxDiscount: _maxDiscountController.text,
        // Include other fields if you add them back to the form
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        avatarUrl:
            _avatarUrlController.text.isNotEmpty
                ? _avatarUrlController.text
                : null,
      );

      // TODO: Implement your save logic here
      // For example, call an API, update a database, or update your state management solution
      print('Saving customer:');
      print('Customer Code: ${newCustomer.customerCode}');
      print('Company Name: ${newCustomer.companyName}');
      print('Address: ${newCustomer.address}');
      print('Customer Type: ${newCustomer.customerType}');
      print('Segment: ${newCustomer.segment}');
      print('Payment Type: ${newCustomer.paymentType}');
      print('Payment Term: ${newCustomer.paymentTerm}');
      print('Max Discount: ${newCustomer.maxDiscount}');
      print('Email: ${newCustomer.email}');
      print('Phone: ${newCustomer.phone}');
      print('Avatar URL: ${newCustomer.avatarUrl}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.customer == null ? 'Customer Created!' : 'Customer Updated!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Optionally, pop the page after saving
      if (Navigator.canPop(context)) {
        Navigator.pop(
          context,
          newCustomer,
        ); // Pass the new/updated customer back
      }
    } else {
      // If form is not valid, show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the errors in the form.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Validator for common fields
  String? _validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName cannot be empty.';
    }
    return null;
  }

  // Validator for dropdowns
  String? _validateDropdownSelection(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please select a $fieldName.';
    }
    return null;
  }

  // Email and Phone validators from your original code (if you add these fields back)
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email cannot be empty.';
    }
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number cannot be empty.';
    }
    final phoneRegex = RegExp(r"^[0-9\s-]{7,}$");
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number (at least 7 digits).';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.customer == null ? 'Add New Customer' : 'Edit Customer',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt_outlined),
            tooltip: 'Save Customer',
            onPressed: _saveForm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Customer Code Field
              TextFormField(
                controller: _customerCodeController,
                decoration: InputDecoration(
                  labelText: 'Customer Code',
                  hintText: 'Enter customer\'s code',
                  prefixIcon: const Icon(
                    Icons.person_outline,
                  ), // Changed from Icons.person_outline
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                validator: (value) => _validateNotEmpty(value, 'Customer Code'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20.0),

              // Company Name Field
              TextFormField(
                controller: _companyNameController, // Assign controller
                decoration: InputDecoration(
                  labelText: 'Company Name',
                  hintText: 'Enter company\'s name',
                  prefixIcon: const Icon(Icons.villa),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                validator: (value) => _validateNotEmpty(value, 'Company Name'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20.0),

              // Address Field
              TextFormField(
                controller: _addressController, // Assign controller
                decoration: InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter address',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  alignLabelWithHint: true,
                ),
                keyboardType: TextInputType.multiline,
                minLines: 3,
                maxLines: null,
                validator:
                    (value) =>
                        _validateNotEmpty(value, 'Address'), // Added validator
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20.0),

              // Customer Type Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Customer Type',
                  hintText: 'Select customer\'s type',
                  prefixIcon: const Icon(FontAwesomeIcons.userGear),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                value: _selectedCustomerType,
                items:
                    _customerTypeOptions.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCustomerType = newValue;
                  });
                },
                validator:
                    (value) =>
                        _validateDropdownSelection(value, 'Customer Type'),
              ),
              const SizedBox(height: 20.0),

              // Segment Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Segment',
                  hintText: 'Select segment',
                  prefixIcon: const Icon(FontAwesomeIcons.chartPie),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                value: _selectedSegment,
                items:
                    _segmentOptions.map((String segment) {
                      // Use _segmentOptions
                      return DropdownMenuItem<String>(
                        value: segment,
                        child: Text(segment),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSegment = newValue;
                  });
                },
                validator:
                    (value) => _validateDropdownSelection(value, 'Segment'),
              ),
              const SizedBox(height: 20.0),

              // Payment Type Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Payment Type',
                  hintText: 'Select payment\'s type',
                  prefixIcon: const Icon(FontAwesomeIcons.handHoldingDollar),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                value: _selectedPaymentType,
                items:
                    _paymentTypeOptions.map((String type) {
                      // Use _paymentTypeOptions
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPaymentType = newValue;
                  });
                },
                validator:
                    (value) =>
                        _validateDropdownSelection(value, 'Payment Type'),
              ),
              const SizedBox(height: 20.0),

              // Payment Term Field
              TextFormField(
                controller: _paymentTermController, // Assign controller
                decoration: InputDecoration(
                  labelText: 'Payment Term',
                  hintText: 'Enter Payment Term (e.g., 30 days)',
                  prefixIcon: const Icon(FontAwesomeIcons.fileInvoice),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                validator:
                    (value) => _validateNotEmpty(
                      value,
                      'Payment Term',
                    ), // Added validator
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20.0),

              // Max Discount Field
              TextFormField(
                controller: _maxDiscountController, // Assign controller
                decoration: InputDecoration(
                  labelText: 'Max Discount (%)',
                  hintText: 'Enter Max Discount (e.g., 10)',
                  prefixIcon: const Icon(FontAwesomeIcons.moneyCheckDollar),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(
                  decimal: true,
                ), // Suggest number keyboard
                validator:
                    (value) => _validateNotEmpty(
                      value,
                      'Max Discount',
                    ), // Added validator
                textInputAction:
                    TextInputAction
                        .done, // Changed to done as it's the last new field
              ),
              const SizedBox(height: 30.0),

              // Save Button
              ElevatedButton.icon(
                icon: const Icon(Icons.save_alt_outlined),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    widget.customer == null
                        ? 'Create Customer'
                        : 'Save Changes',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                onPressed: _saveForm,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 3.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
