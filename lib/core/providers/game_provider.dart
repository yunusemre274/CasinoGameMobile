import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';
import '../models/inventory_item.dart';

// Game State Notifier - Manages all game state with persistence
class GameNotifier extends Notifier<GameState> {
  static const String _storageKey = 'casino_mafia_game_state';

  @override
  GameState build() {
    _loadState();
    return const GameState();
  }

  // Load state from shared preferences
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        state = GameState.fromJson(json);
      }
    } catch (e) {
      // If loading fails, keep default state
      state = const GameState();
    }
  }

  // Save state to shared preferences
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(state.toJson());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      // Silently fail on save errors
    }
  }

  // ==================== MONEY METHODS ====================

  /// Add money to the player
  void addMoney(int amount) {
    if (amount <= 0) return;
    state = state.copyWith(money: (state.money + amount).clamp(0, 999999999));
    _checkUnlocks();
    _saveState();
  }

  /// Spend money (returns false if not enough money)
  bool spendMoney(int amount) {
    if (amount <= 0) return true;
    if (state.money < amount) return false;
    state = state.copyWith(money: state.money - amount);
    _saveState();
    return true;
  }

  /// Update money (can be positive or negative)
  void updateMoney(int amount) {
    state = state.copyWith(money: (state.money + amount).clamp(0, 999999999));
    _checkUnlocks();
    _saveState();
  }

  /// Set money directly
  void setMoney(int amount) {
    state = state.copyWith(money: amount.clamp(0, 999999999));
    _checkUnlocks();
    _saveState();
  }

  // ==================== HP METHODS ====================

  /// Take damage (reduces HP, affected by bodyguards and gang)
  void takeDamage(int damage) {
    if (damage <= 0) return;

    // Bodyguards reduce damage by 5 each
    int reducedDamage = damage - (state.bodyguards * 5);

    // Gang members absorb all damage if present
    if (state.gangMates > 0) {
      // Player takes no damage, but loses 1-5 gang members
      final gangLoss = (1 + (damage ~/ 10)).clamp(1, 5);
      state = state.copyWith(
        gangMates: (state.gangMates - gangLoss).clamp(0, 999),
      );
      _saveState();
      return;
    }

    // Apply reduced damage (minimum 1 if no protection)
    final actualDamage = reducedDamage.clamp(1, damage);
    final newHp = (state.hp - actualDamage).clamp(0, state.effectiveMaxHp);

    state = state.copyWith(hp: newHp);

    // Decrease family happiness when taking damage
    updateFamilyHappiness(-5);
    _saveState();
  }

  /// Heal the player by a specific amount
  void heal(int amount) {
    if (amount <= 0) return;
    final newHp = (state.hp + amount).clamp(0, state.effectiveMaxHp);
    state = state.copyWith(hp: newHp);
    _saveState();
  }

  /// Heal to full HP (hospital - costs money)
  bool healToFull() {
    if (state.hp >= state.effectiveMaxHp) return false;
    if (state.money < state.hospitalCost) return false;

    state = state.copyWith(
      hp: state.effectiveMaxHp,
      money: state.money - state.hospitalCost,
      hospitalCost: state.hospitalCost + 1000,
      hospitalUseCount: state.hospitalUseCount + 1,
    );
    _saveState();
    return true;
  }

  /// Update HP directly
  void updateHp(int amount) {
    final newHp = (state.hp + amount).clamp(0, state.effectiveMaxHp);
    state = state.copyWith(hp: newHp);
    if (amount < 0) {
      updateFamilyHappiness(-5);
    }
    _saveState();
  }

  // ==================== HUNGER METHODS ====================

  /// Reduce hunger (decrease hunger value)
  void reduceHunger(int amount) {
    if (amount <= 0) return;
    final newHunger = (state.hunger - amount).clamp(0, state.maxHunger);
    state = state.copyWith(hunger: newHunger);
    _saveState();
  }

  /// Restore hunger (increase hunger value)
  void restoreHunger(int amount) {
    if (amount <= 0) return;
    final newHunger = (state.hunger + amount).clamp(0, state.maxHunger);
    state = state.copyWith(hunger: newHunger);
    _saveState();
  }

  /// Update hunger (can be positive or negative)
  void updateHunger(int amount) {
    state = state.copyWith(
      hunger: (state.hunger + amount).clamp(0, state.maxHunger),
    );
    _saveState();
  }

  // ==================== XP & LEVEL METHODS ====================

  /// Increase XP and handle leveling up
  void increaseXP(int amount) {
    if (amount <= 0) return;

    int newXp = state.xp + amount;
    int newLevel = state.level;
    int xpToNext = state.xpToNextLevel;

    // Check for level up (every 100 XP)
    while (newXp >= xpToNext) {
      newXp -= xpToNext;
      newLevel++;
      // XP requirement increases by 20% each level
      xpToNext = (100 * (1 + 0.2 * (newLevel - 1))).round();
    }

    state = state.copyWith(xp: newXp, level: newLevel, xpToNextLevel: xpToNext);
    _saveState();
  }

  /// Level up directly
  void levelUp() {
    final newLevel = state.level + 1;
    final newXpToNext = (100 * (1 + 0.2 * (newLevel - 1))).round();
    state = state.copyWith(level: newLevel, xp: 0, xpToNextLevel: newXpToNext);
    _saveState();
  }

  // ==================== FAMILY HAPPINESS METHODS ====================

  /// Update family happiness
  void updateFamilyHappiness(int amount) {
    final newHappiness = (state.familyHappiness + amount).clamp(
      0,
      state.maxFamilyHappiness,
    );

    bool familyBroken = state.familyBroken;

    // Family breaks when happiness reaches 0
    if (newHappiness == 0 && !familyBroken) {
      familyBroken = true;
    }

    // Family restored when happiness goes above 0
    if (newHappiness > 0 && familyBroken) {
      familyBroken = false;
    }

    state = state.copyWith(
      familyHappiness: newHappiness,
      familyBroken: familyBroken,
    );
    _saveState();
  }

  /// Restore family (when happiness goes back up from 0)
  void restoreFamily() {
    if (state.familyHappiness > 0) {
      state = state.copyWith(familyBroken: false);
      _saveState();
    }
  }

  /// Penalty for spending time in casino (call this as a placeholder method)
  /// In the future, this can be called by a timer
  void applyCasinoTimePenalty() {
    updateFamilyHappiness(-5);
    state = state.copyWith(
      lastCasinoVisit: DateTime.now().millisecondsSinceEpoch,
    );
    _saveState();
  }

  /// Penalty for not visiting home (call this as a placeholder method)
  /// In the future, this can be called by a timer
  void applyHomeAbsencePenalty() {
    updateFamilyHappiness(-10);
  }

  /// Record entering casino (for future timer use)
  void enterCasino() {
    state = state.copyWith(
      lastCasinoVisit: DateTime.now().millisecondsSinceEpoch,
    );
    _saveState();
  }

  // ==================== HOME METHODS ====================

  /// Visit home - restores happiness and gives money reward
  /// Returns the money earned
  int visitHome() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final reward = state.homeVisitReward;

    // Restore some family happiness (10-20 based on current level)
    final happinessRestore = (10 + state.level).clamp(10, 25);

    state = state.copyWith(
      money: state.money + reward,
      lastHomeVisit: now,
      homeVisitCount: state.homeVisitCount + 1,
    );

    // Update family happiness (will also restore family if broken)
    updateFamilyHappiness(happinessRestore);

    _checkUnlocks();
    _saveState();

    return reward;
  }

  /// Leave money for family to increase happiness
  /// Returns true if successful
  bool leaveMoneyForFamily(int amount) {
    if (amount <= 0) return false;
    if (state.money < amount) return false;

    // Every $100 gives 5 happiness points
    final happinessGain = (amount ~/ 100) * 5;

    state = state.copyWith(
      money: state.money - amount,
      totalMoneyGivenToFamily: state.totalMoneyGivenToFamily + amount,
    );

    // Update family happiness (will also restore family if broken)
    updateFamilyHappiness(happinessGain);

    _saveState();
    return true;
  }

  /// Calculate suggested donation amount based on happiness deficit
  int getSuggestedDonation() {
    final deficit = state.maxFamilyHappiness - state.familyHappiness;
    // Suggest enough to restore about half the deficit
    return ((deficit / 5) * 100 / 2).round().clamp(100, 5000);
  }

  // ==================== BODYGUARD METHODS ====================

  /// Add bodyguard (costs $5000)
  bool addBodyguard() {
    if (state.bodyguards >= 10) return false;
    if (state.money < 5000) return false;

    state = state.copyWith(
      bodyguards: state.bodyguards + 1,
      money: state.money - 5000,
    );
    _saveState();
    return true;
  }

  // ==================== GANG METHODS ====================

  /// Add gang member
  void addGangMate(int count) {
    state = state.copyWith(gangMates: state.gangMates + count);
    _saveState();
  }

  /// Recruit gang members (costs money)
  bool recruitGangMembers(int count, int cost) {
    if (state.money < cost) return false;
    if (count <= 0) return false;

    state = state.copyWith(
      gangMates: state.gangMates + count,
      money: state.money - cost,
    );
    _saveState();
    return true;
  }

  /// Remove gang members (after fight)
  void removeGangMates(int count) {
    state = state.copyWith(gangMates: (state.gangMates - count).clamp(0, 999));
    _saveState();
  }

  // ==================== BUILDING UNLOCKS ====================

  /// Check and update building unlocks based on money
  void _checkUnlocks() {
    bool bodyguardUnlocked = state.bodyguardUnlocked;
    bool gangUnlocked = state.gangUnlocked;

    if (!bodyguardUnlocked && state.canUnlockBodyguards) {
      bodyguardUnlocked = true;
    }
    if (!gangUnlocked && state.canUnlockGang) {
      gangUnlocked = true;
    }

    if (bodyguardUnlocked != state.bodyguardUnlocked ||
        gangUnlocked != state.gangUnlocked) {
      state = state.copyWith(
        bodyguardUnlocked: bodyguardUnlocked,
        gangUnlocked: gangUnlocked,
      );
    }
  }

  // ==================== GAME MANAGEMENT ====================

  // ==================== INVENTORY METHODS ====================

  /// Buy an item from the market
  /// Returns true if purchase successful
  bool buyItem(InventoryItem item) {
    if (state.money < item.price) return false;

    // Check if item already exists in inventory
    final existingIndex = state.inventory.indexWhere((i) => i.id == item.id);

    List<InventoryItem> newInventory = List.from(state.inventory);

    if (existingIndex >= 0) {
      // Increase quantity
      final existing = newInventory[existingIndex];
      newInventory[existingIndex] = existing.copyWith(
        quantity: existing.quantity + 1,
      );
    } else {
      // Add new item with quantity 1
      newInventory.add(item.copyWith(quantity: 1));
    }

    state = state.copyWith(
      money: state.money - item.price,
      inventory: newInventory,
    );
    _saveState();
    return true;
  }

  /// Use an item from inventory
  /// Returns the hunger restored, or 0 if failed
  int useItem(InventoryItem item) {
    final existingIndex = state.inventory.indexWhere((i) => i.id == item.id);

    if (existingIndex < 0) return 0;

    final existing = state.inventory[existingIndex];
    if (existing.quantity <= 0) return 0;

    List<InventoryItem> newInventory = List.from(state.inventory);

    if (existing.quantity == 1) {
      // Remove item from inventory
      newInventory.removeAt(existingIndex);
    } else {
      // Decrease quantity
      newInventory[existingIndex] = existing.copyWith(
        quantity: existing.quantity - 1,
      );
    }

    // Calculate actual hunger restored (don't exceed max)
    final hungerDeficit = state.maxHunger - state.hunger;
    final actualRestore = item.hungerRestore.clamp(0, hungerDeficit);

    state = state.copyWith(
      hunger: (state.hunger + item.hungerRestore).clamp(0, state.maxHunger),
      inventory: newInventory,
    );
    _saveState();
    return actualRestore > 0 ? actualRestore : item.hungerRestore;
  }

  /// Get total item count in inventory
  int get totalInventoryItems {
    return state.inventory.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Check if inventory has any items
  bool get hasInventoryItems => state.inventory.isNotEmpty;

  // ==================== STREET JOBS METHODS ====================

  /// Complete Math Quiz job - returns reward amount (0 if max attempts reached)
  int completeMathQuiz(int correctAnswers) {
    if (!state.canPlayMathQuiz) return 0;

    final reward = correctAnswers * 10; // $10 per correct answer
    state = state.copyWith(
      money: state.money + reward,
      mathQuizCount: state.mathQuizCount + 1,
    );
    _checkUnlocks();
    _saveState();
    return reward;
  }

  /// Complete Match Samples job - returns reward amount (0 if max attempts reached)
  int completeMatchSamples() {
    if (!state.canPlayMatchSamples) return 0;

    const reward = 50;
    state = state.copyWith(
      money: state.money + reward,
      matchSamplesCount: state.matchSamplesCount + 1,
    );
    _checkUnlocks();
    _saveState();
    return reward;
  }

  /// Complete Code Breaker job - returns reward amount (0 if max attempts reached)
  int completeCodeBreaker() {
    if (!state.canPlayCodeBreaker) return 0;

    const reward = 30;
    state = state.copyWith(
      money: state.money + reward,
      codeBreakerCount: state.codeBreakerCount + 1,
    );
    _checkUnlocks();
    _saveState();
    return reward;
  }

  /// Complete Guess Game job - returns reward amount (0 if max attempts reached)
  int completeGuessGame() {
    if (!state.canPlayGuessGame) return 0;

    const reward = 20;
    state = state.copyWith(
      money: state.money + reward,
      guessGameCount: state.guessGameCount + 1,
    );
    _checkUnlocks();
    _saveState();
    return reward;
  }

  /// Reset game to initial state
  void resetGame() {
    state = const GameState();
    _saveState();
  }
}

// Main game state provider
final gameProvider = NotifierProvider<GameNotifier, GameState>(() {
  return GameNotifier();
});
