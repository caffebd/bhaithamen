import 'package:bhaithamen/data/event.dart';

class EventDay {
  final String eventDate;
  final List<Event> allEvents;
  EventDay({
    this.eventDate,
    this.allEvents,
  });

  Map<dynamic, dynamic> toMap() {
    return {
      'eventDate': eventDate,
      'allEvents': allEvents?.map((x) => x?.toMap())?.toList(),
    };
  }

  static EventDay fromMap(Map<dynamic, dynamic> map) {
    if (map == null) return null;
  
    return EventDay(
      eventDate: map['eventDate'],
      allEvents: List<Event>.from(map['singleClass']?.map((x) => Event.fromMap(x))),
    );
  }

}