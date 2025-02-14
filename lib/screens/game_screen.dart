import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game_object.dart';
import '../widgets/game_over_overlay.dart';
import '../widgets/score_display.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  GameScreenState createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // Constants
  static const double groundHeight = 100;
  static const double gravity = -1.5;
  static const double jumpForce = 25.0;
  static const double marioSize = 60.0;

  // Game state
  double marioY = 0;
  double marioX = 50;
  double verticalVelocity = 0;
  bool isJumping = false;
  bool isGameOver = false;
  int score = 0;
  List<GameObject> obstacles = [];
  Timer? gameTimer;
  Timer? animationTimer;
  double gameSpeed = 5.0;

  // Animation state
  int currentFrame = 0;
  bool isAnimating = false;

  // Placeholder for images until actual assets are added
  Widget getMarioSprite() {
    return Image.asset(
      isJumping ? 'assets/images/mario_jump.png' : 'assets/images/mario_run${currentFrame + 1}.png',
      width: marioSize,
      height: marioSize,
    );
  }

  Widget getObstacleSprite(GameObject obstacle) {
    return Image.asset(
      'assets/images/pipe.png',
      width: obstacle.width,
      height: obstacle.height,
    );
  }
  @override
  void initState() {
    super.initState();
    setupGame();
    startAnimation();
  }

  void setupGame() {
    setState(() {
      marioY = 0;
      score = 0;
      isGameOver = false;
      gameSpeed = 5.0;
      obstacles.clear();

      gameTimer?.cancel();
      gameTimer = Timer.periodic(
          const Duration(milliseconds: 16),
              (timer) => updateGame()
      );
    });
  }

  void startAnimation() {
    animationTimer?.cancel();
    animationTimer = Timer.periodic(
      const Duration(milliseconds: 100),
          (timer) {
        if (!isGameOver && !isJumping) {
          setState(() {
            currentFrame = (currentFrame + 1) % 2; // Only using 2 frames for now
          });
        }
      },
    );
  }

  void jump() {
    if (!isJumping && !isGameOver) {
      setState(() {
        isJumping = true;
        verticalVelocity = jumpForce;
      });
    }
  }

  void updateGame() {
    if (isGameOver) return;

    setState(() {
      // Update Mario's position
      verticalVelocity += gravity;
      marioY += verticalVelocity;

      // Ground collision
      if (marioY <= 0) {
        marioY = 0;
        verticalVelocity = 0;
        isJumping = false;
      }

      // Update obstacles
      for (var obstacle in obstacles) {
        obstacle.x -= gameSpeed;
      }

      // Remove off-screen obstacles
      obstacles.removeWhere((obstacle) => obstacle.x < -50);

      // Add new obstacles
      if (obstacles.isEmpty ||
          obstacles.last.x < MediaQuery.of(context).size.width - 300) {
        obstacles.add(
          GameObject(
            x: MediaQuery.of(context).size.width,
            y: 0,
            width: 40,
            height: 70,
            type: 'basic',
          ),
        );
      }

      // Check collisions
      for (var obstacle in obstacles) {
        if (checkCollision(obstacle)) {
          gameOver();
          break;
        }
      }

      // Update score
      score++;

      // Increase speed
      if (score % 500 == 0) {
        gameSpeed += 0.5;
      }
    });
  }

  bool checkCollision(GameObject obstacle) {
    final marioRect = Rect.fromLTWH(
      marioX,
      groundHeight + marioY,
      marioSize * 0.8, // Smaller collision box
      marioSize * 0.8,
    );

    final obstacleRect = Rect.fromLTWH(
      obstacle.x,
      groundHeight,
      obstacle.width * 0.8,
      obstacle.height,
    );

    return marioRect.overlaps(obstacleRect);
  }

  void gameOver() {
    setState(() {
      isGameOver = true;
    });
    gameTimer?.cancel();
    animationTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameOverOverlay(
        score: score,
        onRestart: () {
          Navigator.of(context).pop();
          setupGame();
          startAnimation();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTapDown: (_) => jump(),
        child: Stack(
          children: [
            // Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.lightBlue.shade300,
                    Colors.lightBlue.shade100,
                  ],
                ),
              ),
            ),

            // Ground
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: groundHeight,
                decoration: BoxDecoration(
                  color: Colors.brown[200],
                  border: Border(
                    top: BorderSide(
                      color: Colors.brown.shade600,
                      width: 3,
                    ),
                  ),
                ),
              ),
            ),

            // Mario
            Positioned(
              left: marioX,
              bottom: groundHeight + marioY,
              child: getMarioSprite(),
            ),

            // Obstacles
            ...obstacles.map((obstacle) => Positioned(
              left: obstacle.x,
              bottom: groundHeight,
              child: getObstacleSprite(obstacle),
            )),

            // Score
            ScoreDisplay(score: score),

            // Start message
            if (!isGameOver && score == 0)
              const Center(
                child: Text(
                  'Tap to Jump!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 4,
                        offset: Offset(2, 2),
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

  @override
  void dispose() {
    gameTimer?.cancel();
    animationTimer?.cancel();
    super.dispose();
  }
}