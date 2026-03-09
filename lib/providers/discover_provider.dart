import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Discover Feed — dynamic home-screen content from MongoDB
// ─────────────────────────────────────────────────────────────────────────────

class DiscoverFeedState {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> experiences;
  final List<Map<String, dynamic>> cities;
  final List<Map<String, dynamic>> suiteHighlights;

  const DiscoverFeedState({
    this.isLoading = true,
    this.error,
    this.experiences = const [],
    this.cities = const [],
    this.suiteHighlights = const [],
  });

  DiscoverFeedState copyWith({
    bool? isLoading,
    String? error,
    List<Map<String, dynamic>>? experiences,
    List<Map<String, dynamic>>? cities,
    List<Map<String, dynamic>>? suiteHighlights,
  }) =>
      DiscoverFeedState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        experiences: experiences ?? this.experiences,
        cities: cities ?? this.cities,
        suiteHighlights: suiteHighlights ?? this.suiteHighlights,
      );
}

class DiscoverFeedNotifier extends Notifier<DiscoverFeedState> {
  @override
  DiscoverFeedState build() {
    Future.microtask(() => fetchFeed());
    return const DiscoverFeedState();
  }

  Future<void> fetchFeed() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await apiClient.get('/discover/feed') as Map<String, dynamic>;

      final rawExperiences = (data['experiences'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final rawCities = (data['cities'] as List? ?? [])
          .map((c) => Map<String, dynamic>.from(c as Map))
          .toList();

      final rawSuites = (data['suiteHighlights'] as List? ?? [])
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList();

      state = state.copyWith(
        isLoading: false,
        experiences: rawExperiences,
        cities: rawCities,
        suiteHighlights: rawSuites,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final discoverFeedProvider =
    NotifierProvider<DiscoverFeedNotifier, DiscoverFeedState>(
  DiscoverFeedNotifier.new,
);
