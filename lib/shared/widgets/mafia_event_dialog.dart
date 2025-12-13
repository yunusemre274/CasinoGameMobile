import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/game_provider.dart';
import '../../core/services/mafia_event_service.dart';

/// Mafia Event Dialog - Blocking modal for mafia extortion events
class MafiaEventDialog extends ConsumerStatefulWidget {
  final int tributeAmount;
  final Function(MafiaEventResult) onResult;

  const MafiaEventDialog({
    super.key,
    required this.tributeAmount,
    required this.onResult,
  });

  /// Show the mafia event dialog
  static Future<MafiaEventResult?> show(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final mafiaNotifier = ref.read(mafiaEventProvider.notifier);
    final tributeAmount = mafiaNotifier.getTributeAmount();

    return showDialog<MafiaEventResult>(
      context: context,
      barrierDismissible: false, // Cannot dismiss without choosing
      barrierColor: Colors.black87,
      builder: (context) => MafiaEventDialog(
        tributeAmount: tributeAmount,
        onResult: (result) => Navigator.of(context).pop(result),
      ),
    );
  }

  @override
  ConsumerState<MafiaEventDialog> createState() => _MafiaEventDialogState();
}

class _MafiaEventDialogState extends ConsumerState<MafiaEventDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _showingResult = false;
  MafiaEventResult? _result;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _payTribute() {
    HapticFeedback.mediumImpact();
    final result = ref
        .read(mafiaEventProvider.notifier)
        .payTribute(widget.tributeAmount);
    setState(() {
      _showingResult = true;
      _result = result;
    });
  }

  void _fight() {
    HapticFeedback.heavyImpact();
    final result = ref.read(mafiaEventProvider.notifier).fight();
    setState(() {
      _showingResult = true;
      _result = result;
    });
  }

  void _closeResult() {
    HapticFeedback.selectionClick();
    widget.onResult(_result!);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final canAffordTribute = gameState.money >= widget.tributeAmount;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(24),
              child: _showingResult
                  ? _buildResultContent()
                  : _buildEventContent(canAffordTribute),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventContent(bool canAffordTribute) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.danger, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Column(
              children: [
                const Text('🔫', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text(
                  'MAFIA ARRIVAL',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  '"Nice business you got here...\nWould be a shame if something happened to it."',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Tribute demand
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'They demand tribute:',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${widget.tributeAmount}',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Player status info
                _buildStatusInfo(),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'PAY',
                        subtitle: '-\$${widget.tributeAmount}',
                        icon: Icons.attach_money,
                        color: AppColors.money,
                        enabled: canAffordTribute,
                        onPressed: canAffordTribute ? _payTribute : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        label: 'FIGHT',
                        subtitle: _getFightSubtitle(),
                        icon: Icons.sports_mma,
                        color: AppColors.danger,
                        enabled: true,
                        onPressed: _fight,
                      ),
                    ),
                  ],
                ),

                if (!canAffordTribute) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Not enough money to pay tribute!',
                    style: TextStyle(color: AppColors.warning, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo() {
    final gameState = ref.watch(gameProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatusItem(
            icon: Icons.favorite,
            label: 'HP',
            value: '${gameState.hp}',
            color: AppColors.health,
          ),
          _StatusItem(
            icon: Icons.groups,
            label: 'Gang',
            value: '${gameState.gangMates}',
            color: AppColors.level,
          ),
          _StatusItem(
            icon: Icons.shield,
            label: 'Guards',
            value: '${gameState.bodyguards}',
            color: AppColors.info,
          ),
        ],
      ),
    );
  }

  String _getFightSubtitle() {
    final gameState = ref.watch(gameProvider);
    if (gameState.gangMates > 0) {
      return 'Gang fights';
    } else if (gameState.bodyguards > 0) {
      return 'Reduced damage';
    }
    return 'Take damage';
  }

  Widget _buildResultContent() {
    final result = _result!;
    final isVictory = result.paidTribute || result.hpLost == 0;

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isVictory ? AppColors.success : AppColors.warning,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              result.paidTribute ? '💸' : (result.gangLost > 0 ? '⚔️' : '🩹'),
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              result.paidTribute ? 'Tribute Paid' : 'Fight Result',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              result.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Result details
            if (result.moneyLost > 0)
              _ResultRow(
                icon: Icons.attach_money,
                label: 'Money Lost',
                value: '-\$${result.moneyLost}',
                color: AppColors.danger,
              ),
            if (result.hpLost > 0)
              _ResultRow(
                icon: Icons.favorite,
                label: 'HP Lost',
                value: '-${result.hpLost}',
                color: AppColors.health,
              ),
            if (result.gangLost > 0)
              _ResultRow(
                icon: Icons.groups,
                label: 'Gang Lost',
                value: '-${result.gangLost}',
                color: AppColors.level,
              ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _closeResult,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.enabled,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? color.withValues(alpha: 0.15) : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? color : AppColors.border,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: enabled ? color : AppColors.textMuted,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: enabled ? color : AppColors.textMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: enabled
                      ? AppColors.textSecondary
                      : AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatusItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ResultRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
