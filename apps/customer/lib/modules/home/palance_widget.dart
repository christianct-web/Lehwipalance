import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
// TODO: replace withValues(alpha:) instead of withValues(alpha: ) for consistency
import 'package:lehwipalancecustomerv1/Providers/merchant_listing_provider.dart';
import 'package:lehwipalancecustomerv1/core/base/service_locator.dart';
import 'package:lehwipalancecustomerv1/core/models/merchant_listing_model.dart';
import 'package:lehwipalancecustomerv1/core/utils/logutil.dart';
import 'package:lehwipalancecustomerv1/enum.dart';
import 'package:lehwipalancecustomerv1/modules/home/new_widgets.dart';
import 'package:lehwipalancecustomerv1/theme/provider/theme_provider.dart';

// ============================================================
// NEW CARD WIDGETS
// ============================================================

// 2. EVENT CARD
class PalanceEventCard extends StatefulWidget {
  final PalanceItem item;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;

  const PalanceEventCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
  });

  @override
  State<PalanceEventCard> createState() => _PalanceEventCardState();
}

class _PalanceEventCardState extends State<PalanceEventCard> {
  late ThemeProvider _themeProvider;
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _themeProvider = GetIt.instance<ThemeProvider>();
    _isFavorite = widget.isFavorite;
  }

  @override
  void didUpdateWidget(PalanceEventCard oldWidget) {
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
    final colorScheme = _themeProvider.colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = _themeProvider.isDarkMode;

    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        elevation: isDark ? 2 : 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDark ? colorScheme.surface : Colors.white,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              children: [
                _buildImage(),

                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.black.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),

                // Date Badge
                if (widget.item.date != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getDay(widget.item.date!),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            _getMonth(widget.item.date!),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Content
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.item.title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.item.location,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (widget.item.followers > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.people,
                                size: 12,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_formatNumber(widget.item.followers)} interested',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Favorite Button
                Positioned(top: 12, right: 12, child: _buildFavoriteButton()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.item.imageUrl.isNotEmpty) {
      return Image.network(
        widget.item.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: _themeProvider.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.event,
          size: 50,
          color: _themeProvider.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _toggleFavorite,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.red : Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  String _getDay(DateTime date) => date.day.toString();
  String _getMonth(DateTime date) => DateFormat('MMM').format(date);
  String _formatNumber(int number) {
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }
}

// 3. HOTEL CARD
class PalanceHotelCard extends StatefulWidget {
  final PalanceItem item;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;

  const PalanceHotelCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
  });

  @override
  State<PalanceHotelCard> createState() => _PalanceHotelCardState();
}

class _PalanceHotelCardState extends State<PalanceHotelCard> {
  late ThemeProvider _themeProvider;
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _themeProvider = GetIt.instance<ThemeProvider>();
    _isFavorite = widget.isFavorite;
  }

  @override
  void didUpdateWidget(PalanceHotelCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      setState(() => _isFavorite = widget.isFavorite);
    }
  }

  void _toggleFavorite() async {
    if (widget.onFavoriteToggle != null) {
      widget.onFavoriteToggle!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = _themeProvider.colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = _themeProvider.isDarkMode;

    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        elevation: isDark ? 2 : 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDark ? colorScheme.surface : Colors.white,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 180,
            height: 220,
            child: Stack(
              children: [
                _buildImage(),

                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.black.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),

                // Price Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          widget.item.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Content
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.item.title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.item.location,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'From \$${(widget.item.rating * 50).toStringAsFixed(0)}/night',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'DEAL',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Favorite Button
                Positioned(top: 12, right: 12, child: _buildFavoriteButton()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.item.imageUrl.isNotEmpty) {
      return Image.network(
        widget.item.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: _themeProvider.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.hotel,
          size: 50,
          color: _themeProvider.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _toggleFavorite,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.red : Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

// 4. EVENT LIST CARD
class PalanceEventListCard extends StatefulWidget {
  final PalanceItem item;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;

  const PalanceEventListCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
  });

  @override
  State<PalanceEventListCard> createState() => _PalanceEventListCardState();
}

class _PalanceEventListCardState extends State<PalanceEventListCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  @override
  void didUpdateWidget(PalanceEventListCard oldWidget) {
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: widget.item.imageUrl.isNotEmpty
                      ? Image.network(
                          widget.item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.event, size: 30),
                          ),
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.event, size: 30),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.item.title,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: _toggleFavorite,
                          icon: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : null,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (widget.item.date != null)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat(
                              'EEE, MMM d, yyyy',
                            ).format(widget.item.date!),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.item.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (widget.item.followers > 0) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatNumber(widget.item.followers)} interested',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }
}

