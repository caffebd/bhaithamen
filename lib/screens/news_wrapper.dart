import 'dart:async';
import 'dart:io';

import 'package:bhaithamen/data/alerts_feed.dart';
import 'package:bhaithamen/data/news_feed.dart';
import 'package:bhaithamen/data/user.dart';
import 'package:bhaithamen/data/userData.dart';
import 'package:bhaithamen/data/user_news_feed.dart';
import 'package:bhaithamen/screens/about.dart';
import 'package:bhaithamen/screens/alerts_news.dart';
import 'package:bhaithamen/screens/custom_list_tile.dart';
import 'package:bhaithamen/screens/home.dart';
import 'package:bhaithamen/screens/map_places_wrapper.dart';
import 'package:bhaithamen/screens/map_wrapper.dart';
import 'package:bhaithamen/screens/news_news.dart';
import 'package:bhaithamen/screens/settings_wrapper.dart';
import 'package:bhaithamen/screens/user_news.dart';
import 'package:bhaithamen/screens/welfare_check.dart';
import 'package:bhaithamen/utilities/auth.dart';
import 'package:bhaithamen/utilities/auto_page_navigation.dart';
import 'package:bhaithamen/utilities/fb_test.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/report_event.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:images_picker/images_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart' as flutLoc;

flutLoc.Location location = new flutLoc.Location();
flutLoc.LocationData myLocationData;

class NewsWrapper extends StatefulWidget {
  final User user;
  final FirebaseAnalyticsObserver observer;
  final FirebaseAnalytics analytics;

  NewsWrapper(this.user, this.observer, this.analytics);
  @override
  _NewsWrapperState createState() =>
      _NewsWrapperState(user, observer, analytics);
}

class _NewsWrapperState extends State<NewsWrapper> {
  _NewsWrapperState(this.user, this.observer, this.analytics);

  final FirebaseAnalyticsObserver observer;
  final FirebaseAnalytics analytics;
  final User user;

  bool canImagePick = false;

  AutoHomePageWelfareSelect homePageWelfare;

  String uid;
  TextEditingController myNews = TextEditingController();
  File _imageFile;
  String pickedImagePath;
  BuildContext thisContext;
  //List<Asset> images = List<Asset>();
  List<Media> images = List<Media>();
  List<String> firebaseUrls = List<String>();
  String userName = '';
  String userPhone = '';
  String userEmail = '';
  String profilePic = '';
  bool isUploading = false;
  bool shareLocation = false;
  var uuid = Uuid();

  initState() {
    super.initState();
    getCurrentUserInfo();
    canCompose = true;
    checkPerm();
    sendResearchReport('Community_Section');
  }

  checkPerm() async {
    // SMS PERM
    try {
      var status = await Permission.sms.status;
      if (status.isUndetermined || status.isDenied) {
        // We didn't ask for permission yet.
        if (await Permission.sms.request().isGranted) {
          print('sms granted');
          // Either the permission was already granted before or the user just granted it.
        }
      }
    } on Exception catch (exception) {
      print(exception.toString());
      // only executed if error is of type Exception
    } catch (error) {
      // executed for errors of all types other than Exception
    }

    ///
    /// CAM PERM
    try {
      var camStatus = await Permission.camera.status;
      if (camStatus.isUndetermined || camStatus.isDenied) {
        // We didn't ask for permission yet.
        if (await Permission.camera.request().isGranted) {
          print('cam granted');
          // Either the permission was already granted before or the user just granted it.
        }
      }
    } on Exception catch (exception) {
      // only executed if error is of type Exception
    } catch (error) {
      // executed for errors of all types other than Exception
    }
    ////
    ///
    ///phone perm
    try {
      var callStatus = await Permission.phone.status;
      if (callStatus.isUndetermined || callStatus.isDenied) {
        // We didn't ask for permission yet.
        if (await Permission.phone.request().isGranted) {
          print('phone granted');
          // Either the permission was already granted before or the user just granted it.
        }
      }
    } on Exception catch (exception) {
      // only executed if error is of type Exception
    } catch (error) {
      // executed for errors of all types other than Exception
    }

    //mic perm
    try {
      var audStatus = await Permission.microphone.status;
      if (audStatus.isUndetermined || audStatus.isDenied) {
        // We didn't ask for permission yet.
        if (await Permission.microphone.request().isGranted) {
          print('mic granted');
          // Either the permission was already granted before or the user just granted it.
        }
      }
    } on Exception catch (exception) {
      // only executed if error is of type Exception
    } catch (error) {
      // executed for errors of all types other than Exception
    }

    //store perm
    try {
      var storeStatus = await Permission.storage.status;
      if (storeStatus.isUndetermined || storeStatus.isDenied) {
        // We didn't ask for permission yet.
        if (await Permission.storage.request().isGranted) {
          print('store granted');
          // Either the permission was already granted before or the user just granted it.
        }
      }
    } on Exception catch (exception) {
      // only executed if error is of type Exception
    } catch (error) {
      // executed for errors of all types other than Exception
    }

    //location perm
    try {
      var locstatus = await Permission.location.status;
      if (locstatus.isUndetermined || locstatus.isDenied) {
        // We didn't ask for permission yet.
        if (await Permission.location.request().isGranted) {
          print('location granted');
          // Either the permission was already granted before or the user just granted it.
        }
      }
    } on Exception catch (exception) {
      // only executed if error is of type Exception
    } catch (error) {
      // executed for errors of all types other than Exception
    }

    //appHasStarted = await awaitStarted();
  }

