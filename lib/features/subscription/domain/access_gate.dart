import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth for the hard paywall. The router listens to this:
/// without an active Oxyn Plus entitlement every app route redirects to
/// `/subscribe`.
class AccessGate extends ChangeNotifier {
  static const _accessCodeKey = 'access_code_granted';

  /// SHA-256 of the store review access code. The code itself is shared only
  /// in the store review instructions; rotate it by replacing this hash.
  static const _accessCodeHash =
      '389ae03975a667c170c38b9a1d88d1385bc41916c4c9954c356f9f00205c6fda';

  bool _hasEntitlement = false;
  bool _storeUnavailablePass = false;
  bool _accessCode = false;

  bool get hasEntitlement => _hasEntitlement;

  /// Full Plus access granted by a valid access code.
  bool get hasAccessCode => _accessCode;

  /// True when the user may use the app: an active entitlement, an access
  /// code, or a session-only pass granted because the store had nothing to
  /// sell.
  bool get hasAccess => _hasEntitlement || _accessCode || _storeUnavailablePass;

  void update(bool hasEntitlement) {
    if (_hasEntitlement == hasEntitlement) return;
    final before = hasAccess;
    _hasEntitlement = hasEntitlement;
    if (hasAccess != before) notifyListeners();
  }

  /// Not persisted: the paywall is shown again on the next launch.
  void grantStoreUnavailablePass() {
    if (_storeUnavailablePass) return;
    final before = hasAccess;
    _storeUnavailablePass = true;
    if (hasAccess != before) notifyListeners();
  }

  Future<void> loadAccessCode() async {
    final prefs = await SharedPreferences.getInstance();
    _accessCode = prefs.getString(_accessCodeKey) == _accessCodeHash;
  }

  /// Returns false when the code is wrong.
  Future<bool> redeemAccessCode(String code) async {
    final normalized = code.trim().toUpperCase().replaceAll(' ', '');
    final hash = sha256.convert(utf8.encode(normalized)).toString();
    if (hash != _accessCodeHash) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessCodeKey, hash);
    final before = hasAccess;
    _accessCode = true;
    if (hasAccess != before) notifyListeners();
    return true;
  }
}

final accessGate = AccessGate();
