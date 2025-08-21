// ignore_for_file: non_constant_identifier_names, prefer_const_constructors, unused_local_variable

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:kanesanapp/models/global_state.dart';
import 'package:kanesanapp/plugins/version_checker.dart';
import 'package:kanesanapp/shared/constant.dart';
import 'package:kanesanapp/shared/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';

import 'shared.dart';

String apiUrl() {
  GlobalState gs = Get.find();
  return gs.getApiUrl();
}

String appDomain() {
  GlobalState gs = Get.find();
  return gs.getApiDomain();
}

devAlert(val) {
  if (val is List || val is Map) {
    val = jsonEncode(val);
  }

  Get.defaultDialog(
    title: "... Alert ...",
    middleText: "$val",
    backgroundColor: Colors.green,
    titleStyle: const TextStyle(color: Colors.white),
    middleTextStyle: const TextStyle(color: Colors.white),
  );
}

showVDialog({title = "Alert", text = "", type = "", onConfirm}) async {
  Widget actionButton;
  IconData icon;
  Color iconColor = Colors.black;

  if (onConfirm != null) {
    actionButton = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        TextButton(onPressed: Get.back, child: Text('Cancel', style: TextStyle(color: Colors.red))),
        ElevatedButton(
          style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.red)),
          onPressed: onConfirm,
          child: Text('Yes', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  } else {
    actionButton = Center(
      child: TextButton(onPressed: Get.back, child: Text('Close', style: TextStyle(color: Colors.red))),
    );
  }

  if (type == "error") {
    icon = FontAwesomeIcons.circleXmark;
    iconColor = Colors.red;
  } else if (type == "success") {
    icon = FontAwesomeIcons.circleCheck;
    iconColor = Colors.teal;
  } else if (type == "confirmation") {
    icon = FontAwesomeIcons.circleQuestion;
    iconColor = Colors.blue;
  } else {
    icon = FontAwesomeIcons.circleExclamation;
    iconColor = Colors.amber;
  }

  return await Get.defaultDialog(
    title: "$title",
    content: Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          FaIcon(icon, size: 50.0, color: iconColor),
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 20),
            child: Align(alignment: Alignment.topLeft, child: Text(text, style: TextStyle(height: 1.5))),
          ),
          actionButton,
        ],
      ),
    ),
    backgroundColor: Colors.white,
    titleStyle: const TextStyle(color: Colors.black),
    middleTextStyle: const TextStyle(color: Colors.black),
  );
}

showLoading({text = 'Loading ...', dismissable = true}) {
  hideLoading();

  Get.defaultDialog(
    barrierDismissible: dismissable,
    title: "",
    middleText: "$text",
    backgroundColor: Colors.white,
    //titleStyle: const TextStyle(color: Colors.black),
    middleTextStyle: const TextStyle(color: Colors.white),
    // barrierDismissible: false,
    content: Column(children: [const SpinKitThreeInOut(color: Colors.red, size: 25), Text(text)]),
  );
}

hideLoading() {
  //debugPrint("${Get.isDialogOpen}");
  if (Get.isDialogOpen == true) {
    Get.back();
  }
}

Future<bool> appNeedUpdate({context}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  DateTime? datetime_stop_version_alert_until;
  String? stop_version_alert_until = prefs.getString('stop_version_alert_until');
  if (stop_version_alert_until != null) {
    debugPrint("STOP ALERT UNTIL: $datetime_stop_version_alert_until");
    datetime_stop_version_alert_until = DateTime.parse(stop_version_alert_until);
  }
  DateTime now = DateTime.now();
  final versionChecker = VersionChecker(managed: false);
  await versionChecker.checkVersion(context);
  bool needUpdate = versionChecker.hasUpdate;
  return needUpdate;
}

