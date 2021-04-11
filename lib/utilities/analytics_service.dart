import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';

class AnalyticsService {
  static FirebaseAnalytics analytics = FirebaseAnalytics();
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  Future<void> testSetCurrentScreen(String screenName) async {
    await analytics
        .setCurrentScreen(
          screenName: screenName,
          screenClassOverride: screenName,
        )
        .whenComplete(() => print('ANA DONE'));
    analytics.logEvent(name: screenName);
  }

  Future<void> sendAnalyticsEvent(String name, {String param = 'n/a'}) async {
    await analytics.logEvent(
      name: name,
      parameters: <String, dynamic>{'string': param},
    );
  }
}
