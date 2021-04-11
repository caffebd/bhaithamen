import 'package:bhaithamen/utilities/auto_page_navigation.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/report_event.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:toggle_switch/toggle_switch.dart';

class WelfareCheck extends StatefulWidget {
  @override
  _WelfareCheckState createState() => _WelfareCheckState();
}

class _WelfareCheckState extends State<WelfareCheck> {
  String myUid;
  String myUsername;
  String myPhoneNumber;
  bool needHelp = false;
  bool needReport = false;

  SafePageIndex safePageIndex;
  AutoHomePageAskSelect homePageAsk;

  @override
  void initState() {
    super.initState();
    getCurrentUserInfo();
    showWelfare = false;
  }

  getCurrentUserInfo() async {
    var firebaseuser = FirebaseAuth.instance.currentUser;
    DocumentSnapshot userDoc = await userCollection.doc(firebaseuser.uid).get();
    setState(() {
      myUid = firebaseuser.uid;
      myUsername = userDoc['username'];
      myPhoneNumber = userDoc['userPhone'];
    });
  }

  _submitted() async {
    if (needHelp == true) sendEvent('welfare', 'welfare-check');

    if (needReport) {
      setState(() {
        homePageIndex = 0;
        sosPageIndex = 1;
        safePageIndex.setSafePageIndex(0);
        savedSafeIndex = 0;
        homePageAsk.setHomePageAsk(false);
        Navigator.of(context).pop();
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    safePageIndex = Provider.of<SafePageIndex>(context);
    homePageAsk = Provider.of<AutoHomePageAskSelect>(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        actions: <Widget>[
          // Padding(
          //   padding: const EdgeInsets.all(8.0),
          //   child: FlatButton(
          //     child: Image.asset('assets/images/cross.png'),
          //     onPressed: () {},
          //   ),
          // ),
        ],
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 25),
            Text(
              languages[selectedLanguage[languageIndex]]['welfareCheckTitle'],
              style: myStyle(26, Colors.black, FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 25),
            Text(
              languages[selectedLanguage[languageIndex]]
                  ['welfareCheckSubTitle'],
              style: myStyle(20),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 45),
            Text(
              languages[selectedLanguage[languageIndex]]['welfareCheckQ1'],
              style: myStyle(22),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 25),
            Container(
              child: ToggleSwitch(
                minWidth: 90.0,
                cornerRadius: 20.0,
                activeBgColor: Colors.green[300],
                activeFgColor: Colors.white,
                inactiveBgColor: Colors.grey,
                inactiveFgColor: Colors.white,
                labels: [
                  languages[selectedLanguage[languageIndex]]['no']
                      .toUpperCase(),
                  languages[selectedLanguage[languageIndex]]['yes']
                      .toUpperCase(),
                ],
                icons: [FontAwesomeIcons.times, FontAwesomeIcons.check],
                onToggle: (index) {
                  if (index == 0) {
                    needHelp = false;
                  } else {
                    needHelp = true;
                  }
                  print('switched to: $needHelp');
                },
              ),
            ),
            SizedBox(height: 45),
            Text(
              languages[selectedLanguage[languageIndex]]['welfareCheckQ2'],
              style: myStyle(22),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 25),
            Container(
              child: ToggleSwitch(
                minWidth: 90.0,
                cornerRadius: 20.0,
                activeBgColor: Colors.green[300],
                activeFgColor: Colors.white,
                inactiveBgColor: Colors.grey,
                inactiveFgColor: Colors.white,
                labels: [
                  languages[selectedLanguage[languageIndex]]['no']
                      .toUpperCase(),
                  languages[selectedLanguage[languageIndex]]['yes']
                      .toUpperCase(),
                ],
                icons: [FontAwesomeIcons.times, FontAwesomeIcons.check],
                onToggle: (index) {
                  if (index == 0) {
                    needReport = false;
                  } else {
                    needReport = true;
                  }
                },
              ),
            ),
            SizedBox(height: 50),
            FlatButton(
                onPressed: () {
                  _submitted();
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                color: Colors.blue,
                child: Text(
                  languages[selectedLanguage[languageIndex]]['submitBtn'],
                  style: myStyle(30, Colors.white),
                )),
          ],
        ),
      ),
    );
  }
}
