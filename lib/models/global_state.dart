//USE FOR MISC data, can treat as session in php
// ignore_for_file: prefer_typing_uninitialized_variables
import 'dart:async';

import 'package:rempahapp/shared/constant.dart';
import 'package:rempahapp/shared/functions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GlobalState {
  String? token;
  String? deviceToken;
  String? apiUrl;
  String? apiDomain;
  String? guideDomain;

  bool enableLocationTracking = false;

  var user;
  var recentClockInData;
  var leavePeriod;

  late Map systemSetting;

  Timer? checkTokenTimer;
  bool networkStatus = true;
  String? appVersion = "";
  var dashboardData;

  setEnableLocationTracking(v) async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setBool('enableLocationTracking', v);
    enableLocationTracking = v;

    // final service = FlutterBackgroundService();
    // var isRunning = await service.isRunning();
    // aLog("isRunning: " + (isRunning ? "TRUE" : "FALSE"));

    // if (v) {
    //   service.startService();
    // } else {
    //   service.invoke("stopService");
    // }
  }

  retrieveEnableLocationTracking() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    enableLocationTracking = sp.getBool('enableLocationTracking') ?? false;
    setEnableLocationTracking(enableLocationTracking);
  }

  getGuideDomain() {
    return guideDomain;
  }

  getApiUrl() {
    return 'https://$apiDomain';
  }

  getEmbedUrl(path) {
    String url = 'https://$apiDomain/$path';
    url = appendQueryParameter(url, 'token', token!);
    return url;
  }

  getApiDomain() {
    return Constant.API_DOMAIN;
  }

  setToken(data) {
    token = data;
    // FirebaseController firebaseController = FirebaseController();
    // firebaseController.saveFirebaseDeviceToken();
    // retrieveEnableLocationTracking();
  }

  setTokenSliently(data) {
    token = data;
  }

  setDeviceToken(data) {
    deviceToken = data;
  }

  setUser(data) {
    user = data;
  }

  setRecentClockInData(data) {
    recentClockInData = data;
  }

  setLeavePeriod(data) {
    leavePeriod = data;
  }

  setSystemSetting(data) {
    systemSetting = data;
  }

  stopCheckLoginTimer() {
    // Start the periodic timer
    checkTokenTimer?.cancel();
  }

  setNetworkStatus(bool v) {
    networkStatus = v;
  }

  init() async {
    appVersion = await getVersion();
  }

  setDashboardData(v) {
    dashboardData = v;
  }
}
