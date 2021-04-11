import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sendsms/sendsms.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;

const platform = const MethodChannel('flutter.native/helper');

SnackBar buildSnackBar(String phone, bool success) {
  String message;
  if (success) {
    message = 'SMS to $phone sent successfully';
  } else {
    message = 'FAILED to send SMS to $phone';
  }
  var theSnackBar = SnackBar(
    content: Text(message,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: Colors.white)),
    backgroundColor: success ? Colors.green : Colors.red,
    duration: Duration(seconds: 5),
  );

  return theSnackBar;
}

sendNewSms(String phone, String username, int pos, String type) async {
  bool wasReceived = false;

  String message;

  switch (type) {
    case 'button':
      message =
          "ভাই থামেন অ্যাপ ব্যবহারকারী আপনার সাহায্যের জন্য অনুরোধ করছেন।";
      break;
    case 'zone':
      message =
          "ভাই থামেন অ্যাপ ব্যবহারকারী তার দেয়া নিরাপদ সীমানার বাহিরে চলে গেছেন।";
      break;
    case 'timer':
      message =
          "ভাই থামেন অ্যাপ ব্যবহারকারী তার দেয়া নিরাপদ সময় অতিক্রম করেছেন।";
      break;
    case 'record':
      message =
          "ভাই থামেন অ্যাপ ব্যবহারকারী আপনার সাহায্যের জন্য অনুরোধ করছেন।";
      break;
    default:
  }

  print('sending $phone' + ' ' + wasReceived.toString());
  try {
    await Sendsms.onSendSMS(phone, message)
        .then((value) => print('sms val ' + value.toString()));
  } on Exception catch (exception) {
    print('SMS EXC ' + exception.toString());
    // only executed if error is of type Exception
  } catch (error) {
    print('SMS ' + error.toString());
    // executed for errors of all types other than Exception
  }

  bg.BackgroundGeolocation.getCurrentPosition(
          persist: false, // <-- do not persist this location
          desiredAccuracy: 0, // <-- desire best possible accuracy
          timeout: 30000, // <-- wait 30s before giving up.
          samples: 3 // <-- sample 3 location before selecting best.
          )
      .then((bg.Location location) async {
    // GeoPoint loc = GeoPoint(location.coords.latitude, location.coords.longitude);
    String mainUrl = 'https://www.google.com/maps/search/?api=1&query=' +
        location.coords.latitude.toString() +
        ',' +
        location.coords.longitude.toString();
    String message2;
    message2 = mainUrl;
    try {
      await Sendsms.onSendSMS(phone, message2)
          .then((value) => print('sms val ' + value.toString()));
    } on Exception catch (exception) {
      print('SMS EXC ' + exception.toString());
      // only executed if error is of type Exception
    } catch (error) {
      print('SMS ' + error.toString());
      // executed for errors of all types other than Exception
    }
  }).catchError((error) {
    print('[getCurrentPosition in fnc] ERROR: $error');
  });
}
