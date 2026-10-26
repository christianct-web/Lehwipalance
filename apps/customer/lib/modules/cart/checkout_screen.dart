// lib/customer/modules/cart/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
//import 'package:go_router/go_router.dart';
import 'package:lehwipalancecustomerv1/Providers/cart_provider.dart';
import 'package:lehwipalancecustomerv1/Providers/receipt_provider.dart';

import 'package:intl/intl.dart';
import 'package:lehwipalancecustomerv1/core/router/route_names.dart';
import 'package:lehwipalancecustomerv1/enum.dart';

class CheckoutScreen extends StatefulWidget {
  final String userId;
  final String? merchantId; // 👈 HERE
  final String? organisationId; // 👈 and HERE

  const CheckoutScreen({
    super.key,
    required this.userId,
    this.merchantId,
    this.organisationId,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = 'Credit Card';
  bool _isProcessing = false;
  String? _errorMessage;

  late final CartProvider _cartProvider;
  late final ReceiptProvider _receiptProvider;

  @override
  void initState() {
    super.initState();
    _cartProvider = GetIt.instance<CartProvider>();
    _receiptProvider = GetIt.instance<ReceiptProvider>();
  }

  Future<void> _placeOrder(BuildContext context, CartProvider cart) async {
    // Validate cart
    if (cart.isCartEmpty) {
      setState(() => _errorMessage = 'Your cart is empty');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final now = DateTime.now();
      final orderId =
          'ORD${now.millisecondsSinceEpoch.toString().substring(5)}';
      final transactionId =
          'TXN${now.millisecondsSinceEpoch.toString().substring(7)}';

      final subtotal = cart.totalPrice;
      final tax = subtotal * 0.085;

      final receipt = await _receiptProvider.createReceiptFromCart(
        orderId: orderId,
        cartItems: cart.items,
        tax: tax,
        discount: 0.0,
        paymentMethod: _selectedPaymentMethod,
        transactionId: transactionId,
        notes: 'Order placed from mobile app',
        merchantId: widget.merchantId ?? '', // 👈 widget. + null-coalesce
        organisationId:
            widget.organisationId ?? '', // 👈 widget. + null-coalesce
      );

      if (receipt != null && mounted) {
        // Clear cart
        cart.clearCart();

        // Navigate to receipt screen
        context.pushNamed(
          RouteNames.receipt,
          pathParameters: {'receiptId': receipt.id},
        );
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Failed to create receipt. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error placing order: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = _cartProvider;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout'), centerTitle: true),
      body: cart.isCartEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderSummary(context, cart),
                  const SizedBox(height: 16),
                  _buildPaymentSection(context),
                  const SizedBox(height: 16),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isProcessing
                          ? null
                          : () => _placeOrder(context, cart),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Place Order'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderSummary(BuildContext context, CartProvider cart) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Order Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            ...cart.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getTypeColor(
                                    item.type,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getTypeLabel(item.type),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _getTypeColor(item.type),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${item.quantity} x ${item.priceDisplay}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          // Show selected date/time if applicable
                          if (item.selectedDate != null)
                            Text(
                              'Date: ${_formatDate(item.selectedDate!)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          if (item.selectedTime != null)
                            Text(
                              'Time: ${item.selectedTime!.format(context)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          if (item.customizations.containsKey('checkOut'))
                            Text(
                              'Check-out: ${_formatDate(item.customizations['checkOut'] as DateTime)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),
            _buildSummaryRow('Subtotal', cart.totalPriceDisplay),
            _buildSummaryRow(
              'Tax (8.5%)',
              '\$${(cart.totalPrice * 0.085).toStringAsFixed(2)}',
            ),
            const Divider(height: 16),
            _buildSummaryRow(
              'Total',
              '\$${(cart.totalPrice * 1.085).toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Payment Method',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            _buildPaymentOption(
              context,
              icon: Icons.credit_card,
              title: 'Credit Card',
              subtitle: 'Pay with credit or debit card',
              isSelected: _selectedPaymentMethod == 'Credit Card',
              onTap: () =>
                  setState(() => _selectedPaymentMethod = 'Credit Card'),
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              context,
              icon: Icons.account_balance_wallet,
              title: 'Digital Wallet',
              subtitle: 'Pay with Google Pay or Apple Pay',
              isSelected: _selectedPaymentMethod == 'Digital Wallet',
              onTap: () =>
                  setState(() => _selectedPaymentMethod = 'Digital Wallet'),
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              context,
              icon: Icons.payments,
              title: 'Bank Transfer',
              subtitle: 'Pay via bank transfer',
              isSelected: _selectedPaymentMethod == 'Bank Transfer',
              onTap: () =>
                  setState(() => _selectedPaymentMethod = 'Bank Transfer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(CartItemType type) {
    switch (type) {
      case CartItemType.ticket:
        return Colors.blue;
      case CartItemType.room:
        return Colors.green;
      case CartItemType.service:
        return Colors.orange;
    }
  }

  String _getTypeLabel(CartItemType type) {
    switch (type) {
      case CartItemType.ticket:
        return 'Ticket';
      case CartItemType.room:
        return 'Room';
      case CartItemType.service:
        return 'Service';
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
}
