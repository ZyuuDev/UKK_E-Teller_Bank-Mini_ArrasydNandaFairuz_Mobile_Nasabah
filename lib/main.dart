import 'dart:async';
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

class _SessionGateState extends State<SessionGate>
    with WidgetsBindingObserver {
  late Future<Map<String, dynamic>?> session;
  Timer? _idleTimer;
  DateTime? _pausedAt;
  DateTime _lastPing = DateTime.now();
  Map<String, dynamic>? _currentUser;

  static const int defaultIdleSeconds = 300;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    session = restore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopIdleWatcher();
    super.dispose();
  }

  int get _idleTimeoutSeconds {
    final configured = _currentUser?['idle_timeout_seconds'];
    if (configured is int && configured > 0) return configured;
    return defaultIdleSeconds;
  }

  void _startIdleWatcher() {
    _idleTimer?.cancel();
    _idleTimer = Timer(Duration(seconds: _idleTimeoutSeconds), _onIdleTimeout);
  }

  void _stopIdleWatcher() {
    _idleTimer?.cancel();
    _idleTimer = null;
    _pausedAt = null;
  }

  void _recordActivity() {
    if (_currentUser == null) return;
    _startIdleWatcher();
    final now = DateTime.now();
    if (now.difference(_lastPing).inSeconds >= 45) {
      _lastPing = now;
      ApiService.me().catchError((_) => <String, dynamic>{});
    }
  }

  void _onIdleTimeout() {
    if (_currentUser == null || !mounted) return;
    expired('Sesi Anda telah berakhir karena tidak ada aktivitas.');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_currentUser == null) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _pausedAt = DateTime.now();
      _idleTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      final paused = _pausedAt;
      _pausedAt = null;
      if (paused != null &&
          DateTime.now().difference(paused).inSeconds >= _idleTimeoutSeconds) {
        _onIdleTimeout();
      } else {
        _startIdleWatcher();
      }
    }
  }

  Future<Map<String, dynamic>?> restore() async {
    if (await StorageService.getToken() == null) return null;
    try {
      final user = await ApiService.me();
      _currentUser = user;
      _startIdleWatcher();
      return user;
    } on ApiException catch (failure) {
      if (failure.status == 401) return null;
      rethrow;
    }
  }

  void signedIn(Map<String, dynamic> user) {
    if (!mounted) return;
    _currentUser = user;
    _startIdleWatcher();
    final next = Future<Map<String, dynamic>?>.value(user);
    setState(() {
      session = next;
    });
  }

  void expired([String? message]) {
    _stopIdleWatcher();
    _currentUser = null;
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    final next = Future<Map<String, dynamic>?>.value(null);
    setState(() {
      session = next;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Sesi berakhir. Silakan masuk kembali.'),
      ),
    );
  }

  Future<void> logout() async {
    _stopIdleWatcher();
    _currentUser = null;
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
      if (user == null) {
        _currentUser = null;
        _stopIdleWatcher();
        return LoginScreen(onLogin: signedIn);
      }
      _currentUser = user;
      if (_idleTimer == null) {
        _startIdleWatcher();
      }
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
      Widget content;
      if (user['must_change_password'] == true) {
        content = PasswordScreen(
          onChanged: signedIn,
          onSessionExpired: () => expired(),
        );
      } else {
        content = DashboardScreen(
          onLogout: logout,
          onSessionExpired: () => expired(),
          user: user,
        );
      }
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _recordActivity(),
        onPointerMove: (_) => _recordActivity(),
        child: content,
      );
    },
  );
}