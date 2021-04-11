import 'dart:async';

import 'package:bhaithamen/data/user.dart';
import 'package:bhaithamen/screens/custom_list_tile.dart';
import 'package:bhaithamen/screens/home.dart';
import 'package:bhaithamen/screens/map_places_wrapper.dart';
import 'package:bhaithamen/screens/map_wrapper.dart';
import 'package:bhaithamen/screens/news_wrapper.dart';
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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  final User user;
  final FirebaseAnalyticsObserver observer;
  final FirebaseAnalytics analytics;
  AboutPage(this.user, this.observer, this.analytics);
  @override
  _AboutPageState createState() => _AboutPageState(user, observer, analytics);
}

class _AboutPageState extends State<AboutPage> {
  _AboutPageState(this.theUser, this.observer, this.analytics);

  final FirebaseAnalyticsObserver observer;
  final FirebaseAnalytics analytics;

  AutoHomePageWelfareSelect homePageWelfare;

  User theUser;

  String userName = '';
  String profilePic = '';

  @override
  void initState() {
    super.initState();

    getCurrentUserInfo();
  }

  FutureOr onGoBack(dynamic value) {
    getCurrentUserInfo();
    setState(() {});
  }

  getCurrentUserInfo() async {
    var firebaseuser = fbAuth.FirebaseAuth.instance.currentUser;
    DocumentSnapshot userDoc = await userCollection.doc(firebaseuser.uid).get();
    setState(() {
      userName = userDoc['username'];
      profilePic = userDoc['profilepic'];
    });
  }

  void navigateSettings() {
    Route route = MaterialPageRoute(builder: (context) => SettingsWrapper());
    Navigator.push(context, route).then(onGoBack);
  }

  void navigateWelfare() {
    Route route = MaterialPageRoute(builder: (context) => WelfareCheck());
    Navigator.push(context, route).then(onGoBack);
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

  Future<void> _onOpen(String link) async {
    if (await canLaunch(link)) {
      await launch(link);
    } else {
      throw 'Could not launch $link';
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => afterBuild(context));
    final AutoHomePageMapSelect homePageMap =
        Provider.of<AutoHomePageMapSelect>(context);
    final AutoHomePageAskSelect homePageAsk =
        Provider.of<AutoHomePageAskSelect>(context);
    homePageWelfare = Provider.of<AutoHomePageWelfareSelect>(context);
    final SafePageIndex safePageIndex = Provider.of<SafePageIndex>(context);

    print('home user ' + widget.user.uid);

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
                    child: Lottie.asset('assets/lottie/alert.json'),
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
                    child: Lottie.asset('assets/lottie/alert.json'),
                    onPressed: () {
                      setState(() {
                        homePageIndex = 2;
                        safePageIndex.setSafePageIndex(0);
                        savedSafeIndex = 0;
                        homePageAsk.setHomePageAsk(false);
                      });
                    }),
              if (homePageWelfare.shouldGoWelfare)
                FlatButton(
                    child: Lottie.asset('assets/lottie/alert.json'),
                    onPressed: () {
                      navigateWelfare();
                    }),
              // IconButton(
              //     icon: Icon(Icons.settings, size: 35),
              //     onPressed: () {
              //       navigateSettings();
              //     }),
            ]),
        //will show the widget (page) depending on which button was pressed

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
              NewsWrapper(theUser, observer, analytics),
              false,
              false),
          CustomListTile(
              languages[selectedLanguage[languageIndex]]['sideMenu2'],
              FontAwesomeIcons.hardHat,
              Home(theUser, observer, analytics),
              false,
              false),
          CustomListTile(
              languages[selectedLanguage[languageIndex]]['sideMenu3'],
              FontAwesomeIcons.map,
              MapPlacesWrapper(theUser, observer, analytics),
              false,
              false),
          CustomListTile(languages[selectedLanguage[languageIndex]]['settings'],
              FontAwesomeIcons.cog, SettingsWrapper(), false, true),
          CustomListTile(
              languages[selectedLanguage[languageIndex]]['about'],
              FontAwesomeIcons.questionCircle,
              AboutPage(theUser, observer, analytics),
              true,
              false),
        ])),
        body: Column(
          children: <Widget>[
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                  SingleChildScrollView(
                      child: Column(children: [
                    Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: 15),
                            Text(
                                languages[selectedLanguage[languageIndex]]
                                    ['aboutTitle'],
                                style:
                                    myStyle(20, Colors.black, FontWeight.bold)),
                            SizedBox(height: 5),
                            Padding(
                              padding: const EdgeInsets.all(26.0),
                              child: Text(
                                  languages[selectedLanguage[languageIndex]]
                                      ['aboutDetails'],
                                  style: myStyle(
                                      14, Colors.grey[800], FontWeight.w400)),
                            ),
                            SizedBox(height: 8),
                            Text(
                                languages[selectedLanguage[languageIndex]]
                                    ['aboutPartners'],
                                style:
                                    myStyle(18, Colors.black, FontWeight.w500)),
                            SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GestureDetector(
                                  onTap: () {
                                    _onOpen(
                                        'https://www.bracu.ac.bd/academics/institutes-and-schools/jpgsph');
                                  },
                                  child: Image.asset(
                                      'assets/logos/bracHealthLogo.png')),
                            ),
                            SizedBox(height: 22),
                            Row(children: [
                              Spacer(),
                              SizedBox(
                                  height: 80,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: GestureDetector(
                                        onTap: () {
                                          _onOpen('https://creaworld.org/');
                                        },
                                        child: Image.asset(
                                            'assets/logos/creaLogo.png')),
                                  )),
                              Spacer(),
                              SizedBox(
                                  height: 80,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: GestureDetector(
                                        onTap: () {
                                          _onOpen(
                                              'https://thetechacademy.net/');
                                        },
                                        child: Image.asset(
                                            'assets/logos/taLogo.png')),
                                  )),
                              Spacer(),
                              SizedBox(
                                  height: 80,
                                  child: GestureDetector(
                                      onTap: () {
                                        _onOpen('https://creatorlab.club/');
                                      },
                                      child: Image.asset(
                                          'assets/logos/clLogo.png'))),
                              Spacer(),
                            ]),
                          ]),
                    )
                  ])),
                ])),
            Divider(
                height: 5, color: Colors.grey[700], indent: 15, endIndent: 15),
            Container(
              padding: EdgeInsets.all(8.0),
              child: Row(children: [
                Spacer(),
                GestureDetector(
                    onTap: () {
                      _onOpen('https://bhaithamen.com/');
                    },
                    child: Icon(Icons.language, size: 40, color: Colors.blue)),
                Spacer(),
                GestureDetector(
                    onTap: () {
                      _onOpen('https://www.facebook.com/bhaithamenbd');
                    },
                    child: Icon(FontAwesomeIcons.facebook,
                        size: 40, color: Colors.blue)),
                Spacer(),
              ]),
            ),
          ],
        ));
  }
}
