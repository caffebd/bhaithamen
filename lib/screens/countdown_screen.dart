import 'dart:async';
import 'package:bhaithamen/utilities/analytics_service.dart';
import 'package:bhaithamen/utilities/fb_test.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/overlay_sets.dart';
import 'package:bhaithamen/data/userData.dart';
import 'package:bhaithamen/utilities/auto_page_navigation.dart';
import 'package:bhaithamen/utilities/report_event.dart';
import 'package:bhaithamen/utilities/send_sms.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:flutter/material.dart';
import 'package:ocarina/ocarina.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class CountDown extends StatefulWidget {
  @override
  _CountDownState createState() => _CountDownState();
}

class _CountDownState extends State<CountDown> {
  //Duration askDuration = Duration(hours: 0, minutes: 0);
  //static AudioCache audioCache = AudioCache();
  //AudioPlayer player;
  final analyticsHelper = AnalyticsService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  int timer = 10;
  dynamic theUserData;
  dynamic homeAsk;
  AutoHomePageAskSelect homePageAskInstance;

  double timerShow = 10;
  double startAngle = 360;
  double angleRange = 360;
  double timeLeftOffset = 15;
  double circleLeftOffset = -40;

  String minuteTimer;

  bool testShow = true;
  List<String> localNumbers;

  loadLocal() async {
    if (countdownPlayer != null) {
      if (countdownPlayer.isLoaded()) {
        await countdownPlayer.dispose();
      }
    }
    //countdownPlayer.dispose();

    countdownPlayer = OcarinaPlayer(
      asset: 'assets/audio/alarm.mp3',
      loop: true,
      volume: 1,
    );

    await countdownPlayer.load();
    print("PLAY HERE");
    countdownPlayer.play();
  }

  Future<void> _getNumbers() async {
    final SharedPreferences prefs = await _prefs;
    localNumbers = prefs.getStringList('contacts');

    if (localNumbers.length > 0 && !testModeToggle) {
      for (var i = 0; i < localNumbers.length; i++) {
        bool done = await sendNewSms(localNumbers[i], '', i, 'timer');
        print('done $i' + done.toString());
      }

      smsBtnSending();
      sendEvent('sms', 'timer-sms');
    } else {
      smsNoContacts();
    }
  }

  grabTime() {
    setState(() {
      minuteTimer = _printDuration(Duration(seconds: timeLeft));
    });
  }

