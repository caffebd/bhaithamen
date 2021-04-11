import 'dart:core';
import 'package:bhaithamen/data/user_news_feed.dart';
import 'package:bhaithamen/screens/user_article.dart';
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
import 'package:cached_network_image/cached_network_image.dart';

class UserNewsPage extends StatefulWidget {
  final bool showMyNews;
  UserNewsPage(this.showMyNews);
  final _UserNewsPageState myAppState = new _UserNewsPageState();
  @override
  _UserNewsPageState createState() => _UserNewsPageState();
  void scrollToTop() {
    myAppState.scrollToTop();
  }
}

class _UserNewsPageState extends State<UserNewsPage> {
  Geodesy geodesy = Geodesy();

  String uid;
  List<bool> isSelected = [true, false, false];
  int selectedIndex = 0;
  List<UserNewsFeed> newsList = List<UserNewsFeed>();
  List<UserNewsFeed> myNewsList = List<UserNewsFeed>();
  List catChoice = ['news', 'info', 'warn'];

  bool distanceSort = true;
  bool timeSort = false;
  bool popularitySort = false;
  LatLng myLocation;

  ScrollController _scrollController = new ScrollController();

  initState() {
    super.initState();
    getCurrentUserUID();
  }

  String getPubDate(DateTime date) {
    String returnDate;

    String year = formatDate(date, [yyyy]);
    String month = formatDate(date, [mm]);
    String fullMonth = formatDate(date, [MM]);
    String day = formatDate(date, [dd]);
    String hour = formatDate(date, [HH, ':', nn]);

    returnDate = day +
        ' ' +
        fullMonth +
        ' ' +
        year +
        ' at ' +
        hour; //DateTime(year, month, day).toString();

    return returnDate;
  }

  getCurrentUserUID() async {
    var firebaseuser = FirebaseAuth.instance.currentUser;

    DocumentSnapshot userInfo =
        await userCollection.doc(firebaseuser.uid).get();

    //setState(() {
    uid = firebaseuser.uid;
    sortByTime();
    //});
  }

