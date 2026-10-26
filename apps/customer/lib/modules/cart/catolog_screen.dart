// lib/screens/catalog_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lehwipalancecustomerv1/Providers/cart_provider.dart';
import 'package:lehwipalancecustomerv1/Providers/merchant_catalog_provider.dart';
import 'package:lehwipalancecustomerv1/core/base/identifiable.dart';
import 'package:lehwipalancecustomerv1/core/base/service_locator.dart';
import 'package:lehwipalancecustomerv1/core/models/receipt_model.dart';
import 'package:lehwipalancecustomerv1/core/models/room_model.dart';
import 'package:lehwipalancecustomerv1/core/models/service_item_model.dart';
import 'package:lehwipalancecustomerv1/core/models/ticket_model.dart';
import 'package:lehwipalancecustomerv1/core/router/route_names.dart';
import 'package:lehwipalancecustomerv1/enum.dart';

import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class CatalogScreen extends StatefulWidget {
  final String merchantId;
  const CatalogScreen({super.key, required this.merchantId});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  @override
  void initState() {
    super.initState();
    // ✅ Kick off load once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      getIt<MerchantCatalogProvider>().initialize(
        merchantId: widget.merchantId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ Use .value for singletons from GetIt
        ChangeNotifierProvider<CartProvider>.value(
          value: getIt<CartProvider>(),
        ),
        ChangeNotifierProvider<MerchantCatalogProvider>.value(
          value: getIt<MerchantCatalogProvider>(),
        ),
      ],
      child: Consumer<MerchantCatalogProvider>(
        builder: (context, provider, _) {
          // Show loading state while initializing
          if (provider.isLoading && !provider.isInitialized) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Show error state
          if (provider.error != null && !provider.isInitialized) {
            return Scaffold(
              appBar: AppBar(title: const Text('Catalog'), centerTitle: true),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        provider.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        provider.reset();
                        provider.initialize(merchantId: widget.merchantId);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Show the catalog content - NOW CartProvider is available here
          return const _CatalogContent();
        },
      ),
    );
  }
}

// Separate widget for the catalog content
class _CatalogContent extends StatelessWidget {
  const _CatalogContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MerchantCatalogProvider>();
    final merchant = provider.merchantListing;

