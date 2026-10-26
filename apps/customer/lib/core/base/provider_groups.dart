// lib/core/base/provider_groups.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lehwipalancecustomerv1/Providers/cart_provider.dart';
import 'package:lehwipalancecustomerv1/Providers/customer_provider.dart';
import 'package:lehwipalancecustomerv1/Providers/location_provider.dart';
import 'package:lehwipalancecustomerv1/Providers/merchant_listing_provider.dart';
import 'package:lehwipalancecustomerv1/Providers/organisation_provider.dart';
import 'package:lehwipalancecustomerv1/Providers/receipt_provider.dart';
import 'package:lehwipalancecustomerv1/Providers/wallet_provider.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_provider.dart';
import 'package:lehwipalancecustomerv1/core/base/service_locator.dart';
import 'package:lehwipalancecustomerv1/modules/orders/inquiry_provider.dart';
import 'package:lehwipalancecustomerv1/theme/provider/theme_provider.dart';

/// ------------------------------------------------------------
/// App-level providers. Wraps the ENTIRE app in main.dart.
/// Registers auth + theme so MaterialApp.router can rebuild.
/// ------------------------------------------------------------
class CoreProviders extends StatelessWidget {
  final Widget child;
  const CoreProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: getIt<AuthProvider>()),
        ChangeNotifierProvider.value(value: getIt<ThemeProvider>()),
      ],
      child: child,
    );
  }
}

/// ------------------------------------------------------------
/// Customer dashboard scope. Wraps the StatefulShellRoute builder
/// so ALL tab branches (home, media, map, orders, profile + nested)
/// have access to every customer-facing provider.
/// ------------------------------------------------------------
class CustomerDashboardProviders extends StatelessWidget {
  final Widget child;
  const CustomerDashboardProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core
        ChangeNotifierProvider.value(value: getIt<AuthProvider>()),
        ChangeNotifierProvider.value(value: getIt<ThemeProvider>()),

        // Location & listings
        ChangeNotifierProvider.value(value: getIt<LocationProvider>()),
        ChangeNotifierProvider.value(value: getIt<MerchantListingProvider>()),
        ChangeNotifierProvider.value(value: getIt<OrganizationProvider>()),

        // Customer / cart
        ChangeNotifierProvider.value(value: getIt<CustomerProvider>()),
        ChangeNotifierProvider.value(value: getIt<CartProvider>()),

        // Orders / payments
        ChangeNotifierProvider.value(value: getIt<ReceiptProvider>()),
        ChangeNotifierProvider.value(value: getIt<InquiryProvider>()),

        // Wallet
        ChangeNotifierProvider.value(value: getIt<WalletProvider>()),
      ],
      child: child,
    );
  }
}

/// ------------------------------------------------------------
/// Organiser / merchant scopes — keep as-is, add providers if
/// you actually use them.
/// ------------------------------------------------------------
class OrganiserProfileProviders extends StatelessWidget {
  final Widget child;
  const OrganiserProfileProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: getIt<AuthProvider>()),
        ChangeNotifierProvider.value(value: getIt<ThemeProvider>()),
        ChangeNotifierProvider.value(value: getIt<OrganizationProvider>()),
      ],
      child: child,
    );
  }
}

class MerchantManagementProviders extends StatelessWidget {
  final Widget child;
  const MerchantManagementProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: getIt<AuthProvider>()),
        ChangeNotifierProvider.value(value: getIt<ThemeProvider>()),
      ],
      child: child,
    );
  }
}

// ------------------------------------------------------------
// DataLoader — unchanged
// ------------------------------------------------------------
class DataLoader extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onLoad;

  const DataLoader({super.key, required this.child, required this.onLoad});

  @override
  State<DataLoader> createState() => _DataLoaderState();
}

class _DataLoaderState extends State<DataLoader> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_loaded) return;
    await widget.onLoad();
    if (mounted) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