showVersionUpdateAlert({context}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  DateTime? datetime_stop_version_alert_until;
  String? stop_version_alert_until = prefs.getString('stop_version_alert_until');
  if (stop_version_alert_until != null) {
    debugPrint("STOP ALERT UNTIL: $datetime_stop_version_alert_until");
    datetime_stop_version_alert_until = DateTime.parse(stop_version_alert_until);
  }
  DateTime now = DateTime.now();

  if (datetime_stop_version_alert_until != null && datetime_stop_version_alert_until.compareTo(now) > 0) {
    // return;
  }

  final versionChecker = VersionChecker(managed: false);
  await versionChecker.checkVersion(context);
  bool needUpdate = versionChecker.hasUpdate;
  String? appStoreLink = versionChecker.storeUrl ?? '';
  String localVersion = versionChecker.packageVersion ?? '';
  String storeVersion = versionChecker.storeVersion ?? '';
  debugPrint("Local $localVersion ; Store $storeVersion");
  if (needUpdate) {
    //android using different dialog
    List<Widget> actionButtons = [];
    var isAndroid = Platform.isAndroid;
    if (isAndroid) {
      actionButtons = <Widget>[
        TextButton(
          child: const Text('Later', style: TextStyle(color: Colors.red)),
          onPressed: () async {
            DateTime stop_until = now.add(const Duration(days: 1));
            await prefs.setString('stop_version_alert_until', stop_until.toString());
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('App Gallery (Huawei)', style: TextStyle(color: Colors.blue)),
          onPressed: () async {
            var url = Constant.HUAWEI_APP_URL; //HUAWEI STORE URL FOR WAW
            var uri = Uri.parse(url);
            await canLaunchUrl(uri)
                ? await launchUrl(uri, mode: LaunchMode.externalApplication)
                : throw 'Could not launch $url';
          },
        ),
        TextButton(
          child: const Text('Play Store (Google Android)', style: TextStyle(color: Colors.blue)),
          onPressed: () async {
            var url = appStoreLink;
            var uri = Uri.parse(url);
            await canLaunchUrl(uri)
                ? await launchUrl(uri, mode: LaunchMode.externalApplication)
                : throw 'Could not launch $url';
          },
        ),
      ];
    } else {
      actionButtons = <Widget>[
        TextButton(
          child: const Text('Later', style: TextStyle(color: Colors.red)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Update', style: TextStyle(color: Colors.blue)),
          onPressed: () async {
            var url = appStoreLink;
            var uri = Uri.parse(url);
            await canLaunchUrl(uri)
                ? await launchUrl(uri, mode: LaunchMode.externalApplication)
                : throw 'Could not launch $url';
          },
        ),
      ];
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('App Update Available !'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'You can now update app from $localVersion to $storeVersion',
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
          actions: actionButtons,
        );
      },
    );
  }
}

laterVersionUpdateAlert() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  DateTime now = DateTime.now();
  DateTime stop_version_alert_until = now.add(const Duration(hours: 8));
  await prefs.setString('stop_version_alert_until', stop_version_alert_until.toString());
}

Widget futureLoading() {
  return const Center(child: CircularProgressIndicator(color: AppColors.blueDress));
}

Widget shimmerLoading({type = "full_page"}) {
  if (type == "full_page") {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      enabled: true,
      child: const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            BannerPlaceholder(),
            TitlePlaceholder(width: double.infinity),
            SizedBox(height: 16.0),
            ContentPlaceholder(lineType: ContentLineType.threeLines),
            SizedBox(height: 16.0),
            TitlePlaceholder(width: 200.0),
            SizedBox(height: 16.0),
            ContentPlaceholder(lineType: ContentLineType.twoLines),
            SizedBox(height: 16.0),
            TitlePlaceholder(width: 200.0),
            SizedBox(height: 16.0),
            ContentPlaceholder(lineType: ContentLineType.twoLines),
          ],
        ),
      ),
    );
  } else {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      enabled: true,
      child: const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [BannerPlaceholder()],
        ),
      ),
    );
  }
}

bool isBase64(String str) {
  try {
    final bytes = base64.decode(str);
    return true;
  } catch (e) {
    return false;
  }
}

