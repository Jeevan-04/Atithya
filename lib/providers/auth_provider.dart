import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';

/// Which step of the auth flow the user is on
enum AuthStep { idle, otp, name, authenticated }

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final Map<String, dynamic>? user;
  final String? error;

  // OTP flow state
  final AuthStep step;
  final String? pendingPhone;
  final String? debugOtp; // returned by backend in dev mode
  final bool isNewUser;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
    this.step = AuthStep.idle,
    this.pendingPhone,
    this.debugOtp,
    this.isNewUser = false,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    Map<String, dynamic>? user,
    String? error,
    AuthStep? step,
    String? pendingPhone,
    String? debugOtp,
    bool? isNewUser,
    bool clearError = false,
    bool clearDebugOtp = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: clearError ? null : (error ?? this.error),
      step: step ?? this.step,
      pendingPhone: pendingPhone ?? this.pendingPhone,
      debugOtp: clearDebugOtp ? null : (debugOtp ?? this.debugOtp),
      isNewUser: isNewUser ?? this.isNewUser,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkInitialAuth();
    return const AuthState();
  }

  // ── Session check on startup ────────────────────────────────────────────

  Future<void> _checkInitialAuth() async {
    await Future.microtask(() async {
      state = state.copyWith(isLoading: true);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null) {
        try {
          final user = await apiClient.get('/auth/me') as Map<String, dynamic>;
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            step: AuthStep.authenticated,
            user: user,
          );
        } catch (_) {
          await prefs.remove('auth_token');
          state = state.copyWith(isLoading: false, isAuthenticated: false);
        }
      } else {
        state = state.copyWith(isLoading: false);
      }
    });
  }

  // ── OTP Flow ────────────────────────────────────────────────────────────

  /// Step 1: request OTP for phone number
  Future<void> sendOTP(String phoneNumber) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response =
          await apiClient.post('/auth/send-otp', {'phoneNumber': phoneNumber})
              as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        step: AuthStep.otp,
        pendingPhone: phoneNumber,
        debugOtp: response['debug_otp'] as String?,
        isNewUser: response['isNewUser'] == true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Step 2: submit OTP — if new user → name step, else → authenticated
  Future<void> verifyOTP(String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await apiClient.post('/auth/verify-otp', {
        'phoneNumber': state.pendingPhone,
        'otp': otp,
      }) as Map<String, dynamic>;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', response['token'] as String);

      final isNew = response['isNewUser'] == true;
      if (isNew) {
        state = state.copyWith(
          isLoading: false,
          step: AuthStep.name,
          user: response['user'] as Map<String, dynamic>?,
          isNewUser: true,
          clearDebugOtp: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          step: AuthStep.authenticated,
          user: response['user'] as Map<String, dynamic>?,
          isNewUser: false,
          clearDebugOtp: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Step 3 (new users only): submit name to complete profile
  Future<void> completeName(String name) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response =
          await apiClient.put('/auth/profile', {'name': name})
              as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        step: AuthStep.authenticated,
        user: response['user'] as Map<String, dynamic>?,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // ── Profile ─────────────────────────────────────────────────────────────

  Future<void> updateProfile({String? name, String? email, String? foodPreference}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (foodPreference != null) body['foodPreference'] = foodPreference;
      final response =
          await apiClient.put('/auth/profile', body) as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        user: response['user'] as Map<String, dynamic>?,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> updatePreferences({
    String? language,
    String? currency,
    Map<String, dynamic>? notificationPrefs,
    Map<String, dynamic>? privacySettings,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final body = <String, dynamic>{};
      if (language != null) body['language'] = language;
      if (currency != null) body['currency'] = currency;
      if (notificationPrefs != null) body['notificationPrefs'] = notificationPrefs;
      if (privacySettings != null) body['privacySettings'] = privacySettings;
      final response =
          await apiClient.put('/auth/profile', body) as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        user: response['user'] as Map<String, dynamic>?,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // ── Staff / Guest ───────────────────────────────────────────────────────

  Future<void> staffLogin(String phoneNumber, String pin) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await apiClient.post('/auth/staff-login', {
        'phoneNumber': phoneNumber,
        'pin': pin,
      }) as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', response['token'] as String);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        step: AuthStep.authenticated,
        user: response['user'] as Map<String, dynamic>?,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loginAsGuest() async {
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      step: AuthStep.authenticated,
      user: {'phoneNumber': 'Guest', 'role': 'guest', 'name': 'Royal Guest'},
    );
  }

  Future<void> logout() async {
    try {
      // Notify backend so it logs the event and pushes a notification
      await apiClient.post('/auth/logout', {});
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(clearError: true);

  /// Go back one step in OTP flow
  void goBack() {
    if (state.step == AuthStep.otp || state.step == AuthStep.name) {
      state = state.copyWith(step: AuthStep.idle, clearError: true);
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

