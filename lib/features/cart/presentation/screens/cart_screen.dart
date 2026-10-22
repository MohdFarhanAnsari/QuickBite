import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite/core/constants/app_colors.dart';
import 'package:quickbite/core/constants/app_spacing.dart';
import 'package:quickbite/core/constants/app_typography.dart';
import 'package:quickbite/features/cart/domain/models/cart_item.dart';
import 'package:quickbite/features/cart/presentation/providers/cart_provider.dart';
import 'package:quickbite/features/cart/presentation/widgets/cart_checkout_bottom_bar.dart';
import 'package:quickbite/features/cart/presentation/widgets/cart_item_card.dart';
import 'package:quickbite/features/cart/presentation/widgets/order_summary_card.dart';

/// Primary Cart screen for reviewing items, modifying quantities,
/// seeing delivery incentives, and navigating to Checkout.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                'Your Cart',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (cartState.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppSpacing.roundedFull,
                ),
                child: Text(
                  '${cartState.totalQuantity}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          if (cartState.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                _showClearCartDialog(context, cartNotifier);
              },
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: const Text('Clear'),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
            ),
        ],
      ),
      body: cartState.isEmpty
          ? _buildEmptyCart(context)
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Free Delivery Incentive Banner
                        _buildFreeDeliveryIncentive(cartState),
                        const SizedBox(height: AppSpacing.md),

                        // 2. Restaurant Grouping & Cart Items
                        ..._buildGroupedItems(
                          context: context,
                          cartState: cartState,
                          cartNotifier: cartNotifier,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 3. Bill Summary Card
                        OrderSummaryCard(
                          subtotal: cartState.subtotal,
                          deliveryFee: cartState.deliveryFee,
                          discount: cartState.discount,
                          total: cartState.grandTotal,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),

                // 4. Sticky Bottom Checkout Bar
                CartCheckoutBottomBar(
                  total: cartState.grandTotal,
                  onCheckout: () {
                    context.push('/checkout');
                  },
                ),
              ],
            ),
    );
  }

  /// Displays delivery progress towards free shipping (₹499 threshold).
  Widget _buildFreeDeliveryIncentive(CartState cart) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cart.isFreeDeliveryUnlocked
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.primaryLight.withValues(alpha: 0.6),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: cart.isFreeDeliveryUnlocked
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                cart.isFreeDeliveryUnlocked
                    ? Icons.celebration_rounded
                    : Icons.local_shipping_outlined,
                size: 20,
                color: cart.isFreeDeliveryUnlocked
                    ? AppColors.success
                    : AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  cart.isFreeDeliveryUnlocked
                      ? '🎉 You unlocked FREE delivery!'
                      : 'Add ₹${cart.freeDeliveryRemaining.toInt()} more for FREE delivery',
                  style: AppTypography.labelMedium.copyWith(
                    color: cart.isFreeDeliveryUnlocked
                        ? AppColors.success
                        : AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (!cart.isFreeDeliveryUnlocked) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppSpacing.roundedFull,
              child: LinearProgressIndicator(
                value: cart.freeDeliveryProgress,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Groups items by restaurant or shows single restaurant header.
  List<Widget> _buildGroupedItems({
    required BuildContext context,
    required CartState cartState,
    required CartNotifier cartNotifier,
  }) {
    final widgets = <Widget>[];
    final grouped = cartState.itemsByRestaurant;

    for (final entry in grouped.entries) {
      final restaurantName = entry.key;
      final items = entry.value;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            children: [
              const Icon(
                Icons.storefront_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'From $restaurantName',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );

      for (final item in items) {
        widgets.add(
          CartItemCard(
            item: item,
            onIncrement: () => cartNotifier.incrementItem(item.id),
            onDecrement: () => cartNotifier.decrementItem(item.id),
            onRemove: () {
              cartNotifier.removeItem(item.id);
              _showUndoSnackBar(context, cartNotifier, item);
            },
          ),
        );
      }
    }

    return widgets;
  }

  void _showUndoSnackBar(
    BuildContext context,
    CartNotifier notifier,
    CartItem removedItem,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Removed "${removedItem.foodItem.name}" from cart',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppColors.primary,
          onPressed: () {
            notifier.undoRemove();
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, CartNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text(
          'Are you sure you want to remove all items from your cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.clearCart();
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  /// Empty cart state illustration and call to action.
  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Your cart is empty',
              style: AppTypography.displayMedium.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add your favorite food and we\'ll deliver it to your door.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textInverse,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.roundedFull,
                ),
              ),
              child: const Text(
                'Explore Food',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
