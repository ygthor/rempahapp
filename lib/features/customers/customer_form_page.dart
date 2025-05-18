import 'package:flutter/material.dart';
import 'package:get/get.dart';
// Assuming ApiV1, Customer, and GlobalState are in these paths. Adjust if necessary.
import 'package:rempahapp/api/api_v1.dart';
import 'package:rempahapp/models/customer.dart';
import 'package:rempahapp/models/global_state.dart';

// CustomerFormPage widget - the main page for the form (ENHANCED WITH API)
class CustomerFormPage extends StatefulWidget {
  final Customer? customer; // Optional: Pass a customer to pre-fill for editing

  const CustomerFormPage({super.key, this.customer});

  @override
  _CustomerFormPageState createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  late ApiV1 _api;
  bool _isLoading = false; // For loading state during API calls

  // Controllers for text fields
  // These match the fields in your original CustomerFormPage
  final TextEditingController _customerCodeController = TextEditingController();
  final TextEditingController _companyController =
      TextEditingController(); // Maps to company_name
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _territoryController = TextEditingController();
  final TextEditingController _telephone1Controller = TextEditingController();
  final TextEditingController _telephone2Controller = TextEditingController();
  final TextEditingController _faxNoController = TextEditingController();
  final TextEditingController _contactPersonController =
      TextEditingController(); // Was _contact1Controller
  final TextEditingController _customerGroupController =
      TextEditingController();
  final TextEditingController _customerTypeController = TextEditingController();
  final TextEditingController _lotTypeController = TextEditingController();

  // Additional controllers for fields from the more detailed Customer model (if needed)
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController =
      TextEditingController(); // General phone, might map to telephone1
  final TextEditingController _paymentTermController = TextEditingController();
  final TextEditingController _maxDiscountController = TextEditingController();
  // Note: segment and payment_type were dropdowns in CustomerDetailPage,
  // this form currently uses TextFields. Adapt if dropdowns are needed.
  final TextEditingController _segmentController = TextEditingController();
  final TextEditingController _paymentTypeDetailController =
      TextEditingController(); // Renamed to avoid conflict

  bool get _isEditMode => widget.customer != null;

  @override
  void initState() {
    super.initState();
    GlobalState gs = Get.find<GlobalState>();
    _api = ApiV1(bearerToken: gs.token);

    if (_isEditMode && widget.customer != null) {
      // Populate fields if editing an existing customer
      _customerCodeController.text = widget.customer!.customerCode ?? '';
      _companyController.text =
          widget.customer!.companyName ??
          ''; // Assuming companyController maps to companyName
      _address1Controller.text = widget.customer!.address1 ?? '';
      _address2Controller.text = widget.customer!.address2 ?? '';
      _postcodeController.text = widget.customer!.postcode ?? '';
      _stateController.text = widget.customer!.state ?? '';
      _territoryController.text =
          widget.customer!.territory ?? 'ALMA'; // Default if null
      _telephone1Controller.text = widget.customer!.telephone1 ?? '';
      _telephone2Controller.text = widget.customer!.telephone2 ?? '';
      _faxNoController.text = widget.customer!.faxNo ?? '';
      _contactPersonController.text = widget.customer!.contactPerson ?? '';
      _customerGroupController.text =
          widget.customer!.customerGroup ?? 'RESTAURANT'; // Default if null
      _customerTypeController.text =
          widget.customer!.customerType ?? 'KEYACC'; // Default if null
      _lotTypeController.text =
          widget.customer!.lotType ?? 'COR'; // Default if null

      // Populate additional fields
      _emailController.text = widget.customer!.email ?? '';
      _phoneController.text =
          widget.customer!.phone ??
          widget.customer!.telephone1 ??
          ''; // Fallback to telephone1
      _paymentTermController.text = widget.customer!.paymentTerm ?? '';
      _maxDiscountController.text = widget.customer!.maxDiscount ?? '';
      _segmentController.text = widget.customer!.segment ?? '';
      _paymentTypeDetailController.text = widget.customer!.paymentType ?? '';
    } else {
      // Set default initial values for add mode if any (already done in controller declaration for some)
      _territoryController.text = 'ALMA';
      _customerGroupController.text = 'RESTAURANT';
      _customerTypeController.text = 'KEYACC';
      _lotTypeController.text = 'COR';
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _customerCodeController.dispose();
    _companyController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _postcodeController.dispose();
    _stateController.dispose();
    _territoryController.dispose();
    _telephone1Controller.dispose();
    _telephone2Controller.dispose();
    _faxNoController.dispose();
    _contactPersonController.dispose();
    _customerGroupController.dispose();
    _customerTypeController.dispose();
    _lotTypeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _paymentTermController.dispose();
    _maxDiscountController.dispose();
    _segmentController.dispose();
    _paymentTypeDetailController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the errors in the form.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });

