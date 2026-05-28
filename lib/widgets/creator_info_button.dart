import 'package:flutter/material.dart';
import 'balatro_button.dart';

class CreatorInfoButton extends StatelessWidget {
  const CreatorInfoButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: const Color(0xFF101416).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24, width: 4),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('ABOUT',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.amberAccent,
                          letterSpacing: 4)),
                  const SizedBox(height: 16),
                  const Text(
                      'Game created by Mustafa Alhasson\n\nThanks for playing!\n\nGitHub: @pascalmmk',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16, color: Colors.white70)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 200,
                    child: BalatroButton(
                      onPressed: () => Navigator.of(context).pop(),
                      color: const Color(0xFF1E88E5),
                      child: const Text('CLOSE'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      icon: const Icon(Icons.info_outline, color: Colors.white54),
      tooltip: 'Creator Info',
    );
  }
}
