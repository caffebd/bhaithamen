import 'package:cloud_firestore/cloud_firestore.dart';

class UserNewsFeed {
  final String docId;
  final String userName;
  final String userPhone;
  final double distance;
  final String article;
  final String title;
  final String uid;
  final DateTime time;
  final int unixTime;
  final int shares;
  final int popularity;
  final GeoPoint location;
  final List<dynamic> likes;
  final List<dynamic> images;
  final List<dynamic> reports;
  final List<dynamic> comments;
  final bool show;
  final String profilePic;

  UserNewsFeed(
      {this.docId,
      this.uid,
      this.distance,
      this.popularity,
      this.userName,
      this.userPhone,
      this.article,
      this.time,
      this.unixTime,
      this.title,
      this.location,
      this.likes,
      this.shares,
      this.comments,
      this.images,
      this.show,
      this.profilePic,
      this.reports});

  Map<String, dynamic> toMap() {
    return {
      'docId': docId,
      'uid': uid,
      'distance': distance,
      'popularity': popularity,
      'userName': userName,
      'userPhone': userPhone,
      'article': article,
      'time': time,
      'unixTime': unixTime,
      'likes': likes,
      'comments': comments,
      'location': location,
      'reports': reports,
      'title': title,
      'shares': shares,
      'images': images,
      'show': show,
      'category': profilePic,
    };
  }

  static UserNewsFeed fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return UserNewsFeed(
        userName: map['userName'],
        userPhone: map['userPhone'],
        popularity: map['popularity'],
        uid: map['uid'],
        distance: map['distance'],
        docId: map['docId'],
        article: map['article'],
        time: map['time'],
        unixTime: map['unixTime'],
        likes: map['likes'],
        shares: map['shares'],
        images: map['images'],
        comments: map['comments'],
        location: map['location'],
        title: map['title'],
        reports: map['reports'],
        profilePic: map['profilePic'],
        show: map['show']);
  }
}
