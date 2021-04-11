import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String type;
  final String category;
  final GeoPoint location;
  final DateTime time;
  final String eventId;
  final String userPhone;
  final int age;

  Event(
      {this.type,
      this.category,
      this.location,
      this.time,
      this.userPhone,
      this.eventId,
      this.age});

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'category': category,
      'location': location,
      'time': time,
      'userPhone': userPhone,
      'age': age,
      'eventId': eventId
    };
  }

  static Event fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return Event(
        type: map['type'],
        category: map['category'],
        location: map['location'],
        time: map['time'],
        userPhone: map['userPhone'],
        age: map['age'],
        eventId: map['eventId']);
  }
}
