import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/game_provider.dart';
import '../../../core/services/casino_logic/casino_logic.dart';
import '../../../shared/widgets/casino_widgets.dart';

/// Horse Race Game Page - Pick a horse and watch it race!
class HorseRacePage extends ConsumerStatefulWidget {
  const HorseRacePage({super.key});

  @override
  ConsumerState<HorseRacePage> createState() => _HorseRacePageState();
}

class _HorseRacePageState extends ConsumerState<HorseRacePage> {
  // Casino logic
  final HorseRaceLogic _horseRaceLogic = HorseRaceLogic();
  HorseRaceResult? _raceResult;

  // Get horse colors from config
  List<Color> get _horseColors =>
      _horseRaceLogic.horses.map((h) => Color(h.colorValue)).toList();

  List<String> get _horseNames =>
      _horseRaceLogic.horses.map((h) => h.name).toList();

  // Game state
  int _betAmount = 100;
  int? _selectedHorse; // 0-4
  List<double> _horsePositions = [0, 0, 0, 0, 0]; // 0.0 to 1.0
  bool _isRacing = false;
  bool _showResult = false;
  int? _winnerHorse;
  int _winAmount = 0;

  Timer? _raceTimer;

  // Preset bet amounts
  final List<int> _betPresets = [50, 100, 250, 500, 1000];

  @override
  void dispose() {
    _raceTimer?.cancel();
    super.dispose();
  }

