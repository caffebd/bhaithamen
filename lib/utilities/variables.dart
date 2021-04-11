import 'dart:async';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flushbar/flushbar.dart';
import 'package:ocarina/ocarina.dart';
import 'package:pausable_timer/pausable_timer.dart';

OcarinaPlayer countdownPlayer;
OcarinaPlayer mapPlayer;
OcarinaPlayer alarmPlayer;

smsSuccessFlushBarShow() {
  Flushbar(
    flushbarPosition: FlushbarPosition.TOP,
    title: languages[selectedLanguage[languageIndex]]['flashSMSSentTitle'],
    message: languages[selectedLanguage[languageIndex]]['flashSMSSentBody'],
    backgroundColor: Colors.green,
    duration: Duration(seconds: 8),
  ).show(globalContext);
}

smsFailFlushBarShow() {
  Flushbar(
    flushbarPosition: FlushbarPosition.TOP,
    title: languages[selectedLanguage[languageIndex]]['flashSMSSFailTitle'],
    message: languages[selectedLanguage[languageIndex]]['flasSMSFailBody'],
    backgroundColor: Colors.red,
    duration: Duration(seconds: 8),
  ).show(globalContext);
}

smsLongPress() {
  Flushbar(
    flushbarPosition: FlushbarPosition.BOTTOM,
    title: languages[selectedLanguage[languageIndex]]['flashLongPressTitle'],
    message: languages[selectedLanguage[languageIndex]]['flashLongPressBody'],
    backgroundColor: Colors.red,
    duration: Duration(seconds: 5),
  ).show(globalContext);
}

smsNoContacts() {
  Flushbar(
    flushbarPosition: FlushbarPosition.BOTTOM,
    title: languages[selectedLanguage[languageIndex]]['flashNoContactsTitle'],
    message: languages[selectedLanguage[languageIndex]]['flashNoContactsBody'],
    backgroundColor: Colors.red,
    duration: Duration(seconds: 7),
  ).show(globalContext);
}

flushLoginError() {
  Flushbar(
    flushbarPosition: FlushbarPosition.TOP,
    title: languages[selectedLanguage[languageIndex]]['loginErrorTitle'],
    message: languages[selectedLanguage[languageIndex]]['loginErrorBody'],
    backgroundColor: Colors.red,
    duration: Duration(seconds: 10),
  ).show(globalContext);
}

smsBtnSending() {
  Flushbar(
    flushbarPosition: FlushbarPosition.BOTTOM,
    title: languages[selectedLanguage[languageIndex]]['flashSMSSentTitle'],
    message: languages[selectedLanguage[languageIndex]]['flashSMSSentBody'],
    backgroundColor: Colors.green,
    duration: Duration(seconds: 7),
  ).show(globalContext);
}

askMeFlushBarShow() {
  Flushbar(
    flushbarPosition: FlushbarPosition.TOP,
    title: 'Welfare Check',
    message: "Do you need to cancel alarm?",
    backgroundColor: Colors.blue,
    duration: Duration(seconds: 8),
    mainButton: FlatButton(
      child: Text('YES'),
      onPressed: () {},
    ),
  ).show(globalContext);
}

mapFlushBarShow() {
  Flushbar(
    flushbarPosition: FlushbarPosition.TOP,
    title: 'Map Alert',
    message: "You left the tracking zone",
    duration: Duration(seconds: 3),
  ).show(globalContext);
}

mapFlushBar() {
  Duration timeOut = Duration(seconds: 3);
  Timer(timeOut, () {
    mapFlushBarShow();
  });
}

askFlushBarShow() {
  Flushbar(
    flushbarPosition: FlushbarPosition.TOP,
    title: 'Welfare Alert',
    backgroundColor: Colors.red,
    message: "Welfare timer expired",
    duration: Duration(seconds: 3),
  ).show(globalContext);
}

deleteNeedCheck() {
  Flushbar(
    flushbarPosition: FlushbarPosition.TOP,
    title: languages[selectedLanguage[languageIndex]]['flashConfirmTitle'],
    backgroundColor: Colors.red,
    message: languages[selectedLanguage[languageIndex]]['flashConfirmBody'],
    duration: Duration(seconds: 8),
  ).show(globalContext);
}

