import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_state.dart';

class SavedServicesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() {
    return AppState.likedServiceIds;
  }

  Future<void> toggle(int serviceId) async {
    await AppState.toggleLikeService(serviceId);
    state = {...AppState.likedServiceIds};
  }

  Future<void> sync() async {
    await AppState.syncSavedServices();
    state = {...AppState.likedServiceIds};
  }
  
  void refreshFromStatic() {
    state = {...AppState.likedServiceIds};
  }
}

final savedServicesProvider =
    NotifierProvider<SavedServicesNotifier, Set<int>>(SavedServicesNotifier.new);
