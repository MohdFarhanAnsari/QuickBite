import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite/core/constants/app_colors.dart';
import 'package:quickbite/core/router/app_router.dart';
import 'package:quickbite/core/constants/app_spacing.dart';
import 'package:quickbite/core/constants/app_typography.dart';
import 'package:quickbite/features/cart/presentation/providers/cart_provider.dart';
import 'package:quickbite/features/restaurants/domain/models/food_customization.dart';
import 'package:quickbite/features/restaurants/domain/models/food_item.dart';
import 'package:quickbite/features/restaurants/domain/models/restaurant.dart';
import 'package:quickbite/features/restaurants/presentation/providers/restaurant_providers.dart';
import 'package:quickbite/shared/widgets/app_network_image.dart';

/// Detailed Food Customization Screen for Day 2.
/// Includes data-driven customization options (Size, Add-ons, Spice Level),
/// multiline special instructions, interactive quantity counter (min 1),
/// dynamic immediate INR price updates, and a sticky bottom action bar.
class FoodDetailsScreen extends ConsumerStatefulWidget {
  final String foodId;

  const FoodDetailsScreen({super.key, required this.foodId});

  @override
  ConsumerState<FoodDetailsScreen> createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends ConsumerState<FoodDetailsScreen> {
  late final TextEditingController _instructionsController;

  @override
  void initState() {
    super.initState();
    _instructionsController = TextEditingController();
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foodAsync = ref.watch(foodDetailsProvider(widget.foodId));

    return foodAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Error loading food details: $err')),
      ),
      data: (FoodItem? food) {
        if (food == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Item Not Found')),
            body: const Center(child: Text('Food item does not exist.')),
          );
        }

        final restaurantAsync = ref.watch(
          restaurantDetailsProvider(food.restaurantId),
        );
        final restaurant = restaurantAsync.value;
        final restaurantName = restaurant?.name ?? '';
        final customizationState = ref.watch(foodCustomizationProvider(food));
        final customizationNotifier = ref.read(
          foodCustomizationProvider(food).notifier,
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food Image with Back Button & Badges
                _buildHeroImage(context, food),

                // Item Details Card
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dietary indicator & rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _buildDietaryIndicator(food.isVeg),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                food.isVeg ? 'VEGETARIAN' : 'NON-VEG',
                                style: AppTypography.labelSmall.copyWith(
                                  color: food.isVeg
                                      ? AppColors.vegGreen
                                      : AppColors.nonVegRed,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                              if (food.isPopular) ...[
                                const SizedBox(width: AppSpacing.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs + 2,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: AppSpacing.roundedXs,
                                  ),
                                  child: Text(
                                    'POPULAR',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: AppColors.accentYellow,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                food.rating.toStringAsFixed(1),
                                style: AppTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Food Name
                      Text(
                        food.name,
                        style: AppTypography.displayMedium.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      if (restaurantName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'by $restaurantName',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.sm),

                      // Price
                      Text(
                        food.priceFormatted,
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Description
                      Text(
                        food.description,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Customization Groups (Size, Add-ons, Spice)
                if (food.customizationGroups.isNotEmpty)
                  ...food.customizationGroups.map(
                    (group) => _buildCustomizationGroupCard(
                      group: group,
                      selectedOptions:
                          customizationState.selectedOptions[group.id] ?? [],
                      onOptionSelected: (option) {
                        if (group.isMultiSelect) {
                          customizationNotifier.toggleMultiOption(
                            group.id,
                            option,
                          );
                        } else {
                          customizationNotifier.selectSingleOption(
                            group.id,
                            option,
                          );
                        }
                      },
                    ),
                  ),

                // Special Instructions Card
                _buildSpecialInstructionsCard(
                  customizationNotifier: customizationNotifier,
                ),

                // Dynamic Price Breakdown Card
                _buildPriceBreakdownCard(customizationState),

                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
          bottomNavigationBar: _buildStickyBottomAction(
            context: context,
            food: food,
            restaurant: restaurant,
            state: customizationState,
            notifier: customizationNotifier,
          ),
        );
      },
    );
  }

  Widget _buildHeroImage(BuildContext context, FoodItem food) {
    return Stack(
      children: [
        SizedBox(
          height: 240,
          width: double.infinity,
          child: AppNetworkImage(imageUrl: food.imageUrl, fit: BoxFit.cover),
        ),
        // Gradient overlay
        Container(
          height: 240,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.4),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.15),
              ],
            ),
          ),
        ),
        // Floating Back Button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: CircleAvatar(
              backgroundColor: AppColors.surface.withValues(alpha: 0.9),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/');
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomizationGroupCard({
    required FoodCustomizationGroup group,
    required List<FoodCustomizationOption> selectedOptions,
    required ValueChanged<FoodCustomizationOption> onOptionSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  group.title,
                  style: AppTypography.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: group.isRequired
                      ? AppColors.primaryLight
                      : AppColors.surfaceVariant,
                  borderRadius: AppSpacing.roundedXs,
                ),
                child: Text(
                  group.isRequired ? 'REQUIRED' : 'OPTIONAL',
                  style: AppTypography.labelSmall.copyWith(
                    color: group.isRequired
                        ? AppColors.primaryDark
                        : AppColors.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...group.options.map((option) {
            final isSelected = selectedOptions.any((o) => o.id == option.id);

            return InkWell(
              onTap: () => onOptionSelected(option),
              borderRadius: AppSpacing.roundedMd,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                  horizontal: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    // Radio or Checkbox icon
                    Icon(
                      group.isMultiSelect
                          ? (isSelected
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded)
                          : (isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded),
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textMuted,
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        option.name,
                        style: AppTypography.bodyLarge.copyWith(
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (option.priceModifier > 0)
                      Text(
                        option.priceModifierFormatted,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSpecialInstructionsCard({
    required FoodCustomizationNotifier customizationNotifier,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Special instructions',
                  style: AppTypography.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _instructionsController,
            maxLines: 3,
            onChanged: (text) {
              customizationNotifier.setSpecialInstructions(text);
            },
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText:
                  'Add a note for the restaurant (e.g. less spicy, cutlery)...',
              hintStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: AppSpacing.roundedMd,
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdownCard(FoodCustomizationState state) {
    double addonsTotal = 0;
    for (final list in state.selectedOptions.values) {
      for (final option in list) {
        addonsTotal += option.priceModifier;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.5),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${state.foodItem.priceFormatted} base ${addonsTotal > 0 ? '+ ₹${addonsTotal.toInt()} add-ons' : ''}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '× ${state.quantity}',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                state.totalPriceFormatted,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomAction({
    required BuildContext context,
    required FoodItem food,
    required Restaurant? restaurant,
    required FoodCustomizationState state,
    required FoodCustomizationNotifier notifier,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [AppColors.shadowMd],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Quantity Selector (Minimum 1)
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppSpacing.roundedFull,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    borderRadius: AppSpacing.roundedFull,
                    onTap: state.quantity > 1
                        ? () => notifier.decrementQuantity()
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs + 2,
                      ),
                      child: Icon(
                        Icons.remove_rounded,
                        size: 18,
                        color: state.quantity > 1
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '${state.quantity}',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: AppSpacing.roundedFull,
                    onTap: () => notifier.incrementQuantity(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs + 2,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Dynamic "Add to Cart • ₹..." CTA button
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final cartConfig = notifier.toCartItemConfig(
                    restaurant: restaurant,
                  );
                  ref.read(cartProvider.notifier).addItem(cartConfig);

                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Added ${state.quantity}x ${food.name} to order (${state.totalPriceFormatted})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: AppColors.textPrimary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.roundedMd,
                      ),
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'VIEW CART',
                        textColor: AppColors.primary,
                        onPressed: () {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            context.push('/cart');
                          } else {
                            final navContext = AppRouter
                                .router
                                .routerDelegate
                                .navigatorKey
                                .currentContext;
                            if (navContext != null && navContext.mounted) {
                              ScaffoldMessenger.of(navContext)
                                  .hideCurrentSnackBar();
                              navContext.push('/cart');
                            } else {
                              AppRouter.router.push('/cart');
                            }
                          }
                        },
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textInverse,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.roundedFull,
                  ),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'Add to Cart • ${state.totalPriceFormatted}',
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

  Widget _buildDietaryIndicator(bool isVeg) {
    final color = isVeg ? AppColors.vegGreen : AppColors.nonVegRed;
    return Container(
      width: 14,
      height: 14,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: color,
          shape: isVeg ? BoxShape.circle : BoxShape.rectangle,
        ),
      ),
    );
  }
}
