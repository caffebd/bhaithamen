import 'dart:async';
import 'dart:io';

import 'package:bhaithamen/data/userData.dart';
import 'package:bhaithamen/screens/expired.dart';
import 'package:bhaithamen/screens/map_wrapper.dart';
import 'package:bhaithamen/screens/profile_page.dart';
import 'package:bhaithamen/utilities/analytics_service.dart';
import 'package:bhaithamen/utilities/fb_test.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/overlay_sets.dart';
import 'package:bhaithamen/utilities/report_event.dart';
import 'package:bhaithamen/utilities/send_sms.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Welcome extends StatefulWidget {
  @override
  _WelcomeState createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  final analyticsHelper = AnalyticsService();

  List<String> localNumbers;

  StorageReference camPictures;

  bool expired = false;
  bool killed = false;

  @override
  void initState() {
    super.initState();
    checkLocalFiles();
    analyticsHelper.testSetCurrentScreen('home_screen');

    useOverlay = 'welcome';

  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  Future<void> _getNumbers() async {
    final SharedPreferences prefs = await _prefs;
    localNumbers = prefs.getStringList('contacts');

    if (localNumbers != null) {
      if (localNumbers.length > 0) {
        for (var i = 0; i < localNumbers.length; i++) {
          bool done = await sendNewSms(localNumbers[i], '', i, 'button');
          print('done $i' + done.toString());
        }

        smsBtnSending();
        sendEvent('sms', 'user-sms');
      } else {
        smsNoContacts();
      }
    } else {
      smsNoContacts();
    }
  }

  doUpload(File theImageFile, madeDate, id) async {
    var firebaseuser = FirebaseAuth.instance.currentUser;

    camPictures = FirebaseStorage.instance
        .ref()
        .child('user_images')
        .child(firebaseuser.uid)
        .child(madeDate);

    StorageUploadTask storageUploadTask =
        camPictures.child(id).putFile(theImageFile);
    StorageTaskSnapshot storageTaskSnapshot =
        await storageUploadTask.onComplete;
    storageTaskSnapshot.ref.getDownloadURL().then((value) {
      print("SNAP Done: $value");
      theImageFile.delete().then((value) => print('DELETE $value'));
    });
  }

  checkLocalFiles() async {
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    final Directory mainOne = new Directory(dirPath);
    mainOne
        .list(recursive: true, followLinks: false)
        .listen((FileSystemEntity entity) async {
      print(entity.path);

      bool hasIt = await File(entity.path).exists();

      if (hasIt) {
        File needFile = new File(entity.path);

        String madeDate = basename(needFile.parent.toString());
        String id = basename(needFile.path);

        doUpload(needFile, madeDate, id);
      }
    });
  }

  checkIfExpired() async {
    final SharedPreferences prefs = await _prefs;


    expired = prefs.getBool('expired');
    if (expired == null) {
      expired = false;
    } else {
      if (expired == true) return;
    }

    var now = DateTime.now();
    var expiryDate = DateTime.utc(2021, 3, 31);

    expired = now.isAfter(expiryDate);
    prefs.setBool('expired', expired);
  }

  FutureOr onGoBack(dynamic value) {
    checkIfExpired();
    setState(() {});
  }

  void navigateMapPage(mycontext) {
    analyticsHelper.sendAnalyticsEvent('Mapping_Opened');
    sendResearchReport('Mapping_Opened');

    Route route = MaterialPageRoute(
      builder: (context) => MapWrapper(),
      settings: RouteSettings(name: 'Mapping'),
    );
    Navigator.push(mycontext, route).then(onGoBack);
  }

  @override
  Widget build(BuildContext context) {
    globalContext = context;

    final userData = Provider.of<UserData>(context);

    if (userData == null) {
      return CircularProgressIndicator();
    } else if (expired == true || userData.killed == true) {
      Future.delayed(Duration.zero, () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Expired(),
          ),
        );
      });
      return Container();
    } else {
      return Center(
        child: userData == null
            ? CircularProgressIndicator()
            : Column(
                children: [
                  SizedBox(height: 15),
                  Text(
                    languages[selectedLanguage[languageIndex]]['welcome'],
                    style: myStyle(35),
                    textAlign: TextAlign.center,
                  ),
                  userData.age == 0 || userData.phoneContact.length == 0
                      ? Column(
                          children: [
                            SizedBox(height: 20),
                            ButtonTheme(
                              minWidth:
                                  (MediaQuery.of(context).size.width / 1.2),
                              height: 60.0,
                              child: RaisedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProfilePage(userData),
                                    ),
                                  );
                                },
                                // padding: EdgeInsets.only(left: MediaQuery.of(context).size.width/4, right: MediaQuery.of(context).size.width/4, top: 15, bottom:15),
                                color: Colors.red[700],
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    side: BorderSide(
                                        color: Colors.black, width: 4)),
                                child: Text(
                                  languages[selectedLanguage[languageIndex]]
                                      ['setupProfile'],
                                  style: myStyle(26, Colors.white),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                          ],
                        )
                      : SizedBox(height: 10),
                  SizedBox(height: 20),
                  Container(
                      width: 150,
                      height: 150,
                      child: InkWell(
                        onLongPress: () async {
                          analyticsHelper.sendAnalyticsEvent('Home_SMS_Press');
                          sendResearchReport('Home_SMS_Press');
                          if (userData.phoneContact.length == 0) {
                            _getNumbers();
                          } else {
                            List<String> numbs = List<String>();
                            for (var n in userData.phoneContact) {
                              numbs.add(n);
                            }
                            if (userData.phoneContact.length > 0)
                              for (var i = 0;
                                  i < userData.phoneContact.length;
                                  i++) {
                                bool done = await sendNewSms(
                                    userData.phoneContact[i],
                                    userData.userName,
                                    i,
                                    'button');
                                print('done $i' + done.toString());
                              }
                            smsBtnSending();
                            sendEvent('sms', 'user-sms');
                          }
                        },
                        onTap: () async {
                          smsLongPress();
                        },
                        child: Container(
                          child: languageIndex == 0
                              ? Image.asset(
                                  'assets/images/sosSMS.png',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.fill,
                                )
                              : Image.asset(
                                  'assets/images/sosSMSBN.png',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.fill,
                                ),
                        ),
                      )),
                  SizedBox(height: 45),
                  ButtonTheme(
                    minWidth: (MediaQuery.of(context).size.width / 3) * 2,
                    height: 50.0,
                    child: RaisedButton(
                      onPressed: () {
                        analyticsHelper.testSetCurrentScreen('mapping');
                        navigateMapPage(context);
                      },
                      // padding: EdgeInsets.only(left: MediaQuery.of(context).size.width/4, right: MediaQuery.of(context).size.width/4, top: 15, bottom:15),
                      color: Colors.blue[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        //side: BorderSide(color: Colors.red, width:4)
                      ),
                      child: Text(
                        languages[selectedLanguage[languageIndex]]
                            ['safetyZones'],
                        style: myStyle(26, Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
      );
    }
  }
}
