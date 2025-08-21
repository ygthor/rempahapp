import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:kanesanapp/features/init_page.dart';
import 'package:kanesanapp/models/global_state.dart';

import 'shared/ui.dart';

StreamSubscription<ConnectivityResult>? connectivitySubscription;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Get.put(GlobalState());

  GlobalState gs = Get.find();
  gs.init();
  startGlobalConnectivityListener();

  runApp(MyApp());
}

//theme color -----primarySwatch only allow materialcolor
MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  final swatch = <int, Color>{};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}

class MyApp extends StatelessWidget {
  // final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // _firebaseMessaging.setForegroundNotificationPresentationOptions(
    //   alert: true,
    //   badge: true,
    //   sound: true,
    // );
    // Get the initial MediaQueryData
    final mediaQueryData = MediaQuery.of(context);

    // Create a new MediaQueryData with textScaler set to noScaling
    final newMediaQueryData = mediaQueryData.copyWith(
      textScaler: TextScaler.noScaling,
      // It's crucial to use copyWith to preserve other important
      // media query data like screen size, padding, orientation, etc.
    );
    ResponsiveFontSize.init(context);

    return MediaQuery(
      data: newMediaQueryData,
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: createMaterialColor(const Color(0xFFFAFAFA)),
          // colorScheme: ColorScheme.fromSwatch().copyWith(
          //   primary: Color(0xFF8F0100),
          //   secondary: Color(0xFFFFFFFF),
          // ),
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: Colors.black,
            selectionHandleColor: Colors.blue,
            selectionColor: Colors.grey,
          ),
        ),
        home: const InitPage(),

        //FOR form_builder use
        supportedLocales: const [Locale('en')],
        // localizationsDelegates: const [
        //   FormBuilderLocalizations.delegate,
        // ],
      ),
    );
  }
}

void startGlobalConnectivityListener() {
  StreamSubscription<List<ConnectivityResult>> subscription = Connectivity().onConnectivityChanged.listen((
    List<ConnectivityResult> result,
  ) {
    GlobalState gs = Get.find();
    if (result != ConnectivityResult.none) {
      print('Network is back!');
      gs.setNetworkStatus(true);
    } else {
      print('No internet');
      gs.setNetworkStatus(false);
    }
  });
}

void disposeGlobalConnectivityListener() {
  connectivitySubscription?.cancel();
}
