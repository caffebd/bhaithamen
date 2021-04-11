import 'dart:async';

import 'package:bhaithamen/data/userData.dart';
import 'package:bhaithamen/screens/mapping.dart';
import 'package:bhaithamen/screens/settings_wrapper.dart';
import 'package:bhaithamen/utilities/auth.dart';
import 'package:bhaithamen/utilities/auto_page_navigation.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class MapWrapper extends StatefulWidget {
  @override
  _MapWrapperState createState() => _MapWrapperState();
}

class _MapWrapperState extends State<MapWrapper> {
  String uid;

  initState() {
    super.initState();
    getCurrentUserUID();
  }

  getCurrentUserUID() async {
    var firebaseuser = FirebaseAuth.instance.currentUser;
    setState(() {
      uid = firebaseuser.uid;
    });
  }

  FutureOr onGoBack(dynamic value) {
    setState(() {});
  }

  void navigateSettings() {
    Route route = MaterialPageRoute(builder: (context) => SettingsWrapper());
    Navigator.push(context, route).then(onGoBack);
  }

  @override
  Widget build(BuildContext context) {
    final AutoHomePageAskSelect homePageAsk =
        Provider.of<AutoHomePageAskSelect>(context);
    final SafePageIndex safePageIndex = Provider.of<SafePageIndex>(context);

    return MultiProvider(
      providers: [
        StreamProvider<UserData>.value(value: AuthService(uid: uid).userData),
      ],
      child: Scaffold(
        appBar: AppBar(
            centerTitle: true,
            title: testModeToggle
                ? Text(languages[selectedLanguage[languageIndex]]['testOn'],
                    style: myStyle(18, Colors.white))
                : Text(languages[selectedLanguage[languageIndex]]['title'],
                    style: myStyle(18, Colors.white)),
            backgroundColor: testModeToggle ? Colors.red : Colors.blue,
            actions: <Widget>[
              //if (homePageMap.shouldGoMap) FlatButton(child: Lottie.asset('assets/lottie/alert.json'), onPressed: (){ setState(() {homePageIndex = 1; safePageIndex.setSafePageIndex(0);savedSafeIndex=0;homePageMap.setHomePageMap(false);});}),
              if (homePageAsk.shouldGoAsk)
                FlatButton(
                    child: Lottie.asset('assets/lottie/alert.json'),
                    onPressed: () {
                      setState(() {
                        homePageIndex = 2;
                        safePageIndex.setSafePageIndex(0);
                        savedSafeIndex = 0;
                        homePageAsk.setHomePageAsk(false);
                        Navigator.pop(context);
                      });
                    }),
              // if (homePageMap.shouldGoMap)
              // FlatButton(
              //   child: Lottie.asset('assets/lottie/alert.json'),
              //   onPressed: (){ setState(() {
              //   Navigator.push(
              //           context,
              //           MaterialPageRoute(
              //             builder: (context) => MapWrapper(),
              //           ),
              //         );
              //     //homePageIndex = 1; safePageIndex.setSafePageIndex(0);savedSafeIndex=0;homePageMap.setHomePageMap(false);
              //     });
              //     }) ,
              IconButton(
                  icon: Icon(Icons.settings, size: 35),
                  onPressed: () {
                    navigateSettings();
                  }),
            ]),
        //key: _scaffoldKeyHome,
        body: Center(
          child: Mapping(),
        ),
      ),
    );
  }
}