// 5. PLACE LIST CARD
class PalancePlaceListCard extends StatefulWidget {
  final PalanceItem item;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;

  const PalancePlaceListCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
  });

  @override
  State<PalancePlaceListCard> createState() => _PalancePlaceListCardState();
}

class _PalancePlaceListCardState extends State<PalancePlaceListCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  @override
  void didUpdateWidget(PalancePlaceListCard oldWidget) {
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: widget.item.imageUrl.isNotEmpty
                      ? Image.network(
                          widget.item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.place, size: 30),
                          ),
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.place, size: 30),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.item.title,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: _toggleFavorite,
                          icon: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : null,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          widget.item.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${widget.item.reviews} reviews)',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.item.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (widget.item.openHour != null &&
                        widget.item.closeHour != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatTime(widget.item.openHour!)} - ${_formatTime(widget.item.closeHour!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:${time.minute.toString().padLeft(2, '0')} $period";
  }
}

// 6. HOTEL LIST CARD
class PalanceHotelListCard extends StatefulWidget {
  final PalanceItem item;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;

  const PalanceHotelListCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
  });

  @override
  State<PalanceHotelListCard> createState() => _PalanceHotelListCardState();
}

class _PalanceHotelListCardState extends State<PalanceHotelListCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  @override
  void didUpdateWidget(PalanceHotelListCard oldWidget) {
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: widget.item.imageUrl.isNotEmpty
                      ? Image.network(
                          widget.item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.hotel, size: 30),
                          ),
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.hotel, size: 30),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.item.title,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: _toggleFavorite,
                          icon: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : null,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          widget.item.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${widget.item.reviews} reviews)',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.item.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'From \$${(widget.item.rating * 50).toStringAsFixed(0)}/night',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (widget.item.followers > 100)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Popular',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 7. SERVICE GRID CARD
class PalanceServiceGridCard extends StatefulWidget {
  final PalanceItem item;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;

  const PalanceServiceGridCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
  });

  @override
  State<PalanceServiceGridCard> createState() => _PalanceServiceGridCardState();
}

