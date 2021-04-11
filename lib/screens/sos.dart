import 'package:bhaithamen/data/event_date.dart';
import 'package:bhaithamen/data/incident_date.dart';
import 'package:bhaithamen/data/userData.dart';
import 'package:bhaithamen/screens/challenge.dart';
import 'package:bhaithamen/screens/report.dart';
import 'package:bhaithamen/screens/secret_record.dart';
import 'package:bhaithamen/utilities/auth.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SOS extends StatefulWidget {
  _SOSState createState() => _SOSState();
}

class _SOSState extends State<SOS> {
  List<bool> isSelected = [false, false];
  bool added = false;
  UserData userData;
  List pageOptions = [
    //RouteScreen(),
    Challenge(),
    MakeReport(),
  ];

  @override
  void initState() {
    super.initState();
    isSelected[sosPageIndex] = true;
    globalContext = context;
    if (showMapPopup) {
      mapFlushBar();
    }
    if (showAskPopup) {
      askFlushBar();
    }
  }

  addSecretRecordPage(userD) {
    pageOptions.add(SecretRecord(userD));
  }

  @override
  Widget build(BuildContext context) {
    userData = Provider.of<UserData>(context);

    return MultiProvider(
      providers: [
        StreamProvider<List<IncidentDay>>.value(
            value: AuthService(uid: userData.uid).getIncidents),
        StreamProvider<List<EventDay>>.value(
            value: AuthService(uid: userData.uid).getEvents),
      ],
      child: new Column(
        children: <Widget>[
          SizedBox(height: 5),
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                //buttons across top of screen
                ToggleButtons(
                  color: Colors.white,
                  selectedColor: Colors.black,
                  fillColor: Colors.red[600],
                  borderColor: Colors.white,
                  children: <Widget>[
                    isSelected[0]
                        ? Container(
                            width: (MediaQuery.of(context).size.width - 12) / 2,
                            child: new Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                new Icon(
                                  Icons.clean_hands,
                                  size: 16.0,
                                  color: Colors.white,
                                ),
                                new SizedBox(
                                  width: 4.0,
                                ),
                                new Text(
                                  languages[selectedLanguage[languageIndex]]
                                      ['confront'],
                                  style: TextStyle(color: Colors.white),
                                )
                              ],
                            ))
                        : Container(
                            width: (MediaQuery.of(context).size.width - 12) / 2,
                            child: new Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                new Icon(
                                  Icons.clean_hands,
                                  size: 16.0,
                                  color: Colors.black,
                                ),
                                new SizedBox(
                                  width: 4.0,
                                ),
                                new Text(
                                  languages[selectedLanguage[languageIndex]]
                                      ['confront'],
                                  style: TextStyle(color: Colors.black),
                                )
                              ],
                            )),
                    isSelected[1]
                        ? Container(
                            width: (MediaQuery.of(context).size.width - 12) / 2,
                            child: new Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                new Icon(
                                  Icons.note,
                                  size: 16.0,
                                  color: Colors.white,
                                ),
                                new SizedBox(
                                  width: 4.0,
                                ),
                                new Text(
                                    languages[selectedLanguage[languageIndex]]
                                        ['report'],
                                    style: TextStyle(color: Colors.white))
                              ],
                            ))
                        : Container(
                            width: (MediaQuery.of(context).size.width - 12) / 2,
                            child: new Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                new Icon(
                                  Icons.note,
                                  size: 16.0,
                                  color: Colors.black,
                                ),
                                new SizedBox(
                                  width: 4.0,
                                ),
                                new Text(
                                    languages[selectedLanguage[languageIndex]]
                                        ['report'],
                                    style: TextStyle(color: Colors.black))
                              ],
                            )),
                    // isSelected[2]?
                    // Container(width: (MediaQuery.of(context).size.width - 12)/3, child: new Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[new Icon(Icons.privacy_tip,size: 16.0,color: Colors.white,),new SizedBox(width: 4.0,), new Text(languages[selectedLanguage[languageIndex]]['secrecy'],style: TextStyle(color: Colors.white))],))
                    // :Container(width: (MediaQuery.of(context).size.width - 12)/3, child: new Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[new Icon(Icons.privacy_tip,size: 16.0,color: Colors.black,),new SizedBox(width: 4.0,), new Text(languages[selectedLanguage[languageIndex]]['secrecy'],style: TextStyle(color: Colors.black))],)),
                  ],
                  onPressed: (int index) {
                    setState(() {
                      mapIsShowing = false;
                      for (int buttonIndex = 0;
                          buttonIndex < isSelected.length;
                          buttonIndex++) {
                        if (buttonIndex == index) {
                          isSelected[buttonIndex] = true;
                          sosPageIndex = index;
                        } else {
                          isSelected[buttonIndex] = false;
                        }
                      }
                    });
                  },
                  isSelected: isSelected,
                ),
              ],
            ),
          ),
          Container(child: pageOptions[sosPageIndex]),
        ],
      ),
    );
  }
}
