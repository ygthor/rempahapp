import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:rempahapp/features/auth/auth_controller.dart';
import 'package:rempahapp/features/customers/customer_list_page.dart';
import 'package:rempahapp/features/dashboard/dashboard_page.dart';
import 'package:rempahapp/features/inventory/inventory_list_page.dart';
import 'package:rempahapp/features/invoices/invoice_list_page.dart';
import 'package:rempahapp/features/messaging/messaging_landing_page.dart';
import 'package:rempahapp/features/orders/order_list_page.dart';
import 'package:rempahapp/features/receipts/receipt_list_page.dart';
import 'package:rempahapp/features/report/business_summary_report_page.dart';
import 'package:rempahapp/features/report/report_landing_page.dart';
import 'package:rempahapp/features/review_collection/debt_list_page.dart';
import 'package:rempahapp/features/settings/setting_page.dart';
import 'package:rempahapp/models/global_state.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  AuthController authController = AuthController();
  // Define a list of items for the drawer
  final List<Map<String, dynamic>> _drawerItems = [
    {
      'icon': Icons.dashboard,
      'title': 'Dashboard',
      'onTap': (BuildContext context) {
        Get.offAll(DashboardPage());
      },
    },
    {
      'icon': FontAwesomeIcons.users,
      'title': 'Customers',
      'onTap': (BuildContext context) {
        Get.to(() => CustomerListPage());
      },
    },
    {
      'icon': FontAwesomeIcons.clipboardList,
      'title': 'Orders',
      'onTap': (BuildContext context) {
        // Add your orders action here
        Get.to(() => OrderListPage());
      },
    },
    {
      'icon': FontAwesomeIcons.fileInvoiceDollar,
      'title': 'Invoices',
      'onTap': (BuildContext context) {
        // Add your orders action here
        Get.to(() => InvoiceListPage());
      },
    },
    {
      'icon': FontAwesomeIcons.circleDollarToSlot,
      'title': 'Review Collection',
      'onTap': (BuildContext context) {
        // Add your review collection action here
        Get.to(() => DebtListPage());
      },
    },
    {
      'icon': FontAwesomeIcons.receipt,
      'title': 'Receipts',
      'onTap': (BuildContext context) {
        Get.to(() => ReceiptListPage());
      },
    },
    {
      'icon': FontAwesomeIcons.layerGroup,
      'title': 'Inventory Stock',
      'onTap': (BuildContext context) {
        Get.to(() => InventoryListPage());
      },
    },
    {
      'icon': FontAwesomeIcons.filePdf,
      'title': 'Report',
      'onTap': (BuildContext context) {
        // Add your report action here
        Get.to(() => ReportLandingPage());
      },
    },
    {
      'icon': FontAwesomeIcons.comments,
      'title': 'Messaging', // Corrected typo from 'Messageing'
      'onTap': (BuildContext context) {
        // Add your messaging action here
        Get.to(() => MessagingLandingPage());
      },
    },
  ];

  @override
  Widget build(BuildContext context) {
    GlobalState gs = Get.find();
    var user = gs.user;
    return Drawer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    const Icon(Icons.account_circle, size: 64, color: Colors.black),
                    const SizedBox(height: 10),
                    Text('Welcome! ${user['username']}', style: const TextStyle(color: Colors.black, fontSize: 18)),
                    Text("Branch Selected: ${gs.selectedBranch}"),
                  ],
                ),
              ),
              const Divider(),
              // Use ListView.builder or a Column with a map for dynamic ListTiles
              // Using a Column with map here for simplicity with existing structure
              Column(
                children:
                    _drawerItems.map((item) {
                      return ListTile(
                        leading: Icon(item['icon'] as IconData), // Cast to IconData
                        title: Text(item['title'] as String), // Cast to String
                        onTap: () => (item['onTap'] as Function(BuildContext))(context), // Cast and call
                      );
                    }).toList(),
              ),
              const Divider(), // Optional: Add a divider after the looped items
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Get.to(() => SettingsPage());
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  // Navigator.pop(context); // Pop before showing dialog if you want the drawer to close immediately
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Are you sure you want to log out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context), // Closes the dialog
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                authController.logout();
                                Navigator.pop(context); // Closes the dialog
                                Navigator.pop(context); // Closes the drawer if not already closed
                              },
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                  );
                },
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Version 1.0.0', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
