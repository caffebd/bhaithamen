
import 'package:bhaithamen/data/userData.dart';
import 'package:bhaithamen/screens/settings.dart';
import 'package:bhaithamen/utilities/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsWrapper extends StatefulWidget {
  @override
  _SettingsWrapperState createState() => _SettingsWrapperState();
}

class _SettingsWrapperState extends State<SettingsWrapper> {

String uid;

  initState(){
    super.initState();
    getCurrentUserUID();

    
  }

  getCurrentUserUID()async{
    var firebaseuser = FirebaseAuth.instance.currentUser;
    setState(() {
      uid = firebaseuser.uid;
    });

  }


  @override
  Widget build(BuildContext context) {
return MultiProvider(
      providers:[    
              StreamProvider<UserData>.value(value: AuthService(uid: uid).userData),  
      ],   
    child: Settings(),
);
  }
}