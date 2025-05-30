// lib/models/my_invitation.dart

class Invitation {
  final int id;
  final int organisation;
  final int invitedBy;
  final String inviteCode;
  final int role;
  final String invitationUrl;
  final bool canAccept;
  final bool isExpired;

  Invitation({
    required this.id,
    required this.organisation,
    required this.invitedBy,
    required this.inviteCode,
    required this.role,
    required this.invitationUrl,
    required this.canAccept,
    required this.isExpired,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'],
      organisation: json['organisation'],
      invitedBy: json['invited_by'],
      inviteCode: json['invite_code'],
      role: json['role'],
      invitationUrl: json['invitation_url'],
      canAccept: json['can_accept'],
      isExpired: json['is_expired'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organisation': organisation,
      'invited_by': invitedBy,
      'invite_code': inviteCode,
      'role': role,
      'invitation_url': invitationUrl,
      'can_accept': canAccept,
      'is_expired': isExpired,
    };
  }

  @override
  String toString() {
    return 'MyInvitation{id: $id, organisation: $organisation, inviteCode: "$inviteCode", canAccept: $canAccept}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Invitation &&
        other.id == id &&
        other.organisation == organisation &&
        other.invitedBy == invitedBy &&
        other.inviteCode == inviteCode &&
        other.role == role;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      organisation.hashCode ^
      invitedBy.hashCode ^
      inviteCode.hashCode ^
      role.hashCode;
}
