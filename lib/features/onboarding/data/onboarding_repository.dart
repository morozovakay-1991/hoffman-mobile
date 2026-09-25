import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers that onboarding was shown, so it appears only once.
class OnboardingRepository {
  OnboardingRepository({Future<SharedPreferences>? prefs})
    : _prefs = prefs ?? SharedPreferences.getInstance();

  static const String seenKey = 'onboarding_seen';

  final Future<SharedPreferences> _prefs;

  Future<bool> isSeen() async => (await _prefs).getBool(seenKey) ?? false;

  Future<void> markSeen() async {
    await (await _prefs).setBool(seenKey, true);
  }
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(),
);

final onboardingSeenProvider = FutureProvider<bool>(
  (ref) => ref.watch(onboardingRepositoryProvider).isSeen(),
);
