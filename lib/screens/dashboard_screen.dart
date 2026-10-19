import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/account_model.dart';
import '../models/mutation_model.dart';
import '../services/api_service.dart';
import 'email_panel.dart';

String money(int value) => NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
).format(value);

class DashboardScreen extends StatefulWidget {
  final Future<void> Function() onLogout;
  const DashboardScreen({super.key, required this.onLogout});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<(AccountModel, MutationPage)> data;
  int tab = 0;
  int page = 1;
  @override
  void initState() {
    super.initState();
    data = load();
  }

  Future<(AccountModel, MutationPage)> load() async {
    final profile = await ApiService.profile();
    final mutations = await ApiService.mutations(page);
    return (profile, mutations);
  }

  Future<void> refresh() async {
    final next = load();
    setState(() {
      data = next;
    });
    try {
      await next;
    } catch (_) {
      return;
    }
  }

  void changePage(int value) {
    setState(() {
      page = value;
      data = load();
    });
  }

  Widget savings(AccountModel profile) {
    final saver = profile.saver;
    if (saver == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rekening belum aktif',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12),
              Text(
                'Datang ke teller sekolah dengan setoran pertama minimal Rp10.000 untuk mengaktifkan rekening.',
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: const Color(0xff103f32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dapat ditarik',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  money(saver.availableBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Saldo total ${money(saver.balance)}',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  'Saldo mengendap ${money(saver.reservedBalance)}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text('Tunjukkan QR ini kepada teller'),
                const SizedBox(height: 16),
                Semantics(
                  label: 'QR identitas rekening',
                  child: QrImageView(
                    data: saver.qrCodeToken,
                    size: 210,
                    backgroundColor: Colors.white,
                  ),
                ),
                SelectableText(saver.accountNumber),
                const SizedBox(height: 12),
                const Text(
                  'QR menunjukkan identitas rekening. Penarikan tetap memerlukan PIN.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget mutations(MutationPage rows) => Column(
    children: [
      if (rows.items.isEmpty)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text('Belum ada transaksi tabungan.'),
        ),
      ...rows.items.map(
        (row) => Card(
          child: ListTile(
            isThreeLine: true,
            title: Text(
              row.transactionType == 'Deposit' ? 'Setoran' : 'Penarikan',
            ),
            subtitle: Text(
              '${DateFormat('dd/MM/yyyy HH:mm').format(row.occurredAt.toLocal())}\n${row.notes.isEmpty ? 'Transaksi loket sekolah' : row.notes}',
            ),
            trailing: Text(
              money(row.amount),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: row.transactionType == 'Deposit'
                    ? const Color(0xff146c4f)
                    : const Color(0xff98251c),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton(
            onPressed: page > 1 ? () => changePage(page - 1) : null,
            child: const Text('Sebelumnya'),
          ),
          Text('Halaman ${rows.currentPage} dari ${rows.lastPage}'),
          OutlinedButton(
            onPressed: page < rows.lastPage ? () => changePage(page + 1) : null,
            child: const Text('Berikutnya'),
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Bank Mini'),
      actions: [
        TextButton(onPressed: widget.onLogout, child: const Text('Keluar')),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: tab,
      onDestinationSelected: (value) => setState(() => tab = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          label: 'Tabungan',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          label: 'Mutasi',
        ),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Akun'),
      ],
    ),
    body: FutureBuilder<(AccountModel, MutationPage)>(
      future: data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(snapshot.error.toString()),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: refresh,
                    child: const Text('Coba lagi'),
                  ),
                  TextButton(
                    onPressed: widget.onLogout,
                    child: const Text('Kembali ke login'),
                  ),
                ],
              ),
            ),
          );
        }
        final (profile, rows) = snapshot.data!;
        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                profile.fullName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                'NIS ${profile.studentNumber} · Lulus ${profile.graduationYear ?? 'belum dilengkapi'}',
              ),
              const SizedBox(height: 24),
              if (tab == 0) savings(profile),
              if (tab == 1) mutations(rows),
              if (tab == 2) const EmailPanel(),
            ],
          ),
        );
      },
    ),
  );
}
