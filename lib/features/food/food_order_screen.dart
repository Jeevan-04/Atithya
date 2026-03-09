import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/colors.dart';
import '../../../core/typography.dart';
import '../../../providers/food_provider.dart';

class FoodOrderScreen extends ConsumerStatefulWidget {
  final String estateId;
  final String bookingId;
  final String estateName;

  const FoodOrderScreen({
    super.key,
    required this.estateId,
    required this.bookingId,
    required this.estateName,
  });

  @override
  ConsumerState<FoodOrderScreen> createState() => _FoodOrderScreenState();
}

class _FoodOrderScreenState extends ConsumerState<FoodOrderScreen> {
  int _selectedCategory = 0;

  static const _deliveryTypes = [
    ('Room Service', Icons.room_service_outlined),
    ('Restaurant', Icons.restaurant_outlined),
    ('Pool Side', Icons.pool_outlined),
    ('Garden Dining', Icons.park_outlined),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(foodProvider.notifier).fetchMenu(widget.estateId));
  }

  Future<void> _placeOrder() async {
    final order = await ref.read(foodProvider.notifier).placeOrder(widget.bookingId);
    if (!mounted) return;
    if (order != null) {
      _showOrderConfirmation(order);
    } else {
      final err = ref.read(foodProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err ?? 'Order failed', style: AtithyaTypography.bodyText.copyWith(fontSize: 13)),
        backgroundColor: AtithyaColors.errorRed,
      ));
    }
  }

  void _showOrderConfirmation(FoodOrder order) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AtithyaColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AtithyaColors.success.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AtithyaColors.success, width: 2),
              ),
              child: const Icon(Icons.check_rounded, color: AtithyaColors.success, size: 36),
            ).animate().scale(duration: 400.ms),
            const SizedBox(height: 20),
            Text('Order Placed!', style: AtithyaTypography.heroTitle.copyWith(
              color: AtithyaColors.shimmerGold, fontSize: 22,
            )),
            const SizedBox(height: 8),
            Text('Your order will be delivered in ~${order.estimatedMinutes} minutes.',
              style: AtithyaTypography.bodyText.copyWith(color: AtithyaColors.parchment, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(order.deliveryType, style: TextStyle(
              color: AtithyaColors.imperialGold, fontSize: 12, letterSpacing: 1,
            )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AtithyaColors.imperialGold,
                  foregroundColor: AtithyaColors.obsidian,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final food = ref.watch(foodProvider);
    final cats = food.categories;

    return Scaffold(
      backgroundColor: AtithyaColors.obsidian,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AtithyaColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AtithyaColors.imperialGold.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: AtithyaColors.pearl, size: 16),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Room Service', style: AtithyaTypography.heroTitle.copyWith(
                      color: AtithyaColors.shimmerGold, fontSize: 20,
                    )),
                    Text(widget.estateName, style: AtithyaTypography.bodyText.copyWith(
                      color: AtithyaColors.parchment, fontSize: 12,
                    )),
                  ]),
                ),
                // Cart count
                if (food.cartCount > 0)
                  GestureDetector(
                    onTap: _showCartSheet,
                    child: Stack(clipBehavior: Clip.none, children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: AtithyaColors.imperialGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AtithyaColors.imperialGold),
                        ),
                        child: const Icon(Icons.shopping_bag_outlined, color: AtithyaColors.imperialGold, size: 20),
                      ),
                      Positioned(
                        top: -4, right: -4,
                        child: Container(
                          width: 20, height: 20,
                          decoration: const BoxDecoration(
                            color: AtithyaColors.imperialGold, shape: BoxShape.circle,
                          ),
                          child: Center(child: Text(food.cartCount.toString(),
                            style: const TextStyle(color: AtithyaColors.obsidian, fontSize: 10, fontWeight: FontWeight.w700),
                          )),
                        ),
                      ),
                    ]),
                  ),
              ]),
            ),

            const SizedBox(height: 16),

            // ── Delivery Type ─────────────────────────────────────────────
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _deliveryTypes.length,
                itemBuilder: (_, i) {
                  final (label, icon) = _deliveryTypes[i];
                  final selected = food.deliveryType == label;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => ref.read(foodProvider.notifier).setDeliveryType(label),
                      child: AnimatedContainer(
                        duration: 200.ms,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AtithyaColors.imperialGold.withOpacity(0.15) : AtithyaColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: selected ? AtithyaColors.imperialGold : AtithyaColors.imperialGold.withOpacity(0.15),
                          ),
                        ),
                        child: Row(children: [
                          Icon(icon, color: selected ? AtithyaColors.imperialGold : AtithyaColors.parchment, size: 14),
                          const SizedBox(width: 6),
                          Text(label, style: TextStyle(
                            color: selected ? AtithyaColors.imperialGold : AtithyaColors.parchment,
                            fontSize: 12,
                          )),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ── Category Tabs ─────────────────────────────────────────────
            if (cats.isNotEmpty) ...[
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: cats.length,
                  itemBuilder: (_, i) {
                    final selected = _selectedCategory == i;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = i),
                        child: AnimatedContainer(
                          duration: 200.ms,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? AtithyaColors.imperialGold : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: selected ? AtithyaColors.imperialGold : AtithyaColors.imperialGold.withOpacity(0.2),
                            ),
                          ),
                          child: Text('${cats[i].icon} ${cats[i].name}',
                            style: TextStyle(
                              color: selected ? AtithyaColors.obsidian : AtithyaColors.parchment,
                              fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            )),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Items List ────────────────────────────────────────────────
            Expanded(
              child: food.loading
                  ? const Center(child: CircularProgressIndicator(color: AtithyaColors.imperialGold))
                  : cats.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          physics: const BouncingScrollPhysics(),
                          itemCount: cats[_selectedCategory].items.length,
                          itemBuilder: (_, i) {
                            final item = cats[_selectedCategory].items[i];
                            final cartItem = food.cart[item.id];
                            return _FoodCard(
                              item: item,
                              quantity: cartItem?.quantity ?? 0,
                              onAdd: () => ref.read(foodProvider.notifier).addToCart(item),
                              onRemove: () => ref.read(foodProvider.notifier).removeFromCart(item.id),
                            );
                          },
                        ),
            ),

            // ── Place Order Button ────────────────────────────────────────
            if (food.cartCount > 0)
              _OrderBar(
                count: food.cartCount,
                total: food.cartTotal,
                loading: food.loading,
                onTap: _placeOrder,
              ),
          ],
        ),
      ),
    );
  }

  void _showCartSheet() {
    final food = ref.read(foodProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AtithyaColors.darkSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AtithyaColors.imperialGold.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Order', style: AtithyaTypography.heroTitle.copyWith(
              color: AtithyaColors.shimmerGold, fontSize: 20,
            )),
            const SizedBox(height: 16),
            ...food.cart.values.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Expanded(child: Text(c.item.name, style: AtithyaTypography.bodyText.copyWith(color: AtithyaColors.pearl))),
                Text('×${c.quantity}', style: TextStyle(color: AtithyaColors.parchment)),
                const SizedBox(width: 12),
                Text('₹${(c.item.price * c.quantity).toStringAsFixed(0)}',
                  style: TextStyle(color: AtithyaColors.imperialGold)),
              ]),
            )),
            const Divider(color: Color(0x33D4AF6A)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Total', style: AtithyaTypography.cardTitle.copyWith(color: AtithyaColors.pearl)),
              Text('₹${food.cartTotal.toStringAsFixed(0)}',
                style: AtithyaTypography.heroTitle.copyWith(color: AtithyaColors.shimmerGold, fontSize: 18)),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.restaurant_menu, color: AtithyaColors.imperialGold, size: 48),
      const SizedBox(height: 16),
      Text('Menu not available', style: AtithyaTypography.bodyText.copyWith(color: AtithyaColors.parchment)),
    ]),
  );
}

