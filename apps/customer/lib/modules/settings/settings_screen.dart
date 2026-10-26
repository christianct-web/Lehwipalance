import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_provider.dart';

import 'package:lehwipalancecustomerv1/core/base/service_locator.dart';
import 'package:lehwipalancecustomerv1/core/router/route_guards.dart';

import 'package:lehwipalancecustomerv1/theme/model/enum_models.dart';
import 'package:lehwipalancecustomerv1/theme/provider/theme_provider.dart';

//import 'package:lehwi_palance_manager/core/themes/theme_provider.dart';

class OrganisationListingSettingsScreen extends StatelessWidget {
  const OrganisationListingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = getIt<ThemeProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Settings'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primaryContainer,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appearance',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.color_lens),
                          title: const Text('Theme Mode'),
                          subtitle: Text(
                            themeProvider.themeModeType
                                .toString()
                                .split('.')
                                .last,
                          ),
                          trailing: Switch(
                            value: themeProvider.themeMode == ThemeMode.dark,
                            onChanged: (value) {
                              themeProvider.toggleTheme();
                            },
                          ),
                        ),
                        const Divider(),

                        // Use RadioGroup to manage the radio buttons
                        RadioGroup<ThemeModeType>(
                          groupValue: themeProvider.themeModeType,
                          onChanged: (ThemeModeType? value) {
                            if (value != null) {
                              themeProvider.setThemeMode(value);
                            }
                          },
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.brightness_medium),
                                title: const Text('Use System Theme'),
                                trailing: Radio<ThemeModeType>(
                                  value: ThemeModeType.system,
                                ),
                              ),
                              ListTile(
                                leading: const Icon(Icons.light_mode),
                                title: const Text('Light Theme'),
                                trailing: Radio<ThemeModeType>(
                                  value: ThemeModeType.light,
                                ),
                              ),
                              ListTile(
                                leading: const Icon(Icons.dark_mode),
                                title: const Text('Dark Theme'),
                                trailing: Radio<ThemeModeType>(
                                  value: ThemeModeType.dark,
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scanner Settings',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.vibration),
                          title: const Text('Vibration on Scan'),
                          trailing: Switch(value: true, onChanged: (value) {}),
                        ),
                        ListTile(
                          leading: Icon(Icons.speaker),
                          title: const Text('Sound on Scan'),
                          trailing: Switch(value: true, onChanged: (value) {}),
                        ),
                        ListTile(
                          leading: const Icon(Icons.flash_on),
                          title: const Text('Auto Flash'),
                          trailing: Switch(value: false, onChanged: (value) {}),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Management',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.backup),
                          title: const Text('Backup Data'),
                          onTap: () {
                            // Backup functionality
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.restore),
                          title: const Text('Restore Data'),
                          onTap: () {
                            // Restore functionality
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete),
                          title: const Text('Clear All Data'),
                          textColor: Colors.red,
                          iconColor: Colors.red,
                          onTap: () {
                            _showClearDataDialog(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.info),
                          title: const Text('Version'),
                          subtitle: const Text('1.0.0'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.privacy_tip),
                          title: const Text('Privacy Policy'),
                          onTap: () {
                            // Open privacy policy
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.description),
                          title: const Text('Terms of Service'),
                          onTap: () {
                            // Open terms of service
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear All Data'),
          content: const Text(
            'Are you sure you want to clear all ticket data? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Clear data logic
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear Data'),
            ),
          ],
        );
      },
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            subtitle: Text('Manage notification preferences'),
          ),
          const ListTile(
            leading: Icon(Icons.language),
            title: Text('Language'),
            subtitle: Text('English'),
          ),
          const ListTile(
            leading: Icon(Icons.dark_mode),
            title: Text('Theme'),
            subtitle: Text('System default'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('About'),
            subtitle: Text('Version 1.0.0'),
          ),

          // Logout button with functionality
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _logout(context),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    // Capture the router & providers BEFORE any async gap
    final router = GoRouter.of(context);
    final authProvider = getIt<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    // 1. Close the confirm dialog
    rootNavigator.pop();

    // 2. Show a loading dialog on the ROOT navigator so it survives
    //    being popped by the router redirect.
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      ),
    );

    // Let the dialog actually mount before we potentially pop it.
    await Future<void>.delayed(Duration.zero);

    try {
      // 3. Perform logout
      await authProvider.signOut();

      // 4. Clear the guard's redirect cache — CRITICAL
      RouteGuards.clearCache();

      // 5. Close loading dialog (if still mounted)
      if (rootNavigator.mounted && rootNavigator.canPop()) {
        rootNavigator.pop();
      }

      // 6. Go home
      router.go('/home');
    } catch (e) {
      debugPrint('[SettingsScreen] Error during logout: $e');

      if (rootNavigator.mounted && rootNavigator.canPop()) {
        rootNavigator.pop();
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
