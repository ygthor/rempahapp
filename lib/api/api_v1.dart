// ignore_for_file: non_constant_identifier_names

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:rempahapp/models/global_state.dart';
import 'dart:convert';
import '../shared/shared.dart';

class ApiV1 {
  String? bearerToken;

  ApiV1({this.bearerToken});

  parseUri(domain, String url) {
    Uri uri = Uri.http(domain, url);
    return uri;
  }

  httpPost(actionUrl, {body}) async {
    return http.post(
      actionUrl,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $bearerToken',
      },

      body: body,
    );
  }

  login(username, password) async {
    Uri actionUrl = parseUri(appDomain(), '/api/auth/token');

    final response = await http.post(
      actionUrl,
      headers: {'Accept': 'application/json'},
      body: {"identifier": "$username", "password": "$password"},
    );
    var result = json.decode(response.body);
    return result;
  }

  register(email, username) async {
    Uri actionUrl = parseUri(appDomain(), '/api/v1/register');

    final response = await http.post(
      actionUrl,
      headers: {'Accept': 'application/json'},
      body: {"email": "$email", "username": "$username"},
    );
    var result = json.decode(response.body);
    return result;
  }

  logout({token, device_token}) async {
    Uri actionUrl = parseUri(appDomain(), '/api/v1/logout');

    final response = await http.post(
      actionUrl,
      headers: {'Accept': 'application/json'},
      body: {"token": "$token", "device_token": "$device_token"},
    );
    var result = json.decode(response.body);
    return result;
  }

  getUser() async {
    Uri actionUrl = parseUri(appDomain(), '/api/me');

    final response = await httpPost(actionUrl);
    aLog(response.body);

    if (response.statusCode != 200) {
      showVDialog(
        title: 'Internal Server Error',
        text: 'Internal Server Error',
      );
      return null;
    }

    var result = json.decode(response.body);
    return result;
  }

  getDashboardData() async {
    GlobalState gs = Get.find();
    String? token = gs.token;
    Uri actionUrl = parseUri(appDomain(), '/api/v1/get_dashboard_data');

    final response = await http.post(
      actionUrl,
      headers: {'Accept': 'application/json'},
      body: {"token": "$token"},
    );
    if (response.statusCode != 200) {
      showVDialog(
        title: 'Internal Server Error',
        text: 'Internal Server Error',
      );
      return null;
    } else {
      var result = json.decode(response.body);
      return result;
    }
  }

  storeDeviceToken({token, deviceToken, deviceInfo}) async {
    Uri actionUrl = parseUri(appDomain(), '/api/v1/store_device_token');

    Map<String, String> header = {'Accept': 'application/json'};

    final response = await http.post(
      actionUrl,
      headers: header,
      body: {
        "token": "$token",
        "device_token": "$deviceToken",
        "device_info": "$deviceInfo",
      },
    );

    if (response.statusCode != 200) {
      showVDialog(
        title: 'Internal Server Error',
        text: 'Internal Server Error',
      );
      return null;
    }

    var result = json.decode(response.body);
    return result;
  }

  getUserPicture(token) async {
    Uri actionUrl = parseUri(appDomain(), '/api/v1/get_user_profile_image');

    final response = await http.post(
      actionUrl,
      headers: {'Accept': 'application/json'},
      body: {"token": "$token"},
    );

    if (response.statusCode != 200) {
      showVDialog(
        title: 'Internal Server Error',
        text: 'Internal Server Error',
      );
      return null;
    }

    var result = json.decode(response.body);
    return result;
  }

  clockInOut({token, gps, address, time_in_type, type, date}) async {
    Uri actionUrl = parseUri(appDomain(), '/api/v1/clock_in_out');
    aLog({
      "token": "$token",
      "gps_lat_lng": "$gps",
      "address": "$address",
      "type": "$type",
      "time_in_type": "$time_in_type",
      "date": "$date",
    });

    if (time_in_type == null || time_in_type == 0) {
      showVDialog(title: 'Error', text: 'time_in_type', type: 'error');
      return;
    }
    final response = await http.post(
      actionUrl,
      headers: {'Accept': 'application/json'},
      body: {
        "token": "$token",
        "gps_lat_lng": "$gps",
        "address": "$address",
        "type": "$type",
        "time_in_type": "$time_in_type",
        "date": "$date",
      },
    );

    if (response.statusCode != 200) {
      showVDialog(
        title: 'Internal Server Error',
        text: 'Internal Server Error',
      );
      return null;
    }

    var result = json.decode(response.body);
    aLog("clockInOut");
    aLog(result);
    return result;
  }

  displayClockInOut({token, type}) async {
    Uri actionUrl = parseUri(appDomain(), '/api/v1/display_clock_in_out');

    final response = await http.post(
      actionUrl,
      headers: {'Accept': 'application/json'},
      body: {"token": "$token", "type": "$type"},
    );

    if (response.statusCode != 200) {
      showVDialog(
        title: 'Internal Server Error',
        text: 'Internal Server Error',
      );
      return null;
    }

    var result = json.decode(response.body);

    return result;
  }

  getRecentClockIn({required token}) async {
    Uri actionUrl = parseUri(appDomain(), '/api/v1/get_recent_clockin_data');

    final response = await http.post(
      actionUrl,
      headers: {'Accept': 'application/json'},
      body: {"token": "$token"},
    );

    if (response.statusCode != 200) {
      showVDialog(
        title: 'Internal Server Error',
        text: 'Internal Server Error',
      );
      return null;
    }

    var result = json.decode(response.body);

    return result;
  }

  getYesterdayPendingTimesheet({required token}) async {
    Uri actionUrl = parseUri(
      appDomain(),
      '/api/v1/get_yesterday_pending_timesheet',
    );

    final response = await http.post(
      actionUrl,
      headers: {'Accept': 'application/json'},
      body: {"token": "$token"},
    );

    if (response.statusCode != 200) {
      showVDialog(
        title: 'Internal Server Error',
        text: 'Internal Server Error',
      );
      return null;
    }

    var result = json.decode(response.body);

    return result;
  }

  getLeavePeriod({required token, year = ''}) async {
    Uri actionUrl = parseUri(appDomain(), '/api/v1/leave/get_leave_info');
    //devAlert(token);
    final response = await http.post(
      actionUrl,
      headers: {'Accept': 'application/json'},
      body: {"token": "$token", "year": "$year"},
    );

    if (response.statusCode != 200) {
      showVDialog(
        title: 'Internal Server Error',
        text: 'Internal Server Error',
      );
      return null;
    }

    var result = json.decode(response.body);

    return result;
  }

  Future<bool> validateOldPassword({
    required token,
    String oldPass = '',
  }) async {
    bool isPasswordValid = false;
    Uri actionUrl = parseUri(
      appDomain(),
      '/api/v1/preference/validate_old_password',
    );
    final response = await http.post(
      actionUrl,
      headers: {'Accept': 'application/json'},
      body: {"token": "$token", "oldPass": oldPass},
    );

    if (response.statusCode != 200) {
      showVDialog(
        title: 'Internal Server Error',
        text: 'Internal Server Error',
      );
      return false;
    }

    var result = json.decode(response.body);
    if (result['data'] == 'true') {
      isPasswordValid = true;
    }

    if (!['true', 'false'].contains(result['data'])) {
      throw Exception('result should only output true or false');
    }
    return isPasswordValid;
  }

  Future<bool> updatePassword({required token, required String newPass}) async {
    bool isUpdateValid = false;
    Uri actionUrl = parseUri(appDomain(), '/api/v1/preference/update_password');
    final response = await http.post(
      actionUrl,
      headers: {'Accept': 'application/json'},
      body: {"token": "$token", "newPass": newPass},
    );

    if (response.statusCode != 200) {
      showVDialog(
        title: 'Internal Server Error',
        text: 'Internal Server Error',
      );
      return false;
    }

    var result = json.decode(response.body);
    if (result['data'] == 'true') {
      isUpdateValid = true;
    }

    if (!['true', 'false'].contains(result['data'])) {
      throw Exception('result should only output true or false');
    }
    return isUpdateValid;
  }

  getNotifications({token, page, perPage}) async {
    Uri actionUrl = parseUri(appDomain(), '/api/v1/get_notifications');
    //devAlert(token);
    final response = await http.post(
      actionUrl,
      headers: {'Accept': 'application/json'},
      body: {"token": "$token", "page": "$page", "per_page": "$perPage"},
    );

    if (response.statusCode != 200) {
      showVDialog(
        title: 'Internal Server Error',
        text: 'Internal Server Error',
      );
      return null;
    }

    var result = json.decode(response.body);

    return result;
  }

  getSystemSetting({required token}) async {
    Uri actionUrl = parseUri(appDomain(), '/api/v1/get_system_setting');
    final response = await http.post(
      actionUrl,
      headers: {'Accept': 'application/json'},
      body: {"token": "$token"},
    );

    if (response.statusCode != 200) {
      showVDialog(
        title: 'Internal Server Error',
        text: 'Internal Server Error',
      );
      return null;
    }

    var result = json.decode(response.body);

    return result;
  }

  getTimesheetTrans({token, page, perPage}) async {
    Uri actionUrl = parseUri(
      appDomain(),
      '/api/v1/timesheet/get_timesheet_trans',
    );
    final response = await http.post(
      actionUrl,
      headers: {'Accept': 'application/json'},
      body: {"token": "$token", "page": "$page", "per_page": "$perPage"},
    );

    if (response.statusCode != 200) {
      showVDialog(
        title: 'Internal Server Error',
        text: 'Internal Server Error',
      );
      return null;
    }

    var result = json.decode(response.body);

    return result;
  }

  getTimesheets({token, transId}) async {
    Uri actionUrl = parseUri(appDomain(), '/api/v1/timesheet/get_timesheets');
    final response = await http.post(
      actionUrl,
      headers: {'Accept': 'application/json'},
      body: {"token": "$token", "trans_id": "$transId"},
    );

    if (response.statusCode != 200) {
      showVDialog(
        title: 'Internal Server Error',
        text: 'Internal Server Error',
      );
      return null;
    }

    var result = json.decode(response.body);

    return result;
  }

  getPayrollPeriod({token}) async {
    Uri actionUrl = parseUri(appDomain(), '/api/v1/get_payslip_period');
    final response = await http.post(
      actionUrl,
      headers: {'Accept': 'application/json'},
      body: {"token": "$token"},
    );

    if (response.statusCode != 200) {
      showVDialog(
        title: 'Internal Server Error',
        text: 'Internal Server Error',
      );
      return null;
    }

    var result = json.decode(response.body);
    return result;
  }

  getPayslipDetail({token, payrollKey}) async {
    Uri actionUrl = parseUri(appDomain(), '/api/v1/get_payslip_detail');
    final response = await http.post(
      actionUrl,
      headers: {'Accept': 'application/json'},
      body: {"token": "$token", "payroll_key": "$payrollKey"},
    );

    if (response.statusCode != 200) {
      showVDialog(
        title: 'Internal Server Error',
        text: 'Internal Server Error',
      );
      return null;
    }

    var result = json.decode(response.body);
    return result;
  }

  getPayslipTemporaryUrl({token, payrollKey}) async {
    Uri actionUrl = parseUri(appDomain(), '/api/v1/get_payslip_temporary_url');
    final response = await http.post(
      actionUrl,
      headers: {'Accept': 'application/json'},
      body: {"token": "$token", "payroll_key": "$payrollKey"},
    );

    if (response.statusCode != 200) {
      showVDialog(
        title: 'Internal Server Error',
        text: 'Internal Server Error',
      );
      return null;
    }

    var result = json.decode(response.body);
    return result;
  }

  triggerPayslipEmail({token, payrollKey}) async {
    Uri actionUrl = parseUri(appDomain(), '/api/v1/trigger_payslip_email');
    final response = await http.post(
      actionUrl,
      headers: {'Accept': 'application/json'},
      body: {"token": "$token", "payroll_key": "$payrollKey"},
    );

    if (response.statusCode != 200) {
      showVDialog(
        title: 'Internal Server Error',
        text: 'Internal Server Error',
      );
      return null;
    }

    var result = json.decode(response.body);
    return result;
  }

  logLocation({token, address, coordinate, device_info}) async {
    Uri actionUrl = parseUri(appDomain(), '/api/v1/log_location');
    final response = await http.post(
      actionUrl,
      headers: {'Accept': 'application/json'},
      body: {
        "token": "$token",
        "address": "$address",
        "coordinate": "$coordinate",
        "device_info": device_info,
      },
    );

    if (response.statusCode != 200) {
      showVDialog(
        title: 'Internal Server Error',
        text: 'Internal Server Error',
      );
      return null;
    }

    var result = json.decode(response.body);

    return result;
  }
} //end of Auth Service Class
