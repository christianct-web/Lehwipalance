import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:lehwipalancecustomerv1/Providers/customer_provider.dart';
import 'package:lehwipalancecustomerv1/enum.dart';
import 'package:lehwipalancecustomerv1/modules/home/palance_widget.dart';
//import 'package:lehwipalancecustomerv1/core/router/route_paths.dart';
import 'package:lehwipalancecustomerv1/theme/provider/theme_provider.dart';

import 'package:lehwipalancecustomerv1/theme/app_constants.dart';

// ============================================================
// PALANCE LIST CARD (generic)
// ============================================================

class PalanceListCard extends StatefulWidget {
  final PalanceItem item;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;

  const PalanceListCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
  });

  @override
  State<PalanceListCard> createState() => _PalanceListCardState();
}

class _PalanceListCardState extends State<PalanceListCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  @override
  void didUpdateWidget(PalanceListCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      setState(() => _isFavorite = widget.isFavorite);
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.onFavoriteToggle != null) {
      widget.onFavoriteToggle!();
    } else {
      final userProvider = GetIt.I<CustomerProvider>();
      await userProvider.toggleFavorite(widget.item.type, widget.item.id);
      if (mounted) setState(() => _isFavorite = !_isFavorite);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textStyles;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingS,
      ),
      child: Stack(
        children: [
          Material(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
            elevation: AppConstants.elevationS,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(AppConstants.radiusXL),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 140,
                  maxHeight: 150,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left side - Image (40% width)
                    Expanded(
                      flex: 4,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(AppConstants.radiusXL),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            widget.item.imageUrl.isNotEmpty
                                ? Image.network(
                                    widget.item.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildPlaceholderIcon(colorScheme),
                                  )
                                : _buildPlaceholderIcon(colorScheme),

                            // Type badge
                            Positioned(
                              top: AppConstants.paddingS,
                              left: AppConstants.paddingS,
                              child: Container(
                                constraints: const BoxConstraints(minWidth: 40),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.space3,
                                  vertical: AppConstants.space1,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.item.type.color,
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.radiusM,
                                  ),
                                ),
                                child: Text(
                                  widget.item.type.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Right side - Content (60% width)
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.paddingM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Header with title
                            Flexible(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.item.title,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 44),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppConstants.space2),

                            // Date and Location section
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.item.date != null)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 12,
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                        const SizedBox(
                                          width: AppConstants.space2,
                                        ),
                                        Expanded(
                                          child: Text(
                                            _formatDate(widget.item.date!),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.8),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),

                                  const SizedBox(height: AppConstants.space1),

                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 12,
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: AppConstants.space2,
                                      ),
                                      Expanded(
                                        child: Text(
                                          widget.item.location,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.8),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppConstants.space2),

                            // Footer (Rating and Price)
                            Flexible(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          size: 14,
                                          color: colorScheme.tertiary,
                                        ),
                                        const SizedBox(
                                          width: AppConstants.space2,
                                        ),
                                        Text(
                                          widget.item.rating.toStringAsFixed(1),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: AppConstants.space3,
                                        ),
                                        if (widget.item.reviews > 0)
                                          Text(
                                            '(${widget.item.reviews})',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  _buildPriceStartingFrom(context),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Favorite button floating on top
          Positioned(
            top: AppConstants.paddingS,
            right: AppConstants.paddingS,
            child: _buildFavoriteButton(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon(ColorScheme colorScheme) {
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.event_outlined,
          size: 40,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildFavoriteButton(ColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleFavorite,
        borderRadius: BorderRadius.circular(AppConstants.radiusRound),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surface.withValues(alpha: 0.9),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite
                ? colorScheme.error
                : colorScheme.onSurfaceVariant,
            size: AppConstants.iconS,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  Widget _buildPriceStartingFrom(BuildContext context) {
    final colorScheme = context.colors;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          LanguageConstants.startingFrom,
          style: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 1. LARGE FEATURED CARD
// ============================================================

class PalanceLargeCard extends StatefulWidget {
  final PalanceItem item;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;

  const PalanceLargeCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
  });

  @override
  State<PalanceLargeCard> createState() => _PalanceLargeCardState();
}

class _PalanceLargeCardState extends State<PalanceLargeCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  @override
  void didUpdateWidget(PalanceLargeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      setState(() => _isFavorite = widget.isFavorite);
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.onFavoriteToggle != null) {
      widget.onFavoriteToggle!();
    } else {
      final userProvider = GetIt.I<CustomerProvider>();
      await userProvider.toggleFavorite(widget.item.type, widget.item.id);
      if (mounted) setState(() => _isFavorite = !_isFavorite);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textStyles;

    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        elevation: AppConstants.elevationM,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        ),
        margin: const EdgeInsets.only(bottom: AppConstants.paddingS),
        child: SizedBox(
          height: 260,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(colorScheme),

              // ✅ Gradient overlay uses colorScheme.scrim
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      colorScheme.scrim.withValues(alpha: 0.85),
                      colorScheme.scrim.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.space5,
                          vertical: AppConstants.space2,
                        ),
                        decoration: BoxDecoration(
                          color: widget.item.type.color,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusL,
                          ),
                        ),
                        child: Text(
                          widget.item.type.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.space4),
                      Text(
                        widget.item.title,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppConstants.space2),
                      Text(
                        widget.item.subtitle.isNotEmpty
                            ? widget.item.subtitle
                            : widget.item.location,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimary.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppConstants.space4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: AppConstants.iconS,
                            color: colorScheme.tertiaryContainer,
                          ),
                          const SizedBox(width: AppConstants.space2),
                          Text(
                            widget.item.rating.toStringAsFixed(1),
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppConstants.space4),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colorScheme.onPrimary.withValues(
                                alpha: 0.55,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppConstants.space4),
                          Icon(
                            Icons.people,
                            size: 14,
                            color: colorScheme.onPrimary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: AppConstants.space2),
                          Text(
                            _formatFollowers(widget.item.followers),
                            style: TextStyle(
                              color: colorScheme.onPrimary.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Favorite Button
              Positioned(
                top: AppConstants.space5,
                right: AppConstants.space5,
                child: _buildFavoriteButton(colorScheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(ColorScheme colorScheme) {
    if (widget.item.imageUrl.isNotEmpty) {
      return Image.network(
        widget.item.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholder(colorScheme),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return ColoredBox(
            color: colorScheme.surfaceContainerHighest,
            child: Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
          );
        },
      );
    }
    return _buildPlaceholder(colorScheme);
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: AppConstants.iconXL * 2,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildFavoriteButton(ColorScheme colorScheme) {
    return Material(
      color: colorScheme.scrim.withValues(alpha: 0.6),
      shape: const CircleBorder(),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusRound),
        onTap: _toggleFavorite,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingS),
          child: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? colorScheme.error : Colors.white,
            size: AppConstants.iconM,
          ),
        ),
      ),
    );
  }

  String _formatFollowers(int followers) {
    if (followers >= 1000000) {
      return '${(followers / 1000000).toStringAsFixed(1)}M';
    }
    if (followers >= 1000) {
      return '${(followers / 1000).toStringAsFixed(1)}K';
    }
    return followers.toString();
  }
}

// ============================================================
// 2. PALANCE GRID CARD
// ============================================================

class PalanceGridCard extends StatefulWidget {
  final PalanceItem item;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;

  const PalanceGridCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
  });

  @override
  State<PalanceGridCard> createState() => _PalanceGridCardState();
}

class _PalanceGridCardState extends State<PalanceGridCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  @override
  void didUpdateWidget(PalanceGridCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      setState(() => _isFavorite = widget.isFavorite);
    }
  }

  void _toggleFavorite() {
    widget.onFavoriteToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textStyles;
    final hasImage = widget.item.imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        elevation: AppConstants.elevationM,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        ),
        margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 160,
          height: 200,
          child: Stack(
            children: [
              _buildImage(colorScheme, hasImage),

              // Gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        colorScheme.scrim.withValues(alpha: 0.85),
                        colorScheme.scrim.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.item.title,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppConstants.space2),
                      _buildExtraInfo(colorScheme),
                      const SizedBox(height: AppConstants.space2),
                      _buildRatingAndFollowers(colorScheme),
                    ],
                  ),
                ),
              ),

              // Favorite button
              Positioned(
                top: AppConstants.paddingS,
                right: AppConstants.paddingS,
                child: _buildFavoriteButton(colorScheme),
              ),

              // Type badge
              Positioned(
                top: AppConstants.paddingS,
                left: AppConstants.paddingS,
                child: _buildTypeBadge(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(ColorScheme colorScheme, bool hasImage) {
    if (hasImage) {
      return Image.network(
        widget.item.imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholderImage(colorScheme),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return ColoredBox(
            color: colorScheme.surfaceContainerHighest,
            child: Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
          );
        },
      );
    }
    return _buildPlaceholderImage(colorScheme);
  }

  Widget _buildPlaceholderImage(ColorScheme colorScheme) {
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: AppConstants.iconXL * 2,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildExtraInfo(ColorScheme colorScheme) {
    if (widget.item.type == ListingType.event && widget.item.date != null) {
      return Row(
        children: [
          Icon(
            Icons.date_range,
            size: 14,
            color: colorScheme.onPrimary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: AppConstants.space3),
          Text(
            DateFormat('d/M/y').format(widget.item.date!),
            style: TextStyle(
              color: colorScheme.onPrimary.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      );
    } else if (widget.item.type == ListingType.place &&
        widget.item.openHour != null &&
        widget.item.closeHour != null) {
      return Row(
        children: [
          Icon(
            Icons.access_time,
            size: 14,
            color: colorScheme.onPrimary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: AppConstants.space3),
          Text(
            '${_formatTime(widget.item.openHour!)} - ${_formatTime(widget.item.closeHour!)}',
            style: TextStyle(
              color: colorScheme.onPrimary.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildRatingAndFollowers(ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(Icons.star, size: 14, color: colorScheme.tertiaryContainer),
        const SizedBox(width: AppConstants.space2),
        Text(
          '${widget.item.rating.toStringAsFixed(1)} (${widget.item.reviews})',
          style: TextStyle(
            color: colorScheme.onPrimary.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(width: AppConstants.space5),
        Icon(
          Icons.people,
          size: 14,
          color: colorScheme.onPrimary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: AppConstants.space2),
        Text(
          _formatFollowers(widget.item.followers),
          style: TextStyle(
            color: colorScheme.onPrimary.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteButton(ColorScheme colorScheme) {
    return Material(
      color: colorScheme.surface.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusRound),
        onTap: _toggleFavorite,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.space3),
          child: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite
                ? colorScheme.error
                : colorScheme.onSurfaceVariant,
            size: AppConstants.iconM,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingS,
        vertical: AppConstants.space2,
      ),
      decoration: BoxDecoration(
        color: widget.item.type.color,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        widget.item.type.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatFollowers(int followers) {
    if (followers >= 1000000) {
      return '${(followers / 1000000).toStringAsFixed(1)}M';
    } else if (followers >= 1000) {
      return '${(followers / 1000).toStringAsFixed(1)}K';
    }
    return followers.toString();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute $period";
  }
}
