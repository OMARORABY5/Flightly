import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/core/providers/storage_provider.dart';

class OnboardingNotifier extends StateNotifier<bool> {
  final Ref _ref;

  OnboardingNotifier(this._ref) : super(false) {
    _init();
  }

  void _init() {
    state = _ref.read(storageServiceProvider).isOnboardingCompleted;
  }

  Future<void> completeOnboarding() async {
    await _ref.read(storageServiceProvider).setOnboardingCompleted(true);
    state = true;
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier(ref);
});
