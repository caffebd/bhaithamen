class IncidentReport {
  final String type;
  final String location;
  final DateTime time;
  final String target;
  final String incidentDate;
  final String description;
  final String reportUid;
  final String userPhone;
  final List<dynamic> attachedEvents;

  IncidentReport(
      {this.type,
      this.location,
      this.time,
      this.target,
      this.incidentDate,
      this.description,
      this.reportUid,
      this.userPhone,
      this.attachedEvents});

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'location': location,
      'time': time,
      'target': target,
      'incidentDate': incidentDate,
      'description': description,
      'reportUid': reportUid,
      'attachedEvents': attachedEvents,
      'userPhone': userPhone
    };
  }

  static IncidentReport fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return IncidentReport(
        type: map['type'],
        location: map['location'],
        time: map['time'],
        target: map['target'],
        incidentDate: map['incidentDate'],
        description: map['description'],
        reportUid: map['reportUid'],
        userPhone: map['userPhone'],
        attachedEvents: map['attachedEvents']);
  }
}