    // Prepare data for API
    // Ensure keys match what your Laravel API expects (e.g., snake_case)
    // The Customer.toJson() method should handle this if defined correctly.
    Map<String, dynamic> customerData = {
      'customer_code': _customerCodeController.text,
      'company_name': _companyController.text, // Mapped from _companyController
      'address1': _address1Controller.text,
      'address2':
          _address2Controller.text.isEmpty ? null : _address2Controller.text,
      'postcode':
          _postcodeController.text.isEmpty ? null : _postcodeController.text,
      'state': _stateController.text.isEmpty ? null : _stateController.text,
      'territory': _territoryController.text,
      'telephone1':
          _telephone1Controller.text.isEmpty
              ? null
              : _telephone1Controller.text,
      'telephone2':
          _telephone2Controller.text.isEmpty
              ? null
              : _telephone2Controller.text,
      'fax_no': _faxNoController.text.isEmpty ? null : _faxNoController.text,
      'contact_person':
          _contactPersonController.text.isEmpty
              ? null
              : _contactPersonController.text,
      'customer_group': _customerGroupController.text,
      'customer_type':
          _customerTypeController
              .text, // This field is from the "original" form
      'lot_type': _lotTypeController.text,
      // Fields from the "detailed" form structure
      'email': _emailController.text.isEmpty ? null : _emailController.text,
      'phone':
          _phoneController.text.isEmpty
              ? null
              : _phoneController.text, // General phone
      'payment_term':
          _paymentTermController.text.isEmpty
              ? null
              : _paymentTermController.text,
      'max_discount':
          _maxDiscountController.text.isEmpty
              ? null
              : _maxDiscountController.text,
      'segment':
          _segmentController.text.isEmpty ? null : _segmentController.text,
      'payment_type':
          _paymentTypeDetailController.text.isEmpty
              ? null
              : _paymentTypeDetailController.text,
      // 'name' and 'address' (general fields from Customer model) are not explicitly in this form's controllers.
      // If they need to be sent, you might need to add controllers or derive them.
    };

    Map<String, dynamic>? response;

