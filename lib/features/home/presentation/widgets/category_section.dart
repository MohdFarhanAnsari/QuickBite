import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/section_header.dart';
import '../providers/home_providers.dart';
import 'category_chip.dart';

/// Horizontal cravings category bar with smooth scrolling and filter selection.
class CategorySection extends ConsumerWidget {
  const CategorySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final selectedCategoryId = ref.watch(selectedCategoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'What are you craving?',
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = selectedCategoryId == category.id;

              return CategoryChip(
                category: category,
                isSelected: isSelected,
                onTap: () {
                  ref
                      .read(selectedCategoryProvider.notifier)
                      .toggleCategory(category.id);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
