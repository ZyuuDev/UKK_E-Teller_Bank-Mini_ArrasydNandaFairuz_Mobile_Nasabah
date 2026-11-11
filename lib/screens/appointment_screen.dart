import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account_model.dart';
import '../models/appointment_model.dart';
import '../services/api_service.dart';
import '../theme/bank_theme.dart';
import '../widgets/account_widgets.dart';
import '../widgets/bank_widgets.dart';

// Helper pemformat tanggal Indonesia yang 100% aman tanpa dependensi eksternal
String formatIndonesianDate(DateTime date) {
  const dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  const monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];
  try {
    final dayName = dayNames[(date.weekday - 1).clamp(0, 6)];
    final dayNum = date.day.toString().padLeft(2, '0');
    final monthName = monthNames[(date.month - 1).clamp(0, 11)];
    final year = date.year;
    return '$dayName, $dayNum $monthName $year';
  } catch (_) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

String displayScheduledDate(String dateStr) {
  final parsed = DateTime.tryParse(dateStr);
  if (parsed != null) {
    return formatIndonesianDate(parsed);
  }
  return dateStr;
}

// Layar Pengajuan & Riwayat Perjanjian Penarikan Dana Siswa (> Rp 1.000.000, H-1)
class AppointmentScreen extends StatefulWidget {
  final AccountModel profile;
  const AppointmentScreen({super.key, required this.profile});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  bool _submitting = false;
  String _formError = '';

  bool _loadingList = true;
  String _listError = '';
  List<AppointmentModel> _appointments = [];

