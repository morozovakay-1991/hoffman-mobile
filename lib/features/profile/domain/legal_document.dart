import 'package:flutter/foundation.dart';

/// A row of `GET /legal-documents` (backend `LegalDocumentSummaryResource`).
@immutable
class LegalDocumentSummary {
  const LegalDocumentSummary({required this.slug, required this.title});

  factory LegalDocumentSummary.fromJson(Map<String, dynamic> json) {
    return LegalDocumentSummary(
      slug: json['slug'] as String,
      title: json['title'] as String? ?? '',
    );
  }

  /// Backend `LegalDocument::SLUG_PRIVACY`.
  static const String privacySlug = 'privacy';

  final String slug;
  final String title;

  @override
  bool operator ==(Object other) =>
      other is LegalDocumentSummary &&
      other.slug == slug &&
      other.title == title;

  @override
  int get hashCode => Object.hash(slug, title);
}

/// `GET /legal-documents/{slug}` (backend `LegalDocumentResource`). [body]
/// is HTML from the admin panel's rich-text editor.
@immutable
class LegalDocument {
  const LegalDocument({required this.title, required this.body});

  factory LegalDocument.fromJson(Map<String, dynamic> json) {
    return LegalDocument(
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  final String title;
  final String body;

  @override
  bool operator ==(Object other) =>
      other is LegalDocument && other.title == title && other.body == body;

  @override
  int get hashCode => Object.hash(title, body);
}
