import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class QRScanResult {
  final bool success;
  final String message;
  final bool alreadyCheckedIn;
  final String accessType; // 'gate' | 'desk' | 'lift' | 'room'
  final String? guestName;
  final String? roomNumber;
  final int? floorNumber;
  final String? estateName;
  final String? bookingRef;
  final String? checkIn;
  final String? checkOut;
  final String? memberTier;
  final List<String> addOns;
  final String? vehicleNumber;

  const QRScanResult({
    required this.success,
    required this.message,
    this.alreadyCheckedIn = false,
    required this.accessType,
    this.guestName,
    this.roomNumber,
    this.floorNumber,
    this.estateName,
    this.bookingRef,
    this.checkIn,
    this.checkOut,
    this.memberTier,
    this.addOns = const [],
    this.vehicleNumber,
  });

  factory QRScanResult.fromJson(Map<String, dynamic> j) {
    final booking = j['booking'] is Map ? Map<String, dynamic>.from(j['booking']) : <String, dynamic>{};
    final guest = j['guest'] is Map ? Map<String, dynamic>.from(j['guest']) : <String, dynamic>{};
    final estate = j['estate'] is Map ? Map<String, dynamic>.from(j['estate']) : <String, dynamic>{};

    return QRScanResult(
      success: (j['success'] == true) || (j['allowed'] == true),
      message: (j['message'] ?? j['error'] ?? '').toString(),
      alreadyCheckedIn: j['alreadyCheckedIn'] == true,
      accessType: (j['accessType'] ?? 'gate').toString(),
      guestName: (j['guestName'] ?? guest['name'] ?? guest['phoneNumber'])?.toString(),
      roomNumber: (j['roomNumber'] ?? booking['roomNumber'])?.toString(),
      floorNumber: j['floorNumber'] is int
          ? j['floorNumber'] as int
          : booking['floorNumber'] is int
              ? booking['floorNumber'] as int
              : null,
      estateName: (j['estateName'] ?? estate['title'])?.toString(),
      bookingRef: (j['bookingRef'] ?? booking['_id'])?.toString(),
      checkIn: (j['checkIn'] ?? booking['checkInDate'])?.toString(),
      checkOut: (j['checkOut'] ?? booking['checkOutDate'])?.toString(),
      memberTier: (j['memberTier'] ?? guest['memberTier'])?.toString(),
      addOns: List<String>.from((j['addOns'] ?? booking['addOns'] ?? const []) as List),
      vehicleNumber: (j['vehicleNumber'] ?? booking['vehicleNumber'])?.toString(),
    );
  }
}

class TodayBooking {
  final String id;
  final String guestName;
  final String guestPhone;
  final String roomNumber;
  final int floorNumber;
  final String checkIn;
  final String checkOut;
  final String memberTier;
  final String status;
  final bool driveInApproved;
  final String? vehicleNumber;
  final List<String> addOns;

  const TodayBooking({
    required this.id,
    required this.guestName,
    required this.guestPhone,
    required this.roomNumber,
    required this.floorNumber,
    required this.checkIn,
    required this.checkOut,
    required this.memberTier,
    required this.status,
    required this.driveInApproved,
    this.vehicleNumber,
    required this.addOns,
  });

  factory TodayBooking.fromJson(Map<String, dynamic> j) => TodayBooking(
        id: j['_id'] ?? '',
        guestName: j['guestName'] ?? j['user']?['name'] ?? 'Guest',
        guestPhone: j['guestPhone'] ?? j['user']?['phoneNumber'] ?? '',
        roomNumber: j['roomNumber'] ?? '--',
        floorNumber: j['floorNumber'] ?? 1,
        checkIn: j['checkIn'] ?? '',
        checkOut: j['checkOut'] ?? '',
        memberTier: j['memberTier'] ?? j['user']?['memberTier'] ?? 'Bronze',
        status: j['status'] ?? 'Confirmed',
        driveInApproved: j['driveInApproved'] ?? false,
        vehicleNumber: j['vehicleNumber'],
        addOns: List<String>.from(j['addOns'] ?? []),
      );
}

// ── State ─────────────────────────────────────────────────────────────────────

class AccessState {
  final QRScanResult? lastScanResult;
  final bool scanning;
  final bool loading;
  final String? error;
  final List<TodayBooking> todayArrivals;
  final List<TodayBooking> activeGuests;

  const AccessState({
    this.lastScanResult,
    this.scanning = false,
    this.loading = false,
    this.error,
    this.todayArrivals = const [],
    this.activeGuests = const [],
  });

  AccessState copyWith({
    QRScanResult? lastScanResult,
    bool? scanning,
    bool? loading,
    String? error,
    List<TodayBooking>? todayArrivals,
    List<TodayBooking>? activeGuests,
  }) =>
      AccessState(
        lastScanResult: lastScanResult ?? this.lastScanResult,
        scanning: scanning ?? this.scanning,
        loading: loading ?? this.loading,
        error: error,
        todayArrivals: todayArrivals ?? this.todayArrivals,
        activeGuests: activeGuests ?? this.activeGuests,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AccessNotifier extends Notifier<AccessState> {
  @override
  AccessState build() => const AccessState();

  Future<QRScanResult?> verifyQR(String qrToken, String accessType) async {
    state = state.copyWith(scanning: true, error: null);
    try {
      final data = await apiClient.post('/access/verify-qr', {
        'qrToken': qrToken,
        'accessType': accessType,
      });
      final result = QRScanResult.fromJson({...data, 'accessType': accessType});
      state = state.copyWith(scanning: false, lastScanResult: result);
      return result;
    } catch (e) {
      final fail = QRScanResult(
        success: false,
        message: e.toString().replaceAll('Exception: ', ''),
        accessType: accessType,
      );
      state = state.copyWith(scanning: false, lastScanResult: fail, error: e.toString());
      return fail;
    }
  }

  Future<bool> approveDriveIn(String bookingId, String vehicleNumber) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await apiClient.post('/access/drive-in/$bookingId', {'vehicleNumber': vehicleNumber});
      state = state.copyWith(loading: false);
      await fetchTodayArrivals();
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<void> fetchTodayArrivals() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final data = await apiClient.get('/bookings/estate/today');
      final arrivals = (data as List? ?? []).map((b) => TodayBooking.fromJson(b)).toList();
      state = state.copyWith(todayArrivals: arrivals, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> fetchActiveGuests() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final data = await apiClient.get('/bookings/estate/active');
      final guests = (data as List? ?? []).map((b) => TodayBooking.fromJson(b)).toList();
      state = state.copyWith(activeGuests: guests, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void clearScanResult() => state = state.copyWith(lastScanResult: null);
}

final accessProvider = NotifierProvider<AccessNotifier, AccessState>(AccessNotifier.new);
