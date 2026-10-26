// models/team_model.dart

// Keep team management separate
import 'package:lehwipalancecustomerv1/core/auth/permission_service.dart';
import 'package:lehwipalancecustomerv1/core/base/identifiable.dart';
import 'package:lehwipalancecustomerv1/core/utils/validators.dart';
import 'package:lehwipalancecustomerv1/enum.dart';

class InvitationDTO implements Identifiable, Timestamped {
  @override
  final String id;
  final String email;
  final String? userId;
  final String invitedBy;

  final String organisationId;
  final String? listingId;
  final String? teamId;
  final String? roleLabel;
  final List<String>? permissions;
  final InvitationStatus status;
  final DateTime invitedAt;
  final DateTime? expiresAt;
  final DateTime? respondedAt;
  final String? message;
  final int resendCount;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;

  InvitationDTO({
    required this.id,
    required this.email,
    this.userId,
    required this.invitedBy,
    required this.organisationId,
    this.listingId,
    this.teamId,
    this.roleLabel,
    this.permissions,
    required this.status,
    required this.invitedAt,
    this.expiresAt,
    this.respondedAt,
    this.message,
    this.resendCount = 0,
    required this.createdAt,
    this.updatedAt,
  }) {
    ValidationUtils.validateEmail(email);
  }

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get canResend =>
      status == InvitationStatus.sent && resendCount < 3 && !isExpired;
  bool get isPending => status == InvitationStatus.sent;
  bool get isAccepted => status == InvitationStatus.accepted;
  bool get isRejected => status == InvitationStatus.rejected;
  bool get isCancelled => status == InvitationStatus.cancelled;

  List<Permission> get grantedPermissions {
    if (permissions != null) return Permission.fromStrings(permissions!);
    return Permission.viewerPermissions;
  }

  InvitationDTO accept(String userId) {
    if (!isPending) throw StateError('Can only accept sent invitations');
    if (isExpired) throw StateError('Cannot accept expired invitation');
    return copyWith(
      userId: userId,
      status: InvitationStatus.accepted,
      respondedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  InvitationDTO reject() {
    if (!isPending) throw StateError('Can only reject sent invitations');
    return copyWith(
      status: InvitationStatus.rejected,
      respondedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  InvitationDTO cancel() {
    if (!isPending) throw StateError('Can only cancel sent invitations');
    return copyWith(
      status: InvitationStatus.cancelled,
      respondedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  InvitationDTO resend() {
    if (!canResend) throw StateError('Cannot resend this invitation');
    return copyWith(
      invitedAt: DateTime.now(),
      expiresAt: DateTime.now().add(ValidationUtils.invitationExpiry),
      resendCount: resendCount + 1,
      status: InvitationStatus.sent,
      respondedAt: null,
      updatedAt: DateTime.now(),
    );
  }

  InvitationDTO copyWith({
    String? id,
    String? email,
    String? userId,
    String? invitedBy,
    String? organisationId,
    String? listingId,
    String? teamId,
    String? roleLabel,
    List<String>? permissions,
    InvitationStatus? status,
    DateTime? invitedAt,
    DateTime? expiresAt,
    DateTime? respondedAt,
    String? message,
    int? resendCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvitationDTO(
      id: id ?? this.id,
      email: email ?? this.email,
      userId: userId ?? this.userId,
      invitedBy: invitedBy ?? this.invitedBy,
      organisationId: organisationId ?? this.organisationId,
      listingId: listingId ?? this.listingId,
      teamId: teamId ?? this.teamId,
      roleLabel: roleLabel ?? this.roleLabel,
      permissions: permissions ?? this.permissions,
      status: status ?? this.status,
      invitedAt: invitedAt ?? this.invitedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      respondedAt: respondedAt ?? this.respondedAt,
      message: message ?? this.message,
      resendCount: resendCount ?? this.resendCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'userId': userId,
    'invitedBy': invitedBy,
    'organisationId': organisationId,
    'listingId': listingId,
    'teamId': teamId,
    'roleLabel': roleLabel,
    'permissions': permissions,
    'status': status.name,
    'invitedAt': invitedAt.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
    'respondedAt': respondedAt?.toIso8601String(),
    'message': message,
    'resendCount': resendCount,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory InvitationDTO.fromJson(Map<String, dynamic> json) {
    return InvitationDTO(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      userId: json['userId'],
      invitedBy: json['invitedBy'] ?? '',
      organisationId: json['organisationId'] ?? '',
      listingId: json['listingId'],
      teamId: json['teamId'],
      roleLabel: json['roleLabel'],
      permissions: json['permissions'] != null
          ? List<String>.from(json['permissions'])
          : null,
      status: InvitationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InvitationStatus.sent,
      ),
      invitedAt: json['invitedAt'] != null
          ? DateTime.parse(json['invitedAt'])
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'])
          : null,
      message: json['message'],
      resendCount: json['resendCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }
}

final List<InvitationDTO> mockInvitations = [];
