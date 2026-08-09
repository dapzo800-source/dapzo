import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/product_service.dart';
import '../../state/app_state.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<AppState>().mode;

    return Scaffold(
      appBar: AppBar(title: const Text('Offers')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ProductService().streamOffers(mode),
        builder: (context, snapshot) {
          final offers = snapshot.data ?? [];
          if (offers.isEmpty) {
            return Center(child: Text('No active offers right now', style: AppTextStyles.supporting));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final offer = offers[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.modeColor(mode).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer['title'] ?? 'Dapzo Offer', style: AppTextStyles.sectionHeading),
                    const SizedBox(height: 6),
                    Text(offer['subtitle'] ?? '', style: AppTextStyles.supporting),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
