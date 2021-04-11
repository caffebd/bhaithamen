import 'package:bhaithamen/data/safe_place_data.dart';
import 'package:bhaithamen/data/user.dart';
import 'package:bhaithamen/screens/map_places.dart';
import 'package:bhaithamen/utilities/auth.dart';
import 'package:bhaithamen/utilities/auto_page_navigation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MapPlacesWrapper extends StatefulWidget {
  final User user;
  final FirebaseAnalyticsObserver observer;
  final FirebaseAnalytics analytics;
  MapPlacesWrapper(this.user, this.observer, this.analytics);

  @override
  _MapPlacesWrapperState createState() =>
      _MapPlacesWrapperState(user, observer, analytics);
}

class _MapPlacesWrapperState extends State<MapPlacesWrapper> {
  _MapPlacesWrapperState(this.user, this.observer, this.analytics);

  final FirebaseAnalyticsObserver observer;
  final FirebaseAnalytics analytics;
  final User user;

  @override
  Widget build(BuildContext context) {
    final AutoPlaceCategorySelect placeCategory =
        Provider.of<AutoPlaceCategorySelect>(context);

    return MultiProvider(providers: [
      StreamProvider<List<SafePlace>>.value(
          value: AuthService(
                  place: 'dhaka', category: placeCategory.shouldGoCategory)
              .getSafePlaces),
    ], child: MapPlaces(user, observer, analytics));
  }
}