    return Scaffold(
      appBar: AppBar(
        title: Text(merchant?.title ?? 'Catalog'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          // Now Consumer<CartProvider> will work because CartProvider is provided
          // in the ancestor widget (MultiProvider above)
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () {
                      context.pushNamed(RouteNames.cart);
                    },
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          cart.itemCount.toString(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onError,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Merchant Hero Image
          if (merchant?.mediaUrls.mainImageUrl != null)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(merchant!.mediaUrls.mainImageUrl),
                  fit: BoxFit.cover,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          // Catalog Tab Bar
          Expanded(
            child: Consumer<MerchantCatalogProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(),
                  );
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => provider.refreshCatalog(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.merchantListing == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.store_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No merchant found',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return CatalogTabBar(merchantId: provider.merchantListing!.id);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CatalogTabBar extends StatelessWidget {
  final String merchantId;

  const CatalogTabBar({super.key, required this.merchantId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: const [
                Tab(icon: Icon(Icons.confirmation_number), text: 'Tickets'),
                Tab(icon: Icon(Icons.hotel), text: 'Rooms'),
                Tab(icon: Icon(Icons.spa), text: 'Services'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                TicketsTab(merchantId: merchantId),
                RoomsTab(merchantId: merchantId),
                ServicesTab(merchantId: merchantId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RoomsTab extends StatelessWidget {
  final String merchantId;

  const RoomsTab({super.key, required this.merchantId});

  @override
  Widget build(BuildContext context) {
    return Consumer<MerchantCatalogProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingRooms) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.roomsError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  provider.roomsError!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: provider.refreshRooms,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.rooms.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hotel_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No rooms available',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '🏨 Available Rooms',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...provider.rooms.map((room) => _buildRoomCard(context, room)),
          ],
        );
      },
    );
  }

  Widget _buildRoomCard(BuildContext context, RoomDTO room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.hotel, color: Colors.green.shade700, size: 30),
        ),
        title: Text(
          room.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              room.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '\$${room.basePrice.toStringAsFixed(2)}/night',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (room.status != PublishStatus.published)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Unavailable',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: FilledButton(
          onPressed: room.status == PublishStatus.published
              ? () => _showRoomDatePicker(context, room)
              : null,
          child: const Text('Book'),
        ),
        onTap: room.status == PublishStatus.published
            ? () => _showRoomDatePicker(context, room)
            : null,
      ),
    );
  }

  void _showRoomDatePicker(BuildContext context, RoomDTO room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          DateTimeRange selectedRange = DateTimeRange(
            start: DateTime.now().add(const Duration(days: 1)),
            end: DateTime.now().add(const Duration(days: 3)),
          );

          return Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Dates for ${room.name}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildQuickDateChip(
                      context,
                      label: '1 Night',
                      isSelected: false,
                      onTap: () {
                        final range = DateTimeRange(
                          start: DateTime.now().add(const Duration(days: 1)),
                          end: DateTime.now().add(const Duration(days: 2)),
                        );
                        setState(() {
                          selectedRange = range;
                        });
                      },
                    ),
                    _buildQuickDateChip(
                      context,
                      label: '2 Nights',
                      isSelected: false,
                      onTap: () {
                        final range = DateTimeRange(
                          start: DateTime.now().add(const Duration(days: 1)),
                          end: DateTime.now().add(const Duration(days: 3)),
                        );
                        setState(() {
                          selectedRange = range;
                        });
                      },
                    ),
                    _buildQuickDateChip(
                      context,
                      label: '3 Nights',
                      isSelected: false,
                      onTap: () {
                        final range = DateTimeRange(
                          start: DateTime.now().add(const Duration(days: 1)),
                          end: DateTime.now().add(const Duration(days: 4)),
                        );
                        setState(() {
                          selectedRange = range;
                        });
                      },
                    ),
                    _buildQuickDateChip(
                      context,
                      label: 'Weekend',
                      isSelected: false,
                      onTap: () {
                        final now = DateTime.now();
                        final daysUntilFriday = (5 - now.weekday) % 7;
                        final friday = now.add(
                          Duration(days: daysUntilFriday + 7),
                        );
                        final range = DateTimeRange(
                          start: friday,
                          end: friday.add(const Duration(days: 3)),
                        );
                        setState(() {
                          selectedRange = range;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: DateRangePickerDialog(
                    initialDateRange: selectedRange,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    currentDate: DateTime.now(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          _addRoomToCart(context, room, selectedRange);
                          Navigator.pop(context);
                        },
                        child: const Text('Add to Cart'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickDateChip(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey[100],
      selectedColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
        fontWeight: isSelected ? FontWeight.w600 : null,
      ),
    );
  }

  void _addRoomToCart(BuildContext context, RoomDTO room, DateTimeRange range) {
    final cartItem = CartItem(
      id: room.id,
      type: CartItemType.room,
      item: room,
      quantity: 1,
      selectedDate: range.start,
      customizations: {
        'checkOut': range.end,
        'nights': range.end.difference(range.start).inDays,
      },
    );

    context.read<CartProvider>().addItem(cartItem);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${room.name} (${range.end.difference(range.start).inDays} nights)',
        ),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () {
            context.pushNamed(RouteNames.cart);
          },
        ),
      ),
    );
  }

  // ... _buildRoomCard and other methods remain the same
}

class TicketsTab extends StatelessWidget {
  final String merchantId;

  const TicketsTab({super.key, required this.merchantId});

  @override
  Widget build(BuildContext context) {
    return Consumer<MerchantCatalogProvider>(
      builder: (context, provider, _) {
        // Show loading state
        if (provider.isLoadingTickets) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show error state
        if (provider.ticketsError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  provider.ticketsError!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: provider.refreshTickets,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Show empty state
        if (provider.tickets.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No tickets available',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Show tickets list
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '🎫 Available Tickets',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...provider.tickets.map(
              (ticket) => _buildTicketCard(context, ticket),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTicketCard(BuildContext context, TicketDTO ticket) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.confirmation_number,
            color: Colors.blue.shade700,
            size: 30,
          ),
        ),
        title: Text(
          ticket.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ticket.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  ticket.priceDisplay,
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (ticket.isSoldOut)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Sold Out',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (!ticket.isOnSale && !ticket.isSoldOut)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Not on Sale',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: FilledButton(
          onPressed: (ticket.isOnSale && !ticket.isSoldOut)
              ? () => _addTicketToCart(context, ticket)
              : null,
          child: const Text('Add'),
        ),
        onTap: (ticket.isOnSale && !ticket.isSoldOut)
            ? () => _addTicketToCart(context, ticket)
            : null,
      ),
    );
  }

  void _addTicketToCart(BuildContext context, TicketDTO ticket) {
    final cartItem = CartItem(
      id: ticket.id,
      type: CartItemType.ticket,
      item: ticket,
      quantity: 1,
      selectedDate: DateTime.now(),
    );

    context.read<CartProvider>().addItem(cartItem);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${ticket.name} to cart'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () {
            context.pushNamed(RouteNames.cart);
          },
        ),
      ),
    );
  }
}

class ServicesTab extends StatelessWidget {
  final String merchantId;

