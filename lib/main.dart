import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'screens/auth_screens.dart';
import 'screens/dashboard_screen.dart';
import 'theme/bank_theme.dart';
import 'widgets/bank_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.removeLegacyToken();
  runApp(const BankApp());
}

class BankApp extends StatelessWidget {
  const BankApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Bank Mini SMKN 1 Bantul',
    debugShowCheckedModeBanner: false,
    theme: BankTheme.dark,
    themeMode: ThemeMode.dark,
    home: const SessionGate(),
  );
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});
  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late Future<Map<String, dynamic>?> session;

  @override
  void initState() {
    super.initState();
    session = restore();
  }

  Future<Map<String, dynamic>?> restore() async {
    if (await StorageService.getToken() == null) return null;
    try {
      return await ApiService.me();
    } on ApiException catch (failure) {
      if (failure.status == 401) return null;
      rethrow;
    }
  }

  void signedIn(Map<String, dynamic> user) {
    if (!mounted) return;
    final next = Future<Map<String, dynamic>?>.value(user);
    setState(() {
      session = next;
    });
  }

  void expired() {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    final next = Future<Map<String, dynamic>?>.value(null);
    setState(() {
      session = next;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesi berakhir. Silakan masuk kembali.')),
    );
  }

  Future<void> logout() async {
    String? warning;
    try {
      await ApiService.logout();
    } catch (_) {
      warning =
          'Token di HP dihapus. Logout server belum dapat dikonfirmasi karena koneksi gagal.';
    }
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    final next = Future<Map<String, dynamic>?>.value(null);
    setState(() {
      session = next;
    });
    if (warning != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(warning)));
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
    future: session,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BankNotice(
                        message: snapshot.error.toString(),
                        error: true,
                      ),
                      BankButton(
                        label: 'Periksa sesi lagi',
                        onPressed: () {
                          final next = restore();
                          setState(() {
                            session = next;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      BankButton(
                        label: 'Keluar dari akun',
                        secondary: true,
                        onPressed: logout,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
      final user = snapshot.data;
      if (user == null) return LoginScreen(onLogin: signedIn);
      if (user['role'] != 'student') {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: BankButton(
                label: 'Akun bukan siswa. Keluar',
                onPressed: logout,
              ),
            ),
          ),
        );
      }
      if (user['must_change_password'] == true) {
        return PasswordScreen(onChanged: signedIn, onSessionExpired: expired);
      }
      return DashboardScreen(
        onLogout: logout,
        onSessionExpired: expired,
        user: user,
      );
    },
  );
}