    try {
      if (_isEditMode && widget.customer?.id != null) {
        // Update existing customer
        response = await _api.updateCustomer(
          widget.customer!.id!,
          customerData,
        );
      } else {
        // Create new customer
        response = await _api.createCustomer(customerData);
      }

      setState(() {
        _isLoading = false;
      });

      if (response != null &&
          (response['error'] != true && response['message'] != null)) {
        // The Laravel API returns a map like {'status': 200, 'message': '...', 'data': {...}}
        // So we check if response['data'] exists and is not null for success.
        // Or if the message indicates success.
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An application error occurred: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Apply theme settings from MyApp if available, otherwise use defaults
    final ThemeData theme = Theme.of(context);
    final inputDecorationTheme = theme.inputDecorationTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Customer' : 'Add New Customer'),
        // backgroundColor: theme.appBarTheme.backgroundColor ?? theme.primaryColor, // Use themed AppBar color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              // Customer Code field with a "New" button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextFormField(
                      controller: _customerCodeController,
                      labelText: 'Customer Code',
                      prefixIcon: Icons.qr_code_scanner_outlined,
                      textInputAction: TextInputAction.next,
                      decorationTheme: inputDecorationTheme,
                      readOnly:
                          _isEditMode, // Customer code might be non-editable in edit mode
                    ),
                  ),
                  if (!_isEditMode) ...[
                    // Show "New" button only in add mode
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(top: 0),
                      child: ElevatedButton(
                        onPressed: () {
                          // Logic for generating new customer code (simulated)
                          _customerCodeController.text =
                              "CUST-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'New Customer Code generated (simulated).',
                              ),
                            ),
                          );
                        },
                        child: const Text('New'),
                        style: theme.elevatedButtonTheme.style?.copyWith(
                          padding: MaterialStateProperty.all(
                            const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              _buildTextFormField(
                controller: _companyController,
                labelText: 'Company Name *',
                prefixIcon: Icons.business_outlined,
                textInputAction: TextInputAction.next,
                decorationTheme: inputDecorationTheme,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _address1Controller,
                labelText: 'Address 1 *',
                prefixIcon: Icons.location_on_outlined,
                textInputAction: TextInputAction.next,
                decorationTheme: inputDecorationTheme,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _address2Controller,
                labelText: 'Address 2 (Optional)',
                prefixIcon: Icons.add_location_alt_outlined,
                validator: (value) => null,
                textInputAction: TextInputAction.next,
                decorationTheme: inputDecorationTheme,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextFormField(
                      controller: _postcodeController,
                      labelText: 'Postcode',
                      prefixIcon: Icons.local_post_office_outlined,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decorationTheme: inputDecorationTheme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextFormField(
                      controller: _stateController,
                      labelText: 'State',
                      prefixIcon: Icons.map_outlined,
                      textInputAction: TextInputAction.next,
                      decorationTheme: inputDecorationTheme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _territoryController,
                labelText: 'Territory',
                prefixIcon: Icons.public_outlined,
                textInputAction: TextInputAction.next,
                decorationTheme: inputDecorationTheme,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _telephone1Controller,
                labelText: 'Telephone 1',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decorationTheme: inputDecorationTheme,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _telephone2Controller,
                labelText: 'Telephone 2 (Optional)',
                prefixIcon: Icons.phone_android_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) => null,
                textInputAction: TextInputAction.next,
                decorationTheme: inputDecorationTheme,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _faxNoController,
                labelText: 'Fax No (Optional)',
                prefixIcon: Icons.fax_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) => null,
                textInputAction: TextInputAction.next,
                decorationTheme: inputDecorationTheme,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _contactPersonController,
                labelText: 'Contact Person',
                prefixIcon: Icons.person_outline,
                textInputAction: TextInputAction.next,
                decorationTheme: inputDecorationTheme,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _customerGroupController,
                labelText: 'Customer Group',
                prefixIcon: Icons.group_work_outlined,
                textInputAction: TextInputAction.next,
                decorationTheme: inputDecorationTheme,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextFormField(
                      controller: _customerTypeController,
                      labelText: 'Customer Type',
                      prefixIcon: Icons.category_outlined,
                      textInputAction: TextInputAction.next,
                      decorationTheme: inputDecorationTheme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextFormField(
                      controller: _lotTypeController,
                      labelText: 'Lot Type',
                      prefixIcon: Icons.real_estate_agent_outlined,
                      textInputAction: TextInputAction.next,
                      decorationTheme: inputDecorationTheme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Additional Fields from Detailed Model
              _buildTextFormField(
                controller: _emailController,
                labelText: 'Email (Optional)',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) => null,
                textInputAction: TextInputAction.next,
                decorationTheme: inputDecorationTheme,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _phoneController,
                labelText: 'General Phone (Optional)',
                prefixIcon: Icons.contact_phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) => null,
                textInputAction: TextInputAction.next,
                decorationTheme: inputDecorationTheme,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _paymentTermController,
                labelText: 'Payment Term (Optional)',
                prefixIcon: Icons.timer_outlined,
                validator: (value) => null,
                textInputAction: TextInputAction.next,
                decorationTheme: inputDecorationTheme,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _maxDiscountController,
                labelText: 'Max Discount (%) (Optional)',
                prefixIcon: Icons.percent_outlined,
                keyboardType: TextInputType.number,
                validator: (value) => null,
                textInputAction: TextInputAction.next,
                decorationTheme: inputDecorationTheme,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _segmentController,
                labelText: 'Segment (Optional)',
                prefixIcon: Icons.pie_chart_outline,
                validator: (value) => null,
                textInputAction: TextInputAction.next,
                decorationTheme: inputDecorationTheme,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _paymentTypeDetailController,
                labelText: 'Payment Type (Optional)',
                prefixIcon: Icons.payment_outlined,
                validator: (value) => null,
                textInputAction: TextInputAction.done,
                decorationTheme: inputDecorationTheme,
              ),

              const SizedBox(height: 80), // Extra space for FAB
            ],
          ),
        ),
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
                onPressed: _saveForm,
                icon: Icon(Icons.save_alt_outlined),
                label: Text(_isEditMode ? 'Save Changes' : 'Create Customer'),
                // style: theme.floatingActionButtonTheme.extendedStyle, // Use themed FAB style
              ),
    );
  }

  // Helper method to build TextFormField widgets consistently
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    IconData? prefixIcon,
    String? Function(String?)? validator,
    TextInputAction textInputAction = TextInputAction.next,
    InputDecorationTheme? decorationTheme, // Pass theme
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        // Uses theme by default if decorationTheme is null or properties are not overridden
        labelText: labelText,
        prefixIcon:
            prefixIcon != null
                ? Icon(
                  prefixIcon,
                  color: decorationTheme?.prefixIconColor ?? Colors.grey[600],
                )
                : null,
        // Apply specific parts of the theme or use defaults
        border:
            decorationTheme?.border ??
            OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        enabledBorder:
            decorationTheme?.enabledBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
        focusedBorder:
            decorationTheme?.focusedBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2.0,
              ),
            ),
        filled: decorationTheme?.filled ?? true,
        fillColor: decorationTheme?.fillColor ?? Colors.grey[50],
        contentPadding:
            decorationTheme?.contentPadding ??
            const EdgeInsets.symmetric(vertical: 15.0, horizontal: 12.0),
      ),
      keyboardType: keyboardType,
      readOnly: readOnly,
      textInputAction: textInputAction,
      validator:
          validator ??
          (value) {
            // Default "not empty" validation, but only if labelText doesn't indicate optionality
            // and the field is not readOnly.
            if (!readOnly && (value == null || value.trim().isEmpty)) {
              if (labelText.contains('(Optional)') ||
                  labelText.endsWith('*') == false) {
                // If not marked as optional and not required
                return null; // Allow empty if not explicitly required
              }
              return '$labelText is required.'; // Default for required fields
            }
            return null;
          },
    );
  }
}
