import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/casino_logic/casino_logic.dart';
import '../../../shared/widgets/game_card.dart';

/// Dev Simulation Screen - Test and verify casino odds
/// This screen is for development/debugging purposes only
class DevSimulationPage extends ConsumerStatefulWidget {
  const DevSimulationPage({super.key});

  @override
  ConsumerState<DevSimulationPage> createState() => _DevSimulationPageState();
}

class _DevSimulationPageState extends ConsumerState<DevSimulationPage> {
  late CasinoSimulationService _simulationService;

  int _numSimulations =
      CasinoSimulationService.defaultSimulations; // 100K default
  bool _isRunning = false;
  List<SimulationResult> _results = [];
  String _statusMessage =
      'Ready to run simulations (100K recommended for accuracy)';

  // Updated presets with higher minimum for statistical significance
  final List<int> _simulationPresets = [10000, 50000, 100000, 500000, 1000000];

  @override
  void initState() {
    super.initState();
    // Create simulation service with unique seed
    _simulationService = CasinoSimulationService();
  }

  Future<void> _runAllSimulations() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _results = [];
      _statusMessage = 'Running simulations...';
    });

    HapticFeedback.heavyImpact();

    try {
      _results = await _simulationService.runAllSimulations(
        numSimulations: _numSimulations,
      );
      setState(() {
        _statusMessage = 'Simulations complete!';
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isRunning = false;
      });
    }

    HapticFeedback.mediumImpact();
  }

  Future<void> _runSingleSimulation(String gameName) async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _statusMessage = 'Running $gameName simulation...';
    });

    HapticFeedback.selectionClick();

    SimulationResult? result;

    try {
      switch (gameName) {
        case 'Roulette':
          result = await _simulationService.simulateRoulette(
            numSimulations: _numSimulations,
          );
        case 'Blackjack':
          result = await _simulationService.simulateBlackjack(
            numSimulations: _numSimulations,
          );
        case 'Slots':
          result = await _simulationService.simulateSlots(
            numSimulations: _numSimulations,
          );
        case 'Coin Flip':
          result = await _simulationService.simulateCoinFlip(
            numSimulations: _numSimulations,
          );
        case 'Horse Race':
          result = await _simulationService.simulateHorseRace(
            numSimulations: _numSimulations,
          );
        case 'Aviator':
          result = await _simulationService.simulateAviator(
            numSimulations: _numSimulations,
          );
      }

      if (result != null) {
        // Update or add result
        final existingIndex = _results.indexWhere(
          (r) => r.gameName.startsWith(gameName),
        );
        setState(() {
          if (existingIndex >= 0) {
            _results[existingIndex] = result!;
          } else {
            _results.add(result!);
          }
          _statusMessage = '$gameName simulation complete!';
          _isRunning = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isRunning = false;
      });
    }

    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.pop();
          },
        ),
        title: const Text('🎲 RTP Simulator'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Simulation count selector
            GameCard(
              backgroundColor: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simulations per game',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _simulationPresets.map((count) {
                      final isSelected = _numSimulations == count;
                      return GestureDetector(
                        onTap: _isRunning
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                setState(() => _numSimulations = count);
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.info.withValues(alpha: 0.2)
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.info
                                  : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            _formatNumber(count),
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.info
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Individual game buttons
            GameCard(
              backgroundColor: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Run individual game',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _GameButton(
                        label: '🎡 Roulette',
                        onTap: () => _runSingleSimulation('Roulette'),
                        isDisabled: _isRunning,
                      ),
                      _GameButton(
                        label: '🃏 Blackjack',
                        onTap: () => _runSingleSimulation('Blackjack'),
                        isDisabled: _isRunning,
                      ),
                      _GameButton(
                        label: '🎰 Slots',
                        onTap: () => _runSingleSimulation('Slots'),
                        isDisabled: _isRunning,
                      ),
                      _GameButton(
                        label: '🪙 Coin Flip',
                        onTap: () => _runSingleSimulation('Coin Flip'),
                        isDisabled: _isRunning,
                      ),
                      _GameButton(
                        label: '🏇 Horse Race',
                        onTap: () => _runSingleSimulation('Horse Race'),
                        isDisabled: _isRunning,
                      ),
                      _GameButton(
                        label: '✈️ Aviator',
                        onTap: () => _runSingleSimulation('Aviator'),
                        isDisabled: _isRunning,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Run All button
            GestureDetector(
              onTap: _isRunning ? null : _runAllSimulations,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _isRunning
                      ? AppColors.surfaceLight
                      : AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isRunning ? AppColors.border : AppColors.success,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isRunning)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Text('▶️', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      _isRunning ? 'Running...' : 'RUN ALL SIMULATIONS',
                      style: TextStyle(
                        color: _isRunning
                            ? AppColors.textMuted
                            : AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Status message
            Text(
              _statusMessage,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Results
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        'No results yet.\nRun simulations to verify RTP.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        return _ResultCard(result: _results[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(0)}K';
    }
    return num.toString();
  }
}

class _GameButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDisabled;

  const _GameButton({
    required this.label,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDisabled ? AppColors.surfaceLight : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isDisabled ? AppColors.textMuted : AppColors.textPrimary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final SimulationResult result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final isPass = result.withinTolerance;

    // Risk level color
    Color riskColor;
    switch (result.riskLevel) {
      case 'LOW':
        riskColor = AppColors.success;
      case 'MEDIUM':
        riskColor = AppColors.info;
      case 'HIGH':
        riskColor = AppColors.warning;
      default:
        riskColor = AppColors.danger;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPass ? AppColors.success : AppColors.warning,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  result.gameName,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPass
                      ? AppColors.success.withValues(alpha: 0.2)
                      : AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isPass ? '✓ PASS' : '⚠ CHECK',
                  style: TextStyle(
                    color: isPass ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // RTP Section Header
          Text(
            'RTP (Expected Value)',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  label: 'Observed',
                  value: '${(result.observedRtp * 100).toStringAsFixed(2)}%',
                ),
              ),
              Expanded(
                child: _StatColumn(
                  label: 'Expected',
                  value: '${(result.theoreticalRtp * 100).toStringAsFixed(2)}%',
                ),
              ),
              Expanded(
                child: _StatColumn(
                  label:
                      'Diff (±${(result.expectedTolerance * 100).toStringAsFixed(2)}%)',
                  value: '${(result.rtpDifference * 100).toStringAsFixed(3)}%',
                  color: isPass ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: riskColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'VARIANCE (Risk Indicators)',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        result.riskLevel,
                        style: TextStyle(
                          color: riskColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _StatColumn(
                        label: 'Hit Rate',
                        value: '${(result.hitRate * 100).toStringAsFixed(1)}%',
                        fontSize: 12,
                      ),
                    ),
                    Expanded(
                      child: _StatColumn(
                        label: 'Avg Win',
                        value: '${result.avgWinAmount.toStringAsFixed(2)}x',
                        fontSize: 12,
                      ),
                    ),
                    Expanded(
                      child: _StatColumn(
                        label: 'Std Dev',
                        value: result.stdDeviation.toStringAsFixed(3),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _StatColumn(
                        label: 'Max Drawdown',
                        value: '-${result.maxDrawdown.toStringAsFixed(0)}',
                        fontSize: 12,
                        color: AppColors.danger,
                      ),
                    ),
                    Expanded(
                      child: _StatColumn(
                        label: 'Loss Streak',
                        value: '${result.longestLosingStreak}',
                        fontSize: 12,
                      ),
                    ),
                    Expanded(
                      child: _StatColumn(
                        label: 'Win Streak',
                        value: '${result.longestWinningStreak}',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          // Outcome distribution
          Row(
            children: [
              _OutcomeBadge(
                label: 'W',
                value: result.totalWins,
                total: result.numSimulations,
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              _OutcomeBadge(
                label: 'L',
                value: result.totalLosses,
                total: result.numSimulations,
                color: AppColors.danger,
              ),
              if (result.totalPushes > 0) ...[
                const SizedBox(width: 8),
                _OutcomeBadge(
                  label: 'P',
                  value: result.totalPushes,
                  total: result.numSimulations,
                  color: AppColors.textMuted,
                ),
              ],
              const Spacer(),
              Text(
                'Net: ${result.netProfit >= 0 ? '+' : ''}${result.netProfit.toStringAsFixed(0)}',
                style: TextStyle(
                  color: result.netProfit >= 0
                      ? AppColors.success
                      : AppColors.danger,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatNumber(result.numSimulations)} simulations | ${result.elapsed.inMilliseconds}ms',
            style: TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toString();
  }
}

class _OutcomeBadge extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _OutcomeBadge({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value / total * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $pct%',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final double fontSize;

  const _StatColumn({
    required this.label,
    required this.value,
    this.color,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color ?? AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }
}
