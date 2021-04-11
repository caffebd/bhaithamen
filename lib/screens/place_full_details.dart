import 'package:auto_size_text/auto_size_text.dart';
import 'package:bhaithamen/data/safe_place_data.dart';
import 'package:bhaithamen/screens/home.dart';
import 'package:bhaithamen/screens/map_wrapper.dart';
import 'package:bhaithamen/screens/welfare_check.dart';
import 'package:bhaithamen/utilities/auto_page_navigation.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:latlong/latlong.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart' as lot;
import 'package:bhaithamen/data/user.dart' as theUser;
import 'package:url_launcher/url_launcher.dart';
import 'package:bhaithamen/screens/news_wrapper.dart';

class PlaceFullDetails extends StatefulWidget {
  final theUser.User user;
  final FirebaseAnalyticsObserver observer;
  final FirebaseAnalytics analytics;
  final SafePlace safeData;
  PlaceFullDetails(this.user, this.observer, this.analytics, this.safeData);
  @override
  _PlaceFullDetailsState createState() =>
      _PlaceFullDetailsState(user, observer, analytics, safeData);
}

class _PlaceFullDetailsState extends State<PlaceFullDetails> {
  _PlaceFullDetailsState(
      this.user, this.observer, this.analytics, this.safeData);

  AutoHomePageWelfareSelect homePageWelfare;
  AutoPlaceCategorySelect autoSetCategory;
  AutoRating autoSetRating;

  final FirebaseAnalyticsObserver observer;
  final FirebaseAnalytics analytics;
  final theUser.User user;

  String name;
  String details;
  String locationDesc;
  String type;
  List<dynamic> facilities;

  final SafePlace safeData;

  List<Widget> imageSliders;

  LatLng latLng;

  @override
  void initState() {
    super.initState();
    setUpSlider();
    pickLanguage();
  }

  pickLanguage() {
    if (languageIndex == 0) {
      name = safeData.nameEN;
      details = safeData.detailsEN;
      locationDesc = safeData.locationDescEN;
      type = safeData.typeEN;
      facilities = List.from(safeData.facilitiesEN);
    } else {
      name = safeData.nameBN;
      details = safeData.detailsBN;
      locationDesc = safeData.locationDescBN;
      type = safeData.typeBN;
      facilities = List.from(safeData.facilitiesBN);
    }
    double lat = safeData.location.latitude;
    double lng = safeData.location.longitude;
    latLng = new LatLng(lat, lng);

    print(locationDesc);
    print(type);
    print(facilities[0]);
    print(details);
    print(name);
  }