class _PalanceServiceGridCardState extends State<PalanceServiceGridCard> {
  late ThemeProvider _themeProvider;
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _themeProvider = GetIt.instance<ThemeProvider>();
    _isFavorite = widget.isFavorite;
  }

  @override
  void didUpdateWidget(PalanceServiceGridCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      setState(() => _isFavorite = widget.isFavorite);
    }
  }

  void _toggleFavorite() async {
    if (widget.onFavoriteToggle != null) {
      widget.onFavoriteToggle!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = _themeProvider.colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = _themeProvider.isDarkMode;

    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        elevation: isDark ? 2 : 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDark ? colorScheme.surface : Colors.white,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                _buildImage(),

                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.black.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),

                // Content
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.item.title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.amber[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.item.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: Colors.white54,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.people, size: 12, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              _formatNumber(widget.item.followers),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Category Badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: widget.item.type.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getCategoryLabel(widget.item),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Favorite Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: const CircleBorder(),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _toggleFavorite,
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.item.imageUrl.isNotEmpty) {
      return Image.network(
        widget.item.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: _themeProvider.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.handyman,
          size: 40,
          color: _themeProvider.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  String _getCategoryLabel(PalanceItem item) {
    switch (item.type) {
      case ListingType.event:
        return 'Event';
      case ListingType.place:
        return 'Place';
      case ListingType.hotel:
        return 'Hotel';
      case ListingType.service:
        return 'Service';
      case ListingType.store:
        return 'Store';
      case ListingType.vacation:
        return 'Vacation';
    }
  }
}

class ListingSection extends StatelessWidget {
  final String title;
  final List<PalanceItem> items;
  final VoidCallback onViewAll;
  final void Function(PalanceItem item) onFavoriteToggle;

  const ListingSection({
    super.key,
    required this.title,
    required this.items,
    required this.onViewAll,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(onPressed: onViewAll, child: const Text("View all")),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];

              return SizedBox(
                width: 160,
                child: PalanceGridCard(
                  item: item,
                  onTap: () => _navigateToDetails(context, item),
                  onFavoriteToggle: () => onFavoriteToggle(item),
                  isFavorite: item.isFavorite,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToDetails(BuildContext context, PalanceItem item) {
    context.push('/home/listing/${item.id}');
  }
}

class PalanceItem {
  final String id; // Firestore document ID
  final String itemID; // The actual entity ID (event, organizer, etc.)
  final String title;
  final String subtitle;
  final String imageUrl;
  final bool isFavorite;
  final String location; // for all types
  final int followers;
  final ListingType type;
  final double rating; //not for events
  final int reviews; //not for events
  final DateTime? date; // for events
  // finl bool isOpen; // for places
  final TimeOfDay? openHour; // for places
  final TimeOfDay? closeHour; // for places

  PalanceItem({
    required this.id,
    required this.itemID,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.rating,
    required this.reviews,
    required this.followers,
    required this.type,
    this.isFavorite = false,
    this.date,
    this.openHour,
    this.closeHour,
    required this.location,
  });

  PalanceItem copyWith({
    bool? isFavorite,
    DateTime? date,
    TimeOfDay? openHour,
    TimeOfDay? closeHour,
  }) {
    return PalanceItem(
      id: id,
      itemID: itemID,
      title: title,
      subtitle: subtitle,
      imageUrl: imageUrl,
      rating: rating,
      reviews: reviews,
      followers: followers,
      type: type,
      location: location,
      isFavorite: isFavorite ?? this.isFavorite,
      date: date ?? this.date,
      openHour: openHour ?? this.openHour,
      closeHour: closeHour ?? this.closeHour,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'itemID': itemID,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviews': reviews,
      'followers': followers,
      'type': type.name,
      'isFavorite': isFavorite,
      'date': date?.millisecondsSinceEpoch,
      'openHour': openHour != null
          ? '${openHour!.hour}:${openHour!.minute}'
          : null,
      'closeHour': closeHour != null
          ? '${closeHour!.hour}:${closeHour!.minute}'
          : null,
    };
  }

  /// ✅ FIXED: Convert from DTO using provider for location
  static Future<PalanceItem> fromDTOAsync(
    MerchantListingDTO dto, [
    MerchantListingProvider? provider,
  ]) async {
    final palanceProvider = provider ?? getIt<MerchantListingProvider>();

    // Get location from cache or load it
    String locationText = 'Unknown';
    final cached = palanceProvider.getCachedLocation(dto);
    if (cached != null) {
      locationText = cached.fullAddress;
    } else if (dto.locationid.isNotEmpty) {
      try {
        final location = await palanceProvider.getLocationForListing(dto);
        if (location != null) {
          locationText = location.fullAddress;
        }
      } catch (e) {
        AppLogger.error('Failed to load location for PalanceItem: $e');
      }
    }

    return PalanceItem(
      id: dto.id,
      itemID: dto.id,
      title: dto.title,
      subtitle: dto.description ?? '',
      imageUrl: dto.mediaUrls.mainImageUrl,
      rating: dto.stats.revenue / 100000,
      reviews: dto.stats.totalSales,
      followers: dto.stats.saves,
      type: dto.type,
      location: locationText,
    );
  }

  /// ✅ FIXED: Synchronous conversion (uses cached location only)
  static PalanceItem fromDTOSync(
    MerchantListingDTO dto, [
    MerchantListingProvider? provider,
  ]) {
    final palanceProvider = provider ?? getIt<MerchantListingProvider>();

    String locationText = 'Unknown';
    final cached = palanceProvider.getCachedLocation(dto);
    if (cached != null) {
      locationText = cached.fullAddress;
    } else if (dto.locationid.isNotEmpty) {
      locationText = 'Location ID: ${dto.locationid}';
    }

    return PalanceItem(
      id: dto.id,
      itemID: dto.id,
      title: dto.title,
      subtitle: dto.description ?? '',
      imageUrl: dto.mediaUrls.mainImageUrl,
      rating: dto.stats.revenue / 100000,
      reviews: dto.stats.totalSales,
      followers: dto.stats.saves,
      type: dto.type,
      location: locationText,
    );
  }
}

// ==================== HELPER FUNCTION ====================

/// ✅ FIXED: Map to PalanceItem using provider
PalanceItem mapToPalanceItem(
  MerchantListingDTO dto, [
  MerchantListingProvider? provider,
]) {
  final palanceProvider = provider ?? getIt<MerchantListingProvider>();

  String locationText = 'Unknown';
  final cached = palanceProvider.getCachedLocation(dto);
  if (cached != null) {
    locationText = cached.fullAddress;
  } else if (dto.locationid.isNotEmpty) {
    locationText = 'Location ID: ${dto.locationid}';
  }

  return PalanceItem(
    id: dto.id,
    itemID: dto.id,
    title: dto.title,
    subtitle: dto.description ?? '',
    imageUrl: dto.mediaUrls.mainImageUrl,
    rating: dto.stats.revenue / 100000, // placeholder logic
    reviews: dto.stats.totalSales,
    followers: dto.stats.saves,
    type: dto.type,
    location: locationText,
  );
}

/// ✅ FIXED: Async version that loads location if not cached
Future<PalanceItem> mapToPalanceItemAsync(
  MerchantListingDTO dto, [
  MerchantListingProvider? provider,
]) async {
  final palanceProvider = provider ?? getIt<MerchantListingProvider>();

  String locationText = 'Unknown';
  final cached = palanceProvider.getCachedLocation(dto);
  if (cached != null) {
    locationText = cached.fullAddress;
  } else if (dto.locationid.isNotEmpty) {
    try {
      final location = await palanceProvider.getLocationForListing(dto);
      if (location != null) {
        locationText = location.fullAddress;
      }
    } catch (e) {
      AppLogger.error('Failed to load location: $e');
    }
  }

  return PalanceItem(
    id: dto.id,
    itemID: dto.id,
    title: dto.title,
    subtitle: dto.description ?? '',
    imageUrl: dto.mediaUrls.mainImageUrl,
    rating: dto.stats.revenue / 100000,
    reviews: dto.stats.totalSales,
    followers: dto.stats.saves,
    type: dto.type,
    location: locationText,
  );
}

/// ✅ FIXED: Batch conversion with preloaded locations
Future<List<PalanceItem>> mapListingsToPalanceItemsAsync(
  List<MerchantListingDTO> listings, [
  MerchantListingProvider? provider,
]) async {
  final palanceProvider = provider ?? getIt<MerchantListingProvider>();

  final items = <PalanceItem>[];
  for (final dto in listings) {
    items.add(await mapToPalanceItemAsync(dto, palanceProvider));
  }
  return items;
}

/// ✅ FIXED: Batch conversion (synchronous)
List<PalanceItem> mapListingsToPalanceItemsSync(
  List<MerchantListingDTO> listings, [
  MerchantListingProvider? provider,
]) {
  final palanceProvider = provider ?? getIt<MerchantListingProvider>();
  return listings.map((dto) => mapToPalanceItem(dto, palanceProvider)).toList();
}
