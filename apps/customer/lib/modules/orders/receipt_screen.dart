// Receipt Detail Screen
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lehwipalancecustomerv1/core/models/receipt_model.dart';
import 'package:lehwipalancecustomerv1/enum.dart';

import 'package:qr_flutter/qr_flutter.dart';

// lib/customer/modules/orders/receipt_screen.dart

import 'package:lehwipalancecustomerv1/Providers/receipt_provider.dart';
import 'package:lehwipalancecustomerv1/core/base/service_locator.dart';

class ReceiptScreen extends StatefulWidget {
  final String receiptId;

  /// Optionally pass a receipt you already have in memory to skip the
  /// initial fetch (e.g. right after checkout). If null, the screen
  /// will load it from the provider / API.
  final Receipt? initialReceipt;

  const ReceiptScreen({
    super.key,
    required this.receiptId,
    this.initialReceipt,
  });

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  Receipt? _receipt;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _receipt = widget.initialReceipt;
    _load();
  }

  Future<void> _load() async {
    // Fast path: we already have the object.
    if (_receipt != null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final provider = getIt<ReceiptProvider>();

      // Try the provider's in-memory cache first.
      final cached = provider.getReceiptById(widget.receiptId);
      if (cached != null) {
        if (!mounted) return;
        setState(() {
          _receipt = cached;
          _isLoading = false;
        });
        return;
      }

      // Otherwise fetch from the API through the provider.
      await provider.loadReceiptsById(widget.receiptId);
      final fetched = provider.getReceiptById(widget.receiptId);

      if (!mounted) return;
      setState(() {
        _receipt = fetched;
        _isLoading = false;
        _error = fetched == null ? 'Receipt not found' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load receipt: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _receipt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Receipt'), centerTitle: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Receipt not found',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final receipt = _receipt!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Receipt'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareReceipt(context),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printReceipt(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(context, receipt),
            const SizedBox(height: 24),
            _buildMainQRCode(context, receipt),
            const SizedBox(height: 24),
            _buildOrderDetails(context, receipt),
            const SizedBox(height: 24),
            _buildItemsWithQRCodes(context, receipt),
            const SizedBox(height: 24),
            _buildPaymentSummary(context, receipt),
            const SizedBox(height: 24),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // SECTIONS
  // ==========================================================================

  Widget _buildStatusHeader(BuildContext context, Receipt receipt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            receipt.status.color,
            receipt.status.color.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(receipt.status.icon, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receipt.status.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Order #${receipt.orderId}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(receipt.createdAt),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (receipt.isPaid)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'PAID',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainQRCode(BuildContext context, Receipt receipt) {
    final receiptData = {
      'orderId': receipt.orderId,
      'orderDate': receipt.createdAt.toIso8601String(),
      'totalAmount': receipt.total,
      'itemCount': receipt.itemCount,
      'transactionId': receipt.transactionId ?? 'N/A',
      'items': receipt.items.map((item) {
        return {
          'id': item.id,
          'name': item.name,
          'type': item.type.toString(),
          'quantity': item.quantity,
          'price': item.totalPrice,
        };
      }).toList(),
      'paymentMethod': receipt.paymentMethod ?? 'Credit Card',
      'status': receipt.status.name,
    };

    final qrData = jsonEncode(receiptData);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Scan for Order Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _showQRCodePopup(
                context,
                qrData,
                'Order #${receipt.orderId}',
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${receipt.itemCount} items • Total: ${receipt.totalDisplay}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap QR to enlarge',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsWithQRCodes(BuildContext context, Receipt receipt) {
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
                  Icons.shopping_bag,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('Items', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const Divider(height: 24),
            ...receipt.items.map(
              (item) => _buildItemQRCode(context, receipt, item),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemQRCode(
    BuildContext context,
    Receipt receipt,
    CartItem item,
  ) {
    final itemData = {
      'itemId': item.id,
      'name': item.name,
      'type': item.type.toString(),
      'quantity': item.quantity,
      'price': item.totalPrice,
      'orderId': receipt.orderId,
      'date': receipt.createdAt.toIso8601String(),
      'transactionId': receipt.transactionId ?? 'N/A',
    };

    final qrData = jsonEncode(itemData);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => _showQRCodePopup(context, qrData, item.name),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 64,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                        color: _getTypeColor(item.type).withValues(alpha: 0.1),
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
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item.quantity} × ${item.priceDisplay}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Total: \$${item.totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap QR to view',
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(BuildContext context, Receipt receipt) {
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
                  Icons.receipt_long,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Order Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow('Order ID', '#${receipt.orderId}'),
            _buildDetailRow(
              'Date',
              DateFormat('MMM d, yyyy').format(receipt.createdAt),
            ),
            _buildDetailRow(
              'Time',
              DateFormat('h:mm a').format(receipt.createdAt),
            ),
            if (receipt.paymentMethod != null)
              _buildDetailRow('Payment Method', receipt.paymentMethod!),
            if (receipt.transactionId != null)
              _buildDetailRow('Transaction ID', receipt.transactionId!),
            _buildDetailRow('Items', receipt.itemCount.toString()),
            _buildDetailRow('Total Amount', receipt.totalDisplay, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummary(BuildContext context, Receipt receipt) {
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
                  'Payment Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            _buildSummaryRow('Subtotal', receipt.subtotalDisplay),
            _buildSummaryRow('Tax', receipt.taxDisplay),
            if (receipt.discount > 0)
              _buildSummaryRow('Discount', '-${receipt.discountDisplay}'),
            const Divider(height: 16),
            _buildSummaryRow('Total', receipt.totalDisplay, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            'Thank you for your purchase!',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This receipt serves as proof of purchase',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.email_outlined),
                onPressed: () => _sendEmail(context),
                tooltip: 'Email Receipt',
              ),
              IconButton(
                icon: const Icon(Icons.print_outlined),
                onPressed: () => _printReceipt(context),
                tooltip: 'Print Receipt',
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined),
                onPressed: () => _downloadReceipt(context),
                tooltip: 'Download Receipt',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: Colors.black87,
            ),
          ),
        ],
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
              color: isTotal ? Colors.blue : Colors.grey,
            ),
          ),
        ],
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

  void _showQRCodePopup(BuildContext context, String qrData, String title) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(dialogContext).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Scan this QR code for details',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareReceipt(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Share receipt coming soon')));
  }

  void _downloadReceipt(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download receipt coming soon')),
    );
  }

  void _sendEmail(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Email receipt coming soon')));
  }

  void _printReceipt(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Print receipt coming soon')));
  }
}
