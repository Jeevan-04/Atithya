import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import 'auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool read;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> j) => NotificationItem(
        id: j['_id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        type: j['type'] as String? ?? 'system',
        read: j['read'] as bool? ?? false,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  NotificationItem copyWith({bool? read}) => NotificationItem(
        id: id,
        title: title,
        body: body,
        type: type,
        read: read ?? this.read,
        createdAt: createdAt,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsState {
  final bool isLoading;
  final List<NotificationItem> items;
  final int unreadCount;
  final String? error;

  const NotificationsState({
    this.isLoading = false,
    this.items = const [],
    this.unreadCount = 0,
    this.error,
  });

  NotificationsState copyWith({
    bool? isLoading,
    List<NotificationItem>? items,
    int? unreadCount,
    String? error,
    bool clearError = false,
  }) =>
      NotificationsState(
        isLoading: isLoading ?? this.isLoading,
        items: items ?? this.items,
        unreadCount: unreadCount ?? this.unreadCount,
        error: clearError ? null : (error ?? this.error),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsNotifier extends Notifier<NotificationsState> {
  @override
  NotificationsState build() {
    final isAuthenticated = ref.watch(
      authProvider.select((s) => s.isAuthenticated),
    );
    // Only fetch for authenticated (non-guest) users.
    // When the user logs out, Riverpod rebuilds this and returns empty state.
    if (!isAuthenticated) {
      return const NotificationsState();
    }
    Future.microtask(() => fetchNotifications());
    return const NotificationsState(isLoading: true);
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await apiClient.get('/notifications') as Map<String, dynamic>;
      final raw = (data['notifications'] as List? ?? [])
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        isLoading: false,
        items: raw,
        unreadCount: data['unreadCount'] as int? ?? 0,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAllRead() async {
    try {
      await apiClient.patch('/notifications/read-all', {});
      state = state.copyWith(
        items: state.items.map((n) => n.copyWith(read: true)).toList(),
        unreadCount: 0,
      );
    } catch (_) {}
  }

  Future<void> markRead(String id) async {
    try {
      await apiClient.patch('/notifications/$id/read', {});
      state = state.copyWith(
        items: state.items
            .map((n) => n.id == id ? n.copyWith(read: true) : n)
            .toList(),
        unreadCount: (state.unreadCount - 1).clamp(0, 999),
      );
    } catch (_) {}
  }

  Future<void> clearAll() async {
    try {
      await apiClient.delete('/notifications');
      state = state.copyWith(items: [], unreadCount: 0);
    } catch (_) {}
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(
  NotificationsNotifier.new,
);