  likePost(String docId) async {
    var firebaseuser = FirebaseAuth.instance.currentUser;
    DocumentSnapshot document = await userNewsCollection.doc(docId).get();

    if (document['likes'].contains(firebaseuser.uid)) {
      userNewsCollection.doc(docId).update({
        'likes': FieldValue.arrayRemove([firebaseuser.uid]),
      });
    } else {
      userNewsCollection.doc(docId).update({
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

    DocumentSnapshot document = await userNewsCollection.doc(docId).get();
    userNewsCollection.doc(docId).update({'shares': document['shares'] + 1});
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

  sortByDistance() async {
    var geoMyLocation = await getUserLocation();

    double lat = geoMyLocation.latitude;
    double lng = geoMyLocation.longitude;
    setState(() {
      myLocation = new LatLng(lat, lng);
      timeSort = false;
      distanceSort = true;
      popularitySort = false;
    });
  }

  sortByTime() async {
    setState(() {
      timeSort = true;
      distanceSort = false;
      popularitySort = false;
    });
  }

  sortByPopularity() async {
    setState(() {
      timeSort = false;
      distanceSort = false;
      popularitySort = true;
    });
  }

  Future<void> openMap(double latitude, double longitude) async {
    var geoMyLocation = await getUserLocation();
    double lat = geoMyLocation.latitude;
    double long = geoMyLocation.longitude;

    var url =
        'https://www.google.com/maps/dir/?api=1&origin=$lat,$long&destination=$latitude,$longitude';

    String googleUrl = url;
    //'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(googleUrl)) {
      await launch(googleUrl);
    } else {
      throw 'Could not open the map.';
    }
  }

  scrollToTop() {
    _scrollController.animateTo(
      0.0,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allNews = Provider.of<List<UserNewsFeed>>(context);

    newsList.clear();

    if (allNews != null) {
      if (widget.showMyNews) {
        myNewsList = allNews.where((i) => i.uid == uid).toList();
      } else {
        myNewsList = List.from(allNews);
      }
    }

    if (allNews != null) {
      //allNews.sort((a, b) => b.likes.length.compareTo(a.likes.length));
      if (timeSort) {
        myNewsList.sort((a, b) => b.time.compareTo(a.time));
        newsList = List.from(myNewsList);
      }

      if (distanceSort && myLocation != null) {
        //distanceSort = false;

        for (var i = 0; i < myNewsList.length; i++) {
          if (myNewsList[i].location != null) {
            double lat = myNewsList[i].location.latitude;
            double lng = myNewsList[i].location.longitude;
            LatLng latLng = new LatLng(lat, lng);

            double distance =
                geodesy.distanceBetweenTwoGeoPoints(myLocation, latLng);

            distance = num.parse(distance.toStringAsFixed(2));

            final newEvent = UserNewsFeed(
                docId: myNewsList[i].docId,
                userName: myNewsList[i].userName,
                userPhone: myNewsList[i].userPhone,
                distance: distance,
                article: myNewsList[i].article,
                uid: myNewsList[i].uid,
                time: myNewsList[i].time,
                unixTime: myNewsList[i].unixTime,
                shares: myNewsList[i].shares,
                location: myNewsList[i].location,
                likes: myNewsList[i].likes,
                images: myNewsList[i].images,
                reports: myNewsList[i].reports,
                comments: myNewsList[i].comments,
                show: myNewsList[i].show,
                profilePic: myNewsList[i].profilePic);

            if (distance < 50000) {
              newsList.add(newEvent);
            }
          }
        }
        newsList.sort((b, a) => b.distance.compareTo(a.distance));
      }

      if (popularitySort) {
        // distanceSort = false;

        for (var i = 0; i < myNewsList.length; i++) {
          int likeScore = myNewsList[i].likes.length;
          int shareScore = myNewsList[i].shares * 2;
          int commentScore = myNewsList[i].comments.length * 3;

          int popularityScore = likeScore + shareScore + commentScore;

          final newEvent = UserNewsFeed(
              docId: myNewsList[i].docId,
              userName: myNewsList[i].userName,
              userPhone: myNewsList[i].userPhone,
              distance: null,
              popularity: popularityScore,
              article: myNewsList[i].article,
              uid: myNewsList[i].uid,
              time: myNewsList[i].time,
              unixTime: myNewsList[i].unixTime,
              shares: myNewsList[i].shares,
              location: myNewsList[i].location,
              likes: myNewsList[i].likes,
              images: myNewsList[i].images,
              reports: myNewsList[i].reports,
              comments: myNewsList[i].comments,
              show: myNewsList[i].show,
              profilePic: myNewsList[i].profilePic);

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
                                        3,
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
                                        3,
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
                                        3,
                                child: new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new Icon(
                                      Icons.directions_walk,
                                      size: 16.0,
                                      color: Colors.white,
                                    ),
                                    new SizedBox(
                                      width: 4.0,
                                    ),
                                    new Text(
                                      languages[selectedLanguage[languageIndex]]
                                          ['proximity'],
                                      style: TextStyle(color: Colors.white),
                                    )
                                  ],
                                ))
                            : Container(
                                width:
                                    (MediaQuery.of(context).size.width - 12) /
                                        3,
                                child: new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new Icon(
                                      Icons.directions_walk,
                                      size: 16.0,
                                      color: Colors.black,
                                    ),
                                    new SizedBox(
                                      width: 4.0,
                                    ),
                                    new Text(
                                      languages[selectedLanguage[languageIndex]]
                                          ['proximity'],
                                      style: TextStyle(color: Colors.black),
                                    )
                                  ],
                                )),
                        isSelected[2]
                            ? Container(
                                width:
                                    (MediaQuery.of(context).size.width - 12) /
                                        3,
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
                                        3,
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
                            sortByTime();
                            //sendResearchReport('News_Section');
                          }
                          if (selectedIndex == 1) {
                            //sendResearchReport('Info_Section');
                            sortByDistance();
                          }
                          if (selectedIndex == 2) {
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
                    controller: _scrollController,
                    itemCount: newsList.length,
                    itemBuilder: (BuildContext context, int index) {
                      //DocumentSnapshot feeddoc = allNews[index];
                      UserNewsFeed feeddoc = newsList[index];
                      return
                          // feeddoc.show != true
                          //     ? Container()
                          //:
                          Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              sendResearchReport('User_Post_Read');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserArticle(feeddoc),
                                ),
                              );
                            },
                            child: Card(
                                margin: EdgeInsets.fromLTRB(5, 10, 5, 0),
                                child: ListTile(
                                    // leading: CircleAvatar(
                                    //   backgroundColor: Colors.white,
                                    //   backgroundImage: feeddoc['profilepic'] == 'default'
                                    //       ? AssetImage('images/defaultAvatar.png')
                                    //       : NetworkImage(feeddoc['profilepic']),
                                    // ),
                                    title: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          feeddoc.userName,
                                          style: myStyle(
                                              18, Colors.blue, FontWeight.w600),
                                        ),
                                        Text(getPubDate(feeddoc.time)),
                                        InkWell(
                                          onTap: () async {
                                            await openMap(
                                                feeddoc.location.latitude,
                                                feeddoc.location.longitude);
                                          },
                                          child: Row(children: [
                                            feeddoc.distance != null
                                                ? Icon(Icons.map)
                                                : Container(),
                                            feeddoc.distance != null
                                                ? Text(feeddoc.distance
                                                        .toString() +
                                                    ' meters away')
                                                : Text(''),

                                            // https://www.google.com/maps/search/?api=1&query=
                                          ]),
                                        )
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 10),
                                        feeddoc.images.length == 0
                                            ? Container()
                                            : Center(
                                                child: feeddoc.images.length ==
                                                        1
                                                    ? Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .fromLTRB(
                                                                12, 10, 12, 10),
                                                        child:
                                                            CachedNetworkImage(
                                                          height: 150,
                                                          imageUrl:
                                                              feeddoc.images[0],
                                                          progressIndicatorBuilder:
                                                              (context, url,
                                                                      downloadProgress) =>
                                                                  SizedBox(
                                                            height: 150,
                                                            child: Center(
                                                              child: CircularProgressIndicator(
                                                                  value: downloadProgress
                                                                      .progress),
                                                            ),
                                                          ),
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              Icon(Icons.error),
                                                        ),
                                                      )
                                                    : Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .fromLTRB(
                                                                5, 10, 12, 5),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceEvenly,
                                                          children: [
                                                            CachedNetworkImage(
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width /
                                                                  2.5,
                                                              imageUrl: feeddoc
                                                                  .images[0],
                                                              progressIndicatorBuilder:
                                                                  (context, url,
                                                                          downloadProgress) =>
                                                                      SizedBox(
                                                                height: 150,
                                                                child: Center(
                                                                  child: CircularProgressIndicator(
                                                                      value: downloadProgress
                                                                          .progress),
                                                                ),
                                                              ),
                                                              errorWidget: (context,
                                                                      url,
                                                                      error) =>
                                                                  Icon(Icons
                                                                      .error),
                                                            ),
                                                            CachedNetworkImage(
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width /
                                                                  2.5,
                                                              imageUrl: feeddoc
                                                                  .images[1],
                                                              progressIndicatorBuilder:
                                                                  (context, url,
                                                                          downloadProgress) =>
                                                                      SizedBox(
                                                                height: 150,
                                                                child: Center(
                                                                  child: CircularProgressIndicator(
                                                                      value: downloadProgress
                                                                          .progress),
                                                                ),
                                                              ),
                                                              errorWidget: (context,
                                                                      url,
                                                                      error) =>
                                                                  Icon(Icons
                                                                      .error),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                              ),
                                        Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                20, 0, 20, 10),
                                            child: Linkify(
                                                onOpen: _onOpen,
                                                text: feeddoc.article.length >
                                                        100
                                                    ? feeddoc.article
                                                            .substring(0, 100) +
                                                        '...'
                                                    : feeddoc.article,
                                                style: myStyle(16, Colors.black,
                                                    FontWeight.w400))),
                                        SizedBox(height: 10),
                                      ],
                                    ))),
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
                                  InkWell(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            UserArticle(feeddoc),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.comment_bank_outlined,
                                            size: 20),
                                        SizedBox(width: 10),
                                        Text(feeddoc.comments.length.toString(),
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
