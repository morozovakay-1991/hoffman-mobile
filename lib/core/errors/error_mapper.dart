import 'package:dio/dio.dart';
import 'package:hoffman/core/errors/failure.dart';

/// Converts a [DioException] into a domain-level [Failure].
abstract final class ErrorMapper {
  static Failure map(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const Failure.network();
      case DioExceptionType.badResponse:
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.unknown:
      // Falls through to the status-code mapping below, which also covers
      // the case where there is no response at all.
    }

    final statusCode = exception.response?.statusCode;
    switch (statusCode) {
      case 400:
      case 422:
        return Failure.validation(_extractFields(exception.response?.data));
      case 401:
        return const Failure.unauthorized();
      case 403:
        return const Failure.accessDenied();
      case 404:
        return const Failure.notFound();
      default:
        if (statusCode != null && statusCode >= 500) {
          return const Failure.server();
        }
        return const Failure.network();
    }
  }

  static Map<String, List<String>> _extractFields(dynamic data) {
    if (data is! Map) {
      return const {};
    }
    final rawFields = data['errors'] is Map ? data['errors'] as Map : data;

    final fields = <String, List<String>>{};
    for (final entry in rawFields.entries) {
      final value = entry.value;
      if (value is List) {
        fields[entry.key.toString()] = value.map((e) => e.toString()).toList();
      } else if (value != null) {
        fields[entry.key.toString()] = [value.toString()];
      }
    }
    return fields;
  }
}
