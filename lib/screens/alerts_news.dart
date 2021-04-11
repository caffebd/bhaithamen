import 'dart:core';

import 'package:bhaithamen/data/alerts_feed.dart';
import 'package:bhaithamen/utilities/fb_test.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geodesy/geodesy.dart';

class AlertsNewsPage extends StatefulWidget {
  @override
  _AlertsNewsPageState createState() => _AlertsNewsPageState();
}

class _AlertsNewsPageState extends State<AlertsNewsPage> {
  Geodesy geodesy = Geodesy();

  String uid;
  List<bool> isSelected = [true, false];
  int selectedIndex = 0;
  List<AlertsFeed> newsList = List<AlertsFeed>();
  List catChoice = ['news', 'info'];

  bool timeSort = true;
  bool popularitySort = false;
  LatLng myLocation;

  initState() {
    super.initState();
    getCurrentUserUID();
    //sendResearchReport('News_Section');
  }

  String getPubDate(DateTime date) {
    String returnDate;

    String year = formatDate(date, [yyyy]);

    String fullMonth = formatDate(date, [MM]);
    String day = formatDate(date, [dd]);
    String hour = formatDate(date, [HH, ':', nn]);

    returnDate = day + ' ' + fullMonth + ' ' + year + ' at ' + hour;

    return returnDate;
  }

  getCurrentUserUID() async {
    var firebaseuser = FirebaseAuth.instance.currentUser;

    setState(() {
      uid = firebaseuser.uid;
    });
  }

  likePost(String docId) async {
    var firebaseuser = FirebaseAuth.instance.currentUser;
    DocumentSnapshot document = await alertsNewsCollection.doc(docId).get();

    if (document['likes'].contains(firebaseuser.uid)) {
      alertsNewsCollection.doc(docId).update({
        'likes': FieldValue.arrayRemove([firebaseuser.uid]),
      });
    } else {
      alertsNewsCollection.doc(docId).update({
        'likes': FieldValue.arrayUnion([firebaseuser.uid]),
      });
    }
  }

  sharePost(String docId, String tweet) async {
    String msg =
        tweet + '\n\n' + 'Shared from Bhai Thamen https://bhaithamen.com';
    try {
      Share.share(msg, subject: 'Bhai Thamen');
    } catch (e) {
      print(e);
    }

    DocumentSnapshot document = await alertsNewsCollection.doc(docId).get();
    alertsNewsCollection.doc(docId).update({'shares': document['shares'] + 1});
  }

  Future<void> _onOpen(LinkableElement link) async {
    if (await canLaunch(link.url)) {
      await launch(link.url);
    } else {
      throw 'Could not launch $link';
    }
  }

  Future getUserLocation() async {
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

    return loc;
  }

  sortByTime() async {
    setState(() {
      timeSort = true;

      popularitySort = false;
    });
  }

