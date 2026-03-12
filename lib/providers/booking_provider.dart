import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import 'auth_provider.dart';

class BookingState {
  final bool isLoading;
  final List<dynamic> bookings;
  final String? error;
  final Map<String, dynamic>? lastBooking; // most recent booking with QR data

  BookingState({
    this.isLoading = false,
    this.bookings = const [],
    this.error,
    this.lastBooking,
  });

  BookingState copyWith({
    bool? isLoading,
    List<dynamic>? bookings,
    String? error,
    Map<String, dynamic>? lastBooking,
  }) {
    return BookingState(
      isLoading: isLoading ?? this.isLoading,
      bookings: bookings ?? this.bookings,
      error: error,
      lastBooking: lastBooking ?? this.lastBooking,
    );
  }
}

class BookingNotifier extends Notifier<BookingState> {
  @override
  BookingState build() {
    // Watch auth — auto-refresh bookings when user logs in, clear when they log out
    final isAuthenticated = ref.watch(
      authProvider.select((s) => s.isAuthenticated),
    );
    if (!isAuthenticated) return BookingState();
    Future.microtask(() => fetchMyBookings());
    return BookingState(isLoading: true);
  }

  Future<void> fetchMyBookings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.get('/bookings/me');
      state = state.copyWith(isLoading: false, bookings: response);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Map<String, dynamic>?> createBooking(Map<String, dynamic> bookingData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.post('/bookings', bookingData);
      final booking = response['booking'] ?? response;
      state = state.copyWith(isLoading: false, lastBooking: booking);
      fetchMyBookings();
      return booking;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Cancel a booking — backend charges 20% cancellation fee.
  /// Returns a map with {cancellationFee, refundAmount} on success, null on failure.
  Future<Map<String, dynamic>?> cancelBooking(String bookingId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.put('/bookings/$bookingId/cancel', {});
      // Update the local booking list to reflect cancelled status
      final updated = state.bookings.map((b) {
        if ((b['_id'] ?? '') == bookingId) {
          return {...(b as Map<String, dynamic>), 'status': 'Cancelled'};
        }
        return b;
      }).toList();
      state = state.copyWith(isLoading: false, bookings: updated);
      return {
        'cancellationFee': response['cancellationFee'],
        'refundAmount': response['refundAmount'],
      };
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final bookingProvider = NotifierProvider<BookingNotifier, BookingState>(BookingNotifier.new);
