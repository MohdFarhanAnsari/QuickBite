import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../domain/models/restaurant.dart';

/// Premium card showcasing restaurant image, ratings, cuisine, and delivery details.
class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onTap;
  final double? width;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    this.onTap,
    this.width = AppSpacing.restaurantCardWidth,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: AppSpacing.roundedLg,
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: const [AppColors.shadowSm],
        ),
        child: ClipRRect(
          borderRadius: AppSpacing.roundedLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hero Image with Badges
              Stack(
                children: [
                  AppNetworkImage(
                    imageUrl: restaurant.imageUrl,
                    width: width ?? double.infinity,
                    height: AppSpacing.restaurantCardImageHeight,
                    fit: BoxFit.cover,
                  ),

                  // Rating Badge (Top Right)
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs + 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.95),
                        borderRadius: AppSpacing.roundedFull,
                        boxShadow: const [AppColors.shadowSm],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: AppColors.accentYellow,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            restaurant.rating.toStringAsFixed(1),
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '(${restaurant.reviewCountFormatted})',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Delivery Time Badge (Bottom Left)
                  Positioned(
                    bottom: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs + 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withValues(alpha: 0.8),
                        borderRadius: AppSpacing.roundedFull,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_filled_rounded,
                            size: 12,
                            color: AppColors.textInverse,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            restaurant.deliveryTime,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textInverse,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Closed Status Overlay
                  if (!restaurant.isOpen)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.55),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: AppSpacing.roundedFull,
                          ),
                          child: Text(
                            'CLOSED NOW',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textInverse,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Details Section
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: AppTypography.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${restaurant.cuisine} • ${restaurant.distance}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Delivery Fee and Status row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs + 2,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: restaurant.deliveryFee == 0
                                ? AppColors.secondaryLight
                                : AppColors.surfaceVariant,
                            borderRadius: AppSpacing.roundedXs,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delivery_dining_rounded,
                                size: 14,
                                color: restaurant.deliveryFee == 0
                                    ? AppColors.secondary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                              Text(
                                restaurant.deliveryFee == 0
                                    ? 'Free Delivery'
                                    : '${restaurant.deliveryFeeFormatted} Delivery',
                                style: AppTypography.labelSmall.copyWith(
                                  color: restaurant.deliveryFee == 0
                                      ? AppColors.secondary
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
