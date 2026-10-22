import 'package:flutter/material.dart';
import 'package:quickbite/core/constants/app_colors.dart';
import 'package:quickbite/core/constants/app_spacing.dart';
import 'package:quickbite/core/constants/app_typography.dart';

/// Reusable order summary card displaying Subtotal, Delivery Fee, Discount, and Total.
class OrderSummaryCard extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final String title;

  const OrderSummaryCard({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    this.title = 'Bill Summary',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
                Icons.receipt_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Subtotal
          _buildSummaryRow(label: 'Subtotal', value: '₹${subtotal.toInt()}'),
          const SizedBox(height: AppSpacing.sm),

          // Delivery Fee
          _buildSummaryRow(
            label: 'Delivery Fee',
            value: deliveryFee == 0 ? 'FREE' : '₹${deliveryFee.toInt()}',
            isSuccess: deliveryFee == 0,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Discount
          if (discount > 0) ...[
            _buildSummaryRow(
              label: 'Discount',
              value: '-₹${discount.toInt()}',
              isSuccess: true,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          const Divider(height: AppSpacing.lg, color: AppColors.divider),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To Pay',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Incl. all taxes & charges',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
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
                '₹${total.toInt()}',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    bool isSuccess = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: isSuccess ? AppColors.success : AppColors.textPrimary,
            fontWeight: isSuccess ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
