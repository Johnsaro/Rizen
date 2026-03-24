import 'package:shared_preferences/shared_preferences.dart';

/// Manages guest (local-only) session state.
/// Call [init] at app startup to restore previous guest session.
class GuestSession {
  static const _activeKey = 'rizen_guest_active';
  static const _idKey = 'rizen_guest_id';

  static bool _isActive = false;
  static String _guestId = '';

  static bool get isActive => _isActive;
  static String get userId => _guestId;

  /// Restore guest state from SharedPreferences. Call once in main().
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isActive = prefs.getBool(_activeKey) ?? false;
    _guestId = prefs.getString(_idKey) ?? '';
    if (_isActive && _guestId.isEmpty) {
      // Corrupted state — reset
      _isActive = false;
      await prefs.remove(_activeKey);
    }
  }

  /// Start a new guest session with a synthetic local ID.
  static Future<void> start() async {
    _guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
    _isActive = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_activeKey, true);
    await prefs.setString(_idKey, _guestId);
  }

  /// Clear guest session and all guest data keys from SharedPreferences.
  static Future<void> clear() async {
    _isActive = false;
    _guestId = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeKey);
    await prefs.remove(_idKey);
    // Clear all guest data keys
    final keys = prefs.getKeys().where((k) => k.startsWith('guest_')).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