geoLimitFlushBarShow() {
  Flushbar(
    flushbarPosition: FlushbarPosition.BOTTOM,
    title: languages[selectedLanguage[languageIndex]]['flashZoneLimitTitle'],
    backgroundColor: Colors.red,
    message: languages[selectedLanguage[languageIndex]]['flashZoneLimitBody'],
    duration: Duration(seconds: 6),
  ).show(globalContext);
}

askFlushBar() {
  Duration timeOut = Duration(seconds: 3);
  Timer(timeOut, () {
    askFlushBarShow();
  });
}

myStyle(double size, [Color color, FontWeight fw]) {
  return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: fw != null ? fw : FontWeight.w400,
      color: color != null ? color : Colors.black);
}

AppLifecycleState stateNotification;
AppLifecycleState mainAppState;
LatLng savedStartLocation = LatLng(23.8103, 90.4125);
bool mapIsShowing;
BuildContext globalContext;

bool secretRecordInactive = false;

bool langJustChanged = false;

bool appHasStarted = false;

bool appWasOpened = false;

bool usePincode = false;

Duration askDuration = Duration(hours: 0, minutes: 0);

bool locEnable = false;

int homePageIndex = 1;

bool askTimerRunning = false;

int askTime = 10;

bool firstRun = true;

PausableTimer newCountDown;

Timer pinTimer;

String checkAuth = 'false';

CurrentRemainingTime myTimeRemaining;

Timer alertTimer;
Timer askTimer;

int askTimerTime = 10;
int timeLeft = askTimerTime;
int askTimerSnooze = 1;
Timer askSnooze;

Timer countDown;
bool timerRunning = false;

Timer mapPeriodicCheck;
String lastGeoEvent = 'non';

bool savedShouldGoAsk = false;
bool savedShouldGoMap = false;
bool savedShouldGoWelfare = false;

bool showWelfare = false;

int savedSafeIndex = 0;

bool pinNeeded = false;

bool secretRecordCover;
bool secretRecordSendSMS;

bool secretRecordingStarted = false;

bool challengeRecordSendSMS;

bool testModeToggle = false;
bool testModeWasChanged = false;

// AudioPlayer alarm;
// AudioPlayer mapAlarm;

//final player = AudioPlayer();
//final askPlayer = AudioPlayer();

int oldsafePageIndex = 0;
int sosPageIndex = 0;

bool needThePin = true;

bool showAskPopup = false;
bool showMapPopup = false;

bool askMeRunning = false;

bool canCompose = false;

bool myNewsOnly = true;

String safePlaceCategory = 'medical';

//List<Asset> multiPickedImages = List<Asset>();

CollectionReference userCollection =
    FirebaseFirestore.instance.collection('users');
CollectionReference tweetCollection =
    FirebaseFirestore.instance.collection('events');
CollectionReference reportsCollection =
    FirebaseFirestore.instance.collection('reports');
CollectionReference smsCollection =
    FirebaseFirestore.instance.collection('smsBtn');
CollectionReference challengeCollection =
    FirebaseFirestore.instance.collection('challenge');
CollectionReference secretCollection =
    FirebaseFirestore.instance.collection('secret');
CollectionReference zoneCollection =
    FirebaseFirestore.instance.collection('zone');
CollectionReference timerCollection =
    FirebaseFirestore.instance.collection('timer');

CollectionReference safePlaceCollection =
    FirebaseFirestore.instance.collection('safeplaces');

CollectionReference requestedDeleteAccount =
    FirebaseFirestore.instance.collection('requestedDeleteAccount');
CollectionReference requestedDeleteData =
    FirebaseFirestore.instance.collection('requestedDeleteData');
CollectionReference feedbackCollection =
    FirebaseFirestore.instance.collection('appFeedback');

CollectionReference reportedCollection =
    FirebaseFirestore.instance.collection('reportedPlaces');

CollectionReference newsCollection =
    FirebaseFirestore.instance.collection('newsfeed');

CollectionReference userNewsCollection =
    FirebaseFirestore.instance.collection('usernews');

CollectionReference alertsNewsCollection =
    FirebaseFirestore.instance.collection('alertsfeed');

StorageReference userStorage = FirebaseStorage.instance.ref().child('users');

StorageReference userNews = FirebaseStorage.instance.ref().child('usernews');

var defaultImage =
    'https://eitrawmaterials.eu/wp-content/uploads/2016/09/empty-avatar.jpg';
var demoImage =
    'https://cdn2.iconfinder.com/data/icons/super-hero/154/spider-man-spiderman-comics-hero-avatar-512.png';
