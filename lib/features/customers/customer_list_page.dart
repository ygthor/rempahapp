import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
// Assuming ApiV1 is in a path accessible like this. Adjust if necessary.
import 'package:rempahapp/api/api_v1.dart'; // You'll need to import your ApiV1 class
import 'package:rempahapp/features/customers/customer_detail_page.dart';
import 'package:rempahapp/features/customers/customer_form_page.dart';
import 'package:rempahapp/models/customer.dart';
import 'package:rempahapp/models/global_state.dart';
import 'package:rempahapp/shared/functions.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  late ApiV1 _api;
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    // Initialize ApiV1 with bearer token from GlobalState via GetX
    GlobalState gs = Get.find<GlobalState>(); // Explicitly type Get.find()
    _api = ApiV1(bearerToken: gs.token);
    super.initState(); // Call super.initState() after initializing _api

    _fetchCustomers();
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
      _errorMessage = '';
    });
    try {
      // Assuming _api.getAllCustomers() returns Map<String, dynamic>?
      // where success is {'data': List<...>} and error is {'error': true, 'message': ...}
      var responseMap = await _api.getAllCustomers();
      aLog(responseMap);

      if (responseMap == null) {
        _errorMessage = 'Failed to connect to the server. Please check your connection.';
      } else if (responseMap['error'] == true) {
        _errorMessage = responseMap['message']?.toString() ?? 'An unknown API error occurred.';
      } else if (responseMap.containsKey('data') && responseMap['data'] is List) {
        final List<dynamic> customerDataList = responseMap['data'];
        _customers =
            customerDataList
                .map((data) {
                  if (data is Map<String, dynamic>) {
                    try {
                      return Customer.fromJson(data);
                    } catch (e) {
                      print("Error parsing customer item: $data, Error: $e");
                      return null; // Skip this item if parsing fails
                    }
                  } else {
                    print("Skipping invalid item in customer list (not a Map): $data");
                    return null; // Skip items that are not maps
                  }
                })
                .whereType<Customer>() // Filter out any nulls from parsing errors
                .toList();
        _filteredCustomers = _customers;
      }
      // This case handles if your ApiV1.getAllCustomers() was changed to return a List directly on success
      else if (responseMap is List) {
        final List<dynamic> customerDataList = responseMap as List<dynamic>;
        _customers =
            customerDataList
                .map((data) {
                  if (data is Map<String, dynamic>) {
                    return Customer.fromJson(data);
                  }
                  return null;
                })
                .whereType<Customer>()
                .toList();
        _filteredCustomers = _customers;
      } else {
        _errorMessage = 'Received an unexpected data format from the server.';
      }
    } catch (e, s) {
      print("Exception in _fetchCustomers: $e\nStack trace: $s");
      _errorMessage = 'An application error occurred while fetching customers.';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterCustomers() {
    final query = _searchController.text.toLowerCase(); // .text is non-nullable
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = _customers;
      } else {
        _filteredCustomers =
            _customers.where((customer) {
              // Use null-aware operators and provide default empty string for toLowerCase
              final companyMatch = customer.companyName?.toLowerCase().contains(query) ?? false;
              final codeMatch = customer.customerCode?.toLowerCase().contains(query) ?? false;
              final contactMatch = customer.contactPerson?.toLowerCase().contains(query) ?? false;
              final phoneMatch =
                  customer.telephone1?.contains(query) ??
                  false; // .contains works on String? directly if query is not empty
              final emailMatch = customer.email?.toLowerCase().contains(query) ?? false;

              return companyMatch || codeMatch || contactMatch || phoneMatch || emailMatch;
            }).toList();
      }
    });
  }

  Future<void> _onAddNewCustomer() async {
    final result = await Get.to(() => CustomerFormPage());
    if (result == true || result is Customer) {
      _fetchCustomers();
    }
  }

  Future<void> _editCustomer(BuildContext context, Customer customer) async {
    // Pass the customer object to CustomerFormPage for editing
    final result = await Get.to(() => CustomerFormPage(customer: customer));
    if (result == true || result is Customer) {
      _fetchCustomers();
    }
  }

  Future<void> _viewCustomerDetails(BuildContext context, Customer customer) async {
    // Make it async
    // Navigate to CustomerDetailPage, passing the customer data.
    // Await the result when CustomerDetailPage is popped.
    final result = await Get.to(() => CustomerDetailPage(customer: customer));

    // Check if the result is true (indicating a successful save/update)
    if (result == true) {
      _fetchCustomers(); // Refresh the list
    }
  }

  Future<void> _deleteCustomer(BuildContext context, Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete ${customer.companyName ?? customer.name ?? 'this customer'}?'),
          actions: <Widget>[
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop(false)),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      if (customer.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot delete customer: ID is missing.'), backgroundColor: Colors.orange),
        );
        return;
      }
      setState(() {
        _isLoading = true;
      });
      final response = await _api.deleteCustomer(customer.id!);
      setState(() {
        _isLoading = false;
      });

      if (response != null &&
          (response['success'] == true || response['message'] == 'Customer deleted successfully.')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${customer.companyName ?? customer.name ?? 'Customer'} deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchCustomers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${response?['message'] ?? 'Unknown API error'}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchCustomers,
            tooltip: 'Refresh Customers',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Company, Code, Contact, Email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.red, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text("Retry"),
                              onPressed: _fetchCustomers,
                            ),
                          ],
                        ),
                      ),
                    )
                    : _filteredCustomers.isEmpty
                    ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? 'No customers found. Pull down to refresh or add one.'
                            : 'No results for "${_searchController.text}".',
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _fetchCustomers,
                      child: ListView.builder(
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = _filteredCustomers[index];
                          return Card(
                            elevation: 2.0,
                            margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Text(
                                  customer.companyName?.isNotEmpty == true
                                      ? customer.companyName![0].toUpperCase()
                                      : (customer.name?.isNotEmpty == true ? customer.name![0].toUpperCase() : "C"),
                                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                                ),
                              ),
                              title: Text(
                                // customer.companyName ?? customer.name ?? 'N/A',
                                customer.name ?? 'N/A',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    "Code: ${customer.customerCode ?? 'N/A'}",
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                  ),
                                  if (customer.contactPerson?.isNotEmpty == true)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0),
                                      child: Text(
                                        "Contact: ${customer.contactPerson}",
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      ),
                                    ),
                                  if (customer.telephone1?.isNotEmpty == true)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0),
                                      child: Text(
                                        "Tel: ${customer.telephone1}",
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      ),
                                    ),
                                  if (customer.email?.isNotEmpty == true)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0),
                                      child: Text(
                                        "Email: ${customer.email}",
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (String result) {
                                  if (result == 'edit')
                                    _editCustomer(context, customer);
                                  else if (result == 'delete')
                                    _deleteCustomer(context, customer);
                                  else if (result == 'details')
                                    _viewCustomerDetails(context, customer);
                                },
                                itemBuilder:
                                    (BuildContext context) => <PopupMenuEntry<String>>[
                                      const PopupMenuItem<String>(
                                        value: 'details',
                                        child: ListTile(
                                          leading: Icon(FontAwesomeIcons.eye),
                                          title: Text('View Details'),
                                        ),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'edit',
                                        child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit')),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'delete',
                                        child: ListTile(
                                          leading: Icon(Icons.delete_outline, color: Colors.redAccent),
                                          title: Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                        ),
                                      ),
                                    ],
                              ),
                              onTap: () => _viewCustomerDetails(context, customer),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddNewCustomer,
        icon: const Icon(Icons.add_business_outlined),
        label: const Text("Add Customer"),
      ),
    );
  }
}
