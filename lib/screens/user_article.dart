import 'package:auto_size_text/auto_size_text.dart';
import 'package:bhaithamen/data/user_news_feed.dart';
import 'package:bhaithamen/utilities/language_data.dart';
import 'package:bhaithamen/utilities/variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_format/date_format.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:keyboard_utils/keyboard_utils.dart';
import 'package:keyboard_utils/keyboard_listener.dart';
import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';

class UserArticle extends StatefulWidget {
  final UserNewsFeed userArticle;
  UserArticle(this.userArticle);
  @override
  _UserArticleState createState() => _UserArticleState();
}

class _UserArticleState extends State<UserArticle> {
  TextEditingController myComment = TextEditingController();
  FocusNode _focusNode = FocusNode();
  bool bottomPadding = false;

  String myUsername;
  String myUid;
  int myShares;

  KeyboardUtils _keyboardUtils = KeyboardUtils();

  int _idKeyboardListener;

  List<Widget> imageSliders;

  setUpSlider() {
    imageSliders = widget.userArticle.images
        .map((item) => Container(
              child: Container(
                margin: EdgeInsets.all(5.0),
                child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    child: Stack(
                      children: <Widget>[
                        Image.network(item, fit: BoxFit.cover, height: 1000.0),
                        Positioned(
                          bottom: 0.0,
                          left: 0.0,
                          right: 0.0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color.fromARGB(200, 0, 0, 0),
                                  Color.fromARGB(0, 0, 0, 0)
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 20.0),
                            child: Container(),
                            // Text(
                            //   'No. ${widget.userArticle.images.indexOf(item)} image',
                            //   style: TextStyle(
                            //     color: Colors.white,
                            //     fontSize: 20.0,
                            //     fontWeight: FontWeight.bold,
                            //   ),
                            // ),
                          ),
                        ),
                      ],
                    )),
              ),
            ))
        .toList();
  }

  @override
  void initState() {
    super.initState();

    getCurrentUserInfo();

    setUpSlider();

    myShares = widget.userArticle.shares;

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          bottomPadding = true;
        });
      } else {
        setState(() {
          bottomPadding = false;
        });
      }
    });

    _idKeyboardListener = _keyboardUtils.add(
        listener: KeyboardListener(willHideKeyboard: () {
      FocusScope.of(context).unfocus();
      print('NO OCUS');
    }, willShowKeyboard: (double keyboardHeight) {
      setState(() {
        bottomPadding = true;
      });
    }));
  }

  @override
  void dispose() {
    _focusNode.dispose();

    super.dispose();
  }

  getCurrentUserInfo() async {
    var firebaseuser = FirebaseAuth.instance.currentUser;
    DocumentSnapshot userDoc = await userCollection.doc(firebaseuser.uid).get();
    setState(() {
      myUid = firebaseuser.uid;
      myUsername = userDoc['username'];
    });
  }

  String getPubDate(DateTime date) {
    String returnDate;

    String year = formatDate(date, [yyyy]);
    String month = formatDate(date, [mm]);
    String fullMonth = formatDate(date, [MM]);
    String day = formatDate(date, [dd]);
    String hour = formatDate(date, [HH, ':', nn]);

    returnDate = day + ' ' + fullMonth + ' ' + year + ' at ' + hour;

    return returnDate;
  }

  postComment() async {
    if (myComment.text.replaceAll(' ', '') != '') {
      var addComment = {'username': myUsername, 'comment': myComment.text};

      userNewsCollection.doc(widget.userArticle.docId).update({
        'comments': FieldValue.arrayUnion([addComment]),
      });

      setState(() {
        widget.userArticle.comments.add(addComment);
        FocusScope.of(context).unfocus();
        myComment.clear();
      });
    }
  }

  likePost(String docId) async {
    var firebaseuser = FirebaseAuth.instance.currentUser;
    DocumentSnapshot document =
        await userNewsCollection.doc(widget.userArticle.docId).get();

    if (document['likes'].contains(firebaseuser.uid)) {
      userNewsCollection.doc(docId).update({
        'likes': FieldValue.arrayRemove([firebaseuser.uid]),
      });
      setState(() {
        widget.userArticle.likes.remove(myUid);
      });
    } else {
      userNewsCollection.doc(docId).update({
        'likes': FieldValue.arrayUnion([firebaseuser.uid]),
      });
      setState(() {
        widget.userArticle.likes.add(myUid);
      });
    }
  }

  sharePost(String docId, String title, String tweet) async {
    String msg = title +
        '\n\n' +
        tweet +
        '\n\n' +
        'Shared from Bhai Thamen https://bhaithamen.com';
    Share.share(msg, subject: 'Bhai Thamen');
    DocumentSnapshot document =
        await userNewsCollection.doc(widget.userArticle.docId).get();
    userNewsCollection.doc(docId).update({'shares': document['shares'] + 1});
    setState(() {
      myShares++;
    });
  }

  Future<void> _onOpen(LinkableElement link) async {
    if (await canLaunch(link.url)) {
      await launch(link.url);
    } else {
      throw 'Could not launch $link';
    }
  }

  Future<bool> _askDelete(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
            title: Text(
                languages[selectedLanguage[languageIndex]]['askDeletePost1']),
            content: Container(
                height: 180,
                width: 320,
                child: Center(
                      child: Column(
                        children: [
                          Text(
                              languages[selectedLanguage[languageIndex]]
                                  ['askDeletePost2'],
                              style: myStyle(20, Colors.red, FontWeight.w400)),
                          SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Spacer(),
                              FlatButton(
                                child: Text(
                                    languages[selectedLanguage[languageIndex]]
                                        ['yes'],
                                    style: myStyle(14, Colors.white)),
                                textColor: Colors.white,
                                color: Colors.green,
                                onPressed: () async {
                                  _doDelete();
                                },
                              ),
                              SizedBox(width: 14),
                              FlatButton(
                                child: AutoSizeText(
                                    languages[selectedLanguage[languageIndex]]
                                        ['no'],
                                    maxLines: 2,
                                    style: myStyle(14, Colors.white)),
                                textColor: Colors.white,
                                color: Colors.red,
                                onPressed: () async {
                                  //analyticsHelper.sendAnalyticsEvent('Sign_Out');
                                  //await sendResearchReport('Sign_Out');
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ) ??
                    false)));
  }

  _doDelete() async {
    for (var i = 0; i < widget.userArticle.images.length; i++) {
      FirebaseStorage.instance
          .getReferenceFromUrl(widget.userArticle.images[i])
          .then((reference) => reference.delete())
          .catchError((e) => print(e));
    }

    userNewsCollection.doc(widget.userArticle.docId).delete().then((done) {
      print('Delete DONE');
      Navigator.pop(context);
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        actions: <Widget>[
          // Padding(
          //   padding: const EdgeInsets.all(8.0),
          //   child: FlatButton(
          //     child: Image.asset('assets/images/cross.png'),
          //     onPressed: () {},
          //   ),
          // ),
        ],
      ),
      body: InkWell(
        splashColor: Colors.transparent,
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height -
                  AppBar().preferredSize.height -
                  50,
              child: SingleChildScrollView(
                child: Column(children: [
                  Card(
                      margin: EdgeInsets.fromLTRB(5, 10, 5, 10),
                      child: ListTile(
                          // leading: CircleAvatar(
                          //   backgroundColor: Colors.white,
                          //   backgroundImage: feeddoc['profilepic'] == 'default'
                          //       ? AssetImage('images/defaultAvatar.png')
                          //       : NetworkImage(feeddoc['profilepic']),
                          // ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.userArticle.userName,
                                style:
                                    myStyle(18, Colors.blue, FontWeight.w600),
                              ),
                              Text(getPubDate(widget.userArticle.time))
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  widget.userArticle.images.length == 0
                                      ? Container()
                                      : Column(
                                          children: <Widget>[
                                            CarouselSlider(
                                              options: CarouselOptions(
                                                autoPlay: true,
                                                aspectRatio: 1.5,
                                                enlargeCenterPage: true,
                                              ),
                                              items: imageSliders,
                                            ),
                                          ],
                                        ),
                                  // : Center(
                                  //     child: Padding(
                                  //       padding: const EdgeInsets.all(12.0),
                                  //       child: Image(
                                  //         height: 200,
                                  //         image: NetworkImage(
                                  //             widget.userArticle.images[0]),
                                  //       ),
                                  //     ),
                                  //   ),
                                  Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Linkify(
                                          onOpen: _onOpen,
                                          text: widget.userArticle.article,
                                          style: myStyle(16, Colors.black,
                                              FontWeight.w400))
                                      // Text(
                                      //   feeddoc.article,
                                      //   style: myStyle(16, Colors.black,
                                      //       FontWeight.w400),
                                      // ),
                                      ),
                                  SizedBox(height: 10),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Spacer(),
                                  Row(
                                    children: [
                                      InkWell(
                                          onTap: () => likePost(
                                              widget.userArticle.docId),
                                          child: widget.userArticle.likes
                                                  .contains(myUid)
                                              ? Icon(Icons.favorite,
                                                  size: 20, color: Colors.red)
                                              : Icon(Icons.favorite_border,
                                                  size: 20)),
                                      SizedBox(width: 10),
                                      Text(
                                          widget.userArticle.likes.length
                                              .toString(),
                                          style: myStyle(16, Colors.grey[600])),
                                    ],
                                  ),
                                  Spacer(),
                                  Row(
                                    children: [
                                      InkWell(
                                          onTap: () => sharePost(
                                              widget.userArticle.docId,
                                              widget.userArticle.title,
                                              widget.userArticle.article),
                                          child: Icon(Icons.share, size: 20)),
                                      SizedBox(width: 10),
                                      Text(myShares.toString(),
                                          style: myStyle(16, Colors.grey[600])),
                                    ],
                                  ),
                                  Spacer(),
                                  Row(
                                    children: [
                                      InkWell(
                                          onTap: () {},
                                          child: Icon(
                                              Icons.comment_bank_outlined,
                                              size: 20)),
                                      SizedBox(width: 10),
                                      Text(
                                          widget.userArticle.comments.length
                                              .toString(),
                                          style: myStyle(16, Colors.grey[600])),
                                    ],
                                  ),
                                  Spacer(),
                                  widget.userArticle.uid == myUid
                                      ? InkWell(
                                          onTap: () {
                                            _askDelete(context);
                                          },
                                          child: Icon(Icons.delete,
                                              color: Colors.red[700]),
                                        )
                                      : Container(),
                                ],
                              ),
                            ],
                          ))),
                  for (var i = 0; i < widget.userArticle.comments.length; i++)
                    Column(
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  36.0, 8.0, 16.0, 8.0),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.userArticle.comments[i]
                                          ['username'],
                                      style: myStyle(
                                          14, Colors.black, FontWeight.bold),
                                    ),
                                    Text(
                                      widget.userArticle.comments[i]['comment'],
                                      style: myStyle(16, Colors.black),
                                    ),
                                  ]),
                            ),
                          ],
                        ),
                        Divider(
                            color: Colors.grey[300],
                            height: 2.0,
                            thickness: 2.0,
                            indent: 20,
                            endIndent: 20)
                      ],
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12.0, 5, 12, 5),
                    child: SizedBox(
                      height: 100,
                      child: Row(children: [
                        SizedBox(
                          width: 220,
                          child: TextField(
                            scrollPadding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom),
                            focusNode: _focusNode,
                            minLines: 1,
                            maxLines: 8,
                            autofocus: false,
                            controller: myComment,
                          ),
                        ),
                        FlatButton(
                          color: Colors.blue,
                          child: Text('post'),
                          onPressed: () {
                            postComment();
                          },
                        ),
                      ]),
                    ),
                  ),
                  bottomPadding
                      ? SizedBox(
                          height: (MediaQuery.of(context).size.height / 3) + 20)
                      : SizedBox(height: 0)
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
