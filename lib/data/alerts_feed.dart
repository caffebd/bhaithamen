class AlertsFeed {
  final String article;
  final String title;
  final String docId;
  final DateTime time;
  final int shares;
  final List<dynamic> likes;
  final int popularity;
  final String image;
  final bool show;

  AlertsFeed(
      {this.docId,
      this.popularity,
      this.article,
      this.time,
      this.title,
      this.likes,
      this.shares,
      this.image,
      this.show});

  Map<String, dynamic> toMap() {
    return {
      'docId': docId,
      'article': article,
      'time': time,
      'popularity': popularity,
      'likes': likes,
      'title': title,
      'shares': shares,
      'image': image,
      'show': show
    };
  }

  static AlertsFeed fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return AlertsFeed(
        docId: map['docId'],
        article: map['article'],
        time: map['time'],
        popularity: map['popularity'],
        likes: map['likes'],
        shares: map['shares'],
        image: map['image'],
        title: map['title'],
        show: map['show']);
  }
}
