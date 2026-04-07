import 'package:flutter/material.dart';

enum GameType { bubbleBlast, wordSearch, blockBlast, colorMatch }

class GameConfig {
  final GameType type;
  final String name;
  final String emoji;
  final String description;
  final int durationSeconds;
  final Color primaryColor;
  final Color secondaryColor;
  final String highScoreKey;

  const GameConfig({
    required this.type,
    required this.name,
    required this.emoji,
    required this.description,
    required this.durationSeconds,
    required this.primaryColor,
    required this.secondaryColor,
    required this.highScoreKey,
  });
}

class GameResult {
  final GameType type;
  final int score;
  final bool won;
  final int timeUsed;

  const GameResult({
    required this.type,
    required this.score,
    required this.won,
    required this.timeUsed,
  });
}