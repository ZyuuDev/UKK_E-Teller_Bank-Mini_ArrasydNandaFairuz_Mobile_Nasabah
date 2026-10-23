import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile/models/account_model.dart';
import 'package:mobile/models/mutation_model.dart';
import 'package:mobile/screens/auth_screens.dart';
import 'package:mobile/theme/bank_theme.dart';
import 'package:mobile/widgets/account_widgets.dart';

AccountModel fixture({bool active = true, int balance = 25000}) =>
    AccountModel.fromJson({
      'member': {
        'student_number': '000001',
        'full_name': 'Siswa Uji Tampilan',
        'graduation_year': 2027,
      },
      'saver': active
          ? {
              'account_number': 'BMS-2026-UJI',
              'balance': balance,
              'reserved_balance': 10000,
              'available_balance': balance - 10000,
              'qr_code_token': 'token-khusus-widget-test',
            }
          : null,
    });

Widget app(Widget child, {double scale = 1}) => MaterialApp(
  theme: BankTheme.dark,
  builder: (context, content) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: content!,
  ),
  home: child,
);

void main() {
  testWidgets('Login mempertahankan identitas dan menolak form kosong', (
    tester,
  ) async {
    await tester.pumpWidget(app(LoginScreen(onLogin: (_) {})));
    await tester.pumpAndSettle();
    expect(find.text('SMKN 1 Bantul'), findsOneWidget);
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Kolom ini wajib diisi.'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Recovery dibuka dan menolak format email tidak valid', (
    tester,
  ) async {
    await tester.pumpWidget(app(LoginScreen(onLogin: (_) {})));
    await tester.ensureVisible(find.text('Lupa password?'));
    await tester.tap(find.text('Lupa password?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'bukan-email');
    await tester.ensureVisible(find.text('Minta kode'));
    await tester.tap(find.text('Minta kode'));
    await tester.pumpAndSettle();
    expect(find.text('Format email belum benar.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Password baru minimal 12 karakter dan konfirmasi harus sama', (
    tester,
  ) async {
    await tester.pumpWidget(app(PasswordScreen(onChanged: (_) {})));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'password-lama-untuk-uji');
    await tester.enterText(fields.at(1), 'pendek');
    await tester.enterText(fields.at(2), 'berbeda');
    await tester.ensureVisible(find.text('Simpan password'));
    await tester.tap(find.text('Simpan password'));
    await tester.pumpAndSettle();
    expect(find.text('Password baru minimal 12 karakter.'), findsOneWidget);
    expect(find.text('Konfirmasi password belum sama.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rekening belum aktif tidak menampilkan saldo palsu', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        Scaffold(
          body: SingleChildScrollView(
            child: BalanceCard(profile: fixture(active: false)),
          ),
        ),
      ),
    );
    expect(find.text('Rekening belum aktif'), findsOneWidget);
    expect(find.byType(BankAmount), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(430, 740),
    const Size(768, 1024),
    const Size(640, 360),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Layout login dan nominal panjang pada $size skala $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          app(LoginScreen(onLogin: (_) {}), scale: scale),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          app(
            Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: BalanceCard(profile: fixture(balance: 9000000000000)),
                ),
              ),
            ),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(BankAmount), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('QR memakai token model dan modal dapat ditutup', (tester) async {
    final saver = fixture().saver!;
    await tester.pumpWidget(
      app(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAccountQr(context, saver),
              child: const Text('Buka QR'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka QR'));
    await tester.pumpAndSettle();
    final paint =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(QrImageView),
                    matching: find.byWidgetPredicate(
                      (widget) =>
                          widget is CustomPaint && widget.painter is QrPainter,
                    ),
                  ),
                )
                .painter!
            as QrPainter;
    final expected = QrPainter(
      data: saver.qrCodeToken,
      version: QrVersions.auto,
      gapless: true,
    );
    final actualBytes = await tester.runAsync(() => paint.toImageData(160));
    final expectedBytes = await tester.runAsync(
      () => expected.toImageData(160),
    );
    expect(actualBytes, isNotNull);
    expect(expectedBytes, isNotNull);
    expect(
      actualBytes!.buffer.asUint8List(),
      orderedEquals(expectedBytes!.buffer.asUint8List()),
    );
    expect(find.text(saver.accountNumber), findsOneWidget);
    await tester.ensureVisible(find.text('Tutup QR'));
    await tester.tap(find.text('Tutup QR'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rincian mutasi mempertahankan referensi, catatan, dan WIB', (
    tester,
  ) async {
    final row = MutationModel.fromJson({
      'id': 91,
      'transaction_type': 'Deposit',
      'amount': 25000,
      'created_at': '2026-10-21T01:30:00Z',
      'notes': 'Catatan fixture uji',
    });
    await tester.pumpWidget(app(Scaffold(body: MutationTile(row: row))));
    await tester.tap(find.text('Setoran'));
    await tester.pumpAndSettle();
    expect(find.text('TRX-91'), findsOneWidget);
    expect(find.text('Catatan fixture uji'), findsOneWidget);
    expect(wib(row.occurredAt), '21/10/2026 08:30 WIB');
    expect(tester.takeException(), isNull);
  });
}
