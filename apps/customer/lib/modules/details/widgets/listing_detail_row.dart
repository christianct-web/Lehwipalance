// lib/features/listing/widgets/common/listing_detail_row.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ListingDetailRow extends StatelessWidget {
  final IconData icon;
  final Widget child;
  const ListingDetailRow({super.key, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Icon(icon, size: 30, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(width: 2),
          Expanded(child: child),
        ],
      ),
    );
  }
}

Widget buildNetworkImage(String? url, {required Widget fallback}) {
  if (url == null || url.isEmpty) return fallback;
  return CachedNetworkImage(
    imageUrl: url,
    fit: BoxFit.cover,
    placeholder: (_, _) => fallback,
    errorWidget: (_, _, _) => fallback,
  );
}
