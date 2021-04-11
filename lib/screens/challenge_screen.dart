import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:bhaithamen/screens/map_wrapper.dart';
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
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:record_mp3/record_mp3.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:ocarina/ocarina.dart';

class ChallengeScreen extends StatefulWidget {
  final style;
  final UserData userData;
  final option;

  ChallengeScreen(this.style, this.userData, this.option); //, this.userData);

  @override
  _ChallengeScreenState createState() => _ChallengeScreenState();
}

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
Random _rnd = Random();
int photoCount = 0;
Timer photoTimer;
bool alarmPlaying = false;
bool recordingStarted = false;
bool firstTime = true;

Timer challengeTimer;

class _ChallengeScreenState extends State<ChallengeScreen>
    with WidgetsBindingObserver {
  final analyticsHelper = AnalyticsService();
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

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

  OcarinaPlayer player;

  double textOffset = 50;
  double textSize = 32;

  loadLocal() async {
    if (alarmPlayer != null) {
      if (alarmPlayer.isLoaded()) {
        await alarmPlayer.dispose();
      }
    }

    alarmPlayer = OcarinaPlayer(
      asset: 'assets/audio/alarm.mp3',
      loop: true,
      volume: 1,
    );

    await alarmPlayer.load();
    alarmPlayer.play();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    analyticsHelper.testSetCurrentScreen('challenge_screen');
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
    analyticsHelper.sendAnalyticsEvent('Challenge_Screen_Open');
    sendResearchReport('Challenge_Screen_Open');

    _triggerEvents();

    switch (widget.option) {
      case 0:
        textSize = 46;
        break;
      case 1:
        if (languageIndex == 0) {
          textSize = 34;
        } else {
          textSize = 46;
        }
        break;
      case 2:
        textSize = 32;
        break;
      case 3:
        textSize = 32;
        break;
    }

    //autoCam();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    alarmPlaying = false;

    recordingStarted = false;
    photoTimer?.cancel();
    if (alarmPlayer != null) {
      alarmPlayer.stop();
      alarmPlayer.dispose();
    }

    Navigator.pop(context);

    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void logError(String code, String message) =>
      print('Error: $code\nError Message: $message');

  autoCam() async {
    bool hasPermission = await checkPermissionCamera();
    if (hasPermission) {
      cameras = await availableCameras();
      onNewCameraSelected(cameras[1]);
    } else {
      showInSnackBar('Need permission to take photos');
      setState(() {
        recordingStarted = false;
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
        if (secretRecordInactive == true) {
          secretRecordInactive = false;
          // Navigator.pop(context);
        }

        //controller?.dispose();
        // if (controller != null) {
        //   onNewCameraSelected(controller.description);
        // }
        break;
      case AppLifecycleState.inactive:
        print('cam state gone inactive');
        recordingStarted = false;

        photoTimer?.cancel();
        //if (!testModeToggle) stopRecord();
        recordingStarted = false;
        secretRecordInactive = true;

        controller?.dispose();
        alarmPlaying = false;
        if (alarmPlayer != null) {
          alarmPlayer.stop();
          alarmPlayer.dispose();
        }

        //player?.stop();

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

  Future<bool> _onBackPressed() {
    return showDialog(
        context: context,
        builder: (context) => new AlertDialog(
            title:
                new Text(languages[selectedLanguage[languageIndex]]['alert']),
            content: Container(
                height: 150,
                child: Center(
                      child: Column(
                        children: [
                          Text(
                              languages[selectedLanguage[languageIndex]]
                                  ['checkLeave'],
                              style: myStyle(20)),
                          SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Spacer(),
                              FlatButton(
                                child: Text(
                                    languages[selectedLanguage[languageIndex]]
                                        ['stay'],
                                    style: myStyle(22, Colors.white)),
                                textColor: Colors.white,
                                color: Colors.red,
                                onPressed: () async {
                                  Navigator.of(context).pop(false);
                                },
                              ),
                              SizedBox(width: 18),
                              FlatButton(
                                child: Text(
                                    languages[selectedLanguage[languageIndex]]
                                        ['leave'],
                                    style: myStyle(22, Colors.white)),
                                textColor: Colors.white,
                                color: Colors.green,
                                onPressed: () async {
                                  // photoTimer?.cancel();
                                  // stopRecord();
                                  recordingStarted = false;
                                  //Navigator.of(context).pop(true);
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                              ),
                              Spacer(),
                            ],
                          ),
                        ],
                      ),
                    ) ??
                    false)));
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//static AudioCache audioCache = AudioCache();

  List<String> localNumbers;

  Future<void> _getNumbers() async {
    final SharedPreferences prefs = await _prefs;
    localNumbers = prefs.getStringList('contacts');

    if (localNumbers.length > 0 && !testModeToggle) {
      for (var i = 0; i < localNumbers.length; i++) {
        bool done = await sendNewSms(localNumbers[i], '', i, 'record');
        print('done $i' + done.toString());
      }

      //smsBtnSending();
      sendEvent('sms', 'challenge-sms');
    } else {
      smsNoContacts();
    }
  }

  _triggerEvents() async {
    Duration timeOut =
        Duration(seconds: 2); //Duration(minutes:askDuration.inMinutes);
    challengeTimer = Timer(timeOut, () async {
      setState(() {
        recordingStarted = true;
        photoCount = 0;
      });

      if (testModeToggle == false) {
        firstTime = true;
        // autoCam();
      }

      if (widget.userData != null &&
          !testModeToggle &&
          challengeRecordSendSMS) {
        if (widget.userData.phoneContact.length == 0) {
          _getNumbers();
        } else {
          for (var i = 0; i < widget.userData.phoneContact.length; i++) {
            bool done = await sendNewSms(widget.userData.phoneContact[i],
                widget.userData.userName, i, 'record');
            print('done $i' + done.toString());
          }
          sendEvent('sms', 'challenge-sms');
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final AutoHomePageMapSelect homePageMap =
        Provider.of<AutoHomePageMapSelect>(context);
    final AutoHomePageAskSelect homePageAsk =
        Provider.of<AutoHomePageAskSelect>(context);

    final SafePageIndex safePageIndex = Provider.of<SafePageIndex>(context);

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
            title: testModeToggle
                ? Text(languages[selectedLanguage[languageIndex]]['testOn'],
                    style: myStyle(18, Colors.white))
                : Text(languages[selectedLanguage[languageIndex]]['title'],
                    style: myStyle(18, Colors.white)),
            backgroundColor: testModeToggle ? Colors.red : Colors.blue,
            actions: <Widget>[
              //if (homePageMap.shouldGoMap) FlatButton(child: Lottie.asset('assets/lottie/alert.json'), onPressed: (){ setState(() {homePageIndex = 1; safePageIndex.setSafePageIndex(0);savedSafeIndex=0;homePageMap.setHomePageMap(false);Navigator.pop(context);});}),
              if (homePageAsk.shouldGoAsk)
                FlatButton(
                    child: Lottie.asset('assets/lottie/alert.json'),
                    onPressed: () {
                      setState(() {
                        homePageIndex = 2;
                        safePageIndex.setSafePageIndex(0);
                        savedSafeIndex = 0;
                        homePageAsk.setHomePageAsk(false);
                        Navigator.pop(context);
                      });
                    }),
              if (homePageMap.shouldGoMap)
                FlatButton(
                    child: Lottie.asset('assets/lottie/alert.json'),
                    onPressed: () {
                      setState(() {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MapWrapper(),
                          ),
                        );
                        //homePageIndex = 1; safePageIndex.setSafePageIndex(0);savedSafeIndex=0;homePageMap.setHomePageMap(false);
                      });
                    })
              // IconButton(icon: Icon(Icons.exit_to_app), onPressed: _checkOnExit,),
            ]),
        body: Center(
          child: Column(
            children: [
              Container(
                width: 400,
                height: 500,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: <Widget>[
                    Positioned(
                      top: 40,
                      left: 0,
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 40),
                        height: 300,
                        width: 280,
                        child: Container(),
                        color: Colors.red,
                      ),
                    ),
                    Positioned(
                      top: 50,
                      //left: textOffset,
                      child: Container(
                        height: 100,
                        width: 200,
                        child: Column(
                          children: [
                            Flexible(
                                child: Text(
                              widget.style.toUpperCase(),
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              style: myStyle(
                                  textSize, Colors.white, FontWeight.w600),
                            )),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 140,
                      left: 90,
                      child: Container(
                        height: 190,
                        child: Center(
                            child: Image.asset('assets/images/handStop.png')),
                      ),
                    ),
                    Positioned(
                      top: 360,
                      child: InkWell(
                        onTap: () async {
                          if (alarmPlaying) {
                            //audioCache.clear('audio/alarm.mp3');

                            if (alarmPlayer != null) {
                              alarmPlayer.stop();
                              alarmPlayer.dispose();
                            }
                            print('STOP');
                          } else {
                            analyticsHelper.sendAnalyticsEvent(
                                'Challenge_Screen_Alarm_Used');
                            sendResearchReport('Challenge_Screen_Alarm_Used');

                            print('START');
                            sendEvent('alarm', 'alarm');

                            loadLocal();
                            //player.play();

                          }
                          setState(() {
                            alarmPlaying = !alarmPlaying;
                          });
                        },
                        child: Image.asset(
                          'assets/images/alarm.png',
                          width: 120,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
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
    }
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    cameraDescription = cameras[1];

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

    var tenSec = Duration(seconds: 10);

    if (firstTime == true) {
      firstTime = false;
      onTakePictureButtonPressed();
    }

    if (photoTimer != null) {
      photoTimer.cancel();
    }

    photoTimer =
        new Timer.periodic(tenSec, (Timer t) => onTakePictureButtonPressed());
    //analyticsHelper.sendAnalyticsEvent('Challenge_Screen_Recording_Start');
    //sendResearchReport('Challenge_Screen_Recording_Start');
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
            //showInSnackBar('Picture saved to $filePath');
            uploadImage(getRandomString(8), filePath);
          }
        }
      });
    } else {
      analyticsHelper.sendAnalyticsEvent('Challenge_More_Than_100_Photos');
      sendResearchReport('Challenge_More_Than_100_Photos');
      //photoTimer?.cancel();
      //stopRecord();
      setState(() {
        recordingStarted = false;
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

      print('aud path ' + recordFilePath);

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
      sendEvent('recording', 'challenge');
      //analyticsHelper.sendAnalyticsEvent('Challenge_Screen_Recording_Stop');
      //sendResearchReport('Challenge_Screen_Recording_Stop');
    }
  }

  void resumeRecord() {
    bool s = RecordMp3.instance.resume();
    if (s) {
      statusText = "Recording...";
      setState(() {});
    }
  }

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
