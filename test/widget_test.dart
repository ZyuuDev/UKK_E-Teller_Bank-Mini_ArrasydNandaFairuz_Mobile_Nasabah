import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/screens/auth_screens.dart';

void main() {
  testWidgets('Login menampilkan identitas sekolah dan pemulihan akun', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: LoginScreen(onLogin: (_) {})));
    expect(find.text('SMKN 1 Bantul'), findsOneWidget);
    expect(find.text('Lupa password?'), findsOneWidget);
    expect(
      find.text('You have pushed the button this many times:'),
      findsNothing,
    );
  });
}