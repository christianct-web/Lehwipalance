// lib/features/listing/widgets/sections/listing_type_info_sections.dart
import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/core/models/merchant_listing_model.dart';
import 'package:lehwipalancecustomerv1/modules/details/widgets/operating_hours_helper.dart';
import 'package:lehwipalancecustomerv1/theme/app_constants.dart';
import 'package:lehwipalancecustomerv1/theme/provider/theme_provider.dart';

import 'listing_event_prohibited_section.dart';
import 'listing_facility_section.dart';

class ListingEventInfo extends StatelessWidget {
  final MerchantListingDTO listing;
  const ListingEventInfo({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (listing.startDate != null)
          buildListingInfoRow(
            context,
            icon: Icons.calendar_today_outlined,
            label: LanguageConstants.date,
            value: formatDate(listing.startDate!),
          ),
        if (listing.ticketSummary != null)
          buildListingInfoRow(
            context,
            icon: Icons.confirmation_number_outlined,
            label: LanguageConstants.tickets,
            value:
                '${listing.ticketSummary!.availableTickets} ${LanguageConstants.available}'
                ' ${LanguageConstants.from} \$${listing.ticketSummary!.minPrice}',
          ),
        const ListingEventProhibitedSection(),
      ],
    );
  }
}

class ListingAccommodationInfo extends StatelessWidget {
  final MerchantListingDTO listing;
  const ListingAccommodationInfo({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildListingInfoRow(
          context,
          icon: Icons.bed_outlined,
          label: LanguageConstants.rooms,
          value: listing.roomSummary != null
              ? '${listing.roomSummary!.totalRooms} ${LanguageConstants.rooms}'
                    ' ${LanguageConstants.from} \$${listing.roomSummary!.minPrice}'
              : '${listing.roomIds?.length ?? 0} ${LanguageConstants.rooms}',
        ),
        if (listing.starRating != null)
          buildListingInfoRow(
            context,
            icon: Icons.star_outline_rounded,
            label: LanguageConstants.rating,
            value: '${listing.starRating} ★',
          ),
        if (listing.facilities.isNotEmpty == true)
          buildListingInfoRow(
            context,
            icon: Icons.room_service_outlined,
            label: LanguageConstants.facilities,
            value: listing.facilities.join(', '),
          ),
      ],
    );
  }
}

class ListingPlaceInfo extends StatelessWidget {
  final MerchantListingDTO listing;
  const ListingPlaceInfo({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (listing.entryFee != null)
          buildListingInfoRow(
            context,
            icon: Icons.payments_outlined,
            label: LanguageConstants.entryFee,
            value: listing.entryFee! > 0
                ? '\$${listing.entryFee!.toStringAsFixed(2)}'
                : LanguageConstants.free,
          ),
        if (listing.requiresBooking != null)
          buildListingInfoRow(
            context,
            icon: Icons.event_available_outlined,
            label: LanguageConstants.bookingRequired,
            value: listing.requiresBooking!
                ? LanguageConstants.yes
                : LanguageConstants.no,
          ),
        const ListingFacilitySection(),
      ],
    );
  }
}

class ListingServiceInfo extends StatelessWidget {
  final MerchantListingDTO listing;
  const ListingServiceInfo({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (listing.serviceTypeIds?.isNotEmpty == true)
          buildListingInfoRow(
            context,
            icon: Icons.build_outlined,
            label: LanguageConstants.servicesTab,
            value:
                '${listing.serviceTypeIds!.length} ${LanguageConstants.available}',
          ),
      ],
    );
  }
}

Widget buildListingInfoRow(
  BuildContext context, {
  required IconData icon,
  required String label,
  required String value,
}) {
  final colorScheme = context.colors;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: AppConstants.space2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: AppConstants.space5),
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: context.textStyles.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: context.textStyles.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
