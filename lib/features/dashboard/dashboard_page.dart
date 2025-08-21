import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:kanesanapp/features/auth/auth_controller.dart';
import 'package:kanesanappp/features/dashboard/app_drawer.dart';
import 'package:kanesanappp/shared/constant.dart';
import 'package:kanesanappp/shared/widgets/date_range_component.dart';
import 'package:kanesanappp/api/api_v1.dart';

import '../../models/global_state.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  AuthController authController = AuthController();
  bool _isLoading = false;
  DateTimeRange? _selectedRange;
  Map<String, dynamic> _dashboardData = {
    'totalRevenue': 'RM 0.00',
    'nettSales': 'RM 0.00',
    'totalCollections': 'RM 0.00',
    'outstandingDebt': 'RM 0.00',
    'inventoryValue': 'RM 0.00',
    'invoicesIssued': '0',
    'receiptsIssued': '0',
    'newCustomers': '0',
    'pendingOrders': '0',
    'lowStockItems': '0',
  };

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      String? date_from;
      String? date_to;

      if (_selectedRange != null) {
        date_from = _selectedRange!.start.toString().split(' ')[0];
        date_to = _selectedRange!.end.toString().split(' ')[0];
      }

      GlobalState gs = Get.find<GlobalState>(); // Explicitly type Get.find()
      ApiV1 _api = ApiV1(bearerToken: gs.token);
      final response = await _api.getDashboard(date_from: date_from, date_to: date_to);

      if (response['error'] == 0 && response['status'] == 200) {
        if (mounted) {
          setState(() {
            _dashboardData = response['data'];
            _isLoading = false;
          });
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to load dashboard data');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading dashboard data: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<bool> _onWillPop(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Exit App"),
            content: const Text("Are you sure you want to exit the app?"),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
              ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Exit")),
            ],
          ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    GlobalState gs = Get.find();
    var user = gs.user;

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        drawer: AppDrawer(),
        appBar: AppBar(
          elevation: 2.0,
          backgroundColor: Colors.white,
          title: Text('Dashboard', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 30.0)),
          actions: <Widget>[
            Container(
              margin: EdgeInsets.symmetric(horizontal: 8.0),
              width: 120,
              child: DropdownSearch<String>(
                selectedItem: gs.selectedBranch,
                onChanged: (v) {
                  gs.setSelectedBranch(v);
                  _fetchDashboardData(); // Refresh data when branch changes
                },
                items: (filter, infiniteScrollProps) => Constant.branchList,
                dropdownBuilder: (context, selectedItem) {
                  return Center(child: Text(selectedItem ?? "Select an item", style: TextStyle(fontSize: 16)));
                },
                decoratorProps: DropDownDecoratorProps(
                  decoration: InputDecoration(
                    border: UnderlineInputBorder(borderSide: BorderSide(width: 2.0, color: Colors.grey)),
                  ),
                ),
              ),
            ),
          ],
        ),
        body:
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                  onRefresh: _fetchDashboardData,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Welcome! ${user['username']}',
                              style: TextStyle(color: Colors.black, fontSize: 21, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: 20),
                          DateRangeComponent(
                            currentValue: _selectedRange,
                            onDateRangeChanged: (v) {
                              setState(() {
                                _selectedRange = v;
                              });
                              _fetchDashboardData(); // Refresh data when date range changes
                            },
                          ),
                          SizedBox(height: 10),
                          Wrap(
                            spacing: 16.0,
                            runSpacing: 16.0,
                            children: [
                              _buildDashboardTile(
                                title: 'Revenue',
                                value: _dashboardData['totalRevenue'] ?? 'RM 0.00',
                                icon: FontAwesomeIcons.dollarSign,
                                iconColor: Colors.white,
                                iconBgColor: Colors.green,
                              ),
                              _buildDashboardTile(
                                title: 'Nett Sales',
                                value: _dashboardData['nettSales'] ?? 'RM 0.00',
                                icon: FontAwesomeIcons.chartLine,
                                iconColor: Colors.white,
                                iconBgColor: Colors.lightGreen,
                              ),
                              _buildDashboardTile(
                                title: 'Collections',
                                value: _dashboardData['totalCollections'] ?? 'RM 0.00',
                                icon: FontAwesomeIcons.handHoldingDollar,
                                iconColor: Colors.white,
                                iconBgColor: Colors.blue,
                              ),
                              // _buildDashboardTile(
                              //   title: 'Outstanding',
                              //   value:
                              //       _dashboardData['outstandingDebt'] ??
                              //       'RM 0.00',
                              //   icon: FontAwesomeIcons.hourglassHalf,
                              //   iconColor: Colors.white,
                              //   iconBgColor: Colors.orange,
                              // ),
                              // _buildDashboardTile(
                              //   title: 'Inventory Value',
                              //   value:
                              //       _dashboardData['inventoryValue'] ?? 'RM 0.00',
                              //   icon: FontAwesomeIcons.boxesStacked,
                              //   iconColor: Colors.white,
                              //   iconBgColor: Colors.purple,
                              // ),
                              _buildDashboardTile(
                                title: 'Invoices Issued',
                                value: _dashboardData['invoicesIssued'] ?? '0',
                                icon: FontAwesomeIcons.fileLines,
                                iconColor: Colors.white,
                                iconBgColor: Colors.cyan,
                              ),
                              _buildDashboardTile(
                                title: 'Receipts Issued',
                                value: _dashboardData['receiptsIssued'] ?? '0',
                                icon: FontAwesomeIcons.receipt,
                                iconColor: Colors.white,
                                iconBgColor: Colors.pinkAccent,
                              ),
                              _buildDashboardTile(
                                title: 'New Customers',
                                value: _dashboardData['newCustomers'] ?? '0',
                                icon: FontAwesomeIcons.userPlus,
                                iconColor: Colors.white,
                                iconBgColor: Colors.indigo,
                              ),
                              _buildDashboardTile(
                                title: 'Pending Orders',
                                value: _dashboardData['pendingOrders'] ?? '0',
                                icon: FontAwesomeIcons.clockRotateLeft,
                                iconColor: Colors.white,
                                iconBgColor: Colors.brown,
                              ),
                              // _buildDashboardTile(
                              //   title: 'Low Stock Items',
                              //   value: _dashboardData['lowStockItems'] ?? '0',
                              //   icon: FontAwesomeIcons.triangleExclamation,
                              //   iconColor: Colors.white,
                              //   iconBgColor: Colors.redAccent,
                              // ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
      width: MediaQuery.of(context).size.width / 2 - (16.0 + 8.0), // (padding + spacing/2)
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Ensure content is spaced
              children: [
                Material(
                  color: iconBgColor,
                  shape: CircleBorder(),
                  elevation: 2.0, // Slight elevation for the icon holder
                  child: Padding(
                    padding: const EdgeInsets.all(12.0), // Reduced padding for icon
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
