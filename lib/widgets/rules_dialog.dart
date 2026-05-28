import 'package:flutter/material.dart';
import 'balatro_button.dart';

class RulesDialog extends StatelessWidget {
  const RulesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        decoration: BoxDecoration(
          color: const Color(0xFF101416).withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 4),
        ),
        child: Column(
          children: [
            const Text('CHEAT SHEET', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amberAccent, letterSpacing: 4)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildRule('INCOME', 'Take 1 coin.'),
                  _buildRule('FOREIGN AID', 'Take 2 coins (Can be blocked by Duke).'),
                  _buildRule('COUP', 'Pay 7 coins to force a player to lose an influence. (Must Coup if you have 10+ coins).'),
                  const Divider(color: Colors.white24, height: 32),
                  const Text('CHARACTERS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 2)),
                  const SizedBox(height: 16),
                  _buildChar('DUKE', 'Takes 3 coins (Tax). Blocks Foreign Aid.', Colors.purpleAccent),
                  _buildChar('ASSASSIN', 'Pays 3 coins to assassinate another player.', Colors.grey),
                  _buildChar('CAPTAIN', 'Steals 2 coins from another player. Blocks stealing.', Colors.blueAccent),
                  _buildChar('AMBASSADOR', 'Draws 2 cards and returns 2. Blocks stealing.', Colors.greenAccent),
                  _buildChar('CONTESSA', 'Blocks assassination.', Colors.redAccent),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
    );
  }

  Widget _buildRule(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(desc, style: const TextStyle(fontSize: 14, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildChar(String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.only(top: 4, right: 12),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color, letterSpacing: 1)),
                Text(desc, style: const TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
