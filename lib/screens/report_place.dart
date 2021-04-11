import 'package:bhaithamen/screens/map_wrapper.dart';
import 'package:bhaithamen/utilities/analytics_service.dart';
import 'package:bhaithamen/utilities/auto_page_navigation.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/report_event.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;

class ReportPlace extends StatefulWidget {
  final String name;
  final LatLng location;
  final String docId;
  final String category;
  ReportPlace(this.name, this.location, this.docId, this.category);
  @override
  _ReportPlaceState createState() => _ReportPlaceState();
}

class _ReportPlaceState extends State<ReportPlace> {
  final analyticsHelper = AnalyticsService();
  bool checkConfirm = false;

  String selectedReason;

  TextEditingController message = TextEditingController();

  var reasons = [
    languages[selectedLanguage[languageIndex]]['reportReason1'],
    languages[selectedLanguage[languageIndex]]['reportReason2'],
    languages[selectedLanguage[languageIndex]]['reportReason3'],
  ];

  String userName;
  String userPhone;
  String email;
  List<dynamic> phoneContacts;
  String profilePic;
  int age;
  String uid;

  deleteClear() {
    setState(() {
      selectedReason = null;
      message.text = '';
    });
  }

  initState() {
    super.initState();
    getCurrentUserInfo();
  }

  getCurrentUserInfo() async {
    var firebaseuser = fbAuth.FirebaseAuth.instance.currentUser;
    DocumentSnapshot userDoc = await userCollection.doc(firebaseuser.uid).get();
    setState(() {
      uid = firebaseuser.uid;
      userName = userDoc['username'];
      userPhone = userDoc['userPhone'];
      email = userDoc['email'];
      phoneContacts = userDoc['phoneContact'];
      profilePic = userDoc['profilepic'];
      age = userDoc['age'];
    });
  }

  _submitReport() async {
    DocumentSnapshot placeDoc = await safePlaceCollection
        .doc('dhaka')
        .collection(widget.category)
        .doc(widget.docId)
        .get();

    List<dynamic> allReports = placeDoc['reports'];

    allReports.add(uid);

    await safePlaceCollection
        .doc('dhaka')
        .collection(widget.category)
        .doc(widget.docId)
        .update({
      'reports': allReports,
    }).then((doc) async {
      print("doc save successful");
      showDialog(
        context: globalContext,
        builder: (context) => AlertDialog(
          content: Text(
              languages[selectedLanguage[languageIndex]]
                  ['reportPlaceSubmitted'],
              style: myStyle(14)),
          actions: [
            FlatButton(
              child: Text(languages[selectedLanguage[languageIndex]]['ok']),
              onPressed: () {
                deleteClear();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    });

    final newEvent = {
      'userId': uid,
      'message': message.text,
      'reason': selectedReason,
      'time': DateTime.now()
    };

//need to change below

    int unixDate = getDate().toUtc().millisecondsSinceEpoch;

    DocumentSnapshot cat = await reportedCollection.doc(widget.docId).get();
    if (cat.exists) {
      reportedCollection.doc(widget.docId).update({
        "createdAt": unixDate,
        "reports": FieldValue.arrayUnion([newEvent])
      });
    } else {
      reportedCollection.doc(widget.docId).set({
        "createdAt": unixDate,
        "reports": FieldValue.arrayUnion([newEvent])
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AutoHomePageMapSelect homePageMap =
        Provider.of<AutoHomePageMapSelect>(context);
    final AutoHomePageAskSelect homePageAsk =
        Provider.of<AutoHomePageAskSelect>(context);
    final SafePageIndex safePageIndex = Provider.of<SafePageIndex>(context);

    globalContext = context;

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
                  })
          ]),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              SizedBox(height: 18),
              Text(
                  languages[selectedLanguage[languageIndex]]
                      ['reportScreenTitle'],
                  style: myStyle(28, Colors.red, FontWeight.w600)),
              SizedBox(height: 18),
              Divider(
                  thickness: 5, color: Colors.red, indent: 40, endIndent: 40),
              SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.name,
                      style: myStyle(21, Colors.black, FontWeight.w500)),
                ],
              ),
              SizedBox(height: 12),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(languages[selectedLanguage[languageIndex]]
                          ['reportDescription']),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Card(
                margin: EdgeInsets.only(left: 50, right: 50),
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
                  isEmpty: selectedReason == '',
                  child: DropdownButton<String>(
                    value: selectedReason,
                    items: reasons.map((String value) {
                      return new DropdownMenuItem<String>(
                        value: value,
                        child: new Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value;
                      });
                    },
                    hint: Text(
                        languages[selectedLanguage[languageIndex]]
                            ['deleteReason'],
                        style: myStyle(16, Colors.black, FontWeight.w400)),
                  ),
                ),
              ),
              SizedBox(height: 15),
              Card(
                margin: EdgeInsets.only(left: 50, right: 50),
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
              SizedBox(height: 20),
              RaisedButton(
                elevation: 5.0,
                color: Colors.red,
                onPressed: () {
                  FocusManager.instance.primaryFocus.unfocus();
                  _submitReport();
                },
                child: new Text(
                  languages[selectedLanguage[languageIndex]]['reportButton'],
                  style: myStyle(18, Colors.white),
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
