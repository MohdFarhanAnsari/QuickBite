import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite/core/constants/app_colors.dart';
import 'package:quickbite/core/constants/app_spacing.dart';
import 'package:quickbite/core/constants/app_typography.dart';
import 'package:quickbite/features/checkout/domain/models/delivery_address.dart';
import 'package:quickbite/features/checkout/domain/models/order.dart';
import 'package:quickbite/features/checkout/presentation/providers/checkout_provider.dart';

/// Screen displayed immediately following successful order placement.
/// Shows confirmation details, order ID, delivery time, address summary,
/// and routes to Continue Shopping or Day 4 Track Order placeholder.
class OrderSuccessScreen extends ConsumerWidget {
  final Order? order;

  const OrderSuccessScreen({super.key, this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Resolve order from constructor extra or fallback to checkoutProvider
    final placedOrder =
        order ??
        ref.watch(checkoutProvider).lastPlacedOrder ??
        _createFallbackOrder();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.xxl),

                      // Success Animation / Icon Badge
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 64,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Title
                      Text(
                        'Order Placed Successfully!',
                        style: AppTypography.displayMedium.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Your delicious meal is being prepared with care.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Order Details Card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppSpacing.roundedLg,
                          border: Border.all(color: AppColors.border, width: 1),
                          boxShadow: const [AppColors.shadowSm],
                        ),
                        child: Column(
                          children: [
                            // Order ID
                            _buildDetailRow(
                              label: 'Order ID',
                              value: placedOrder.orderId,
                              isHighlighted: true,
                            ),
                            const Divider(height: AppSpacing.lg),

                            // Estimated Delivery
                            _buildDetailRow(
                              label: 'Estimated Delivery',
                              value: placedOrder.estimatedDelivery,
                              icon: Icons.timer_outlined,
                            ),
                            const Divider(height: AppSpacing.lg),

                            // Total Amount
                            _buildDetailRow(
                              label: 'Total Amount',
                              value: placedOrder.totalFormatted,
                              isBold: true,
                            ),
                            const Divider(height: AppSpacing.lg),

                            // Restaurant
                            if (placedOrder.restaurant != null) ...[
                              _buildDetailRow(
                                label: 'Restaurant',
                                value: placedOrder.restaurant!.name,
                                icon: Icons.storefront_outlined,
                              ),
                              const Divider(height: AppSpacing.lg),
                            ],

                            // Delivery Address
                            _buildDetailRow(
                              label: 'Delivery To',
                              value:
                                  '${placedOrder.deliveryAddress.label} • ${placedOrder.deliveryAddress.streetAddress}, ${placedOrder.deliveryAddress.city}',
                              icon: Icons.place_outlined,
                            ),
                            const Divider(height: AppSpacing.lg),

                            // Payment Method
                            _buildDetailRow(
                              label: 'Payment',
                              value:
                                  '${placedOrder.paymentMethod.title} (Demo)',
                              icon: Icons.payment_outlined,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Column(
                children: [
                  // Track Order
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _onTrackOrderPressed(context, placedOrder),
                      icon: const Icon(Icons.navigation_outlined, size: 20),
                      label: const Text(
                        'Track Order',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textInverse,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.roundedFull,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Continue Shopping
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => context.go('/'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.roundedFull,
                        ),
                      ),
                      child: const Text(
                        'Continue Shopping',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // View in My Orders text button
                  TextButton.icon(
                    onPressed: () => context.go('/orders'),
                    icon: const Icon(Icons.receipt_long_rounded, size: 16),
                    label: const Text(
                      'View in My Orders',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    IconData? icon,
    bool isHighlighted = false,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.bodyMedium.copyWith(
              color: isHighlighted
                  ? AppColors.primaryDark
                  : AppColors.textPrimary,
              fontWeight: isBold || isHighlighted
                  ? FontWeight.w800
                  : FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _onTrackOrderPressed(BuildContext context, Order placedOrder) {
    if (GoRouter.maybeOf(context) != null) {
      context.push('/track-order/${placedOrder.orderId}');
    } else {
      _showTrackOrderPlaceholder(context, placedOrder);
    }
  }

  void _showTrackOrderPlaceholder(BuildContext context, Order placedOrder) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.radar_rounded, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            const Text('Live Tracking'),
          ],
        ),
        content: Text(
          'Live GPS Tracking for Order ${placedOrder.orderId} will be unlocked in Day 4!\n\nYour order is confirmed and being prepared.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
            ),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  static Order _createFallbackOrder() {
    return Order(
      orderId: 'QB-2026-0001',
      createdAt: DateTime.now(),
      items: const [],
      subtotal: 349.0,
      deliveryFee: 40.0,
      discount: 0.0,
      total: 389.0,
      deliveryAddress: DeliveryAddress.demoAddresses.first,
      deliveryMethod: DeliveryMethodType.standard,
      paymentMethod: PaymentMethodType.upi,
      status: 'Confirmed',
    );
  }
}
