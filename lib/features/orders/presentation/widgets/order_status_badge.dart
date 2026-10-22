import 'package:flutter/material.dart';
import 'package:quickbite/core/constants/app_colors.dart';
import 'package:quickbite/core/constants/app_spacing.dart';
import 'package:quickbite/core/constants/app_typography.dart';
import 'package:quickbite/features/orders/presentation/providers/orders_provider.dart';

/// Clean, color-coded status badge for QuickBite orders.
class OrderStatusBadge extends StatelessWidget {
  final String status;
  final bool isDense;

  const OrderStatusBadge({
    super.key,
    required this.status,
    this.isDense = false,
  });

  @override
  Widget build(BuildContext context) {
    final orderStatus = QuickBiteOrderStatus.fromString(status);

    final (
      Color foreground,
      Color background,
      IconData icon,
    ) = switch (orderStatus) {
      QuickBiteOrderStatus.placed => (
        AppColors.primaryDark,
        AppColors.primaryLight,
        Icons.receipt_long_rounded,
      ),
      QuickBiteOrderStatus.preparing => (
        const Color(0xFFD97706), // warm amber
        const Color(0xFFFEF3C7),
        Icons.soup_kitchen_rounded,
      ),
      QuickBiteOrderStatus.readyForPickup => (
        const Color(0xFF0D9488), // deep teal
        const Color(0xFFCCFBF1),
        Icons.takeout_dining_rounded,
      ),
      QuickBiteOrderStatus.onTheWay => (
        AppColors.primary,
        AppColors.primaryLight,
        Icons.delivery_dining_rounded,
      ),
      QuickBiteOrderStatus.delivered => (
        AppColors.success,
        const Color(0xFFD1FAE5),
        Icons.check_circle_rounded,
      ),
      QuickBiteOrderStatus.cancelled => (
        AppColors.error,
        const Color(0xFFFEE2E2),
        Icons.cancel_rounded,
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDense ? AppSpacing.xs + 2 : AppSpacing.sm + 2,
        vertical: isDense ? 2 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppSpacing.roundedFull,
        border: Border.all(
          color: foreground.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isDense ? 12 : 14, color: foreground),
          const SizedBox(width: AppSpacing.xs),
          Text(
            orderStatus.label,
            style: AppTypography.labelSmall.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: isDense ? 10.5 : 11.5,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
