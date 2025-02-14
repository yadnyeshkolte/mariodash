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
  late AnimationController _marioAnimationController;
  late Animation<double> _marioAnimation;

  double marioYPosition = 0;
  double marioXPosition = 50;
  bool isJumping = false;
  bool isGameOver = false;
  int score = 0;
  List<GameObject> obstacles = [];
  Timer? gameTimer;
  double gameSpeed = 5.0;

  @override
  void initState() {
    super.initState();
    setupMarioAnimation();
    startGame();
  }

  void setupMarioAnimation() {
    _marioAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _marioAnimation = Tween<double>(
      begin: 0,
      end: -100,
    ).animate(CurvedAnimation(
      parent: _marioAnimationController,
      curve: Curves.decelerate,
    ));

    _marioAnimation.addListener(() {
      setState(() {
        marioYPosition = _marioAnimation.value;
      });
    });
  }

  void startGame() {
    obstacles.clear();
    score = 0;
    isGameOver = false;
    gameSpeed = 5.0;

    gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      updateGame();
    });
  }

  void jump() {
    if (!isJumping && !isGameOver) {
      isJumping = true;
      _marioAnimationController.forward().then((_) {
        _marioAnimationController.reverse();
        isJumping = false;
      });
    }
  }

  void updateGame() {
    if (isGameOver) return;

    setState(() {
      // Update obstacles
      for (var obstacle in obstacles) {
        obstacle.x -= gameSpeed;
      }

      // Remove off-screen obstacles
      obstacles.removeWhere((obstacle) => obstacle.x < -50);

      // Add new obstacles
      if (obstacles.isEmpty || obstacles.last.x < 200) {
        obstacles.add(GameObject(
          x: MediaQuery.of(context).size.width,
          y: 0,
          width: 30,
          height: 50,
        ));
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

      // Increase game speed
      if (score % 500 == 0) {
        gameSpeed += 0.5;
      }
    });
  }

  bool checkCollision(GameObject obstacle) {
    return (marioXPosition < obstacle.x + obstacle.width &&
        marioXPosition + 50 > obstacle.x &&
        marioYPosition > -30);
  }

  void gameOver() {
    isGameOver = true;
    gameTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameOverOverlay(
        score: score,
        onRestart: () {
          Navigator.of(context).pop();
          startGame();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTapDown: (_) => jump(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.lightBlue, Colors.white],
            ),
          ),
          child: Stack(
            children: [
              // Ground
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 100,
                  color: Colors.brown[200],
                ),
              ),

              // Mario
              Positioned(
                left: marioXPosition,
                bottom: 100 + marioYPosition,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),

              // Obstacles
              ...obstacles.map((obstacle) => Positioned(
                left: obstacle.x,
                bottom: 100,
                child: Container(
                  width: obstacle.width,
                  height: obstacle.height,
                  color: Colors.green,
                ),
              )),

              // Score Display
              ScoreDisplay(score: score),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _marioAnimationController.dispose();
    super.dispose();
  }
}