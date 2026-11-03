import 'package:flutter_test/flutter_test.dart';
import 'package:oxyn/features/subscription/domain/access_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const validCode = String.fromEnvironment('ACCESS_CODE');

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('wrong access code does not unlock', () async {
    final gate = AccessGate();
    expect(await gate.redeemAccessCode('OXYN-0000-0000'), isFalse);
    expect(gate.hasAccess, isFalse);
  });

  test('valid access code unlocks and persists', () async {
    final gate = AccessGate();
    expect(await gate.redeemAccessCode(' ${validCode.toLowerCase()} '), isTrue);
    expect(gate.hasAccess, isTrue);

    final reloaded = AccessGate();
    await reloaded.loadAccessCode();
    expect(reloaded.hasAccessCode, isTrue);
  }, skip: validCode.isEmpty ? 'pass --dart-define=ACCESS_CODE=...' : false);
}
