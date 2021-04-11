import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:bhaithamen/data/safe_place_data.dart';
import 'package:bhaithamen/data/user.dart';
import 'package:bhaithamen/screens/about.dart';
import 'package:bhaithamen/screens/custom_list_tile.dart';
import 'package:bhaithamen/screens/home.dart';
import 'package:bhaithamen/screens/map_places_wrapper.dart';
import 'package:bhaithamen/screens/map_top_menu.dart';
import 'package:bhaithamen/screens/map_wrapper.dart';
import 'package:bhaithamen/screens/news_wrapper.dart';
import 'package:bhaithamen/screens/place_full_details.dart';
import 'package:bhaithamen/screens/report_place.dart';
import 'package:bhaithamen/screens/settings_wrapper.dart';
import 'package:bhaithamen/screens/welfare_check.dart';
import 'package:bhaithamen/utilities/auto_page_navigation.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share/share.dart';
import 'package:top_modal_sheet/top_modal_sheet.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:lottie/lottie.dart' as lot;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';

class MapPlaces extends StatefulWidget {
  final User user;
  final FirebaseAnalyticsObserver observer;
  final FirebaseAnalytics analytics;
  MapPlaces(this.user, this.observer, this.analytics);
  @override
  _MapPlacesState createState() => _MapPlacesState(user, observer, analytics);
}

class _MapPlacesState extends State<MapPlaces> {
  _MapPlacesState(this.user, this.observer, this.analytics);

  Set<Marker> _markers = {};

  final _mapPlacesKey = GlobalKey<TopModalSheetState>();

  AutoHomePageWelfareSelect homePageWelfare;
  AutoPlaceCategorySelect autoSetCategory;
  AutoRating autoSetRating;

  Function modalUpdate;

  final FirebaseAnalyticsObserver observer;
  final FirebaseAnalytics analytics;
  final User user;
  String uid;
  String userName = '';
  String userPhone = '';
  String userEmail = '';
  String profilePic = '';

  bool ratingMode = true;

  bool firstTimeRating = true;

  StateSetter setTheModalState;

  int rating;
  int raters;
  int lastRating = 0;

  double overallRating;

  Map<dynamic, dynamic> safeplacesRatings = Map<dynamic, dynamic>();

  BitmapDescriptor toiletMarker;
  BitmapDescriptor pharmacyMarker;
  BitmapDescriptor doctorMarker;
  BitmapDescriptor clubMarker;
  BitmapDescriptor gymMarker;
  BitmapDescriptor shopMarker;
  BitmapDescriptor beautyMarker;
  BitmapDescriptor foodMarker;

  Map<String, BitmapDescriptor> myMarkers = {
    'toilet': null,
    'pharmacy': null,
    'doctor': null,
    'club': null,
    'gym': null,
    'shop': null,
    'beauty': null,
    'food': null
  };

  initState() {
    super.initState();
    setToiletCustomMarker();
    setPharmacyCustomMarker();
    setDoctorCustomMarker();
    setClubCustomMarker();
    setGymCustomMarker();
    setShopCustomMarker();
    setBeautyCustomMarker();
    setFoodCustomMarker();

    getCurrentUserInfo();
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

  getCurrentUserInfo() async {
    var firebaseuser = fbAuth.FirebaseAuth.instance.currentUser;
    DocumentSnapshot userDoc = await userCollection.doc(firebaseuser.uid).get();
    setState(() {
      uid = firebaseuser.uid;
      userName = userDoc['username'];
      userPhone = userDoc['userPhone'];
      userEmail = userDoc['email'];
      profilePic = userDoc['profilepic'];
      safeplacesRatings = userDoc['safeplaceRatings'];
    });
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

  FutureOr onGoBack(dynamic value) {
    getCurrentUserInfo();
    setState(() {});
  }

  void navigateSettings() {
    Route route = MaterialPageRoute(builder: (context) => SettingsWrapper());
    Navigator.push(context, route).then(onGoBack);
  }

  void navigateWelfare() {
    Route route = MaterialPageRoute(builder: (context) => WelfareCheck());
    Navigator.push(context, route);
  }

  afterBuild(context) {
    if (showWelfare) {
      if (!homePageWelfare.shouldGoWelfare) {
        homePageWelfare.setHomePageWelfare(true);
      }
    } else {
      if (homePageWelfare.shouldGoWelfare) {
        homePageWelfare.setHomePageWelfare(false);
      }
    }
  }

  setToiletCustomMarker() async {
    toiletMarker = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(), 'assets/pins/toilet.png');
    myMarkers['toilet'] = toiletMarker;
  }

  setDoctorCustomMarker() async {
    doctorMarker = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(), 'assets/pins/doctor.png');
    myMarkers['doctor'] = doctorMarker;
  }

