import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:bhaithamen/screens/secrecy.dart';
import 'package:bhaithamen/utilities/analytics_service.dart';
import 'package:bhaithamen/utilities/auth.dart';
import 'package:bhaithamen/utilities/auto_page_navigation.dart';
import 'package:bhaithamen/utilities/fb_test.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bhaithamen/data/userData.dart';
import 'package:bhaithamen/utilities/report_event.dart';
import 'package:bhaithamen/utilities/send_sms.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:record_mp3/record_mp3.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class SecretRecord extends StatefulWidget {
  final UserData userData;

  SecretRecord(this.userData); //, this.userData);

  @override
  _SecretRecordState createState() => _SecretRecordState();
}

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
Random _rnd = Random();
int photoCount = 0;
Timer photoTimer;
bool alarmPlaying = false;
bool firstTime = true;

class _SecretRecordState extends State<SecretRecord>
    with WidgetsBindingObserver {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final analyticsHelper = AnalyticsService();

  CameraController controller;
  String imagePath;
  String videoPath;
  String recordFilePath;
  VoidCallback videoPlayerListener;
  bool enableAudio = true;
  StorageReference camPictures;
  String statusText = "";
  bool isComplete = false;

  List<CameraDescription> cameras = [];
  final AuthService _auth = AuthService();
  //final player = AudioPlayer();

  var firebaseUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    analyticsHelper.testSetCurrentScreen('secret_record');
    photoCount = 0;
    print('CAM INIT STATE ' + photoCount.toString());
    firebaseUser = FirebaseAuth.instance.currentUser;
    globalContext = context;
    if (showMapPopup) {
      mapFlushBar();
      print('MAIN init state map pop');
    }
    if (showAskPopup) {
      askFlushBar();
      print('MAIN init state ask pop');
    }

    print('uid ' + widget.userData.uid);

    //autoCam();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    secretRecordingStarted = false;
    photoTimer?.cancel();

    super.dispose();
  }

  void logError(String code, String message) =>
      print('Error: $code\nError Message: $message');

  autoCam() async {
    bool hasPermission = await checkPermissionCamera();
    if (hasPermission) {
      cameras = await availableCameras();
      print('cameras ' + cameras.toString());
      onNewCameraSelected(cameras[0]);
    } else {
      showInSnackBar('Need permission to take photos');
      setState(() {
        secretRecordingStarted = false;
      });
    }
  }

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // App state changed before we got the chance to initialize.
    //if (controller == null || !controller.value.isInitialized) {
    //return;
    // }

    print('cam thing state');

    switch (state) {
      case AppLifecycleState.paused:
        print('PAUSED');
        //justResumed=true;
        break;
      case AppLifecycleState.resumed:
        print('resume');
        //controller?.dispose();
        // if (controller != null) {
        //   onNewCameraSelected(controller.description);
        // }
        if (langJustChanged) {
          print('LANG CHANG');
          langJustChanged = false;
          forceUpdate();
        }
        break;
      case AppLifecycleState.inactive:
        print('cam state gone inactive');
        secretRecordingStarted = false;

        //photoTimer?.cancel();
        // stopRecord();
        secretRecordingStarted = false;
        //Navigator.of(context).pop(true);
        //widget.localAuth.setLocalAuthVale(false);
        //Navigator.pop(context);

        break;
      case AppLifecycleState.detached:
        print('gone detached');
        //widget.localAuth.setLocalAuthVale(false);
        break;
    }
  }

  List<String> localNumbers;

  Future<void> _getNumbers() async {
    final SharedPreferences prefs = await _prefs;
    localNumbers = prefs.getStringList('contacts');

    if (localNumbers.length > 0 && !testModeToggle) {
      if (widget.userData.phoneContact.length > 0)
        for (var i = 0; i < localNumbers.length; i++) {
          bool done = await sendNewSms(localNumbers[i], '', i, 'record');
          print('done $i' + done.toString());
        }

      smsBtnSending();
      sendEvent('sms', 'secret-sms');
      analyticsHelper.sendAnalyticsEvent('Secret_Recording_SMS_Sent');
      sendResearchReport('Secret_Recording_SMS_Sent');
    } else {
      smsNoContacts();
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//static AudioCache audioCache = AudioCache();

  _sendSMSMessages() async {
    if (widget.userData != null && !testModeToggle) {
      if (widget.userData.phoneContact.length == 0) {
        _getNumbers();
      } else {
        for (var i = 0; i < widget.userData.phoneContact.length; i++) {
          bool done = await sendNewSms(widget.userData.phoneContact[i],
              widget.userData.userName, i, 'record');
          print('done $i' + done.toString());
        }
        analyticsHelper.sendAnalyticsEvent('Secret_Recording_SMS_Sent');
        sendResearchReport('Secret_Recording_SMS_Sent');
        smsBtnSending();
        sendEvent('sms', 'secret-sms');
      }
    }
  }

  Future<void> _saveSMSOption(state) async {
    final SharedPreferences prefs = await _prefs;
    prefs.setBool('secretSMS', state);
    sendResearchReport('Secret_Record_SMS_$state');
  }

  Future<void> _saveDummyOption(state) async {
    final SharedPreferences prefs = await _prefs;
    prefs.setBool('secretDummy', state);
    sendResearchReport('Secret_Record_Dummy_$state');
  }

  _switchSMS(bool enabled) {
    setState(() {
      secretRecordSendSMS = !secretRecordSendSMS;
      _saveSMSOption(secretRecordSendSMS);
    });
  }

  _switchDummy(bool enabled) {
    setState(() {
      secretRecordCover = !secretRecordCover;
      _saveDummyOption(secretRecordCover);
    });
  }

  forceUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AutoHomePageMapSelect homePageMap =
        Provider.of<AutoHomePageMapSelect>(context);
    final AutoHomePageAskSelect homePageAsk =
        Provider.of<AutoHomePageAskSelect>(context);

    final SafePageIndex safePageIndex = Provider.of<SafePageIndex>(context);

    final userData = Provider.of<UserData>(context);

    return Center(
      child: Column(
        children: [
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: 20,
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
                  value: secretRecordSendSMS,
                  onChanged: _switchSMS,
                ),
              ),
              SizedBox(width: 8),
              secretRecordSendSMS
                  ? Flexible(
                      child: Text(
                      languages[selectedLanguage[languageIndex]]['doShare'],
                      maxLines: 2,
                      style: myStyle(18),
                      textAlign: TextAlign.left,
                    ))
                  : Flexible(
                      child: Text(
                      languages[selectedLanguage[languageIndex]]['notShare'],
                      maxLines: 2,
                      style: myStyle(18),
                      textAlign: TextAlign.left,
                    )),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
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
                  value: secretRecordCover,
                  onChanged: _switchDummy,
                ),
              ),
              SizedBox(width: 12),
              secretRecordCover
                  ? Text(
                      languages[selectedLanguage[languageIndex]]
                          ['dummyScreenOn'],
                      style: myStyle(18))
                  : Text(
                      languages[selectedLanguage[languageIndex]]
                          ['dummyScreenOff'],
                      style: myStyle(18)),
              Spacer(),
            ],
          ),
          SizedBox(height: 40),
          InkWell(
              onTap: () {
                if (!secretRecordingStarted) {
                  analyticsHelper
                      .sendAnalyticsEvent('Secret_Recording_Started');
                  sendResearchReport('Secret_Recording_Started');

                  if (testModeToggle == false) {
                    firstTime = true;
                    sendEvent('recording', 'secret');
                    //autoCam();
                  }

                  if (secretRecordSendSMS && !testModeToggle) {
                    _sendSMSMessages();
                  }
                  setState(() {
                    secretRecordingStarted = true;
                  });

                  if (secretRecordCover) {
                    analyticsHelper
                        .sendAnalyticsEvent('Secret_Recording_Cover_Screen');
                    sendResearchReport('Secret_Recording_Cover_Screen');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Secrecy(),
                      ),
                    );
                  }
                } else {
                  //photoCount=6;
                  // photoTimer?.cancel();
                  // if (!testModeToggle) stopRecord();
                  setState(() {
                    secretRecordingStarted = false;
                  });
                }
              },
              child: secretRecordingStarted
                  ? languageIndex == 0
                      ? Image.asset(
                          'assets/images/stopTimer.png',
                          width: MediaQuery.of(context).size.width / 1.7,
                        )
                      : Image.asset(
                          'assets/images/stopTimerBN.png',
                          width: MediaQuery.of(context).size.width / 1.7,
                        )
                  : languageIndex == 0
                      ? Image.asset(
                          'assets/images/timerStart.png',
                          width: MediaQuery.of(context).size.width / 1.7,
                        )
                      : Image.asset(
                          'assets/images/timerStartBN.png',
                          width: MediaQuery.of(context).size.width / 1.7,
                        )
              //color: secretRecordingStarted ? Colors.red[50] : null,

              ),
        ],
      ),
    );
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void showInSnackBar(String message) {
    //_scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  //CameraDescription cameraDescription

  uploadImage(String id, String theImagePath) async {
    if (!testModeToggle) {
      File theImageFile = File(theImagePath);
      camPictures = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child(widget.userData.uid)
          .child(getDate().toString());

      StorageUploadTask storageUploadTask =
          camPictures.child(id).putFile(theImageFile);
      StorageTaskSnapshot storageTaskSnapshot =
          await storageUploadTask.onComplete;
      storageTaskSnapshot.ref.getDownloadURL().then((value) {
        print("SNAP Done: $value");
        theImageFile.delete().then((value) => print('DELETE $value'));
      });
      //String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
      //return downloadUrl;

    }
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    cameraDescription = cameras[0];

    if (controller != null) {
      await controller.dispose();
    }
    print(cameraDescription);
    controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: enableAudio,
    );

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        showInSnackBar('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }

    if (firstTime == true) {
      firstTime = false;
      onTakePictureButtonPressed();
    }

    const oneSec = const Duration(seconds: 10);
    if (photoTimer != null) {
      photoTimer.cancel();
    }

    photoTimer =
        new Timer.periodic(oneSec, (Timer t) => onTakePictureButtonPressed());

    startRecord();
  }

  void onTakePictureButtonPressed() async {
    if (photoCount < 100) {
      photoCount += 1;

      Vibration.vibrate(
        pattern: [1000, 500, 1000, 1000],
      );
      takePicture().then((String filePath) {
        if (mounted) {
          setState(() {
            imagePath = filePath;
            //videoController?.dispose();
            //videoController = null;
          });
          if (filePath != null) {
            showInSnackBar('Picture saved to $filePath');
            uploadImage(getRandomString(5), filePath);
          }
        }
      });
    }
  }

//AUDIO ADUIO ADUIO

  Future<bool> checkPermission() async {
    var audStatus = await Permission.microphone.status;
    if (audStatus.isUndetermined) {
      // We didn't ask for permission yet.
      if (await Permission.microphone.request().isGranted) {
        print('mic just granted in cam');
        return true;
        // Either the permission was already granted before or the user just granted it.
      } else {
        return false;
      }
    } else {
      print('was det ret true');
      return true;
    }
  }

  Future<bool> checkPermissionCamera() async {
    var camStatus = await Permission.camera.status;
    if (camStatus.isUndetermined) {
      // We didn't ask for permission yet.
      if (await Permission.camera.request().isGranted) {
        print('cam just granted in cam');
        return true;
        // Either the permission was already granted before or the user just granted it.
      } else {
        return false;
      }
    } else {
      print('was det ret true');
      return true;
    }
  }

  void startRecord() async {
    bool hasPermission = await checkPermission();
    if (hasPermission) {
      statusText = "Recording...";
      recordFilePath = await getFilePath();
      isComplete = false;
      RecordMp3.instance.start(recordFilePath, (type) {
        statusText = "Record error--->$type";
        setState(() {});
      });
    } else {
      showInSnackBar('Need permission to record audio.');
    }
    setState(() {});
  }

  void pauseRecord() {
    if (RecordMp3.instance.status == RecordStatus.PAUSE) {
      bool s = RecordMp3.instance.resume();
      if (s) {
        statusText = "Recording...";
        setState(() {});
      }
    } else {
      bool s = RecordMp3.instance.pause();
      if (s) {
        statusText = "Recording pause...";
        setState(() {});
      }
    }
  }

  void stopRecord() {
    bool s = RecordMp3.instance.stop();
    if (s) {
      statusText = "Record complete";
      isComplete = true;
      setState(() {});
      uploadImage(getRandomString(5) + ' audio', recordFilePath);
    }
  }

  void resumeRecord() {
    bool s = RecordMp3.instance.resume();
    if (s) {
      statusText = "Recording...";
      setState(() {});
    }
  }

  // void play() {
  //   if (recordFilePath != null && File(recordFilePath).existsSync()) {
  //     AudioPlayer audioPlayer = AudioPlayer();
  //     audioPlayer.play(recordFilePath, isLocal: true);
  //   }
  // }

  int i = 0;

  Future<String> getFilePath() async {
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath =
        '${extDir.path}/recordings/bhaithamen/' + getDate().toString();
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.mp3';

    return filePath;

    // Directory storageDirectory = await getApplicationDocumentsDirectory();
    // String sdPath = storageDirectory.path + "/record";
    // var d = Directory(sdPath);
    // if (!d.existsSync()) {
    //   d.createSync(recursive: true);
    // }
    // return sdPath + "/test_${i++}.mp3";
  }

  Future<String> takePicture() async {
    if (!controller.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath =
        '${extDir.path}/recordings/bhaithamen/' + getDate().toString();
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';

    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      await controller.takePicture(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }
}
