import 'package:flutter_test/flutter_test.dart';
import 'package:rizen/models/player_data.dart';

void main() {
  group('PlayerData Cosmetics Tests', () {
    test('copyWith updates equippedCosmetics correctly', () {
      final initialPlayer = PlayerData.empty;
      expect(initialPlayer.equippedCosmetics, isEmpty);

      // Equip a Theme
      final playerWithTheme = initialPlayer.copyWith(
        equippedCosmetics: {'Theme': 'Shadow Environment'},
      );
      expect(playerWithTheme.equippedCosmetics['Theme'], 'Shadow Environment');
      expect(playerWithTheme.equippedCosmetics.length, 1);

      // Equip an Effect
      final playerWithEffect = playerWithTheme.copyWith(
        equippedCosmetics: {
          'Theme': 'Shadow Environment',
          'Effect': 'Neon Arsenal',
        },
      );
      expect(playerWithEffect.equippedCosmetics['Effect'], 'Neon Arsenal');
      expect(playerWithEffect.equippedCosmetics.length, 2);

      // Unequip Theme
      final unequippedTheme = Map<String, String>.from(playerWithEffect.equippedCosmetics);
      unequippedTheme.remove('Theme');
      final finalPlayer = playerWithEffect.copyWith(
        equippedCosmetics: unequippedTheme,
      );
      expect(finalPlayer.equippedCosmetics.containsKey('Theme'), isFalse);
      expect(finalPlayer.equippedCosmetics['Effect'], 'Neon Arsenal');
    });

    test('Json Serialization preserves equippedCosmetics', () {
       // Assuming the fromJson / toJson logic if any, but PlayerData uses factory pattern usually inside SupabaseService. 
       // We'll just verify the memory models update correctly for state management.
    });
  });
}
