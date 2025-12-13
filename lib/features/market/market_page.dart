import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/inventory_item.dart';
import '../../core/providers/game_provider.dart';
import '../../shared/widgets/game_card.dart';
import '../../shared/widgets/animated_button.dart';

// Market Page - Buy items to restore hunger and boost stats
class MarketPage extends ConsumerWidget {
  const MarketPage({super.key});

  void _buyItem(BuildContext context, WidgetRef ref, InventoryItem item) {
    HapticFeedback.mediumImpact();
    final success = ref.read(gameProvider.notifier).buyItem(item);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '✅ Bought ${item.name} for \$${item.price}!'
              : '❌ Not enough money for ${item.name}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: success ? AppColors.success : AppColors.danger,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🏪 Market',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.money.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('💵', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        '\$${gameState.money}',
                        style: const TextStyle(
                          color: AppColors.money,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Buy food and supplies',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppConstants.largePadding),

            // Market items
            ...MarketItems.all.map(
              (item) => _MarketItemCard(
                item: item,
                canAfford: gameState.money >= item.price,
                onBuy: () => _buyItem(context, ref, item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketItemCard extends StatelessWidget {
  final InventoryItem item;
  final bool canAfford;
  final VoidCallback onBuy;

  const _MarketItemCard({
    required this.item,
    required this.canAfford,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return GameCard(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      child: Row(
        children: [
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: Center(
              child: Text(item.icon, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: AppConstants.defaultPadding),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.restaurant, size: 14, color: AppColors.hunger),
                    const SizedBox(width: 4),
                    Text(
                      '+${item.hungerRestore} hunger',
                      style: TextStyle(
                        color: AppColors.hunger,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Price and Buy Button
          Column(
            children: [
              Text(
                '\$${item.price}',
                style: TextStyle(
                  color: canAfford ? AppColors.money : AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedButton(
                onPressed: canAfford ? onBuy : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                backgroundColor: canAfford
                    ? AppColors.success
                    : AppColors.surfaceLight,
                child: Text(
                  'Buy',
                  style: TextStyle(
                    color: canAfford ? Colors.white : AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
