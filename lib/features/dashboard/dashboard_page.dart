import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:rempahapp/features/auth/auth_controller.dart';

import '../../models/global_state.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  AuthController authController = AuthController();
  static final List<String> chartDropdownItems = [
    'Last 7 days',
    'Last month',
    'Last year',
  ];
  String actualDropdown = chartDropdownItems[0];
  int actualChart = 0;

  final List<String> items = [
    'Item1',
    'Item2',
    'Item3',
    'Item4',
    'Item5',
    'Item6',
    'Item7',
    'Item8',
  ];
  String? selectedValue;

  @override
  Widget build(BuildContext context) {
    GlobalState gs = Get.find();
    var user = gs.user;

    return Scaffold(
      drawer: Drawer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            Column(
              children: [
                DrawerHeader(
                  child: Container(
                    width: double.infinity,
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_circle,
                          size: 64,
                          color: Colors.black,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Welcome! ${user['username']}',
                          style: TextStyle(color: Colors.black, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.dashboard),
                  title: Text('Dashboard'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(FontAwesomeIcons.users),
                  title: Text('Customers'),
                  onTap: () {},
                ),
                ListTile(
                  leading: Icon(FontAwesomeIcons.users),
                  title: Text('Products'),
                  onTap: () {},
                ),
                ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    // Add your settings action here
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                  onTap: () {
                    Navigator.pop(context);
                    // Add your logout logic here
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text('Logout'),
                            content: Text('Are you sure you want to log out?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  authController.logout();
                                  Navigator.pop(context);
                                },
                                child: Text('Logout'),
                              ),
                            ],
                          ),
                    );
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),

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
              selectedItem: "Penang",
              items: (filter, infiniteScrollProps) => ["Penang", "Ipoh"],
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
              _buildTile(
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Views',
                            style: TextStyle(color: Colors.blueAccent),
                          ),
                          Text(
                            '265K',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 34.0,
                            ),
                          ),
                        ],
                      ),
                      Material(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(24.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Icon(
                            Icons.timeline,
                            color: Colors.white,
                            size: 30.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.0),
              Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 2 - 22,
                    child: _buildTile(
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Material(
                              color: Colors.teal,
                              shape: CircleBorder(),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Icon(
                                  Icons.settings_applications,
                                  color: Colors.white,
                                  size: 30.0,
                                ),
                              ),
                            ),
                            SizedBox(height: 16.0),
                            Text(
                              'General',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 24.0,
                              ),
                            ),
                            Text(
                              'Images, Videos',
                              style: TextStyle(color: Colors.black45),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 2 - 22,
                    child: _buildTile(
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Material(
                              color: Colors.amber,
                              shape: CircleBorder(),
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Icon(
                                  Icons.notifications,
                                  color: Colors.white,
                                  size: 30.0,
                                ),
                              ),
                            ),
                            SizedBox(height: 16.0),
                            Text(
                              'Alerts',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 24.0,
                              ),
                            ),
                            Text(
                              'All',
                              style: TextStyle(color: Colors.black45),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: _buildTile(
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Revenue',
                                  style: TextStyle(color: Colors.green),
                                ),
                                Text(
                                  '\$16K',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 34.0,
                                  ),
                                ),
                              ],
                            ),
                            DropdownButton(
                              isDense: true,
                              value: actualDropdown,
                              onChanged: (v) {
                                setState(() {
                                  actualDropdown = v!;
                                });
                              },
                              items:
                                  chartDropdownItems.map((String title) {
                                    return DropdownMenuItem(
                                      value: title,
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: _buildTile(
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Shop Items',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                                Text(
                                  '173',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 34.0,
                                  ),
                                ),
                              ],
                            ),
                            Material(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(24.0),
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Icon(
                                  Icons.store,
                                  color: Colors.white,
                                  size: 30.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
}
