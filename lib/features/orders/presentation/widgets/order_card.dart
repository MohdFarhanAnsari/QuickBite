import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite/core/constants/app_colors.dart';
import 'package:quickbite/core/constants/app_spacing.dart';
import 'package:quickbite/core/constants/app_typography.dart';
import 'package:quickbite/features/cart/presentation/providers/cart_provider.dart';
import 'package:quickbite/features/checkout/domain/models/order.dart';
import 'package:quickbite/features/orders/presentation/providers/orders_provider.dart';
import 'package:quickbite/features/orders/presentation/widgets/order_status_badge.dart';
import 'package:quickbite/shared/widgets/app_network_image.dart';

/// Clean, responsive card displaying order summary in "My Orders".
class OrderCard extends ConsumerWidget {
  final Order order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = QuickBiteOrderStatus.fromString(order.status);
    final isInProgress = status.isInProgress;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [AppColors.shadowSm],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppSpacing.roundedLg,
          onTap: () => context.push('/order-details/${order.orderId}'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Order ID + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: AppSpacing.roundedXs,
                            ),
                            child: const Icon(
                              Icons.receipt_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              order.orderId,
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    OrderStatusBadge(status: order.status, isDense: true),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Restaurant Info & Date
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: AppSpacing.roundedSm,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.storefront_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.restaurant?.name ?? 'QuickBite Partner',
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _formatDate(order.createdAt),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Thumbnails + Item Summary
                Row(
                  children: [
                    // Thumbnails row (up to 3)
                    ..._buildThumbnails(),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _buildItemsSummary(),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: AppSpacing.sm),

                // Bottom Row: Total Amount, Estimated Delivery & Action CTA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Total + Est Delivery
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.totalFormatted,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            isInProgress
                                ? 'Est. ${order.estimatedDelivery}'
                                : (status == QuickBiteOrderStatus.delivered
                                      ? 'Delivered'
                                      : 'Cancelled'),
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11,
                              color: isInProgress
                                  ? AppColors.primaryDark
                                  : AppColors.textMuted,
                              fontWeight: isInProgress
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),

                    // Action Buttons: "Track" or "View Details"
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isInProgress) ...[
                          InkWell(
                            onTap: () =>
                                context.push('/track-order/${order.orderId}'),
                            borderRadius: AppSpacing.roundedFull,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.primary),
                                borderRadius: AppSpacing.roundedFull,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.navigation_outlined,
                                    size: 13,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Track',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                        ] else ...[
                          InkWell(
                            onTap: () => _handleReorder(context, ref),
                            borderRadius: AppSpacing.roundedFull,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.replay_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Reorder',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        InkWell(
                          onTap: () =>
                              context.push('/order-details/${order.orderId}'),
                          borderRadius: AppSpacing.roundedFull,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: AppSpacing.roundedFull,
                            ),
                            child: Text(
                              'Details',
                              style: AppTypography.labelSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildThumbnails() {
    final widgets = <Widget>[];
    final previewItems = order.items.take(2).toList();

    for (final item in previewItems) {
      widgets.add(
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedXs,
            border: Border.all(color: AppColors.border, width: 0.5),
            color: AppColors.surfaceVariant,
          ),
          clipBehavior: Clip.antiAlias,
          child: AppNetworkImage(
            imageUrl: item.foodItem.imageUrl,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    if (order.items.length > 2) {
      widgets.add(
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedXs,
            color: AppColors.surfaceVariant,
          ),
          child: Center(
            child: Text(
              '+${order.items.length - 2}',
              style: AppTypography.labelSmall.copyWith(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  String _buildItemsSummary() {
    final count = order.totalQuantity;
    final itemText = count == 1 ? '1 item' : '$count items';
    if (order.items.isEmpty) return itemText;

    final firstItemName = order.items.first.foodItem.name;
    if (order.items.length == 1) {
      return '$itemText • $firstItemName';
    }
    return '$itemText • $firstItemName & more';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute $period';
  }

  void _handleReorder(BuildContext context, WidgetRef ref) {
    if (order.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items to reorder in this order.')),
      );
      return;
    }

    final cartNotifier = ref.read(cartProvider.notifier);
    for (final item in order.items) {
      cartNotifier.addItem(item.config);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${order.items.length} items added to your cart'),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: AppColors.primary,
          onPressed: () => context.push('/cart'),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );

    context.push('/cart');
  }
}
