import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_seeder.dart';
import '../../state/app_state.dart';
import '../auth/onboarding_screen.dart';
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
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: (user?.profileImage.isNotEmpty ?? false)
                    ? NetworkImage(user!.profileImage)
                    : null,
                child: (user?.profileImage.isEmpty ?? true)
                    ? const Icon(Icons.person, color: AppColors.primary, size: 32)
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
            ],
          ),
          const SizedBox(height: 24),
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
          _MenuTile(icon: Icons.settings_outlined, label: 'Settings', onTap: () {}),
          const SizedBox(height: 12),
          _MenuTile(
            icon: Icons.logout,
            label: 'Logout',
            color: AppColors.error,
            onTap: () async {
              await AuthService().signOut();
              if (context.mounted) {
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
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEED BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _SeedButton extends StatefulWidget {
  @override
  State<_SeedButton> createState() => _SeedButtonState();
}

class _SeedButtonState extends State<_SeedButton> {
  bool _seeding = false;
  String _status = '';

  Future<void> _seed() async {
    setState(() {
      _seeding = true;
      _status = 'Starting…';
    });

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Seeding Demo Data'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (_, __) => Text(_status,
                      style: const TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ),
          );
        },
      ),
    );

    try {
      await FirestoreSeeder().seedAll(
        onProgress: (msg) {
          if (mounted) setState(() => _status = msg);
        },
      );
      if (mounted) {
        Navigator.of(context).pop(); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Demo data seeded to Firestore successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Seeding failed: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _seeding ? null : _seed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_upload_rounded,
                    color: AppColors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  _seeding ? 'Seeding…' : '🌱  Seed Demo Data to Firebase',
                  style: AppTextStyles.button,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
