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

  var user;
  bool networkStatus = true;
  String? appVersion = "";
  var dashboardData;

  String? selectedBranch;

  GlobalState() {
    init();
  }
  init() async {
    appVersion = await getVersion();
    selectedBranch = Constant.branchList[0];
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
  }

  setDeviceToken(data) {
    deviceToken = data;
  }

  setUser(data) {
    user = data;
  }

  setNetworkStatus(bool v) {
    networkStatus = v;
  }

  setDashboardData(v) {
    dashboardData = v;
  }

  setSelectedBranch(v) {
    selectedBranch = v;
  }
}
