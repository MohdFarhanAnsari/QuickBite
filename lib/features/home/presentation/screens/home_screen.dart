import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../restaurants/domain/models/food_item.dart';
import '../../../restaurants/domain/models/restaurant.dart';
import '../../../restaurants/presentation/widgets/food_card.dart';
import '../../../restaurants/presentation/widgets/restaurant_card.dart';
import '../providers/home_providers.dart';
import '../widgets/category_section.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/location_header.dart';
import '../widgets/promo_banner.dart';

/// The Day 1 Home experience for QuickBite.
/// Connects Riverpod providers for search, category filtering, and mock datasets.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popularRestaurantsAsync = ref.watch(popularRestaurantsProvider);
    final recommendedFoodAsync = ref.watch(recommendedFoodProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final cartState = ref.watch(cartProvider);

    final isFiltering =
        searchQuery.trim().isNotEmpty || selectedCategory != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            // Re-fetch / refresh data providers
            ref.invalidate(popularRestaurantsProvider);
            ref.invalidate(recommendedFoodProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),

                // 1. Top Location & Greeting Area
                LocationHeader(
                  cartItemCount: cartState.itemCount,
                  onCartTap: () => context.push('/cart'),
                ),

                const SizedBox(height: AppSpacing.lg),

                // 2. Search Bar
                const HomeSearchBar(),

                const SizedBox(height: AppSpacing.lg),

                // 3. Promotional Hero Banner (Hidden when actively searching to preserve viewport)
                if (!isFiltering) ...[
                  const PromoBanner(),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // 4. Craving Categories
                const CategorySection(),

                const SizedBox(height: AppSpacing.xl),

                // 5. Active Filter Indicator Bar
                if (isFiltering)
                  _buildActiveFilterBar(
                    context,
                    ref,
                    searchQuery,
                    selectedCategory,
                  ),

                // 6. Popular Restaurants Section
                popularRestaurantsAsync.when(
                  loading: () => _buildSectionLoadingPlaceholder(),
                  error: (error, _) =>
                      _buildErrorBanner('Error loading restaurants'),
                  data: (restaurants) {
                    if (restaurants.isEmpty && isFiltering) {
                      return const SizedBox.shrink();
                    }
                    return _buildPopularRestaurantsSection(restaurants);
                  },
                ),

                const SizedBox(height: AppSpacing.xl),

                // 7. Recommended Food Dishes Section
                recommendedFoodAsync.when(
                  loading: () => _buildSectionLoadingPlaceholder(),
                  error: (error, _) =>
                      _buildErrorBanner('Error loading dishes'),
                  data: (foodItems) {
                    final restaurants = popularRestaurantsAsync.value ?? [];
                    final restaurantMap = {
                      for (var r in restaurants) r.id: r.name,
                    };

                    if (foodItems.isEmpty && isFiltering) {
                      final hasRestaurants =
                          (popularRestaurantsAsync.value?.isNotEmpty ?? false);
                      if (!hasRestaurants) {
                        return _buildNoResultsState(ref);
                      }
                      return const SizedBox.shrink();
                    }

                    return _buildRecommendedFoodSection(
                      foodItems,
                      restaurantMap,
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.xxxl + AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Displays an active filter status bar when search query or category is applied
  Widget _buildActiveFilterBar(
    BuildContext context,
    WidgetRef ref,
    String searchQuery,
    String? selectedCategory,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing results for: ${selectedCategory != null ? '#$selectedCategory ' : ''}${searchQuery.isNotEmpty ? '"$searchQuery"' : ''}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(searchQueryProvider.notifier).clear();
              ref.read(selectedCategoryProvider.notifier).clear();
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Reset',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Horizontal scrolling carousel for Popular Restaurants
  Widget _buildPopularRestaurantsSection(List<Restaurant> restaurants) {
    if (restaurants.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Popular Near You', actionTitle: 'See All'),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: AppSpacing.restaurantCardHeight,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: restaurants.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              return RestaurantCard(
                restaurant: restaurant,
                onTap: () => context.push('/restaurant/${restaurant.id}'),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Vertical list of Recommended Dishes
  Widget _buildRecommendedFoodSection(
    List<FoodItem> foodItems,
    Map<String, String> restaurantMap,
  ) {
    if (foodItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recommended For You'),
        const SizedBox(height: AppSpacing.sm),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: foodItems.length,
          itemBuilder: (context, index) {
            final food = foodItems[index];
            return FoodCard(
              foodItem: food,
              restaurantName: restaurantMap[food.restaurantId],
              onTap: () => context.push('/food/${food.id}'),
              onAddTap: () => context.push('/food/${food.id}'),
            );
          },
        ),
      ],
    );
  }

  /// Empty state when search/category filters yield 0 results
  Widget _buildNoResultsState(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 32,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No matching dishes or restaurants',
            style: AppTypography.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Try adjusting your search terms or craving filters.',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(
            onPressed: () {
              ref.read(searchQueryProvider.notifier).clear();
              ref.read(selectedCategoryProvider.notifier).clear();
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.roundedFull,
              ),
            ),
            child: Text(
              'Clear Filters',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLoadingPlaceholder() {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppSpacing.roundedLg,
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: AppSpacing.roundedMd,
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            Text(message, style: AppTypography.bodyMedium),
          ],
        ),
      ),
    );
  }
}
