import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

/// Duolingo-inspired animated game button with press feedback
class GameButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final String? emoji;
  final VoidCallback? onPressed;
  final Color? color;
  final bool enabled;
  final bool isLoading;
  final double? width;
  final String? disabledReason;

  const GameButton({
    super.key,
    required this.text,
    this.icon,
    this.emoji,
    this.onPressed,
    this.color,
    this.enabled = true,
    this.isLoading = false,
    this.width,
    this.disabledReason,
  });

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _shadowAnimation = Tween<double>(
      begin: 6.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canPress => widget.enabled && !widget.isLoading;

  void _handleTapDown(TapDownDetails details) {
    if (!_canPress) return;
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_canPress) return;
    setState(() => _isPressed = false);
    _controller.reverse().then((_) {
      HapticFeedback.mediumImpact();
      widget.onPressed?.call();
    });
  }

  void _handleTapCancel() {
    if (!_canPress) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _showDisabledTooltip() {
    if (widget.disabledReason != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.disabledReason!),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? AppColors.accent;
    final effectiveColor = _canPress ? buttonColor : AppColors.buttonDisabled;
    final darkerColor = Color.lerp(effectiveColor, Colors.black, 0.3)!;

    return GestureDetector(
      onTapDown: _canPress ? _handleTapDown : (_) => _showDisabledTooltip(),
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width ?? double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
              decoration: BoxDecoration(
                color: effectiveColor,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  bottom: BorderSide(
                    color: darkerColor,
                    width: _isPressed ? 2 : 4,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: effectiveColor.withValues(alpha: 0.3),
                    blurRadius: _shadowAnimation.value,
                    offset: Offset(0, _shadowAnimation.value / 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isLoading) ...[
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ] else if (widget.emoji != null) ...[
                    Text(widget.emoji!, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                  ] else if (widget.icon != null) ...[
                    Icon(widget.icon, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.text,
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: _canPress ? 1.0 : 0.6,
                      ),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Selection chip for bet amounts and choices
class SelectionChip extends StatefulWidget {
  final String label;
  final String? sublabel;
  final String? emoji;
  final bool isSelected;
  final bool isDisabled;
  final Color? selectedColor;
  final VoidCallback? onTap;

  const SelectionChip({
    super.key,
    required this.label,
    this.sublabel,
    this.emoji,
    this.isSelected = false,
    this.isDisabled = false,
    this.selectedColor,
    this.onTap,
  });

  @override
  State<SelectionChip> createState() => _SelectionChipState();
}

class _SelectionChipState extends State<SelectionChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isDisabled) return;
    HapticFeedback.selectionClick();
    _controller.forward().then((_) {
      _controller.reverse();
      widget.onTap?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.selectedColor ?? AppColors.accent;
    final isActive = widget.isSelected && !widget.isDisabled;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isActive
                    ? color.withValues(alpha: 0.2)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? color : AppColors.border,
                  width: isActive ? 2.5 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.emoji != null) ...[
                    Text(
                      widget.emoji!,
                      style: TextStyle(
                        fontSize: 28,
                        color: widget.isDisabled
                            ? Colors.white.withValues(alpha: 0.3)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.isDisabled
                          ? AppColors.textMuted
                          : (isActive ? color : AppColors.textPrimary),
                      fontSize: 15,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  if (widget.sublabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.sublabel!,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Bet amount selector row
class BetSelector extends StatelessWidget {
  final int currentBet;
  final int playerMoney;
  final List<int> presets;
  final bool isDisabled;
  final ValueChanged<int> onSelect;

  const BetSelector({
    super.key,
    required this.currentBet,
    required this.playerMoney,
    required this.presets,
    this.isDisabled = false,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BET AMOUNT',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.money.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '\$$currentBet',
                  style: TextStyle(
                    color: AppColors.money,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: presets.map((amount) {
              final isSelected = currentBet == amount;
              final canAfford = playerMoney >= amount;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: presets.first == amount ? 0 : 4,
                    right: presets.last == amount ? 0 : 4,
                  ),
                  child: _BetChip(
                    amount: amount,
                    isSelected: isSelected,
                    isDisabled: isDisabled || !canAfford,
                    onTap: () => onSelect(amount),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _BetChip extends StatefulWidget {
  final int amount;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _BetChip({
    required this.amount,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_BetChip> createState() => _BetChipState();
}

class _BetChipState extends State<_BetChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isDisabled
          ? null
          : () {
              HapticFeedback.selectionClick();
              _controller.forward().then((_) => _controller.reverse());
              widget.onTap();
            },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? AppColors.money.withValues(alpha: 0.2)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.isSelected
                      ? AppColors.money
                      : (widget.isDisabled
                            ? AppColors.border.withValues(alpha: 0.5)
                            : AppColors.border),
                  width: widget.isSelected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  '\$${widget.amount}',
                  style: TextStyle(
                    color: widget.isDisabled
                        ? AppColors.textMuted
                        : (widget.isSelected
                              ? AppColors.money
                              : AppColors.textPrimary),
                    fontSize: 13,
                    fontWeight: widget.isSelected
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Result display card with win/lose styling
class ResultCard extends StatelessWidget {
  final bool isWin;
  final String title;
  final String amount;
  final String? subtitle;
  final VoidCallback? onPlayAgain;

  const ResultCard({
    super.key,
    required this.isWin,
    required this.title,
    required this.amount,
    this.subtitle,
    this.onPlayAgain,
  });

  @override
  Widget build(BuildContext context) {
    final color = isWin ? AppColors.success : AppColors.danger;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isWin ? '🎉' : '😢', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(
                color: isWin ? AppColors.money : AppColors.danger,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
            if (onPlayAgain != null) ...[
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: onPlayAgain,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Play Again'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Section header for casino games
class GameSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const GameSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ],
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Animated multiplier display for Aviator
class MultiplierDisplay extends StatelessWidget {
  final double multiplier;
  final bool hasCrashed;
  final bool hasCashedOut;

  const MultiplierDisplay({
    super.key,
    required this.multiplier,
    this.hasCrashed = false,
    this.hasCashedOut = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = hasCrashed
        ? AppColors.danger
        : (hasCashedOut ? AppColors.success : AppColors.accent);

    // Scale based on multiplier (grows as multiplier increases)
    final scale = 1.0 + (multiplier - 1) * 0.05;
    final clampedScale = scale.clamp(1.0, 1.8);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: clampedScale),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      builder: (context, animatedScale, child) {
        return Transform.scale(
          scale: animatedScale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color, width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: hasCrashed ? 5 : 0,
                ),
              ],
            ),
            child: Text(
              '${multiplier.toStringAsFixed(2)}x',
              style: TextStyle(
                color: color,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Game area container with consistent styling
class GameArea extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsets? padding;

  const GameArea({super.key, required this.child, this.height, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
