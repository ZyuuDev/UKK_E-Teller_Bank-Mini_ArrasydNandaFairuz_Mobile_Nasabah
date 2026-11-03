import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/bank_theme.dart';
import '../widgets/bank_widgets.dart';

enum _PinStep { request, reset, done }

class PinRecoveryScreen extends StatefulWidget {
  const PinRecoveryScreen({super.key});

  @override
  State<PinRecoveryScreen> createState() => _PinRecoveryScreenState();
}

class _PinRecoveryScreenState extends State<PinRecoveryScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final code = TextEditingController();
  final loginPassword = TextEditingController();
  final pin = TextEditingController();
  final confirmation = TextEditingController();
  _PinStep step = _PinStep.request;
  bool busy = false;
  bool failed = false;
  String message = '';

  @override
  void dispose() {
    email.dispose();
    code.dispose();
    loginPassword.dispose();
    pin.dispose();
    confirmation.dispose();
    super.dispose();
  }

  void clearSecrets() {
    code.clear();
    loginPassword.clear();
    pin.clear();
    confirmation.clear();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final resetting = step == _PinStep.reset;
    setState(() {
      busy = true;
      failed = false;
      message = '';
    });
    try {
      final result = await ApiService.request(
        'POST',
        resetting ? '/auth/reset-pin' : '/auth/forgot-pin',
        authenticated: false,
        body: {
          'email': email.text.trim(),
          if (resetting) 'code': code.text,
          if (resetting) 'login_password': loginPassword.text,
          if (resetting) 'pin': pin.text,
          if (resetting) 'pin_confirmation': confirmation.text,
        },
      );
      if (!mounted) return;
      setState(() {
        message = result['message']?.toString() ?? 'Permintaan diproses.';
        step = resetting ? _PinStep.done : _PinStep.reset;
      });
      if (resetting) clearSecrets();
    } catch (failure) {
      if (mounted) {
        setState(() {
          failed = true;
          message = failure.toString();
        });
        if (resetting) {
          loginPassword.clear();
          pin.clear();
          confirmation.clear();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  void changeEmail() {
    if (busy) return;
    clearSecrets();
    setState(() {
      step = _PinStep.request;
      message = '';
      failed = false;
    });
  }

  Widget pinField({
    required TextEditingController controller,
    required String label,
    bool confirm = false,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !busy,
      obscureText: true,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 6,
      autocorrect: false,
      enableSuggestions: false,
      validator: (value) {
        if (!RegExp(r'^\d{6}$').hasMatch(value ?? '')) {
          return 'PIN harus tepat enam digit angka.';
        }
        if (confirm && value != pin.text) return 'Pengulangan PIN belum sama.';
        return null;
      },
      decoration: InputDecoration(labelText: label, counterText: ''),
    );
  }

  @override
  Widget build(BuildContext context) => BankAuthFrame(
    title: step == _PinStep.done ? 'PIN diperbarui.' : 'Pulihkan PIN rekening.',
    description: step == _PinStep.done
        ? 'Password login tetap sama. Sesi lama diakhiri; masuk kembali menggunakan password loginmu.'
        : 'Gunakan email siswa terverifikasi dan password login yang masih kamu ingat. Rekening harus sudah terbentuk dan aksesnya aktif.',
    back: true,
    busy: busy,
    child: step == _PinStep.done
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BankNotice(message: message),
              BankButton(
                label: 'Kembali ke login',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          )
        : Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BankNotice(message: message, error: failed),
                TextFormField(
                  controller: email,
                  enabled: !busy && step == _PinStep.request,
                  maxLength: 254,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  enableSuggestions: false,
                  validator: emailValue,
                  decoration: const InputDecoration(
                    labelText: 'Email siswa terverifikasi',
                    counterText: '',
                  ),
                ),
                if (step == _PinStep.reset) ...[
                  const SizedBox(height: 20),
                  BankCodeField(controller: code, enabled: !busy),
                  const SizedBox(height: 20),
                  BankPasswordField(
                    controller: loginPassword,
                    label: 'Password login saat ini',
                    enabled: !busy,
                    validator: requiredValue,
                  ),
                  const SizedBox(height: 20),
                  pinField(controller: pin, label: 'PIN baru enam digit'),
                  const SizedBox(height: 20),
                  pinField(
                    controller: confirmation,
                    label: 'Ulangi PIN baru',
                    confirm: true,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Kode berlaku 10 menit, sekali pakai, maksimal lima percobaan. Masukkan PIN sendiri; petugas tidak perlu mengetahuinya.',
                    style: TextStyle(color: BankColors.muted, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 28),
                BankButton(
                  label: step == _PinStep.reset
                      ? 'Simpan PIN baru'
                      : 'Minta kode PIN',
                  busy: busy,
                  onPressed: submit,
                ),
                if (step == _PinStep.reset)
                  TextButton(
                    onPressed: busy ? null : changeEmail,
                    child: const Text('Ubah email atau minta ulang'),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Jika password login juga lupa, kembali ke login dan pulihkan password lebih dahulu. PIN tidak dapat dibuat sebelum setoran pertama teller.',
                  style: TextStyle(color: BankColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
  );
}
