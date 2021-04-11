import 'dart:io';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:bhaithamen/data/userData.dart';
import 'package:bhaithamen/screens/map_wrapper.dart';
import 'package:bhaithamen/utilities/analytics_service.dart';
import 'package:bhaithamen/utilities/auto_page_navigation.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/report_event.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record_mp3/record_mp3.dart';

class AppFeedback extends StatefulWidget {
  final UserData userData;
  AppFeedback(this.userData);
  @override
  _AppFeedbackState createState() => _AppFeedbackState();
}

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
Random _rnd = Random();

class _AppFeedbackState extends State<AppFeedback> {
  final analyticsHelper = AnalyticsService();

  CameraController controller;

  String topic;
  String hearBack;

  TextEditingController message = TextEditingController();

  StorageReference camPictures;

  String recordFilePath;
  bool isComplete = false;
  bool sendAudio = false;
  bool sendImage = false;

  bool isRecording = false;

  String imagePath;
  String feedbackUid;

  File imageFile;
  String pickedImagePath;

  int i = 0;

  //List<String> feedbackTopics;
  //var hearBackOptions;

  @override
  void initState() {
    super.initState();
    analyticsHelper.testSetCurrentScreen('app_feedback');
  }

  var feedbackTopics = [
    languages[selectedLanguage[languageIndex]]['feedbackTopic1'],
    languages[selectedLanguage[languageIndex]]['feedbackTopic2'],
    languages[selectedLanguage[languageIndex]]['feedbackTopic3']
  ];

