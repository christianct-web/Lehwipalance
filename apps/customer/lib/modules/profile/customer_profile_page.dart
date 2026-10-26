import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_provider.dart';
import 'package:lehwipalancecustomerv1/core/models/user_models.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final customer = authProvider.customerUser;

    if (customer == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            ProfileHeader(customer: customer),
            const SizedBox(height: 24),
            ProfileStats(customer: customer),
            const SizedBox(height: 32),
            ProfileMenuGrid(customer: customer),
            const SizedBox(height: 24),
            ProfileActionButton(onPressed: () => _handleLogout(context)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authService.signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully')),
        );
        context.go('/login');
      }
    }
  }
}

// widgets/profile_header.dart
class ProfileHeader extends StatelessWidget {
  final CustomerDTO customer;

  const ProfileHeader({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blue.shade100,
              backgroundImage: customer.imageUrl.isNotEmpty
                  ? NetworkImage(customer.imageUrl)
                  : null,
              child: customer.imageUrl.isEmpty
                  ? const Icon(Icons.person, size: 60, color: Colors.blue)
                  : null,
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          customer.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          customer.email,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        if (customer.isActive && !customer.isBanned)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 16, color: Colors.green.shade700),
                const SizedBox(width: 4),
                Text(
                  'Verified Account',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// widgets/profile_stats.dart
class ProfileStats extends StatelessWidget {
  final CustomerDTO customer;

  const ProfileStats({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            label: 'Bookings',
            value: customer.bookingIds.length.toString(),
            icon: Icons.calendar_today_outlined,
          ),
          _buildStatItem(
            label: 'Favorites',
            value: customer.savedMerchantIds.length.toString(),
            icon: Icons.favorite_border_outlined,
          ),
          _buildStatItem(
            label: 'Following',
            value: customer.followingOrganisationsIds.length.toString(),
            icon: Icons.people_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

// widgets/profile_menu_grid.dart
class ProfileMenuGrid extends StatelessWidget {
  final CustomerDTO customer;

  const ProfileMenuGrid({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final menuItems = _buildMenuItems(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        return _buildMenuItem(context, menuItems[index]);
      },
    );
  }

  List<_MenuItem> _buildMenuItems(BuildContext context) {
    return [
      _MenuItem(
        icon: Icons.shopping_bag_outlined,
        label: 'Orders',
        route: '/profile/orders',
        color: Colors.blue,
      ),
      _MenuItem(
        icon: Icons.favorite_border_outlined,
        label: 'Favorites',
        route: '/profile/favorites',
        color: Colors.red,
        count: customer.savedMerchantIds.length,
      ),
      _MenuItem(
        icon: Icons.people_outline,
        label: 'Followings',
        route: '/profile/followings',
        color: Colors.purple,
        count: customer.followingOrganisationsIds.length,
      ),
      _MenuItem(
        icon: Icons.wallet_outlined,
        label: 'Wallet',
        route: '/profile/wallet',
        color: Colors.green,
      ),
      _MenuItem(
        icon: Icons.location_on_outlined, // Changed from settings
        label: 'Location Filters', // New item
        route: '/profile/location-filters', // New route
        color: Colors.blue, // You can choose any color
      ),
      _MenuItem(
        icon: Icons.settings_outlined,
        label: 'Settings',
        route: '/profile/settings',
        color: Colors.orange,
      ),
      _MenuItem(
        icon: Icons.gavel_outlined,
        label: 'Policies',
        route: '/profile/policies',
        color: Colors.teal,
      ),
      _MenuItem(
        icon: Icons.people_alt_outlined,
        label: 'Friends',
        route: '/profile/friends',
        color: Colors.pink,
      ),
      _MenuItem(
        icon: Icons.notifications_outlined,
        label: 'Notifications',
        route: '/profile/notifications',
        color: Colors.indigo,
        showBadge: customer.notificationsEnabled,
      ),
      _MenuItem(
        icon: Icons.help_outline,
        label: 'Support',
        route: '/profile/support',
        color: Colors.grey,
      ),
    ];
  }

  Widget _buildMenuItem(BuildContext context, _MenuItem item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => context.push(item.route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, color: item.color, size: 28),
                  ),
                  if (item.count != null && item.count! > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          item.count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  if (item.showBadge == true)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  final int? count;
  final bool showBadge;

  _MenuItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
    this.count,
    this.showBadge = false,
  });
}

// widgets/profile_action_button.dart
class ProfileActionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ProfileActionButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout, size: 20),
        label: const Text(
          'Logout',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// extensions/profile_extensions.dart
extension ProfileContextExtension on BuildContext {
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
