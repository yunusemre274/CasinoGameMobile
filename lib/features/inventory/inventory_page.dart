import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/inventory_item.dart';
import '../../core/providers/game_provider.dart';
import '../../shared/widgets/game_card.dart';
import '../../shared/widgets/animated_button.dart';

// Inventory Page - Shows items purchased from market
class InventoryPage extends ConsumerWidget {
  const InventoryPage({super.key});

  void _useItem(BuildContext context, WidgetRef ref, InventoryItem item) {
    HapticFeedback.mediumImpact();
    final gameState = ref.read(gameProvider);

    // Check if hunger is already full
    if (gameState.hunger >= gameState.maxHunger) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '🍽️ You\'re already full!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final restored = ref.read(gameProvider.notifier).useItem(item);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🍴 Used ${item.name}! +$restored hunger',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final inventory = gameState.inventory;
    final totalItems = inventory.fold(0, (sum, item) => sum + item.quantity);

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
                  '🎒 Inventory',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📦', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        '$totalItems items',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),

            // Hunger bar
            _HungerStatusBar(
              hunger: gameState.hunger,
              maxHunger: gameState.maxHunger,
            ),
            const SizedBox(height: AppConstants.largePadding),

            // Inventory content
            if (inventory.isEmpty)
              _EmptyInventory()
            else
              ...inventory.map(
                (item) => _InventoryItemCard(
                  item: item,
                  onUse: () => _useItem(context, ref, item),
                  hungerFull: gameState.hunger >= gameState.maxHunger,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HungerStatusBar extends StatelessWidget {
  final int hunger;
  final int maxHunger;

  const _HungerStatusBar({required this.hunger, required this.maxHunger});

  @override
  Widget build(BuildContext context) {
    final percent = hunger / maxHunger;
    final isFull = hunger >= maxHunger;

    return GameCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🍽️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  const Text(
                    'Hunger',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '$hunger/$maxHunger',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isFull ? AppColors.success : AppColors.hunger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                isFull ? AppColors.success : AppColors.hunger,
              ),
              minHeight: 10,
            ),
          ),
          if (isFull) ...[
            const SizedBox(height: 8),
            Text(
              '✨ You\'re full! No need to eat right now.',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GameCard(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.largePadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: const Text('📦', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'Your inventory is empty',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Visit the Market to buy items\nthat can restore your hunger',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppConstants.largePadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back, size: 16, color: AppColors.accent),
                const SizedBox(width: 4),
                Text(
                  'Go to Market tab',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onUse;
  final bool hungerFull;

  const _InventoryItemCard({
    required this.item,
    required this.onUse,
    required this.hungerFull,
  });

  @override
  Widget build(BuildContext context) {
    return GameCard(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      child: Row(
        children: [
          // Icon with quantity badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
                child: Center(
                  child: Text(item.icon, style: const TextStyle(fontSize: 32)),
                ),
              ),
              if (item.quantity > 1)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'x${item.quantity}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
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
          // Use Button
          AnimatedButton(
            onPressed: onUse,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            backgroundColor: hungerFull
                ? AppColors.surfaceLight
                : AppColors.accent,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.restaurant_menu,
                  size: 16,
                  color: hungerFull ? AppColors.textMuted : Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  'Use',
                  style: TextStyle(
                    color: hungerFull ? AppColors.textMuted : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
