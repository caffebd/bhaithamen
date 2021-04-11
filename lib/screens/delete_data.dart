import 'package:bhaithamen/data/userData.dart';
import 'package:bhaithamen/screens/map_wrapper.dart';
import 'package:bhaithamen/utilities/analytics_service.dart';
import 'package:bhaithamen/utilities/auto_page_navigation.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class DeleteData extends StatefulWidget {
  final UserData userData;
  DeleteData(this.userData);
  @override
  _DeleteDataState createState() => _DeleteDataState();
}

class _DeleteDataState extends State<DeleteData> {
  final analyticsHelper = AnalyticsService();
  bool checkConfirm = false;

  String selectedReason;

  TextEditingController message = TextEditingController();

  var reasons = [
    languages[selectedLanguage[languageIndex]]['deleteReason1'],
    languages[selectedLanguage[languageIndex]]['deleteReason2'],
    languages[selectedLanguage[languageIndex]]['deleteReason3'],
  ];

  String userName;
  String userPhone;
  String email;
  List<dynamic> phoneContacts;
  String profilePic;
  int age;

  deleteClear() {
    setState(() {
      checkConfirm = false;
      selectedReason = null;
      message.text = '';
    });
  }

  getCurrentUserInfo() async {
    DocumentSnapshot userDoc =
        await userCollection.doc(widget.userData.uid).get();
    setState(() {
      userName = userDoc['username'];
      userPhone = userDoc['userPhone'];
      email = userDoc['email'];
      phoneContacts = userDoc['phoneContact'];
      profilePic = userDoc['profilepic'];
      age = userDoc['age'];
    });
  }

  _submitDelete() async {
    FocusManager.instance.primaryFocus.unfocus();

    if (checkConfirm == true) {
      await getCurrentUserInfo();

      userCollection
          .doc(widget.userData.uid)
          .set({
            'username': userName,
            'userPhone': userPhone,
            'profilepic': profilePic,
            'uid': widget.userData.uid,
            'email': email,
            'age': age,
            'phoneContact': phoneContacts,
            'requestDeleteData': true,
          })
          .then((doc) {
            requestedDeleteData
                .doc(widget.userData.uid)
                .set({
                  'username': userName,
                  'userPhone': userPhone,
                  'uid': widget.userData.uid,
                  'requestDeleteData': true,
                  'date': DateTime.now()
                })
                .then((doc) {
                  analyticsHelper.sendAnalyticsEvent('Data_Delete_Requested');
                  //sendResearchReport('Data_Delete_Requested');
                  print("doc save successful");
                  showDialog(
                    context: globalContext,
                    builder: (context) => AlertDialog(
                      content: Text(
                          languages[selectedLanguage[languageIndex]]
                              ['deleteDataReview'],
                          style: myStyle(14)),
                      actions: [
                        FlatButton(
                          child: Text(
                              languages[selectedLanguage[languageIndex]]['ok']),
                          onPressed: () {
                            deleteClear();
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
                            content: Text(
                                languages[selectedLanguage[languageIndex]]
                                    ['submitError']),
                            actions: [
                              FlatButton(
                                child: Text(
                                    languages[selectedLanguage[languageIndex]]
                                        ['ok']),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ));
                });
          })
          .timeout(Duration(seconds: 10))
          .catchError((error) {
            print("doc save error");
            print(error);
            showDialog(
                context: globalContext,
                builder: (context) => AlertDialog(
                      content: Text(languages[selectedLanguage[languageIndex]]
                          ['submitError']),
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
    } else {
      deleteNeedCheck();
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
              Text(languages[selectedLanguage[languageIndex]]['deleteData'],
                  style: myStyle(28, Colors.red, FontWeight.w600)),
              SizedBox(height: 18),
              Divider(
                  thickness: 5, color: Colors.red, indent: 40, endIndent: 40),
              SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                      languages[selectedLanguage[languageIndex]]
                          ['checkConfirm'],
                      style: myStyle(21, Colors.black, FontWeight.w500)),
                  Transform.scale(
                    scale: 1.5,
                    child: Checkbox(
                        activeColor: Colors.red,
                        value: checkConfirm,
                        onChanged: (value) {
                          setState(() {
                            checkConfirm = value;
                          });
                        }),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(languages[selectedLanguage[languageIndex]]
                          ['deleteDataExplain']),
                    ),
                  ],
                ),
              ),

              //     SizedBox(height:20),
              //     Card(
              //       margin: EdgeInsets.only(left:50, right:50),
              //       child: InputDecorator(
              //       textAlign: TextAlign.center,
              //       isHovering: true,
              //       decoration: InputDecoration(
              //         contentPadding: EdgeInsets.only(left: 20, right: 20),
              //             //labelStyle: textStyle,
              //         errorStyle: TextStyle(color: Colors.redAccent, fontSize: 16.0),

              //         border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0),
              //             ),
              //         ),
              //         isEmpty: selectedReason == '',

              //       child: DropdownButton<String>(
              //         value: selectedReason,
              //       items: reasons.map((String value) {
              //         return new DropdownMenuItem<String>(
              //           value: value,
              //           child: new Text(value),
              //         );
              //       }).toList(),
              //       onChanged: (value) {
              //         setState(() {
              //             selectedReason = value;
              //           });
              //       },
              //       hint: Text(languages[selectedLanguage[languageIndex]]['deleteReason'], style: myStyle(16, Colors.black, FontWeight.w400)),
              //     ),
              //     ),
              // ),
              //   SizedBox(height:15),

              //   Card(
              //     margin: EdgeInsets.only(left:50, right:50),
              //       child: TextField(
              //       controller: message,
              //       minLines:1,
              //       maxLines: 8,
              //       decoration: InputDecoration(
              //         border: OutlineInputBorder(),
              //         labelText: languages[selectedLanguage[languageIndex]]['message'],
              //       ),
              //     ),
              //   ),
              SizedBox(height: 20),
              RaisedButton(
                elevation: 5.0,
                color: Colors.red,
                onPressed: () {
                  FocusManager.instance.primaryFocus.unfocus();
                  _submitDelete();
                },
                child: new Text(
                  languages[selectedLanguage[languageIndex]]['reallyDeleteBtn'],
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
