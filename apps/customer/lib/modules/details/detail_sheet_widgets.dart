import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lehwipalancecustomerv1/Providers/merchant_listing_provider.dart';
import 'package:lehwipalancecustomerv1/core/base/service_locator.dart';
import 'package:lehwipalancecustomerv1/core/models/common_models/opening_hour_model.dart';
import 'package:lehwipalancecustomerv1/core/models/merchant_listing_model.dart';
import 'package:lehwipalancecustomerv1/core/models/venue_model.dart';
import 'package:lehwipalancecustomerv1/core/utils/logutil.dart';
import 'package:lehwipalancecustomerv1/enum.dart';
import 'package:url_launcher/url_launcher.dart';

class InteractionService extends ChangeNotifier {
  // ignore: unused_field
  final Map<String, bool> _likedListings = {};
  // ignore: unused_field
  final Map<String, bool> _savedListings = {};

  // Track likes and saves per user
  final Map<String, Set<String>> _userLikes = {};
  final Map<String, Set<String>> _userSaves = {};

  bool isLiked(String listingId, String userId) {
    return _userLikes[userId]?.contains(listingId) ?? false;
  }

  bool isSaved(String listingId, String userId) {
    return _userSaves[userId]?.contains(listingId) ?? false;
  }

  void toggleLike(String listingId, String userId, Function(int) updateStats) {
    final userLikesSet = _userLikes.putIfAbsent(userId, () => {});

    if (userLikesSet.contains(listingId)) {
      userLikesSet.remove(listingId);
      updateStats(-1);
    } else {
      userLikesSet.add(listingId);
      updateStats(1);
    }

    notifyListeners();
  }

  void toggleSave(String listingId, String userId, Function(int) updateStats) {
    final userSavesSet = _userSaves.putIfAbsent(userId, () => {});

    if (userSavesSet.contains(listingId)) {
      userSavesSet.remove(listingId);
      updateStats(-1);
    } else {
      userSavesSet.add(listingId);
      updateStats(1);
    }

    notifyListeners();
  }

  void clearUserInteractions(String userId) {
    _userLikes.remove(userId);
    _userSaves.remove(userId);
    notifyListeners();
  }
}

class BottomActionSheet extends StatefulWidget {
  final MerchantListingDTO listing;

  const BottomActionSheet({super.key, required this.listing});

  @override
  State<BottomActionSheet> createState() => _BottomActionSheetState();
}

class _BottomActionSheetState extends State<BottomActionSheet> {
  LocationModel? _cachedLocation;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final provider = getIt<MerchantListingProvider>();

    // Check if location is already cached
    final cached = provider.getCachedLocation(widget.listing);
    if (cached != null) {
      setState(() {
        _cachedLocation = cached;
      });
      return;
    }

    // Load location from API if not cached
    if (widget.listing.locationid.isNotEmpty) {
      setState(() => _isLoadingLocation = true);
      try {
        final location = await provider.getLocationForListing(widget.listing);
        if (mounted) {
          setState(() {
            _cachedLocation = location;
            _isLoadingLocation = false;
          });
        }
      } catch (e) {
        AppLogger.error('Failed to load location: $e');
        if (mounted) {
          setState(() => _isLoadingLocation = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _cachedLocation != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      widget.listing.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Event Date
                    if (widget.listing.type == ListingType.event &&
                        widget.listing.startDate != null) ...[
                      _buildInfoRow(
                        context,
                        Icons.calendar_today,
                        'Date',
                        '${DateFormat('MMM dd, yyyy').format(widget.listing.startDate!)} - ${DateFormat('MMM dd, yyyy').format(widget.listing.endDate!)}',
                      ),
                    ],

                    // Operating Hours
                    if (widget.listing.operationalHours != null) ...[
                      _buildInfoRow(
                        context,
                        Icons.access_time,
                        'Hours',
                        'Tap to view hours',
                        onTap: () => _showHoursDialog(context),
                        isClickable: true,
                      ),
                    ],

                    // ✅ FIXED: Location using cached location
                    if (_isLoadingLocation) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Loading location...'),
                          ],
                        ),
                      ),
                    ] else if (hasLocation) ...[
                      _buildInfoRow(
                        context,
                        Icons.location_on,
                        'Location',
                        _cachedLocation!.fullAddress,
                      ),
                    ] else if (widget.listing.locationid.isNotEmpty) ...[
                      _buildInfoRow(
                        context,
                        Icons.location_on_outlined,
                        'Location ID',
                        widget.listing.locationid,
                      ),
                    ],