  setPharmacyCustomMarker() async {
    pharmacyMarker = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(), 'assets/pins/pharmacy.png');
    myMarkers['pharmacy'] = pharmacyMarker;
  }

  setClubCustomMarker() async {
    clubMarker = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(), 'assets/images/club.png');
    myMarkers['club'] = clubMarker;
  }

  setGymCustomMarker() async {
    gymMarker = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(), 'assets/pins/gym.png');
    myMarkers['gym'] = gymMarker;
  }

  setFoodCustomMarker() async {
    foodMarker = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(), 'assets/pins/food.png');
    myMarkers['food'] = foodMarker;
  }

  setBeautyCustomMarker() async {
    beautyMarker = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(), 'assets/pins/beauty.png');
    myMarkers['beauty'] = beautyMarker;
  }

  setShopCustomMarker() async {
    shopMarker = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(), 'assets/pins/shop.png');
    myMarkers['shop'] = shopMarker;
  }

  Future<void> openMap(LatLng location) async {
    var geoMyLocation = await getUserLocation();

    double lat = geoMyLocation.latitude;
    double long = geoMyLocation.longitude;

    double latitude = location.latitude;
    double longitude = location.longitude;

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

  calculateRating(received, docId) async {
    int newRating = received.toInt();

    if (firstTimeRating) {
      firstTimeRating = false;
      raters++;
      rating = (rating + newRating);
    } else {
      rating = (rating + newRating) - lastRating;

      lastRating = newRating;
    }

    userCollection.doc(uid).set({
      "safeplaceRatings": {docId: newRating}
    }, SetOptions(merge: true));

    await safePlaceCollection
        .doc('dhaka')
        .collection(autoSetCategory.shouldGoCategory)
        .doc(docId)
        .update({'rating': rating, 'raters': raters});

    overallRating = rating / raters;
    setTheModalState(() {
      autoSetRating.setRating(overallRating);
    });
  }

  Future<bool> _onGiveRating(docId) async {
    DocumentSnapshot userDoc = await userCollection.doc(uid).get();

    safeplacesRatings = userDoc['safeplaceRatings'];

    if (safeplacesRatings.containsKey(docId)) {
      lastRating = safeplacesRatings[docId];
      firstTimeRating = false;
    } else {
      lastRating = 0;
      firstTimeRating = true;
    }

    int tempRating = lastRating;
    double displayRating = tempRating.toDouble();

    return showDialog(
        context: context,
        builder: (context) => new AlertDialog(
            title: new Text(
                languages[selectedLanguage[languageIndex]]['giveRating']),
            content: Container(
                height: 150,
                child: Center(
                      child: Column(
                        children: [
                          SmoothStarRating(
                              allowHalfRating: false,
                              onRated: (v) {
                                calculateRating(v, docId);
                              },
                              starCount: 5,
                              rating: displayRating,
                              size: 40.0,
                              isReadOnly: false,
                              filledIconData: Icons.star,
                              halfFilledIconData: Icons.star_half,
                              color: Colors.green,
                              borderColor: Colors.green,
                              spacing: 0.0),
                          SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Spacer(),
                              FlatButton(
                                child: Text(
                                    languages[selectedLanguage[languageIndex]]
                                        ['ok'],
                                    style: myStyle(22, Colors.white)),
                                textColor: Colors.white,
                                color: Colors.green,
                                onPressed: () async {
                                  setTheModalState(() {
                                    autoSetRating.setRating(overallRating);
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                              Spacer(),
                            ],
                          ),
                        ],
                      ),
                    ) ??
                    false)));
  }

  _sharePlace(name, details, location) async {
    double latitude = location.latitude;
    double longitude = location.longitude;

    String msg = userName +
        ' thought you might like to see this...' +
        '\n\n' +
        name +
        '\n\n' +
        details +
        '\n\n' +
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude' +
        '\n\n' +
        'Shared from Bhai Thamen https://bhaithamen.com';
    Share.share(msg, subject: 'Bhai Thamen');
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

  doShow(
      SafePlace theSafePlace,
      String nameEN,
      String nameBN,
      String detailsEN,
      String detailsBN,
      String price,
      String phone,
      LatLng location,
      images,
      docId) async {
    DocumentSnapshot placeDoc = await safePlaceCollection
        .doc('dhaka')
        .collection(autoSetCategory.shouldGoCategory)
        .doc(docId)
        .get();

    String details;
    String name;

    if (languageIndex == 0) {
      details = detailsEN;
      name = nameEN;
    } else {
      details = detailsBN;
      name = nameBN;
    }

    raters = placeDoc['raters'];
    rating = placeDoc['rating'];

    overallRating = rating / raters;

    autoSetRating.setRating(overallRating);

    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (BuildContext context,
              StateSetter setModalState /*You can rename this!*/) {
            this.setTheModalState = setModalState;
            return SizedBox(
              height: MediaQuery.of(context).size.height / 2,
              child: SingleChildScrollView(
                child: Center(
                  child: Column(children: [
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: AutoSizeText(name,
                              maxLines: 1,
                              style:
                                  myStyle(22, Colors.black, FontWeight.bold)),
                        ),
                        SizedBox(width: 12),
                        GestureDetector(
                            onTap: () {
                              _sharePlace(name, details, location);
                            },
                            child: Icon(Icons.share))
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        images.length > 0
                            ? SizedBox(
                                height: 120, child: Image.network(images[0]))
                            : Container(),
                        SizedBox(width: 15),
                        images.length > 1
                            ? SizedBox(
                                height: 120, child: Image.network(images[1]))
                            : Container(),
                        SizedBox(height: 22),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22.0, 10, 10, 10),
                      child: Linkify(
                        onOpen: _onOpen,
                        text: details,
                        style: myStyle(18),
                      ),
                    ),
                    SizedBox(height: 16),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        phone != ''
                            ? GestureDetector(
                                onTap: () {
                                  _launchCaller(phone);
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.phone),
                                    SizedBox(width: 8),
                                    Text(phone,
                                        style: myStyle(18, Colors.blue)),
                                  ],
                                ))
                            : Container(),
                        SizedBox(height: 18),
                        Text(
                            languages[selectedLanguage[languageIndex]]
                                    ['price'] +
                                ' ' +
                                languages[selectedLanguage[languageIndex]]
                                    [price.replaceAll(' ', '').toLowerCase()],
                            style: myStyle(18)),
                        SizedBox(height: 18),
                        InkWell(
                            onTap: () {
                              openMap(location);
                            },
                            child: Text(
                                languages[selectedLanguage[languageIndex]]
                                    ['getDirections'],
                                style: myStyle(18, Colors.blue)))
                      ],
                    ),
                    SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        _onGiveRating(docId);
                      },
                      child: SmoothStarRating(
                          allowHalfRating: true,
                          onRated: (v) {},
                          starCount: 5,
                          rating: autoSetRating.shouldGoRating,
                          size: 40.0,
                          isReadOnly: true,
                          filledIconData: Icons.star,
                          halfFilledIconData: Icons.star_half,
                          color: Colors.green,
                          borderColor: Colors.green,
                          spacing: 0.0),
                    ),
                    SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: Colors.grey[400])),
                        ),
                        child: InkWell(
                            splashColor: Colors.blueAccent,
                            onTap: () {
                              // Navigator.of(context).pop();

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => PlaceFullDetails(user,
                                        observer, analytics, theSafePlace)),
                              );
                            },
                            child: Container(
                              height: 40,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Icon(FontAwesomeIcons.list)),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                            languages[selectedLanguage[
                                                languageIndex]]['fullDetails'],
                                            style: myStyle(18)),
                                      )
                                    ],
                                  ),
                                  Icon(Icons.arrow_right),
                                ],
                              ),
                            )),
                      ),
                    ),
                    SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: Colors.grey[400])),
                        ),
                        child: InkWell(
                            splashColor: Colors.blueAccent,
                            onTap: () {
                              // Navigator.of(context).pop();

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ReportPlace(
                                        name,
                                        location,
                                        docId,
                                        autoSetCategory.shouldGoCategory)),
                              );
                            },
                            child: Container(
                              height: 40,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child:
                                              Icon(FontAwesomeIcons.pencilAlt)),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                            languages[selectedLanguage[
                                                    languageIndex]]
                                                ['reportPlaceBtn'],
                                            style: myStyle(18)),
                                      )
                                    ],
                                  ),
                                  Icon(Icons.arrow_right),
                                ],
                              ),
                            )),
                      ),
                    ),
                    SizedBox(height: 20),
                  ]),
                ),
              ),
            );
          });
        });
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

    final safePlaces = Provider.of<List<SafePlace>>(context);

    if (safePlaces != null) {
      _markers.clear();
      if (safePlaces.length > 0) {
        for (var i = 0; i < safePlaces.length; i++) {
          double lat = safePlaces[i].location.latitude;
          double lng = safePlaces[i].location.longitude;
          LatLng latLng = new LatLng(lat, lng);

          double rate = safePlaces[i].rating / safePlaces[i].raters;

          if (safePlaces[i].rating == 0 && safePlaces[i].raters == 0) {
            rate = 0;
          }

          String name;

          if (languageIndex == 0) {
            name = safePlaces[i].nameEN;
          } else {
            name = safePlaces[i].nameBN;
          }

          _markers.add(Marker(
              markerId: MarkerId(safePlaces[i].docId),
              position: latLng,
              onTap: () {
                doShow(
                    safePlaces[i],
                    safePlaces[i].nameEN,
                    safePlaces[i].nameBN,
                    safePlaces[i].detailsEN,
                    safePlaces[i].detailsBN,
                    safePlaces[i].price,
                    safePlaces[i].phone,
                    latLng,
                    safePlaces[i].images,
                    safePlaces[i].docId);
              },
              icon: myMarkers[safePlaces[i].category],
              infoWindow: InfoWindow(
                  title: name,
                  snippet: rate.toStringAsFixed(1) + ' out of 5')));
        }
      }
    }

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
            IconButton(
              icon: Icon(Icons.arrow_downward, size: 35),
              onPressed: () async {
                var value = await showTopModalSheet<String>(
                    context: context, child: MapTopMenu());

                if (value != null) {
                  autoSetCategory.setCategory(value);
                }
              },
            ),
          ]),
      key: _mapPlacesKey,
      drawer: Drawer(
          child: ListView(children: [
        DrawerHeader(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: <Color>[Colors.blue[700], Colors.blue[200]])),
          child: Container(
              child: Column(
            children: [
              Material(
                borderRadius: BorderRadius.all(Radius.circular(120.0)),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: profilePic == 'default'
                      ? Image.asset('assets/images/defaultAvatar.png',
                          height: 100, width: 100)
                      : CachedNetworkImage(
                          height: 70,
                          width: 70,
                          imageUrl: profilePic,
                          progressIndicatorBuilder:
                              (context, url, downloadProgress) => SizedBox(
                            height: 100,
                            child: Center(
                              child: CircularProgressIndicator(
                                  value: downloadProgress.progress),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 8, 2, 2),
                child: Text(userName,
                    style: myStyle(20, Colors.white, FontWeight.w300)),
              ),
            ],
          )),
        ),
        CustomListTile(
            languages[selectedLanguage[languageIndex]]['sideMenu1'],
            FontAwesomeIcons.newspaper,
            NewsWrapper(user, observer, analytics),
            false,
            false),
        CustomListTile(
            languages[selectedLanguage[languageIndex]]['sideMenu2'],
            FontAwesomeIcons.hardHat,
            Home(user, observer, analytics),
            false,
            false),
        CustomListTile(
            languages[selectedLanguage[languageIndex]]['sideMenu3'],
            FontAwesomeIcons.map,
            MapPlacesWrapper(user, observer, analytics),
            true,
            false),
        CustomListTile(languages[selectedLanguage[languageIndex]]['settings'],
            FontAwesomeIcons.cog, SettingsWrapper(), false, true),
        CustomListTile(
            languages[selectedLanguage[languageIndex]]['about'],
            FontAwesomeIcons.questionCircle,
            AboutPage(widget.user, observer, analytics),
            false,
            false),
      ])),
      body: Container(
        height: screenHeightExcludingToolbar(context, dividedBy: 1.05),
        child: GoogleMap(
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomGesturesEnabled: true,
          initialCameraPosition: CameraPosition(
            target: LatLng(23.8103, 90.4125),
            zoom: 15.0,
          ),
          //circles: Set<Circle>.of(circles.values),
          markers: _markers,
          //markers: Set.of((marker != null) ? [marker] : []),
          //onMapCreated: _onMapCreated,
          // onLongPress: (LatLng pos) {
          //   setState(() {
          //     _lastLongPress = pos;
          //     _add(pos, false, '', 100);
          //   });
          // },
        ),
      ),
    );
  }
}
