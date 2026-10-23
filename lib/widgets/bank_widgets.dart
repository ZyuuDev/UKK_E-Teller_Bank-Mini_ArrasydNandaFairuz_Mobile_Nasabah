import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/bank_theme.dart';

class BankBrand extends StatelessWidget {
  final bool compact;
  const BankBrand({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Image.asset(
          'assets/brand/bank-mini-symbol.png',
          fit: BoxFit.contain,
          semanticLabel: 'Logo Bank Mini',
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bank Mini',
              style: TextStyle(
                fontSize: compact ? 17 : 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Text(
              'SMKN 1 Bantul',
              style: TextStyle(fontSize: 12, color: BankColors.muted),
            ),
          ],
        ),
      ),
    ],
  );
}

class BankPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const BankPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: BankColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: BankColors.border),
    ),
    child: child,
  );
}

class BankNotice extends StatelessWidget {
  final String message;
  final bool error;
  const BankNotice({super.key, required this.message, this.error = false});
  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();
    final color = error ? BankColors.danger : BankColors.blue;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(message, style: TextStyle(color: color, height: 1.5)),
      ),
    );
  }
}

class BankButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool secondary;
  const BankButton({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
    this.secondary = false,
  });
  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (busy) ...[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
        ],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
    return SizedBox(
      width: double.infinity,
      child: secondary
          ? OutlinedButton(onPressed: busy ? null : onPressed, child: content)
          : FilledButton(onPressed: busy ? null : onPressed, child: content),
    );
  }
}

class BankPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final bool newPassword;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  const BankPasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.enabled = true,
    this.newPassword = false,
    this.validator,
    this.onSubmitted,
  });
  @override
  State<BankPasswordField> createState() => _BankPasswordFieldState();
}

class _BankPasswordFieldState extends State<BankPasswordField> {
  bool hidden = true;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    enabled: widget.enabled,
    obscureText: hidden,
    autocorrect: false,
    enableSuggestions: false,
    maxLength: 100,
    autofillHints: [
      widget.newPassword ? AutofillHints.newPassword : AutofillHints.password,
    ],
    textInputAction: widget.onSubmitted == null
        ? TextInputAction.next
        : TextInputAction.done,
    validator: widget.validator,
    onFieldSubmitted: widget.onSubmitted,
    decoration: InputDecoration(
      labelText: widget.label,
      counterText: '',
      suffixIcon: IconButton(
        tooltip: hidden ? 'Tampilkan password' : 'Sembunyikan password',
        onPressed: widget.enabled
            ? () => setState(() => hidden = !hidden)
            : null,
        icon: Icon(
          hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    ),
  );
}

class BankCodeField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  const BankCodeField({
    super.key,
    required this.controller,
    this.enabled = true,
  });
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    enabled: enabled,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    maxLength: 6,
    autofillHints: const [AutofillHints.oneTimeCode],
    validator: (value) => RegExp(r'^\d{6}$').hasMatch(value ?? '')
        ? null
        : 'Masukkan kode enam digit dari email.',
    decoration: const InputDecoration(
      labelText: 'Kode enam digit',
      counterText: '',
    ),
  );
}

class BankAuthFrame extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;
  final bool back;
  final bool busy;
  const BankAuthFrame({
    super.key,
    required this.title,
    required this.description,
    required this.child,
    this.back = false,
    this.busy = false,
  });
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: back
          ? AppBar(
              leading: IconButton(
                tooltip: 'Kembali',
                onPressed: busy ? null : () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            )
          : null,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(24, back ? 12 : 40, 24, 32),
              children: [
                const BankBrand(),
                const SizedBox(height: 40),
                Text(title, style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: const TextStyle(color: BankColors.muted),
                ),
                const SizedBox(height: 32),
                child,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class BankDetailRow extends StatelessWidget {
  final String label;
  final String value;
  const BankDetailRow({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: BankColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

String? requiredValue(String? value) =>
    value == null || value.isEmpty ? 'Kolom ini wajib diisi.' : null;

String? emailValue(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Masukkan email akun.';
  if (text.length > 254 ||
      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
    return 'Format email belum benar.';
  }
  return null;
}

String? newPasswordValue(String? value) => value == null || value.length < 12
    ? 'Password baru minimal 12 karakter.'
    : null;
