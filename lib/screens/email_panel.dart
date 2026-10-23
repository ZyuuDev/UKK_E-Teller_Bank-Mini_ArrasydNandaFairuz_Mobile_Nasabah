import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/bank_theme.dart';
import '../widgets/bank_widgets.dart';

class EmailPanel extends StatefulWidget {
  final String? initialEmail;
  final bool initiallyVerified;
  final VoidCallback? onSessionExpired;
  const EmailPanel({
    super.key,
    this.initialEmail,
    this.initiallyVerified = false,
    this.onSessionExpired,
  });
  @override
  State<EmailPanel> createState() => _EmailPanelState();
}

class _EmailPanelState extends State<EmailPanel> {
  final requestForm = GlobalKey<FormState>();
  final codeForm = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  final code = TextEditingController();
  late String registeredEmail;
  late bool verified;
  bool busy = false;
  bool failed = false;
  String message = '';

  @override
  void initState() {
    super.initState();
    registeredEmail = widget.initialEmail ?? '';
    email.text = registeredEmail;
    verified = widget.initiallyVerified;
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> act(bool verify) async {
    if (busy || !(verify ? codeForm : requestForm).currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    final requestedEmail = email.text.trim();
    setState(() {
      busy = true;
      failed = false;
      message = '';
    });
    try {
      final result = await ApiService.request(
        'POST',
        verify ? '/student/email/verify' : '/student/email/request',
        body: verify
            ? {'code': code.text}
            : {'email': requestedEmail, 'current_password': password.text},
      );
      if (!mounted) return;
      password.clear();
      if (verify) code.clear();
      setState(() {
        message = result['message'] as String;
        if (!verify && requestedEmail != registeredEmail) verified = false;
        if (!verify) registeredEmail = requestedEmail;
      });
      try {
        final user = await ApiService.me();
        if (!mounted) return;
        setState(() {
          registeredEmail = user['email'] as String? ?? '';
          verified = user['email_verified_at'] != null;
        });
      } catch (failure) {
        if (!mounted) return;
        if (failure is ApiException && failure.status == 401) {
          widget.onSessionExpired?.call();
          return;
        }
        setState(() {
          message +=
              ' Status terbaru belum dapat dimuat. Buka ulang aplikasi untuk memeriksanya.';
        });
      }
    } catch (failure) {
      if (!mounted) return;
      if (failure is ApiException &&
          failure.status == 401 &&
          widget.onSessionExpired != null) {
        widget.onSessionExpired!();
        return;
      }
      setState(() {
        failed = true;
        message = failure.toString();
      });
    } finally {
      if (mounted) {
        password.clear();
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => BankPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Email pemulihan', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          registeredEmail.isEmpty
              ? 'Belum ada email terdaftar.'
              : '$registeredEmail\n${verified ? 'Terverifikasi' : 'Belum diverifikasi'}',
          style: TextStyle(
            color: verified ? BankColors.success : BankColors.muted,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Gunakan email milikmu sendiri. Password login saat ini diperlukan untuk meminta kode atau mengganti alamat email.',
          style: TextStyle(color: BankColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 20),
        BankNotice(message: message, error: failed),
        Form(
          key: requestForm,
          child: Column(
            children: [
              TextFormField(
                controller: email,
                enabled: !busy,
                maxLength: 254,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                validator: emailValue,
                decoration: const InputDecoration(
                  labelText: 'Email pemulihan',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              BankPasswordField(
                controller: password,
                label: 'Password login saat ini',
                enabled: !busy,
                validator: requiredValue,
              ),
              const SizedBox(height: 20),
              BankButton(
                label: 'Minta kode verifikasi',
                secondary: true,
                busy: busy,
                onPressed: () => act(false),
              ),
            ],
          ),
        ),
        if (registeredEmail.isNotEmpty && !verified) ...[
          const SizedBox(height: 24),
          Text(
            'Kode untuk $registeredEmail',
            style: const TextStyle(color: BankColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Form(
            key: codeForm,
            child: Column(
              children: [
                BankCodeField(controller: code, enabled: !busy),
                const SizedBox(height: 20),
                BankButton(
                  label: 'Verifikasi email',
                  busy: busy,
                  onPressed: () => act(true),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
