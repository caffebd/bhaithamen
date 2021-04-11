import 'package:bhaithamen/screens/countdown_screen.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

FlutterLocalNotificationsPlugin fltrNotification;
InitializationSettings initializationSettings;
String task;
int val;
BuildContext theContext;
Function doReset;
bool dialogShowing = false;

Future selectNotification(String payload) async {
  if (payload != null) {
    debugPrint('notification payload: $payload');
  }
  await Navigator.push(
    globalContext,
    MaterialPageRoute<void>(builder: (context) => CountDown()),
  );
}

Future notificationSelected(String payload) async {
  if (!dialogShowing) {
    dialogShowing = true;
    showDialog(
      context: globalContext,
      builder: (context) => AlertDialog(
        content: Text("Notification : $payload"),
        actions: [
          FlatButton(
            child: Text('Ok'),
            onPressed: () {
              dialogShowing = false;

              doReset();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

Future showNotification(Function reset, int time) async {
  theContext = globalContext;
  doReset = reset;
  var androidInitilize = new AndroidInitializationSettings('app_icon');
  var initilizationsSettings =
      InitializationSettings(android: androidInitilize);
  fltrNotification = new FlutterLocalNotificationsPlugin();
  fltrNotification.initialize(initilizationsSettings,
      onSelectNotification: (String payload) async {
    if (payload != null) {
      debugPrint('notification payload: OLD ONE $payload');
    }
  });

  var androidDetails = new AndroidNotificationDetails(
      "Channel ID", "Desi programmer", "This is my channel",
      priority: Priority.high,
      importance: Importance.high,
      fullScreenIntent: true);
  var generalNotificationDetails = NotificationDetails(android: androidDetails);

  await fltrNotification.show(
      0, "Bhai Thamen", "Check Bhia Thamen", generalNotificationDetails,
      payload: "Task");
}
