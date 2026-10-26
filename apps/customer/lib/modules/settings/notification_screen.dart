// ==================== NOTIFICATION SETTINGS SCREEN ====================
import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingGroup(context, 'General Settings', [
            _buildSwitchTile(
              context,
              'Push Notifications',
              'Enable push notifications for all updates',
              Icons.notifications_active,
              true,
            ),
            _buildSwitchTile(
              context,
              'Email Notifications',
              'Receive notifications via email',
              Icons.email,
              true,
            ),
            _buildSwitchTile(
              context,
              'SMS Notifications',
              'Receive notifications via SMS',
              Icons.sms,
              false,
            ),
          ]),
          _buildSettingGroup(context, 'Activity Alerts', [
            _buildSwitchTile(
              context,
              'Likes',
              'Get notified when someone likes your content',
              Icons.favorite_border,
              true,
            ),
            _buildSwitchTile(
              context,
              'Comments',
              'Get notified when someone comments',
              Icons.comment,
              true,
            ),
            _buildSwitchTile(
              context,
              'Follows',
              'Get notified when someone follows you',
              Icons.person_add,
              false,
            ),
          ]),
          _buildSettingGroup(context, 'Reminders', [
            _buildSwitchTile(
              context,
              'Daily Reminders',
              'Get daily activity reminders',
              Icons.today,
              false,
            ),
            _buildSwitchTile(
              context,
              'Weekly Summary',
              'Receive weekly activity summary',
              Icons.summarize,
              true,
            ),
          ]),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset All Settings'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingGroup(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Card(child: Column(children: children)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool initialValue,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return SwitchListTile(
      secondary: Icon(icon, color: colorScheme.primary),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      value: initialValue,
      onChanged: (value) {},
      activeThumbColor: colorScheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
