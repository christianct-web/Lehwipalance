// lib/features/listing/widgets/tabs/listing_info_tab.dart
import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/Providers/merchant_detail_provider.dart';
import 'package:lehwipalancecustomerv1/core/models/merchant_listing_model.dart';
import 'package:lehwipalancecustomerv1/enum.dart';
import 'package:lehwipalancecustomerv1/modules/details/widgets/listing_collaborators_section.dart';
import 'package:lehwipalancecustomerv1/modules/details/widgets/listing_contact_block.dart';
import 'package:lehwipalancecustomerv1/modules/details/widgets/listing_detail_row.dart';
import 'package:lehwipalancecustomerv1/modules/details/widgets/listing_map_section.dart';
import 'package:lehwipalancecustomerv1/modules/details/widgets/listing_type_info_sections.dart';
import 'package:lehwipalancecustomerv1/modules/details/widgets/operating_hours_display.dart';
import 'package:lehwipalancecustomerv1/modules/details/widgets/operating_hours_helper.dart';
import 'package:lehwipalancecustomerv1/theme/app_constants.dart';

class ListingInfoTab extends StatelessWidget {
  final MerchantDetailProvider provider;
  final MerchantListingDTO listing;
  const ListingInfoTab({
    super.key,
    required this.provider,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          ListingDetailRow(
            icon: Icons.access_time_rounded,
            child: _buildDateInfo(context, listing),
          ),
          const SizedBox(height: 10),
          ListingMapSection(provider: provider),
          const SizedBox(height: 12),
          if (provider.cachedLocation != null)
            ListingDetailRow(
              icon: Icons.location_on_outlined,
              child: Text(
                provider.cachedLocation!.fullAddress,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (listing.placeCategories?.isNotEmpty == true)
            ListingDetailRow(
              icon: Icons.map_outlined,
              child: Text(
                listing.placeCategories!.values.map((c) => c.name).join(', '),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (listing.contactInfo != null) ...[
            Text(
              LanguageConstants.contactInfo,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            ListingContactBlock(provider: provider, listing: listing),
          ],
          const ListingCollaboratorsSection(),
          if (listing.isEvent) ...[
            const SizedBox(height: 8),
            ListingEventInfo(listing: listing),
          ],
          if (listing.isAccommodation) ...[
            const SizedBox(height: 8),
            ListingAccommodationInfo(listing: listing),
          ],
          if (listing.isPlace) ...[
            const SizedBox(height: 8),
            ListingPlaceInfo(listing: listing),
          ],
          if (listing.isService) ...[
            const SizedBox(height: 8),
            ListingServiceInfo(listing: listing),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDateInfo(BuildContext context, MerchantListingDTO listing) {
    final start = listing.startDate;
    final end = listing.endDate;

    if (start != null || end != null) {
      final startText = start != null ? formatDate(start) : null;
      final endText = end != null ? formatDate(end) : null;

      String dateText;
      if (startText != null && endText != null) {
        if (isSameDay(start!, end!)) {
          dateText = formatDateTime(start);
        } else {
          dateText = '$startText – $endText';
        }
      } else if (startText != null) {
        dateText = formatDateTime(start!);
      } else {
        dateText = endText!;
      }

      return buildListingInfoRow(
        context,
        icon: Icons.calendar_today_outlined,
        label: LanguageConstants.date,
        value: dateText,
      );
    }

    final dto = listing.operationalHours;

    if (dto == null || dto.openingHours.isEmpty) {
      return const OperatingHoursDisplay(
        status: 'Open 24 hours',
        hours: 'Open 24 hours',
        statusType: OperatingStatus.open,
      );
    }

    final now = DateTime.now();
    final todayHours = getTodayHours(dto.openingHours, now);

    if (todayHours == null || todayHours.is24Hours) {
      return OperatingHoursDisplay(
        status: 'Open 24 hours',
        hours: 'Open 24 hours',
        statusType: OperatingStatus.open,
        operationalHours: dto,
      );
    }

    if (todayHours.isClosed) {
      return OperatingHoursDisplay(
        status: 'Closed',
        hours: 'Closed today',
        statusType: OperatingStatus.closed,
        operationalHours: dto,
      );
    }

    final isOpen = isCurrentlyOpen(todayHours, now);
    final hoursText = formatOperatingHours(todayHours);

    if (hoursText == null) {
      return OperatingHoursDisplay(
        status: isOpen ? 'Open now' : 'Closed',
        hours: '',
        statusType: isOpen ? OperatingStatus.open : OperatingStatus.closed,
        operationalHours: dto,
      );
    }

    if (!isOpen) {
      return OperatingHoursDisplay(
        status: 'Closed',
        hours: hoursText,
        statusType: OperatingStatus.closed,
        operationalHours: dto,
      );
    }

    final closingSoon = isClosingSoon(todayHours, now);
    return OperatingHoursDisplay(
      status: closingSoon ? 'Closing soon' : 'Open now',
      hours: hoursText,
      statusType: closingSoon
          ? OperatingStatus.closingSoon
          : OperatingStatus.open,
      operationalHours: dto,
    );
  }
}
