import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';

class EstateState {
  final bool isLoading;
  final List<dynamic> estates;
  final String? error;

  EstateState({
    this.isLoading = false,
    this.estates = const [],
    this.error,
  });

  EstateState copyWith({
    bool? isLoading,
    List<dynamic>? estates,
    String? error,
  }) {
    return EstateState(
      isLoading: isLoading ?? this.isLoading,
      estates: estates ?? this.estates,
      error: error,
    );
  }
}

class EstateNotifier extends Notifier<EstateState> {
  @override
  EstateState build() {
    Future.microtask(() => fetchEstates());
    return EstateState(isLoading: true);
  }

  Future<void> fetchEstates({
    String? location,
    String? city,
    String? category,
    int? maxPrice,
    int? minPrice,
    String? sort,
    String? facilities,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = <String, String>{};
      if (location != null && location.isNotEmpty) params['location'] = location;
      if (city != null && city.isNotEmpty) params['city'] = city;
      if (category != null && category.isNotEmpty) params['category'] = category;
      if (maxPrice != null) params['maxPrice'] = maxPrice.toString();
      if (minPrice != null && minPrice > 0) params['minPrice'] = minPrice.toString();
      if (sort != null && sort.isNotEmpty) params['sort'] = sort;
      if (facilities != null && facilities.isNotEmpty) params['facilities'] = facilities;

      final query = params.isNotEmpty
          ? '?' + params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')
          : '';

      final response = await apiClient.get('/estates$query');
      state = state.copyWith(isLoading: false, estates: response is List ? response : []);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final estateProvider = NotifierProvider<EstateNotifier, EstateState>(EstateNotifier.new);
