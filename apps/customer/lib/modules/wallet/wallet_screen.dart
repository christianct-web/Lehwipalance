// lib/features/wallet/screens/wallet_screen.dart
// lib/features/wallet/screens/wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lehwipalancecustomerv1/Providers/wallet_provider.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_provider.dart';
import 'package:lehwipalancecustomerv1/core/models/waller_model.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late final WalletProvider _walletProvider;
  late final PaymentMethodProvider _paymentMethodProvider;
  bool _initialLoadComplete = false;

  @override
  void initState() {
    super.initState();
    _walletProvider = GetIt.instance<WalletProvider>();
    _paymentMethodProvider = GetIt.instance<PaymentMethodProvider>();

    // Add listeners
    _walletProvider.addListener(_onWalletChanged);
    _paymentMethodProvider.addListener(_onPaymentMethodsChanged);

    _initializeData();
  }

  @override
  void dispose() {
    _walletProvider.removeListener(_onWalletChanged);
    _paymentMethodProvider.removeListener(_onPaymentMethodsChanged);
    super.dispose();
  }

  void _onWalletChanged() {
    if (mounted) setState(() {});
  }

  void _onPaymentMethodsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _walletProvider.loadWallet(),
      _paymentMethodProvider.loadPaymentMethods(),
    ]);
    if (mounted) {
      setState(() => _initialLoadComplete = true);
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _walletProvider.refreshWallet(),
      _paymentMethodProvider.refreshPaymentMethods(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(), body: _buildBody());
  }

  PreferredSizeWidget? _buildAppBar() {
    return AppBar(
      title: Text('My Wallet'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _refreshData,
          tooltip: 'Refresh',
        ),
        _buildAppBarMenu(),
      ],
    );
  }

  Widget _buildAppBarMenu() {
    return PopupMenuButton<WalletMenuAction>(
      onSelected: _handleMenuAction,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: WalletMenuAction.transactions,
          child: ListTile(
            leading: Icon(Icons.history),
            title: Text('Transaction History'),
          ),
        ),
        const PopupMenuItem(
          value: WalletMenuAction.help,
          child: ListTile(
            leading: Icon(Icons.help_outline),
            title: Text('Wallet Help'),
          ),
        ),
        const PopupMenuItem(
          value: WalletMenuAction.security,
          child: ListTile(
            leading: Icon(Icons.security),
            title: Text('Security Info'),
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(WalletMenuAction action) {
    switch (action) {
      case WalletMenuAction.transactions:
        // Navigate to transactions screen
        break;
      case WalletMenuAction.help:
        _showComingSoonSnackBar('Wallet Help coming soon');
        break;
      case WalletMenuAction.security:
        _showComingSoonSnackBar('Security Info coming soon');
        break;
    }
  }

  Widget _buildBody() {
    final walletState = _walletProvider;
    final methodsState = _paymentMethodProvider;

    if (!_initialLoadComplete && walletState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (walletState.hasError && !walletState.hasWallet) {
      return ErrorStateWidget(
        icon: Icons.error_outline,
        title: 'Failed to load wallet',
        message: walletState.error!,
        actionText: 'Try Again',
        onAction: _refreshData,
      );
    }

    if (!walletState.hasWallet) {
      return const EmptyStateWidget(
        icon: Icons.account_balance_wallet_outlined,
        title: 'No wallet found',
        message: 'Unable to load wallet information',
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBalanceCard(walletState),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildPaymentMethodsPreview(methodsState),
            const SizedBox(height: 24),
            _buildRecentTransactions(walletState),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(WalletProvider provider) {
    return ModernBalanceCard(
      balance: provider.balance,
      currency: provider.wallet?.currency ?? 'USD',
      onAddFunds: _navigateToAddFunds,
      onWithdraw: null, // Add withdraw functionality if needed
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: ActionCard(
            icon: Icons.add,
            label: 'Add Funds',
            color: Colors.green,
            onTap: _navigateToAddFunds,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ActionCard(
            icon: Icons.history,
            label: 'History',
            color: Colors.orange,
            onTap: () {
              // Navigate to transactions history
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodsPreview(PaymentMethodProvider provider) {
    final methods = provider.methods.take(2).toList();

    return ModernSectionCard(
      title: 'Payment Methods',
      actionText: 'Add Method',
      onAction: _showAddPaymentMethodSheet,
      child: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : methods.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.credit_card_off,
              title: 'No payment methods',
              message: 'Add a payment method to make transactions',
              compact: true,
            )
          : Column(
              children: methods
                  .map(
                    (method) => ModernPaymentMethodItem(
                      method: method,
                      onTap: () => _showPaymentMethodOptions(method),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildRecentTransactions(WalletProvider provider) {
    final transactions = provider.transactions.take(5).toList();

    return ModernSectionCard(
      title: 'Recent Transactions',
      actionText: 'View All',
      onAction: () {
        // Navigate to all transactions
      },
      child: transactions.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.receipt_long,
              title: 'No transactions',
              message: 'Your transactions will appear here',
              compact: true,
            )
          : Column(
              children: transactions
                  .map(
                    (transaction) => ModernTransactionItem(
                      transaction: transaction,
                      onTap: () => _showTransactionDetails(transaction),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  void _navigateToAddFunds() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddFundsScreen()),
    ).then((_) => _refreshData());
  }

  void _showAddPaymentMethodSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddPaymentMethodSheet(),
    ).then((_) => _refreshData());
  }

  void _showPaymentMethodOptions(BaseMethod method) {
    showModalBottomSheet(
      context: context,
      builder: (context) => PaymentMethodOptionsSheet(
        method: method,
        onSetDefault: () => _setDefaultPaymentMethod(method.id),
        onDelete: () => _deletePaymentMethod(method.id),
      ),
    );
  }

  void _showTransactionDetails(TransactionModel transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TransactionDetailsSheet(transaction: transaction),
    );
  }

  Future<void> _setDefaultPaymentMethod(String id) async {
    try {
      await _paymentMethodProvider.setDefault(id);
      _showSuccessSnackBar('Default payment method updated');
    } catch (e) {
      _showErrorSnackBar('Failed to set default payment method: $e');
    }
  }

  Future<void> _deletePaymentMethod(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Payment Method',
        message: 'Are you sure you want to delete this payment method?',
        confirmText: 'Delete',
        confirmColor: Colors.red,
      ),
    );

    if (confirmed == true) {
      try {
        await _paymentMethodProvider.deletePaymentMethod(id);
        _showSuccessSnackBar('Payment method deleted successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to delete payment method: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showComingSoonSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
// lib/features/wallet/widgets/credit_card_form_sheet.dart

class CreditCardFormSheet extends StatefulWidget {
  const CreditCardFormSheet({super.key});

  @override
  State<CreditCardFormSheet> createState() => _CreditCardFormSheetState();
}

class _CreditCardFormSheetState extends State<CreditCardFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _expiryMonthController = TextEditingController();
  final _expiryYearController = TextEditingController();
  final _cvvController = TextEditingController();

  late final PaymentMethodProvider _paymentMethodProvider;
  late final AuthProvider _authProvider;

  CardType _cardType = CardType.visa;
  bool _isDefault = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _paymentMethodProvider = GetIt.instance<PaymentMethodProvider>();
    _authProvider = GetIt.instance<AuthProvider>();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _holderNameController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (_isSubmitting)
              LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: colorScheme.primary,
              ),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildCardTypeDropdown(),
                  const SizedBox(height: 16),
                  _buildCardNumberField(),
                  const SizedBox(height: 16),
                  _buildCardHolderNameField(),
                  const SizedBox(height: 16),
                  _buildExpiryAndCvvFields(),
                  const SizedBox(height: 16),
                  _buildDefaultCheckbox(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
        const Spacer(),
        Text(
          'Add Credit/Debit Card',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildCardTypeDropdown() {
    return DropdownButtonFormField<CardType>(
      initialValue: _cardType,
      decoration: const InputDecoration(
        labelText: 'Card Type',
        border: OutlineInputBorder(),
      ),
      items: CardType.values.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type.name.toUpperCase()),
        );
      }).toList(),
      onChanged: _isSubmitting
          ? null
          : (value) => setState(() => _cardType = value!),
    );
  }

  Widget _buildCardNumberField() {
    return TextFormField(
      controller: _cardNumberController,
      enabled: !_isSubmitting,
      decoration: const InputDecoration(
        labelText: 'Card Number',
        border: OutlineInputBorder(),
        hintText: '1234 5678 9012 3456',
      ),
      keyboardType: TextInputType.number,
      maxLength: 19,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter card number';
        }
        final cleaned = value.replaceAll(' ', '');
        if (cleaned.length != 16) {
          return 'Card number must be 16 digits';
        }
        return null;
      },
    );
  }

  Widget _buildCardHolderNameField() {
    return TextFormField(
      controller: _holderNameController,
      enabled: !_isSubmitting,
      decoration: const InputDecoration(
        labelText: 'Card Holder Name',
        border: OutlineInputBorder(),
        hintText: 'John Doe',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter card holder name';
        }
        return null;
      },
    );
  }

  Widget _buildExpiryAndCvvFields() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _expiryMonthController,
            enabled: !_isSubmitting,
            decoration: const InputDecoration(
              labelText: 'MM',
              border: OutlineInputBorder(),
              hintText: '12',
            ),
            keyboardType: TextInputType.number,
            maxLength: 2,
            validator: (value) {
              if (value == null || value.isEmpty) return 'MM';
              final month = int.tryParse(value);
              if (month == null || month < 1 || month > 12) {
                return 'Invalid';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _expiryYearController,
            enabled: !_isSubmitting,
            decoration: const InputDecoration(
              labelText: 'YY',
              border: OutlineInputBorder(),
              hintText: '25',
            ),
            keyboardType: TextInputType.number,
            maxLength: 2,
            validator: (value) {
              if (value == null || value.isEmpty) return 'YY';
              final year = int.tryParse(value);
              if (year == null || year < DateTime.now().year % 100) {
                return 'Invalid';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _cvvController,
            enabled: !_isSubmitting,
            decoration: const InputDecoration(
              labelText: 'CVV',
              border: OutlineInputBorder(),
              hintText: '123',
            ),
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            validator: (value) {
              if (value == null || value.isEmpty) return 'CVV';
              if (value.length < 3) return 'Invalid CVV';
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultCheckbox() {
    return CheckboxListTile(
      title: const Text('Set as default payment method'),
      value: _isDefault,
      onChanged: _isSubmitting
          ? null
          : (value) => setState(() => _isDefault = value!),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildSubmitButton() {
    return FilledButton(
      onPressed: _isSubmitting ? null : _submitForm,
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator.adaptive(strokeWidth: 2),
            )
          : const Text('Add Card'),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Get current user from auth provider
    final currentUser = _authProvider.state.user;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to add a payment method'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final expiryDate = DateTime(
        int.parse('20${_expiryYearController.text}'),
        int.parse(_expiryMonthController.text),
      );

      final card = CreditCardModel(
        id: 'card_${DateTime.now().millisecondsSinceEpoch}',
        userId: currentUser.id, // Use actual user ID from auth
        cardNumber: _cardNumberController.text.replaceAll(' ', ''),
        holderName: _holderNameController.text,
        expiryDate: expiryDate,
        cvv: _cvvController.text,
        cardType: _cardType,
        isDefault: _isDefault,
        isVerified: true,
        addedDate: DateTime.now(),
      );

      await _paymentMethodProvider.addCreditCard(card);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credit card added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add card: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

// lib/features/wallet/screens/add_funds_screen.dart

class AddFundsScreen extends StatefulWidget {
  const AddFundsScreen({super.key});

  @override
  State<AddFundsScreen> createState() => _AddFundsScreenState();
}

class _AddFundsScreenState extends State<AddFundsScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  late final WalletProvider _walletProvider;
  late final PaymentMethodProvider _paymentMethodProvider;

  String? _selectedPaymentMethodId;
  bool _isProcessing = false;
  double _amount = 0.0;

  @override
  void initState() {
    super.initState();
    _walletProvider = GetIt.instance<WalletProvider>();
    _paymentMethodProvider = GetIt.instance<PaymentMethodProvider>();

    _amountController.addListener(_onAmountChanged);

    // Add listeners
    _walletProvider.addListener(_onProviderChanged);
    _paymentMethodProvider.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _scrollController.dispose();
    _walletProvider.removeListener(_onProviderChanged);
    _paymentMethodProvider.removeListener(_onProviderChanged);
    super.dispose();
  }

  void _onAmountChanged() {
    setState(() {
      _amount = double.tryParse(_amountController.text) ?? 0.0;
    });
  }

  void _onProviderChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final methods = _paymentMethodProvider.methods;
    final isLoading = _paymentMethodProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Funds'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isProcessing)
              LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                color: Theme.of(context).colorScheme.primary,
              ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAmountSection(),
                      const SizedBox(height: 24),
                      _buildPaymentMethodSection(methods, isLoading),
                      const SizedBox(height: 24),
                      _buildQuickAmountsSection(),
                      const SizedBox(height: 24),
                      _buildSummarySection(),
                      const SizedBox(height: 24),
                      _buildInfoSection(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount to Add',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            prefixText: '\$',
            prefixStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            hintText: '0.00',
            hintStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an amount';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Please enter a valid amount';
            }
            if (amount > WalletConstants.maxTopUpAmount) {
              return 'Maximum amount is \$${WalletConstants.maxTopUpAmount}';
            }
            return null;
          },
        ),
        const SizedBox(height: 4),
        Text(
          'Enter amount between \$${WalletConstants.minTopUpAmount} and \$${WalletConstants.maxTopUpAmount}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection(List<BaseMethod> methods, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Payment Method',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _showAddPaymentMethodSheet,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add New'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (methods.isEmpty)
          _buildEmptyPaymentMethods()
        else
          ...methods.map((method) => _buildPaymentMethodTile(method)),
      ],
    );
  }

  Widget _buildPaymentMethodTile(BaseMethod method) {
    final isSelected = _selectedPaymentMethodId == method.id;
    final isExpired = method.isExpired;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        borderRadius: BorderRadius.circular(8),
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface,
        child: InkWell(
          onTap: isExpired
              ? null
              : () {
                  setState(() {
                    _selectedPaymentMethodId = method.id;
                  });
                },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.1),
                    ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getMethodColor(method.type),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(method.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              method.displayName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration: isExpired
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isExpired
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant
                                    : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (method.isDefault) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Default',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        method.maskedDetails,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isExpired
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (isExpired)
                        Text(
                          'Expired',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPaymentMethods() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.credit_card_off,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'No Payment Methods',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Add a payment method to continue',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _showAddPaymentMethodSheet,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Payment Method'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Amounts',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: WalletConstants.quickTopUpAmounts.map((amount) {
            final isSelected = _amount == amount;
            return ActionChip(
              label: Text('\$${amount.toInt()}'),
              onPressed: () {
                _amountController.text = amount.toStringAsFixed(2);
                // Scroll to top to show amount field
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              backgroundColor: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.1),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSummarySection() {
    final processingFee = _amount * WalletConstants.processingFeePercent;
    final totalAmount = _amount + processingFee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Amount', '\$${_amount.toStringAsFixed(2)}'),
          const SizedBox(height: 4),
          _buildSummaryRow(
            'Processing Fee (${(WalletConstants.processingFeePercent * 100).toStringAsFixed(1)}%)',
            '\$${processingFee.toStringAsFixed(2)}',
          ),
          const Divider(height: 16),
          _buildSummaryRow(
            'Total',
            '\$${totalAmount.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
            fontWeight: isTotal ? FontWeight.w600 : null,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : null,
            fontSize: isTotal ? 18 : null,
            color: isTotal ? colorScheme.primary : null,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.primaryContainer.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'A ${(WalletConstants.processingFeePercent * 100).toStringAsFixed(1)}% processing fee applies. '
              'Funds are added instantly to your wallet.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isAmountValid =
        _amount >= WalletConstants.minTopUpAmount &&
        _amount <= WalletConstants.maxTopUpAmount;
    final isPaymentMethodSelected = _selectedPaymentMethodId != null;
    final isEnabled =
        isAmountValid && isPaymentMethodSelected && !_isProcessing;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: isEnabled ? _processAddFunds : null,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_balance_wallet, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Add Funds',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _processAddFunds() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    if (_selectedPaymentMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final amount = double.parse(_amountController.text);
      await _walletProvider.topUp(amount, _selectedPaymentMethodId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully added \$${amount.toStringAsFixed(2)} to your wallet',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add funds: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showAddPaymentMethodSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddPaymentMethodSheet(),
    ).then((_) {
      // Refresh payment methods when sheet is closed
      _paymentMethodProvider.refreshPaymentMethods();
    });
  }

  Color _getMethodColor(MethodType type) {
    switch (type) {
      case MethodType.creditCard:
      case MethodType.debitCard:
        return Colors.blue;
      case MethodType.bankAccount:
        return Colors.green;
      case MethodType.stripe:
        return Colors.purple;
      case MethodType.paypal:
        return Colors.blue.shade800;
    }
  }
}

// lib/features/wallet/widgets/add_payment_method_sheet.dart

class AddPaymentMethodSheet extends StatelessWidget {
  const AddPaymentMethodSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Add Payment Method',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    _buildMethodTile(
                      icon: Icons.credit_card,
                      color: Colors.blue,
                      title: 'Credit/Debit Card',
                      subtitle: 'Visa, Mastercard, American Express',
                      onTap: () => _showCardForm(context),
                    ),
                    const Divider(),
                    _buildMethodTile(
                      icon: Icons.account_balance,
                      color: Colors.green,
                      title: 'Bank Account',
                      subtitle: 'Direct bank transfer',
                      onTap: () => _showBankAccountForm(context),
                    ),
                    const Divider(),
                    _buildMethodTile(
                      icon: Icons.account_balance_wallet,
                      color: Colors.purple,
                      title: 'Stripe Account',
                      subtitle: 'For payouts and payments',
                      onTap: () => _showStripeForm(context),
                    ),
                    const Divider(),
                    _buildMethodTile(
                      icon: Icons.payment,
                      color: Colors.blue.shade800,
                      title: 'PayPal Account',
                      subtitle: 'For payouts and payments',
                      onTap: () => _showPayPalForm(context),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMethodTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  void _showCardForm(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreditCardFormSheet(),
    );
  }

  void _showBankAccountForm(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BankAccountFormSheet(),
    );
  }

  void _showStripeForm(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const StripeFormSheet(),
    );
  }

  void _showPayPalForm(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PayPalFormSheet(),
    );
  }
}

// lib/features/wallet/widgets/transaction_details_sheet.dart

class TransactionDetailsSheet extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailsSheet({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Status icon
          Icon(
            transaction.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
            size: 48,
            color: transaction.isCredit ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 8),

          // Amount
          Text(
            transaction.formattedAmount,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: transaction.isCredit ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 4),

          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: transaction.statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              transaction.status.name.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: transaction.statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Details
          _buildDetailItem(context, 'Description', transaction.description),
          _buildDivider(context),
          _buildDetailItem(context, 'Date', _formatDate(transaction.timestamp)),
          _buildDivider(context),
          _buildDetailItem(
            context,
            'Transaction ID',
            transaction.id,
            isMonospace: true,
          ),
          _buildDivider(context),
          _buildDetailItem(
            context,
            'Status',
            transaction.status.name.toUpperCase(),
          ),
          const SizedBox(height: 24),

          // Close button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    String label,
    String value, {
    bool isMonospace = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// lib/features/wallet/widgets/payment_method_options_sheet.dart

class PaymentMethodOptionsSheet extends StatelessWidget {
  final BaseMethod method;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  const PaymentMethodOptionsSheet({
    super.key,
    required this.method,
    required this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getMethodColor(method.type),
                  shape: BoxShape.circle,
                ),
                child: Icon(method.icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      method.maskedDetails,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          if (!method.isDefault) ...[
            ListTile(
              leading: Icon(
                Icons.check_circle_outline,
                color: colorScheme.primary,
              ),
              title: const Text('Set as Default'),
              onTap: () {
                Navigator.pop(context);
                onSetDefault();
              },
            ),
            const Divider(height: 8),
          ],
          ListTile(
            leading: Icon(Icons.delete_outline, color: colorScheme.error),
            title: Text('Delete', style: TextStyle(color: colorScheme.error)),
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
          const Divider(height: 8),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Color _getMethodColor(MethodType type) {
    switch (type) {
      case MethodType.creditCard:
      case MethodType.debitCard:
        return Colors.blue;
      case MethodType.bankAccount:
        return Colors.green;
      case MethodType.stripe:
        return Colors.purple;
      case MethodType.paypal:
        return Colors.blue.shade800;
    }
  }
}

// lib/features/wallet/widgets/modern_balance_card.dart

class ModernBalanceCard extends StatelessWidget {
  final double balance;
  final String currency;
  final VoidCallback onAddFunds;
  final VoidCallback? onWithdraw;

  const ModernBalanceCard({
    super.key,
    required this.balance,
    required this.currency,
    required this.onAddFunds,
    this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.primaryContainer],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: colorScheme.onPrimary),
              const SizedBox(width: 8),
              Text(
                'Wallet Balance',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimary.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$currency ${balance.toStringAsFixed(2)}',
            style: textTheme.displaySmall?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onAddFunds,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.onPrimary,
                    foregroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Add Funds'),
                ),
              ),
              if (onWithdraw != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onWithdraw,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onPrimary,
                      side: BorderSide(
                        color: colorScheme.onPrimary.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Withdraw'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// lib/features/wallet/widgets/modern_section_card.dart
class ModernSectionCard extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  final Widget child;

  const ModernSectionCard({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (actionText != null && onAction != null)
                  TextButton(onPressed: onAction, child: Text(actionText!)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: child,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// lib/features/wallet/widgets/modern_transaction_item.dart
class ModernTransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onTap;

  const ModernTransactionItem({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: transaction.isCredit
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                transaction.isCredit
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                color: transaction.isCredit ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatDate(transaction.timestamp),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction.formattedAmount,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: transaction.isCredit ? Colors.green : Colors.red,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: transaction.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    transaction.status.name,
                    style: textTheme.labelSmall?.copyWith(
                      color: transaction.statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// lib/features/wallet/widgets/modern_payment_method_item.dart
class ModernPaymentMethodItem extends StatelessWidget {
  final BaseMethod method;
  final VoidCallback onTap;

  const ModernPaymentMethodItem({
    super.key,
    required this.method,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getMethodColor(method.type),
                shape: BoxShape.circle,
              ),
              child: Icon(method.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        method.displayName,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (method.isDefault) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Default',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    method.maskedDetails,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Color _getMethodColor(MethodType type) {
    switch (type) {
      case MethodType.creditCard:
      case MethodType.debitCard:
        return Colors.blue;
      case MethodType.bankAccount:
        return Colors.green;
      case MethodType.stripe:
        return Colors.purple;
      case MethodType.paypal:
        return Colors.blue.shade800;
    }
  }
}

// lib/features/wallet/widgets/confirmation_dialog.dart

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String? cancelText;
  final Color confirmColor;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    this.cancelText,
    this.confirmColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText ?? 'Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: colorScheme.onError,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
}

// lib/features/wallet/widgets/state_widgets.dart

class ErrorStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const ErrorStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              title,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton(onPressed: onAction, child: Text(actionText!)),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool compact;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(
              title,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              message,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// lib/features/wallet/widgets/action_card.dart

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/features/wallet/widgets/paypal_form_sheet.dart

class PayPalFormSheet extends StatefulWidget {
  const PayPalFormSheet({super.key});

  @override
  State<PayPalFormSheet> createState() => _PayPalFormSheetState();
}

class _PayPalFormSheetState extends State<PayPalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  late final PaymentMethodProvider _paymentMethodProvider;
  late final AuthProvider _authProvider;

  String _country = 'US';
  bool _isDefault = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _paymentMethodProvider = GetIt.instance<PaymentMethodProvider>();
    _authProvider = GetIt.instance<AuthProvider>();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (_isSubmitting)
              LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: colorScheme.primary,
              ),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildEmailField(),
                  const SizedBox(height: 16),
                  _buildCountryDropdown(),
                  const SizedBox(height: 16),
                  _buildNameFields(),
                  const SizedBox(height: 16),
                  _buildDefaultCheckbox(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
        const Spacer(),
        Text(
          'Connect PayPal Account',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      enabled: !_isSubmitting,
      decoration: const InputDecoration(
        labelText: 'PayPal Email',
        border: OutlineInputBorder(),
        hintText: 'user@example.com',
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter PayPal email';
        }
        if (!value.contains('@')) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildCountryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _country,
      decoration: const InputDecoration(
        labelText: 'Country',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'US', child: Text('United States')),
        DropdownMenuItem(value: 'CA', child: Text('Canada')),
        DropdownMenuItem(value: 'UK', child: Text('United Kingdom')),
        DropdownMenuItem(value: 'AU', child: Text('Australia')),
      ],
      onChanged: _isSubmitting
          ? null
          : (value) => setState(() => _country = value!),
    );
  }

  Widget _buildNameFields() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _firstNameController,
            enabled: !_isSubmitting,
            decoration: const InputDecoration(
              labelText: 'First Name',
              border: OutlineInputBorder(),
              hintText: 'John',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: _lastNameController,
            enabled: !_isSubmitting,
            decoration: const InputDecoration(
              labelText: 'Last Name',
              border: OutlineInputBorder(),
              hintText: 'Doe',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultCheckbox() {
    return CheckboxListTile(
      title: const Text('Set as default payout method'),
      value: _isDefault,
      onChanged: _isSubmitting
          ? null
          : (value) => setState(() => _isDefault = value!),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildSubmitButton() {
    return FilledButton(
      onPressed: _isSubmitting ? null : _submitForm,
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator.adaptive(strokeWidth: 2),
            )
          : const Text('Connect PayPal'),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = _authProvider.state.user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to connect PayPal'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final paypalAccount = PayPalAccountModel(
        id: 'paypal_${DateTime.now().millisecondsSinceEpoch}',
        userId: currentUser.id,
        email: _emailController.text,
        country: _country,
        firstName: _firstNameController.text.isNotEmpty
            ? _firstNameController.text
            : null,
        lastName: _lastNameController.text.isNotEmpty
            ? _lastNameController.text
            : null,
        isDefault: _isDefault,
        isVerified: true,
        payoutsEnabled: true,
        addedDate: DateTime.now(),
        verifiedDate: DateTime.now(),
      );

      await _paymentMethodProvider.addPayPalAccount(paypalAccount);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PayPal account connected successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect PayPal: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class StripeFormSheet extends StatefulWidget {
  const StripeFormSheet({super.key});

  @override
  State<StripeFormSheet> createState() => _StripeFormSheetState();
}

class _StripeFormSheetState extends State<StripeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _accountIdController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  late final PaymentMethodProvider _paymentMethodProvider;
  late final AuthProvider _authProvider;

  String _country = 'US';
  StripeBusinessType _businessType = StripeBusinessType.individual;
  bool _isDefault = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _paymentMethodProvider = GetIt.instance<PaymentMethodProvider>();
    _authProvider = GetIt.instance<AuthProvider>();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _accountIdController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (_isSubmitting)
              LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: colorScheme.primary,
              ),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildEmailField(),
                  const SizedBox(height: 16),
                  _buildAccountIdField(),
                  const SizedBox(height: 16),
                  _buildCountryDropdown(),
                  const SizedBox(height: 16),
                  _buildBusinessTypeDropdown(),
                  const SizedBox(height: 16),
                  _buildNameFields(),
                  const SizedBox(height: 16),
                  _buildDefaultCheckbox(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
        const Spacer(),
        Text(
          'Connect Stripe Account',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      enabled: !_isSubmitting,
      decoration: const InputDecoration(
        labelText: 'Email Address',
        border: OutlineInputBorder(),
        hintText: 'user@example.com',
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter email address';
        }
        if (!value.contains('@')) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildAccountIdField() {
    return TextFormField(
      controller: _accountIdController,
      enabled: !_isSubmitting,
      decoration: const InputDecoration(
        labelText: 'Stripe Account ID',
        border: OutlineInputBorder(),
        hintText: 'acct_123456789',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter Stripe account ID';
        }
        return null;
      },
    );
  }

  Widget _buildCountryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _country,
      decoration: const InputDecoration(
        labelText: 'Country',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'US', child: Text('United States')),
        DropdownMenuItem(value: 'CA', child: Text('Canada')),
        DropdownMenuItem(value: 'UK', child: Text('United Kingdom')),
        DropdownMenuItem(value: 'AU', child: Text('Australia')),
      ],
      onChanged: _isSubmitting
          ? null
          : (value) => setState(() => _country = value!),
    );
  }

  Widget _buildBusinessTypeDropdown() {
    return DropdownButtonFormField<StripeBusinessType>(
      initialValue: _businessType,
      decoration: const InputDecoration(
        labelText: 'Business Type',
        border: OutlineInputBorder(),
      ),
      items: StripeBusinessType.values.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type.name.toUpperCase()),
        );
      }).toList(),
      onChanged: _isSubmitting
          ? null
          : (value) => setState(() => _businessType = value!),
    );
  }

  Widget _buildNameFields() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _firstNameController,
            enabled: !_isSubmitting,
            decoration: const InputDecoration(
              labelText: 'First Name',
              border: OutlineInputBorder(),
              hintText: 'John',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: _lastNameController,
            enabled: !_isSubmitting,
            decoration: const InputDecoration(
              labelText: 'Last Name',
              border: OutlineInputBorder(),
              hintText: 'Doe',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultCheckbox() {
    return CheckboxListTile(
      title: const Text('Set as default payout method'),
      value: _isDefault,
      onChanged: _isSubmitting
          ? null
          : (value) => setState(() => _isDefault = value!),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildSubmitButton() {
    return FilledButton(
      onPressed: _isSubmitting ? null : _submitForm,
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator.adaptive(strokeWidth: 2),
            )
          : const Text('Connect Stripe'),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = _authProvider.state.user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to connect Stripe'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final stripeAccount = StripeAccountModel(
        id: 'stripe_${DateTime.now().millisecondsSinceEpoch}',
        userId: currentUser.id,
        accountId: _accountIdController.text,
        email: _emailController.text,
        country: _country,
        businessType: _businessType,
        firstName: _firstNameController.text.isNotEmpty
            ? _firstNameController.text
            : null,
        lastName: _lastNameController.text.isNotEmpty
            ? _lastNameController.text
            : null,
        isDefault: _isDefault,
        isVerified: true,
        payoutsEnabled: true,
        addedDate: DateTime.now(),
        verifiedDate: DateTime.now(),
      );

      await _paymentMethodProvider.addStripeAccount(stripeAccount);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stripe account connected successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect Stripe: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class BankAccountFormSheet extends StatefulWidget {
  const BankAccountFormSheet({super.key});

  @override
  State<BankAccountFormSheet> createState() => _BankAccountFormSheetState();
}

class _BankAccountFormSheetState extends State<BankAccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _routingNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountHolderNameController = TextEditingController();

  late final PaymentMethodProvider _paymentMethodProvider;
  late final AuthProvider _authProvider;

  AccountType _accountType = AccountType.checking;
  String _accountHolderType = 'individual';
  bool _isDefault = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _paymentMethodProvider = GetIt.instance<PaymentMethodProvider>();
    _authProvider = GetIt.instance<AuthProvider>();
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _routingNumberController.dispose();
    _bankNameController.dispose();
    _accountHolderNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (_isSubmitting)
              LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: colorScheme.primary,
              ),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildBankNameField(),
                  const SizedBox(height: 16),
                  _buildAccountTypeDropdown(),
                  const SizedBox(height: 16),
                  _buildAccountHolderTypeDropdown(),
                  const SizedBox(height: 16),
                  _buildAccountHolderNameField(),
                  const SizedBox(height: 16),
                  _buildRoutingNumberField(),
                  const SizedBox(height: 16),
                  _buildAccountNumberField(),
                  const SizedBox(height: 16),
                  _buildDefaultCheckbox(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
        const Spacer(),
        Text(
          'Add Bank Account',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildBankNameField() {
    return TextFormField(
      controller: _bankNameController,
      enabled: !_isSubmitting,
      decoration: const InputDecoration(
        labelText: 'Bank Name',
        border: OutlineInputBorder(),
        hintText: 'e.g., Chase Bank',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter bank name';
        }
        return null;
      },
    );
  }

  Widget _buildAccountTypeDropdown() {
    return DropdownButtonFormField<AccountType>(
      initialValue: _accountType,
      decoration: const InputDecoration(
        labelText: 'Account Type',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(
          value: AccountType.checking,
          child: Text('Checking Account'),
        ),
        DropdownMenuItem(
          value: AccountType.savings,
          child: Text('Savings Account'),
        ),
      ],
      onChanged: _isSubmitting
          ? null
          : (value) => setState(() => _accountType = value!),
    );
  }

  Widget _buildAccountHolderTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _accountHolderType,
      decoration: const InputDecoration(
        labelText: 'Account Holder Type',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'individual', child: Text('Individual')),
        DropdownMenuItem(value: 'company', child: Text('Business')),
      ],
      onChanged: _isSubmitting
          ? null
          : (value) => setState(() => _accountHolderType = value!),
    );
  }

  Widget _buildAccountHolderNameField() {
    return TextFormField(
      controller: _accountHolderNameController,
      enabled: !_isSubmitting,
      decoration: const InputDecoration(
        labelText: 'Account Holder Name',
        border: OutlineInputBorder(),
        hintText: 'John Doe or Company Name',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter account holder name';
        }
        return null;
      },
    );
  }

  Widget _buildRoutingNumberField() {
    return TextFormField(
      controller: _routingNumberController,
      enabled: !_isSubmitting,
      decoration: const InputDecoration(
        labelText: 'Routing Number',
        border: OutlineInputBorder(),
        hintText: '123456789',
      ),
      keyboardType: TextInputType.number,
      maxLength: 9,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter routing number';
        }
        if (value.length != 9) {
          return 'Routing number must be 9 digits';
        }
        return null;
      },
    );
  }

  Widget _buildAccountNumberField() {
    return TextFormField(
      controller: _accountNumberController,
      enabled: !_isSubmitting,
      decoration: const InputDecoration(
        labelText: 'Account Number',
        border: OutlineInputBorder(),
        hintText: '1234567890',
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter account number';
        }
        if (value.length < 4) {
          return 'Account number too short';
        }
        return null;
      },
    );
  }

  Widget _buildDefaultCheckbox() {
    return CheckboxListTile(
      title: const Text('Set as default payment method'),
      value: _isDefault,
      onChanged: _isSubmitting
          ? null
          : (value) => setState(() => _isDefault = value!),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildSubmitButton() {
    return FilledButton(
      onPressed: _isSubmitting ? null : _submitForm,
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator.adaptive(strokeWidth: 2),
            )
          : const Text('Add Bank Account'),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = _authProvider.state.user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to add a payment method'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final bankAccount = BankAccountModel(
        id: 'bank_${DateTime.now().millisecondsSinceEpoch}',
        userId: currentUser.id,
        accountNumber: _accountNumberController.text,
        routingNumber: _routingNumberController.text,
        bankName: _bankNameController.text,
        accountType: _accountType,
        accountHolderName: _accountHolderNameController.text,
        accountHolderType: _accountHolderType,
        isDefault: _isDefault,
        isVerified: false,
        addedDate: DateTime.now(),
      );

      await _paymentMethodProvider.addBankAccount(bankAccount);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bank account added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add bank account: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
