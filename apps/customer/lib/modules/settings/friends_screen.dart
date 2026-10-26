// ==================== FRIENDS SCREEN ====================
import 'package:flutter/material.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Friends'),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(text: 'All', icon: Icon(Icons.people)),
              Tab(text: 'Online', icon: Icon(Icons.circle)),
              Tab(text: 'Requests', icon: Icon(Icons.person_add)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFriendList(context, 'All Friends'),
            _buildFriendList(context, 'Online Friends'),
            _buildFriendList(context, 'Friend Requests'),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendList(BuildContext context, String type) {
    final friends = [
      {'name': 'Sarah Johnson', 'status': 'Online', 'avatar': 'SJ'},
      {'name': 'Michael Chen', 'status': 'Online', 'avatar': 'MC'},
      {'name': 'Emily Davis', 'status': 'Offline', 'avatar': 'ED'},
      {'name': 'James Wilson', 'status': 'Online', 'avatar': 'JW'},
      {'name': 'Maria Garcia', 'status': 'Offline', 'avatar': 'MG'},
      {'name': 'Robert Taylor', 'status': 'Online', 'avatar': 'RT'},
      {'name': 'Jennifer Lee', 'status': 'Offline', 'avatar': 'JL'},
      {'name': 'William Brown', 'status': 'Online', 'avatar': 'WB'},
    ];

    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.green,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        final color = colors[index % colors.length];
        final isOnline = friend['status'] == 'Online';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Text(
                    friend['avatar']!,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        border: Border.all(color: Colors.white, width: 2),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              friend['name']!,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              friend['status']!,
              style: TextStyle(
                color: isOnline ? Colors.green : colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            trailing: type == 'Friend Requests'
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () {},
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green.withValues(alpha: 0.1),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {},
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  )
                : IconButton(
                    icon: const Icon(Icons.message),
                    onPressed: () {},
                    color: colorScheme.primary,
                  ),
          ),
        );
      },
    );
  }
}
