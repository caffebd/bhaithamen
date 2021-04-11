import 'dart:core';

import 'package:bhaithamen/data/news_feed.dart';
import 'package:bhaithamen/screens/news_article.dart';
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
import 'package:image_gallery_grid_fb/image_gallery_grid_fb.dart';

class NewsPage extends StatefulWidget {
  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  Geodesy geodesy = Geodesy();

  String uid;
  List<bool> isSelected = [true, false];
  int selectedIndex = 0;
  List<NewsFeed> newsList = List<NewsFeed>();
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
    //DateTime getToday =  new DateTime.now();  //DateTime(2020, 10, 13);

    print(date);

    String returnDate;

    String year = formatDate(date, [yyyy]);
    String month = formatDate(date, [mm]);
    String fullMonth = formatDate(date, [MM]);
    String day = formatDate(date, [dd]);
    String hour = formatDate(date, [HH, ':', nn]);
    //String min = formatDate(date, []);

    //today = DateTime(year, month, day);

    //print('today is ' + today.toString());

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
    setState(() {
      uid = firebaseuser.uid;
    });
  }

  likePost(String docId) async {
    var firebaseuser = FirebaseAuth.instance.currentUser;
    DocumentSnapshot document = await newsCollection.doc(docId).get();

    if (document['likes'].contains(firebaseuser.uid)) {
      newsCollection.doc(docId).update({
        'likes': FieldValue.arrayRemove([firebaseuser.uid]),
      });
    } else {
      newsCollection.doc(docId).update({
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

    DocumentSnapshot document = await newsCollection.doc(docId).get();
    newsCollection.doc(docId).update({'shares': document['shares'] + 1});
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
    final allNews = Provider.of<List<NewsFeed>>(context);

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
          int commentScore = allNews[i].comments.length * 3;

          int popularityScore = likeScore + shareScore + commentScore;

          final newEvent = NewsFeed(
            docId: allNews[i].docId,
            article: allNews[i].article,
            uid: allNews[i].uid,
            title: allNews[i].title,
            time: allNews[i].time,
            shares: allNews[i].shares,
            likes: allNews[i].likes,
            images: allNews[i].images,
            popularity: popularityScore,
            comments: allNews[i].comments,
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
                      NewsFeed feeddoc = newsList[index];
                      return
                          // feeddoc.show != true
                          //     ? Container()
                          //:
                          Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              sendResearchReport('News_Post_Read');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NewsArticle(feeddoc),
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
                                          feeddoc.title,
                                          style: myStyle(
                                              18, Colors.blue, FontWeight.w600),
                                        ),
                                        Text(getPubDate(feeddoc.time)),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 10),
                                        feeddoc.images.length == 0
                                            ? Container()
                                            : feeddoc.images.length > 1
                                                ? GalleryImageGridFb(
                                                    imageUrls:
                                                        List<String>.from(
                                                            feeddoc.images),
                                                    onTap: () => Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            NewsArticle(
                                                                feeddoc),
                                                      ),
                                                    ),
                                                  )
                                                : Center(
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                              .fromLTRB(
                                                          12, 40, 12, 10),
                                                      child: CachedNetworkImage(
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
                                            NewsArticle(feeddoc),
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
