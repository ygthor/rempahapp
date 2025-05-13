import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:rempahapp/features/auth/auth_controller.dart';
import 'package:rempahapp/features/dashboard/app_drawer.dart';
import 'package:rempahapp/shared/constant.dart';
import 'package:rempahapp/shared/widgets/date_range_component.dart';

import '../../models/global_state.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

DateTimeRange? _selectedRange;

class _DashboardPageState extends State<DashboardPage> {
  AuthController authController = AuthController();

  @override
  Widget build(BuildContext context) {
    GlobalState gs = Get.find();
    var user = gs.user;

    String _totalRevenue = "RM 0.00";
    String _nettSales = "RM 0.00";
    String _totalCollections = "RM 0.00";
    String _outstandingDebt = "RM 0.00";
    String _inventoryValue = "RM 0.00";
    String _invoicesIssued = "0";
    String _receiptsIssued = "0";
    String _newCustomers = "0";
    String _pendingOrders = "0";
    String _lowStockItems = "0";

    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        elevation: 2.0,
        backgroundColor: Colors.white,
        title: Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 30.0,
          ),
        ),

        actions: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(horizontal: 8.0),
            width: 120,
            child: DropdownSearch<String>(
              selectedItem: gs.selectedBranch,
              onChanged: (v) {
                gs.setSelectedBranch(v);
                setState(() {});
              },
              items: (filter, infiniteScrollProps) => Constant.branchList,
              dropdownBuilder: (context, selectedItem) {
                return Center(
                  child: Text(
                    selectedItem ?? "Select an item", // Handle null case
                    style: TextStyle(
                      fontSize: 16,
                    ), // Optional: Customize text style
                  ),
                );
              },
              decoratorProps: DropDownDecoratorProps(
                decoration: InputDecoration(
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(width: 2.0, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Welcome! ${user['username']}',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Text(_selectedRange.toString()),
              DateRangeComponent(
                onDateRangeChanged: (v) {
                  setState(() {
                    _selectedRange = v;
                  });
                },
              ),
              SizedBox(height: 10),

              Wrap(
                spacing: 16.0, // Increased spacing
                runSpacing: 16.0, // Increased spacing
                children: [
                  // Existing Tiles
                  _buildDashboardTile(
                    title: 'Customers',
                    value: '5000', // Replace with actual data
                    icon: FontAwesomeIcons.userGroup,
                    iconColor: Colors.white,
                    iconBgColor: Colors.teal,
                    onTap: () {
                      /* Navigate to customer list page */
                    },
                  ),
                  _buildDashboardTile(
                    title: 'Orders',
                    value: '1205', // Replace with actual data
                    icon: FontAwesomeIcons.fileInvoiceDollar,
                    iconColor: Colors.white,
                    iconBgColor: Colors.amber,
                    onTap: () {
                      /* Navigate to order list page */
                    },
                  ),

                  // New Tiles
                  _buildDashboardTile(
                    title: 'Revenue',
                    value: _totalRevenue,
                    icon: FontAwesomeIcons.dollarSign,
                    iconColor: Colors.white,
                    iconBgColor: Colors.green,
                    onTap: () {
                      /* Navigate to revenue report */
                    },
                  ),
                  _buildDashboardTile(
                    title: 'Nett Sales',
                    value: _nettSales,
                    icon: FontAwesomeIcons.chartLine,
                    iconColor: Colors.white,
                    iconBgColor: Colors.lightGreen,
                    onTap: () {
                      /* Navigate to sales report */
                    },
                  ),
                  _buildDashboardTile(
                    title: 'Collections',
                    value: _totalCollections,
                    icon: FontAwesomeIcons.handHoldingDollar,
                    iconColor: Colors.white,
                    iconBgColor: Colors.blue,
                    onTap: () {
                      /* Navigate to collections/receipt report */
                    },
                  ),
                  _buildDashboardTile(
                    title: 'Outstanding',
                    value: _outstandingDebt,
                    icon: FontAwesomeIcons.hourglassHalf,
                    iconColor: Colors.white,
                    iconBgColor: Colors.orange,
                    onTap: () {
                      /* Navigate to debt list page */
                    },
                  ),
                  _buildDashboardTile(
                    title: 'Inventory Value',
                    value: _inventoryValue,
                    icon: FontAwesomeIcons.boxesStacked,
                    iconColor: Colors.white,
                    iconBgColor: Colors.purple,
                    onTap: () {
                      /* Navigate to inventory value report */
                    },
                  ),
                  _buildDashboardTile(
                    title: 'Invoices Issued',
                    value: _invoicesIssued,
                    icon: FontAwesomeIcons.fileLines,
                    iconColor: Colors.white,
                    iconBgColor: Colors.cyan,
                    onTap: () {
                      /* Navigate to invoice list */
                    },
                  ),
                  _buildDashboardTile(
                    title: 'Receipts Issued',
                    value: _receiptsIssued,
                    icon: FontAwesomeIcons.receipt,
                    iconColor: Colors.white,
                    iconBgColor: Colors.pinkAccent,
                    onTap: () {
                      /* Navigate to receipt list */
                    },
                  ),
                  _buildDashboardTile(
                    title: 'New Customers',
                    value: _newCustomers,
                    icon: FontAwesomeIcons.userPlus,
                    iconColor: Colors.white,
                    iconBgColor: Colors.indigo,
                    onTap: () {
                      /* Navigate to new customer report */
                    },
                  ),
                  _buildDashboardTile(
                    title: 'Pending Orders',
                    value: _pendingOrders,
                    icon: FontAwesomeIcons.clockRotateLeft,
                    iconColor: Colors.white,
                    iconBgColor: Colors.brown,
                    onTap: () {
                      /* Navigate to pending orders list */
                    },
                  ),
                  _buildDashboardTile(
                    title: 'Low Stock Items',
                    value: _lowStockItems,
                    icon: FontAwesomeIcons.triangleExclamation,
                    iconColor: Colors.white,
                    iconBgColor: Colors.redAccent,
                    onTap: () {
                      /* Navigate to low stock report */
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(Widget child, {onTap}) {
    return Material(
      elevation: 14.0,
      borderRadius: BorderRadius.circular(12.0),
      shadowColor: Color(0x802196F3),
      child: InkWell(
        // Do onTap() if it isn't null, otherwise do print()
        onTap:
            onTap != null
                ? () => onTap()
                : () {
                  print('Not set yet');
                },
        child: child,
      ),
    );
  }

  // Refactored _buildTile to a more generic _buildDashboardTile
  Widget _buildDashboardTile({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width:
          MediaQuery.of(context).size.width / 2 -
          (16.0 + 8.0), // (padding + spacing/2)
      child: Material(
        elevation: 8.0, // Reduced elevation for a flatter look
        borderRadius: BorderRadius.circular(12.0),
        shadowColor: Colors.grey.withOpacity(0.3), // Softer shadow
        child: InkWell(
          onTap: onTap ?? () => print('$title tile tapped (Not set yet)'),
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Reduced padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // Ensure content is spaced
              children: [
                Material(
                  color: iconBgColor,
                  shape: CircleBorder(),
                  elevation: 2.0, // Slight elevation for the icon holder
                  child: Padding(
                    padding: const EdgeInsets.all(
                      12.0,
                    ), // Reduced padding for icon
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 24.0, // Reduced icon size
                    ),
                  ),
                ),
                SizedBox(height: 12.0),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600, // Slightly less bold
                    fontSize: 16.0, // Adjusted font size
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0, // Adjusted font size for value
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
