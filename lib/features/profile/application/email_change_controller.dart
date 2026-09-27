import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoffman/features/auth/index.dart';

/// The new email waiting for its code, carried from the email screen
/// (642:3504) to the code screen (848:1330); `null` when no change is in
/// progress.
class EmailChangeController extends Notifier<String?> {
  /// Starts over whenever the signed-in user changes, so one account's
  /// pending email never reaches the next account on the device.
  @override
  String? build() {
    ref.watch(signedInUserIdProvider);
    return null;
  }

  void codeSent(String newEmail) => state = newEmail;

  void reset() => state = null;
}

/// Not auto-disposed: nothing listens between the email screen setting it
/// and the code screen opening. Reset once the change is confirmed.
final emailChangeControllerProvider =
    NotifierProvider<EmailChangeController, String?>(EmailChangeController.new);
