import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_model.dart';
import '../services/score_service.dart';
import '../utils/app_colors.dart';
import '../widgets/timer_bar.dart';
import '../widgets/score_badge.dart';
import '../widgets/swipe_hint.dart';
import '../games/bubble_blast.dart';
import '../games/word_search.dart';
import '../games/block_blast.dart';
import '../games/color_match.dart';

class GameWrapper extends StatefulWidget {
  final GameConfig config;
  final VoidCallback onSwipeUp;
  final bool isActive;

  const GameWrapper({
    super.key,
    required this.config,
    required this.onSwipeUp,
    required this.isActive,
  });

  @override
  State<GameWrapper> createState() => _GameWrapperState();
}

class _GameWrapperState extends State<GameWrapper>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late int _timeLeft;
  int _score = 0;
  bool _gameOver = false;
  bool _won = false;
  bool _isActive = true;

  late AnimationController _resultController;
  late Animation<double> _resultScale;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.config.durationSeconds;
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _resultScale = CurvedAnimation(
      parent: _resultController,
      curve: Curves.elasticOut,
    );

    if (widget.isActive) _startTimer();
  }

  @override
  void didUpdateWidget(GameWrapper old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive && !_gameOver) {
      _startTimer();
    } else if (!widget.isActive && old.isActive) {
      _pauseTimer();
    }
  }

  void _startTimer() {
    _isActive = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) _endGame(false);
    });
  }

  void _pauseTimer() {
    _isActive = false;
    _timer.cancel();
  }

  void _endGame(bool won) {
    if (_gameOver) return;
    _timer.cancel();
    setState(() {
      _gameOver = true;
      _won = won;
      _isActive = false;
    });
    HapticFeedback.mediumImpact();
    _resultController.forward();
    ScoreService.instance.saveIfHighScore(
      widget.config.highScoreKey,
      _score,
    );
  }

  void _addScore(int pts) {
    if (!mounted || _gameOver) return;
    setState(() => _score += pts);
  }

  @override
  void dispose() {
    _timer.cancel();
    _resultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _timeLeft / widget.config.durationSeconds;
    final color = widget.config.primaryColor;

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Row(
                    children: [
                      // Game name + emoji
                      Row(children: [
                        Text(
                          widget.config.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.config.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ]),
                      const Spacer(),
                      // Timer
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _timeLeft <= 10
                              ? AppColors.accent.withValues(alpha: 0.2)
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_timeLeft s',
                          style: TextStyle(
                            color: _timeLeft <= 10
                                ? AppColors.accent
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedScoreBump(score: _score, color: color),
                    ],
                  ),
                ),

                // Timer bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TimerBar(progress: progress, color: color),
                ),

                const SizedBox(height: 10),

                // Game area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: AbsorbPointer(
                      absorbing: _gameOver || !_isActive,
                      child: _buildGame(),
                    ),
                  ),
                ),

                // Swipe hint
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, top: 4),
                  child: _gameOver
                      ? GestureDetector(
                          onTap: widget.onSwipeUp,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: color.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              'Next Game →',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : const SwipeHint(),
                ),
              ],
            ),

            // Game over overlay
            if (_gameOver)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(color: Colors.black.withValues(alpha: 0.4)),
                ),
              ),

            if (_gameOver)
              Center(
                child: ScaleTransition(
                  scale: _resultScale,
                  child: _ResultCard(
                    won: _won,
                    score: _score,
                    color: color,
                    gameName: widget.config.name,
                    onNext: widget.onSwipeUp,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGame() {
    switch (widget.config.type) {
      case GameType.bubbleBlast:
        return BubbleBlastGame(
          onScore: _addScore,
          onWin: () => _endGame(true),
          isActive: _isActive && !_gameOver,
        );
      case GameType.wordSearch:
        return WordSearchGame(
          onScore: _addScore,
          onWin: () => _endGame(true),
          isActive: _isActive && !_gameOver,
        );
      case GameType.blockBlast:
        return BubbleBlastGame(
          onScore: _addScore,
          onWin: () => _endGame(true),
          isActive: _isActive && !_gameOver,
        );
      case GameType.colorMatch:
        return WordSearchGame(
          onScore: _addScore,
          onWin: () => _endGame(true),
          isActive: _isActive && !_gameOver,
        );
    }
  }
}

class _ResultCard extends StatelessWidget {
  final bool won;
  final int score;
  final Color color;
  final String gameName;
  final VoidCallback onNext;

  const _ResultCard({
    required this.won,
    required this.score,
    required this.color,
    required this.gameName,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            won ? '🎉' : '⏱️',
            style: const TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 8),
          Text(
            won ? 'Level Clear!' : "Time's Up!",
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            gameName,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Score',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                Text(
                  '$score',
                  style: TextStyle(
                    color: color,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onNext,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Next Game →',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
