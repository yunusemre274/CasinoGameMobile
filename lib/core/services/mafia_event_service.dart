import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';

/// Mafia Event Service - Handles mafia extortion event logic
class MafiaEventService {
  final Random _random = Random();

  // Event trigger probability (30% chance when conditions are met)
  static const double _triggerProbability = 0.30;

  // Minimum time between events (5 minutes in milliseconds)
  static const int _minEventInterval = 5 * 60 * 1000;

  // Track last event time to prevent spam
  int _lastEventTime = 0;

  /// Check if mafia event should trigger
  bool shouldTriggerEvent(GameState state) {
    // Don't trigger if money is not high enough
    if (!state.isMafiaActive) return false;

    // Don't trigger if not enough time has passed
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastEventTime < _minEventInterval) return false;

    // Random chance to trigger
    return _random.nextDouble() < _triggerProbability;
  }

  /// Generate tribute amount based on player money
  int generateTributeAmount(GameState state) {
    final minTribute = state.minTribute;
    final maxTribute = state.maxTribute;
    return minTribute + _random.nextInt(maxTribute - minTribute + 1);
  }

  /// Calculate fight damage (base damage before reductions)
  int calculateFightDamage(GameState state) {
    // Base damage scales with player money
    // $10,000 = 20-30 damage, scales up with money
    final baseDamage = 20 + ((state.money - 10000) / 5000 * 5).round();
    return baseDamage.clamp(20, 60) + _random.nextInt(11); // +0-10 random
  }

  /// Calculate gang member loss when fighting with gang
  int calculateGangLoss(GameState state) {
    // Lose 1-5 gang members randomly
    final maxLoss = state.gangMates.clamp(1, 5);
    return 1 + _random.nextInt(maxLoss);
  }

  /// Mark event as triggered (for cooldown)
  void markEventTriggered() {
    _lastEventTime = DateTime.now().millisecondsSinceEpoch;
  }

  /// Reset cooldown (for testing)
  void resetCooldown() {
    _lastEventTime = 0;
  }
}

/// Result of a mafia event choice
class MafiaEventResult {
  final bool paidTribute;
  final int moneyLost;
  final int hpLost;
  final int gangLost;
  final String message;

  const MafiaEventResult({
    required this.paidTribute,
    required this.moneyLost,
    required this.hpLost,
    required this.gangLost,
    required this.message,
  });
}

/// Mafia Event Notifier - Manages event state
class MafiaEventNotifier extends Notifier<bool> {
  late final MafiaEventService _service;

  @override
  bool build() {
    _service = MafiaEventService();
    return false; // false = no event active
  }

  /// Check and potentially trigger a mafia event
  /// Returns true if event should be shown
  bool checkAndTrigger() {
    final gameState = ref.read(gameProvider);
    if (_service.shouldTriggerEvent(gameState)) {
      _service.markEventTriggered();
      state = true;
      return true;
    }
    return false;
  }

  /// Force trigger an event (for testing or specific scenarios)
  bool forceTrigger() {
    final gameState = ref.read(gameProvider);
    if (!gameState.isMafiaActive) return false;
    _service.markEventTriggered();
    state = true;
    return true;
  }

  /// Get the tribute amount for current event
  int getTributeAmount() {
    final gameState = ref.read(gameProvider);
    return _service.generateTributeAmount(gameState);
  }

  /// Player chooses to pay tribute
  MafiaEventResult payTribute(int amount) {
    final gameNotifier = ref.read(gameProvider.notifier);
    gameNotifier.spendMoney(amount);

    state = false; // Close event

    return MafiaEventResult(
      paidTribute: true,
      moneyLost: amount,
      hpLost: 0,
      gangLost: 0,
      message:
          'You paid \$$amount to the mafia. They leave you alone... for now.',
    );
  }

  /// Player chooses to fight
  MafiaEventResult fight() {
    final gameState = ref.read(gameProvider);
    final gameNotifier = ref.read(gameProvider.notifier);

    int hpLost = 0;
    int gangLost = 0;
    String message;

    if (gameState.gangMates > 0) {
      // Gang protects player
      gangLost = _service.calculateGangLoss(gameState);
      gameNotifier.removeGangMates(gangLost);
      message =
          'Your gang fought off the mafia! You lost $gangLost gang member${gangLost > 1 ? 's' : ''}.';
    } else {
      // Player takes damage
      final baseDamage = _service.calculateFightDamage(gameState);
      // Bodyguards reduce damage by 5 each
      hpLost = (baseDamage - (gameState.bodyguards * 5)).clamp(5, baseDamage);
      gameNotifier.updateHp(-hpLost);
      message = 'You fought the mafia and took $hpLost damage!';

      if (gameState.bodyguards > 0) {
        message += ' Your bodyguards reduced the damage.';
      }
    }

    state = false; // Close event

    return MafiaEventResult(
      paidTribute: false,
      moneyLost: 0,
      hpLost: hpLost,
      gangLost: gangLost,
      message: message,
    );
  }

  /// Dismiss event without action (should not normally be called)
  void dismiss() {
    state = false;
  }

  /// Reset cooldown for testing
  void resetCooldown() {
    _service.resetCooldown();
  }
}

/// Provider for mafia event state
final mafiaEventProvider = NotifierProvider<MafiaEventNotifier, bool>(() {
  return MafiaEventNotifier();
});
