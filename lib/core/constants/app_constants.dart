// App Constants - Game rules and settings
class AppConstants {
  // Starting values
  static const int startingMoney = 100;
  static const int startingHp = 100;
  static const int startingHunger = 100;
  static const int startingLevel = 1;
  static const int startingFamilyHappiness = 100;

  // Bodyguard settings
  static const int bodyguardUnlockMoney = 50000;
  static const int bodyguardCost = 5000;
  static const int maxBodyguards = 10;
  static const int bodyguardDamageReduction = 5;

  // Gang settings
  static const int gangUnlockMoney = 100000;
  static const int minGangDeathPerFight = 1;
  static const int maxGangDeathPerFight = 5;

  // Mafia settings
  static const int mafiaActivationMoney = 10000;
  static const int baseTributeMin = 700;
  static const int baseTributeMax = 1000;

  // Hospital settings
  static const int hospitalBaseCost = 1500;
  static const int hospitalCostIncrease = 1000;

  // Home settings
  static const int baseHomeReward = 200;
  static const double homeRewardLevelMultiplier = 0.2;

  // Family settings
  static const int brokenFamilyMaxHp = 75;

  // Street job rewards
  static const int mathQuizRewardPerQuestion = 10;
  static const int matchSamplesReward = 50;
  static const int codeBreakerReward = 30;
  static const int guessGameReward = 20;

  // UI Constants
  static const double borderRadius = 16.0;
  static const double cardBorderRadius = 20.0;
  static const double buttonBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Animation durations (milliseconds)
  static const int buttonPressDuration = 100;
  static const int buttonReleaseDuration = 200;
  static const int pageTransitionDuration = 300;
}
