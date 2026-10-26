// lib/features/listing/widgets/sections/listing_action_buttons.dart
import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/Providers/merchant_detail_provider.dart';
import 'package:lehwipalancecustomerv1/theme/app_constants.dart';

class ListingActionButtons extends StatelessWidget {
  final MerchantDetailProvider provider;
  const ListingActionButtons({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => provider.handlePrimaryAction(context),
              icon: Icon(provider.actionIcon),
              label: Text(provider.actionButtonText),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _showContactOptions(context, provider),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
              label: const Text(LanguageConstants.contact),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                foregroundColor: theme.colorScheme.onSurface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactOptions(
    BuildContext context,
    MerchantDetailProvider provider,
  ) {
    final listing = provider.listing;
    if (listing?.contactInfo == null) return;
    final contact = listing!.contactInfo!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              LanguageConstants.contact,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (contact.phone != null && contact.phone!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: Text(contact.phone!),
                subtitle: const Text('Phone'),
                onTap: () {
                  Navigator.pop(context);
                  provider.makePhoneCall(contact.phone!);
                },
              ),
            if (contact.email.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: Text(contact.email),
                subtitle: const Text('Email'),
                onTap: () {
                  Navigator.pop(context);
                  provider.sendEmail(contact.email);
                },
              ),
            if (contact.website != null && contact.website!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: Text(contact.website!),
                subtitle: const Text('Website'),
                onTap: () {
                  Navigator.pop(context);
                  provider.openWebsite(contact.website!);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
