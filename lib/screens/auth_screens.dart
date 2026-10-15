import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onLogin;
  const LoginScreen({super.key, required this.onLogin});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
    setState(() {
      busy = true;
      error = '';
    });
    try {
      final user = await ApiService.login(username.text.trim(), password.text);
      if (mounted) widget.onLogin(user);
    } catch (failure) {
      if (mounted) setState(() => error = failure.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Bank Mini',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const Text('SMKN 1 Bantul'),
                const SizedBox(height: 32),
                const Text('Masuk untuk melihat tabunganmu.'),
                const SizedBox(height: 20),
                TextField(
                  controller: username,
                  autofillHints: const [AutofillHints.username],
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(labelText: 'Password'),
                  onSubmitted: (_) {
                    if (!busy) submit();
                  },
                ),
                if (error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      error,
                      style: const TextStyle(color: Color(0xff98251c)),
                    ),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: busy ? null : submit,
                  child: Text(busy ? 'Memeriksa akun...' : 'Masuk'),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RecoveryScreen(),
                          ),
                        ),
                  child: const Text('Lupa password?'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PasswordScreen extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onChanged;
  const PasswordScreen({super.key, required this.onChanged});
  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final current = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  String error = '';
  bool busy = false;
  @override
  void dispose() {
    current.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> submit() async {
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
      if (mounted) widget.onChanged(user);
    } catch (failure) {
      if (mounted) setState(() => error = failure.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Password pribadi')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Ganti password sementara dengan minimal 12 karakter.'),
        const SizedBox(height: 20),
        TextField(
          controller: current,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password saat ini'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password baru'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: confirmation,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Ulangi password baru'),
        ),
        if (error.isNotEmpty)
          Text(error, style: const TextStyle(color: Color(0xff98251c))),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: busy ? null : submit,
          child: const Text('Simpan password'),
        ),
      ],
    ),
  );
}

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});
  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final email = TextEditingController();
  final code = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  bool requested = false;
  bool busy = false;
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
    setState(() => busy = true);
    try {
      final result = await ApiService.request(
        'POST',
        requested ? '/auth/reset-password' : '/auth/forgot-password',
        authenticated: false,
        body: {
          'email': email.text.trim(),
          if (requested) 'code': code.text,
          if (requested) 'password': password.text,
          if (requested) 'password_confirmation': confirmation.text,
        },
      );
      if (!mounted) return;
      if (requested) {
        password.clear();
        confirmation.clear();
        code.clear();
        setState(() {
          requested = false;
          message = result['message'] as String;
        });
      } else {
        setState(() {
          requested = true;
          message = result['message'] as String;
        });
      }
    } catch (failure) {
      if (mounted) setState(() => message = failure.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pulihkan password')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Gunakan email yang sudah diverifikasi. Jika belum, hubungi petugas sekolah.',
        ),
        const SizedBox(height: 20),
        TextField(
          controller: email,
          enabled: !requested,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email akun'),
        ),
        if (requested) ...[
          const SizedBox(height: 16),
          TextField(
            controller: code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofillHints: const [AutofillHints.oneTimeCode],
            decoration: const InputDecoration(labelText: 'Kode enam digit'),
          ),
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password baru'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: confirmation,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Ulangi password baru',
            ),
          ),
        ],
        if (message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(message),
          ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: busy ? null : submit,
          child: Text(
            busy
                ? 'Memproses...'
                : requested
                ? 'Simpan password'
                : 'Minta kode',
          ),
        ),
        if (requested)
          TextButton(
            onPressed: busy ? null : () => setState(() => requested = false),
            child: const Text('Ubah email atau minta ulang'),
          ),
      ],
    ),
  );
}