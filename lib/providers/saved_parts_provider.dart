import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_state.dart';

class SavedPartsNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() {
    return AppState.likedPartIds;
  }

  Future<void> toggle(int partId) async {
    await AppState.toggleLikePart(partId);
    state = {...AppState.likedPartIds};
  }

  Future<void> sync() async {
    await AppState.syncSavedParts();
    state = {...AppState.likedPartIds};
  }
  
  void refreshFromStatic() {
    state = {...AppState.likedPartIds};
  }
}

final savedPartsProvider =
    NotifierProvider<SavedPartsNotifier, Set<int>>(SavedPartsNotifier.new);
