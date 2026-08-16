import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// About Dapzo screen — company information, refund policy, and contact.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textDark,
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('About Dapzo', style: AppTextStyles.heading.copyWith(fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // ── Brand Header Card ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dapzo',
                          style: AppTextStyles.heading.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Shop Local. Delivered Better.',
                          style: AppTextStyles.supporting.copyWith(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── About Dapzo ───────────────────────────────────────────────────
          _SectionCard(
            title: 'About Dapzo',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bodyText(
                  'Dapzo is a convenient local delivery platform designed to make everyday shopping simple, fast, and reliable.',
                ),
                const SizedBox(height: 12),
                _bodyText(
                  'With Dapzo, customers can discover products from local shops, place orders easily, choose their preferred payment method, and track their orders from placement to delivery.',
                ),
                const SizedBox(height: 12),
                _bodyText(
                  'Our goal is to connect customers with trusted local businesses while providing a smooth and transparent delivery experience.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── What Dapzo Offers ─────────────────────────────────────────────
          _SectionCard(
            title: 'What Dapzo Offers',
            child: Column(
              children: const [
                _OfferItem(
                  title: 'Shop Local',
                  description: 'Discover products from nearby stores in your area.',
                ),
                _OfferItem(
                  title: 'Fast Delivery',
                  description: 'Get your orders delivered to your selected location.',
                ),
                _OfferItem(
                  title: 'Live Order Tracking',
                  description: 'Track your order status and delivery progress in real time.',
                ),
                _OfferItem(
                  title: 'Secure Payments',
                  description: 'Pay online through our secure payment gateway or choose Cash on Delivery where available.',
                ),
                _OfferItem(
                  title: 'Local Businesses',
                  description: 'Support and connect with trusted local shops in your community.',
                ),
                _OfferItem(
                  title: 'Order Updates',
                  description: 'Receive important updates about your order at every stage.',
                  isLast: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Our Mission ───────────────────────────────────────────────────
          _SectionCard(
            title: 'Our Mission',
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '"Making local shopping easier, faster, and more accessible for everyone."',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Refund Policy ─────────────────────────────────────────────────
          _SectionCard(
            title: 'Refund Policy',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _policyText(
                  '1. Eligibility for Refund',
                  'Refund requests must be raised within 24 hours of order delivery. Requests submitted after this window will not be considered.',
                ),
                _policyDivider(),
                _policyText(
                  '2. Valid Reasons for Refund',
                  'Refunds are applicable in the following cases: wrong item delivered, item missing from the order, item received in damaged or spoiled condition, or order not delivered despite being marked as delivered.',
                ),
                _policyDivider(),
                _policyText(
                  '3. Non-Refundable Cases',
                  'Refunds will not be issued in the following cases: change of mind after the order is placed or prepared, minor variations in taste or presentation, orders where incorrect delivery address was provided by the customer, or delays caused by weather, traffic, or other circumstances beyond our control.',
                ),
                _policyDivider(),
                _policyText(
                  '4. How to Request a Refund',
                  'Contact our support team at support@dapzo.in with your Order ID and a clear description of the issue. Attach relevant photos where applicable.',
                ),
                _policyDivider(),
                _policyText(
                  '5. Refund Method',
                  'Approved refunds will be credited to the original payment method. For Cash on Delivery orders, refunds will be issued as Dapzo credits or via bank transfer upon verification.',
                ),
                _policyDivider(),
                _policyText(
                  '6. Refund Timeline',
                  'Refunds are typically processed within 5 to 7 business days after approval. The actual credit date may vary depending on your bank or payment provider.',
                ),
                _policyDivider(),
                _policyText(
                  '7. Order Cancellation',
                  'Orders can be cancelled before the shop begins preparation. Once the shop starts preparing your order, cancellation is not possible. For pre-payment orders that are cancelled before preparation, a full refund will be issued.',
                  isLast: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Contact Us ────────────────────────────────────────────────────
          _SectionCard(
            title: 'Contact Us',
            child: Column(
              children: [
                _ContactRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: 'support@dapzo.in',
                ),
                const SizedBox(height: 12),
                _ContactRow(
                  icon: Icons.language_rounded,
                  label: 'Website',
                  value: 'www.dapzo.in',
                ),
                const SizedBox(height: 12),
                _ContactRow(
                  icon: Icons.location_on_outlined,
                  label: 'Country',
                  value: 'India',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Footer ────────────────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Text(
                  'Dapzo',
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Shop Local. Delivered Better.',
                  style: AppTextStyles.supporting.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Version 1.0.0',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _bodyText(String text) => Text(
        text,
        style: AppTextStyles.supporting.copyWith(
          fontSize: 14,
          height: 1.6,
          color: AppColors.textMedium,
          fontWeight: FontWeight.w500,
        ),
      );

  Widget _policyText(String heading, String body, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: AppTextStyles.supporting.copyWith(
              fontSize: 13.5,
              height: 1.55,
              color: AppColors.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _policyDivider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION CARD
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.sectionHeading.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OFFER ITEM ROW
// ─────────────────────────────────────────────────────────────────────────────

class _OfferItem extends StatelessWidget {
  final String title;
  final String description;
  final bool isLast;

  const _OfferItem({
    required this.title,
    required this.description,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTextStyles.supporting.copyWith(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTACT ROW
// ─────────────────────────────────────────────────────────────────────────────

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              value,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
