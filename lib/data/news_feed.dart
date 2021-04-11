class NewsFeed {
  final String author;
  final String article;
  final String title;
  final String uid;
  final String docId;
  final DateTime time;
  final int shares;
  final List<dynamic> likes;
  final List<dynamic> comments;
  final int popularity;
  final List<dynamic> images;
  final bool show;
  final String category;

  NewsFeed(
      {this.uid,
      this.docId,
      this.author,
      this.comments,
      this.popularity,
      this.article,
      this.time,
      this.title,
      this.likes,
      this.shares,
      this.images,
      this.show,
      this.category});

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'docId': docId,
      'author': author,
      'article': article,
      'time': time,
      'popularity': popularity,
      'comments': comments,
      'likes': likes,
      'title': title,
      'shares': shares,
      'images': images,
      'show': show,
      'category': category,
    };
  }

  static NewsFeed fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return NewsFeed(
        author: map['author'],
        uid: map['uid'],
        docId: map['docId'],
        article: map['article'],
        time: map['time'],
        popularity: map['popularity'],
        comments: map['comments'],
        likes: map['likes'],
        shares: map['shares'],
        images: map['images'],
        title: map['title'],
        category: map['category'],
        show: map['show']);
  }
}
