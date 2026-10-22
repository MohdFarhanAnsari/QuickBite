import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite/core/constants/app_colors.dart';
import 'package:quickbite/core/constants/app_spacing.dart';
import 'package:quickbite/core/constants/app_typography.dart';
import 'package:quickbite/features/cart/presentation/providers/cart_provider.dart';
import 'package:quickbite/features/restaurants/domain/models/food_item.dart';
import 'package:quickbite/features/restaurants/domain/models/restaurant.dart';
import 'package:quickbite/features/restaurants/presentation/providers/restaurant_providers.dart';
import 'package:quickbite/features/restaurants/presentation/widgets/menu_item_card.dart';
import 'package:quickbite/shared/widgets/app_network_image.dart';

/// Comprehensive Restaurant Details & Menu Screen for Day 2.
/// Features a hero photography header, restaurant information card,
/// category filtering bar, and interactive menu list.
class RestaurantDetailsScreen extends ConsumerWidget {
  final String restaurantId;

  const RestaurantDetailsScreen({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantAsync = ref.watch(restaurantDetailsProvider(restaurantId));
    final categoriesAsync = ref.watch(
      restaurantMenuCategoriesProvider(restaurantId),
    );
    final activeCategory = ref.watch(
      selectedMenuCategoryProvider(restaurantId),
    );
    final menuItemsAsync = ref.watch(restaurantMenuProvider(restaurantId));
    final isFavorite = ref
        .watch(favoriteRestaurantsProvider)
        .contains(restaurantId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: restaurantAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) =>
            Center(child: Text('Error loading restaurant details: $err')),
        data: (Restaurant? restaurant) {
          if (restaurant == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Restaurant Not Found')),
              body: const Center(child: Text('Restaurant does not exist.')),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Hero Image Header with Floating Controls
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                elevation: 0,
                backgroundColor: AppColors.surface,
                leading: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs + 2),
                  child: CircleAvatar(
                    backgroundColor: AppColors.surface.withValues(alpha: 0.9),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: CircleAvatar(
                      backgroundColor: AppColors.surface.withValues(alpha: 0.9),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.shopping_bag_outlined,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                            onPressed: () => context.push('/cart'),
                          ),
                          if (ref.watch(cartProvider).itemCount > 0)
                            Positioned(
                              top: 5,
                              right: 5,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 14,
                                  minHeight: 14,
                                ),
                                child: Text(
                                  '${ref.watch(cartProvider).itemCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    height: 1,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: CircleAvatar(
                      backgroundColor: AppColors.surface.withValues(alpha: 0.9),
                      child: IconButton(
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavorite
                              ? AppColors.error
                              : AppColors.textPrimary,
                          size: 20,
                        ),
                        onPressed: () {
                          ref
                              .read(favoriteRestaurantsProvider.notifier)
                              .toggleFavorite(restaurantId);
                        },
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppNetworkImage(
                        imageUrl: restaurant.imageUrl,
                        fit: BoxFit.cover,
                      ),
                      // Gradient overlay for back button legibility
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.45),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Restaurant Metadata & Information Area
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Restaurant Name & Open Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              restaurant.name,
                              style: AppTypography.displayMedium.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: restaurant.isOpen
                                  ? AppColors.success.withValues(alpha: 0.12)
                                  : AppColors.error.withValues(alpha: 0.12),
                              borderRadius: AppSpacing.roundedFull,
                            ),
                            child: Text(
                              restaurant.isOpen ? 'OPEN NOW' : 'CLOSED',
                              style: AppTypography.labelSmall.copyWith(
                                color: restaurant.isOpen
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Cuisine
                      Text(
                        restaurant.cuisine,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Rating & Reviews Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs + 2,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentYellow.withValues(
                                alpha: 0.18,
                              ),
                              borderRadius: AppSpacing.roundedXs,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 15,
                                  color: AppColors.accentYellow,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  restaurant.rating.toStringAsFixed(1),
                                  style: AppTypography.labelSmall.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '(${restaurant.reviewCountFormatted} reviews)',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Delivery & Distance Chips
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: AppSpacing.roundedMd,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Flexible(
                              child: _buildInfoPill(
                                icon: Icons.access_time_rounded,
                                label: restaurant.deliveryTime,
                              ),
                            ),
                            _buildVerticalDivider(),
                            Flexible(
                              child: _buildInfoPill(
                                icon: Icons.place_outlined,
                                label: restaurant.distance,
                              ),
                            ),
                            _buildVerticalDivider(),
                            Flexible(
                              child: _buildInfoPill(
                                icon: Icons.delivery_dining_rounded,
                                label: restaurant.deliveryFee == 0
                                    ? 'Free delivery'
                                    : restaurant.deliveryFeeFormatted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (restaurant.description.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          restaurant.description,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              // 3. Menu Category Navigation Bar
              SliverToBoxAdapter(
                child: categoriesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (categories) {
                    if (categories.isEmpty) return const SizedBox.shrink();

                    return Container(
                      height: 44,
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: categories.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = activeCategory == category;

                          return GestureDetector(
                            onTap: () {
                              ref
                                  .read(
                                    selectedMenuCategoryProvider(restaurantId)
                                        .notifier,
                                  )
                                  .setCategory(category);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.surface,
                                borderRadius: AppSpacing.roundedFull,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: 1.2,
                                ),
                                boxShadow: isSelected
                                    ? const [AppColors.primaryGlow]
                                    : const [AppColors.shadowSm],
                              ),
                              child: Center(
                                child: Text(
                                  category,
                                  style: AppTypography.labelMedium.copyWith(
                                    color: isSelected
                                        ? AppColors.textInverse
                                        : AppColors.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              // 4. Menu Items Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    activeCategory == 'Recommended'
                        ? 'Recommended Items'
                        : activeCategory,
                    style: AppTypography.titleLarge,
                  ),
                ),
              ),

              // 5. Menu Items List
              menuItemsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                error: (err, _) => SliverToBoxAdapter(
                  child: Center(child: Text('Error loading menu: $err')),
                ),
                data: (List<FoodItem> menuItems) {
                  if (menuItems.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xxl),
                        child: Center(
                          child: Text('No items found in this category.'),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final food = menuItems[index];
                      return MenuItemCard(
                        foodItem: food,
                        onTap: () {
                          context.push('/food/${food.id}');
                        },
                        onAddTap: () {
                          context.push('/food/${food.id}');
                        },
                      );
                    }, childCount: menuItems.length),
                  );
                },
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xxxl + AppSpacing.lg),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoPill({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(width: 1, height: 16, color: AppColors.divider);
  }
}