  getCurrentUserInfo() async {
    var firebaseuser = fbAuth.FirebaseAuth.instance.currentUser;
    DocumentSnapshot userDoc = await userCollection.doc(firebaseuser.uid).get();
    setState(() {
      uid = firebaseuser.uid;
      userName = userDoc['username'];
      userPhone = userDoc['userPhone'];
      userEmail = userDoc['email'];
      profilePic = userDoc['profilepic'];
    });
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

  uploadImage(File myImage) async {
    var imgUid = uuid.v1();
    String savePath = uid + '/' + imgUid + '.jpg';

    StorageUploadTask storageUploadTask =
        userNews.child(savePath).putFile(myImage);
    StorageTaskSnapshot storageTaskSnapshot =
        await storageUploadTask.onComplete;
    String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  _postComment() async {
    print('post ');
    if (myNews.text.replaceAll(' ', '') != '') {
      List<String> imageUrls = List<String>();
      GeoPoint reportLocation;

      for (var i = 0; i < images.length; i++) {
        dynamic url = await uploadImage(File(images[i].path));
        imageUrls.add(url);
      }

      if (shareLocation == true) {
        reportLocation = await getUserLocation();
      } else {
        reportLocation = null;
      }

      int unixDate = getDate().toUtc().millisecondsSinceEpoch;

      final userNewsFeedDoc = UserNewsFeed(
              time: DateTime.now(),
              unixTime: unixDate,
              userName: userName,
              uid: uid,
              userPhone: userPhone,
              location: reportLocation,
              article: myNews.text,
              likes: [],
              reports: [],
              comments: [],
              shares: 0,
              images: imageUrls,
              show: true,
              profilePic: profilePic)
          .toMap();

      userNewsCollection.doc().set(userNewsFeedDoc).then((doc) {
        print('POST DONE');
        setState(() {
          isUploading = false;
          imageUrls = [];
          images = [];
          myNews.text = '';
          Navigator.pop(context);
        });
      });
    }
  }

  int newsPageIndex = 0;

  List newsPageOptions = [
    UserNewsPage(false),
    NewsPage(),
    AlertsNewsPage(),
    UserNewsPage(true)
  ];

  _switchLocationSharing(bool share) {
    setState(() {
      shareLocation = !shareLocation;
    });
  }

  doShow() {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (BuildContext context,
              StateSetter setModalState /*You can rename this!*/) {
            return !isUploading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              List<Media> res = await ImagesPicker.pick(
                                count: 4,
                                // pickType: PickType.video,
                              );
                              if (res != null) {
                                print(images.map((e) => e.path).toList());
                                setModalState(() {
                                  images.addAll(res);
                                });
                              }
                              // Navigator.pop(context);
                              //navigateSettings();
                            },
                            child: Container(
                                color: Colors.blue,
                                width: MediaQuery.of(context).size.width * 0.2,
                                padding: EdgeInsets.all(15.0),
                                child: Icon(Icons.camera_alt,
                                    color: Colors.white)),
                          ),
                          Container(
                            padding: EdgeInsets.all(3.0),
                            color: Colors.grey[300],
                            width: MediaQuery.of(context).size.width * 0.6,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                shareLocation
                                    ? Padding(
                                        padding:
                                            const EdgeInsets.only(right: 4.0),
                                        child: Icon(
                                          Icons.place,
                                          color: Colors.green,
                                        ),
                                      )
                                    : Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Icon(
                                          Icons.wrong_location,
                                          color: Colors.red[700],
                                        ),
                                      ),
                                shareLocation
                                    ? Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        child: Container(
                                          width: 110,
                                          child: Text(
                                            languages[selectedLanguage[
                                                    languageIndex]]
                                                ['locationSharingStatusOn'],
                                            style: myStyle(14),
                                            textAlign: TextAlign.left,
                                            maxLines: 2,
                                          ),
                                        ),
                                      )
                                    : Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        child: Container(
                                          width: 110,
                                          child: Text(
                                            languages[selectedLanguage[
                                                    languageIndex]]
                                                ['locationSharingStatusOff'],
                                            style: myStyle(14),
                                            textAlign: TextAlign.left,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ),
                                Switch(
                                    activeColor: Colors.green[500],
                                    inactiveThumbColor: Colors.red[700],
                                    value: shareLocation,
                                    onChanged: (bool val) {
                                      setModalState(() {
                                        shareLocation = !shareLocation;
                                      });
                                    }),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setModalState(() {
                                isUploading = true;
                              });
                              _postComment();
                            },
                            child: Container(
                                padding: EdgeInsets.all(15.0),
                                color: Colors.blue,
                                width: MediaQuery.of(context).size.width * 0.2,
                                child: Icon(Icons.send, color: Colors.white)),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            SizedBox(
                              height: 4.0,
                            ),

                            images.length > 0
                                ? SizedBox(
                                    height: 150,
                                    child: Column(
                                      children: [
                                        Expanded(
                                            child: GridView.count(
                                          scrollDirection: Axis.horizontal,
                                          crossAxisCount: 1,
                                          children: List.generate(images.length,
                                              (index) {
                                            return Stack(
                                                alignment: Alignment.topLeft,
                                                children: <Widget>[
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            2.0),
                                                    child: Card(
                                                        elevation: 6,
                                                        child: Container(
                                                          height: 100,
                                                          child: Image.file(
                                                            File(images[index]
                                                                .thumbPath),
                                                            fit: BoxFit.contain,
                                                          ),
                                                        )),
                                                  ),
                                                  Padding(
                                                      padding:
                                                          EdgeInsets.all(10.0),
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          setModalState(() {
                                                            images.removeAt(
                                                                index);
                                                          });
                                                        },
                                                        child: Container(
                                                          decoration:
                                                              new BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            border:
                                                                new Border.all(
                                                              color: Colors
                                                                  .black26,
                                                              width: 2.0,
                                                            ),
                                                          ),
                                                          child: CircleAvatar(
                                                              radius: 15,
                                                              backgroundColor:
                                                                  Colors
                                                                      .white70,
                                                              child: Icon(
                                                                Icons.delete,
                                                                color: Colors
                                                                    .red[800],
                                                                size: 25,
                                                              )),
                                                        ),
                                                      )),
                                                ]);
                                          }),
                                        )),
                                      ],
                                    ),
                                  )
                                : Container(),
                            SizedBox(height: 8),

                            Divider(
                              height: 2.0,
                              thickness: 2.0,
                              color: Colors.grey[300],
                            ),

                            Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom,
                                left: 5.0,
                                right: 5.0,
                                top: 8.0,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    12.0, 2.0, 12.0, 2.0),
                                child: Container(
                                  color: Colors.grey[200],
                                  child: ConstrainedBox(
                                    constraints: new BoxConstraints(
                                      minWidth:
                                          MediaQuery.of(context).size.width,
                                      maxWidth:
                                          MediaQuery.of(context).size.height,
                                      minHeight: 85.0,
                                      maxHeight: 105.0,
                                    ),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      reverse: true,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: TextField(
                                          keyboardType: TextInputType.multiline,
                                          maxLines: null,
                                          autofocus: true,
                                          controller: myNews,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // FlatButton(
                            //   color: Colors.blue,
                            //   child: Text('post'),
                            //   onPressed: () {
                            //     setModalState(() {
                            //       isUploading = true;
                            //     });
                            //     _postComment();
                            //   },
                            // ),

                            SizedBox(height: 15),
                          ],
                        ),
                      ),
                    ],
                  )
                : SizedBox(
                    child: Center(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 60,
                          ),
                          CircularProgressIndicator(),
                          SizedBox(
                            height: 40,
                          ),
                          Text(
                            'Posting...',
                            style: myStyle(21),
                          )
                        ],
                      ),
                    ),
                    height: 250,
                  );
          });
        });
  }

  FutureOr onGoBack(dynamic value) {
    setState(() {
      doShow();
    });
  }

  // void navigateSettings() {
  //   Route route =
  //       MaterialPageRoute(builder: (context) => MultiImagePickerScreen());
  //   Navigator.push(context, route).then(onGoBack);
  // }

  afterBuild(context) {
    if (showWelfare) {
      if (!homePageWelfare.shouldGoWelfare) {
        homePageWelfare.setHomePageWelfare(true);
        print('SHHHHHHH ' + showWelfare.toString());
      }
    } else {
      if (homePageWelfare.shouldGoWelfare) {
        homePageWelfare.setHomePageWelfare(false);
        print('SHHHHHHH ' + showWelfare.toString());
      }
    }
  }

  void navigateWelfare() {
    Route route = MaterialPageRoute(builder: (context) => WelfareCheck());
    Navigator.push(context, route);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => afterBuild(context));
    final AutoHomePageMapSelect homePageMap =
        Provider.of<AutoHomePageMapSelect>(context);
    final AutoHomePageAskSelect homePageAsk =
        Provider.of<AutoHomePageAskSelect>(context);
    homePageWelfare = Provider.of<AutoHomePageWelfareSelect>(context);
    final SafePageIndex safePageIndex = Provider.of<SafePageIndex>(context);

    thisContext = context;

    return MultiProvider(
      providers: [
        StreamProvider<UserData>.value(value: AuthService(uid: uid).userData),
        StreamProvider<List<NewsFeed>>.value(
            value: AuthService(uid: uid).getNews),
        StreamProvider<List<UserNewsFeed>>.value(
            value: AuthService(uid: uid).getUserNews),
        StreamProvider<List<AlertsFeed>>.value(
            value: AuthService(uid: uid).getAlerts),
      ],
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          actions: <Widget>[
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
                      //homePageIndex = 1; safePageIndex.setSafePageIndex(0);savedSafeIndex=0;homePageMap.setHomePageMap(false);
                    });
                  }),
            if (homePageAsk.shouldGoAsk)
              FlatButton(
                  child: Lottie.asset('assets/lottie/alert.json'),
                  onPressed: () {
                    setState(() {
                      homePageIndex = 2;
                      safePageIndex.setSafePageIndex(0);
                      savedSafeIndex = 0;
                      homePageAsk.setHomePageAsk(false);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                Home(user, observer, analytics)),
                      );
                    });
                  }),
            if (homePageWelfare.shouldGoWelfare)
              FlatButton(
                  child: Lottie.asset('assets/lottie/alert.json'),
                  onPressed: () {
                    navigateWelfare();
                  }),
            !canCompose
                ? Container()
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: MaterialButton(
                      onPressed: () {
                        shareLocation = false;
                        doShow();
                      },
                      color: Colors.white,
                      textColor: Colors.blue,
                      child: Icon(
                        Icons.edit,
                        size: 24,
                      ),
                      //padding: EdgeInsets.all(16),
                      shape: CircleBorder(),
                    ),
                  ),
          ],
        ),
        drawer: Drawer(
            child: ListView(children: [
          DrawerHeader(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: <Color>[Colors.blue[700], Colors.blue[200]])),
            child: Container(
                child: Column(
              children: [
                Material(
                  borderRadius: BorderRadius.all(Radius.circular(120.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: profilePic == 'default'
                        ? Image.asset('assets/images/defaultAvatar.png',
                            height: 100, width: 100)
                        : CachedNetworkImage(
                            height: 70,
                            width: 70,
                            imageUrl: profilePic,
                            progressIndicatorBuilder:
                                (context, url, downloadProgress) => SizedBox(
                              height: 100,
                              child: Center(
                                child: CircularProgressIndicator(
                                    value: downloadProgress.progress),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                          ),

                    //Image.network(profilePic, height: 70, width: 70),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 8, 2, 2),
                  child: Text(userName,
                      style: myStyle(20, Colors.white, FontWeight.w300)),
                ),
              ],
            )),
          ),
          CustomListTile(
              languages[selectedLanguage[languageIndex]]['sideMenu1'],
              FontAwesomeIcons.newspaper,
              NewsWrapper(user, observer, analytics),
              true,
              false),
          CustomListTile(
              languages[selectedLanguage[languageIndex]]['sideMenu2'],
              FontAwesomeIcons.hardHat,
              Home(user, observer, analytics),
              false,
              false),
          CustomListTile(
              languages[selectedLanguage[languageIndex]]['sideMenu3'],
              FontAwesomeIcons.map,
              MapPlacesWrapper(user, observer, analytics),
              false,
              false),
          CustomListTile(languages[selectedLanguage[languageIndex]]['settings'],
              FontAwesomeIcons.cog, SettingsWrapper(), false, true),
          CustomListTile(
              languages[selectedLanguage[languageIndex]]['about'],
              FontAwesomeIcons.questionCircle,
              AboutPage(widget.user, observer, analytics),
              false,
              false),
        ])),
        body: Column(
          children: [
            newsPageOptions[newsPageIndex],
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,

          onTap: (index) {
            //userNews.scrollToTop();
            setState(() {
              //set page variable = to index (0,1 or 2) depending on which button was pressed
              newsPageIndex = index;
              mapIsShowing = false;
              if (newsPageIndex == 0 || newsPageIndex == 3) {
                canCompose = true;
              } else {
                canCompose = false;
              }
            });
            switch (newsPageIndex) {
              case 0:
                sendResearchReport('Community_Section');
                break;
              case 1:
                sendResearchReport('News_Section');
                break;
              case 2:
                sendResearchReport('Alert_Section');
                break;

              default:
            }
          },
          fixedColor: Colors.blue[700],
          backgroundColor: Colors.white70,
          elevation: 12.0,
          selectedFontSize: 17,
          //selectedItemColor: Colors.redAccent,
          unselectedItemColor: Colors.grey[600],
          currentIndex: newsPageIndex,
          items: [
            //3 buttons across bottom of screen
            BottomNavigationBarItem(
                icon: newsPageIndex == 0
                    ? Icon(Icons.people_alt_outlined, size: 24)
                    : Icon(Icons.people_alt_outlined, size: 22),
                label: languages[selectedLanguage[languageIndex]]['community']),
            BottomNavigationBarItem(
                icon: newsPageIndex == 1
                    ? Icon(Icons.chrome_reader_mode, size: 24)
                    : Icon(Icons.chrome_reader_mode, size: 22),
                label: languages[selectedLanguage[languageIndex]]['news']),
            BottomNavigationBarItem(
                icon: newsPageIndex == 2
                    ? Icon(Icons.warning_amber_outlined, size: 26)
                    : Icon(Icons.warning_amber_outlined, size: 22),
                label: languages[selectedLanguage[languageIndex]]['warn']),
            BottomNavigationBarItem(
                icon: newsPageIndex == 3
                    ? Icon(Icons.person, size: 26)
                    : Icon(Icons.person, size: 22),
                label: languages[selectedLanguage[languageIndex]]['myposts'])
          ],
        ),
      ),
    );
  }
}
