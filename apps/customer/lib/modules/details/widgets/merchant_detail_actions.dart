// lib/features/listing/extensions/merchant_detail_actions.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lehwipalancecustomerv1/Providers/merchant_detail_provider.dart';
import 'package:lehwipalancecustomerv1/core/router/route_names.dart';
import 'package:lehwipalancecustomerv1/theme/app_constants.dart';
import 'package:lehwipalancecustomerv1/theme/provider/theme_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

extension MerchantDetailActions on MerchantDetailProvider {
  void handlePrimaryAction(BuildContext context) {
    final l = listing;
    if (l == null) return;
    context.pushNamed(RouteNames.catalog, pathParameters: {'listingId': l.id});
  }

  void handleWriteReview(BuildContext context) {
    final l = listing;
    if (l == null) return;
    context.pushNamed(
      RouteNames.writeReview,
      queryParameters: {'listingId': l.id, 'type': l.type.name},
    );
  }

  void handleChatAction(BuildContext context) {
    final l = listing;
    final org = organization;
    if (l == null || org == null) {
      context.showSnackBar('Chat unavailable');
      return;
    }
    context.pushNamed(
      RouteNames.chat,
      pathParameters: {'organizationId': org.id, 'listingId': l.id},
    );
  }

  Future<void> handleCallAction() async {
    final phone = listing?.contactInfo?.phone;
    if (phone == null || phone.trim().isEmpty) return;
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> handleWebsiteAction(BuildContext context) async {
    final website = listing?.contactInfo?.website;
    if (website == null || website.trim().isEmpty) {
      context.showSnackBar(LanguageConstants.websiteIsUnavailable);
      return;
    }
    final url = Uri.parse(
      website.startsWith('http') ? website : 'https://$website',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      context.showSnackBar(LanguageConstants.websiteIsUnavailable);
    }
  }

  Future<void> handleDirectionsAction(BuildContext context) async {
    final loc = cachedLocation;
    if (loc == null) {
      context.showSnackBar(LanguageConstants.locationIsUnavailable);
      return;
    }
    final uri = Uri.parse(
      'geo:${loc.latitude},${loc.longitude}?q=${loc.latitude},${loc.longitude}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        final fallback = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${loc.latitude},${loc.longitude}',
        );
        await launchUrl(fallback, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) {
        context.showSnackBar(LanguageConstants.locationIsUnavailable);
      }
    }
  }

  Future<void> shareListing() async {
    final l = listing;
    if (l == null) return;
    final orgName = organization?.name ?? '';
    await SharePlus.instance.share(
      ShareParams(
        text:
            'Check out ${l.title} on Lehwi Palance!\n📍 $orgName\n🔗 https://lehwi-palance.app/listing/${l.id}',
        subject: l.title,
      ),
    );
  }
}
