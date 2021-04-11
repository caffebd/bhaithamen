import 'package:bhaithamen/data/userData.dart';
import 'package:bhaithamen/screens/events_wrapper.dart';
import 'package:bhaithamen/screens/profile_page.dart';
import 'package:bhaithamen/screens/reports_wrapper.dart';
import 'package:bhaithamen/utilities/auth.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsOld extends StatefulWidget {
  @override
  _SettingsOldState createState() => _SettingsOldState();
}

class _SettingsOldState extends State<SettingsOld> {
  final AuthService _auth = AuthService();

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
  }

  Future<bool> _exitApp(BuildContext context) {
    return showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text('Do you want to logout?'),
            content: Text('!location tracking will no longer be available!'),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text('No'),
              ),
              FlatButton(
                onPressed: () {
                  _auth.signOut();
                  Navigator.pop(context);
                },
                child: Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserData>(context);
    return userData == null
        ? Center(child: CircularProgressIndicator())
        : Container(
            height: MediaQuery.of(context).size.height - 150,
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                Container(
                  width: 200,
                  height: 150,
                  child: Card(
                    color: Colors.blue[300],
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      height: 120,
                      padding: const EdgeInsets.all(5),
                      child: Row(children: [
                        Expanded(
                          flex: 6,
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
                            padding: const EdgeInsets.only(top: 5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                SizedBox(height: 12),
                                userData.userName == ''
                                    ? Text('username',
                                        style: myStyle(22, Colors.black87,
                                            FontWeight.w300))
                                    : Text(
                                        userData.userName,
                                        style: myStyle(
                                            22, Colors.black, FontWeight.w400),
                                      ),
                                SizedBox(height: 12),
                                userData.email == ''
                                    ? Text('email',
                                        style: myStyle(18, Colors.black87,
                                            FontWeight.w300))
                                    : Text(
                                        userData.email,
                                        style: myStyle(
                                            18, Colors.black, FontWeight.w400),
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
                // UserAccountsDrawerHeader(
                //   accountName: Text(userData.userName, style: myStyle(22, Colors.white, FontWeight.w500),),
                //   accountEmail: null,
                //   currentAccountPicture:
                //       Container(
                //       width: 120,
                //       height: 120,
                //       //margin: EdgeInsets.only(top:30),
                //       decoration: BoxDecoration(
                //         shape: BoxShape.circle,
                //         image: DecorationImage(image: userData.profilePic=='default' ? AssetImage('images/handStop.jpg') : NetworkImage(userData.profilePic),
                //         fit: BoxFit.fill,
                //         ),
                //       ),
                //       ),

                // ),
                ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(userData),
                      ),
                    );
                  },
                  title: Text(
                    'My Profile & Trusted Contacts',
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
                    'App Events',
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
                    'Submitted Reports',
                    style: myStyle(18, Colors.black, FontWeight.w400),
                  ),
                  trailing: Icon(Icons.arrow_forward),
                ),
                ListTile(
                  onTap: () {},
                  title: Text(
                    'Pick Secret Screen',
                    style: myStyle(18, Colors.black, FontWeight.w400),
                  ),
                  trailing: Icon(Icons.arrow_forward),
                ),
                SizedBox(height: 5),
                Divider(
                    indent: 15.0,
                    endIndent: 15.0,
                    thickness: 3.0,
                    color: Colors.black54),
                ListTile(
                  onTap: () {
                    _exitApp(context);
                  },
                  title: Text(
                    'Sign Out',
                    style: myStyle(18, Colors.black, FontWeight.w400),
                  ),
                  trailing: Icon(Icons.logout),
                ),
              ],
            ),
          );
  }
}
