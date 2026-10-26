// ==================== FOLLOWINGS SCREEN ====================
import 'package:flutter/material.dart';

class FollowingsScreen extends StatelessWidget {
  const FollowingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Followings'),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (context, index) {
          return _buildFollowingItem(context, index);
        },
      ),
    );
  }

  Widget _buildFollowingItem(BuildContext context, int index) {
    final names = [
      'Alice Johnson',
      'Bob Smith',
      'Carol White',
      'David Brown',
      'Emma Wilson',
      'Frank Miller',
      'Grace Davis',
      'Henry Garcia',
      'Ivy Martinez',
      'Jack Lee',
    ];

    final usernames = [
      '@alice_j',
      '@bob_s',
      '@carol_w',
      '@david_b',
      '@emma_w',
      '@frank_m',
      '@grace_d',
      '@henry_g',
      '@ivy_m',
      '@jack_l',
    ];

    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colors[index % colors.length].withValues(alpha: 0.2),
          child: Text(
            names[index][0],
            style: TextStyle(
              color: colors[index % colors.length],
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          names[index],
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          usernames[index],
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: FilledButton.tonal(
          onPressed: () {},
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            visualDensity: VisualDensity.compact,
          ),
          child: const Text('Following'),
        ),
      ),
    );
  }
}