  timerUpdate() {
    if (timeLeft <= 0) {
      startNotificationTimer();
      countDown.cancel();
      timerRunning = false;
      setState(() {});
      return;
    }
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      timeLeftOffset = 10;
      circleLeftOffset = -25;
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      timeLeftOffset = 15;
      circleLeftOffset = -40;
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  @override
  void initState() {
    super.initState();
    globalContext = context;
    analyticsHelper.testSetCurrentScreen('countdown_screen');
    if (showMapPopup) {
      mapFlushBar();
    }

    minuteTimer = _printDuration(Duration(seconds: timeLeft));
    if (timerRunning) clockTick();

    useOverlay = 'reminder';
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void resetTimer() {
    if (askTimer.isActive) {
      askTimer.cancel();
    }

    Vibration.cancel();
    beginTimer();
  }

  void startAlertTimer() async {
    analyticsHelper.sendAnalyticsEvent('Countdown_SMS_Sent');
    sendResearchReport('Countdown_SMS_Sent');

    Duration timeOut = Duration(minutes: askTimerSnooze);
    askTimer = Timer(timeOut, () async {
      if (theUserData != null && !testModeToggle) {
        sendEvent('timer', 'timer');
        if (theUserData.phoneContact.length == 0) {
          _getNumbers();
        } else {
          for (var i = 0; i < theUserData.phoneContact.length; i++) {
            bool done = await sendNewSms(
                theUserData.phoneContact[i], theUserData.userName, i, 'timer');
            print('done $i' + done.toString());
          }
          smsBtnSending();
          sendEvent('sms', 'timer-sms');
        }
      }

      cancelTimerBtn(); //stop alarm

      //wait the interval time again and then start alarm again
      askTimer = Timer(timeOut, () async {
        startNotificationTimer();
      });
    });
  }

  clockTick() {
    if (countDown != null) {
      if (countDown.isActive) countDown.cancel();
    }
    countDown = Timer.periodic(Duration(seconds: 1), (Timer t) {
      if (timeLeft > 0) timeLeft -= 1;
      minuteTimer = _printDuration(Duration(seconds: timeLeft));
      setState(() {});

      print('counting ' + timeLeft.toString());

      if (timeLeft <= 0) {
        startNotificationTimer();
        countDown.cancel();
        timerRunning = false;
        setState(() {});
      }
    });
  }

  void startNotificationTimer() async {
    startAlertTimer();

    showAskPopup = true;

    homePageAskInstance.setHomePageAsk(true);
    savedShouldGoAsk = true;
    print('SETTING HOME PAGE ASK TRUE');
    setState(() {
      homePageAskInstance.setHomePageAsk(true);

      showAskPopup = true;
    });

    loadLocal();
    Vibration.vibrate(
      pattern: [
        500,
        1000,
        500,
        1000,
        500,
        1000,
        500,
        200,
        500,
        1000,
        500,
        1000,
        500,
        1000,
        500,
        200,
        200,
        200,
        200
      ],
    );
  }

  cancelTimerBtn() {
    print('in cancel timerBtn');
    //sendTestingReport('cancel timer btn');
    if (askTimer != null) {
      if (askTimer.isActive) {
        askTimer.cancel();
      }
    }
    //askPlayer.stop();
    if (countdownPlayer != null) {
      countdownPlayer.stop();
      countdownPlayer.dispose();
    }

    Vibration.cancel();
  }

  cancelTimer() {
    print('in cancel timer');
    //sendTestingReport('cancel timer non btn');
    if (askTimer.isActive) {
      askTimer.cancel();
    }

    //alarm?.stop();
    if (countdownPlayer != null) {
      countdownPlayer.stop();
      countdownPlayer.dispose();
    }
    Vibration.cancel();
    setState(() {
      askMeRunning = false;
    });
  }

  beginTimer() {
    //alarm?.stop();

    //sendTestingReport('begin timer');

    if (askTimer != null) {
      askTimer.cancel();
    }
    if (countdownPlayer != null) {
      countdownPlayer.stop();
      countdownPlayer.dispose();
    }
    Vibration.cancel();
    Duration timeOut = Duration(
        seconds: askTimerSnooze); //Duration(minutes:askDuration.inMinutes);
    askTimer = Timer(timeOut, () {
      startNotificationTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    globalContext = context;
    homePageAskInstance = Provider.of<AutoHomePageAskSelect>(context);

    final userData = Provider.of<UserData>(context);
    if (userData != null) {
      theUserData = userData;
    }
    return Center(
      child: Column(
        children: [
          SizedBox(height: 20),
          showAskPopup
              ? SizedBox(
                  width: 300,
                  height: 80,
                  child: Card(
                      elevation: 8.0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FlatButton(
                              height: 70,
                              minWidth: 142,
                              color: Colors.red,
                              onPressed: () {
                                setState(() {
                                  showAskPopup = false;
                                  askMeRunning = false;
                                  homePageAskInstance.setHomePageAsk(false);
                                  savedShouldGoAsk = false;
                                  timeLeft = askTimerTime;
                                  grabTime();
                                  cancelTimerBtn();
                                });
                              },
                              child: Text(
                                  languages[selectedLanguage[languageIndex]]
                                      ['stop'],
                                  style: myStyle(22, Colors.white))),
                          FlatButton(
                              height: 70,
                              minWidth: 142,
                              color: Colors.green,
                              onPressed: () {
                                setState(() {
                                  showAskPopup = false;
                                  homePageAskInstance.setHomePageAsk(false);
                                  savedShouldGoAsk = false;
                                  timeLeft = askTimerTime;
                                  grabTime();
                                  cancelTimerBtn();
                                  clockTick();
                                  timerRunning = true;
                                });
                                //beginTimer();
                              },
                              child: Container(
                                  width: 100,
                                  child: Text(
                                      languages[selectedLanguage[languageIndex]]
                                          ['restart'],
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      style: myStyle(22, Colors.white))))
                        ],
                      )),
                  //),
                )
              : Container(),

          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              Text(
                languages[selectedLanguage[languageIndex]]['timer'],
                style: myStyle(24),
              ),
              Spacer(),
              Text(
                languages[selectedLanguage[languageIndex]]['interval'],
                style: myStyle(24),
              ),
              Spacer(),
            ],
          ),

          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              Container(
                height: 65,
                alignment: Alignment.center,
                child: Column(
                  children: [
                    DropdownButton(
                        value: askTimerTime,
                        items: [
                          DropdownMenuItem(
                            child: Text(
                                languages[selectedLanguage[languageIndex]]
                                    ['10sec'],
                                style: myStyle(18)),
                            value: 10,
                          ),
                          DropdownMenuItem(
                            child: Text(
                                languages[selectedLanguage[languageIndex]]
                                    ['5min'],
                                style: myStyle(18)),
                            value: 300,
                          ),
                          DropdownMenuItem(
                            child: Text(
                                languages[selectedLanguage[languageIndex]]
                                    ['10min'],
                                style: myStyle(18)),
                            value: 600,
                          ),
                          DropdownMenuItem(
                            child: Text(
                                languages[selectedLanguage[languageIndex]]
                                    ['20min'],
                                style: myStyle(18)),
                            value: 1200,
                          ),
                          DropdownMenuItem(
                            child: Text(
                                languages[selectedLanguage[languageIndex]]
                                    ['30min'],
                                style: myStyle(18)),
                            value: 1800,
                          ),
                          DropdownMenuItem(
                            child: Text(
                                languages[selectedLanguage[languageIndex]]
                                    ['60min'],
                                style: myStyle(18)),
                            value: 3600,
                          ),
                          DropdownMenuItem(
                            child: Text(
                                languages[selectedLanguage[languageIndex]]
                                    ['90min'],
                                style: myStyle(18)),
                            value: 5400,
                          ),
                          DropdownMenuItem(
                            child: Text(
                                languages[selectedLanguage[languageIndex]]
                                    ['120min'],
                                style: myStyle(18)),
                            value: 7200,
                          ),
                        ],
                        onChanged: (value1) {
                          setState(() {
                            askTimerTime = value1;
                            timeLeft = askTimerTime;
                            grabTime();
                          });
                        }),
                  ],
                ),
              ),
              Spacer(),
              Container(
                height: 65,
                //alignment: Alignment.center,
                child: Column(
                  children: [
                    DropdownButton(
                        value: askTimerSnooze,
                        items: [
                          DropdownMenuItem(
                            child: Text(
                                languages[selectedLanguage[languageIndex]]
                                    ['1min'],
                                style: myStyle(18)),
                            value: 1,
                          ),
                          DropdownMenuItem(
                            child: Text(
                                languages[selectedLanguage[languageIndex]]
                                    ['2min'],
                                style: myStyle(18)),
                            value: 2,
                          ),
                          DropdownMenuItem(
                            child: Text(
                                languages[selectedLanguage[languageIndex]]
                                    ['5min'],
                                style: myStyle(18)),
                            value: 5,
                          ),
                          DropdownMenuItem(
                            child: Text(
                                languages[selectedLanguage[languageIndex]]
                                    ['10min'],
                                style: myStyle(18)),
                            value: 10,
                          ),
                        ],
                        onChanged: (value2) {
                          setState(() {
                            askTimerSnooze = value2;
                          });
                        }),
                  ],
                ),
              ),
              Spacer(),
            ],
          ),

          //Center(child:
          SizedBox(
            width: 300,
            height: 80,
            child: Card(
              elevation: 8.0,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(minuteTimer,
                    style: myStyle(40, Colors.black, FontWeight.w700),
                    textAlign: TextAlign.center),
              ),
              //),
            ),
          ),
          //),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              Container(
                width: 100,
                child: InkWell(
                    onTap: () {
                      setState(() {
                        showAskPopup = false;
                        homePageAskInstance.setHomePageAsk(false);
                        savedShouldGoAsk = false;
                        timeLeft = askTimerTime;
                        grabTime();
                        cancelTimerBtn();
                      });
                    },
                    child: languageIndex == 0
                        ? Image.asset('assets/images/resetTimer.png')
                        : Image.asset('assets/images/resetTimerBN.png')),
              ),
              Spacer(),
              Container(
                width: 100,
                child: InkWell(
                  onTap: () {
                    if (timerRunning) {
                      countDown.cancel();
                    } else {
                      if (timeLeft > 0) {
                        analyticsHelper.sendAnalyticsEvent('Countdown_started',
                            param: 'Time:_' + askTimerTime.toString());
                        sendResearchReport('Countdown_started');
                        clockTick();
                      }
                    }
                    setState(() {
                      timerRunning = !timerRunning;
                    });

                    cancelTimerBtn();
                  },
                  child: timerRunning
                      ? languageIndex == 0
                          ? Image.asset('assets/images/stopTimer.png')
                          : Image.asset('assets/images/stopTimerBN.png')
                      : languageIndex == 0
                          ? Image.asset('assets/images/timerStart.png')
                          : Image.asset('assets/images/timerStartBN.png'),
                ),
              ),
              Spacer(),
            ],
          ),

          //       Stack(
          //         overflow: Overflow.visible,
          //         children:[
          //           Positioned (
          //           top:-40,
          //           left:circleLeftOffset,
          //             child: Container(
          //               width: 180,
          //               child: Image.asset('assets/images/countCircle.png'),
          //             ),
          //           ),
          //     Container(
          //       margin: EdgeInsets.only(top:40, left: timeLeftOffset),
          //       child: Text(minuteTimer, style: myStyle(25, Colors.black, FontWeight.w700))
          //       ),
          // Visibility(
          // visible: showAskPopup,
          // child:
          // Positioned(
          //   top:-80,
          //   left:-135,
          //       child: Container(
          //     width: 280,
          //     height: 200,
          //     //margin: EdgeInsets.only(left:0, top:0),

          //     decoration: BoxDecoration(
          //       border: Border.all(color: Colors.blueAccent),
          //       borderRadius: BorderRadius.circular(20),
          //       boxShadow: [
          //     BoxShadow(
          //       color: Colors.grey.withOpacity(0.5),
          //       spreadRadius: 5,
          //       blurRadius: 7,
          //       offset: Offset(0, 3), // changes position of shadow
          //     ),
          //   ],
          //       color: Colors.white,
          //       shape: BoxShape.rectangle,
          //     ),
          //     child: Center(
          //       child:Column(
          //         children:[
          //           SizedBox(height:15),
          //           Text('Welfare Check', style: myStyle(20, Colors.black, FontWeight.w600)),
          //           SizedBox(height:25),
          //           Text('Snooze - delay sending SMS', style: myStyle(20)),
          //           SizedBox(height:25),
          //           Row(
          //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //             children:[
          //             FlatButton(
          //         shape: RoundedRectangleBorder(side: BorderSide(
          //           color: Colors.red,
          //           width: 2,
          //           style: BorderStyle.solid,
          //         ), borderRadius: BorderRadius.circular(20)
          //         ),
          //               onPressed: (){
          //                 setState(() {
          //                   showAskPopup=false;
          //                   askMeRunning=false;
          //                   homePageAskInstance.setHomePageAsk(false);
          //                   savedShouldGoAsk=false;
          //                   timeLeft = askTimerTime;
          //                   grabTime();
          //                   cancelTimerBtn();
          //                 });

          //               } ,
          //               child: Text('CANCEL', style:myStyle(20))),

          //             FlatButton(
          //         shape: RoundedRectangleBorder(side: BorderSide(
          //           color: Colors.green,
          //           width: 2,
          //           style: BorderStyle.solid,
          //         ), borderRadius: BorderRadius.circular(20)
          //         ),
          //               onPressed: (){
          //                   setState(() {
          //                   showAskPopup=false;
          //                   homePageAskInstance.setHomePageAsk(false);
          //                   savedShouldGoAsk=false;
          //                 });
          //                 beginTimer();
          //               },
          //               child: Text('SNOOZE', style: myStyle(20))
          //               ),
          //           ],

          //       )

          //     ],
          //     ),
          //     ),
          //   ),
          // ),

          // ),
          //       ],
          //       ),
        ],
      ),
    );
  }
}
//   Container(
//   width: 120,
//   margin: EdgeInsets.only(left:MediaQuery.of(context).size.width/2-64, top: 280),
//   child:  FloatingActionButton(
//               onPressed: () async {
//                 Duration resultingDuration = await showDurationPicker(
//                   context: context,
//                   initialTime: new Duration(minutes: 30),
//                 );
//                 Scaffold.of(context).showSnackBar(new SnackBar(
//                     content: new Text("Chose duration: $resultingDuration")));
//               },
//               tooltip: 'Popup Duration Picker',
//               child: new Icon(Icons.add),
//             )

