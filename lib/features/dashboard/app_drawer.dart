import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:rempahapp/features/auth/auth_controller.dart';
import 'package:rempahapp/models/global_state.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  AuthController authController = AuthController();
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
              SizedBox(height: 50),
              Container(
                width: double.infinity,
                child: Column(
                  children: [
                    Icon(Icons.account_circle, size: 64, color: Colors.black),
                    SizedBox(height: 10),
                    Text(
                      'Welcome! ${user['username']}',
                      style: TextStyle(color: Colors.black, fontSize: 18),
                    ),
                    Text("Branch Selected: ${gs.selectedBranch}"),
                  ],
                ),
              ),
              Divider(),
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
                leading: Icon(FontAwesomeIcons.fileInvoiceDollar),
                title: Text('Orders'),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(FontAwesomeIcons.circleDollarToSlot),
                title: Text('Review Collection'),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(FontAwesomeIcons.receipt),
                title: Text('Receipts'),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(FontAwesomeIcons.layerGroup),
                title: Text('Inventory Stock'),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(FontAwesomeIcons.filePdf),
                title: Text('Report'),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(FontAwesomeIcons.comments),
                title: Text('Messageing'),
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
            child: Text('Version 1.0.0', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
