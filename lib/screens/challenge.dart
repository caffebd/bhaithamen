import 'package:auto_size_text/auto_size_text.dart';
import 'package:bhaithamen/data/userData.dart';
import 'package:bhaithamen/screens/challenge_screen.dart';
import 'package:bhaithamen/utilities/analytics_service.dart';
import 'package:bhaithamen/utilities/fb_test.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Challenge extends StatefulWidget {
  @override
  _ChallengeState createState() => _ChallengeState();
}

class _ChallengeState extends State<Challenge> {
  var firebaseUser;

  final analyticsHelper = AnalyticsService();

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  List challengeOptions;

  Future<void> _saveSMSOption() async {
    final SharedPreferences prefs = await _prefs;
    prefs.setBool('challengeSMS', challengeRecordSendSMS);
  }

  @override
  void initState() {
    super.initState();
    analyticsHelper.testSetCurrentScreen('challenge_options');
    globalContext = context;
    if (showMapPopup) {
      mapFlushBar();
      print('MAIN init state map pop');
    }
    if (showAskPopup) {
      askFlushBar();
      print('MAIN init state ask pop');
    }

    firebaseUser = FirebaseAuth.instance.currentUser;

    changeButtons();
  }

  changeButtons() {
    setState(() {
      challengeOptions = [
        languages[selectedLanguage[languageIndex]]['stopIt'],
        languages[selectedLanguage[languageIndex]]['goAway'],
        languages[selectedLanguage[languageIndex]]['leaveAlone'],
        languages[selectedLanguage[languageIndex]]['pleaseLeave']
      ];
    });
  }

  _switchSMS(bool enabled) {
    setState(() {
      challengeRecordSendSMS = !challengeRecordSendSMS;
    });
    _saveSMSOption();
  }

  @override
  Widget build(BuildContext context) {
    globalContext = context;

    final userData = Provider.of<UserData>(context);

    if (langJustChanged) {
      langJustChanged = false;
      changeButtons();
    }

    return Center(
      child: Column(
        children: [
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: 14,
              ),
              Container(
                width: 70,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white70,
                  border: Border.all(
                    color: Colors.black87,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Switch(
                  activeColor: Colors.red[500],
                  inactiveThumbColor: Colors.black54,
                  value: challengeRecordSendSMS,
                  onChanged: _switchSMS,
                ),
              ),
              SizedBox(width: 10),
              challengeRecordSendSMS
                  ? Flexible(
                      child: AutoSizeText(
                      languages[selectedLanguage[languageIndex]]['doShare'],
                      maxLines: 2,
                      style: myStyle(18),
                      textAlign: TextAlign.left,
                    ))
                  : Flexible(
                      child: AutoSizeText(
                      languages[selectedLanguage[languageIndex]]['notShare'],
                      maxLines: 2,
                      style: myStyle(18),
                      textAlign: TextAlign.left,
                    ))
            ],
          ),

          // Column(children:[
          for (var i = 0; i < challengeOptions.length; i++)
            Column(
              children: [
                SizedBox(height: 30),
                ButtonTheme(
                  minWidth: (MediaQuery.of(context).size.width * 0.8),
                  height: 50.0,
                  child: RaisedButton(
                    onPressed: () {
                      analyticsHelper.sendAnalyticsEvent(
                          'Challenge_Screen_Select',
                          param: challengeOptions[i]);
                      sendResearchReport(
                          'Challenge_Screen_Select_' + challengeOptions[i]);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ChallengeScreen(challengeOptions[i], userData, i),
                        ),
                      );
                    },
                    // padding: EdgeInsets.only(left: MediaQuery.of(context).size.width/4, right: MediaQuery.of(context).size.width/4, top: 15, bottom:15),
                    color: challengeRecordSendSMS
                        ? Colors.red[400]
                        : Colors.grey[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      //side: BorderSide(color: Colors.red, width:4)
                    ),
                    child: Text(
                      challengeOptions[i],
                      style: myStyle(26, Colors.white),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
