import 'package:bhaithamen/data/event_date.dart';
import 'package:bhaithamen/screens/event_dates.dart';
import 'package:bhaithamen/utilities/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventsWrapper extends StatefulWidget {
  @override
  _EventsWrapperState createState() => _EventsWrapperState();
}

class _EventsWrapperState extends State<EventsWrapper> {

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
        StreamProvider<List<EventDay>>.value(value: AuthService(uid: uid).getEvents),  
      ],   
    child: EventDates(),
);
  }
}