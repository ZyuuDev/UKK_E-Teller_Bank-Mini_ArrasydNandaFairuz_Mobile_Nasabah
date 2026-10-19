import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'screens/auth_screens.dart';
import 'screens/dashboard_screen.dart';

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
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff146c4f),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xfff4f7f4),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(44, 48)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(44, 48)),
      ),
    ),
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
    setState(() {
      session = Future.value(user);
    });
  }

  Future<void> logout() async {
    String? warning;
    try {
      await ApiService.logout();
    } catch (_) {
      warning =
          'Token di HP dihapus. Server belum dapat dikonfirmasi karena koneksi gagal.';
    }
    if (!mounted) return;
    setState(() {
      session = Future.value(null);
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
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(snapshot.error.toString()),
                FilledButton(
                  onPressed: () {
                    final nextSession = restore();
                    setState(() {
                      session = nextSession;
                    });
                  },
                  child: const Text('Periksa sesi lagi'),
                ),
              ],
            ),
          ),
        );
      }
      final user = snapshot.data;
      if (user == null) return LoginScreen(onLogin: signedIn);
      if (user['role'] != 'student') {
        return Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: logout,
              child: const Text('Akun bukan siswa. Keluar'),
            ),
          ),
        );
      }
      if (user['must_change_password'] == true) {
        return PasswordScreen(onChanged: signedIn);
      }
      return DashboardScreen(onLogout: logout);
    },
  );
}
