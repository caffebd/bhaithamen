import 'package:bhaithamen/data/user.dart';
import 'package:bhaithamen/screens/login.dart';
import 'package:bhaithamen/screens/news_wrapper.dart';
import 'package:bhaithamen/utilities/auto_page_navigation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatefulWidget {
  Wrapper({this.analytics, this.observer});

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;
  @override
  _WrapperState createState() => _WrapperState(analytics, observer);
}

class _WrapperState extends State<Wrapper> with WidgetsBindingObserver {
  _WrapperState(this.analytics, this.observer);

  final FirebaseAnalyticsObserver observer;
  final FirebaseAnalytics analytics;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User>(context);

    if (user == null) {
      return Login();
    } else {
      return NewsWrapper(user, observer, analytics);
    }
  }
}
