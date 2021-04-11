import 'package:bhaithamen/utilities/report_event.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart' as flutLoc;

flutLoc.Location location = new flutLoc.Location();
flutLoc.LocationData myLocationData;

String uid;
String userPhone;
int userAge;

sendTestingReport(String message) async {
  DateTime now = DateTime.now();

  var firebaseUser = FirebaseAuth.instance.currentUser;
  DocumentSnapshot userDoc = await userCollection
      .doc(firebaseUser.uid)
      .collection('bugs')
      .doc(now.toString())
      .get();
  if (userDoc.exists) {
    userCollection
        .doc(firebaseUser.uid)
        .collection('bugs')
        .doc(now.toString())
        .set({"msg": message});
  } else {
    userCollection
        .doc(firebaseUser.uid)
        .collection('bugs')
        .doc(now.toString())
        .set({"msg": message});
  }
}

sendResearchReport(String event) async {
  String theDate = getDate().toString();
  int unixDate = getDate().toUtc().millisecondsSinceEpoch;

  var firebaseUser = FirebaseAuth.instance.currentUser;
  DocumentSnapshot userDoc = await userCollection.doc(firebaseUser.uid).get();

  uid = userDoc['uid'];
  userPhone = userDoc['userPhone'];
  if (userDoc['age'] != null) {
    userAge = userDoc['age'];
  } else {
    userAge = 0;
  }

  DocumentSnapshot userResearchDoc = await userCollection
      .doc(firebaseUser.uid)
      .collection('research')
      .doc(theDate)
      .get();

  myLocationData = await location.getLocation();

  GeoPoint loc;

  if (myLocationData != null) {
    loc = GeoPoint(myLocationData.latitude, myLocationData.longitude);
  } else {
    loc = GeoPoint(90.0000, 135.0000);
  }

  if (loc == null) {
    loc = GeoPoint(90.0000, 135.0000);
  }

//is crash caused by empty location?

  if (userResearchDoc.exists) {
    userCollection
        .doc(firebaseUser.uid)
        .collection('research')
        .doc(theDate)
        .update({
      "createdAt": unixDate,
      "data": FieldValue.arrayUnion([
        {
          "uid": firebaseUser.uid,
          "userPhone": userPhone,
          "age": userAge,
          "event": event,
          "date": DateTime.now(),
          "location": loc
        }
      ])
    });
  } else {
    userCollection
        .doc(firebaseUser.uid)
        .collection('research')
        .doc(theDate)
        .set({
      "createdAt": unixDate,
      "data": FieldValue.arrayUnion([
        {
          "uid": firebaseUser.uid,
          "userPhone": userPhone,
          "age": userAge,
          "event": event,
          "date": DateTime.now(),
          "location": loc
        }
      ])
    });
  }

  bool sendResearch = false;
  String category = '';

  switch (event) {
    case 'Use_Bangla':
      sendResearch = true;
      category = 'researchBangla';
      break;
    case 'Use_English':
      sendResearch = true;
      category = 'researchEnglish';
      break;
    case 'Challenge_Screen_Alarm_Used':
      sendResearch = true;
      category = 'researchAlarm';
      break;
    case 'App_Opened':
      sendResearch = true;
      category = 'researchAppOpened';
      break;
    case 'Challenge_Screen_Recording_Start':
      sendResearch = true;
      category = 'researchChallenge';
      break;
    case 'Secret_Recording_Started':
      sendResearch = true;
      category = 'researchSecret';
      break;
    case 'Test_Mode_On':
      sendResearch = true;
      category = 'researchTestOn';
      break;
    case 'Countdown_started':
      sendResearch = true;
      category = 'researchTimer';
      break;
    case 'Home_SMS_Press':
      sendResearch = true;
      category = 'researchUserSMS';
      break;
    case 'Geofence_Start':
      sendResearch = true;
      category = 'researchZone';
      break;
    case 'News_Section':
      sendResearch = true;
      category = 'researchNews';
      break;
    case 'Community_Section':
      sendResearch = true;
      category = 'researchCommunity';
      break;
    case 'User_Post_Read':
      sendResearch = true;
      category = 'researchUserPostRead';
      break;
    case 'Map_toilet':
      sendResearch = true;
      category = 'researchMapToilet';
      break;
    case 'Map_pharmacy':
      sendResearch = true;
      category = 'researchMapPharmacy';
      break;
    case 'Map_shop':
      sendResearch = true;
      category = 'researchMapShop';
      break;
    case 'Map_doctor':
      sendResearch = true;
      category = 'researchMapDoctor';
      break;
    case 'Map_food':
      sendResearch = true;
      category = 'researchMapFood';
      break;
    case 'Map_beauty':
      sendResearch = true;
      category = 'researchMapBeauty';
      break;
    case 'Map_club':
      sendResearch = true;
      category = 'researchMapClub';
      break;
    case 'Map_gym':
      sendResearch = true;
      category = 'researchMapGym';
      break;
    case 'News_Post_Read':
      sendResearch = true;
      category = 'researchNewsPostRead';
      break;
    case 'Info_Section':
      sendResearch = true;
      category = 'researchInfo';
      break;
    case 'Alert_Section':
      sendResearch = true;
      category = 'researchAlert';
      break;
    default:
  }

  if (sendResearch == true) {
    CollectionReference catCollection =
        FirebaseFirestore.instance.collection(category);

    DocumentSnapshot cat = await catCollection.doc(getDate().toString()).get();
    if (cat.exists) {
      catCollection.doc(getDate().toString()).update({
        "createdAt": unixDate,
        "data": FieldValue.arrayUnion([
          {
            "uid": firebaseUser.uid,
            "userPhone": userPhone,
            "age": userAge,
            "event": event,
            "date": DateTime.now(),
            "location": loc
          }
        ])
      });
    } else {
      catCollection.doc(getDate().toString()).set({
        "createdAt": unixDate,
        "data": FieldValue.arrayUnion([
          {
            "uid": firebaseUser.uid,
            "userPhone": userPhone,
            "age": userAge,
            "event": event,
            "date": DateTime.now(),
            "location": loc
          }
        ])
      });
    }
  }
}
