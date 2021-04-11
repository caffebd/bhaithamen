import 'package:cloud_firestore/cloud_firestore.dart';

class SafePlace {
  final String detailsEN;
  final String detailsBN;
  final String docId;
  final String price;
  final String phone;
  final String website;
  final String social;
  final String locationDescEN;
  final String locationDescBN;
  final String typeEN;
  final String typeBN;
  final List<dynamic> facilitiesEN;
  final List<dynamic> facilitiesBN;
  final String nameEN;
  final String nameBN;
  final String category;
  final List<dynamic> images;
  final GeoPoint location;
  final int rating;
  final int raters;
  final DateTime time;

  SafePlace(
      {this.detailsEN,
      this.detailsBN,
      this.location,
      this.category,
      this.time,
      this.phone,
      this.rating,
      this.raters,
      this.price,
      this.images,
      this.nameEN,
      this.nameBN,
      this.locationDescBN,
      this.locationDescEN,
      this.typeBN,
      this.typeEN,
      this.facilitiesBN,
      this.facilitiesEN,
      this.website,
      this.social,
      this.docId});

  Map<String, dynamic> toMap() {
    return {
      'detailsEN': detailsEN,
      'detailsBN': detailsBN,
      'time': time,
      'nameEN': nameEN,
      'nameBN': nameBN,
      'website': website,
      'social': social,
      'typeEN': typeEN,
      'typeBN': typeBN,
      'facilitiesBN': facilitiesBN,
      'facilitiesEN': facilitiesEN,
      'locationDescBN': locationDescBN,
      'locationDescEN': locationDescEN,
      'phone': phone,
      'category': category,
      'images': images,
      'price': price,
      'location': location,
      'rating': rating,
      'raters': raters,
      'docId': docId
    };
  }

  static SafePlace fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return SafePlace(
        location: map['location'],
        time: map['time'],
        nameEN: map['nameEN'],
        nameBN: map['nameBN'],
        website: map['website'],
        social: map['social'],
        typeBN: map['typeBN'],
        typeEN: map['typeEN'],
        facilitiesBN: map['facilitiesBN'],
        facilitiesEN: map['facilitiesEN'],
        locationDescBN: map['locationDescBN'],
        locationDescEN: map['locationDescEN'],
        phone: map['phone'],
        category: map['category'],
        images: map['images'],
        detailsEN: map['detailsEN'],
        detailsBN: map['detailsBN'],
        rating: map['rating'],
        raters: map['raters'],
        price: map['price'],
        docId: map['docId']);
  }
}
