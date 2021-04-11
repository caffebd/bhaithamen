import 'dart:math';
import 'dart:typed_data';
import 'package:bhaithamen/data/event.dart';
import 'package:bhaithamen/data/incident_report.dart';
import 'package:bhaithamen/data/userData.dart';
import 'package:bhaithamen/main.dart';
import 'package:bhaithamen/utilities/analytics_service.dart';
import 'package:bhaithamen/utilities/fb_test.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:checkdigit/checkdigit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

DateTime today;

Function reportFormClear;

final analyticsHelper = AnalyticsService();

showWelfareNotification() async {
  String title =
      languages[selectedLanguage[languageIndex]]['notificationTitle'];
  String body = languages[selectedLanguage[languageIndex]]['notificationBody'];
  String pay_load = 'none';

  Future.delayed(const Duration(minutes: 15), () async {
    showWelfare = true;

    final Int64List vibrationPattern = Int64List(4);
    vibrationPattern[0] = 0;
    vibrationPattern[1] = 1000;
    vibrationPattern[2] = 5000;
    vibrationPattern[3] = 2000;

    const int insistentFlag = 4;

    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'myid', 'mychannel', 'mydesc',
        importance: Importance.max,
        priority: Priority.max,
        additionalFlags: Int32List.fromList(<int>[insistentFlag, 26]),
        vibrationPattern: vibrationPattern,
        enableLights: true,
        color: Colors.red,
        ledColor: Colors.blue,
        ledOnMs: 1000,
        ledOffMs: 500);
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin
        .show(0, title, body, platformChannelSpecifics, payload: pay_load);
  });
}

DateTime getDate() {
  DateTime getToday = new DateTime.now();
  DateTime(2020, 10, 13);
  int year = int.parse(formatDate(getToday, [yyyy]));
  int month = int.parse(formatDate(getToday, [mm]));
  //String fullMonth = formatDate( getToday, [MM]);
  int day = int.parse(formatDate(getToday, [dd]));

  today = DateTime(year, month, day);

  return today;
}

getCurrentReportPosition(String type, String reportLocation, String target,
    String incidentDate, String description) async {
  String theType = type;

  bg.BackgroundGeolocation.getCurrentPosition(
          persist: false, // <-- do not persist this location
          desiredAccuracy: 0, // <-- desire best possible accuracy
          timeout: 30000, // <-- wait 30s before giving up.
          samples: 3 // <-- sample 3 location before selecting best.
          )
      .then((bg.Location location) {
    GeoPoint loc =
        GeoPoint(location.coords.latitude, location.coords.longitude);
  }).catchError((error) {
    print('[getCurrentPosition in fnc] ERROR: $error');
  });
}

getCurrentPosition(String type, String category) async {
  String theType = type;

  bg.BackgroundGeolocation.getCurrentPosition(
          persist: false, // <-- do not persist this location
          desiredAccuracy: 0, // <-- desire best possible accuracy
          timeout: 30000, // <-- wait 30s before giving up.
          samples: 3 // <-- sample 3 location before selecting best.
          )
      .then((bg.Location location) {
    print('[getCurrentPosition in fnc] - $location');
    print('TETETETETET ' + location.coords.latitude.toString());
    GeoPoint loc =
        GeoPoint(location.coords.latitude, location.coords.longitude);
    doTheSend(theType, loc, category);
  }).catchError((error) {
    print('[getCurrentPosition in fnc] ERROR: $error');
  });
}

sendEvent(String type, String category) async {
  if (!testModeToggle) {
    getCurrentPosition(type, category);

    if (type != 'welfare') showWelfareNotification();
  }
}

sendReport(
    String type,
    String location,
    String target,
    String incidentDate,
    String description,
    String reportUid,
    List<String> attachedEvents,
    Function clear,
    UserData userData) async {
  reportFormClear = clear;
  //getCurrentReportPosition(type, location, target, incidentDate, description);
  doTheIncidentSend(type, location, target, incidentDate, description,
      attachedEvents, reportUid, userData.userPhone);
}