// ── Food Item Card ─────────────────────────────────────────────────────────────

class _FoodCard extends StatelessWidget {
  final FoodItem item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _FoodCard({
    required this.item,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AtithyaColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AtithyaColors.imperialGold.withOpacity(0.12)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Image
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16), bottomLeft: Radius.circular(16),
          ),
          child: CachedNetworkImage(
            imageUrl: item.image,
            width: 100, height: 100, fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AtithyaColors.surfaceElevated,
              child: const Icon(Icons.restaurant, color: AtithyaColors.imperialGold, size: 30)),
            errorWidget: (_, __, ___) => Container(color: AtithyaColors.surfaceElevated,
              child: const Icon(Icons.restaurant, color: AtithyaColors.imperialGold, size: 30)),
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                // Veg/Non-veg dot
                Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    border: Border.all(color: item.isVeg ? Colors.green : Colors.red, width: 1.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Center(
                    child: Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: item.isVeg ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(item.name, style: AtithyaTypography.cardTitle.copyWith(
                  color: AtithyaColors.pearl, fontSize: 13,
                ))),
                if (item.isSignature)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AtithyaColors.imperialGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('✦ Signature', style: TextStyle(
                      color: AtithyaColors.imperialGold, fontSize: 9, letterSpacing: 0.5,
                    )),
                  ),
              ]),
              const SizedBox(height: 4),
              Text(item.desc, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AtithyaColors.parchment.withOpacity(0.7), fontSize: 11)),
              const SizedBox(height: 2),
              Text('⏱ ${item.prepTime} min', style: TextStyle(
                color: AtithyaColors.parchment.withOpacity(0.5), fontSize: 10)),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('₹${item.price.toStringAsFixed(0)}', style: AtithyaTypography.heroTitle.copyWith(
                  color: AtithyaColors.imperialGold, fontSize: 16,
                )),
                quantity == 0
                    ? GestureDetector(
                        onTap: onAdd,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: AtithyaColors.imperialGold.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AtithyaColors.imperialGold),
                          ),
                          child: Text('ADD', style: TextStyle(
                            color: AtithyaColors.imperialGold, fontSize: 12, fontWeight: FontWeight.w600,
                          )),
                        ),
                      )
                    : Row(children: [
                        _qtyBtn(onRemove, Icons.remove),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('$quantity', style: AtithyaTypography.cardTitle.copyWith(
                            color: AtithyaColors.pearl, fontSize: 14,
                          )),
                        ),
                        _qtyBtn(onAdd, Icons.add),
                      ]),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _qtyBtn(VoidCallback onTap, IconData icon) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
        color: AtithyaColors.imperialGold.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AtithyaColors.imperialGold.withOpacity(0.4)),
      ),
      child: Icon(icon, color: AtithyaColors.imperialGold, size: 14),
    ),
  );
}

// ── Order Bar ─────────────────────────────────────────────────────────────────

class _OrderBar extends StatelessWidget {
  final int count;
  final double total;
  final bool loading;
  final VoidCallback onTap;

  const _OrderBar({required this.count, required this.total, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: AtithyaColors.goldGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AtithyaColors.imperialGold.withOpacity(0.3), blurRadius: 20),
          ],
        ),
        child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AtithyaColors.obsidian.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text('$count', style: const TextStyle(
              color: AtithyaColors.obsidian, fontSize: 13, fontWeight: FontWeight.w700,
            ))),
          ),
          const SizedBox(width: 12),
          Text('Place Order', style: AtithyaTypography.cardTitle.copyWith(
            color: AtithyaColors.obsidian, fontSize: 15,
          )),
          const Spacer(),
          if (loading)
            const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(color: AtithyaColors.obsidian, strokeWidth: 2))
          else
            Text('₹${total.toStringAsFixed(0)}', style: AtithyaTypography.heroTitle.copyWith(
              color: AtithyaColors.obsidian, fontSize: 16,
            )),
        ]),
      ),
    );
  }
}
