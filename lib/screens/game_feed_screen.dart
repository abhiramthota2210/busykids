import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_model.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import 'game_wrapper.dart';

class GameFeedScreen extends StatefulWidget {
  const GameFeedScreen({super.key});

  @override
  State<GameFeedScreen> createState() => _GameFeedScreenState();
}

class _GameFeedScreenState extends State<GameFeedScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isAnimating = false;

  static final List<GameConfig> _games = [
    const GameConfig(
      type: GameType.bubbleBlast,
      name: 'Bubble Blast',
      emoji: '🫧',
      description: 'Pop color clusters before time runs out!',
      durationSeconds: AppConstants.bubbleBlastDuration,
      primaryColor: Color(0xFF6C63FF),
      secondaryColor: Color(0xFF4ECDC4),
      highScoreKey: AppConstants.keyHighScoreBubble,
    ),
    const GameConfig(
      type: GameType.wordSearch,
      name: 'Word Search',
      emoji: '🔤',
      description: 'Find hidden words in the grid!',
      durationSeconds: AppConstants.wordSearchDuration,
      primaryColor: Color(0xFF2ECC71),
      secondaryColor: Color(0xFF1ABC9C),
      highScoreKey: AppConstants.keyHighScoreWord,
    ),
    const GameConfig(
      type: GameType.blockBlast,
      name: 'Block Blast',
      emoji: '🟦',
      description: 'Fill rows with blocks to clear them!',
      durationSeconds: AppConstants.blockBlastDuration,
      primaryColor: Color(0xFFFF6584),
      secondaryColor: Color(0xFFFF8E53),
      highScoreKey: AppConstants.keyHighScoreBlock,
    ),
    const GameConfig(
      type: GameType.colorMatch,
      name: 'Color Match',
      emoji: '🎨',
      description: 'Tap all tiles matching the target color!',
      durationSeconds: AppConstants.colorMatchDuration,
      primaryColor: Color(0xFFFFE66D),
      secondaryColor: Color(0xFFFF9800),
      highScoreKey: AppConstants.keyHighScoreColor,
    ),
  ];

  // Infinite loop: repeat games
  static const int _virtualCount = 10000;
  static const int _startIndex = 5000;

  GameConfig _configAt(int index) => _games[index % _games.length];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _startIndex);
    _currentPage = _startIndex;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNext() {
    if (_isAnimating) return;
    _isAnimating = true;
    HapticFeedback.lightImpact();
    _pageController
        .nextPage(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        )
        .then((_) => _isAnimating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Game feed
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemCount: _virtualCount,
            itemBuilder: (context, index) {
              final config = _configAt(index);
              final isActive = index == _currentPage;

              return GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null &&
                      details.primaryVelocity! < -300) {
                    _goToNext();
                  }
                },
                child: GameWrapper(
                  key: ValueKey('game_${index}_${config.type.name}'),
                  config: config,
                  isActive: isActive,
                  onSwipeUp: _goToNext,
                ),
              );
            },
          ),

          // Page indicator dots (right side)
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_games.length, (i) {
                    final isCurrent = i == (_currentPage % _games.length);
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 4,
                      height: isCurrent ? 20 : 6,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? _configAt(_currentPage).primaryColor
                            : AppColors.textMuted,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}