  WithdrawalLimitsModel? _limits;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Inisialisasi data: Memuat batas limit penarikan & riwayat pengajuan nasabah
  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadLimits(),
      _loadAppointments(),
    ]);
  }

  Future<void> _loadLimits() async {
    try {
      final res = await ApiService.withdrawalLimits();
      if (!mounted) return;
      setState(() => _limits = res);
    } catch (_) {
      // fallback to saver available balance
    }
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _loadingList = true;
      _listError = '';
    });
    try {
      final page = await ApiService.appointments();
      if (!mounted) return;
      setState(() => _appointments = page.items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _listError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingList = false);
    }
  }

  // 1. Pemilihan tanggal penarikan wajib minimal H-1 (mulai besok)
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final maxDate = DateTime(now.year, now.month, now.day + 60);

    DateTime initial = _selectedDate ?? tomorrow;
    if (initial.isBefore(tomorrow)) initial = tomorrow;
    if (initial.isAfter(maxDate)) initial = maxDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: tomorrow,
      lastDate: maxDate,
      helpText: 'PILIH TANGGAL PENARIKAN (H-1)',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // 2. Validasi & Pengiriman formulir perjanjian penarikan ke Admin
  Future<void> _submitAppointment() async {
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(amountText) ?? 0;

    if (amount <= 1000000) {
      setState(() => _formError = 'Perjanjian hanya untuk penarikan di atas Rp1.000.000.');
      return;
    }

    final maxAllowed = _limits?.maxWithdrawable ?? (widget.profile.saver?.availableBalance ?? 0);
    if (amount > maxAllowed) {
      setState(() => _formError = 'Nominal melebihi saldo yang dapat ditarik (${money(maxAllowed)}).');
      return;
    }

    if (_selectedDate == null) {
      setState(() => _formError = 'Pilih tanggal rencana pengambilan uang (minimal H-1).');
      return;
    }

    setState(() {
      _submitting = true;
      _formError = '';
    });

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final newAppt = await ApiService.createAppointment(
        amount: amount,
        scheduledDate: formattedDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (!mounted) return;

      _amountController.clear();
      _notesController.clear();
      setState(() {
        _selectedDate = null;
        _appointments.insert(0, newAppt);
      });

      _tabController.animateTo(1);

      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pengajuan Berhasil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kode Tiket: ${newAppt.appointmentCode}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Nominal: ${money(newAppt.amount)}'),
              Text('Rencana Ambil: ${newAppt.scheduledDate}'),
              const SizedBox(height: 12),
              const Text(
                'Permohonan telah dikirim ke Admin untuk diperiksa dan disetujui sebelum tanggal pencairan.',
                style: TextStyle(fontSize: 13, color: BankColors.muted),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _formError = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // 3. Widget badge status persetujuan (Menunggu, Disetujui, Dicairkan, Ditolak)
  Widget _buildStatusChip(String status, String? reason) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'approved':
        bg = BankColors.success.withValues(alpha: 0.15);
        fg = BankColors.success;
        label = 'Disetujui Admin';
        break;
      case 'completed':
        bg = BankColors.blue.withValues(alpha: 0.15);
        fg = BankColors.blue;
        label = 'Selesai Dicairkan';
        break;
      case 'rejected':
        bg = BankColors.danger.withValues(alpha: 0.15);
        fg = BankColors.danger;
        label = 'Ditolak';
        break;
      default:
        bg = BankColors.warning.withValues(alpha: 0.15);
        fg = BankColors.warning;
        label = 'Menunggu Persetujuan';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  // 4. Tab Formulir: Input nominal penarikan, tanggal H-1, & keperluan
  Widget _buildFormTab() {
    final maxAllowed = _limits?.maxWithdrawable ?? (widget.profile.saver?.availableBalance ?? 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BankPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: BankColors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Ketentuan Penarikan Kas Besar',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '1. Penarikan di atas Rp1.000.000 wajib membuat perjanjian minimal H-1 sebelum pencairan.\n'
                  '2. Setiap pengajuan wajib disetujui oleh Admin Bank Mini.\n'
                  '3. Saldo mengendap minimal Rp10.000 harus tetap tersisa di rekening.',
                  style: TextStyle(color: BankColors.muted, fontSize: 13, height: 1.5),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Saldo dapat ditarik:', style: TextStyle(color: BankColors.muted)),
                    Text(
                      money(maxAllowed),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: BankColors.blue),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          BankNotice(message: _formError, error: true),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nominal Penarikan (Rp)',
              hintText: 'Contoh: 1500000',
              prefixText: 'Rp ',
              helperText: 'Wajib lebih dari Rp1.000.000',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final val in [1500000, 2000000, 3000000, 5000000])
                if (val <= maxAllowed)
                  ActionChip(
                    label: Text(money(val)),
                    onPressed: () {
                      _amountController.text = val.toString();
                    },
                  ),
              if (maxAllowed > 1000000)
                ActionChip(
                  label: const Text('Maksimal'),
                  onPressed: () {
                    _amountController.text = maxAllowed.toString();
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: BankColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BankColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: BankColors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tanggal Rencana Pengambilan',
                          style: TextStyle(color: BankColors.muted, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedDate == null
                              ? 'Pilih tanggal (minimal H-1 besok)'
                              : formatIndonesianDate(_selectedDate!),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.bold,
                            color: _selectedDate == null ? BankColors.muted : BankColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: BankColors.muted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _notesController,
            maxLines: 2,
            maxLength: 255,
            decoration: const InputDecoration(
              labelText: 'Alasan / Catatan Penarikan (Opsional)',
              hintText: 'Contoh: Biaya daftar ulang / keperluan keluarga',
            ),
          ),
          const SizedBox(height: 24),
          BankButton(
            label: 'Ajukan ke Admin',
            busy: _submitting,
            onPressed: _submitting ? null : _submitAppointment,
          ),
        ],
      ),
    );
  }

  // 5. Tab Riwayat: Menampilkan daftar riwayat tiket pengajuan penarikan siswa
  Widget _buildListTab() {
    if (_loadingList) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_listError.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BankNotice(message: _listError, error: true),
              BankButton(
                label: 'Coba Lagi',
                secondary: true,
                onPressed: _loadAppointments,
              ),
            ],
          ),
        ),
      );
    }

    if (_appointments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event_busy, size: 56, color: BankColors.muted),
              const SizedBox(height: 16),
              const Text(
                'Belum Ada Pengajuan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kamu belum pernah membuat perjanjian penarikan kas besar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: BankColors.muted),
              ),
              const SizedBox(height: 24),
              BankButton(
                label: 'Ajukan Perjanjian Sekarang',
                onPressed: () => _tabController.animateTo(0),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _appointments.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _appointments[index];
          return BankPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SelectableText(
                      item.appointmentCode,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: BankColors.blue,
                      ),
                    ),
                    _buildStatusChip(item.status, item.rejectionReason),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Nominal:', style: TextStyle(color: BankColors.muted)),
                    Text(
                      money(item.amount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tgl Pengambilan:', style: TextStyle(color: BankColors.muted)),
                    Text(displayScheduledDate(item.scheduledDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Catatan: "${item.notes}"',
                    style: const TextStyle(fontStyle: FontStyle.italic, color: BankColors.muted, fontSize: 13),
                  ),
                ],
                if (item.status == 'rejected' && item.rejectionReason != null) ...[
                  const Divider(height: 16),
                  Text(
                    'Alasan Ditolak: ${item.rejectionReason}',
                    style: const TextStyle(color: BankColors.danger, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
                if (item.status == 'approved') ...[
                  const Divider(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: BankColors.success),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Disetujui Admin. Tunjukkan kode tiket ini ke Teller saat pencairan di hari H.',
                          style: TextStyle(color: BankColors.success, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perjanjian Tarik Tunai (> 1 Juta)'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: BankColors.blue,
          labelColor: BankColors.text,
          unselectedLabelColor: BankColors.muted,
          tabs: const [
            Tab(text: 'Ajukan Baru'),
            Tab(text: 'Riwayat Pengajuan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFormTab(),
          _buildListTab(),
        ],
      ),
    );
  }
}
