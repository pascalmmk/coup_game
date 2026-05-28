import 'package:flutter/material.dart';
import '../models/models.dart';
import 'balatro_button.dart';

class ActionPanel extends StatelessWidget {
  final Player activePlayer;
  final Function(ActionType) onActionSelected;

  const ActionPanel({
    super.key,
    required this.activePlayer,
    required this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final mustCoup = activePlayer.coins >= 10;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade800, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(4, 4),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.shade700,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.lightBlueAccent, width: 2),
            ),
            child: const Text(
              'ACTIONS',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: ActionType.values.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final type = ActionType.values[index];
                final bool canAfford = _canAfford(type);
                final bool disabled = (mustCoup && type != ActionType.coup) || !canAfford;

                return BalatroButton(
                  onPressed: disabled ? null : () => onActionSelected(type),
                  color: _getActionColor(type),
                  height: 60,
                  child: Row(
                    children: [
                      Icon(_getActionIcon(type), size: 28, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          type.name.toUpperCase(),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      if (type == ActionType.coup)
                         const Text('-\$7', style: TextStyle(fontSize: 20, color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                      if (type == ActionType.assassinate)
                         const Text('-\$3', style: TextStyle(fontSize: 20, color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _canAfford(ActionType type) {
    if (type == ActionType.assassinate) return activePlayer.coins >= 3;
    if (type == ActionType.coup) return activePlayer.coins >= 7;
    return true;
  }

  IconData _getActionIcon(ActionType type) {
    switch (type) {
      case ActionType.income: return Icons.attach_money;
      case ActionType.foreignAid: return Icons.public;
      case ActionType.coup: return Icons.gavel;
      case ActionType.tax: return Icons.account_balance;
      case ActionType.assassinate: return Icons.colorize;
      case ActionType.steal: return Icons.front_hand;
      case ActionType.exchange: return Icons.swap_horiz;
    }
  }

  Color _getActionColor(ActionType type) {
    switch (type) {
      case ActionType.income:
      case ActionType.foreignAid:
      case ActionType.coup:
        return Colors.blueGrey[700]!;
      case ActionType.tax: return const Color(0xFF6A1B9A);
      case ActionType.assassinate: return const Color(0xFFC62828);
      case ActionType.steal: return const Color(0xFF1565C0);
      case ActionType.exchange: return const Color(0xFF2E7D32);
    }
  }
}