  const ServicesTab({super.key, required this.merchantId});

  @override
  Widget build(BuildContext context) {
    return Consumer<MerchantCatalogProvider>(
      builder: (context, provider, _) {
        // Show loading state
        if (provider.isLoadingServices) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show error state
        if (provider.servicesError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  provider.servicesError!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: provider.refreshServices,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Show empty state
        if (provider.services.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.spa_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No services available',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Show services list
        return RefreshIndicator(
          onRefresh: provider.refreshServices,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                '💆 Available Services',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...provider.services.map(
                (service) => _buildServiceCard(context, service),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceCard(BuildContext context, ServiceItemDTO service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            service.categoryIcon,
            color: Colors.orange.shade700,
            size: 30,
          ),
        ),
        title: Text(
          service.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              service.shortDescription ?? service.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  service.priceDisplay,
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (service.status != PublishStatus.published)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Unavailable',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: FilledButton(
          onPressed: service.isActive
              ? () => _showServiceDateTimePicker(context, service)
              : null,
          child: const Text('Book'),
        ),
        onTap: service.isActive
            ? () => _showServiceDateTimePicker(context, service)
            : null,
      ),
    );
  }

  void _showServiceDateTimePicker(
    BuildContext context,
    ServiceItemDTO service,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
          TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);

          final availableSlots = _getAvailableTimeSlots(service);

          return Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Date & Time for ${service.name}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Available Time Slots',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: availableSlots.isEmpty
                      ? Center(
                          child: Text(
                            'No available slots for this date',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 1.5,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: availableSlots.length,
                          itemBuilder: (context, index) {
                            final slot = availableSlots[index];
                            final isSelected =
                                selectedTime.hour == slot.hour &&
                                selectedTime.minute == slot.minute;
                            return ChoiceChip(
                              label: Text(
                                '${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}',
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    selectedTime = slot;
                                  });
                                }
                              },
                              backgroundColor: Colors.grey[100],
                              selectedColor: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          _addServiceToCart(
                            context,
                            service,
                            selectedDate,
                            selectedTime,
                          );
                          Navigator.pop(context);
                        },
                        child: const Text('Add to Cart'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<TimeOfDay> _getAvailableTimeSlots(ServiceItemDTO service) {
    final slots = <TimeOfDay>[];

    if (service.isAvailable24_7) {
      for (int hour = 6; hour <= 23; hour++) {
        slots.add(TimeOfDay(hour: hour, minute: 0));
        slots.add(TimeOfDay(hour: hour, minute: 30));
      }
      return slots;
    }

    if (service.availableFrom != null && service.availableTo != null) {
      int startHour = service.availableFrom!.hour;
      int startMinute = service.availableFrom!.minute;
      int endHour = service.availableTo!.hour;
      int endMinute = service.availableTo!.minute;

      int totalMinutes =
          (endHour * 60 + endMinute) - (startHour * 60 + startMinute);

      int slotDuration = service.duration.inMinutes;
      int stepMinutes = slotDuration > 30 ? slotDuration : 30;

      for (int minutes = 0; minutes < totalMinutes; minutes += stepMinutes) {
        int currentMinutes = startHour * 60 + startMinute + minutes;
        int hour = currentMinutes ~/ 60;
        int minute = currentMinutes % 60;
        if (hour < endHour || (hour == endHour && minute <= endMinute)) {
          slots.add(TimeOfDay(hour: hour, minute: minute));
        }
      }
    }

    return slots;
  }

  void _addServiceToCart(
    BuildContext context,
    ServiceItemDTO service,
    DateTime date,
    TimeOfDay time,
  ) {
    final cartItem = CartItem(
      id: service.id,
      type: CartItemType.service,
      item: service,
      quantity: 1,
      selectedDate: date,
      selectedTime: time,
    );

    context.read<CartProvider>().addItem(cartItem);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${service.name} on ${DateFormat('MMM d').format(date)} at ${time.format(context)}',
        ),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () {
            context.pushNamed(RouteNames.cart);
          },
        ),
      ),
    );
  }
}
