import 'package:flutter/material.dart';

import '../models/meditation.dart';
import '../theme.dart';

class TagFilterBar extends StatelessWidget {
  final List<Tag> tags;
  final String? activeSlug;
  final ValueChanged<String?> onTagSelected;

  const TagFilterBar({
    super.key,
    required this.tags,
    required this.activeSlug,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: activeSlug == null,
              onSelected: (_) => onTagSelected(null),
              selectedColor: AppColors.primary600,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: activeSlug == null ? Colors.white : AppColors.textMuted,
                fontSize: 13,
              ),
              backgroundColor: AppColors.bgCard,
              side: BorderSide(
                color: activeSlug == null
                    ? AppColors.primary500
                    : AppColors.borderSubtle,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          ...tags.map((tag) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(tag.name),
                  selected: activeSlug == tag.slug,
                  onSelected: (_) => onTagSelected(
                    activeSlug == tag.slug ? null : tag.slug,
                  ),
                  selectedColor: AppColors.primary600,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: activeSlug == tag.slug
                        ? Colors.white
                        : AppColors.textMuted,
                    fontSize: 13,
                  ),
                  backgroundColor: AppColors.bgCard,
                  side: BorderSide(
                    color: activeSlug == tag.slug
                        ? AppColors.primary500
                        : AppColors.borderSubtle,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
