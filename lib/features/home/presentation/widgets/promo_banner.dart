import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/app_network_image.dart';

/// Premium promotional hero banner featuring high-contrast typography,
/// appetizing visual imagery, and an engaging "Order now" CTA.
class PromoBanner extends StatelessWidget {
  final VoidCallback? onCtaTap;

  const PromoBanner({super.key, this.onCtaTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        height: AppSpacing.promoBannerHeight,
        decoration: BoxDecoration(
          borderRadius: AppSpacing.roundedXl,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7A45), Color(0xFFE84E1B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [AppColors.primaryGlow],
        ),
        child: ClipRRect(
          borderRadius: AppSpacing.roundedXl,
          child: Stack(
            children: [
              // Decorative background radial ambient glow
              Positioned(
                top: -30,
                right: -20,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Positioned(
                bottom: -40,
                left: 120,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),

              // Banner Content Layout
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    // Text Column
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Promo Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: AppSpacing.roundedFull,
                            ),
                            child: Text(
                              'LIMITED TIME',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textInverse,
                                letterSpacing: 0.8,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),

                          // Offer Headline
                          Text(
                            '50% OFF',
                            style: AppTypography.displayMedium.copyWith(
                              color: AppColors.textInverse,
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),

                          // Subtitle
                          Text(
                            'On your first order',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // Action CTA
                          InkWell(
                            onTap: onCtaTap,
                            borderRadius: AppSpacing.roundedFull,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: AppSpacing.roundedFull,
                                boxShadow: const [AppColors.shadowSm],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Order now',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xxs),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 13,
                                    color: AppColors.primaryDark,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: AppSpacing.xs),

                    // Food Image Visual
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const ClipOval(
                            child: AppNetworkImage(
                              imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=300&q=80',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
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
