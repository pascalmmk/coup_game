import 'package:flutter/material.dart';
import '../models/models.dart';

class InfluenceCardWidget extends StatelessWidget {
  final InfluenceCard card;
  final bool isFaceDown;
  final double width;
  final double height;
  final double angle;
  final VoidCallback? onTap;

  const InfluenceCardWidget({
    super.key,
    required this.card,
    this.isFaceDown = false,
    this.width = 110,
    this.height = 160,
    this.angle = 0.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool showBack = isFaceDown && !card.isRevealed;
    final imagePath = 'assets/images/${card.type.name}.png';
    
    return GestureDetector(
      onTap: onTap,
      child: Transform.rotate(
        angle: angle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: showBack ? const Color(0xFF2E7D32) : Colors.black,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 10,
                offset: const Offset(4, 6),
              )
            ],
            border: Border.all(
              color: card.isRevealed ? Colors.redAccent : Colors.white,
              width: 4, // Chunky border
            )
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: showBack
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset('assets/images/table.png', fit: BoxFit.cover),
                      const Center(child: Icon(Icons.casino, color: Colors.white54, size: 60)),
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(imagePath, fit: BoxFit.cover),
                      // Inner shadow vignette
                      Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.0,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                          )
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 0,
                        right: 0,
                        child: Text(
                          card.type.name.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            shadows: [Shadow(color: Colors.black, offset: Offset(2, 2))]
                          ),
                        ),
                      ),
                      if (card.isRevealed)
                        Container(
                          color: Colors.black54,
                          child: Center(
                            child: Transform.rotate(
                              angle: -0.2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Text(
                                  'REVEALED', 
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
