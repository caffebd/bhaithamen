import 'package:bhaithamen/data/event_date.dart';
import 'package:bhaithamen/data/incident_date.dart';
import 'package:bhaithamen/data/userData.dart';
import 'package:bhaithamen/screens/incident_dates.dart';
import 'package:bhaithamen/utilities/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReportsWrapper extends StatefulWidget {
  @override
  _ReportsWrapperState createState() => _ReportsWrapperState();
}

class _ReportsWrapperState extends State<ReportsWrapper> {
  String uid;

  initState() {
    super.initState();
    getCurrentUserUID();
  }

  getCurrentUserUID() async {
    var firebaseuser = FirebaseAuth.instance.currentUser;
    setState(() {
      uid = firebaseuser.uid;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<List<IncidentDay>>.value(
            value: AuthService(uid: uid).getIncidents),
        StreamProvider<List<EventDay>>.value(
            value: AuthService(uid: uid).getEvents),
        StreamProvider<UserData>.value(value: AuthService(uid: uid).userData),
      ],
      child: IncidentDates(),
    );
  }
}
