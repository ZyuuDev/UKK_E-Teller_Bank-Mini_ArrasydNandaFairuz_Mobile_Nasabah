import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/bank_theme.dart';
import '../widgets/bank_widgets.dart';

class LoginScreen extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onLogin;
  const LoginScreen({super.key, required this.onLogin});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  final username = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  String error = '';

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = '';
    });
    try {
      final user = await ApiService.login(username.text.trim(), password.text);
      if (mounted) {
        password.clear();
        widget.onLogin(user);
      }
    } catch (failure) {
      if (mounted) setState(() => error = failure.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => BankAuthFrame(
    title: 'Masuk ke Bank Mini.',
    description: 'Lihat saldo, mutasi, dan QR rekening sekolahmu.',
    busy: busy,
    child: AutofillGroup(
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BankNotice(message: error, error: true),
            TextFormField(
              controller: username,
              enabled: !busy,
              maxLength: 50,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              validator: (value) => requiredValue(value?.trim()),
              decoration: const InputDecoration(
                labelText: 'Username siswa',
                counterText: '',
              ),
            ),
            const SizedBox(height: 20),
            BankPasswordField(
              controller: password,
              label: 'Password',
              enabled: !busy,
              validator: requiredValue,
              onSubmitted: (_) => submit(),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: busy
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const RecoveryScreen(),
                        ),
                      ),
                child: const Text('Lupa password?'),
              ),
            ),
            const SizedBox(height: 16),
            BankButton(
              label: busy ? 'Memeriksa akun…' : 'Masuk',
              busy: busy,
              onPressed: submit,
            ),
            const SizedBox(height: 24),
            const Text(
              'Gunakan akun siswa dari petugas Bank Mini. Setoran dan penarikan dilayani melalui teller sekolah.',
              style: TextStyle(color: BankColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}

class PasswordScreen extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onChanged;
  final bool requiredChange;
  final VoidCallback? onSessionExpired;
  const PasswordScreen({
    super.key,
    required this.onChanged,
    this.requiredChange = true,
    this.onSessionExpired,
  });
  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final form = GlobalKey<FormState>();
  final current = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  bool busy = false;
  String error = '';

  @override
  void dispose() {
    current.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = '';
    });
    try {
      final user = await ApiService.changePassword(
        current.text,
        password.text,
        confirmation.text,
      );
      if (mounted) {
        current.clear();
        password.clear();
        confirmation.clear();
        widget.onChanged(user);
      }
    } catch (failure) {
      if (!mounted) return;
      if (failure is ApiException &&
          failure.status == 401 &&
          widget.onSessionExpired != null) {
        widget.onSessionExpired!();
        return;
      }
      setState(() => error = failure.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => BankAuthFrame(
    title: widget.requiredChange ? 'Buat password pribadi.' : 'Ganti password.',
    description: widget.requiredChange
        ? 'Ganti password sementara sebelum membuka rekeningmu. Gunakan minimal 12 karakter.'
        : 'Masukkan password saat ini dan password baru minimal 12 karakter. PIN rekening tidak ikut berubah.',
    back: !widget.requiredChange,
    busy: busy,
    child: Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BankNotice(message: error, error: true),
          BankPasswordField(
            controller: current,
            label: 'Password saat ini',
            enabled: !busy,
            validator: requiredValue,
          ),
          const SizedBox(height: 20),
          BankPasswordField(
            controller: password,
            label: 'Password baru',
            enabled: !busy,
            newPassword: true,
            validator: (value) =>
                newPasswordValue(value) ??
                (value == current.text
                    ? 'Gunakan password yang berbeda.'
                    : null),
          ),
          const SizedBox(height: 20),
          BankPasswordField(
            controller: confirmation,
            label: 'Ulangi password baru',
            enabled: !busy,
            newPassword: true,
            validator: (value) => value == password.text && value!.isNotEmpty
                ? null
                : 'Konfirmasi password belum sama.',
            onSubmitted: (_) => submit(),
          ),
          const SizedBox(height: 28),
          BankButton(label: 'Simpan password', busy: busy, onPressed: submit),
        ],
      ),
    ),
  );
}

enum _RecoveryStep { request, reset, done }

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});
  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final code = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  _RecoveryStep step = _RecoveryStep.request;
  bool busy = false;
  bool failed = false;
  String message = '';

  @override
  void dispose() {
    email.dispose();
    code.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final resetting = step == _RecoveryStep.reset;
    setState(() {
      busy = true;
      failed = false;
      message = '';
    });
    try {
      final result = await ApiService.request(
        'POST',
        resetting ? '/auth/reset-password' : '/auth/forgot-password',
        authenticated: false,
        body: {
          'email': email.text.trim(),
          if (resetting) 'code': code.text,
          if (resetting) 'password': password.text,
          if (resetting) 'password_confirmation': confirmation.text,
        },
      );
      if (!mounted) return;
      setState(() {
        message = result['message'] as String;
        step = resetting ? _RecoveryStep.done : _RecoveryStep.reset;
      });
      if (resetting) {
        code.clear();
        password.clear();
        confirmation.clear();
      }
    } catch (failure) {
      if (mounted) {
        setState(() {
          failed = true;
          message = failure.toString();
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void changeEmail() {
    if (busy) return;
    code.clear();
    password.clear();
    confirmation.clear();
    setState(() {
      step = _RecoveryStep.request;
      message = '';
      failed = false;
    });
  }

  @override
  Widget build(BuildContext context) => BankAuthFrame(
    title: step == _RecoveryStep.done
        ? 'Password diperbarui.'
        : 'Pulihkan akses.',
    description: step == _RecoveryStep.done
        ? 'Masuk kembali menggunakan password baru. PIN rekeningmu tetap sama.'
        : 'Gunakan email siswa yang sudah diverifikasi. Jika belum, hubungi petugas sekolah.',
    back: true,
    busy: busy,
    child: step == _RecoveryStep.done
        ? Column(
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
                  enabled: !busy && step == _RecoveryStep.request,
                  maxLength: 254,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  validator: emailValue,
                  decoration: const InputDecoration(
                    labelText: 'Email akun',
                    counterText: '',
                  ),
                ),
                if (step == _RecoveryStep.reset) ...[
                  const SizedBox(height: 20),
                  BankCodeField(controller: code, enabled: !busy),
                  const SizedBox(height: 20),
                  BankPasswordField(
                    controller: password,
                    label: 'Password baru',
                    enabled: !busy,
                    newPassword: true,
                    validator: newPasswordValue,
                  ),
                  const SizedBox(height: 20),
                  BankPasswordField(
                    controller: confirmation,
                    label: 'Ulangi password baru',
                    enabled: !busy,
                    newPassword: true,
                    validator: (value) =>
                        value == password.text && value!.isNotEmpty
                        ? null
                        : 'Konfirmasi password belum sama.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Kode berlaku 10 menit dan hanya dapat dipakai sekali. Periksa inbox dan spam. Permintaan ulang dibatasi server.',
                    style: TextStyle(color: BankColors.muted, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 28),
                BankButton(
                  label: step == _RecoveryStep.reset
                      ? 'Simpan password'
                      : 'Minta kode',
                  busy: busy,
                  onPressed: submit,
                ),
                if (step == _RecoveryStep.reset)
                  TextButton(
                    onPressed: busy ? null : changeEmail,
                    child: const Text('Ubah email atau minta ulang'),
                  ),
              ],
            ),
          ),
  );
}
