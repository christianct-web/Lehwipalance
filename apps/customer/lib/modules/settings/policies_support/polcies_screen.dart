// ==================== POLICIES SCREEN ====================
import 'package:flutter/material.dart';

class PoliciesScreen extends StatelessWidget {
  const PoliciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Policies'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPolicyCard(
            context,
            'Privacy Policy',
            'Learn how we collect, use, and protect your personal information. We are committed to maintaining the privacy and security of your data.',
            Icons.privacy_tip,
            Colors.blue,
          ),
          _buildPolicyCard(
            context,
            'Terms of Service',
            'Understand the terms and conditions for using our platform. By using our services, you agree to these terms.',
            Icons.assignment,
            Colors.purple,
          ),
          _buildPolicyCard(
            context,
            'Cookie Policy',
            'Information about how we use cookies to improve your experience and analyze site usage.',
            Icons.cookie,
            Colors.orange,
          ),
          _buildPolicyCard(
            context,
            'Data Security',
            'Learn about our security measures to protect your data from unauthorized access and breaches.',
            Icons.security,
            Colors.green,
          ),
          _buildPolicyCard(
            context,
            'Refund Policy',
            'Understand our refund and cancellation procedures for services and subscriptions.',
            Icons.receipt_long,
            Colors.red,
          ),
          _buildPolicyCard(
            context,
            'Community Guidelines',
            'Read our guidelines for maintaining a positive and inclusive community environment.',
            Icons.group,
            Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
