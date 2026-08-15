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
import 'settings_screen.dart';
import '../home/home_screen.dart';

/// Profile screen — Customer account options and settings.
class ProfileScreen extends StatelessWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          onPressed: () {
            if (embedded) {
              context.findAncestorStateOfType<HomeScreenState>()?.goToTab(0);
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text('My Profile', style: AppTextStyles.heading.copyWith(fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // ── Header Profile Card ──
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ProfileSetupScreen(isEditing: true)),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 3),
                      image: (user?.profileImage.isNotEmpty ?? false)
                          ? DecorationImage(image: NetworkImage(user!.profileImage), fit: BoxFit.cover)
                          : null,
                    ),
                    child: (user?.profileImage.isEmpty ?? true)
                        ? const Icon(Icons.person, color: AppColors.primary, size: 36)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name.isNotEmpty == true ? user!.name : 'Dapzo User', 
                            style: AppTextStyles.heading.copyWith(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text(user?.phone ?? '', style: AppTextStyles.supporting.copyWith(fontSize: 14)),
                        if (user?.email.isNotEmpty ?? false) ...[
                          const SizedBox(height: 2),
                          Text(user!.email, style: AppTextStyles.supporting.copyWith(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // ── Group 1: Activity ──
          _MenuGroup(
            children: [
              _MenuTile(
                icon: Icons.receipt_long_rounded,
                label: 'My Orders',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                ),
              ),
              _MenuTile(
                icon: Icons.favorite_rounded,
                label: 'Favorites',
                iconColor: AppColors.error,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                ),
              ),
              _MenuTile(
                icon: Icons.local_offer_rounded,
                label: 'Offers & Promos',
                iconColor: AppColors.warning,
                showDivider: false,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OffersScreen()),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Group 2: Account ──
          _MenuGroup(
            children: [
              _MenuTile(
                icon: Icons.location_on_rounded,
                label: 'Saved Addresses',
                iconColor: AppColors.success,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddressesScreen()),
                ),
              ),
              _MenuTile(
                icon: Icons.notifications_rounded,
                label: 'Notifications',
                iconColor: const Color(0xFF3B82F6),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
              ),
              _MenuTile(
                icon: Icons.settings_rounded,
                label: 'Settings',
                showDivider: false,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),

          // ── Group 3: Logout ──
          _MenuGroup(
            children: [
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
                context.read<AppState>().clearUserData();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  (route) => false,
                );
              }
            },
            showDivider: false,
          ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREMIUM MENU GROUP
// ─────────────────────────────────────────────────────────────────────────────

class _MenuGroup extends StatelessWidget {
  final List<Widget> children;
  
  const _MenuGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color? iconColor;
  final bool showDivider;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.iconColor,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (color ?? iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color ?? iconColor ?? AppColors.primary, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.body.copyWith(
                      color: color ?? AppColors.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 64, right: 16),
            child: Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
          ),
      ],
    );
  }
}