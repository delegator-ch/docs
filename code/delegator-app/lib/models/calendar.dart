// lib/models/calendar.dart

import 'organisation.dart';
import 'user.dart';

class Calendar {
  final int? id;
  final Organisation organisation;
  final User? user;

  Calendar({this.id, required this.organisation, this.user});

  factory Calendar.fromJson(Map<String, dynamic> json) {
    return Calendar(
      id: json['id'],
      organisation: Organisation.fromJson(json['organisation']),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    data['organisation'] = organisation.toJson();
    if (user != null) data['user'] = user!.toJson();
    return data;
  }
}
