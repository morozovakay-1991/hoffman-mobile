import 'package:flutter/foundation.dart';

/// Backend `VerificationStatus`.
enum VerificationStatus {
  /// No match in the graduate directory (or the match is already claimed by
  /// another user): left for manual review by an administrator.
  pending,

  /// Matched the graduate directory, or approved by an administrator.
  confirmed,

  /// Rejected by an administrator.
  rejected,

  /// A value this app version does not know.
  unknown;

  static VerificationStatus fromJson(Object? value) => switch (value) {
    'pending' => pending,
    'confirmed' => confirmed,
    'rejected' => rejected,
    _ => unknown,
  };
}

/// The user's graduate verification request, as returned in
/// `verification_request` by `/verification/submit` and
/// `/verification/status` (backend `VerificationRequestResource`).
@immutable
class VerificationRequest {
  const VerificationRequest({
    required this.status,
    required this.lastName,
    required this.firstName,
    required this.phone,
  });

  factory VerificationRequest.fromJson(Map<String, dynamic> json) {
    return VerificationRequest(
      status: VerificationStatus.fromJson(json['status']),
      lastName: json['last_name'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }

  final VerificationStatus status;
  final String lastName;
  final String firstName;
  final String phone;

  bool get isConfirmed => status == VerificationStatus.confirmed;

  @override
  bool operator ==(Object other) =>
      other is VerificationRequest &&
      other.status == status &&
      other.lastName == lastName &&
      other.firstName == firstName &&
      other.phone == phone;

  @override
  int get hashCode => Object.hash(status, lastName, firstName, phone);
}
