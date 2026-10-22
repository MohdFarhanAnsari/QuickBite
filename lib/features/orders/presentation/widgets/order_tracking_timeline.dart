import 'package:flutter/material.dart';
import 'package:quickbite/core/constants/app_colors.dart';
import 'package:quickbite/core/constants/app_spacing.dart';
import 'package:quickbite/core/constants/app_typography.dart';
import 'package:quickbite/features/checkout/domain/models/order.dart';
import 'package:quickbite/features/orders/presentation/providers/orders_provider.dart';

class TrackingStageData {
  final String title;
  final String description;
  final IconData icon;

  const TrackingStageData({
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// Polished vertical timeline displaying order progression stages.
class OrderTrackingTimeline extends StatelessWidget {
  final Order order;

  const OrderTrackingTimeline({super.key, required this.order});

  static const List<TrackingStageData> stages = [
    TrackingStageData(
      title: 'Order Placed',
      description: 'Your order was received and confirmed by the restaurant.',
      icon: Icons.receipt_long_rounded,
    ),
    TrackingStageData(
      title: 'Preparing Your Food',
      description: 'The kitchen is freshly preparing your dishes with care.',
      icon: Icons.outdoor_grill_rounded,
    ),
    TrackingStageData(
      title: 'Ready for Pickup',
      description: 'Items are neatly packed and awaiting courier pickup.',
      icon: Icons.takeout_dining_rounded,
    ),
    TrackingStageData(
      title: 'On the Way',
      description: 'Our delivery partner is heading toward your address.',
      icon: Icons.delivery_dining_rounded,
    ),
    TrackingStageData(
      title: 'Delivered',
      description: 'Order delivered safely to your doorstep. Bon appétit!',
      icon: Icons.home_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final status = QuickBiteOrderStatus.fromString(order.status);
    final activeIndex = _calculateActiveStageIndex(status);

    if (status == QuickBiteOrderStatus.cancelled) {
      return _buildCancelledView();
    }

    return Column(
      children: List.generate(stages.length, (index) {
        final stage = stages[index];
        final isCompleted = status == QuickBiteOrderStatus.delivered
            ? true
            : index < activeIndex;
        final isActive = status == QuickBiteOrderStatus.delivered
            ? false
            : index == activeIndex;
        final isUpcoming = !isCompleted && !isActive;
        final isLast = index == stages.length - 1;

        final timeLabel = _getTimeLabelForStage(
          index,
          order,
          isCompleted,
          isActive,
        );

        return _buildTimelineRow(
          stage: stage,
          isCompleted: isCompleted,
          isActive: isActive,
          isUpcoming: isUpcoming,
          isLast: isLast,
          timeLabel: timeLabel,
        );
      }),
    );
  }

  static int _calculateActiveStageIndex(QuickBiteOrderStatus status) {
    switch (status) {
      case QuickBiteOrderStatus.placed:
        return 0;
      case QuickBiteOrderStatus.preparing:
        return 1;
      case QuickBiteOrderStatus.readyForPickup:
        return 2;
      case QuickBiteOrderStatus.onTheWay:
        return 3;
      case QuickBiteOrderStatus.delivered:
        return 4;
      case QuickBiteOrderStatus.cancelled:
        return -1;
    }
  }

  String _getTimeLabelForStage(
    int index,
    Order order,
    bool isCompleted,
    bool isActive,
  ) {
    if (index == 0) {
      final hour = order.createdAt.hour > 12
          ? order.createdAt.hour - 12
          : (order.createdAt.hour == 0 ? 12 : order.createdAt.hour);
      final minute = order.createdAt.minute.toString().padLeft(2, '0');
      final period = order.createdAt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }

    if (isCompleted) {
      return 'Completed';
    }

    if (isActive) {
      return 'In Progress';
    }

    return 'Pending';
  }

  Widget _buildTimelineRow({
    required TrackingStageData stage,
    required bool isCompleted,
    required bool isActive,
    required bool isUpcoming,
    required bool isLast,
    required String timeLabel,
  }) {
    // Node indicator colors
    final Color nodeColor = isCompleted
        ? AppColors.success
        : (isActive ? AppColors.primary : AppColors.border);
    final Color iconColor = isCompleted
        ? Colors.white
        : (isActive ? Colors.white : AppColors.textMuted);
    final IconData displayIcon = isCompleted ? Icons.check_rounded : stage.icon;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Vertical Line & Node Circle
          Column(
            children: [
              // Circle Node
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUpcoming ? AppColors.surfaceVariant : nodeColor,
                  border: Border.all(
                    color: isActive
                        ? AppColors.primaryDark
                        : (isUpcoming ? AppColors.border : nodeColor),
                    width: isActive ? 2 : 1,
                  ),
                  boxShadow: isActive ? const [AppColors.primaryGlow] : null,
                ),
                child: Center(
                  child: Icon(displayIcon, size: 18, color: iconColor),
                ),
              ),

              // Connecting Line
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.5,
                    margin: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xxs,
                    ),
                    color: isCompleted ? AppColors.success : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),

          // Right: Content Details
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          stage.title,
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: isActive || isCompleted
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isActive
                                ? AppColors.primaryDark
                                : (isUpcoming
                                      ? AppColors.textMuted
                                      : AppColors.textPrimary),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primaryLight
                              : (isCompleted
                                    ? AppColors.success.withValues(alpha: 0.12)
                                    : AppColors.surfaceVariant),
                          borderRadius: AppSpacing.roundedXs,
                        ),
                        child: Text(
                          timeLabel,
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 10.5,
                            color: isActive
                                ? AppColors.primaryDark
                                : (isCompleted
                                      ? AppColors.success
                                      : AppColors.textMuted),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    stage.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: isUpcoming
                          ? AppColors.textMuted
                          : AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledView() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Cancelled',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'This order was cancelled. Any processed payment will be refunded within 2–4 business days.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
