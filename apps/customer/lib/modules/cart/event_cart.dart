// lib/screens/cart/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lehwipalancecustomerv1/Providers/cart_provider.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_provider.dart';
import 'package:lehwipalancecustomerv1/core/base/service_locator.dart';
import 'package:lehwipalancecustomerv1/core/models/receipt_model.dart';

import 'package:intl/intl.dart';
import 'package:lehwipalancecustomerv1/core/router/route_names.dart';
import 'package:lehwipalancecustomerv1/core/router/route_paths.dart';
import 'package:lehwipalancecustomerv1/enum.dart';

// ============================================================================
// CART SCREEN
// ============================================================================
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Store date/time selections per item
  final Map<String, DateTime> _serviceDates = {};
  final Map<String, TimeOfDay> _serviceTimes = {};
  final Map<String, DateTimeRange> _roomDateRanges = {};

  // ✅ Getters instead of `late final` — always resolve the current
  //    singleton and survive hot restart without LateInitializationError.
  CartProvider get _cartProvider => getIt<CartProvider>();
  AuthProvider get _authProvider => getIt<AuthProvider>();

  @override
  void initState() {
    super.initState();
    _cartProvider.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    // Safe even if the locator got wiped by a hot restart.
    if (getIt.isRegistered<CartProvider>()) {
      _cartProvider.removeListener(_onCartChanged);
    }
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  /// Returns `true` only when the user is a signed-in customer.
  /// Otherwise pushes the login sheet with a redirect back to /cart
  /// and returns `false`.
  bool _checkAuthentication(BuildContext context) {
    if (!_authProvider.isCustomer) {
      context.pushNamed(
        RouteNames.loginSheet,
        queryParameters: {'redirect': RoutePaths.cart},
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final cart = _cartProvider;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (!cart.isCartEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showClearCartDialog(context),
              tooltip: 'Clear Cart',
            ),
        ],
      ),
      body: cart.isCartEmpty
          ? const EmptyCartView()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];

                      // Initialize date/time for services if not set
                      if (item.type == CartItemType.service &&
                          !_serviceDates.containsKey(item.id)) {
                        _serviceDates[item.id] =
                            item.selectedDate ??
                            DateTime.now().add(const Duration(days: 1));
                        _serviceTimes[item.id] =
                            item.selectedTime ??
                            const TimeOfDay(hour: 10, minute: 0);
                      }

                      // Initialize date range for rooms if not set
                      if (item.type == CartItemType.room &&
                          !_roomDateRanges.containsKey(item.id)) {
                        _roomDateRanges[item.id] = DateTimeRange(
                          start:
                              item.selectedDate ??
                              DateTime.now().add(const Duration(days: 1)),
                          end: DateTime.now().add(const Duration(days: 3)),
                        );
                      }

                      return Column(
                        children: [
                          CartItemWidget(
                            item: item,
                            onQuantityChanged: (quantity) {
                              cart.updateQuantity(item.id, item.type, quantity);
                            },
                            onRemove: () {
                              _cleanupItemData(item.id);
                              cart.removeItem(item.id, item.type);
                            },
                            onEditDateTime: () {
                              _showDateTimePicker(context, item);
                            },
                          ),
                          if (item.type == CartItemType.room)
                            _buildRoomDateRangeSelector(context, item),
                          if (item.type == CartItemType.service)
                            _buildServiceDateTimeSelector(context, item),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                ),
                CartSummaryBottomBar(
                  totalPrice: cart.totalPrice,
                  itemCount: cart.itemCount,
                  onInquiry: () {
                    if (_checkAuthentication(context)) {
                      _showInquiryOptions(context, cart);
                    }
                  },
                  onCheckout: () {
                    if (_checkAuthentication(context)) {
                      _validateAndNavigateToCheckout(context, cart);
                    }
                  },
                ),
              ],
            ),
    );
  }

  // ==========================================================================
  // INQUIRY / CHECKOUT SHEET
  // ==========================================================================

  void _showInquiryOptions(BuildContext context, CartProvider cart) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.35,
        maxChildSize: 0.65,
        expand: false,
        builder: (sheetContext, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    'Choose Action',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'What would you like to do with your cart items?',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  _buildActionCard(
                    sheetContext,
                    icon: Icons.shopping_cart_checkout,
                    title: 'Checkout',
                    subtitle: 'Proceed to payment',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      // Re-check in the parent context — auth state
                      // may have changed while the sheet was open.
                      if (_checkAuthentication(context)) {
                        _validateAndNavigateToCheckout(context, cart);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildActionCard(
                    sheetContext,
                    icon: Icons.question_answer,
                    title: 'Send Inquiry',
                    subtitle: 'Ask questions about items',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      if (_checkAuthentication(context)) {
                        context.pushNamed(RouteNames.inquiry);
                      }
                    },
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // INLINE DATE/TIME SELECTORS
  // ==========================================================================

  Widget _buildServiceDateTimeSelector(BuildContext context, CartItem item) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _showServiceDateTimePicker(context, item),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _serviceDates[item.id] != null
                          ? DateFormat(
                              'MMM d, yyyy',
                            ).format(_serviceDates[item.id]!)
                          : 'Select Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: _serviceDates[item.id] != null
                            ? Colors.black87
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () => _showServiceDateTimePicker(context, item),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _serviceTimes[item.id] != null
                          ? _serviceTimes[item.id]!.format(context)
                          : 'Select Time',
                      style: TextStyle(
                        fontSize: 12,
                        color: _serviceTimes[item.id] != null
                            ? Colors.black87
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => _showServiceDateTimePicker(context, item),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomDateRangeSelector(BuildContext context, CartItem item) {
    final range = _roomDateRanges[item.id];
    if (range == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _showRoomDateRangePicker(context, item),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Check-in: ${DateFormat('MMM d').format(range.start)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          Text(
                            'Check-out: ${DateFormat('MMM d').format(range.end)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          Text(
                            '${range.end.difference(range.start).inDays} nights',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => _showRoomDateRangePicker(context, item),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // DATE / TIME PICKER DIALOGS
  // ==========================================================================

  void _showDateTimePicker(BuildContext context, CartItem item) {
    if (item.type == CartItemType.service) {
      _showServiceDateTimePicker(context, item);
    } else if (item.type == CartItemType.room) {
      _showRoomDateRangePicker(context, item);
    }
  }

  void _showServiceDateTimePicker(BuildContext context, CartItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (sheetContext, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
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
                  'Select Date & Time for ${item.name}',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: DateTimeSelector(
                    initialDate: _serviceDates[item.id],
                    initialTime: _serviceTimes[item.id],
                    title: '',
                    showTime: true,
                    onDateTimeSelected: (date, time) {
                      if (!mounted) return;
                      setState(() {
                        _serviceDates[item.id] = date;
                        _serviceTimes[item.id] = time;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showRoomDateRangePicker(BuildContext context, CartItem item) {
    final currentRange =
        _roomDateRanges[item.id] ??
        DateTimeRange(
          start: DateTime.now().add(const Duration(days: 1)),
          end: DateTime.now().add(const Duration(days: 3)),
        );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        // ✅ `localRange` lives OUTSIDE the StatefulBuilder so its value
        //    survives `setModalState` rebuilds — that was the bug.
        var localRange = currentRange;

        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                      'Select Dates for ${item.name}',
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    _buildDateRangePicker(
                      sheetContext,
                      initialRange: localRange,
                      onRangeSelected: (range) {
                        setModalState(() => localRange = range);
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              if (!mounted) return;
                              setState(() {
                                _roomDateRanges[item.id] = localRange;
                              });
                              Navigator.pop(sheetContext);
                            },
                            child: const Text('Confirm'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Rebuilt using `showDateRangePicker` (imperative) instead of
  /// embedding `DateRangePickerDialog` in an `Expanded`. The dialog
  /// only reads `initialDateRange` once, so the embedded version
  /// would drift out of sync with the quick-pick chips.
  Widget _buildDateRangePicker(
    BuildContext context, {
    required DateTimeRange initialRange,
    required Function(DateTimeRange) onRangeSelected,
  }) {
    var selectedRange = initialRange;

    return StatefulBuilder(
      builder: (context, setModalState) {
        Widget chip(
          String label,
          DateTimeRange range,
          bool Function(DateTimeRange) isSelected,
        ) {
          final selected = isSelected(selectedRange);
          return FilterChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) {
              setModalState(() => selectedRange = range);
              onRangeSelected(range);
            },
            backgroundColor: Colors.grey[100],
            selectedColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.2),
            checkmarkColor: Theme.of(context).colorScheme.primary,
            labelStyle: TextStyle(
              color: selected ? Theme.of(context).colorScheme.primary : null,
              fontWeight: selected ? FontWeight.w600 : null,
            ),
          );
        }

        final now = DateTime.now();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                chip(
                  '1 Night',
                  DateTimeRange(
                    start: now.add(const Duration(days: 1)),
                    end: now.add(const Duration(days: 2)),
                  ),
                  (r) => r.end.difference(r.start).inDays == 1,
                ),
                chip(
                  '2 Nights',
                  DateTimeRange(
                    start: now.add(const Duration(days: 1)),
                    end: now.add(const Duration(days: 3)),
                  ),
                  (r) => r.end.difference(r.start).inDays == 2,
                ),
                chip(
                  '3 Nights',
                  DateTimeRange(
                    start: now.add(const Duration(days: 1)),
                    end: now.add(const Duration(days: 4)),
                  ),
                  (r) => r.end.difference(r.start).inDays == 3,
                ),
                chip(
                  'Weekend',
                  () {
                    final daysUntilFriday = (5 - now.weekday) % 7;
                    final friday = now.add(Duration(days: daysUntilFriday + 7));
                    return DateTimeRange(
                      start: friday,
                      end: friday.add(const Duration(days: 3)),
                    );
                  }(),
                  (r) =>
                      r.start.weekday == 5 &&
                      r.end.difference(r.start).inDays == 3,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Summary tile
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.date_range,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${DateFormat('MMM d').format(selectedRange.start)} → '
                          '${DateFormat('MMM d').format(selectedRange.end)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${selectedRange.end.difference(selectedRange.start).inDays} nights',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        initialDateRange: selectedRange,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setModalState(() => selectedRange = picked);
                        onRangeSelected(picked);
                      }
                    },
                    icon: const Icon(Icons.edit_calendar, size: 18),
                    label: const Text('Change'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================================
  // NAVIGATION & VALIDATION
  // ==========================================================================

  void _validateAndNavigateToCheckout(BuildContext context, CartProvider cart) {
    // Validate room dates and sync them back into the cart items.
    for (final item in cart.items) {
      if (item.type == CartItemType.room) {
        final range = _roomDateRanges[item.id];
        if (range == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please select dates for ${item.name}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        final updatedItem = item.copyWith(
          selectedDate: range.start,
          customizations: {
            ...item.customizations,
            'checkOut': range.end,
            'nights': range.end.difference(range.start).inDays,
          },
        );
        cart.updateItem(updatedItem);
      }

      if (item.type == CartItemType.service) {
        final date = _serviceDates[item.id];
        final time = _serviceTimes[item.id];
        if (date == null || time == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please select date and time for ${item.name}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        final updatedItem = item.copyWith(
          selectedDate: date,
          selectedTime: time,
        );
        cart.updateItem(updatedItem);
      }
    }

    // ✅ Pass data via `extra` — checkout has no `:userId` path parameter.
    final userId =
        _authProvider.customerUser?.id ?? _authProvider.state.user?.id ?? '';

    context.pushNamed(
      RouteNames.checkout,
      extra: <String, dynamic>{
        'userId': userId,
        'merchantId': null,
        'organisationId': null,
      },
    );
  }

  void _cleanupItemData(String itemId) {
    _serviceDates.remove(itemId);
    _serviceTimes.remove(itemId);
    _roomDateRanges.remove(itemId);
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text(
          'Are you sure you want to remove all items from your cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _cartProvider.clearCart();
              _serviceDates.clear();
              _serviceTimes.clear();
              _roomDateRanges.clear();
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Cart cleared')));
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EMPTY CART VIEW
// ============================================================================

class EmptyCartView extends StatelessWidget {
  const EmptyCartView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 120,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add tickets, rooms, or services to get started',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            // ✅ Switch branch instead of Navigator.pop — cart is a
            //    branch root, so there's nothing to pop to.
            onPressed: () {
              context.pushNamed(RouteNames.catalog);
            },
            icon: const Icon(Icons.explore),
            label: const Text('Browse Items'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CART SUMMARY BOTTOM BAR
// ============================================================================

class CartSummaryBottomBar extends StatelessWidget {
  final double totalPrice;
  final int itemCount;
  final VoidCallback onCheckout;
  final VoidCallback? onInquiry;

  const CartSummaryBottomBar({
    super.key,
    required this.totalPrice,
    required this.itemCount,
    required this.onCheckout,
    this.onInquiry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total ($itemCount items)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${totalPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Taxes included',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (onInquiry != null)
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      onPressed: onInquiry,
                      icon: const Icon(Icons.question_answer, size: 18),
                      label: const Text('Inquire'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                if (onInquiry != null) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: onCheckout,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Proceed to Checkout'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DATE TIME SELECTOR (unchanged — you already had this correct)
// ============================================================================

class DateTimeSelector extends StatefulWidget {
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final Function(DateTime date, TimeOfDay time) onDateTimeSelected;
  final String title;
  final bool showTime;

  const DateTimeSelector({
    super.key,
    this.initialDate,
    this.initialTime,
    required this.onDateTimeSelected,
    this.title = 'Select Date & Time',
    this.showTime = true,
  });

  @override
  State<DateTimeSelector> createState() => _DateTimeSelectorState();
}

class _DateTimeSelectorState extends State<DateTimeSelector> {
  late DateTime selectedDate;
  late TimeOfDay selectedTime;

  @override
  void initState() {
    super.initState();
    selectedDate =
        widget.initialDate ?? DateTime.now().add(const Duration(days: 1));
    selectedTime = widget.initialTime ?? const TimeOfDay(hour: 10, minute: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDatePicker(context)),
                if (widget.showTime) ...[
                  const SizedBox(width: 12),
                  Expanded(child: _buildTimePicker(context)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('MMM d, yyyy').format(selectedDate),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    return InkWell(
      onTap: () => _selectTime(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedTime.format(context),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Theme.of(context).colorScheme.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
      widget.onDateTimeSelected(selectedDate, selectedTime);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Theme.of(context).colorScheme.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != selectedTime) {
      setState(() => selectedTime = picked);
      widget.onDateTimeSelected(selectedDate, selectedTime);
    }
  }
}

// ============================================================================
// DATE RANGE SELECTOR
// ============================================================================

class DateRangeSelector extends StatefulWidget {
  final DateTimeRange? initialRange;
  final Function(DateTimeRange range) onRangeSelected;

  const DateRangeSelector({
    super.key,
    this.initialRange,
    required this.onRangeSelected,
  });

  @override
  State<DateRangeSelector> createState() => _DateRangeSelectorState();
}

class _DateRangeSelectorState extends State<DateRangeSelector> {
  late DateTimeRange selectedRange;

  @override
  void initState() {
    super.initState();
    selectedRange =
        widget.initialRange ??
        DateTimeRange(
          start: DateTime.now().add(const Duration(days: 1)),
          end: DateTime.now().add(const Duration(days: 3)),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Check-in & Check-out Dates',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Quick selection chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickChip(
                  context,
                  label: '1 Night',
                  onTap: () {
                    final range = DateTimeRange(
                      start: DateTime.now().add(const Duration(days: 1)),
                      end: DateTime.now().add(const Duration(days: 2)),
                    );
                    _updateRange(range);
                  },
                  isSelected:
                      selectedRange.end
                          .difference(selectedRange.start)
                          .inDays ==
                      1,
                ),
                _buildQuickChip(
                  context,
                  label: '2 Nights',
                  onTap: () {
                    final range = DateTimeRange(
                      start: DateTime.now().add(const Duration(days: 1)),
                      end: DateTime.now().add(const Duration(days: 3)),
                    );
                    _updateRange(range);
                  },
                  isSelected:
                      selectedRange.end
                          .difference(selectedRange.start)
                          .inDays ==
                      2,
                ),
                _buildQuickChip(
                  context,
                  label: '3 Nights',
                  onTap: () {
                    final range = DateTimeRange(
                      start: DateTime.now().add(const Duration(days: 1)),
                      end: DateTime.now().add(const Duration(days: 4)),
                    );
                    _updateRange(range);
                  },
                  isSelected:
                      selectedRange.end
                          .difference(selectedRange.start)
                          .inDays ==
                      3,
                ),
                _buildQuickChip(
                  context,
                  label: 'Weekend',
                  onTap: () {
                    final now = DateTime.now();
                    final daysUntilFriday = (5 - now.weekday) % 7;
                    final friday = now.add(Duration(days: daysUntilFriday + 7));
                    final range = DateTimeRange(
                      start: friday,
                      end: friday.add(const Duration(days: 3)),
                    );
                    _updateRange(range);
                  },
                  isSelected:
                      selectedRange.start.weekday == 5 &&
                      selectedRange.end
                              .difference(selectedRange.start)
                              .inDays ==
                          3,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Date range picker - Custom implementation
            Row(
              children: [
                Expanded(
                  child: _buildDatePicker(
                    context,
                    label: 'Check-in',
                    date: selectedRange.start,
                    onDateSelected: (date) {
                      if (date != null) {
                        final newRange = DateTimeRange(
                          start: date,
                          end: date.isAfter(selectedRange.end)
                              ? date.add(const Duration(days: 1))
                              : selectedRange.end,
                        );
                        _updateRange(newRange);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDatePicker(
                    context,
                    label: 'Check-out',
                    date: selectedRange.end,
                    onDateSelected: (date) {
                      if (date != null && date.isAfter(selectedRange.start)) {
                        final newRange = DateTimeRange(
                          start: selectedRange.start,
                          end: date,
                        );
                        _updateRange(newRange);
                      } else if (date != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Check-out date must be after check-in date',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stay Duration',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        '${selectedRange.end.difference(selectedRange.start).inDays} nights',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Check-in',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        DateFormat('MMM d, yyyy').format(selectedRange.start),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Check-out',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        DateFormat('MMM d, yyyy').format(selectedRange.end),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(
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
        fontSize: 12,
      ),
    );
  }

  Widget _buildDatePicker(
    BuildContext context, {
    required String label,
    required DateTime date,
    required Function(DateTime?) onDateSelected,
  }) {
    return InkWell(
      onTap: () => _selectDate(context, date, onDateSelected),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat('MMM d, yyyy').format(date),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    DateTime initialDate,
    Function(DateTime?) onDateSelected,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  void _updateRange(DateTimeRange range) {
    setState(() {
      selectedRange = range;
    });
    widget.onRangeSelected(range);
  }
}

// lib/screens/receipt_list_screen.dart

// ============================================================================
// RECEIPT SCREEN
// ============================================================================

class CartItemWidget extends StatelessWidget {
  final CartItem item;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;
  final VoidCallback? onEditDateTime;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    this.onEditDateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.grey[200],
                child: item.imageUrl != null
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            _getPlaceholderIcon(),
                            size: 40,
                            color: Colors.grey[400],
                          );
                        },
                      )
                    : Icon(
                        _getPlaceholderIcon(),
                        size: 40,
                        color: Colors.grey[400],
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor(context).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getTypeLabel(),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getTypeColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Edit DateTime button (only for rooms and services)
                      if (item.type != CartItemType.ticket &&
                          onEditDateTime != null)
                        IconButton(
                          icon: Icon(
                            Icons.edit_calendar,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: onEditDateTime,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: onRemove,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Show date/time info with edit indicator
                  if (item.type == CartItemType.room &&
                      item.customizations.containsKey('checkOut')) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Check-in: ${_formatDate(item.selectedDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Check-out: ${_formatDate(item.customizations['checkOut'] as DateTime)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${(item.customizations['checkOut'] as DateTime).difference(item.selectedDate!).inDays} nights',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                  if (item.type == CartItemType.service &&
                      item.selectedDate != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(item.selectedDate!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (item.selectedTime != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.selectedTime!.format(context),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Quantity Selector
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: item.quantity > 1
                                  ? () => onQuantityChanged(item.quantity - 1)
                                  : null,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            SizedBox(
                              width: 32,
                              child: Center(
                                child: Text(
                                  item.quantity.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              onPressed: () =>
                                  onQuantityChanged(item.quantity + 1),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            item.priceDisplay,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '\$${item.totalPrice.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel() {
    switch (item.type) {
      case CartItemType.ticket:
        return 'Ticket';
      case CartItemType.room:
        return 'Room';
      case CartItemType.service:
        return 'Service';
    }
  }

  Color _getTypeColor(BuildContext context) {
    switch (item.type) {
      case CartItemType.ticket:
        return Colors.blue;
      case CartItemType.room:
        return Colors.green;
      case CartItemType.service:
        return Colors.orange;
    }
  }

  IconData _getPlaceholderIcon() {
    switch (item.type) {
      case CartItemType.ticket:
        return Icons.confirmation_number;
      case CartItemType.room:
        return Icons.hotel;
      case CartItemType.service:
        return Icons.miscellaneous_services;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
