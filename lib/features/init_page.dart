import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:kanesanapp/api/api_v1.dart';
import 'package:kanesanapp/features/auth/auth_controller.dart';
import 'package:kanesanapp/models/global_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shared/shared.dart';

class InitPage extends StatefulWidget {
  const InitPage({super.key});

  @override
  _InitPageState createState() => _InitPageState();
}

class _InitPageState extends State<InitPage> {
  AuthController authController = AuthController();

  int step = 0;
  String companyName = '';
  String empName = '';
  String empCode = '';

  @override
  void initState() {
    super.initState();

    // get ui info
    init();
  }

  List<Widget> listsMessages = [];

  pushMessage(Widget w) async {
    await Future.delayed(Duration(milliseconds: 100));
    setState(() {
      listsMessages.add(w);
    });
  }

  init() async {
    final GlobalState gs = Get.find();
    final SharedPreferences sp = await SharedPreferences.getInstance();
    final token = sp.getString('token');

    await pushMessage(Text('Checking Token ...'));
    if (token != null) {
      gs.setToken(token);
      final ApiV1 apiV1 = ApiV1(bearerToken: token);

      //VALIDATE TOKEN
      await pushMessage(Text('Get User Info: ${token.substring(0, 8)}...'));
      var token_info = await apiV1.getUser();
      aLog(token_info);
      if (token_info['error'] == 0) {
        var userInfo = token_info['data'];
        await pushMessage(Text('Retreived User Info ... '));
        await pushMessage(Text(userInfo['name'] + ' ' + userInfo['email'] + '✅'));
        // gs.setEmp(user['data']);
        // aLog(user);
      } else {
        authController.logout();
      }
      await pushMessage(Text('Logging In ...'));
    }
    authController.checkLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Overlay: spinner + messages
          Center(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Image.asset('assets/splashscreen/splash_icon.png', width: 100)),
                  const SpinKitRipple(color: Colors.white, size: 80),
                  const SizedBox(height: 30),
                  ...listsMessages, // Unpack the list of widgets
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
