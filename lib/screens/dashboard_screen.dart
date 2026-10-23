import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../models/mutation_model.dart';
import '../services/api_service.dart';
import '../theme/bank_theme.dart';
import '../widgets/bank_widgets.dart';
import '../widgets/account_widgets.dart';
import 'auth_screens.dart';
import 'email_panel.dart';

class DashboardScreen extends StatefulWidget {
  final Future<void> Function() onLogout;
  final VoidCallback onSessionExpired;
  final Map<String, dynamic> user;
  const DashboardScreen({
    super.key,
    required this.onLogout,
    required this.onSessionExpired,
    required this.user,
  });
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  AccountModel? profile;
  MutationPage? rows;
  List<MutationModel> recent = [];
  int tab = 0;
  bool loading = true;
  bool refreshing = false;
  bool pageBusy = false;
  bool loggingOut = false;
  String error = '';
  String pageError = '';

  @override
  void initState() {
    super.initState();
    refresh();
  }

  bool expire(Object failure) {
    if (failure is ApiException && failure.status == 401) {
      widget.onSessionExpired();
      return true;
    }
    return false;
  }

  Future<void> refresh() async {
    if (refreshing || pageBusy || loggingOut) return;
    refreshing = true;
    setState(() {
      loading = true;
      error = '';
      pageError = '';
    });
    try {
      final result = await Future.wait<Object>([
        ApiService.profile(),
        ApiService.mutations(1),
      ]);
      if (!mounted) return;
      setState(() {
        profile = result[0] as AccountModel;
        rows = result[1] as MutationPage;
        recent = rows!.items.take(3).toList();
      });
    } catch (failure) {
      if (!mounted || expire(failure)) return;
      setState(() => error = failure.toString());
    } finally {
      refreshing = false;
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> changePage(int value) async {
    if (pageBusy ||
        loading ||
        rows == null ||
        value < 1 ||
        value > rows!.lastPage) {
      return;
    }
    setState(() {
      pageBusy = true;
      pageError = '';
    });
    try {
      final next = await ApiService.mutations(value);
      if (mounted) setState(() => rows = next);
    } catch (failure) {
      if (!mounted || expire(failure)) return;
      setState(() => pageError = failure.toString());
    } finally {
      if (mounted) setState(() => pageBusy = false);
    }
  }

  Future<void> logout() async {
    if (loggingOut) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Kamu perlu login kembali untuk melihat tabungan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || loggingOut) return;
    setState(() => loggingOut = true);
    try {
      await widget.onLogout();
    } finally {
      if (mounted) setState(() => loggingOut = false);
    }
  }

  Future<void> changePassword() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (screen) => PasswordScreen(
          requiredChange: false,
          onChanged: (_) {
            Navigator.of(screen).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password diperbarui. PIN rekening tetap sama.'),
              ),
            );
          },
          onSessionExpired: widget.onSessionExpired,
        ),
      ),
    );
  }

  Widget heading(String title, {Widget? action}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        ?action,
      ],
    ),
  );

  Widget savings(AccountModel account) {
    final saver = account.saver;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tabunganmu', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(account.fullName, style: const TextStyle(color: BankColors.muted)),
        const SizedBox(height: 24),
        BalanceCard(profile: account),
        if (saver != null) ...[
          const SizedBox(height: 20),
          BankPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Saldo tersedia',
                  style: TextStyle(color: BankColors.muted),
                ),
                const SizedBox(height: 8),
                BankAmount(value: saver.availableBalance, size: 24),
                const SizedBox(height: 16),
                Text(
                  'Saldo mengendap ${money(saver.reservedBalance)}',
                  style: const TextStyle(color: BankColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        AccountActions(
          onQr: saver == null ? null : () => showAccountQr(context, saver),
          onMutations: () => setState(() => tab = 1),
          onCopy: saver == null
              ? null
              : () => copyAccountNumber(context, saver.accountNumber),
        ),
        const SizedBox(height: 28),
        heading(
          'Transaksi terbaru',
          action: TextButton(
            onPressed: () => setState(() => tab = 1),
            child: const Text('Lihat mutasi'),
          ),
        ),
        if (recent.isEmpty)
          const BankPanel(child: Text('Belum ada transaksi tabungan.')),
        ...recent.map((row) => MutationTile(row: row)),
      ],
    );
  }

  Widget mutations() {
    final data = rows!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Mutasi rekening',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Setoran dan penarikan dari layanan teller sekolah.',
          style: TextStyle(color: BankColors.muted),
        ),
        const SizedBox(height: 24),
        BankNotice(message: pageError, error: true),
        if (data.items.isEmpty)
          const BankPanel(child: Text('Belum ada transaksi tabungan.')),
        ...data.items.map((row) => MutationTile(row: row)),
        if (pageBusy)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        const SizedBox(height: 20),
        Text(
          'Halaman ${data.currentPage} dari ${data.lastPage}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: BankColors.muted),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: pageBusy || loading || data.currentPage <= 1
                  ? null
                  : () => changePage(data.currentPage - 1),
              child: const Text('Sebelumnya'),
            ),
            OutlinedButton(
              onPressed:
                  pageBusy || loading || data.currentPage >= data.lastPage
                  ? null
                  : () => changePage(data.currentPage + 1),
              child: const Text('Berikutnya'),
            ),
          ],
        ),
      ],
    );
  }

  Widget account(AccountModel account) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Akun siswa', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 24),
      BankPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BankDetailRow(label: 'Nama siswa', value: account.fullName),
            BankDetailRow(label: 'Nomor siswa', value: account.studentNumber),
            BankDetailRow(
              label: 'Tahun kelulusan',
              value: account.graduationYear?.toString() ?? 'Belum dilengkapi',
            ),
            BankDetailRow(
              label: 'Nomor rekening',
              value: account.saver?.accountNumber ?? 'Belum aktif',
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      EmailPanel(
        initialEmail: widget.user['email'] as String?,
        initiallyVerified: widget.user['email_verified_at'] != null,
        onSessionExpired: widget.onSessionExpired,
      ),
      const SizedBox(height: 24),
      BankButton(
        label: 'Ganti password login',
        secondary: true,
        onPressed: loggingOut ? null : changePassword,
      ),
      const SizedBox(height: 12),
      const Text(
        'PIN penarikan ditetapkan saat aktivasi oleh teller. Reset PIN belum tersedia di aplikasi ini.',
        style: TextStyle(color: BankColors.muted, fontSize: 12),
      ),
      const SizedBox(height: 24),
      BankButton(
        label: 'Keluar dari akun',
        secondary: true,
        busy: loggingOut,
        onPressed: logout,
      ),
    ],
  );

  Widget scrollable(Widget child, String key) => RefreshIndicator(
    onRefresh: refresh,
    child: ListView(
      key: PageStorageKey(key),
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        if (error.isNotEmpty)
          BankNotice(
            message:
                '$error\nData terakhir tetap ditampilkan. Muat ulang untuk memperoleh data terbaru.',
            error: true,
          ),
        child,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final current = profile;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: const BankBrand(compact: true),
        actions: [
          IconButton(
            tooltip: 'Muat ulang data',
            onPressed: loading || pageBusy || loggingOut ? null : refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: loggingOut
                  ? null
                  : (value) {
                      FocusScope.of(context).unfocus();
                      setState(() => tab = value);
                    },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet),
                  label: 'Tabungan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: 'Mutasi',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Akun',
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: current == null
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: loading
                          ? const CircularProgressIndicator()
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                BankNotice(message: error, error: true),
                                BankButton(
                                  label: 'Coba lagi',
                                  onPressed: refresh,
                                ),
                                TextButton(
                                  onPressed: logout,
                                  child: const Text('Keluar dari akun'),
                                ),
                              ],
                            ),
                    ),
                  )
                : Column(
                    children: [
                      if (loading) const LinearProgressIndicator(minHeight: 2),
                      Expanded(
                        child: IndexedStack(
                          index: tab,
                          children: [
                            scrollable(savings(current), 'savings'),
                            scrollable(mutations(), 'mutations'),
                            scrollable(account(current), 'account'),
                          ],
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
