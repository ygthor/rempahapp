import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
// Adjust these import paths if they differ in your project structure
import 'package:rempahapp/api/api_v1.dart';
import 'package:rempahapp/models/customer.dart';
import 'package:rempahapp/models/global_state.dart';

class CustomerDetailPage extends StatefulWidget {
  final Customer customer; // Customer is now required for this page

  const CustomerDetailPage({super.key, required this.customer});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  final _formKey = GlobalKey<FormState>();
  late ApiV1 _api;
  bool _isLoading = false;

  // Controllers for each text field
  late TextEditingController _customerCodeController;
  late TextEditingController _companyNameController;
  late TextEditingController _addressController; // General address
  late TextEditingController _paymentTermController;
  late TextEditingController _maxDiscountController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController; // General phone
  // Controllers for fields that might be part of the detailed form but not in the simple one
  late TextEditingController _address1Controller;
  late TextEditingController _address2Controller;
  late TextEditingController _postcodeController;
  late TextEditingController _stateController;
  late TextEditingController _territoryController;
  late TextEditingController _telephone1Controller; // Specific telephone 1
  late TextEditingController _telephone2Controller;
  late TextEditingController _faxNoController;
  late TextEditingController _contactPersonController;
  late TextEditingController _customerGroupController;
  late TextEditingController _lotTypeController;

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
    'Other',
  ];
  final List<String> _segmentOptions = [
    'Premium',
    'Mid-Range',
    'Budget',
    'Niche',
    'Other',
  ];
  final List<String> _paymentTypeOptions = [
    'Cash on Delivery (COD)',
    'Bank Transfer',
    'Credit Card',
    'E-Wallet',
    'Other',
  ];

  // This page is always in edit mode as widget.customer is required
  bool get _isEditMode => true;

  @override
  void initState() {
    GlobalState gs = Get.find<GlobalState>();
    _api = ApiV1(bearerToken: gs.token);
    super.initState();

    // Initialize controllers
    _customerCodeController = TextEditingController();
    _companyNameController = TextEditingController();
    _addressController = TextEditingController();
    _paymentTermController = TextEditingController();
    _maxDiscountController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _address1Controller = TextEditingController();
    _address2Controller = TextEditingController();
    _postcodeController = TextEditingController();
    _stateController = TextEditingController();
    _territoryController = TextEditingController();
    _telephone1Controller = TextEditingController();
    _telephone2Controller = TextEditingController();
    _faxNoController = TextEditingController();
    _contactPersonController = TextEditingController();
    _customerGroupController = TextEditingController();
    _lotTypeController = TextEditingController();

    // Populate fields from the provided customer
    _populateFieldsFromCustomer(widget.customer);
  }

  void _populateFieldsFromCustomer(Customer customer) {
    _customerCodeController.text = customer.customerCode ?? '';
    _companyNameController.text = customer.companyName ?? '';
    _addressController.text =
        customer.address ??
        ((customer.address1 ?? '') +
                (customer.address2 != null ? '\n${customer.address2}' : ''))
            .trim();
    _paymentTermController.text = customer.paymentTerm ?? '';
    _maxDiscountController.text = customer.maxDiscount ?? '';
    _emailController.text = customer.email ?? '';
    _phoneController.text = customer.phone ?? customer.telephone1 ?? '';

    _address1Controller.text = customer.address1 ?? '';
    _address2Controller.text = customer.address2 ?? '';
    _postcodeController.text = customer.postcode ?? '';
    _stateController.text = customer.state ?? '';
    _territoryController.text = customer.territory ?? '';
    _telephone1Controller.text = customer.telephone1 ?? '';
    _telephone2Controller.text = customer.telephone2 ?? '';
    _faxNoController.text = customer.faxNo ?? '';
    _contactPersonController.text = customer.contactPerson ?? '';
    _customerGroupController.text = customer.customerGroup ?? '';
    _lotTypeController.text = customer.lotType ?? '';

    // Initialize selected values for dropdowns
    _selectedCustomerType = null; // Reset first
    if (customer.customerType != null &&
        _customerTypeOptions.contains(customer.customerType)) {
      _selectedCustomerType = customer.customerType;
    } else if (customer.customerType != null &&
        customer.customerType!.isNotEmpty) {
      if (!_customerTypeOptions.contains('Other'))
        _customerTypeOptions.add('Other');
      _selectedCustomerType = 'Other';
    }

    _selectedSegment = null; // Reset first
    if (customer.segment != null &&
        _segmentOptions.contains(customer.segment)) {
      _selectedSegment = customer.segment;
    } else if (customer.segment != null && customer.segment!.isNotEmpty) {
      if (!_segmentOptions.contains('Other')) _segmentOptions.add('Other');
      _selectedSegment = 'Other';
    }

    _selectedPaymentType = null; // Reset first
    if (customer.paymentType != null &&
        _paymentTypeOptions.contains(customer.paymentType)) {
      _selectedPaymentType = customer.paymentType;
    } else if (customer.paymentType != null &&
        customer.paymentType!.isNotEmpty) {
      if (!_paymentTypeOptions.contains('Other'))
        _paymentTypeOptions.add('Other');
      _selectedPaymentType = 'Other';
    }
  }

  @override
  void dispose() {
    _customerCodeController.dispose();
    _companyNameController.dispose();
    _addressController.dispose();
    _paymentTermController.dispose();
    _maxDiscountController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
    _lotTypeController.dispose();
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

    Map<String, dynamic> customerData = {
      'customer_code': _customerCodeController.text,
      'company_name': _companyNameController.text,
      'address': _addressController.text,
      'address1':
          _address1Controller.text.isEmpty ? null : _address1Controller.text,
      'address2':
          _address2Controller.text.isEmpty ? null : _address2Controller.text,
      'postcode':
          _postcodeController.text.isEmpty ? null : _postcodeController.text,
      'state': _stateController.text.isEmpty ? null : _stateController.text,
      'territory':
          _territoryController.text.isEmpty ? null : _territoryController.text,
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
      'customer_group':
          _customerGroupController.text.isEmpty
              ? null
              : _customerGroupController.text,
      'lot_type':
          _lotTypeController.text.isEmpty ? null : _lotTypeController.text,
      'payment_term': _paymentTermController.text,
      'max_discount': _maxDiscountController.text,
      'email': _emailController.text.isEmpty ? null : _emailController.text,
      'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
      'customer_type': _selectedCustomerType,
      'segment': _selectedSegment,
      'payment_type': _selectedPaymentType,
    };

    Map<String, dynamic>? apiResponse;

    try {
      if (widget.customer.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Customer ID is missing. Cannot update.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      apiResponse = await _api.updateCustomer(
        widget.customer.id!,
        customerData,
      );

      setState(() {
        _isLoading = false;
      });

      if (apiResponse != null) {
        // Check for error flag from ApiV1 wrapper first (network/HTTP status errors)
        // This 'error' key is assumed to be set by your ApiV1 class for non-2xx HTTP or network issues.
        bool isApiV1WrapperError =
            apiResponse['error'] == true && apiResponse['message'] != null;

        if (isApiV1WrapperError) {
          // Error was caught by ApiV1 wrapper (e.g., network issue, non-2xx HTTP status)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                apiResponse['message']?.toString() ?? 'An API error occurred.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else {
          // ApiV1 call was successful (HTTP 200/201), now inspect Laravel's response
          // This 'apiResponse' is the direct decoded JSON from Laravel's makeResponse
          int laravelStatus =
              apiResponse['status'] as int? ??
              0; // Status from Laravel's makeResponse
          dynamic laravelErrorFlag =
              apiResponse['error']; // Potential "error: 1" from Laravel's makeResponse payload

          bool isLaravelSuccessStatus =
              laravelStatus >= 200 && laravelStatus < 300;
          // Check if laravelErrorFlag is explicitly 1 (integer) or true (boolean)
          bool hasLaravelLogicalError =
              laravelErrorFlag == 1 || laravelErrorFlag == true;

          if (isLaravelSuccessStatus && !hasLaravelLogicalError) {
            // True success from Laravel
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  apiResponse['message'] ?? 'Customer updated successfully!',
                ),
                backgroundColor: Colors.green,
              ),
            );
            Get.back(result: true); // Pass true to indicate success for refresh
          } else {
            // Logical error from Laravel (e.g., status 422 or error: 1)
            String errorMessage =
                apiResponse['message']?.toString() ?? 'Operation failed.';
            if (laravelStatus == 422 &&
                apiResponse['data'] is Map &&
                apiResponse['data']['errors'] is Map) {
              // Format validation errors
              Map<String, dynamic> validationErrors =
                  apiResponse['data']['errors'];
              StringBuffer errorsBuffer = StringBuffer();
              errorsBuffer.writeln(errorMessage); // Start with the main message
              validationErrors.forEach((field, messages) {
                if (messages is List && messages.isNotEmpty) {
                  errorsBuffer.writeln("- $field: ${messages.join(', ')}");
                }
              });
              errorMessage = errorsBuffer.toString().trim();
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.redAccent,
                duration: const Duration(
                  seconds: 5,
                ), // Show longer for detailed errors
              ),
            );
          }
        }
      } else {
        // apiResponse is null - this case should ideally be handled within ApiV1 if it means an error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Received no response from API service.'),
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

  String? _validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName cannot be empty.';
    }
    return null;
  }

  String? _validateDropdownSelection(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please select a $fieldName.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Customer Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20.0,
          20.0,
          20.0,
          80.0,
        ), // Added bottom padding for FAB
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildTextFormField(
                controller: _customerCodeController,
                labelText: 'Customer Code *',
                prefixIcon: Icons.qr_code_scanner_outlined,
                validator: (v) => _validateNotEmpty(v, "Customer Code"),
                readOnly: true,
              ),
              const SizedBox(height: 20.0),
              _buildTextFormField(
                controller: _companyNameController,
                labelText: 'Company Name *',
                prefixIcon: Icons.business_outlined,
                validator: (v) => _validateNotEmpty(v, "Company Name"),
              ),
              const SizedBox(height: 20.0),
              _buildTextFormField(
                controller: _addressController,
                labelText: 'Main Address *',
                prefixIcon: Icons.location_city_outlined,
                keyboardType: TextInputType.multiline,
                minLines: 3,
                maxLines: null,
                validator: (v) => _validateNotEmpty(v, "Main Address"),
              ),
              const SizedBox(height: 20.0),

              _buildDropdownFormField(
                value: _selectedCustomerType,
                items: _customerTypeOptions,
                onChanged: (val) => setState(() => _selectedCustomerType = val),
                labelText: 'Customer Type *',
                prefixIcon: FontAwesomeIcons.userGear,
                validator:
                    (v) => _validateDropdownSelection(v, "Customer Type"),
              ),
              const SizedBox(height: 20.0),
              _buildDropdownFormField(
                value: _selectedSegment,
                items: _segmentOptions,
                onChanged: (val) => setState(() => _selectedSegment = val),
                labelText: 'Segment *',
                prefixIcon: FontAwesomeIcons.chartPie,
                validator: (v) => _validateDropdownSelection(v, "Segment"),
              ),
              const SizedBox(height: 20.0),
              _buildDropdownFormField(
                value: _selectedPaymentType,
                items: _paymentTypeOptions,
                onChanged: (val) => setState(() => _selectedPaymentType = val),
                labelText: 'Payment Type *',
                prefixIcon: FontAwesomeIcons.handHoldingDollar,
                validator: (v) => _validateDropdownSelection(v, "Payment Type"),
              ),
              const SizedBox(height: 20.0),

              _buildTextFormField(
                controller: _paymentTermController,
                labelText: 'Payment Term *',
                prefixIcon: FontAwesomeIcons.fileInvoiceDollar,
                validator: (v) => _validateNotEmpty(v, "Payment Term"),
              ),
              const SizedBox(height: 20.0),
              _buildTextFormField(
                controller: _maxDiscountController,
                labelText: 'Max Discount (%) *',
                prefixIcon: FontAwesomeIcons.percent,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) => _validateNotEmpty(v, "Max Discount"),
              ),
              const SizedBox(height: 20.0),
              _buildTextFormField(
                controller: _emailController,
                labelText: 'Email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20.0),
              _buildTextFormField(
                controller: _phoneController,
                labelText: 'Primary Phone',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20.0),

              ExpansionTile(
                title: Text(
                  "Additional Details (Optional)",
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 10),
                initiallyExpanded: false,
                children: [
                  _buildTextFormField(
                    controller: _address1Controller,
                    labelText: 'Address Line 1',
                    prefixIcon: Icons.home_outlined,
                  ),
                  const SizedBox(height: 20.0),
                  _buildTextFormField(
                    controller: _address2Controller,
                    labelText: 'Address Line 2',
                    prefixIcon: Icons.home_work_outlined,
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _postcodeController,
                          labelText: 'Postcode',
                          prefixIcon: Icons.local_post_office_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextFormField(
                          controller: _stateController,
                          labelText: 'State',
                          prefixIcon: Icons.map_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  _buildTextFormField(
                    controller: _territoryController,
                    labelText: 'Territory',
                    prefixIcon: Icons.public_outlined,
                  ),
                  const SizedBox(height: 20.0),
                  _buildTextFormField(
                    controller: _telephone1Controller,
                    labelText: 'Telephone 1 (Office)',
                    prefixIcon: Icons.phone_in_talk_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20.0),
                  _buildTextFormField(
                    controller: _telephone2Controller,
                    labelText: 'Telephone 2 (Mobile)',
                    prefixIcon: Icons.phone_android_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20.0),
                  _buildTextFormField(
                    controller: _faxNoController,
                    labelText: 'Fax No',
                    prefixIcon: Icons.fax_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20.0),
                  _buildTextFormField(
                    controller: _contactPersonController,
                    labelText: 'Contact Person',
                    prefixIcon: Icons.person_pin_outlined,
                  ),
                  const SizedBox(height: 20.0),
                  _buildTextFormField(
                    controller: _customerGroupController,
                    labelText: 'Customer Group',
                    prefixIcon: Icons.groups_outlined,
                  ),
                  const SizedBox(height: 20.0),
                  _buildTextFormField(
                    controller: _lotTypeController,
                    labelText: 'Lot Type',
                    prefixIcon: Icons.real_estate_agent_outlined,
                  ),
                ],
              ),
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
                backgroundColor: theme.colorScheme.secondary,
              )
              : FloatingActionButton.extended(
                onPressed: _saveForm,
                icon: const Icon(Icons.save_alt_outlined),
                label: const Text('Save Changes'),
              ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int minLines = 1,
    int? maxLines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: 'Enter ${labelText.replaceAll(" *", "")}',
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      readOnly: readOnly,
      validator: validator,
      textInputAction: textInputAction,
    );
  }

  Widget _buildDropdownFormField({
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    required String labelText,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: labelText,
        hintText: 'Select ${labelText.replaceAll(" *", "")}',
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      value: value,
      items:
          items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
