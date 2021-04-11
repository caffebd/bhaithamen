import 'package:bhaithamen/data/event.dart';
import 'package:bhaithamen/data/incident_report.dart';

class IncidentDay {
  final String incidentDate;
  final List<IncidentReport> allIncidents;
  IncidentDay({
    this.incidentDate,
    this.allIncidents,
  });

  Map<dynamic, dynamic> toMap() {
    return {
      'eventDate': incidentDate,
      'allEvents': allIncidents?.map((x) => x?.toMap())?.toList(),
    };
  }

  static IncidentDay fromMap(Map<dynamic, dynamic> map) {
    if (map == null) return null;
  
    return IncidentDay(
      incidentDate: map['eventDate'],
      allIncidents: List<IncidentReport>.from(map['singleClass']?.map((x) => Event.fromMap(x))),
    );
  }

}