import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:rempahapp/features/customers/customer_form_page.dart';
import 'package:rempahapp/models/customer.dart'; // If you want to use FontAwesome icons

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  // Sample list of customers - in a real app, this would come from a database or API
  final List<Customer> _customers = [
    Customer(
      id: '1',
      name: 'Alice Wonderland',
      email: 'alice@example.com',
      phone: '555-1234',
      avatarUrl: 'https://placehold.co/100x100/E6E6FA/333333?text=AW',
    ),
    Customer(
      id: '2',
      name: 'Bob The Builder',
      email: 'bob@example.com',
      phone: '555-5678',
      avatarUrl: 'https://placehold.co/100x100/F0E68C/333333?text=BB',
    ),
    Customer(
      id: '3',
      name: 'Charlie Brown',
      email: 'charlie@example.com',
      phone: '555-8765',
    ), // No avatar
    Customer(
      id: '4',
      name: 'Diana Prince',
      email: 'diana@example.com',
      phone: '555-4321',
      avatarUrl: 'https://placehold.co/100x100/ADD8E6/333333?text=DP',
    ),
    Customer(
      id: '5',
      name: 'Edward Scissorhands',
      email: 'edward@example.com',
      phone: '555-9900',
    ),
    Customer(
      id: '6',
      name: 'Fiona Gallagher',
      email: 'fiona@example.com',
      phone: '555-1122',
      avatarUrl: 'https://placehold.co/100x100/90EE90/333333?text=FG',
    ),
    Customer(
      id: '7',
      name: 'George Jetson',
      email: 'george@example.com',
      phone: '555-3344',
    ),
    Customer(
      id: '8',
      name: 'Hannah Montana',
      email: 'hannah@example.com',
      phone: '555-5566',
      avatarUrl: 'https://placehold.co/100x100/FFB6C1/333333?text=HM',
    ),
  ];

  List<Customer> _filteredCustomers = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initially, display all customers
    _filteredCustomers = _customers;
    _searchController.addListener(_filterCustomers);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCustomers);
    _searchController.dispose();
    super.dispose();
  }

  _onAddNewCustomer() {
    Get.to(() => CustomerFormPage());
  }

  void _filterCustomers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      // if (query.isEmpty) {
      //   _filteredCustomers = _customers;
      // } else {
      //   _filteredCustomers =
      //       _customers.where((customer) {
      //         return customer.name.toLowerCase().contains(query) ||
      //             customer.email.toLowerCase().contains(query) ||
      //             customer.phone.toLowerCase().contains(query);
      //       }).toList();
      // }
    });
  }

  void _viewCustomerDetails(BuildContext context, Customer customer) {
    Get.to(() => CustomerFormPage());
  }

  void _editCustomer(BuildContext context, Customer customer) {
    Get.to(() => CustomerFormPage());
  }

  void _deleteCustomer(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete ${customer.name}?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                setState(() {
                  _customers.removeWhere((c) => c.id == customer.id);
                  _filterCustomers(); // Re-apply filter to update the displayed list
                });
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${customer.name} deleted'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        // backgroundColor: Colors.teal, // Example custom color
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 20,
                ),
              ),
            ),
          ),
          // Customer List
          Expanded(
            child:
                _filteredCustomers.isEmpty
                    ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? 'No customers yet.'
                            : 'No customers found for "${_searchController.text}".',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = _filteredCustomers[index];
                        return Card(
                          elevation: 3.0,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 6.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 10.0,
                            ),

                            title: Text(
                              customer.name ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  customer.email ?? '',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  customer.phone ?? '',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (String result) {
                                if (result == 'edit') {
                                  _editCustomer(context, customer);
                                } else if (result == 'delete') {
                                  _deleteCustomer(context, customer);
                                } else if (result == 'details') {
                                  _viewCustomerDetails(context, customer);
                                }
                              },
                              itemBuilder:
                                  (BuildContext context) =>
                                      <PopupMenuEntry<String>>[
                                        const PopupMenuItem<String>(
                                          value: 'edit',
                                          child: ListTile(
                                            leading: Icon(Icons.edit_outlined),
                                            title: Text('Edit'),
                                          ),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'delete',
                                          child: ListTile(
                                            leading: Icon(
                                              Icons.delete_outline,
                                              color: Colors.redAccent,
                                            ),
                                            title: Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.redAccent,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                            ),
                            onTap:
                                () => _viewCustomerDetails(context, customer),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _onAddNewCustomer();
        },
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text("New Customer"),
        // backgroundColor: Colors.teal, // Example custom color
      ),
    );
  }
}

/*
To use this page, you would typically navigate to it, for example:

Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const CustomerListPage()),
);

And ensure you have the `font_awesome_flutter` package in your `pubspec.yaml`
if you plan to use its icons (though this example primarily uses Material Icons).

dependencies:
  flutter:
    sdk: flutter
  font_awesome_flutter: ^latest_version # Check pub.dev for the latest version
*/
