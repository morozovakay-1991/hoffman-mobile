import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:hoffman/features/profile/data/legal_repository.dart';
import 'package:hoffman/features/profile/domain/legal_document.dart';

/// `GET /legal-documents`. Public data, so not keyed by user.
final FutureProvider<List<LegalDocumentSummary>> legalDocumentsProvider =
    FutureProvider.autoDispose<List<LegalDocumentSummary>>(
      (ref) => ref.watch(legalRepositoryProvider).list(),
      // The screen shows its own retry instead.
      retry: (_, _) => null,
    );

/// `GET /legal-documents/{slug}`.
final FutureProviderFamily<LegalDocument, String> legalDocumentProvider =
    FutureProvider.autoDispose.family<LegalDocument, String>(
      (ref, slug) => ref.watch(legalRepositoryProvider).document(slug),
      retry: (_, _) => null,
    );
