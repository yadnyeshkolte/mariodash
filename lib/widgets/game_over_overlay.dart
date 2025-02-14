import 'package:flutter/material.dart';

class GameOverOverlay extends StatelessWidget {
  final int score;
  final VoidCallback onRestart;

  const GameOverOverlay({
    super.key,
    required this.score,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Game Over!'),
      content: Text('Score: $score'),
      actions: [
        TextButton(
          onPressed: onRestart,
          child: const Text('Play Again'),
        ),
      ],
    );
  }
}