import 'inventory_item.dart';

// Game State Model - Core player data
class GameState {
  final int money;
  final int hp;
  final int maxHp;
  final int hunger;
  final int maxHunger;
  final int level;
  final int xp;
  final int xpToNextLevel;
  final int bodyguards;
  final int gangMates;
  final int familyHappiness;
  final int maxFamilyHappiness;
  final int hospitalCost;
  final int hospitalUseCount;
  final bool gangUnlocked;
  final bool bodyguardUnlocked;
  final bool familyBroken;
  final int lastHomeVisit; // timestamp in milliseconds
  final int lastCasinoVisit; // timestamp in milliseconds
  final int homeVisitCount;
  final int totalMoneyGivenToFamily;
  final List<InventoryItem> inventory;
  // Street Jobs completion counts (max 3 each)
  final int mathQuizCount;
  final int matchSamplesCount;
  final int codeBreakerCount;
  final int guessGameCount;

  static const int maxJobAttempts = 3;

  const GameState({
    this.money = 100,
    this.hp = 100,
    this.maxHp = 100,
    this.hunger = 100,
    this.maxHunger = 100,
    this.level = 1,
    this.xp = 0,
    this.xpToNextLevel = 100,
    this.bodyguards = 0,
    this.gangMates = 0,
    this.familyHappiness = 100,
    this.maxFamilyHappiness = 100,
    this.hospitalCost = 1500,
    this.hospitalUseCount = 0,
    this.gangUnlocked = false,
    this.bodyguardUnlocked = false,
    this.familyBroken = false,
    this.lastHomeVisit = 0,
    this.lastCasinoVisit = 0,
    this.homeVisitCount = 0,
    this.totalMoneyGivenToFamily = 0,
    this.inventory = const [],
    this.mathQuizCount = 0,
    this.matchSamplesCount = 0,
    this.codeBreakerCount = 0,
    this.guessGameCount = 0,
  });

  // Street job helpers
  bool get canPlayMathQuiz => mathQuizCount < maxJobAttempts;
  bool get canPlayMatchSamples => matchSamplesCount < maxJobAttempts;
  bool get canPlayCodeBreaker => codeBreakerCount < maxJobAttempts;
  bool get canPlayGuessGame => guessGameCount < maxJobAttempts;

  int get mathQuizAttemptsLeft => maxJobAttempts - mathQuizCount;
  int get matchSamplesAttemptsLeft => maxJobAttempts - matchSamplesCount;
  int get codeBreakerAttemptsLeft => maxJobAttempts - codeBreakerCount;
  int get guessGameAttemptsLeft => maxJobAttempts - guessGameCount;

  // Calculate actual max HP (capped at 75 if family broken)
  int get effectiveMaxHp => familyBroken ? 75 : maxHp;

  // Check if mafia extortion is active
  bool get isMafiaActive => money > 10000;

  // Check if bodyguard building should be unlocked
  bool get canUnlockBodyguards => money >= 50000;

  // Check if gang building should be unlocked
  bool get canUnlockGang => money >= 100000;

  // Calculate home visit reward based on level
  int get homeVisitReward => (200 * (1 + 0.2 * (level - 1))).round();

  // Calculate tribute range based on money
  int get minTribute {
    if (money <= 10000) return 700;
    return (700 + ((money - 10000) / 1000) * 50).round();
  }

  int get maxTribute {
    if (money <= 10000) return 1000;
    return (1000 + ((money - 10000) / 1000) * 75).round();
  }

  // XP progress percentage (0.0 to 1.0)
  double get xpProgress =>
      xpToNextLevel > 0 ? (xp / xpToNextLevel).clamp(0.0, 1.0) : 0.0;

