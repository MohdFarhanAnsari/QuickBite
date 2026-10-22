import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite/core/constants/app_colors.dart';
import 'package:quickbite/core/constants/app_spacing.dart';
import 'package:quickbite/core/constants/app_typography.dart';
import 'package:quickbite/features/orders/presentation/providers/orders_provider.dart';
import 'package:quickbite/features/orders/presentation/widgets/order_card.dart';

/// "My Orders" screen presenting order history with filter chips
/// and comprehensive empty-state handling.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(ordersProvider);
    final notifier = ref.read(ordersProvider.notifier);
    final filteredOrders = ordersState.filteredOrders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textPrimary,
            ),
            tooltip: 'Order options',
            onSelected: (value) {
              if (value == 'clear') {
                notifier.clearOrders();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order history cleared (Empty State active)'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else if (value == 'reset') {
                notifier.loadMockOrders();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Demo order history restored'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: AppColors.error,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text('Clear History (Test Empty)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(
                      Icons.restore_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text('Load Demo Orders'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Horizontal Filter Chips
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: OrderFilter.values.map((filter) {
                    final isSelected = ordersState.activeFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(filter.label),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                        backgroundColor: AppColors.surfaceVariant,
                        selectedColor: AppColors.primaryLight,
                        checkmarkColor: AppColors.primary,
                        showCheckmark: false,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.roundedFull,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        onSelected: (_) => notifier.setFilter(filter),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Orders List or Empty State
            Expanded(
              child: filteredOrders.isEmpty
                  ? _buildEmptyState(context, ordersState.activeFilter)
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredOrders.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.md),

                      itemBuilder: (context, index) {
                        return OrderCard(order: filteredOrders[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, OrderFilter filter) {
    final isFiltered = filter != OrderFilter.all;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Empty State Graphic
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              isFiltered ? 'No ${filter.label} Orders' : 'No orders yet',
              style: AppTypography.displayMedium.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),

            // Subtitle
            Text(
              isFiltered
                  ? 'You have no orders currently in "${filter.label}" status.'
                  : 'You have not placed any orders yet. Discover delicious dishes from our top restaurants and place your first order!',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Explore Food CTA
            SizedBox(
              height: AppSpacing.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.restaurant_menu_rounded, size: 20),
                label: const Text(
                  'Explore Food',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textInverse,
                  minimumSize: const Size(0, AppSpacing.buttonHeight),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.roundedFull,
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
