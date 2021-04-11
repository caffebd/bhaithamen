import 'dart:async';

import 'package:bhaithamen/data/user.dart';
import 'package:bhaithamen/screens/welfare_check.dart';
import 'package:bhaithamen/screens/wrapper.dart';
import 'package:bhaithamen/utilities/analytics_service.dart';
import 'package:bhaithamen/utilities/auth.dart';
import 'package:bhaithamen/utilities/auto_page_navigation.dart';
import 'package:bhaithamen/utilities/fb_test.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/report_event.dart';
import 'package:bhaithamen/utilities/variables.dart' as myVars;
import 'package:bhaithamen/utilities/variables.dart';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  var initializationSettingsIOS = IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification:
          (int id, String title, String body, String payload) async {});
  var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String payload) async {
    if (payload != null) {
      debugPrint('notification payload nEW: ' + payload);
    }
    Navigator.push(
      globalContext,
      MaterialPageRoute(
        builder: (context) => WelfareCheck(),
      ),
    );
  });

  runApp(
    ChangeNotifierProvider(
      create: (context) => PinRequired(myVars.needThePin),
      child: MyApp(),
    ),
  );

  //runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final localAuth = LocalAuthentication();

  static FirebaseAnalytics analytics = FirebaseAnalytics();
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  final analyticsHelper = AnalyticsService();

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  bool needUnlock;
  dynamic pinProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    needUnlock = false;
    String theDate = getDate().toString();
    analyticsHelper.sendAnalyticsEvent('App_Opened', param: theDate);
    sendResearchReport('App_Opened');
    initLanguage();
  }

  initLanguage() async {
    final SharedPreferences prefs = await _prefs;
    languageIndex = prefs.getInt('languageIndex');
    if (languageIndex == null) {
      languageIndex = 1;
    }

    myVars.usePincode = prefs.getBool('pincode');
    if (myVars.usePincode == null) {
      myVars.usePincode = false;
    }

    secretRecordSendSMS = prefs.getBool('secretSMS');
    if (secretRecordSendSMS == null) {
      secretRecordSendSMS = true;
    }

    secretRecordCover = prefs.getBool('secretDummy');
    if (secretRecordCover == null) {
      secretRecordCover = false;
    }

    challengeRecordSendSMS = prefs.getBool('challengeSMS');
    if (challengeRecordSendSMS == null) {
      challengeRecordSendSMS = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    myVars.stateNotification = state;

    switch (state) {
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.inactive:
        print('MAIN state notifi ' + myVars.stateNotification.toString());

        break;
      case AppLifecycleState.detached:
        print('state notifi ' + myVars.stateNotification.toString());

        break;
    }
  }

  Future<bool> awaitGone() async {
    return new Future.delayed(const Duration(milliseconds: 200), () => false);
  }

  Future<bool> awaitStarted() async {
    return new Future.delayed(const Duration(seconds: 8), () => true);
  }

  setToTrue() async {
    myVars.appHasStarted = await awaitStarted();
  }

  @override
  Widget build(BuildContext context) {
    if (checkAuth == 'false') {}

    FirebaseAnalytics analytics = FirebaseAnalytics();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    return MultiProvider(
      providers: [
        StreamProvider<User>.value(value: AuthService().user),
        ChangeNotifierProvider<AutoRating>.value(value: AutoRating(0)),
        ChangeNotifierProvider<AutoHomePageMapSelect>.value(
            value: AutoHomePageMapSelect(myVars.savedShouldGoMap)),
        ChangeNotifierProvider<AutoHomePageAskSelect>.value(
            value: AutoHomePageAskSelect(myVars.savedShouldGoAsk)),
        ChangeNotifierProvider<AutoHomePageWelfareSelect>.value(
            value: AutoHomePageWelfareSelect(myVars.savedShouldGoWelfare)),

        ChangeNotifierProvider<AutoPlaceCategorySelect>.value(
            value: AutoPlaceCategorySelect(myVars.safePlaceCategory)),
        //ChangeNotifierProvider<PinRequired>.value(value : PinRequired(pinNeeded)),
        ChangeNotifierProvider<SafePageIndex>.value(
            value: SafePageIndex(myVars.savedSafeIndex)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Wrapper(
          analytics: analytics,
          observer: observer,
        ),
        navigatorObservers: [
          FirebaseAnalyticsObserver(analytics: analytics),
        ],
      ),
    );
  }
}
