import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// Domain-level representation of everything that can go wrong when talking
/// to the backend, produced by `ErrorMapper` from a `DioException`.
@freezed
sealed class Failure with _$Failure {
  /// No connection to the backend, or a connection/read/send timeout.
  const factory Failure.network() = NetworkFailure;

  /// The backend responded with a 5xx status code.
  const factory Failure.server() = ServerFailure;

  /// The backend rejected the request as invalid (400/422). [fields] maps
  /// each invalid field name to its list of validation messages.
  const factory Failure.validation(Map<String, List<String>> fields) = ValidationFailure;

  /// The backend responded 401 — the session is missing or expired.
  const factory Failure.unauthorized() = UnauthorizedFailure;

  /// The backend responded 403 — authenticated, but not allowed.
  const factory Failure.accessDenied() = AccessDeniedFailure;

  /// The backend responded 404.
  const factory Failure.notFound() = NotFoundFailure;
}