                    // Contact Information
                    if (widget.listing.contactInfo != null) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Contact Information',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (widget.listing.contactInfo!.phone != null &&
                          widget.listing.contactInfo!.phone!.isNotEmpty)
                        _buildContactTile(
                          context,
                          Icons.phone,
                          widget.listing.contactInfo!.phone!,
                          'Call',
                          () => _makePhoneCall(
                            widget.listing.contactInfo!.phone!,
                          ),
                        ),
                      if (widget.listing.contactInfo!.email.isNotEmpty)
                        _buildContactTile(
                          context,
                          Icons.email,
                          widget.listing.contactInfo!.email,
                          'Email',
                          () => _sendEmail(widget.listing.contactInfo!.email),
                        ),
                      if (widget.listing.contactInfo!.website != null &&
                          widget.listing.contactInfo!.website!.isNotEmpty)
                        _buildContactTile(
                          context,
                          Icons.language,
                          widget.listing.contactInfo!.website!,
                          'Visit',
                          () => _openWebsite(
                            widget.listing.contactInfo!.website!,
                          ),
                        ),
                    ],

                    const Divider(),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.listing.description ?? 'No description available',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),

                    // More Photos
                    if (widget.listing.mediaUrls.imageUrls.isNotEmpty) ...[
                      Text(
                        'More Photos',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.listing.mediaUrls.imageUrls.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl:
                                      widget.listing.mediaUrls.imageUrls[index],
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 120,
                                    height: 120,
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        width: 120,
                                        height: 120,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.error),
                                      ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
    bool isClickable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                value,
                style: TextStyle(
                  color: isClickable ? Colors.blue : null,
                  decoration: isClickable ? TextDecoration.underline : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(
    BuildContext context,
    IconData icon,
    String value,
    String action,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
          ElevatedButton(onPressed: onPressed, child: Text(action)),
        ],
      ),
    );
  }

  void _showHoursDialog(BuildContext context) {
    if (widget.listing.operationalHours == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Operating Hours',
                    style: Theme.of(dialogContext).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: OperationalHoursWidget(
                    operationalHours: widget.listing.operationalHours,
                    showTitle: false,
                    isExpanded: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== CONTACT ACTION METHODS ====================

  Future<void> _makePhoneCall(String phone) async {
    final url = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        _showSnackBar('Could not make call to $phone');
      }
    } catch (e) {
      AppLogger.error('Error making phone call: $e');
      _showSnackBar('Could not make call');
    }
  }

  Future<void> _sendEmail(String email) async {
    final url = Uri.parse('mailto:$email');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        _showSnackBar('Could not send email to $email');
      }
    } catch (e) {
      AppLogger.error('Error sending email: $e');
      _showSnackBar('Could not send email');
    }
  }

  Future<void> _openWebsite(String website) async {
    String urlString = website;
    if (!website.startsWith('http://') && !website.startsWith('https://')) {
      urlString = 'https://$website';
    }

    final url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not open website');
      }
    } catch (e) {
      AppLogger.error('Error opening website: $e');
      _showSnackBar('Could not open website');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }
}

class OperationalHoursWidget extends StatelessWidget {
  final OperationalHoursDTO? operationalHours;
  final bool showTitle;
  final bool isExpanded;

