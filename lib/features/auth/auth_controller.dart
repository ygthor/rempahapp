// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:background_location/background_location.dart';
import 'package:flutter/material.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:rempahapp/api/api_v1.dart';
import 'package:rempahapp/features/auth/pages/login_page.dart';
import 'package:rempahapp/features/dashboard/dashboard_page.dart';
import 'package:rempahapp/models/global_state.dart';
import 'package:rempahapp/shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController {
  final formKeyLogin = GlobalKey<FormBuilderState>();
  final formKeyRegister = GlobalKey<FormBuilderState>();

  setDefaultFormValue() {
    formKeyLogin.currentState?.patchValue({
      'username': 'orangutan',
      'password': '123123123',
    });
  }

  checkLogin() async {
    final GlobalState gs = Get.find();
    final SharedPreferences sp = await SharedPreferences.getInstance();
    final token = sp.getString('token');
    ApiV1 apiV1 = ApiV1(bearerToken: token);

    if (token != null) {
      gs.setToken(token);

      //VALIDATE TOKEN
      var user = await apiV1.getUser();
      if (user['error'] == 0) {
        //Get and set employee info to phone

        gs.setUser(user['data']);
        //SET USER TO GLOBAL

        Get.off(DashboardPage());
      } else {
        //USER TOKEN IS Invalid, log it out, and remove token
        sp.remove('token');
        Get.off(const LoginPage());
      }
    } else {
      //go to login page
      Get.off(const LoginPage());
    }
  }

  Future<bool> checkUserTokenStatus() async {
    ApiV1 apiV1 = ApiV1();
    final GlobalState gs = Get.find();
    final SharedPreferences sp = await SharedPreferences.getInstance();
    final token = sp.getString('token');
    final companyCode = sp.getString('company_code');
    sp.getString('api_domain');

    if (gs.token == null) return false; // do nothing

    if (!gs.networkStatus) {
      await showVDialog(title: 'No Network', text: "Network is not available");
      return false;
    }

    bool forceLogout = false;

    if (companyCode == null || companyCode.isEmpty) {
      forceLogout = true;
    }

    if (token != null) {
      var user = await apiV1.getUser();
      aLog(user);
      if (user['error'] == 0) {
        // gs.setEmp(user['data']);
        // var systemSetting = await apiV1.getSystemSetting(token: token);
        // gs.setSystemSetting(systemSetting['data']);
      } else {
        sp.remove('token');
        forceLogout = true;
      }
    } else {
      forceLogout = true;
    }

    if (forceLogout) {
      Get.put(GlobalState()); // reset global status
      sp.remove('token');
      sp.remove('api_domain');
      await showVDialog(
        title: 'Session Expired',
        text: "Your session token is invalid, please login again.",
      );
      Get.off(const LoginPage());
      return false;
    } else {
      return true;
    }
  }

  login({context}) async {
    showLoading();
    ApiV1 apiV1 = ApiV1();
    final GlobalState gs = Get.put(GlobalState());
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    formKeyLogin.currentState!.save();
    var formData = formKeyLogin.currentState!.value;

    if (formKeyLogin.currentState!.validate()) {
    } else {
      //VALIDATE FAIL
      hideLoading();
      return;
    }

    var result = await apiV1.login(formData['username'], formData['password']);

    if (result['error'] == 0) {
      //SET login token into phone storage
      var token = result['data']['token'];
      await prefs.setString('token', token);
      gs.setToken(token);

      //Get and set employee info to phone
      ApiV1 apiV1 = ApiV1(bearerToken: gs.token);
      result = await apiV1.getUser();
      aLog(result);

      gs.setUser(result['data']);

      Get.offAll(DashboardPage());
      //redirect to home page
    } else {
      hideLoading();
      //said login fail
    }
  }

  logout() async {
    final GlobalState gs = Get.find();
    final SharedPreferences sp = await SharedPreferences.getInstance();
    Get.put(GlobalState()); // reset global status
    sp.remove('token');
    sp.remove('company_code');
    sp.remove('api_domain');

    ApiV1 apiV1 = ApiV1();
    apiV1.logout(token: gs.token, device_token: gs.deviceToken);
    sp.remove('token');
    sp.remove('enableLocationTracking');

    // final service = FlutterBackgroundService();
    // var isRunning = await service.isRunning();
    // if (isRunning) service.invoke("stopService");

    Get.off(const LoginPage());
  }

  register() async {
    ApiV1 apiV1 = ApiV1();
    formKeyRegister.currentState!.save();
    var formData = formKeyRegister.currentState!.value;

    if (formKeyRegister.currentState!.validate()) {
    } else {
      //VALIDATE FAIL
      return;
    }

    showLoading();
    var result = await apiV1.register(formData['email'], formData['username']);
    hideLoading();
    if (result['error'] == 0) {
      var message = result['message'] ?? 'Success';
      showVDialog(title: 'Success', text: message, type: "success");
    } else {
      var message = result['message'] ?? 'There are some error in system';
      showVDialog(title: 'Error', text: message, type: "error");
    }
  }
}
