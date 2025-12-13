import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/game_provider.dart';
import '../../../core/services/casino_logic/casino_logic.dart';
import '../../../shared/widgets/casino_widgets.dart';

/// Blackjack Game Page - Beat the dealer to 21!
class BlackjackPage extends ConsumerStatefulWidget {
  const BlackjackPage({super.key});

  @override
  ConsumerState<BlackjackPage> createState() => _BlackjackPageState();
}

class _BlackjackPageState extends ConsumerState<BlackjackPage> {
  // Casino logic
  final BlackjackLogic _blackjackLogic = BlackjackLogic();
  BlackjackResult? _blackjackResult;

  // Game state
  int _betAmount = 100;
  List<_Card> _playerHand = [];
  List<_Card> _dealerHand = [];
  bool _gameInProgress = false;
  bool _playerStand = false;
  bool _showResult = false;
  String _resultMessage = '';
  int _winAmount = 0;

  // Preset bet amounts
  final List<int> _betPresets = [50, 100, 250, 500, 1000];

  // Convert BlackjackCard to display _Card
  _Card _convertCard(BlackjackCard card) {
    return _Card(
      suit: card.suitString,
      rank: card.rankString,
      value: card.value,
    );
  }

  // Get hand value using casino logic
  int _calculateHandValue(List<_Card> hand) {
    // This is now only used for reference; actual value comes from BlackjackHand
    int total = 0;
    int aces = 0;
    for (final card in hand) {
      total += card.value;
      if (card.rank == 'A') aces++;
    }
    while (total > 21 && aces > 0) {
      total -= 10;
      aces--;
    }
    return total;
  }

  void _selectBetAmount(int amount) {
    if (_gameInProgress) return;
    HapticFeedback.selectionClick();
    setState(() => _betAmount = amount);
  }

  void _startGame() {
    if (_gameInProgress) return;

    final gameState = ref.read(gameProvider);
    if (gameState.money < _betAmount) {
      _showInsufficientFundsSnackbar();
      return;
    }

    // Deduct bet
    ref.read(gameProvider.notifier).spendMoney(_betAmount);

    HapticFeedback.heavyImpact();

    // Start new game using casino logic
    _blackjackLogic.newGame();

    setState(() {
      _gameInProgress = true;
      _playerStand = false;
      _showResult = false;
      _resultMessage = '';
      _winAmount = 0;
      _blackjackResult = null;

      // Convert cards from logic for display
      _playerHand = _blackjackLogic.playerHand.cards.map(_convertCard).toList();
      _dealerHand = _blackjackLogic.dealerHand.cards.map(_convertCard).toList();
    });

    // Check for natural blackjack
    if (_blackjackLogic.playerHand.isBlackjack) {
      _playerStand = true;
      _dealerPlay();
    }
  }

  void _hit() {
    if (!_gameInProgress || _playerStand) return;

    HapticFeedback.selectionClick();

    // Use casino logic for hit
    _blackjackLogic.hit();

    setState(() {
      _playerHand = _blackjackLogic.playerHand.cards.map(_convertCard).toList();
    });

    if (_blackjackLogic.playerHand.isBusted) {
      // Player busts
      _endGame('BUST! 💥', false);
    } else if (_blackjackLogic.playerHand.value == 21) {
      // Auto-stand on 21
      _stand();
    }
  }

  void _stand() {
    if (!_gameInProgress || _playerStand) return;

    HapticFeedback.selectionClick();

    setState(() {
      _playerStand = true;
    });

    _dealerPlay();
  }