  GameState copyWith({
    int? money,
    int? hp,
    int? maxHp,
    int? hunger,
    int? maxHunger,
    int? level,
    int? xp,
    int? xpToNextLevel,
    int? bodyguards,
    int? gangMates,
    int? familyHappiness,
    int? maxFamilyHappiness,
    int? hospitalCost,
    int? hospitalUseCount,
    bool? gangUnlocked,
    bool? bodyguardUnlocked,
    bool? familyBroken,
    int? lastHomeVisit,
    int? lastCasinoVisit,
    int? homeVisitCount,
    int? totalMoneyGivenToFamily,
    List<InventoryItem>? inventory,
    int? mathQuizCount,
    int? matchSamplesCount,
    int? codeBreakerCount,
    int? guessGameCount,
  }) {
    return GameState(
      money: money ?? this.money,
      hp: hp ?? this.hp,
      maxHp: maxHp ?? this.maxHp,
      hunger: hunger ?? this.hunger,
      maxHunger: maxHunger ?? this.maxHunger,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      bodyguards: bodyguards ?? this.bodyguards,
      gangMates: gangMates ?? this.gangMates,
      familyHappiness: familyHappiness ?? this.familyHappiness,
      maxFamilyHappiness: maxFamilyHappiness ?? this.maxFamilyHappiness,
      hospitalCost: hospitalCost ?? this.hospitalCost,
      hospitalUseCount: hospitalUseCount ?? this.hospitalUseCount,
      gangUnlocked: gangUnlocked ?? this.gangUnlocked,
      bodyguardUnlocked: bodyguardUnlocked ?? this.bodyguardUnlocked,
      familyBroken: familyBroken ?? this.familyBroken,
      lastHomeVisit: lastHomeVisit ?? this.lastHomeVisit,
      lastCasinoVisit: lastCasinoVisit ?? this.lastCasinoVisit,
      homeVisitCount: homeVisitCount ?? this.homeVisitCount,
      totalMoneyGivenToFamily:
          totalMoneyGivenToFamily ?? this.totalMoneyGivenToFamily,
      inventory: inventory ?? this.inventory,
      mathQuizCount: mathQuizCount ?? this.mathQuizCount,
      matchSamplesCount: matchSamplesCount ?? this.matchSamplesCount,
      codeBreakerCount: codeBreakerCount ?? this.codeBreakerCount,
      guessGameCount: guessGameCount ?? this.guessGameCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'money': money,
    'hp': hp,
    'maxHp': maxHp,
    'hunger': hunger,
    'maxHunger': maxHunger,
    'level': level,
    'xp': xp,
    'xpToNextLevel': xpToNextLevel,
    'bodyguards': bodyguards,
    'gangMates': gangMates,
    'familyHappiness': familyHappiness,
    'maxFamilyHappiness': maxFamilyHappiness,
    'hospitalCost': hospitalCost,
    'hospitalUseCount': hospitalUseCount,
    'gangUnlocked': gangUnlocked,
    'bodyguardUnlocked': bodyguardUnlocked,
    'familyBroken': familyBroken,
    'lastHomeVisit': lastHomeVisit,
    'lastCasinoVisit': lastCasinoVisit,
    'homeVisitCount': homeVisitCount,
    'totalMoneyGivenToFamily': totalMoneyGivenToFamily,
    'inventory': inventory.map((item) => item.toJson()).toList(),
    'mathQuizCount': mathQuizCount,
    'matchSamplesCount': matchSamplesCount,
    'codeBreakerCount': codeBreakerCount,
    'guessGameCount': guessGameCount,
  };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
    money: json['money'] ?? 100,
    hp: json['hp'] ?? 100,
    maxHp: json['maxHp'] ?? 100,
    hunger: json['hunger'] ?? 100,
    maxHunger: json['maxHunger'] ?? 100,
    level: json['level'] ?? 1,
    xp: json['xp'] ?? 0,
    xpToNextLevel: json['xpToNextLevel'] ?? 100,
    bodyguards: json['bodyguards'] ?? 0,
    gangMates: json['gangMates'] ?? 0,
    familyHappiness: json['familyHappiness'] ?? 100,
    maxFamilyHappiness: json['maxFamilyHappiness'] ?? 100,
    hospitalCost: json['hospitalCost'] ?? 1500,
    hospitalUseCount: json['hospitalUseCount'] ?? 0,
    gangUnlocked: json['gangUnlocked'] ?? false,
    bodyguardUnlocked: json['bodyguardUnlocked'] ?? false,
    familyBroken: json['familyBroken'] ?? false,
    lastHomeVisit: json['lastHomeVisit'] ?? 0,
    lastCasinoVisit: json['lastCasinoVisit'] ?? 0,
    homeVisitCount: json['homeVisitCount'] ?? 0,
    totalMoneyGivenToFamily: json['totalMoneyGivenToFamily'] ?? 0,
    inventory:
        (json['inventory'] as List<dynamic>?)
            ?.map(
              (item) => InventoryItem.fromJson(item as Map<String, dynamic>),
            )
            .toList() ??
        [],
    mathQuizCount: json['mathQuizCount'] ?? 0,
    matchSamplesCount: json['matchSamplesCount'] ?? 0,
    codeBreakerCount: json['codeBreakerCount'] ?? 0,
    guessGameCount: json['guessGameCount'] ?? 0,
  );
}