// ),
// return Container(
//   height: MediaQuery.of(context).size.height-200,
//   child:
//   Stack(
//       children:[
//   SingleChildScrollView(
//   child:
//       Column(
//       mainAxisSize: MainAxisSize.min,
//       mainAxisAlignment: MainAxisAlignment.spaceAround,
//       children: <Widget>[
//           Container(
//            // alignment: Alignment.center,
//             margin: EdgeInsets.only(top:100, left: 50),
//             width: 200,
//             height: 150,
//             decoration: new BoxDecoration(
//               color: Colors.lightBlue,
//             ),
//             child:
//             Center(
//               child:
//               Column(children: [

//               ],
//               ),
//             )
//           ) ,
//       // Container(
//       //   child: DurationPicker(
//       //       duration: _duration,
//       //       onChange: (val) {
//       //         this.setState(() => _duration = val);
//       //       },
//       //       snapToMins: 1.0,
//       //     ),
//       // ),

// Container(
//   margin: EdgeInsets.only(top:100, left: 50),
//   child: FloatingActionButton(
//       backgroundColor: askMeRunning ? Colors.red: Colors.green,
//       onPressed: () async {
//         setState(() {
//           if (askMeRunning) {cancelTimer();}else{beginTimer();}
//           askMeRunning= ! askMeRunning;
//         });

//       },

//       child: askMeRunning ? Icon(Icons.pause) : Icon(Icons.play_arrow),
//     ),
// ),

//       ],
//     ),
//     //],
//     //),
//   ),
//       ],
//   ),

// );