ImageProvider getImageProviderByBase64(String empName, String? image64) {
  late Uint8List bytesImage;
  late String networkImageUrl;

  if (image64 != null && image64 != '') {
    bytesImage = base64.decode(image64);

    return MemoryImage(bytesImage);
  } else if (empName != '-') {
    empName = empName.toLowerCase();
    if (empName == 'admin') {
      empName = 'admin1';
    }
    networkImageUrl = "https://ui-avatars.com/api/?name=$empName&color=7F9CF5&background=EBF4FF";
    return NetworkImage(networkImageUrl);
  } else {
    return const AssetImage('assets/images/no_product.jpg');
  }
}

String appendQueryParameter(String url, String paramName, String paramValue) {
  Uri uri = Uri.parse(url);

  // Get the existing query parameters as a mutable map
  Map<String, List<String>> queryParams = Map.from(uri.queryParametersAll);

  // Add or update the new query parameter
  if (queryParams.containsKey(paramName)) {
    // If the parameter already exists, append the new value to its list
    queryParams[paramName]!.add(paramValue);
  } else {
    // If the parameter doesn't exist, create a new list with the new value
    queryParams[paramName] = [paramValue];
  }

  // Rebuild the URI with the updated query parameters
  Uri updatedUri = uri.replace(queryParameters: queryParams);

  return updatedUri.toString();
}

aLog(v) {
  var logger = Logger(printer: PrettyPrinter());
  logger.w(v);
  print("11111");
}

bool isScreenLessThan6Inches(BuildContext context) {
  // Get screen size in logical pixels
  var size = MediaQuery.of(context).size;
  double width = size.width;
  // aLog(width);
  if (width < 400) {
    return true;
  } else {
    return false;
  }
}

String convertDaysToYMD(dynamic totalDays) {
  // Try to parse if it's a String
  int? days;
  if (totalDays is String) {
    days = int.tryParse(totalDays);
  } else if (totalDays is int) {
    days = totalDays;
  }
  // Handle invalid inputs
  if (days == null) return 'Invalid input';

  int years = days ~/ 365;
  int remainingDaysAfterYears = days % 365;

  int months = remainingDaysAfterYears ~/ 30;
  int leftoverDays = remainingDaysAfterYears % 30;

  return '${years}y ${months}m ${leftoverDays}d';
}

Future<String?> getVersion() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  String packageVersion = packageInfo.version;
  return packageVersion;
}

String convertToAmPm(String? dateTimeStr) {
  if (dateTimeStr == null || dateTimeStr.isEmpty) return '-';

  try {
    final inputFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    final outputFormat = DateFormat("hh:mm a");

    final dateTime = inputFormat.parseStrict(dateTimeStr);
    return outputFormat.format(dateTime);
  } catch (e) {
    return '-';
  }
}

double? parseDoubleFromStringOrNum(dynamic value) {
  if (value == null) return null;
  if (value is String) return double.tryParse(value);
  if (value is num) return value.toDouble();
  return null;
}

DateTime? parseDateFromString(String input, {String format = 'yyyy-MM-dd'}) {
  try {
    if (input.trim().isEmpty) return null;

    // Try custom format first
    final formatter = DateFormat(format);
    return formatter.parseStrict(input.trim());
  } catch (e) {
    // Fallback: try default DateTime.parse for ISO formats
    try {
      return DateTime.parse(input.trim());
    } catch (_) {
      return null;
    }
  }
}

Future<bool> showConfirmationDialog({
  required BuildContext context,
  String title = "Confirm",
  String content = "Are you sure?",
  String cancelText = "Cancel",
  String confirmText = "Yes",
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(cancelText)),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(confirmText)),
          ],
        ),
  );

  return result == true;
}

bool isSuccessCode(int statusCode) {
  if (statusCode >= 200 && statusCode < 300) {
    // Covers 200, 201, 202, 204, etc.
    return true;
  } else {
    return false;
  }
}
