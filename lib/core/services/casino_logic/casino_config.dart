/// Casino configuration with per-game RTP/house edge settings
/// All odds are configurable for testing and balance adjustments

class CasinoConfig {
  // ==================== ROULETTE ====================
  /// European roulette has single zero (37 numbers: 0-36)
  /// American roulette has double zero (38 numbers) - not implemented
  static const String rouletteType = 'european';

  /// European roulette natural house edge: 1/37 ≈ 2.7%
  /// This comes from the single zero giving house an edge on even-money bets
  static const double rouletteHouseEdge = 1 / 37; // ~2.7%

  // Roulette payouts (standard)
  static const int rouletteSingleNumberPayout = 35; // 35:1 (36 total return)
  static const int rouletteColorPayout = 1; // 1:1 (2 total return)
  static const int rouletteOddEvenPayout = 1; // 1:1
  static const int rouletteHighLowPayout = 1; // 1:1
  static const int rouletteDozenPayout = 2; // 2:1 (3 total return)
  static const int rouletteColumnPayout = 2; // 2:1

  // ==================== BLACKJACK ====================
  /// Dealer stands on soft 17 (standard rule)
  static const bool blackjackDealerStandsOnSoft17 = true;

  /// Blackjack (21 with first 2 cards) pays 3:2
  static const double blackjackNaturalPayout = 1.5; // 3:2

  /// Normal win pays 1:1
  static const double blackjackWinPayout = 1.0;

  /// Push returns bet (0 profit)
  static const double blackjackPushPayout = 0.0;

  /// Number of decks (affects house edge slightly)
  static const int blackjackDecks = 6;

  /// Insurance disabled by default (bad bet for player)
  static const bool blackjackInsuranceEnabled = false;

  /// Theoretical RTP for blackjack with basic strategy
  static const double blackjackTheoreticalRtp = 0.995; // ~99.5%

  // ==================== SLOT MACHINE ====================
  /// Target RTP (Return To Player) for slots
  /// 0.94 = 94% RTP = 6% house edge
  /// 0.96 = 96% RTP = 4% house edge
  static const double slotTargetRtp = 0.95; // 95% RTP, 5% house edge

  /// Minimum RTP (legal requirement in many jurisdictions)
  static const double slotMinRtp = 0.85;

  /// Maximum RTP
  static const double slotMaxRtp = 0.98;

  // ==================== COIN FLIP ====================
  /// House edge for coin flip (achieved through payout adjustment)
  /// 2% house edge means paying 1.96x instead of 2x
  static const double coinFlipHouseEdge = 0.02; // 2%

  /// Payout multiplier (2.0 * (1 - houseEdge))
  static double get coinFlipPayoutMultiplier => 2.0 * (1 - coinFlipHouseEdge);

  // ==================== HORSE RACE ====================
  /// House edge for horse racing (applied to fair odds)
  static const double horseRaceHouseEdge = 0.10; // 10% (typical for racing)

  /// Horse weights determine win probability
  /// Higher weight = more likely to win = lower payout
  static const Map<int, HorseConfig> horseConfigs = {
    0: HorseConfig(name: 'Thunder', weight: 25, color: 0xFFE53935), // Favorite
    1: HorseConfig(name: 'Lightning', weight: 22, color: 0xFF1E88E5),
    2: HorseConfig(name: 'Storm', weight: 20, color: 0xFF43A047),
    3: HorseConfig(name: 'Blaze', weight: 18, color: 0xFFFF9800),
    4: HorseConfig(name: 'Shadow', weight: 15, color: 0xFF8E24AA), // Longshot
  };

  // ==================== AVIATOR ====================
  /// House edge for aviator crash game
  /// 4% house edge is typical
  static const double aviatorHouseEdge = 0.04; // 4%

  /// Minimum crash point (always at least 1.0x)
  static const double aviatorMinCrash = 1.0;

  /// Maximum possible multiplier (for display purposes)
  static const double aviatorMaxDisplayMultiplier = 100.0;

  /// Multiplier growth rate (exponential: e^(rate * seconds))
  static const double aviatorGrowthRate = 0.06;

  // ==================== HELPER METHODS ====================

  /// Calculate fair odds from probability
  static double fairOddsFromProbability(double probability) {
    if (probability <= 0 || probability > 1) return 0;
    return 1 / probability;
  }

  /// Calculate payout with house edge applied
  static double payoutWithHouseEdge(double fairOdds, double houseEdge) {
    return fairOdds * (1 - houseEdge);
  }
}

/// Configuration for individual horses
class HorseConfig {
  final String name;
  final int weight; // Higher = more likely to win
  final int color;

  const HorseConfig({
    required this.name,
    required this.weight,
    required this.color,
  });

  /// Calculate win probability based on total weights
  double winProbability(int totalWeight) {
    return weight / totalWeight;
  }

  /// Calculate payout multiplier with house edge
  double payoutMultiplier(int totalWeight, double houseEdge) {
    final probability = winProbability(totalWeight);
    final fairOdds = 1 / probability;
    return fairOdds * (1 - houseEdge);
  }
}
