import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite/core/constants/app_colors.dart';
import 'package:quickbite/core/constants/app_spacing.dart';
import 'package:quickbite/core/constants/app_typography.dart';
import 'package:quickbite/features/cart/domain/models/cart_item.dart';
import 'package:quickbite/features/cart/presentation/providers/cart_provider.dart';
import 'package:quickbite/features/cart/presentation/widgets/order_summary_card.dart';
import 'package:quickbite/features/checkout/domain/models/order.dart';
import 'package:quickbite/features/checkout/presentation/providers/checkout_provider.dart';
import 'package:quickbite/features/checkout/presentation/widgets/address_selection_bottom_sheet.dart';

/// Comprehensive Checkout screen with Address, Delivery Method,
/// Demo Payment selection, Order Items overview, and Place Order action.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isItemsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final checkoutState = ref.watch(checkoutProvider);
    final checkoutNotifier = ref.read(checkoutProvider.notifier);

    final deliveryFee = checkoutNotifier.calculateDeliveryFee(cartState);
    final total = checkoutNotifier.calculateTotal(cartState);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/cart');
            }
          },
        ),
      ),
      body: cartState.isEmpty
          ? _buildEmptyState(context)
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section A: Delivery Address
                        _buildAddressCard(
                          context,
                          checkoutState,
                          checkoutNotifier,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Section B: Delivery Method
                        _buildDeliveryMethodSection(
                          checkoutState,
                          checkoutNotifier,
                          cartState,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Section C: Payment Method (Demo)
                        _buildPaymentMethodSection(
                          checkoutState,
                          checkoutNotifier,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Section D: Order Items Preview
                        _buildOrderItemsSection(cartState),
                        const SizedBox(height: AppSpacing.md),

                        // Section E: Price Details
                        OrderSummaryCard(
                          subtotal: cartState.subtotal,
                          deliveryFee: deliveryFee,
                          discount: cartState.discount,
                          total: total,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),

                // Sticky Bottom CTA: Place Order
                _buildStickyBottomBar(
                  context: context,
                  checkoutState: checkoutState,
                  checkoutNotifier: checkoutNotifier,
                  cartState: cartState,
                  total: total,
                ),
              ],
            ),
    );
  }

  // --- Section A: Delivery Address ---
  Widget _buildAddressCard(
    BuildContext context,
    CheckoutState checkoutState,
    CheckoutNotifier notifier,
  ) {
    final address = checkoutState.selectedAddress;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [AppColors.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        'Delivery Address',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => AddressSelectionBottomSheet(
                      selectedAddress: address,
                      onAddressSelected: notifier.selectAddress,
                    ),
                  );
                },
                child: const Text('Change'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppSpacing.roundedXs,
                ),
                child: Text(
                  address.label.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.recipientName,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address.formattedAddress,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Section B: Delivery Method ---
  Widget _buildDeliveryMethodSection(
    CheckoutState checkoutState,
    CheckoutNotifier notifier,
    CartState cartState,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [AppColors.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.two_wheeler_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Delivery Speed',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildDeliveryMethodTile(
                  method: DeliveryMethodType.standard,
                  title: 'Standard',
                  subtitle: '30–45 min',
                  badge: cartState.isFreeDeliveryUnlocked ? 'FREE' : '₹40',
                  isSelected:
                      checkoutState.selectedDeliveryMethod ==
                      DeliveryMethodType.standard,
                  onTap: () => notifier.selectDeliveryMethod(
                    DeliveryMethodType.standard,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildDeliveryMethodTile(
                  method: DeliveryMethodType.express,
                  title: 'Express',
                  subtitle: '20–30 min',
                  badge: '+₹49',
                  isSelected:
                      checkoutState.selectedDeliveryMethod ==
                      DeliveryMethodType.express,
                  onTap: () =>
                      notifier.selectDeliveryMethod(DeliveryMethodType.express),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryMethodTile({
    required DeliveryMethodType method,
    required String title,
    required String subtitle,
    required String badge,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.roundedMd,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight.withValues(alpha: 0.35)
              : AppColors.surfaceVariant.withValues(alpha: 0.4),
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 18,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surfaceVariant,
                borderRadius: AppSpacing.roundedXs,
              ),
              child: Text(
                badge,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Section C: Payment Method ---
  Widget _buildPaymentMethodSection(
    CheckoutState checkoutState,
    CheckoutNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [AppColors.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.payment_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        'Payment Method',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppSpacing.roundedXs,
                ),
                child: Text(
                  'Demo Payment',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Options: UPI, Card, Cash on Delivery
          _buildPaymentOptionTile(
            type: PaymentMethodType.upi,
            icon: Icons.account_balance_wallet_outlined,
            title: 'UPI',
            subtitle: 'Google Pay, PhonePe, Paytm',
            isSelected:
                checkoutState.selectedPaymentMethod == PaymentMethodType.upi,
            onTap: () => notifier.selectPaymentMethod(PaymentMethodType.upi),
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildPaymentOptionTile(
            type: PaymentMethodType.card,
            icon: Icons.credit_card_rounded,
            title: 'Credit / Debit Card',
            subtitle: 'Visa, Mastercard, RuPay',
            isSelected:
                checkoutState.selectedPaymentMethod == PaymentMethodType.card,
            onTap: () => notifier.selectPaymentMethod(PaymentMethodType.card),
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildPaymentOptionTile(
            type: PaymentMethodType.cod,
            icon: Icons.money_rounded,
            title: 'Cash on Delivery',
            subtitle: 'Pay cash or UPI upon delivery',
            isSelected:
                checkoutState.selectedPaymentMethod == PaymentMethodType.cod,
            onTap: () => notifier.selectPaymentMethod(PaymentMethodType.cod),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionTile({
    required PaymentMethodType type,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.roundedMd,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // --- Section D: Order Items Preview ---
  Widget _buildOrderItemsSection(CartState cartState) {
    final displayedItems = _isItemsExpanded
        ? cartState.items
        : cartState.items.take(2).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [AppColors.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Items (${cartState.totalQuantity})',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (cartState.items.length > 2)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isItemsExpanded = !_isItemsExpanded;
                    });
                  },
                  child: Text(_isItemsExpanded ? 'View less' : 'View all'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...displayedItems.map(_buildCompactItemRow),
        ],
      ),
    );
  }

  Widget _buildCompactItemRow(CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppSpacing.roundedXs,
            ),
            child: Text(
              '${item.quantity}x',
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.foodItem.name,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.customizationSummary.isNotEmpty)
                  Text(
                    item.customizationSummary,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            item.totalPriceFormatted,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // --- Sticky Bottom Bar ---
  Widget _buildStickyBottomBar({
    required BuildContext context,
    required CheckoutState checkoutState,
    required CheckoutNotifier checkoutNotifier,
    required CartState cartState,
    required double total,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [AppColors.shadowMd],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To Pay',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '₹${total.toInt()}',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 6,
              child: ElevatedButton(
                onPressed: checkoutState.isProcessing
                    ? null
                    : () async {
                        final order = await checkoutNotifier.placeOrder(
                          cart: cartState,
                          onCartClear: () =>
                              ref.read(cartProvider.notifier).clearCart(),
                        );
                        if (order != null && context.mounted) {
                          context.go('/order-success', extra: order);
                        } else if (context.mounted) {
                          final currentError = ref
                              .read(checkoutProvider)
                              .errorMessage;
                          if (currentError != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(currentError),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textInverse,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.roundedFull,
                  ),
                  elevation: 2,
                ),
                child: checkoutState.isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'Place Order • ₹${total.toInt()}',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.textInverse,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Your cart is empty',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }
}
