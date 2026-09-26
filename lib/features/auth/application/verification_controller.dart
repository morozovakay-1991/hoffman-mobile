import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:hoffman/features/auth/application/auth_controller.dart';
import 'package:hoffman/features/auth/data/verification_repository.dart';
import 'package:hoffman/features/auth/domain/auth_exception.dart';
import 'package:hoffman/features/auth/domain/verification_request.dart';

/// Id of the signed-in user; `null` while signed out or restoring.
final signedInUserIdProvider = Provider<int?>(
  (ref) => switch (ref.watch(authControllerProvider).value) {
    Authenticated(:final user) => user.id,
    _ => null,
  },
);

/// Graduate verification request of the user [userId], loaded with
/// `GET /verification/status` (`null`: never submitted).
///
/// [submit] never puts the provider into loading; the form tracks its own
/// progress and catches the thrown [AuthException].
class VerificationController extends AsyncNotifier<VerificationRequest?> {
  VerificationController(this.userId);

  final int userId;

  @override
  Future<VerificationRequest?> build() =>
      ref.watch(verificationRepositoryProvider).status();

  Future<VerificationRequest> submit({
    required String lastName,
    required String firstName,
    required String phone,
  }) async {
    final request = await ref
        .read(verificationRepositoryProvider)
        .submit(lastName: lastName, firstName: firstName, phone: phone);
    state = AsyncData(request);
    return request;
  }
}

/// Keyed by user id rather than rebuilt on sign-in: a rebuilt provider
/// keeps its previous value while reloading, which would briefly hand one
/// account's request (and its `confirmed` status) to the next account on
/// the same device.
final AsyncNotifierProviderFamily<
  VerificationController,
  VerificationRequest?,
  int
>
verificationControllerProvider = AsyncNotifierProvider.autoDispose
    .family<VerificationController, VerificationRequest?, int>(
      VerificationController.new,
      // Screens that need the status show their own retry instead.
      retry: (_, _) => null,
    );

/// The signed-in user's verification request — the source of truth for
/// graduate-only access (e.g. the Diary). `AsyncData(null)` when signed out.
final Provider<AsyncValue<VerificationRequest?>> currentVerificationProvider =
    Provider.autoDispose<AsyncValue<VerificationRequest?>>((ref) {
      final userId = ref.watch(signedInUserIdProvider);
      if (userId == null) return const AsyncData(null);
      return ref.watch(verificationControllerProvider(userId));
    });