  setUpSlider() {
    imageSliders = safeData.images
        .map((item) => Container(
              child: Container(
                margin: EdgeInsets.all(5.0),
                child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    child: Stack(
                      children: <Widget>[
                        Image.network(item, fit: BoxFit.cover, height: 1000.0),
                        Positioned(
                          bottom: 0.0,
                          left: 0.0,
                          right: 0.0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color.fromARGB(200, 0, 0, 0),
                                  Color.fromARGB(0, 0, 0, 0)
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 20.0),
                            child: Container(),
                            // Text(
                            //   'No. ${widget.userArticle.images.indexOf(item)} image',
                            //   style: TextStyle(
                            //     color: Colors.white,
                            //     fontSize: 20.0,
                            //     fontWeight: FontWeight.bold,
                            //   ),
                            // ),
                          ),
                        ),
                      ],
                    )),
              ),
            ))
        .toList();
  }

  void navigateWelfare() {
    Route route = MaterialPageRoute(builder: (context) => WelfareCheck());
    Navigator.push(context, route);
  }

  Size screenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  double screenHeight(BuildContext context,
      {double dividedBy = 1, double reducedBy = 0.0}) {
    return (screenSize(context).height - reducedBy) / dividedBy;
  }

  double screenHeightExcludingToolbar(BuildContext context,
      {double dividedBy = 1}) {
    return screenHeight(context,
        dividedBy: dividedBy, reducedBy: kToolbarHeight);
  }

  Future<void> _onOpen(LinkableElement link) async {
    if (await canLaunch(link.url)) {
      await launch(link.url);
    } else {
      throw 'Could not launch $link';
    }
  }

  _launchCaller(String number) async {
    var url = "tel:" + number;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future getUserLocation() async {
    myLocationData = await location.getLocation();

    GeoPoint loc;

    if (myLocationData != null) {
      loc = GeoPoint(myLocationData.latitude, myLocationData.longitude);
    } else {
      loc = GeoPoint(90.0000, 135.0000);
    }

    if (loc == null) {
      loc = GeoPoint(90.0000, 135.0000);
    }

    return loc;
  }

  Future<void> openMap() async {
    var geoMyLocation = await getUserLocation();

    double lat = geoMyLocation.latitude;
    double long = geoMyLocation.longitude;

    double latitude = latLng.latitude;
    double longitude = latLng.longitude;

    var url =
        'https://www.google.com/maps/dir/?api=1&origin=$lat,$long&destination=$latitude,$longitude';

    String googleUrl = url;
    //'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(googleUrl)) {
      await launch(googleUrl);
    } else {
      throw 'Could not open the map.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final AutoHomePageMapSelect homePageMap =
        Provider.of<AutoHomePageMapSelect>(context);
    final AutoHomePageAskSelect homePageAsk =
        Provider.of<AutoHomePageAskSelect>(context);
    homePageWelfare = Provider.of<AutoHomePageWelfareSelect>(context);
    Provider.of<AutoHomePageAskSelect>(context);

    autoSetRating = Provider.of<AutoRating>(context);

    autoSetCategory = Provider.of<AutoPlaceCategorySelect>(context);

    final SafePageIndex safePageIndex = Provider.of<SafePageIndex>(context);

    globalContext = context;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
          centerTitle: true,
          title: testModeToggle
              ? Text(languages[selectedLanguage[languageIndex]]['testOn'],
                  style: myStyle(18, Colors.white))
              : Text(languages[selectedLanguage[languageIndex]]['title'],
                  style: myStyle(18, Colors.white)),
          backgroundColor: testModeToggle ? Colors.red : Colors.blue,
          actions: <Widget>[
            if (homePageMap.shouldGoMap)
              FlatButton(
                  child: lot.Lottie.asset('assets/lottie/alert.json'),
                  onPressed: () {
                    setState(() {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapWrapper(),
                        ),
                      );
                      //homePageIndex = 1; safePageIndex.setSafePageIndex(0);savedSafeIndex=0;homePageMap.setHomePageMap(false);
                    });
                  }),
            if (homePageAsk.shouldGoAsk)
              FlatButton(
                  child: lot.Lottie.asset('assets/lottie/alert.json'),
                  onPressed: () {
                    setState(() {
                      homePageIndex = 2;
                      safePageIndex.setSafePageIndex(0);
                      savedSafeIndex = 0;
                      homePageAsk.setHomePageAsk(false);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                Home(user, observer, analytics)),
                      );
                    });
                  }),
            if (homePageWelfare.shouldGoWelfare)
              FlatButton(
                  child: lot.Lottie.asset('assets/lottie/alert.json'),
                  onPressed: () {
                    navigateWelfare();
                  }),
          ]),
      body: Container(
        height: screenHeightExcludingToolbar(context, dividedBy: 1.05),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 15),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: AutoSizeText(name,
                      maxLines: 1,
                      style: myStyle(20, Colors.black, FontWeight.bold),
                      textAlign: TextAlign.center),
                ),
                SizedBox(height: 15),
                safeData.images.length == 0
                    ? Container()
                    : Column(
                        children: <Widget>[
                          CarouselSlider(
                            options: CarouselOptions(
                              autoPlay: true,
                              aspectRatio: 1.5,
                              enlargeCenterPage: true,
                            ),
                            items: imageSliders,
                          ),
                        ],
                      ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 10, 20, 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Center(
                              child: Text(
                                locationDesc,
                                style: myStyle(16),
                                maxLines: 3,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      InkWell(
                          onTap: () {
                            openMap();
                          },
                          child: Text(
                              languages[selectedLanguage[languageIndex]]
                                  ['getDirections'],
                              style: myStyle(16, Colors.blue))),
                      SizedBox(height: 18),
                      Text(
                        details,
                        style: myStyle(16),
                        maxLines: 3,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 18),
                      for (var i = 0; i < facilities.length; i++)
                        Text(
                          facilities[i].toString(),
                          style: myStyle(16),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        ),
                      SizedBox(height: 18),
                      Text(
                          languages[selectedLanguage[languageIndex]]['price'] +
                              ' ' +
                              languages[selectedLanguage[languageIndex]][
                                  safeData.price
                                      .replaceAll(' ', '')
                                      .toLowerCase()],
                          style: myStyle(18)),
                      SizedBox(height: 12),
                      safeData.phone != ''
                          ? GestureDetector(
                              onTap: () {
                                _launchCaller(safeData.phone);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.phone),
                                  SizedBox(width: 8),
                                  Text(safeData.phone,
                                      style: myStyle(18, Colors.blue)),
                                ],
                              ))
                          : Container(),
                      SizedBox(height: 12),
                      safeData.website != ''
                          ? Linkify(
                              onOpen: _onOpen,
                              text: safeData.website,
                              style: myStyle(18),
                            )
                          : Container(),
                      SizedBox(height: 12),
                      safeData.social != ''
                          ? Linkify(
                              onOpen: _onOpen,
                              text: safeData.social,
                              style: myStyle(18),
                            )
                          : Container(),
                      SizedBox(height: 22),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
