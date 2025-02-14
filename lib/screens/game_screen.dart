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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.lightBlue.shade300,
                Colors.lightBlue.shade100,
              ],
              stops: const [0.0, 0.7],
            ),
          ),
          child: Stack(
            children: [
              // Clouds (Parallax Background)
              _buildClouds(),

              // Mountains (Background)
              _buildMountains(),

              // Ground
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildGround(),
              ),

              // Mario Character
              Positioned(
                left: marioXPosition,
                bottom: 100 + marioYPosition,
                child: _buildMario(),
              ),

              // Obstacles
              ...obstacles.map((obstacle) => Positioned(
                left: obstacle.x,
                bottom: 100,
                child: _buildObstacle(obstacle),
              )),

              // Score Display
              ScoreDisplay(score: score),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClouds() {
    return Positioned(
      top: 50,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          3,
              (index) => Container(
            width: 80,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMountains() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: CustomPaint(
        size: const Size(double.infinity, 100),
        painter: MountainPainter(),
      ),
    );
  }

  Widget _buildGround() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.brown.shade400,
            Colors.brown.shade700,
          ],
        ),
        border: Border(
          top: BorderSide(
            color: Colors.brown.shade600,
            width: 3,
          ),
        ),
      ),
      child: CustomPaint(
        size: const Size(double.infinity, 100),
        painter: GroundPatternPainter(),
      ),
    );
  }

  Widget _buildMario() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.red, Color(0xFFCC0000)],
        ),
      ),
    );
  }

  Widget _buildObstacle(GameObject obstacle) {
    return Container(
      width: obstacle.width,
      height: obstacle.height,
      decoration: BoxDecoration(
        color: Colors.green.shade800,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green.shade400,
            Colors.green.shade800,
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Mountains
class MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    // First mountain
    path.lineTo(size.width * 0.3, 0);
    path.lineTo(size.width * 0.6, size.height);

    // Second mountain
    path.lineTo(size.width * 0.8, size.height * 0.3);
    path.lineTo(size.width, size.height);

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter for Ground Pattern
class GroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown.shade300.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < size.width; i += 20) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

}