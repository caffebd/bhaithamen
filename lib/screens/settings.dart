import 'package:auto_size_text/auto_size_text.dart';
import 'package:bhaithamen/data/userData.dart';
import 'package:bhaithamen/screens/app_feedback.dart';
import 'package:bhaithamen/screens/delete_account.dart';
import 'package:bhaithamen/screens/delete_data.dart';
import 'package:bhaithamen/screens/events_wrapper.dart';
import 'package:bhaithamen/screens/map_wrapper.dart';
import 'package:bhaithamen/screens/profile_page.dart';
import 'package:bhaithamen/screens/reports_wrapper.dart';
import 'package:bhaithamen/screens/select_secret.dart';
import 'package:bhaithamen/screens/tutorial_main.dart';
import 'package:bhaithamen/utilities/analytics_service.dart';
import 'package:bhaithamen/utilities/auth.dart';
import 'package:bhaithamen/utilities/auto_page_navigation.dart';
import 'package:bhaithamen/utilities/fb_test.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final AuthService _auth = AuthService();

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  final analyticsHelper = AnalyticsService();

  final GlobalKey<ScaffoldState> _scaffoldKeyHome = GlobalKey<ScaffoldState>();

  UserData userData;

  bool _isEnglish;

  @override
  void initState() {
    super.initState();
    globalContext = context;
    if (showMapPopup) {
      mapFlushBar();
      print('MAIN init state map pop');
    }
    if (showAskPopup) {
      askFlushBar();
      print('MAIN init state ask pop');
    }

    if (languageIndex == 0) {
      _isEnglish = true;
    } else {
      _isEnglish = false;
    }
  }

  Future<bool> _exitApp(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
            title: Text(
                languages[selectedLanguage[languageIndex]]['checkSignOut1']),
            content: Container(
                height: 180,
                width: 320,
                child: Center(
                      child: Column(
                        children: [
                          Text(
                              languages[selectedLanguage[languageIndex]]
                                  ['checkSignOut2'],
                              style: myStyle(20, Colors.red, FontWeight.w400)),
                          SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Spacer(),
                              FlatButton(
                                child: Text(
                                    languages[selectedLanguage[languageIndex]]
                                        ['stay'],
                                    style: myStyle(14, Colors.white)),
                                textColor: Colors.white,
                                color: Colors.red,
                                onPressed: () async {
                                  Navigator.of(context).pop(false);
                                },
                              ),
                              SizedBox(width: 14),
                              FlatButton(
                                child: AutoSizeText(
                                    languages[selectedLanguage[languageIndex]]
                                        ['signOut'],
                                    maxLines: 2,
                                    style: myStyle(14, Colors.white)),
                                textColor: Colors.white,
                                color: Colors.green,
                                onPressed: () async {
                                  analyticsHelper
                                      .sendAnalyticsEvent('Sign_Out');
                                  await sendResearchReport('Sign_Out');
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                  _auth.signOut();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ) ??
                    false)));
  }

  Future<void> _saveLanguage() async {
    final SharedPreferences prefs = await _prefs;
    prefs.setInt('languageIndex', languageIndex);
  }

  Future<void> _savePinCode(bool state) async {
    final SharedPreferences prefs = await _prefs;
    prefs.setBool('pincode', state);
  }

  @override
  Widget build(BuildContext context) {
    final AutoHomePageMapSelect homePageMap =
        Provider.of<AutoHomePageMapSelect>(context);
    final AutoHomePageAskSelect homePageAsk =
        Provider.of<AutoHomePageAskSelect>(context);
    final SafePageIndex safePageIndex = Provider.of<SafePageIndex>(context);

    userData = Provider.of<UserData>(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
          backgroundColor: testModeToggle ? Colors.red : Colors.blue,
          centerTitle: true,
          title: Text(''),
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
                    });
                  }),
            Row(
              children: [
                testModeToggle
                    ? Text(languages[selectedLanguage[languageIndex]]['testOn'],
                        style: myStyle(18, Colors.white))
                    : Text(
                        languages[selectedLanguage[languageIndex]]['testOff'],
                        style: myStyle(18, Colors.white)),
                Switch(
                  activeColor: Colors.yellow[500],
                  inactiveThumbColor: Colors.white,
                  value: testModeToggle,
                  onChanged: (state) {
                    setState(() {
                      testModeToggle = state;
                      testModeWasChanged = true;
                      if (testModeToggle == true) {
                        analyticsHelper.sendAnalyticsEvent('Test_Mode_On');
                        sendResearchReport('Test_Mode_On');
                      } else {
                        analyticsHelper.sendAnalyticsEvent('Test_Mode_Off');
                        sendResearchReport('Test_Mode_Off');
                      }
                    });
                  },
                ),
              ],
            ),
          ]),
      key: _scaffoldKeyHome,
      body: userData == null
          ? Center(child: CircularProgressIndicator())
          : Container(
              height: MediaQuery.of(context).size.height,
              child: SingleChildScrollView(
                child: Container(
                  height: MediaQuery.of(context).size.height - 80,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      Container(
                        width: 200,
                        height: 120,
                        child: Card(
                          color: Colors.blue[300],
                          clipBehavior: Clip.antiAlias,
                          child: Container(
                            height: 100,
                            padding: const EdgeInsets.all(5),
                            child: Row(children: [
                              Expanded(
                                flex: 4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                        image: userData.profilePic == 'default'
                                            ? AssetImage(
                                                'assets/images/defaultAvatar.png')
                                            : NetworkImage(userData.profilePic),
                                        fit: BoxFit.fill),
                                  ),
                                ),
                              ),
                              Spacer(
                                flex: 1,
                              ),
                              Expanded(
                                flex: 12,
                                child: Container(
                                  //padding: const EdgeInsets.only(top: 5),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: <Widget>[
                                      SizedBox(height: 12),
                                      userData.userName == ''
                                          ? AutoSizeText(
                                              languages[selectedLanguage[
                                                  languageIndex]]['username'],
                                              maxLines: 1,
                                              style: myStyle(18, Colors.black87,
                                                  FontWeight.w300))
                                          : AutoSizeText(
                                              userData.userName,
                                              maxLines: 1,
                                              style: myStyle(22, Colors.black,
                                                  FontWeight.w400),
                                            ),
                                      SizedBox(height: 12),
                                      userData.email == ''
                                          ? AutoSizeText(
                                              languages[selectedLanguage[
                                                  languageIndex]]['email'],
                                              maxLines: 1,
                                              style: myStyle(16, Colors.black87,
                                                  FontWeight.w300))
                                          : AutoSizeText(
                                              userData.email,
                                              maxLines: 1,
                                              style: myStyle(18, Colors.black,
                                                  FontWeight.w400),
                                            ),
                                      Spacer(
                                        flex: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ),

                      ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(userData),
                            ),
                          );
                        },
                        title: AutoSizeText(
                          languages[selectedLanguage[languageIndex]]
                              ['setProfile'],
                          maxLines: 1,
                          style: myStyle(18, Colors.black, FontWeight.w400),
                        ),
                        trailing: Icon(Icons.arrow_forward),
                      ),
                      ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventsWrapper(),
                            ),
                          );
                        },
                        title: Text(
                          languages[selectedLanguage[languageIndex]]
                              ['setEvents'],
                          style: myStyle(18, Colors.black, FontWeight.w400),
                        ),
                        trailing: Icon(Icons.arrow_forward),
                      ),
                      ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReportsWrapper(),
                            ),
                          );
                        },
                        title: Text(
                          languages[selectedLanguage[languageIndex]]
                              ['setReports'],
                          style: myStyle(18, Colors.black, FontWeight.w400),
                        ),
                        trailing: Icon(Icons.arrow_forward),
                      ),
                      ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SelectSecret(),
                            ),
                          );
                        },
                        title: Text(
                          languages[selectedLanguage[languageIndex]]
                              ['setSecret'],
                          style: myStyle(18, Colors.black, FontWeight.w400),
                        ),
                        trailing: Icon(Icons.arrow_forward),
                      ),
                      ListTile(
                        onTap: () {},
                        title: Text(
                          languages[selectedLanguage[languageIndex]]
                              ['setLanguage'],
                          style: myStyle(18, Colors.black, FontWeight.w400),
                        ),
                        trailing: Switch(
                          activeColor: Colors.blue[500],
                          inactiveThumbColor: Colors.green[500],
                          inactiveTrackColor: Colors.green[200],
                          value: _isEnglish,
                          onChanged: (state) {
                            setState(() {
                              _isEnglish = state;
                              langJustChanged = true;
                              if (_isEnglish == true) {
                                languageIndex = 0;
                                _saveLanguage();
                                analyticsHelper
                                    .sendAnalyticsEvent('Use_English');
                                sendResearchReport('Use_English');
                              } else {
                                languageIndex = 1;
                                _saveLanguage();
                                analyticsHelper
                                    .sendAnalyticsEvent('Use_Bangla');
                                sendResearchReport('Use_Bangla');
                              }
                            });
                          },
                        ),
                      ),
                      //   ListTile(
                      //     onTap: (){
                      //         },
                      //     title:
                      //     usePincode == true ? Text(languages[selectedLanguage[languageIndex]]['setPincodeON'], style: myStyle(18, Colors.black, FontWeight.w400),):
                      //   Text(languages[selectedLanguage[languageIndex]]['setPincodeOFF'], style: myStyle(18, Colors.black, FontWeight.w400),),
                      //   trailing: Switch(
                      //   activeColor: Colors.blue[500],
                      //   inactiveThumbColor: Colors.red[500],
                      //   inactiveTrackColor: Colors.red[200],
                      //   value: usePincode,
                      //   onChanged: (state){
                      // setState(() {
                      //   usePincode=state;
                      //   if (usePincode==true){
                      //     analyticsHelper.sendAnalyticsEvent('Pincode_ON');
                      //     sendResearchReport('Pincode_ON');
                      //     _savePinCode(true);
                      //   }else{
                      //     analyticsHelper.sendAnalyticsEvent('Pincode_OFF');
                      //     sendResearchReport('Pincode_OFF');
                      //     _savePinCode(false);
                      //   }

                      // });

                      // },
                      // ),
                      //   ),
                      SizedBox(height: 5),
                      Divider(
                          indent: 15.0,
                          endIndent: 15.0,
                          thickness: 3.0,
                          color: Colors.black54),
                      ListTile(
                        onTap: () {
                          analyticsHelper.sendAnalyticsEvent('Tutorial_Viewed');
                          sendResearchReport('Tutorial_Viewed');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Tutorial(),
                            ),
                          );
                        },
                        title: Text(
                          languages[selectedLanguage[languageIndex]]
                              ['tutorialPage'],
                          style: myStyle(18, Colors.black, FontWeight.w400),
                        ),
                        trailing: Icon(Icons.school),
                      ),
                      ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AppFeedback(userData),
                            ),
                          );
                        },
                        title: Text(
                          languages[selectedLanguage[languageIndex]]
                              ['setFeedback'],
                          style: myStyle(18, Colors.black, FontWeight.w400),
                        ),
                        trailing: Icon(Icons.feedback),
                      ),
                      ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DeleteData(userData),
                            ),
                          );
                        },
                        title: Text(
                          languages[selectedLanguage[languageIndex]]
                              ['deleteData'],
                          style: myStyle(18, Colors.black, FontWeight.w400),
                        ),
                        trailing: Icon(Icons.delete_sweep),
                      ),
                      ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DeleteAccount(userData),
                            ),
                          );
                        },
                        title: Text(
                          languages[selectedLanguage[languageIndex]]
                              ['setDelete'],
                          style: myStyle(18, Colors.black, FontWeight.w400),
                        ),
                        trailing: Icon(Icons.delete_forever),
                      ),
                      ListTile(
                        onTap: () {
                          _exitApp(context);
                        },
                        title: Text(
                          languages[selectedLanguage[languageIndex]]
                              ['setSignOut'],
                          style: myStyle(18, Colors.black, FontWeight.w400),
                        ),
                        trailing: Icon(Icons.logout),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
