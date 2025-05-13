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

              // _buildTile(
              //   Padding(
              //     padding: const EdgeInsets.all(24.0),
              //     child: Row(
              //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //       children: [
              //         Column(
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           children: [
              //             Text(
              //               'Total Views',
              //               style: TextStyle(color: Colors.blueAccent),
              //             ),
              //             Text(
              //               '265K',
              //               style: TextStyle(
              //                 color: Colors.black,
              //                 fontWeight: FontWeight.w700,
              //                 fontSize: 34.0,
              //               ),
              //             ),
              //           ],
              //         ),
              //         Material(
              //           color: Colors.blue,
              //           borderRadius: BorderRadius.circular(24.0),
              //           child: Padding(
              //             padding: const EdgeInsets.all(16.0),
              //             child: Icon(
              //               Icons.timeline,
              //               color: Colors.white,
              //               size: 30.0,
              //             ),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
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
                                  FontAwesomeIcons.userGroup,
                                  color: Colors.white,
                                  size: 30.0,
                                ),
                              ),
                            ),
                            SizedBox(height: 16.0),
                            Text(
                              'Customer',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 24.0,
                              ),
                            ),
                            Text(
                              '5000',
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
                                  FontAwesomeIcons.fileInvoiceDollar,
                                  color: Colors.white,
                                  size: 30.0,
                                ),
                              ),
                            ),
                            SizedBox(height: 16.0),
                            Text(
                              'Orders',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 24.0,
                              ),
                            ),
                            Text('12', style: TextStyle(color: Colors.black45)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // SizedBox(
                  //   width: MediaQuery.of(context).size.width,
                  //   child: _buildTile(
                  //     Padding(
                  //       padding: const EdgeInsets.all(24.0),
                  //       child: Row(
                  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //         children: [
                  //           Column(
                  //             crossAxisAlignment: CrossAxisAlignment.start,
                  //             children: [
                  //               Text(
                  //                 'Revenue',
                  //                 style: TextStyle(color: Colors.green),
                  //               ),
                  //               Text(
                  //                 '\$16K',
                  //                 style: TextStyle(
                  //                   fontWeight: FontWeight.w700,
                  //                   fontSize: 34.0,
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // SizedBox(
                  //   width: MediaQuery.of(context).size.width,
                  //   child: _buildTile(
                  //     Padding(
                  //       padding: const EdgeInsets.all(24.0),
                  //       child: Row(
                  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //         children: [
                  //           Column(
                  //             crossAxisAlignment: CrossAxisAlignment.start,
                  //             children: [
                  //               Text(
                  //                 'Inventory',
                  //                 style: TextStyle(color: Colors.redAccent),
                  //               ),
                  //               Text(
                  //                 '173',
                  //                 style: TextStyle(
                  //                   fontWeight: FontWeight.w700,
                  //                   fontSize: 34.0,
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //           Material(
                  //             color: Colors.red,
                  //             borderRadius: BorderRadius.circular(24.0),
                  //             child: Padding(
                  //               padding: EdgeInsets.all(16.0),
                  //               child: Icon(
                  //                 Icons.store,
                  //                 color: Colors.white,
                  //                 size: 30.0,
                  //               ),
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ),
                  // ),
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