  sortByPopularity() async {
    setState(() {
      timeSort = false;

      popularitySort = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allNews = Provider.of<List<AlertsFeed>>(context);

    if (allNews != null) {
      //allNews.sort((a, b) => b.likes.length.compareTo(a.likes.length));
      if (timeSort) {
        allNews.sort((a, b) => b.time.compareTo(a.time));
        newsList = List.from(allNews);
      }

      if (popularitySort) {
        // distanceSort = false;
        newsList.clear();
        for (var i = 0; i < allNews.length; i++) {
          int likeScore = allNews[i].likes.length;
          int shareScore = allNews[i].shares * 2;

          int popularityScore = likeScore + shareScore;

          final newEvent = AlertsFeed(
            docId: allNews[i].docId,
            article: allNews[i].article,
            title: allNews[i].title,
            time: allNews[i].time,
            shares: allNews[i].shares,
            likes: allNews[i].likes,
            image: allNews[i].image,
            popularity: popularityScore,
            show: allNews[i].show,
          );

          newsList.add(newEvent);
        }
        newsList.sort((a, b) => b.popularity.compareTo(a.popularity));
      }
    }
    return newsList.length == 0
        ? Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    //buttons across top of screen
                    ToggleButtons(
                      color: Colors.white,
                      selectedColor: Colors.black,
                      fillColor: Colors.red[600],
                      borderColor: Colors.white,
                      children: <Widget>[
                        isSelected[0]
                            ? Container(
                                width:
                                    (MediaQuery.of(context).size.width - 12) /
                                        2,
                                child: new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new Icon(
                                      Icons.calendar_today,
                                      size: 16.0,
                                      color: Colors.white,
                                    ),
                                    new SizedBox(
                                      width: 4.0,
                                    ),
                                    new Text(
                                        languages[
                                                selectedLanguage[languageIndex]]
                                            ['recent'],
                                        style: TextStyle(color: Colors.white))
                                  ],
                                ))
                            : Container(
                                width:
                                    (MediaQuery.of(context).size.width - 12) /
                                        2,
                                child: new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new Icon(
                                      Icons.calendar_today,
                                      size: 16.0,
                                      color: Colors.black,
                                    ),
                                    new SizedBox(
                                      width: 4.0,
                                    ),
                                    new Text(
                                        languages[
                                                selectedLanguage[languageIndex]]
                                            ['recent'],
                                        style: TextStyle(color: Colors.black))
                                  ],
                                )),
                        isSelected[1]
                            ? Container(
                                width:
                                    (MediaQuery.of(context).size.width - 12) /
                                        2,
                                child: new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new Icon(
                                      Icons.thumb_up_outlined,
                                      size: 16.0,
                                      color: Colors.white,
                                    ),
                                    new SizedBox(
                                      width: 4.0,
                                    ),
                                    new Text(
                                        languages[
                                                selectedLanguage[languageIndex]]
                                            ['popular'],
                                        style: TextStyle(color: Colors.white))
                                  ],
                                ))
                            : Container(
                                width:
                                    (MediaQuery.of(context).size.width - 12) /
                                        2,
                                child: new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new Icon(
                                      Icons.thumb_up_outlined,
                                      size: 16.0,
                                      color: Colors.black,
                                    ),
                                    new SizedBox(
                                      width: 4.0,
                                    ),
                                    new Text(
                                        languages[
                                                selectedLanguage[languageIndex]]
                                            ['popular'],
                                        style: TextStyle(color: Colors.black))
                                  ],
                                )),
                      ],
                      onPressed: (int index) {
                        setState(() {
                          selectedIndex = index;
                          mapIsShowing = false;
                          for (int buttonIndex = 0;
                              buttonIndex < isSelected.length;
                              buttonIndex++) {
                            if (buttonIndex == index) {
                              isSelected[buttonIndex] = true;
                            } else {
                              isSelected[buttonIndex] = false;
                            }
                          }
                          if (selectedIndex == 0) {
                            //sendResearchReport('Info_Section');
                            sortByTime();
                          }
                          if (selectedIndex == 1) {
                            sortByPopularity();
                            //sendResearchReport('Alert_Section');
                          }
                        });
                      },
                      isSelected: isSelected,
                    ),
                  ],
                ),
              ),
              Container(
                height: MediaQuery.of(context).size.height -
                    kBottomNavigationBarHeight -
                    150,
                child: ListView.builder(
                    itemCount: newsList.length,
                    itemBuilder: (BuildContext context, int index) {
                      //DocumentSnapshot feeddoc = allNews[index];
                      AlertsFeed feeddoc = newsList[index];
                      return
                          // feeddoc.show != true
                          //     ? Container()
                          //:
                          Column(
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: Card(
                                margin: EdgeInsets.fromLTRB(5, 10, 5, 0),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    backgroundImage: feeddoc.image == ''
                                        ? AssetImage('images/defaultAvatar.png')
                                        : NetworkImage(feeddoc.image),
                                  ),
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        feeddoc.title,
                                        style: myStyle(
                                            18, Colors.blue, FontWeight.w600),
                                      ),
                                      Text(getPubDate(feeddoc.time)),
                                    ],
                                  ),
                                  subtitle: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          20, 0, 20, 10),
                                      child: Linkify(
                                          onOpen: _onOpen,
                                          text: feeddoc.article.length > 100
                                              ? feeddoc.article
                                                      .substring(0, 100) +
                                                  '...'
                                              : feeddoc.article,
                                          style: myStyle(16, Colors.black,
                                              FontWeight.w400))),
                                )),
                          ),
                          Card(
                            margin: EdgeInsets.fromLTRB(5, 5, 5, 10),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Spacer(),
                                  InkWell(
                                    onTap: () => likePost(feeddoc.docId),
                                    child: Row(
                                      children: [
                                        feeddoc.likes.contains(uid)
                                            ? Icon(Icons.favorite,
                                                size: 20, color: Colors.red)
                                            : Icon(Icons.favorite_border,
                                                size: 20),
                                        SizedBox(width: 10),
                                        Text(feeddoc.likes.length.toString(),
                                            style:
                                                myStyle(16, Colors.grey[600])),
                                      ],
                                    ),
                                  ),
                                  Spacer(),
                                  InkWell(
                                    onTap: () => sharePost(
                                        feeddoc.docId, feeddoc.article),
                                    child: Row(
                                      children: [
                                        Icon(Icons.share, size: 20),
                                        SizedBox(width: 10),
                                        Text(feeddoc.shares.toString(),
                                            style:
                                                myStyle(16, Colors.grey[600])),
                                      ],
                                    ),
                                  ),
                                  Spacer(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
              ),
            ],
          );
  }
}
