// lib/features/listing/screens/listing_detail_sheet_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lehwipalancecustomerv1/core/models/merchant_listing_model.dart';
import 'package:lehwipalancecustomerv1/modules/details/screens/listing_media_tab.dart';
import 'package:lehwipalancecustomerv1/modules/details/screens/listing_reviews_tab.dart';
import 'package:lehwipalancecustomerv1/modules/details/widgets/listing_action_buttons.dart';
import 'package:lehwipalancecustomerv1/modules/details/widgets/listing_description_section.dart';
import 'package:lehwipalancecustomerv1/modules/details/widgets/listing_identity_section.dart';
import 'package:lehwipalancecustomerv1/modules/details/widgets/listing_info_tab.dart';
import 'package:lehwipalancecustomerv1/modules/details/widgets/listing_media_header.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'package:lehwipalancecustomerv1/Providers/merchant_detail_provider.dart';
import 'package:lehwipalancecustomerv1/core/models/common_models/media_model.dart';
import 'package:lehwipalancecustomerv1/theme/app_constants.dart';
import 'package:lehwipalancecustomerv1/theme/provider/theme_provider.dart';

class ListingDetailSheetScreen extends StatefulWidget {
  final String listingId;
  final VoidCallback? onDismissed;
  final int initialMediaIndex;

  const ListingDetailSheetScreen({
    super.key,
    required this.listingId,
    this.onDismissed,
    this.initialMediaIndex = 0,
  });

  @override
  State<ListingDetailSheetScreen> createState() =>
      _ListingDetailSheetScreenState();
}

class _ListingDetailSheetScreenState extends State<ListingDetailSheetScreen>
    with SingleTickerProviderStateMixin {
  late final MerchantDetailProvider _provider;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final PageController _mediaPageController;

  VideoPlayerController? _videoController;
  int _lastVideoIndex = -1;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: AppConstants.animSlow,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _mediaPageController = PageController(
      initialPage: widget.initialMediaIndex,
    );
    _provider = MerchantDetailProvider();

    _provider.loadListing(widget.listingId).then((_) {
      if (mounted) {
        _provider.setCurrentMediaIndex(widget.initialMediaIndex);
        _initializeVideoForIndex(widget.initialMediaIndex);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mediaPageController.dispose();
    _videoController?.dispose();
    _provider.dispose();
    super.dispose();
  }

  // ============================================================
  // VIDEO MANAGEMENT
  // ============================================================

  void _initializeVideoForIndex(int index) {
    final mediaItems = _provider.mediaItems;
    if (index < 0 || index >= mediaItems.length) return;

    final mediaItem = mediaItems[index];
    if (_lastVideoIndex == index && _videoController != null) return;

    _lastVideoIndex = index;
    _videoController?.dispose();
    _videoController = null;

    if (mediaItem.type != MediaType.video) {
      setState(() {});
      return;
    }

    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(mediaItem.url),
    );
    _videoController!
        .initialize()
        .then((_) {
          _videoController!.setLooping(true);
          if (_provider.isVideoPlaying) _videoController!.play();
          if (mounted) setState(() {});
        })
        .catchError((e) {
          debugPrint('[ListingDetailScreen] Video init error: $e');
        });
  }

  void _toggleVideoPlayback() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }

    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }

    _provider.toggleVideoPlayback();
    setState(() {});
  }

  void _onMediaPageChanged(int index) {
    _provider.setCurrentMediaIndex(index);
    _initializeVideoForIndex(index);
    setState(() {});
  }

  void _close() {
    if (context.canPop()) context.pop();
    widget.onDismissed?.call();
  }

  void _refreshHeader() => setState(() {});

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MerchantDetailProvider>.value(
      value: _provider,
      child: Consumer<MerchantDetailProvider>(
        builder: (context, provider, _) {
          return AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(opacity: _fadeAnimation.value, child: child);
            },
            child: _buildScreen(context, provider),
          );
        },
      ),
    );
  }

  Widget _buildScreen(BuildContext context, MerchantDetailProvider provider) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(top: false, child: _buildContent(context, provider)),
    );
  }

  Widget _buildContent(BuildContext context, MerchantDetailProvider provider) {
    final listing = provider.listing;

    if (provider.isLoading && listing == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.paddingXXL),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (provider.hasError && listing == null) {
      return _buildErrorState(context, provider);
    }

    if (listing == null) return _buildEmptyState(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ListingMediaHeader(
            provider: provider,
            pageController: _mediaPageController,
            videoController: _videoController,
            onClose: _close,
            onPageChanged: _onMediaPageChanged,
            onToggleVideoPlayback: _toggleVideoPlayback,
            onInitializeVideo: _refreshHeader,
          ),
        ),
        SliverToBoxAdapter(
          child: ListingIdentitySection(provider: provider, listing: listing),
        ),
        SliverToBoxAdapter(child: ListingDescriptionSection(listing: listing)),
        SliverToBoxAdapter(child: ListingActionButtons(provider: provider)),
        SliverToBoxAdapter(child: _buildTabs(context, provider)),
        SliverToBoxAdapter(child: _buildTabContent(context, provider, listing)),
        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs(BuildContext context, MerchantDetailProvider provider) {
    final theme = Theme.of(context);
    const tabs = [
      LanguageConstants.infoTab,
      LanguageConstants.mediaTab,
      LanguageConstants.reviewsTab,
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.7),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = ListingDetailTab.values[index];
          final selected = provider.selectedTab == tab;

          return Expanded(
            child: InkWell(
              onTap: () => provider.setSelectedTab(tab),
              child: SizedBox(
                height: 58,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? theme.colorScheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      tabs[index],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    MerchantDetailProvider provider,
    MerchantListingDTO listing,
  ) {
    switch (provider.selectedTab) {
      case ListingDetailTab.info:
        return ListingInfoTab(provider: provider, listing: listing);
      case ListingDetailTab.media:
        return ListingMediaTab(
          provider: provider,
          mediaPageController: _mediaPageController,
        );
      case ListingDetailTab.reviews:
        return ListingReviewsTab(provider: provider);
    }
  }

  // ============================================================
  // ERROR / EMPTY STATES
  // ============================================================

  Widget _buildErrorState(
    BuildContext context,
    MerchantDetailProvider provider,
  ) {
    final colorScheme = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: AppConstants.iconXL * 2,
              color: colorScheme.error,
            ),
            const SizedBox(height: AppConstants.paddingM),
            Text(
              provider.error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: context.textStyles.bodyLarge,
            ),
            const SizedBox(height: AppConstants.paddingL),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: _close,
                  child: const Text(LanguageConstants.close),
                ),
                const SizedBox(width: AppConstants.paddingM),
                FilledButton(
                  onPressed: provider.refresh,
                  child: const Text(LanguageConstants.retry),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: AppConstants.iconXL * 2,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppConstants.paddingM),
            Text(
              LanguageConstants.listingNotFound,
              style: context.textStyles.titleMedium,
            ),
            const SizedBox(height: AppConstants.paddingM),
            OutlinedButton(
              onPressed: _close,
              child: const Text(LanguageConstants.close),
            ),
          ],
        ),
      ),
    );
  }
}