  void _selectHorse(int index) {
    if (_isRacing) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedHorse = index;
      _showResult = false;
      _raceResult = null;
    });
  }

  void _selectBetAmount(int amount) {
    if (_isRacing) return;
    HapticFeedback.selectionClick();
    setState(() => _betAmount = amount);
  }

  void _startRace() {
    if (_isRacing || _selectedHorse == null) return;

    final gameState = ref.read(gameProvider);
    if (gameState.money < _betAmount) {
      _showInsufficientFundsSnackbar();
      return;
    }

    // Deduct bet
    ref.read(gameProvider.notifier).spendMoney(_betAmount);

    HapticFeedback.heavyImpact();
    setState(() {
      _isRacing = true;
      _showResult = false;
      _winnerHorse = null;
      _winAmount = 0;
      _horsePositions = [0, 0, 0, 0, 0];
    });

    HapticFeedback.heavyImpact();

    // Use casino logic to determine winner
    _raceResult = _horseRaceLogic.race(_selectedHorse);

    // Animate the race based on the pre-determined result
    final random = Random();
    final targetPositions = _raceResult!.finalPositions;

    _raceTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      bool raceFinished = true;

      setState(() {
        for (int i = 0; i < _horsePositions.length; i++) {
          if (_horsePositions[i] < targetPositions[i]) {
            // Animate toward target with some variance
            final speed = 0.008 + random.nextDouble() * 0.015;
            _horsePositions[i] = (_horsePositions[i] + speed).clamp(
              0,
              targetPositions[i],
            );

            if (_horsePositions[i] < targetPositions[i]) {
              raceFinished = false;
            }
          }
        }
      });

      // Check if race animation finished
      if (raceFinished) {
        timer.cancel();
        _winnerHorse = _raceResult!.winnerIndex;
        _finishRace();
      }
    });
  }

  void _finishRace() {
    setState(() {
      _isRacing = false;
      _showResult = true;
    });

    HapticFeedback.mediumImpact();

    // Use casino logic result with proper odds-based payout
    if (_raceResult != null && _raceResult!.playerWins) {
      _winAmount = _horseRaceLogic.calculatePayout(_betAmount, _raceResult!);
      ref.read(gameProvider.notifier).addMoney(_winAmount);
      HapticFeedback.heavyImpact();
    }
  }

  void _showInsufficientFundsSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('💸 Not enough money!'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _playAgain() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedHorse = null;
      _showResult = false;
      _winnerHorse = null;
      _horsePositions = [0, 0, 0, 0, 0];
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final bool canPlay =
        _selectedHorse != null && gameState.money >= _betAmount && !_isRacing;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.selectionClick();
            _raceTimer?.cancel();
            context.pop();
          },
        ),
        title: const Text('🏇 Horse Race'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '\$${gameState.money}',
                style: TextStyle(
                  color: AppColors.money,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          children: [
            // Bet amount selector
            BetSelector(
              presets: _betPresets,
              currentBet: _betAmount,
              playerMoney: gameState.money,
              isDisabled: _isRacing,
              onSelect: _selectBetAmount,
            ),
            const SizedBox(height: 16),

            // Race track
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D5016), // Grass green
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Stack(
                  children: [
                    // Track lanes
                    Column(
                      children: List.generate(5, (index) {
                        final isSelected = _selectedHorse == index;
                        final isWinner = _winnerHorse == index && _showResult;

                        return Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _horseColors[index].withValues(alpha: 0.1)
                                  : null,
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: index < 4 ? 2 : 0,
                                ),
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Track markings
                                Row(
                                  children: List.generate(5, (i) {
                                    return Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              color: Colors.white.withValues(
                                                alpha: 0.1,
                                              ),
                                              width: 1,
                                              style: BorderStyle.solid,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),

                                // Horse lane number
                                Positioned(
                                  left: 8,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: _horseColors[index],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Horse progress bar
                                Positioned(
                                  left: 40,
                                  right: 40,
                                  top: 0,
                                  bottom: 0,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Stack(
                                        children: [
                                          // Progress track
                                          Center(
                                            child: Container(
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: Colors.brown.shade800,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                          // Horse position
                                          AnimatedPositioned(
                                            duration: const Duration(
                                              milliseconds: 50,
                                            ),
                                            left:
                                                _horsePositions[index] *
                                                (constraints.maxWidth - 40),
                                            top: 0,
                                            bottom: 0,
                                            child: Center(
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _horseColors[index],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  boxShadow: isWinner
                                                      ? [
                                                          BoxShadow(
                                                            color: AppColors
                                                                .money
                                                                .withValues(
                                                                  alpha: 0.5,
                                                                ),
                                                            blurRadius: 8,
                                                            spreadRadius: 2,
                                                          ),
                                                        ]
                                                      : null,
                                                ),
                                                child: const Text(
                                                  '🏇',
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),

                    // Finish line
                    Positioned(
                      right: 40,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white,
                              Colors.black,
                              Colors.white,
                              Colors.black,
                              Colors.white,
                              Colors.black,
                              Colors.white,
                              Colors.black,
                            ],
                            stops: const [
                              0,
                              0.125,
                              0.125,
                              0.25,
                              0.25,
                              0.375,
                              0.375,
                              0.5,
                            ],
                            tileMode: TileMode.repeated,
                          ),
                        ),
                      ),
                    ),

                    // Result overlay
                    if (_showResult)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: _winAmount > 0
                                ? AppColors.success.withValues(alpha: 0.95)
                                : AppColors.danger.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: _horseColors[_winnerHorse!],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${_winnerHorse! + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${_horseNames[_winnerHorse!]} Wins!',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _winAmount > 0
                                    ? '🎉 You won \$$_winAmount!'
                                    : '😢 Better luck next time!',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Horse selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SELECT YOUR HORSE',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.money.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'WIN: 5x',
                          style: TextStyle(
                            color: AppColors.money,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      return _HorseButton(
                        number: index + 1,
                        color: _horseColors[index],
                        name: _horseNames[index],
                        isSelected: _selectedHorse == index,
                        isDisabled: _isRacing || _showResult,
                        onTap: () => _selectHorse(index),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            if (_showResult)
              GameButton(
                text: 'PLAY AGAIN',
                icon: Icons.replay,
                color: AppColors.info,
                onPressed: _playAgain,
              )
            else
              GameButton(
                text: _isRacing ? 'RACING...' : 'START RACE',
                icon: Icons.flag,
                color: AppColors.warning,
                enabled: canPlay,
                isLoading: _isRacing,
                onPressed: _startRace,
                disabledReason: _selectedHorse == null
                    ? 'Select a horse first!'
                    : null,
              ),
          ],
        ),
      ),
      ),
    );
  }
}

class _HorseButton extends StatelessWidget {
  final int number;
  final Color color;
  final String name;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _HorseButton({
    required this.number,
    required this.color,
    required this.name,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDisabled ? color.withValues(alpha: 0.3) : color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                color: isDisabled
                    ? AppColors.textMuted
                    : AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
