import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Trip Routes Provider — predefined journey circuits from backend
// ─────────────────────────────────────────────────────────────────────────────

class TripRoutesState {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> routes;

  const TripRoutesState({
    this.isLoading = true,
    this.error,
    this.routes = const [],
  });

  TripRoutesState copyWith({
    bool? isLoading,
    String? error,
    List<Map<String, dynamic>>? routes,
  }) =>
      TripRoutesState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        routes: routes ?? this.routes,
      );
}

class TripRoutesNotifier extends Notifier<TripRoutesState> {
  @override
  TripRoutesState build() {
    Future.microtask(() => fetchRoutes());
    return const TripRoutesState();
  }

  Future<void> fetchRoutes() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await apiClient.get('/trips/routes') as List;
      final routes = data
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
      state = state.copyWith(isLoading: false, routes: routes);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final tripRoutesProvider =
    NotifierProvider<TripRoutesNotifier, TripRoutesState>(
  TripRoutesNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// User Saved Journeys (CRUD)
// ─────────────────────────────────────────────────────────────────────────────

class UserTripsState {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> trips;

  const UserTripsState({
    this.isLoading = false,
    this.error,
    this.trips = const [],
  });

  UserTripsState copyWith({
    bool? isLoading,
    String? error,
    List<Map<String, dynamic>>? trips,
  }) =>
      UserTripsState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        trips: trips ?? this.trips,
      );
}

class UserTripsNotifier extends Notifier<UserTripsState> {
  @override
  UserTripsState build() => const UserTripsState();

  Future<void> fetchMyTrips() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await apiClient.get('/trips/my') as List;
      state = state.copyWith(
        isLoading: false,
        trips: data.map((t) => Map<String, dynamic>.from(t as Map)).toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Save a new trip and return it (or null on failure).
  Future<Map<String, dynamic>?> saveTrip({
    required String name,
    required List<Map<String, dynamic>> stops,
    String type = 'custom',
    String? routeKey,
  }) async {
    try {
      final result = await apiClient.post('/trips', {
        'name': name,
        'stops': stops,
        'type': type,
        if (routeKey != null) 'routeKey': routeKey,
      }) as Map<String, dynamic>;
      // prepend to local list
      state = state.copyWith(trips: [result, ...state.trips]);
      return result;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteTrip(String tripId) async {
    try {
      await apiClient.delete('/trips/$tripId');
      state = state.copyWith(
        trips: state.trips.where((t) => t['_id'] != tripId).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Link an estate to a specific stop on a saved trip.
  Future<void> linkEstateToStop(String tripId, int stopIdx, String estateId) async {
    try {
      final updated = await apiClient.put(
        '/trips/$tripId/stop/$stopIdx',
        {'estateId': estateId},
      ) as Map<String, dynamic>;
      state = state.copyWith(
        trips: state.trips
            .map((t) => t['_id'] == tripId ? updated : t)
            .toList(),
      );
    } catch (_) {}
  }
}

final userTripsProvider =
    NotifierProvider<UserTripsNotifier, UserTripsState>(UserTripsNotifier.new);