  var hearBackOptions = [
    languages[selectedLanguage[languageIndex]]['anonymous'],
    languages[selectedLanguage[languageIndex]]['byEmail'],
    languages[selectedLanguage[languageIndex]]['byPhone'],
  ];

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  uploadImage(String id, String theImagePath) async {
    File theImageFile = File(theImagePath);
    camPictures = FirebaseStorage.instance
        .ref()
        .child('feedback')
        .child(feedbackUid)
        .child(getDate().toString());

    StorageUploadTask storageUploadTask =
        camPictures.child(id).putFile(theImageFile);
    StorageTaskSnapshot storageTaskSnapshot =
        await storageUploadTask.onComplete;
    String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<String> getFilePath(String type) async {
    Directory storageDirectory = await getApplicationDocumentsDirectory();
    String sdPath = storageDirectory.path + "/feedback-" + type;
    var d = Directory(sdPath);
    if (!d.existsSync()) {
      d.createSync(recursive: true);
    }
    return sdPath + "/test_${i++}.mp3";
  }

  Future<bool> checkPermission() async {
    var audStatus = await Permission.microphone.status;
    if (audStatus.isUndetermined) {
      // We didn't ask for permission yet.
      if (await Permission.microphone.request().isGranted) {
        return true;
        // Either the permission was already granted before or the user just granted it.
      } else {
        return false;
      }
    } else {
      return true;
    }
  }

  void startRecord() async {
    bool hasPermission = await checkPermission();
    if (hasPermission) {
      recordFilePath = await getFilePath('audio');
      isComplete = false;
      setState(() {
        isRecording = true;
      });
      RecordMp3.instance.start(recordFilePath, (type) {});
    } else {
      //showInSnackBar('Need permission to record audio.');
    }
    //setState(() {isRecording=false;});
  }

  void stopRecord() {
    bool s = RecordMp3.instance.stop();
    if (s) {
      isComplete = true;
      sendAudio = true;
      setState(() {
        isRecording = false;
      });
    }
  }

  pickImage(ImageSource source) async {
    final image = await ImagePicker().getImage(source: source);
    setState(() {
      imageFile = File(image.path);
      pickedImagePath = image.path;
      sendImage = true;
    });
    Navigator.pop(context);

    needThePin = true;
    appHasStarted = true;
  }

  optionsDialog() {
    return showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            children: [
              SimpleDialogOption(
                  onPressed: () {
                    needThePin = false;
                    appHasStarted = false;
                    pickImage(ImageSource.gallery);
                  },
                  child: Text(
                      languages[selectedLanguage[languageIndex]]
                          ['galleryImage'],
                      style: myStyle(18))),
              SimpleDialogOption(
                  onPressed: () => pickImage(ImageSource.camera),
                  child: Text(
                      languages[selectedLanguage[languageIndex]]['cameraImage'],
                      style: myStyle(18))),
              SimpleDialogOption(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                      languages[selectedLanguage[languageIndex]]['cancel'],
                      style: myStyle(18))),
            ],
          );
        });
  }

  _submitFeedback() async {
    feedbackUid = getRandomString(8);

    String email;
    String userName;
    String sendId;
    String phone;

    if (hearBack != languages[selectedLanguage[languageIndex]]['anonymous']) {
      email = widget.userData.email;
      userName = widget.userData.userName;
      sendId = widget.userData.uid;
      phone = widget.userData.userPhone;
    } else {
      email = 'anon';
      userName = 'anon';
      sendId = 'anon';
      phone = 'anon';
    }

    feedbackCollection
        .doc(feedbackUid)
        .set({
          'feedbackUid': feedbackUid,
          'username': userName,
          'topic': topic,
          'message': message.text,
          'uid': sendId,
          'email': email,
          'phone': phone,
          'date': DateTime.now()
          //'phoneContact': phoneNumbers
        })
        .then((doc) {
          print("doc save successful");
          analyticsHelper.sendAnalyticsEvent('Feedback_sent',
              param: 'hear_back:' + hearBack);
          //sendResearchReport('Feedback_sent');
          showDialog(
            context: globalContext,
            builder: (context) => AlertDialog(
              content: Text(languages[selectedLanguage[languageIndex]]
                  ['feedbackThankYou']),
              actions: [
                FlatButton(
                  child: Text(languages[selectedLanguage[languageIndex]]['ok']),
                  onPressed: () {
                    fedbackClear();
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
          showDialog(
              context: globalContext,
              builder: (context) => AlertDialog(
                    content: Text(languages[selectedLanguage[languageIndex]]
                        ['feedbackError']),
                    actions: [
                      FlatButton(
                        child: Text(
                            languages[selectedLanguage[languageIndex]]['ok']),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ));
        });

    String imgDone = '';
    String audDone = '';

    if (sendAudio) {
      imgDone =
          await uploadImage(feedbackUid + 'feedback_audio', recordFilePath);
    }
    if (sendImage) {
      audDone =
          await uploadImage(feedbackUid + 'feedback_image', pickedImagePath);
    }
  }

  fedbackClear() {
    setState(() {
      isComplete = false;
      sendAudio = false;
      sendImage = false;
      hearBack = null;
      topic = null;
      message.text = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final AutoHomePageMapSelect homePageMap =
        Provider.of<AutoHomePageMapSelect>(context);
    final AutoHomePageAskSelect homePageAsk =
        Provider.of<AutoHomePageAskSelect>(context);
    final SafePageIndex safePageIndex = Provider.of<SafePageIndex>(context);

    return Scaffold(
      appBar: AppBar(
          title: testModeToggle
              ? Text(languages[selectedLanguage[languageIndex]]['testOn'],
                  style: myStyle(18, Colors.white))
              : Text(languages[selectedLanguage[languageIndex]]['title'],
                  style: myStyle(18, Colors.white)),
          backgroundColor: testModeToggle ? Colors.red : Colors.blue,
          actions: <Widget>[
            //if (homePageMap.shouldGoMap) FlatButton(child: Lottie.asset('assets/lottie/alert.json'), onPressed: (){ setState(() {homePageIndex = 1; safePageIndex.setSafePageIndex(0);savedSafeIndex=0;homePageMap.setHomePageMap(false);});}),
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
                  }),
            IconButton(
                icon: Icon(Icons.settings, size: 35),
                onPressed: () {
                  Navigator.pop(context);
                }),
          ]),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              SizedBox(height: 20),
              Text(
                  languages[selectedLanguage[languageIndex]]['welcomeFeedback'],
                  style: myStyle(20)),
              SizedBox(height: 20),
              Card(
                margin: EdgeInsets.only(left: 30, right: 30),
                child: InputDecorator(
                  textAlign: TextAlign.center,
                  isHovering: true,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.only(left: 20, right: 20),
                    //labelStyle: textStyle,
                    errorStyle:
                        TextStyle(color: Colors.redAccent, fontSize: 16.0),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  isEmpty: topic == '',
                  child: DropdownButton<String>(
                    value: topic,
                    items: feedbackTopics.map((String value) {
                      return new DropdownMenuItem<String>(
                        value: value,
                        child: new Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        topic = value;
                      });
                    },
                    hint: Text(
                        languages[selectedLanguage[languageIndex]]
                            ['selectTopic'],
                        style: myStyle(18, Colors.black, FontWeight.w400)),
                  ),
                ),
              ),
              SizedBox(height: 15),
              Card(
                margin: EdgeInsets.only(left: 40, right: 40),
                child: TextField(
                  controller: message,
                  minLines: 1,
                  maxLines: 8,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: languages[selectedLanguage[languageIndex]]
                        ['message'],
                  ),
                ),
              ),
              SizedBox(height: 15),
              SizedBox(
                height: 100,
                child: InkWell(
                  onTap: () {
                    FocusManager.instance.primaryFocus.unfocus();
                    if (isRecording == false) {
                      if (sendAudio) {
                        setState(() {
                          sendAudio = false;
                        });
                      } else {
                        startRecord();
                      }
                    } else {
                      stopRecord();
                    }
                  },
                  child: Card(
                    color: isRecording ? Colors.red : Colors.white,
                    margin: EdgeInsets.only(left: 40, right: 40),
                    child: Row(
                      children: [
                        sendAudio
                            ? Icon(Icons.check_box,
                                size: 50, color: Colors.green)
                            : Icon(Icons.mic_none_rounded, size: 50),
                        Flexible(
                            child: Text(
                          languages[selectedLanguage[languageIndex]]
                              ['tapRecord'],
                          style: myStyle(14),
                          textAlign: TextAlign.center,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 15),
              SizedBox(
                height: 70,
                child: InkWell(
                  onTap: () {
                    FocusManager.instance.primaryFocus.unfocus();
                    if (sendImage) {
                      setState(() {
                        sendImage = false;
                      });
                    } else {
                      optionsDialog();
                    }
                  },
                  child: Card(
                    margin: EdgeInsets.only(left: 40, right: 40),
                    child: Row(
                      children: [
                        sendImage
                            ? Icon(Icons.check_box,
                                size: 50, color: Colors.green)
                            : Icon(Icons.photo, size: 50),
                        Flexible(
                            child: Text(
                          languages[selectedLanguage[languageIndex]]
                              ['tapPhoto'],
                          style: myStyle(14),
                          textAlign: TextAlign.center,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 18),
              Card(
                margin: EdgeInsets.only(left: 30, right: 30),
                child: InputDecorator(
                  textAlign: TextAlign.center,
                  isHovering: true,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.only(left: 0, right: 0),
                    //labelStyle: textStyle,
                    errorStyle:
                        TextStyle(color: Colors.redAccent, fontSize: 16.0),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  isEmpty: hearBack == '',
                  child: DropdownButton<String>(
                    value: hearBack,
                    items: hearBackOptions.map((String value) {
                      return new DropdownMenuItem<String>(
                        value: value,
                        child: new Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        FocusManager.instance.primaryFocus.unfocus();
                        hearBack = value;
                      });
                    },
                    hint: AutoSizeText(
                        languages[selectedLanguage[languageIndex]]
                            ['canContact'],
                        maxLines: 1,
                        style: myStyle(12, Colors.black, FontWeight.w400)),
                  ),
                ),
              ),
              SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.only(right: 22, top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    RaisedButton(
                      elevation: 5.0,
                      color: Colors.blue,
                      onPressed: () {
                        FocusManager.instance.primaryFocus.unfocus();
                        _submitFeedback();
                      },
                      child: new Text(
                        languages[selectedLanguage[languageIndex]]['submitBtn'],
                        style: myStyle(18, Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}
