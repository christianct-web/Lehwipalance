// lib/features/listing/widgets/sections/listing_contact_block.dart
import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/Providers/merchant_detail_provider.dart';
import 'package:lehwipalancecustomerv1/core/models/merchant_listing_model.dart';
import 'package:lehwipalancecustomerv1/theme/provider/theme_provider.dart';

class ListingContactBlock extends StatelessWidget {
  final MerchantDetailProvider provider;
  final MerchantListingDTO listing;
  const ListingContactBlock({
    super.key,
    required this.provider,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final contact = listing.contactInfo!;

    return Column(
      children: [
        if (contact.phone != null && contact.phone!.isNotEmpty)
          ListTile(
            leading: Icon(Icons.phone_outlined, color: colorScheme.primary),
            title: Text(contact.phone!),
            dense: true,
            contentPadding: EdgeInsets.zero,
            onTap: () => provider.makePhoneCall(contact.phone!),
          ),
        if (contact.email.isNotEmpty)
          ListTile(
            leading: Icon(Icons.email_outlined, color: colorScheme.primary),
            title: Text(contact.email),
            dense: true,
            contentPadding: EdgeInsets.zero,
            onTap: () => provider.sendEmail(contact.email),
          ),
        if (contact.website != null && contact.website!.isNotEmpty)
          ListTile(
            leading: Icon(Icons.language_outlined, color: colorScheme.primary),
            title: Text(contact.website!),
            dense: true,
            contentPadding: EdgeInsets.zero,
            onTap: () => provider.openWebsite(contact.website!),
          ),
      ],
    );
  }
}
