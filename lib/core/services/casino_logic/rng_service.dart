import 'dart:math';

/// Seedable RNG service for testable casino randomness
/// All casino games should use this for consistency and testing
class CasinoRng {
  static CasinoRng? _instance;
  late Random _random;
  int? _seed;

  CasinoRng._internal([int? seed]) {
    _seed = seed;
    _random = seed != null ? Random(seed) : Random();
  }

  /// Get singleton instance
  static CasinoRng get instance {
    _instance ??= CasinoRng._internal();
    return _instance!;
  }

  /// Create a seeded instance (for testing/simulation)
  factory CasinoRng.seeded(int seed) {
    return CasinoRng._internal(seed);
  }

  /// Reset with optional seed (useful for testing)
  static void reset([int? seed]) {
    _instance = CasinoRng._internal(seed);
  }

  /// Get current seed (null if unseeded)
  int? get seed => _seed;

  /// Generate random double [0, 1)
  double nextDouble() => _random.nextDouble();

  /// Generate random int [0, max)
  int nextInt(int max) => _random.nextInt(max);

  /// Generate random bool
  bool nextBool() => _random.nextBool();

  /// Select from weighted options
  /// weights: map of option -> weight (higher = more likely)
  /// Returns selected option
  T selectWeighted<T>(Map<T, double> weights) {
    final totalWeight = weights.values.fold(0.0, (a, b) => a + b);
    var random = nextDouble() * totalWeight;

    for (final entry in weights.entries) {
      random -= entry.value;
      if (random <= 0) {
        return entry.key;
      }
    }

    // Fallback (should not reach here)
    return weights.keys.last;
  }

  /// Select random item from list
  T selectRandom<T>(List<T> items) {
    return items[nextInt(items.length)];
  }

  /// Generate crash point using inverse transform sampling
  /// For aviator-style games with house edge
  /// Formula: crashPoint = 1 / (1 - (1 - houseEdge) * random)
  /// This creates an exponential-like distribution where lower multipliers
  /// are more likely than higher ones
  double generateCrashPoint(double houseEdge) {
    final random = nextDouble();
    // Avoid division by zero and ensure minimum crash of 1.0
    if (random >= (1 - houseEdge)) {
      return 1.0; // Instant crash
    }
    // Inverse transform for crash distribution
    // E[1/crashPoint] = 1 - houseEdge, giving expected RTP = 1 - houseEdge
    return 1 / (1 - random * (1 - houseEdge));
  }
}
