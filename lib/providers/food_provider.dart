import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class FoodItem {
  final String id;
  final String name;
  final String desc;
  final double price;
  final bool isVeg;
  final bool isSignature;
  final int prepTime;
  final List<String> allergens;
  final String image;

  FoodItem({
    required this.id,
    required this.name,
    required this.desc,
    required this.price,
    required this.isVeg,
    required this.isSignature,
    required this.prepTime,
    required this.allergens,
    required this.image,
  });

  factory FoodItem.fromJson(Map<String, dynamic> j) => FoodItem(
        id: j['_id'] ?? j['name'] ?? '',
        name: j['name'] ?? '',
        desc: j['desc'] ?? '',
        price: (j['price'] ?? 0).toDouble(),
        isVeg: j['isVeg'] ?? true,
        isSignature: j['isSignature'] ?? false,
        prepTime: j['prepTime'] ?? 20,
        allergens: List<String>.from(j['allergens'] ?? []),
        image: j['image'] ?? '',
      );
}

class FoodCategory {
  final String name;
  final String icon;
  final List<FoodItem> items;

  FoodCategory({required this.name, required this.icon, required this.items});

  factory FoodCategory.fromJson(Map<String, dynamic> j) => FoodCategory(
        name: j['name'] ?? '',
        icon: j['icon'] ?? '🍽️',
        items: (j['items'] as List? ?? []).map((i) => FoodItem.fromJson(i)).toList(),
      );
}

class FoodOrder {
  final String id;
  final String status;
  final String deliveryType;
  final List<FoodOrderItem> items;
  final double total;
  final DateTime placedAt;
  final int estimatedMinutes;

  FoodOrder({
    required this.id,
    required this.status,
    required this.deliveryType,
    required this.items,
    required this.total,
    required this.placedAt,
    required this.estimatedMinutes,
  });

  factory FoodOrder.fromJson(Map<String, dynamic> j) => FoodOrder(
        id: j['_id'] ?? '',
        status: j['status'] ?? 'Placed',
        deliveryType: j['deliveryType'] ?? 'Room Service',
        items: (j['items'] as List? ?? []).map((i) => FoodOrderItem.fromJson(i)).toList(),
        total: (j['total'] ?? 0).toDouble(),
        placedAt: j['createdAt'] != null ? DateTime.parse(j['createdAt']) : DateTime.now(),
        estimatedMinutes: j['estimatedMinutes'] ?? 35,
      );
}

class FoodOrderItem {
  final String name;
  final int quantity;
  final double price;

  FoodOrderItem({required this.name, required this.quantity, required this.price});

  factory FoodOrderItem.fromJson(Map<String, dynamic> j) => FoodOrderItem(
        name: j['name'] ?? '',
        quantity: j['quantity'] ?? 1,
        price: (j['price'] ?? 0).toDouble(),
      );
}

class CartItem {
  final FoodItem item;
  int quantity;

  CartItem({required this.item, this.quantity = 1});
}

// ── State ─────────────────────────────────────────────────────────────────────

class FoodState {
  final List<FoodCategory> categories;
  final Map<String, CartItem> cart; // itemId → CartItem
  final List<FoodOrder> myOrders;
  final bool loading;
  final String? error;
  final String deliveryType;

  const FoodState({
    this.categories = const [],
    this.cart = const {},
    this.myOrders = const [],
    this.loading = false,
    this.error,
    this.deliveryType = 'Room Service',
  });

  FoodState copyWith({
    List<FoodCategory>? categories,
    Map<String, CartItem>? cart,
    List<FoodOrder>? myOrders,
    bool? loading,
    String? error,
    String? deliveryType,
  }) =>
      FoodState(
        categories: categories ?? this.categories,
        cart: cart ?? this.cart,
        myOrders: myOrders ?? this.myOrders,
        loading: loading ?? this.loading,
        error: error,
        deliveryType: deliveryType ?? this.deliveryType,
      );

  int get cartCount => cart.values.fold(0, (s, c) => s + c.quantity);
  double get cartTotal => cart.values.fold(0.0, (s, c) => s + c.item.price * c.quantity);
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class FoodNotifier extends Notifier<FoodState> {
  @override
  FoodState build() => const FoodState();

  Future<void> fetchMenu(String estateId) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final data = await apiClient.get('/estates/$estateId/menu');
      final cats = (data['categories'] as List? ?? [])
          .map((c) => FoodCategory.fromJson(c))
          .toList();
      state = state.copyWith(categories: cats, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void addToCart(FoodItem item) {
    final cart = Map<String, CartItem>.from(state.cart);
    if (cart.containsKey(item.id)) {
      cart[item.id]!.quantity++;
    } else {
      cart[item.id] = CartItem(item: item);
    }
    state = state.copyWith(cart: cart);
  }

  void removeFromCart(String itemId) {
    final cart = Map<String, CartItem>.from(state.cart);
    if (cart.containsKey(itemId)) {
      if (cart[itemId]!.quantity > 1) {
        cart[itemId]!.quantity--;
      } else {
        cart.remove(itemId);
      }
    }
    state = state.copyWith(cart: cart);
  }

  void clearCart() => state = state.copyWith(cart: {});

  void setDeliveryType(String type) => state = state.copyWith(deliveryType: type);

  Future<FoodOrder?> placeOrder(String bookingId) async {
    if (state.cart.isEmpty) return null;
    state = state.copyWith(loading: true, error: null);
    try {
      final items = state.cart.values
          .map((c) => {'name': c.item.name, 'price': c.item.price, 'quantity': c.quantity})
          .toList();
      final data = await apiClient.post('/food/order', {
        'bookingId': bookingId,
        'items': items,
        'deliveryType': state.deliveryType,
      });
      final order = FoodOrder.fromJson(data['order']);
      state = state.copyWith(loading: false, cart: {}, myOrders: [order, ...state.myOrders]);
      return order;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return null;
    }
  }

  Future<void> fetchMyOrders() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final data = await apiClient.get('/food/orders/me');
      final orders = (data as List? ?? []).map((o) => FoodOrder.fromJson(o)).toList();
      state = state.copyWith(myOrders: orders, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final foodProvider = NotifierProvider<FoodNotifier, FoodState>(FoodNotifier.new);
