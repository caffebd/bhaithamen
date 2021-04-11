import 'package:bhaithamen/data/userData.dart';
import 'package:bhaithamen/utilities/auto_page_navigation.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:provider/provider.dart';

class CountPlug extends StatefulWidget {
  // CountPlug({Key key, this.title}) : super(key: key);

  //final String title;

  @override
  _CountPlugState createState() => _CountPlugState();
}

class _CountPlugState extends State<CountPlug> {
  int timer = 10;
  dynamic theUserData;
  dynamic homeAsk;
  AutoHomePageAskSelect homePageAskInstance;

  int endTime = DateTime.now().millisecondsSinceEpoch + 1000 * askTime;
  bool earlyQuit = false;
  bool resetValue = false;

  @override
  void initState() {
    super.initState();
    endTime = 0;
  }

  @override
  Widget build(BuildContext context) {
    globalContext = context;
    homePageAskInstance = Provider.of<AutoHomePageAskSelect>(context);

    final userData = Provider.of<UserData>(context);
    if (userData != null) {
      theUserData = userData;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(),
            Text(
              'Timer',
              style: myStyle(26),
            ),
            Spacer(),
            Text(
              'Interval',
              style: myStyle(26),
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
              height: 100,
              alignment: Alignment.center,
              child: Column(
                children: [
                  DropdownButton(
                      value: askTime,
                      items: [
                        DropdownMenuItem(
                          child: Text("10 sec", style: myStyle(18)),
                          value: 10,
                        ),
                        DropdownMenuItem(
                          child: Text("5 mins", style: myStyle(18)),
                          value: 300,
                        ),
                        DropdownMenuItem(
                          child: Text("10 mins", style: myStyle(18)),
                          value: 600,
                        ),
                        DropdownMenuItem(
                          child: Text("20 mins", style: myStyle(18)),
                          value: 1200,
                        ),
                        DropdownMenuItem(
                          child: Text("30 mins", style: myStyle(18)),
                          value: 1800,
                        ),
                        DropdownMenuItem(
                          child: Text("60 mins", style: myStyle(18)),
                          value: 3600,
                        ),
                      ],
                      onChanged: (value1) {
                        setState(() {
                          askTime = value1;
                          resetValue = true;
                        });
                      }),
                ],
              ),
            ),
            Spacer(),
            Container(
              height: 100,
              alignment: Alignment.center,
              child: Column(
                children: [
                  DropdownButton(
                      value: askTimerSnooze,
                      items: [
                        DropdownMenuItem(
                          child: Text("1 min", style: myStyle(18)),
                          value: 10,
                        ),
                        DropdownMenuItem(
                          child: Text("2 mins", style: myStyle(18)),
                          value: 120,
                        ),
                        DropdownMenuItem(
                          child: Text("5 mins", style: myStyle(18)),
                          value: 300,
                        ),
                        DropdownMenuItem(
                          child: Text("10 mins", style: myStyle(18)),
                          value: 600,
                        ),
                      ],
                      onChanged: (value2) {
                        setState(() {
                          //askTimerSnooze = value2;
                        });
                      }),
                ],
              ),
            ),
            Spacer(),
          ],
        ),
        CountdownTimer(
          textStyle: TextStyle(fontSize: 50, color: Colors.pink),
          endTime: endTime,
          widgetBuilder: (_, CurrentRemainingTime time) {
            if (earlyQuit && time != null) {
              myTimeRemaining = time;
              endTime = 0;
            }
            if (firstRun) {
              myTimeRemaining = time;
              firstRun = false;
            }
            if (time != null) {
              if (time.hours == null) {
                return Text(
                    '00' +
                        ':' +
                        time.min.toString().padLeft(2, "0") +
                        ':' +
                        time.sec.toString().padLeft(2, "0"),
                    style: myStyle(30));
              } else if (time.hours == null && time.min == null) {
                return Text(
                    '00' + '00' + ':' + time.sec.toString().padLeft(2, "0"),
                    style: myStyle(30));
              } else {
                return Text(
                    time.hours.toString().padLeft(2, "0") +
                        ':' +
                        time.min.toString().padLeft(2, "0") +
                        ':' +
                        time.sec.toString().padLeft(2, "0"),
                    style: myStyle(30));
              }
            } else {
              if (myTimeRemaining.hours == null) {
                return Text(
                    '00' +
                        ':' +
                        myTimeRemaining.min.toString().padLeft(2, "0") +
                        ':' +
                        myTimeRemaining.sec.toString().padLeft(2, "0"),
                    style: myStyle(30));
              } else if (myTimeRemaining.hours == null &&
                  myTimeRemaining.min == null) {
                return Text(
                    '00' +
                        '00' +
                        ':' +
                        myTimeRemaining.sec.toString().padLeft(2, "0"),
                    style: myStyle(30));
              } else {
                return Text(
                    myTimeRemaining.hours.toString().padLeft(2, "0") +
                        ':' +
                        myTimeRemaining.min.toString().padLeft(2, "0") +
                        ':' +
                        myTimeRemaining.sec.toString().padLeft(2, "0"),
                    style: myStyle(30));
              }
            }
          },
          onEnd: () {
            setState(() {
              earlyQuit = false;
              myTimeRemaining = null;
              askTimerRunning = false;
            });
          },
        ),
        SizedBox(height: 60),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(),
            Container(
              width: 100,
              child: InkWell(
                  onTap: () {},
                  child: Image.asset('assets/images/resetTimer.png')),
            ),
            Spacer(),
            Container(
              width: 100,
              child: InkWell(
                  onTap: () {
                    if (askTimerRunning == false) {
                      setState(() {
                        if (resetValue == true) {
                          endTime = DateTime.now().millisecondsSinceEpoch +
                              1000 * askTime;
                          resetValue = false;
                        } else {
                          int hourSeconds = myTimeRemaining.hours != null
                              ? myTimeRemaining.hours * 3600
                              : 0;
                          int minuteSeconds = myTimeRemaining.min != null
                              ? myTimeRemaining.min * 60
                              : 0;
                          int seconds = myTimeRemaining.sec;
                          int allSeconds =
                              hourSeconds + minuteSeconds + seconds;
                          endTime = allSeconds;
                        }
                        askTimerRunning = true;
                        earlyQuit = true;
                      });
                    } else {
                      setState(() {
                        askTimerRunning = false;
                        earlyQuit = false;
                        print('resume clock');

                        //timeRemaining=
                      });
                    }
                  },
                  child: askTimerRunning
                      ? Image.asset('assets/images/stopTimer.png')
                      : Image.asset('assets/images/timerStart.png')),
            ),
            Spacer(),
          ],
        ),
      ],
    );
  }
}
