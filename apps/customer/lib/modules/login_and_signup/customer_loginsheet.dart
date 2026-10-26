import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_provider.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_state.dart';
import 'package:lehwipalancecustomerv1/core/router/route_guards.dart';

import 'package:lehwipalancecustomerv1/core/router/route_paths.dart';
import 'package:lehwipalancecustomerv1/theme/provider/theme_provider.dart';
import 'package:provider/provider.dart';

import 'package:lehwipalancecustomerv1/theme/app_constants.dart';

class LoginBottomSheet extends StatefulWidget {
  final String? redirectPath;

  const LoginBottomSheet({super.key, this.redirectPath});

  @override
  State<LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends State<LoginBottomSheet> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() => isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      bool success = false;

      if (emailController.text.trim().isEmpty &&
          passwordController.text.trim().isEmpty) {
        success = await authProvider.signInAsCustomer();
      } else {
        success = await authProvider.signInWithEmail(
          emailController.text.trim(),
        );
      }

      if (!mounted) return;

      if (success) {
        final customer = authProvider.customerUser;
        Navigator.of(context).pop();
        RouteGuards.clearCache();

        String redirectPath = widget.redirectPath ?? RoutePaths.home;
        if (redirectPath.isNotEmpty && !redirectPath.startsWith('/')) {
          redirectPath = '/$redirectPath';
        }

        if (kDebugMode) {
          debugPrint('[LoginBottomSheet] Redirecting to: $redirectPath');
        }

        context.go(redirectPath);

        if (!mounted) return;
        context.showSnackBar(
          customer != null
              ? '${LanguageConstants.welcomeBack}, ${customer.name}!'
              : LanguageConstants.loginSuccess,
        );
      } else {
        if (!mounted) return;
        context.showSnackBar(LanguageConstants.loginFailedRetry, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar('${LanguageConstants.error}: $e', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> signUp() async {
    await context.push(RoutePaths.signup);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textStyles;
    final authProvider = context.watch<AuthProvider>();
    final authState = authProvider.state;

    return Padding(
      padding: EdgeInsets.only(
        left: AppConstants.paddingL,
        right: AppConstants.paddingL,
        top: AppConstants.paddingXL,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + AppConstants.paddingXL,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(AppConstants.radiusRound),
              ),
            ),
            const SizedBox(height: AppConstants.paddingXL),

            // Icon
            Icon(
              Icons.lock_outline_rounded,
              size: AppConstants.iconXL * 2,
              color: colorScheme.primary,
            ),
            const SizedBox(height: AppConstants.paddingM),

            Text(
              LanguageConstants.loginRequired,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingS),

            Text(
              widget.redirectPath != null
                  ? '${LanguageConstants.loginToContinueTo} ${widget.redirectPath}'
                  : LanguageConstants.pleaseLoginToContinue,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppConstants.paddingXL),

            // Email field
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: LanguageConstants.emailOptional,
                hintText: LanguageConstants.leaveBlankAutoLogin,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),

            // Password field
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: LanguageConstants.passwordOptional,
                hintText: LanguageConstants.leaveBlankAutoLogin,
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: AppConstants.space5),

            // Error banner
            if (authState is AuthError)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.paddingM),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  border: Border.all(
                    color: colorScheme.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: AppConstants.paddingS),
                    Expanded(
                      child: Text(
                        authState.error!,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppConstants.paddingXL),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isLoading ? null : login,
                    icon: isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.login_rounded),
                    label: Text(
                      isLoading
                          ? LanguageConstants.signingIn
                          : LanguageConstants.autoLoginAsCustomer,
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                        AppConstants.buttonHeightL,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingM),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: isLoading ? null : signUp,
                    icon: const Icon(Icons.account_box_outlined),
                    label: const Text(LanguageConstants.signUp),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                        AppConstants.buttonHeightL,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingM),

            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text(LanguageConstants.cancel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper method to show the login bottom sheet
void showLoginSheet(BuildContext context, {String? redirectPath}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppConstants.radiusXL),
      ),
    ),
    builder: (context) => LoginBottomSheet(redirectPath: redirectPath),
  );
}