  const OperationalHoursWidget({
    super.key,
    required this.operationalHours,
    this.showTitle = true,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    if (operationalHours == null || operationalHours!.openingHours.isEmpty) {
      return const SizedBox.shrink();
    }

    final uiModel = OperationalHoursUIModel.fromDTO(operationalHours!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTitle)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Operating Hours',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        // Current status indicator
        _buildCurrentStatus(context, uiModel),
        const SizedBox(height: 16),

        // Regular weekly hours
        if (uiModel.weeklyHours.isNotEmpty) ...[
          Text(
            'Weekly Schedule',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildWeeklyHours(context, uiModel.weeklyHours),
          const SizedBox(height: 16),
        ],

        // Special hours (overrides)
        if (uiModel.specialHours.isNotEmpty) ...[
          Text(
            'Special Hours',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          ...uiModel.specialHours.map(
            (special) => _buildSpecialHoursTile(context, special),
          ),
        ],
      ],
    );
  }

  Widget _buildWeeklyHours(
    BuildContext context,
    Map<Weekday, DayHoursUIModel> weeklyHours,
  ) {
    final weekdays = Weekday.values;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: weekdays.map((weekday) {
          final hours = weeklyHours[weekday];
          return _buildWeeklyHoursTile(context, weekday, hours);
        }).toList(),
      ),
    );
  }

  Widget _buildWeeklyHoursTile(
    BuildContext context,
    Weekday weekday,
    DayHoursUIModel? hours,
  ) {
    final dayName = _formatWeekday(weekday);
    String displayText;
    Color? textColor;

    if (hours == null) {
      displayText = 'Not specified';
      textColor = Colors.grey;
    } else if (hours.isClosed) {
      displayText = 'Closed';
      textColor = Colors.red;
    } else if (hours.is24Hours) {
      displayText = 'Open 24 hours';
      textColor = Colors.green;
    } else {
      displayText = hours.displayText;
      textColor = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              dayName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              displayText,
              textAlign: TextAlign.end,
              style: TextStyle(color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialHoursTile(
    BuildContext context,
    SpecialDayHoursUIModel special,
  ) {
    Color? textColor;
    String displayText = special.displayText;

    if (special.isClosed) {
      textColor = Colors.red;
    } else if (special.is24Hours) {
      textColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            special.label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            displayText,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatus(
    BuildContext context,
    OperationalHoursUIModel uiModel,
  ) {
    final now = DateTime.now();
    final currentHours = _getCurrentHours(uiModel, now);
    final isOpen = _isCurrentlyOpen(currentHours, now);

    String statusText = isOpen ? 'Open Now' : 'Closed Now';
    String? subText;

    if (isOpen && currentHours != null && !currentHours.is24Hours) {
      subText = 'Closes ${_formatTimeOnly(currentHours.closesAt!)}';
    } else if (!isOpen && currentHours != null && !currentHours.isClosed) {
      subText = 'Opens ${_getNextOpenTime(uiModel, now)}';
    } else if (!isOpen && currentHours?.isClosed == true) {
      subText = 'Closed today';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOpen
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isOpen ? Colors.green : Colors.red, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            isOpen ? Icons.check_circle : Icons.cancel,
            color: isOpen ? Colors.green : Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isOpen ? Colors.green : Colors.red,
                  ),
                ),
                if (subText != null)
                  Text(subText, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  OpeningHourModel? _getCurrentHours(
    OperationalHoursUIModel uiModel,
    DateTime now,
  ) {
    // Check special hours first
    for (final special in uiModel.specialHours) {
      if (special.date.year == now.year &&
          special.date.month == now.month &&
          special.date.day == now.day) {
        return operationalHours!.openingHours.firstWhere(
          (h) =>
              h.date != null &&
              h.date!.year == now.year &&
              h.date!.month == now.month &&
              h.date!.day == now.day,
          orElse: () => throw Exception('Special hours not found'),
        );
      }
    }

    // Check regular weekly hours
    final weekday = Weekday.values[now.weekday - 1];
    final hours = uiModel.weeklyHours[weekday];

    if (hours != null) {
      return operationalHours!.openingHours.firstWhere(
        (h) => h.weekday == weekday,
        orElse: () => throw Exception('Weekly hours not found'),
      );
    }

    return null;
  }

  bool _isCurrentlyOpen(OpeningHourModel? hours, DateTime now) {
    if (hours == null) return false;
    if (hours.isClosed) return false;
    if (hours.is24Hours) return true;

    final openTime = TimeOfDay.fromDateTime(hours.opensAt!);
    final closeTime = TimeOfDay.fromDateTime(hours.closesAt!);
    final currentTime = TimeOfDay.fromDateTime(now);

    // Handle overnight hours (e.g., 8 PM to 2 AM)
    if (closeTime.hour < openTime.hour ||
        (closeTime.hour == openTime.hour &&
            closeTime.minute < openTime.minute)) {
      return currentTime.hour >= openTime.hour ||
          currentTime.hour < closeTime.hour;
    }

    return currentTime.hour >= openTime.hour &&
        currentTime.hour < closeTime.hour;
  }

  String _getNextOpenTime(OperationalHoursUIModel uiModel, DateTime now) {
    for (int i = 1; i <= 7; i++) {
      final checkDate = now.add(Duration(days: i));
      final checkWeekday = Weekday.values[checkDate.weekday - 1];

      // Check special hours first
      bool hasSpecial = false;
      for (final special in uiModel.specialHours) {
        if (special.date.year == checkDate.year &&
            special.date.month == checkDate.month &&
            special.date.day == checkDate.day) {
          hasSpecial = true;
          if (!special.isClosed) {
            return DateFormat('MMM d').format(checkDate);
          }
          break;
        }
      }

      if (!hasSpecial) {
        final hours = uiModel.weeklyHours[checkWeekday];
        if (hours != null && !hours.isClosed) {
          return DateFormat('MMM d').format(checkDate);
        }
      }
    }

    return 'Unknown';
  }

  String _formatWeekday(Weekday weekday) {
    switch (weekday) {
      case Weekday.monday:
        return 'Monday';
      case Weekday.tuesday:
        return 'Tuesday';
      case Weekday.wednesday:
        return 'Wednesday';
      case Weekday.thursday:
        return 'Thursday';
      case Weekday.friday:
        return 'Friday';
      case Weekday.saturday:
        return 'Saturday';
      case Weekday.sunday:
        return 'Sunday';
    }
  }

  String _formatTimeOnly(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }
}
