import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EmailPanel extends StatefulWidget {
  const EmailPanel({super.key});
  @override
  State<EmailPanel> createState() => _EmailPanelState();
}

class _EmailPanelState extends State<EmailPanel> {
  final email = TextEditingController();
  final password = TextEditingController();
  final code = TextEditingController();
  String message = '';
  bool busy = false;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> act(bool verify) async {
    setState(() => busy = true);
    try {
      final result = await ApiService.request(
        'POST',
        verify ? '/student/email/verify' : '/student/email/request',
        body: verify
            ? {'code': code.text}
            : {'email': email.text.trim(), 'current_password': password.text},
      );
      if (mounted) setState(() => message = result['message'] as String);
    } catch (failure) {
      if (mounted) setState(() => message = failure.toString());
    } finally {
      if (mounted) {
        password.clear();
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Email pemulihan', style: Theme.of(context).textTheme.titleLarge),
      const Text(
        'Daftarkan email milikmu sendiri, lalu masukkan kode yang diterima. Email belum dapat memulihkan akun sebelum diverifikasi.',
      ),
      const SizedBox(height: 20),
      TextField(
        controller: email,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(labelText: 'Email'),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: password,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Password login saat ini'),
      ),
      const SizedBox(height: 16),
      OutlinedButton(
        onPressed: busy ? null : () => act(false),
        child: const Text('Minta kode verifikasi'),
      ),
      TextField(
        controller: code,
        keyboardType: TextInputType.number,
        maxLength: 6,
        autofillHints: const [AutofillHints.oneTimeCode],
        decoration: const InputDecoration(labelText: 'Kode dari email'),
      ),
      FilledButton(
        onPressed: busy ? null : () => act(true),
        child: const Text('Verifikasi email'),
      ),
      if (message.isNotEmpty)
        Padding(padding: const EdgeInsets.only(top: 16), child: Text(message)),
    ],
  );
}