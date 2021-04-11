import 'package:bhaithamen/data/alerts_feed.dart';
import 'package:bhaithamen/data/event.dart';
import 'package:bhaithamen/data/event_date.dart';
import 'package:bhaithamen/data/incident_date.dart';
import 'package:bhaithamen/data/incident_report.dart';
import 'package:bhaithamen/data/news_feed.dart';
import 'package:bhaithamen/data/safe_place_data.dart';
import 'package:bhaithamen/data/user.dart';
import 'package:bhaithamen/data/userData.dart';
import 'package:bhaithamen/data/user_news_feed.dart';
import 'package:bhaithamen/utilities/googleSignIn.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  final String uid;
  final String place;
  final String category;

  AuthService({this.uid, this.place, this.category});

  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      auth.UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      auth.User user = result.user;
      print('logged in and ' + user.uid);
      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());

      return null;
    }
  }

  Future registerWithEmailAndPassword(String email, String password) async {
    try {
      auth.UserCredential result = await auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      auth.User user = result.user;

      userCollection.doc(user.uid).set({
        'uid': user.uid,
        'username': email,
        'email': email,
        'profilepic': 'default',
        'phoneContact': []
      });

      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());

      if (e is PlatformException) {
        print('PC' + e.code);
        return [false, e.code];

      } else {

        return [false, e.toString()];
      }

    }
  }

  Future signInWithGoogleAuth() async {
    await Firebase.initializeApp();

    try {
      final GoogleSignInAccount googleSignInAccount =
          await googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final auth.AuthCredential credential = auth.GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      try {
        final auth.UserCredential authResult =
            await _auth.signInWithCredential(credential);
        final auth.User user = authResult.user;

        DocumentSnapshot userDoc = await userCollection.doc(user.uid).get();

        if (!userDoc.exists) {
          userCollection.doc(user.uid).set({
            'uid': user.uid,
            'username': user.displayName,
            'email': user.email,
            'profilepic': user.photoURL,
            'phoneContact': [],
          });
        } else {
          print('already got the user');
        }

        return _userFromFirebaseUser(user);
      } catch (e) {
        print(e.toString());

        return null;
      }
    } catch (e) {
      print(e.toString());

      return null;
    }
  }

  UserData _userDataFromSnapshot(DocumentSnapshot snapshot) {
    return UserData(
        uid: uid,
        userName: snapshot.data()['username'],
        userPhone: snapshot.data()['userPhone'],
        age: snapshot.data()['age'],
        email: snapshot.data()['email'],
        phoneContact: snapshot.data()['phoneContact'],
        profilePic: snapshot.data()['profilepic'],
        killed: snapshot.data()['killed']);
  }

  static List<EventDay> _eventsFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return EventDay(
        eventDate: doc.id ?? '',
        allEvents: List<Event>.from(doc.data()["events"].map((item) {
          return new Event(
              type: item['type'] ?? 'none',
              category: item['category'] != null ? item['category'] : 'none',
              location: item['location'],
              time: item['time'].toDate(),
              eventId: item['eventId'] ?? '00000000');
        })),
      );
    }).toList();
  }

  static List<IncidentDay> _incidentssFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return IncidentDay(
        incidentDate: doc.id ?? '',
        allIncidents:
            List<IncidentReport>.from(doc.data()["incidents"].map((item) {
          return new IncidentReport(
              type: item['type'] ?? 'none',
              location: item['location'] ?? 'none given',
              time: item['time'].toDate(),
              target: item['target'] ?? 'none given',
              incidentDate: item['incidentDate'] ?? 'none given',
              description: item['description'] ?? 'none given',
              reportUid: item['reportUid'],
              attachedEvents: item['attachedEvents'] ?? []);
        })),
      );
    }).toList();
  }

  static List<NewsFeed> _newsFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      int milliseconds = int.parse(doc.id);

      // DateTime date =
      //     new DateTime.fromMillisecondsSinceEpoch(doc.data()['time']);

      return NewsFeed(
          time: doc.data()['time'].toDate(),
          docId: doc.id,
          author: doc.data()['author'],
          article: doc.data()['article'],
          likes: doc.data()['likes'],
          comments: doc.data()['comments'],
          shares: doc.data()['shares'],
          show: doc.data()['show'],
          title: doc.data()['title'],
          category: doc.data()['cat'],
          images: doc.data()['images']);
    }).toList();
  }

  static List<AlertsFeed> _alertsFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      // DateTime date =
      //     new DateTime.fromMillisecondsSinceEpoch(doc.data()['time']);

      return AlertsFeed(
          time: doc.data()['time'].toDate(),
          docId: doc.id,
          article: doc.data()['article'],
          likes: doc.data()['likes'],
          shares: doc.data()['shares'],
          show: doc.data()['show'],
          title: doc.data()['title'],
          image: doc.data()['image']);
    }).toList();
  }

  static List<UserNewsFeed> _userNewsFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return UserNewsFeed(
          time: doc.data()['time'].toDate(),
          docId: doc.id,
          uid: doc.data()['uid'],
          unixTime: doc.data()['unixTime'],
          userName: doc.data()['userName'],
          article: doc.data()['article'],
          likes: doc.data()['likes'],
          shares: doc.data()['shares'],
          show: doc.data()['show'],
          title: doc.data()['title'],
          reports: doc.data()['reports'],
          location: doc.data()['location'],
          comments: doc.data()['comments'],
          images: doc.data()['images']);
    }).toList();
  }

  static List<SafePlace> _safePlaceFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return SafePlace(
          time: doc.data()['time'].toDate(),
          docId: doc.id,
          nameEN: doc.data()['nameEN'] ?? '',
          nameBN: doc.data()['nameBN'] ?? '',
          website: doc.data()['website'] ?? '',
          social: doc.data()['social'] ?? '',
          typeBN: doc.data()['typeBN'] ?? '',
          typeEN: doc.data()['typeEN'] ?? '',
          facilitiesBN: doc.data()['facilitiesBN'] ?? [],
          facilitiesEN: doc.data()['facilitiesEN'] ?? [],
          locationDescBN: doc.data()['locationDescBN'] ?? '',
          locationDescEN: doc.data()['locationDescEN'] ?? '',
          category: doc.data()['category'] ?? '',
          detailsEN: doc.data()['detailsEN'] ?? [],
          detailsBN: doc.data()['detailsBN'] ?? [],
          rating: doc.data()['rating'] ?? 0,
          phone: doc.data()['phone'] ?? '',
          raters: doc.data()['raters'] ?? 0,
          price: doc.data()['price'] ?? 'Free',
          location: doc.data()['location'] ?? [],
          images: doc.data()['images'] ?? []);
    }).toList();
  }

  Future<void> signOut() async {
    var user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.providerData[0].providerId == 'google.com') {
        await googleSignIn.signOut();
      }
    }
    auth.FirebaseAuth.instance.signOut();
  }

  Stream<UserData> get userData {
    //var user =  auth.FirebaseAuth.instance.currentUser;

    return userCollection.doc(uid).snapshots().map(_userDataFromSnapshot);
  }

  Stream<List<AlertsFeed>> get getAlerts {
    return alertsNewsCollection.snapshots().map(_alertsFromSnapshot);
  }

  Stream<List<NewsFeed>> get getNews {
    return newsCollection.snapshots().map(_newsFromSnapshot);
  }

  Stream<List<UserNewsFeed>> get getUserNews {
    return userNewsCollection.snapshots().map(_userNewsFromSnapshot);
  }

  Stream<List<SafePlace>> get getSafePlaces {
    return safePlaceCollection
        .doc(place)
        .collection(category)
        .snapshots()
        .map(_safePlaceFromSnapshot);
  }

  Stream<List<EventDay>> get getEvents {
    return userCollection
        .doc(uid)
        .collection('events')
        .snapshots()
        .map(_eventsFromSnapshot);
  }

  Stream<List<IncidentDay>> get getIncidents {
    return userCollection
        .doc(uid)
        .collection('incidents')
        .snapshots()
        .map(_incidentssFromSnapshot);
  }

  User _userFromFirebaseUser(auth.User user) {
    return user != null ? User(uid: user.uid) : null;
  }

  User userFromFirebaseUser(auth.User user) {
    return user != null ? User(uid: user.uid) : null;
  }

  Stream<User> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }
}
