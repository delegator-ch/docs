// lib/model/event_model.dart
class Event {
  final int id;
  final int calendar;
  final String start;
  final String end;
  final bool isGig;
  final CalendarDetails calendarDetails;

  Event({
    required this.id,
    required this.calendar,
    required this.start,
    required this.end,
    required this.isGig,
    required this.calendarDetails,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      calendar: json['calendar'],
      start: json['start'],
      end: json['end'],
      isGig: json['is_gig'] ?? false,
      calendarDetails: CalendarDetails.fromJson(json['calendar_details']),
    );
  }
}

class CalendarDetails {
  final int id;
  final int organisation;
  final OrganisationDetails organisationDetails;

  CalendarDetails({
    required this.id,
    required this.organisation,
    required this.organisationDetails,
  });

  factory CalendarDetails.fromJson(Map<String, dynamic> json) {
    return CalendarDetails(
      id: json['id'],
      organisation: json['organisation'],
      organisationDetails: OrganisationDetails.fromJson(
        json['organisation_details'],
      ),
    );
  }
}

class OrganisationDetails {
  final int id;
  final String name;
  final String since;

  OrganisationDetails({
    required this.id,
    required this.name,
    required this.since,
  });

  factory OrganisationDetails.fromJson(Map<String, dynamic> json) {
    return OrganisationDetails(
      id: json['id'],
      name: json['name'],
      since: json['since'],
    );
  }
}