  void _dealerPlay() {
    // Use casino logic for dealer play with animation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      // Let casino logic handle dealer
      _blackjackLogic.dealerPlay();

      setState(() {
        _dealerHand = _blackjackLogic.dealerHand.cards
            .map(_convertCard)
            .toList();
      });

      _determineWinner();
    });
  }

  void _determineWinner() {
    // Use casino logic to determine winner
    _blackjackResult = _blackjackLogic.getResult(_betAmount);

    switch (_blackjackResult!.outcome) {
      case BlackjackOutcome.playerBlackjack:
        _endGame('BLACKJACK! 🃏', true, payout: _blackjackResult!.payout);
      case BlackjackOutcome.playerWins:
        _endGame('YOU WIN! 🎉', true, payout: _blackjackResult!.payout);
      case BlackjackOutcome.dealerWins:
        _endGame('Dealer Wins 😢', false);
      case BlackjackOutcome.dealerBusts:
        _endGame('Dealer Busts! 🎉', true, payout: _blackjackResult!.payout);
      case BlackjackOutcome.push:
        _endGame('PUSH 🤝', true, payout: _blackjackResult!.payout);
      case BlackjackOutcome.playerBusts:
        _endGame('BUST! 💥', false);
    }
  }

  void _endGame(String message, bool playerWins, {int payout = 0}) {
    HapticFeedback.mediumImpact();

    setState(() {
      _gameInProgress = false;
      _showResult = true;
      _resultMessage = message;

      if (playerWins && payout > 0) {
        _winAmount = payout;
        ref.read(gameProvider.notifier).addMoney(_winAmount);
        if (payout > _betAmount) {
          HapticFeedback.heavyImpact();
        }
      }
    });
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
      _playerHand = [];
      _dealerHand = [];
      _showResult = false;
      _resultMessage = '';
      _winAmount = 0;
      _blackjackResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final playerValue = _calculateHandValue(_playerHand);
    final dealerValue = _calculateHandValue(_dealerHand);
    final bool canPlay = !_gameInProgress && gameState.money >= _betAmount;

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
        title: const Text('🃏 Blackjack'),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Bet amount selector (only when not in game)
            if (!_gameInProgress && !_showResult)
              BetSelector(
                presets: _betPresets,
                currentBet: _betAmount,
                playerMoney: gameState.money,
                isDisabled: _gameInProgress,
                onSelect: _selectBetAmount,
              ),

            if (!_gameInProgress && !_showResult) const SizedBox(height: 16),

            // Dealer area
            GameArea(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dealer',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      if (_dealerHand.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _playerStand || _showResult
                                ? '$dealerValue'
                                : '${_dealerHand.first.value}+?',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: _dealerHand.isEmpty
                        ? Center(
                            child: Text(
                              'Place bet to start',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (int i = 0; i < _dealerHand.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _CardWidget(
                                    card: _dealerHand[i],
                                    faceDown:
                                        i == 1 && !_playerStand && !_showResult,
                                  ),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Game table
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D5C36), // Casino green
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.5),
                    width: 3,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'BLACKJACK PAYS 3:2',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Result message
                    if (_showResult)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: _winAmount > 0
                              ? AppColors.success.withValues(alpha: 0.9)
                              : AppColors.danger.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _resultMessage,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_winAmount > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                _winAmount > _betAmount
                                    ? '+\$$_winAmount'
                                    : 'Bet returned',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    else if (_gameInProgress)
                      Text(
                        _playerStand ? 'Dealer is playing...' : 'Hit or Stand?',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      )
                    else
                      Text(
                        'Place your bet!',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 16,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Player area
            GameArea(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Hand',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      if (_playerHand.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: playerValue > 21
                                ? AppColors.danger.withValues(alpha: 0.2)
                                : playerValue == 21
                                ? AppColors.success.withValues(alpha: 0.2)
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: playerValue > 21
                                  ? AppColors.danger
                                  : playerValue == 21
                                  ? AppColors.success
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            '$playerValue',
                            style: TextStyle(
                              color: playerValue > 21
                                  ? AppColors.danger
                                  : playerValue == 21
                                  ? AppColors.success
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: _playerHand.isEmpty
                        ? Center(
                            child: Text(
                              'Your cards will appear here',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (final card in _playerHand)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _CardWidget(card: card),
                                  ),
                              ],
                            ),
                          ),
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
            else if (_gameInProgress)
              Row(
                children: [
                  Expanded(
                    child: GameButton(
                      text: 'HIT',
                      icon: Icons.add_card,
                      color: AppColors.info,
                      enabled: !_playerStand,
                      onPressed: _hit,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GameButton(
                      text: 'STAND',
                      icon: Icons.front_hand,
                      color: AppColors.warning,
                      enabled: !_playerStand,
                      onPressed: _stand,
                    ),
                  ),
                ],
              )
            else
              GameButton(
                text: 'DEAL',
                icon: Icons.play_arrow,
                color: AppColors.success,
                enabled: canPlay,
                onPressed: _startGame,
              ),
          ],
        ),
      ),
    );
  }
}

class _Card {
  final String suit;
  final String rank;
  final int value;

  _Card({required this.suit, required this.rank, required this.value});

  bool get isRed => suit == '♥' || suit == '♦';
}

class _CardWidget extends StatelessWidget {
  final _Card card;
  final bool faceDown;

  const _CardWidget({required this.card, this.faceDown = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 90,
      decoration: BoxDecoration(
        color: faceDown ? AppColors.accent : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: faceDown
          ? Center(
              child: Container(
                width: 40,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    '🎴',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Column(
                      children: [
                        Text(
                          card.rank,
                          style: TextStyle(
                            color: card.isRed ? Colors.red : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          card.suit,
                          style: TextStyle(
                            color: card.isRed ? Colors.red : Colors.black,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Text(
                      card.suit,
                      style: TextStyle(
                        color: card.isRed ? Colors.red : Colors.black,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Transform.rotate(
                      angle: pi,
                      child: Column(
                        children: [
                          Text(
                            card.rank,
                            style: TextStyle(
                              color: card.isRed ? Colors.red : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            card.suit,
                            style: TextStyle(
                              color: card.isRed ? Colors.red : Colors.black,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
