import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/account_model.dart';
import '../models/mutation_model.dart';
import '../theme/bank_theme.dart';
import 'bank_widgets.dart';

String money(int value) => NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
).format(value);

String wib(DateTime value) =>
    '${DateFormat('dd/MM/yyyy HH:mm').format(value.toUtc().add(const Duration(hours: 7)))} WIB';

class BankAmount extends StatelessWidget {
  final int value;
  final double size;
  final Color color;
  final String prefix;
  const BankAmount({
    super.key,
    required this.value,
    this.size = 24,
    this.color = BankColors.text,
    this.prefix = '',
  });
  @override
  Widget build(BuildContext context) {
    final groups = NumberFormat.decimalPattern(
      'id_ID',
    ).format(value).split('.');
    final style = BankTheme.numbers.copyWith(
      fontSize: size,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      color: color,
    );
    return Semantics(
      label: '$prefix${money(value)}',
      excludeSemantics: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('${prefix}Rp ', style: style),
          for (var i = 0; i < groups.length; i++)
            Text(
              '${groups[i]}${i < groups.length - 1 ? '.' : ''}',
              style: style,
            ),
        ],
      ),
    );
  }
}

// 1. Kartu Saldo Tabungan Sekolah (menampilkan saldo total, nomor rekening, & nama pemilik)
class BalanceCard extends StatelessWidget {
  final AccountModel profile;
  const BalanceCard({super.key, required this.profile});
  @override
  Widget build(BuildContext context) {
    final saver = profile.saver;
    if (saver == null) {
      return const BankPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.account_balance_outlined,
              size: 32,
              color: BankColors.blue,
            ),
            SizedBox(height: 20),
            Text(
              'Rekening belum aktif',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 12),
            Text(
              'Datang ke teller sekolah dengan setoran pertama minimal Rp10.000. Nomor rekening dan PIN ditetapkan melalui alur aktivasi teller.',
            ),
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF34235F),
                  Color(0xFF792953),
                  Color(0xFF8F2648),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TABUNGAN SEKOLAH',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Saldo total',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                BankAmount(value: saver.balance, size: 38, color: Colors.white),
                const SizedBox(height: 24),
                SelectableText(
                  saver.accountNumber,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            color: const Color(0xFFECE3EA),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PEMILIK REKENING',
                  style: TextStyle(
                    color: Color(0xFF504653),
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  profile.fullName,
                  style: const TextStyle(
                    color: Color(0xFF161019),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 2. Tombol Aksi Cepat Siswa (QR Rekening, Mutasi, Janji Tarik H-1, Salin Nomor Rekening)
class AccountActions extends StatelessWidget {
  final VoidCallback? onQr;
  final VoidCallback onMutations;
  final VoidCallback? onCopy;
  final VoidCallback? onAppointment;
  const AccountActions({
    super.key,
    this.onQr,
    required this.onMutations,
    this.onCopy,
    this.onAppointment,
  });
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: _CircleAction(
          icon: Icons.qr_code_rounded,
          label: 'QR rekening',
          onTap: onQr,
          primary: true,
        ),
      ),
      Expanded(
        child: _CircleAction(
          icon: Icons.receipt_long_outlined,
          label: 'Mutasi',
          onTap: onMutations,
        ),
      ),
      Expanded(
        child: _CircleAction(
          icon: Icons.event_note_rounded,
          label: 'Janji Tarik',
          onTap: onAppointment,
        ),
      ),
      Expanded(
        child: _CircleAction(
          icon: Icons.copy_rounded,
          label: 'Salin rek',
          onTap: onCopy,
        ),
      ),
    ],
  );
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  const _CircleAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.primary = false,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Column(
      children: [
        IconButton.filled(
          tooltip: label,
          onPressed: onTap,
          style: IconButton.styleFrom(
            minimumSize: const Size(60, 60),
            backgroundColor: primary ? BankColors.text : BankColors.surface,
            foregroundColor: primary ? BankColors.background : BankColors.text,
            disabledBackgroundColor: BankColors.surface,
            disabledForegroundColor: BankColors.muted,
          ),
          icon: Icon(icon, size: 25),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}

// 3. Baris Transaksi Mutasi (Ikon arah dana masuk/keluar, nominal, waktu, & status)
class MutationTile extends StatelessWidget {
  final MutationModel row;
  const MutationTile({super.key, required this.row});
  @override
  Widget build(BuildContext context) {
    final deposit = row.transactionType == 'Deposit';
    final color = deposit ? BankColors.success : BankColors.danger;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: BankColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => showMutationDetails(context, row),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    deposit
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    size: 20,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deposit ? 'Setoran' : 'Penarikan',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        wib(row.occurredAt),
                        style: const TextStyle(
                          color: BankColors.muted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),
                      BankAmount(
                        value: row.amount,
                        prefix: deposit ? '+ ' : '− ',
                        size: 18,
                        color: color,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'TRX-${row.id} · Lihat rincian',
                        style: const TextStyle(
                          color: BankColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: BankColors.muted,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 4. Modal Bottom Sheet Detail Transaksi (Nomor referensi, jenis, nominal, waktu WIB, catatan)
Future<void> showMutationDetails(BuildContext context, MutationModel row) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (sheet) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Rincian transaksi',
                style: Theme.of(sheet).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              BankDetailRow(label: 'Referensi', value: 'TRX-${row.id}'),
              BankDetailRow(
                label: 'Jenis',
                value: row.transactionType == 'Deposit'
                    ? 'Setoran'
                    : 'Penarikan',
              ),
              BankDetailRow(label: 'Nominal', value: money(row.amount)),
              BankDetailRow(label: 'Waktu', value: wib(row.occurredAt)),
              BankDetailRow(
                label: 'Catatan',
                value: row.notes.isEmpty ? 'Tidak ada catatan' : row.notes,
              ),
              const SizedBox(height: 20),
              BankButton(
                label: 'Tutup rincian',
                onPressed: () => Navigator.of(sheet).pop(),
              ),
            ],
          ),
        ),
      ),
    );

Future<void> showAccountQr(
  BuildContext context,
  SaverAccount saver,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 560),
  builder: (sheet) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('QR rekening', style: Theme.of(sheet).textTheme.headlineSmall),
          const SizedBox(height: 12),
          const Text(
            'Tunjukkan kepada teller untuk mengidentifikasi rekening.',
            textAlign: TextAlign.center,
            style: TextStyle(color: BankColors.muted),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: QrImageView(
              data: saver.qrCodeToken,
              size: math.min(240, MediaQuery.sizeOf(sheet).width - 80),
              padding: const EdgeInsets.all(12),
              backgroundColor: Colors.white,
              semanticsLabel: 'QR identitas rekening Bank Mini',
            ),
          ),
          const SizedBox(height: 20),
          SelectableText(
            saver.accountNumber,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const Text(
            'QR hanya menunjukkan identitas rekening. Penarikan tetap memerlukan PIN.',
            textAlign: TextAlign.center,
            style: TextStyle(color: BankColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 24),
          BankButton(
            label: 'Tutup QR',
            onPressed: () => Navigator.of(sheet).pop(),
          ),
        ],
      ),
    ),
  ),
);

Future<void> copyAccountNumber(BuildContext context, String number) async {
  await Clipboard.setData(ClipboardData(text: number));
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Nomor rekening disalin.')));
  }
}
