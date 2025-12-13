import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/game_provider.dart';
import '../../shared/widgets/game_card.dart';

// Buildings Page - Gang, Secure Building, Hospital, Home
class BuildingsPage extends ConsumerWidget {
  const BuildingsPage({super.key});

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
            Text(
              '🏢 Buildings',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Manage your properties',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppConstants.largePadding),

            // Buildings list
            _BuildingCard(
              icon: '🏠',
              name: 'Home',
              description:
                  'Visit family, restore happiness\nReward: \$${gameState.homeVisitReward}',
              color: AppColors.happiness,
              isLocked: false,
              onTap: () {
                context.push('/home');
              },
            ),
            _BuildingCard(
              icon: '🏥',
              name: 'Hospital',
              description: 'Heal to full HP\nCost: \$${gameState.hospitalCost}',
              color: AppColors.health,
              isLocked: false,
              onTap: () {
                context.push('/hospital');
              },
            ),
            _BuildingCard(
              icon: '🛡️',
              name: 'Secure Building',
              description:
                  'Hire bodyguards (\$5,000 each)\nYou have: ${gameState.bodyguards}/10',
              color: AppColors.info,
              isLocked: !gameState.bodyguardUnlocked,
              lockMessage: 'Unlocks at \$50,000',
              onTap: () {
                context.push('/secure-building');
              },
            ),
            _BuildingCard(
              icon: '👥',
              name: 'Gang Building',
              description:
                  'Recruit gang members\nMembers: ${gameState.gangMates}',
              color: AppColors.warning,
              isLocked: !gameState.gangUnlocked,
              lockMessage: 'Unlocks at \$100,000',
              onTap: () {
                context.push('/gang-building');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildingCard extends StatelessWidget {
  final String icon;
  final String name;
  final String description;
  final Color color;
  final bool isLocked;
  final String? lockMessage;
  final VoidCallback onTap;

  const _BuildingCard({
    required this.icon,
    required this.name,
    required this.description,
    required this.color,
    required this.isLocked,
    this.lockMessage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isLocked ? 0.5 : 1.0,
      child: GameCard(
        margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
        onTap: isLocked ? null : onTap,
        child: Row(
          children: [
            // Icon
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Center(
                child: isLocked
                    ? Icon(Icons.lock, color: color, size: 32)
                    : Text(icon, style: const TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLocked ? lockMessage ?? 'Locked' : description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            // Arrow
            if (!isLocked) Icon(Icons.chevron_right, color: color, size: 28),
          ],
        ),
      ),
    );
  }
}