doTheIncidentSend(
    String type,
    String location,
    String target,
    String incidentDate,
    String description,
    List<String> attachedEvents,
    String reportUid,
    String userPhone) async {
  final newEvent = IncidentReport(
          time: DateTime.now(),
          type: type,
          location: location,
          target: target,
          incidentDate: incidentDate,
          description: description,
          attachedEvents: attachedEvents,
          reportUid: reportUid,
          userPhone: userPhone)
      .toMap();

//need to change below

  int unixDate = getDate().toUtc().millisecondsSinceEpoch;

  CollectionReference catCollection =
      FirebaseFirestore.instance.collection('reportsFiled');

  DocumentSnapshot cat = await catCollection.doc(getDate().toString()).get();
  if (cat.exists) {
    catCollection.doc(getDate().toString()).update({
      "createdAt": unixDate,
      "incidents": FieldValue.arrayUnion([newEvent])
    });
  } else {
    catCollection.doc(getDate().toString()).set({
      "createdAt": unixDate,
      "incidents": FieldValue.arrayUnion([newEvent])
    });
  }

  var firebaseUser = FirebaseAuth.instance.currentUser;
  DocumentSnapshot userDoc = await userCollection
      .doc(firebaseUser.uid)
      .collection('incidents')
      .doc(getDate().toString())
      .get();
  if (userDoc.exists) {
    userCollection
        .doc(firebaseUser.uid)
        .collection('incidents')
        .doc(getDate().toString())
        .update({
          "createdAt": unixDate,
          "incidents": FieldValue.arrayUnion([newEvent])
        })
        .then((doc) {
          print("doc save successful");
          reportFormClear();
          analyticsHelper.sendAnalyticsEvent('User_Report_Sent_Success');
          sendResearchReport('User_Report_Sent_Success');
          showDialog(
            context: globalContext,
            builder: (context) => AlertDialog(
              content: Container(
                height: 120,
                child: Column(
                  children: [
                    SizedBox(height: 15),
                    Text(
                      languages[selectedLanguage[languageIndex]]
                          ['reportSuccess'],
                      style: myStyle(18),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                            languages[selectedLanguage[languageIndex]]
                                ['reportId'],
                            style: myStyle(18)),
                        Text(': ' + reportUid,
                            style: myStyle(18, Colors.black, FontWeight.w600))
                      ],
                    )
                  ],
                ),
              ),
              actions: [
                FlatButton(
                  child: Text(languages[selectedLanguage[languageIndex]]['ok']),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        })
        .timeout(Duration(seconds: 10))
        .catchError((error) {
          print("doc save error");
          print(error);
          analyticsHelper.sendAnalyticsEvent('User_Report_Sent_Fail');
          sendResearchReport('User_Report_Sent_Fail');
          showDialog(
            context: globalContext,
            builder: (context) => AlertDialog(
              content: Text(
                  languages[selectedLanguage[languageIndex]]['reportFail']),
              actions: [
                FlatButton(
                  child: Text(languages[selectedLanguage[languageIndex]]['ok']),
                  onPressed: () {
                    reportFormClear();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        });
  } else {
    userCollection
        .doc(firebaseUser.uid)
        .collection('incidents')
        .doc(getDate().toString())
        .set({
          "createdAt": unixDate,
          "incidents": FieldValue.arrayUnion([newEvent])
        })
        .then((doc) {
          print("doc save successful");
          analyticsHelper.sendAnalyticsEvent('User_Report_Sent_Success');
          sendResearchReport('User_Report_Sent_Success');
          showDialog(
            context: globalContext,
            builder: (context) => AlertDialog(
              content: Container(
                height: 120,
                child: Column(
                  children: [
                    SizedBox(height: 15),
                    Text(
                      languages[selectedLanguage[languageIndex]]
                          ['reportSuccess'],
                      style: myStyle(18),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                            languages[selectedLanguage[languageIndex]]
                                ['reportId'],
                            style: myStyle(18)),
                        Text(': ' + reportUid,
                            style: myStyle(18, Colors.black, FontWeight.w600))
                      ],
                    )
                  ],
                ),
              ),
              actions: [
                FlatButton(
                  child: Text(languages[selectedLanguage[languageIndex]]['ok']),
                  onPressed: () {
                    reportFormClear();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        })
        .timeout(Duration(seconds: 10))
        .catchError((error) {
          print("doc save error");
          print(error);
          analyticsHelper.sendAnalyticsEvent('User_Report_Sent_Fail');
          sendResearchReport('User_Report_Sent_Fail');
          showDialog(
            context: globalContext,
            builder: (context) => AlertDialog(
              content: Text(
                  languages[selectedLanguage[languageIndex]]['reportFail']),
              actions: [
                FlatButton(
                  child: Text(languages[selectedLanguage[languageIndex]]['ok']),
                  onPressed: () {
                    reportFormClear();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        });
  }
}

doTheSend(String type, GeoPoint location, String category) async {
  var firebaseUser = FirebaseAuth.instance.currentUser;
  DocumentSnapshot userForAgeDoc =
      await userCollection.doc(firebaseUser.uid).get();

  int userAge = userForAgeDoc['age'] ?? 0;
  String userPhone = userForAgeDoc['userPhone'];

  int unixDate = getDate().toUtc().millisecondsSinceEpoch;

  final newEvent = Event(
          time: DateTime.now(),
          type: type,
          location: location,
          category: category,
          eventId: _eventUid(),
          age: userAge,
          userPhone: userPhone)
      .toMap();

  DocumentSnapshot userDoc = await userCollection
      .doc(firebaseUser.uid)
      .collection('events')
      .doc(getDate().toString())
      .get();
  if (userDoc.exists) {
    userCollection
        .doc(firebaseUser.uid)
        .collection('events')
        .doc(getDate().toString())
        .update({
      "createdAt": unixDate,
      "events": FieldValue.arrayUnion([newEvent])
    });
  } else {
    userCollection
        .doc(firebaseUser.uid)
        .collection('events')
        .doc(getDate().toString())
        .set({
      "createdAt": unixDate,
      "events": FieldValue.arrayUnion([newEvent])
    });
  }

  CollectionReference catCollection =
      FirebaseFirestore.instance.collection(category);

  DocumentSnapshot cat = await catCollection.doc(getDate().toString()).get();
  if (cat.exists) {
    catCollection.doc(getDate().toString()).update({
      "createdAt": unixDate,
      "events": FieldValue.arrayUnion([newEvent])
    });
  } else {
    catCollection.doc(getDate().toString()).set({
      "createdAt": unixDate,
      "events": FieldValue.arrayUnion([newEvent])
    });
  }
}

String _eventUid() {
  var random = new Random();
  var code = random.nextInt(99999999);

  int checkDigit = damm.checkDigit(code.toString());
  String reportUid = code.toString() + checkDigit.toString();
  return reportUid;
}
