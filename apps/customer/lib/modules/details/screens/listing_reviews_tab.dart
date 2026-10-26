// lib/features/listing/widgets/tabs/listing_reviews_tab.dart
import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/Providers/merchant_detail_provider.dart';
import 'package:lehwipalancecustomerv1/theme/app_constants.dart';
import 'package:lehwipalancecustomerv1/theme/provider/theme_provider.dart';

class ListingReviewsTab extends StatelessWidget {
  final MerchantDetailProvider provider;
  const ListingReviewsTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final rating = provider.averageRating ?? 0;
    final reviews = provider.totalReviews ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star_rounded,
                color: colorScheme.tertiary,
                size: AppConstants.iconL,
              ),
              const SizedBox(width: AppConstants.paddingS),
              Text(
                rating > 0 ? rating.toStringAsFixed(1) : '—',
                style: context.textStyles.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: AppConstants.space3),
              Text(
                reviews > 0
                    ? '($reviews ${LanguageConstants.reviews})'
                    : LanguageConstants.noReviewsYet,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingL),
          ..._buildRatingBars(context),
          const SizedBox(height: AppConstants.paddingL),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => provider.handleWriteReview(context),
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text(LanguageConstants.writeReview),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRatingBars(BuildContext context) {
    const ratings = [
      ('5', 0.60),
      ('4', 0.25),
      ('3', 0.10),
      ('2', 0.03),
      ('1', 0.02),
    ];

    return ratings.map((rating) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.space1),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: Text(rating.$1, style: context.textStyles.bodySmall),
            ),
            const SizedBox(width: AppConstants.paddingS),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.radiusXS),
                child: LinearProgressIndicator(
                  value: rating.$2,
                  minHeight: 7,
                  backgroundColor: context.colors.surfaceContainerHighest,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
