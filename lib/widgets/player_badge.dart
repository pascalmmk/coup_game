import 'package:flutter/material.dart';
import '../models/models.dart';

class PlayerBadge extends StatelessWidget {
  final Player player;
  final bool isActive;

  const PlayerBadge({
    super.key,
    required this.player,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.redAccent.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? Colors.redAccent : Colors.white24,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive ? [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.3),
            blurRadius: 12,
          )
        ] : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: player.isAlive ? Colors.white12 : Colors.black54,
            child: Icon(
              player.isAlive ? Icons.person : Icons.sentiment_very_dissatisfied,
              color: player.isAlive ? Colors.white : Colors.white30,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                player.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: player.isAlive ? Colors.white : Colors.white30,
                  decoration: player.isAlive ? null : TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text('${player.coins}', style: const TextStyle(color: Colors.white)),
                  const SizedBox(width: 12),
                  const Icon(Icons.style, color: Colors.blueGrey, size: 14),
                  const SizedBox(width: 4),
                  Text('${player.influenceCount}', style: const TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
