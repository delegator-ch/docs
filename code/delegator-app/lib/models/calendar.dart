// lib/models/calendar.dart

import 'organisation.dart';

class Calendar {
  final int? id;
  final int? organisationId;
  final Organisation? organisation;
  final String? icalUrl;

  Calendar({this.id, this.organisationId, this.organisation, this.icalUrl});

  factory Calendar.fromJson(Map<String, dynamic> json) {
    // Handle the case where organisation might be just an ID
    int? orgId;
    Organisation? org;

    if (json['organisation'] != null) {
      // If organisation field exists, store its ID
      if (json['organisation'] is int) {
        orgId = json['organisation'];
      } else if (json['organisation'] is Map<String, dynamic>) {
        // If somehow the organisation is a full object, parse it
        org = Organisation.fromJson(json['organisation']);
        orgId = org.id;
      }
    }

    // Check if organisation_details exists and is a Map
    if (json['organisation_details'] != null &&
        json['organisation_details'] is Map<String, dynamic>) {
      org = Organisation.fromJson(json['organisation_details']);
    }

    return Calendar(
      id: json['id'],
      organisationId: orgId,
      organisation: org,
      icalUrl: json['ical_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    if (organisationId != null) data['organisation'] = organisationId;
    if (icalUrl != null) data['ical_url'] = icalUrl;
    // Don't include the organisation object in the JSON
    return data;
  }
}
