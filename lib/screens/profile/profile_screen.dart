import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';
import '../auth/onboarding_screen.dart';
import '../auth/profile_setup_screen.dart';
import '../location/addresses_screen.dart';
import '../orders/orders_screen.dart';
import 'favorites_screen.dart';
import 'offers_screen.dart';
import 'notifications_screen.dart';

/// Profile screen — deliberately excludes Wallet, Refer & Earn, and any
/// Google account references per spec.
class ProfileScreen extends StatelessWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: !embedded, title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileSetupScreen(isEditing: true)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: (user?.profileImage.isNotEmpty ?? false)
                      ? NetworkImage(user!.profileImage)
                      : null,
                  child: (user?.profileImage.isEmpty ?? true)
                      ? Icon(Icons.person, color: AppColors.primary, size: 32)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name.isNotEmpty == true ? user!.name : 'Dapzo User', style: AppTextStyles.sectionHeading),
                      const SizedBox(height: 2),
                      Text(user?.phone ?? '', style: AppTextStyles.supporting),
                      if (user?.email.isNotEmpty ?? false)
                        Text(user!.email, style: AppTextStyles.supporting),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _MenuTile(
            icon: Icons.edit_outlined,
            label: 'Edit Profile',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileSetupScreen(isEditing: true)),
            ),
          ),
          _MenuTile(
            icon: Icons.receipt_long_outlined,
            label: 'My Orders',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OrdersScreen()),
            ),
          ),
          _MenuTile(
            icon: Icons.location_on_outlined,
            label: 'Saved Addresses',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddressesScreen()),
            ),
          ),
          _MenuTile(
            icon: Icons.favorite_border,
            label: 'Favorites',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            ),
          ),
          _MenuTile(
            icon: Icons.local_offer_outlined,
            label: 'Offers',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OffersScreen()),
            ),
          ),
          _MenuTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          SwitchListTile(
            title: Text('Dark Mode', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            secondary: Icon(
              context.watch<AppState>().isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: AppColors.primary,
            ),
            value: context.watch<AppState>().isDarkMode,
            onChanged: (_) {
              context.read<AppState>().toggleDarkMode();
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            activeColor: AppColors.primary,
          ),
          const SizedBox(height: 12),
          _MenuTile(
            icon: Icons.logout,
            label: 'Logout',
            color: AppColors.error,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Log out?'),
                  content: const Text('Are you sure you want to log out of Dapzo?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      child: const Text('Log Out'),
                    ),
                  ],
                ),
              );

              if (confirmed != true) return;

              await AuthService().signOut();
              if (context.mounted) {
                // AppState.user (and selectedAddress) previously stayed
                // populated after Firebase sign-out, since only Firebase
                // was signed out here — clear it so a stale profile/address
                // from the old session can't leak into the next login.
                context.read<AppState>().clearUserData();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuTile({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color ?? AppColors.textDark),
      title: Text(label, style: AppTextStyles.body.copyWith(color: color)),
      trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}