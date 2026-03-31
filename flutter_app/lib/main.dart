import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'providers/theme_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const NGOEducationApp());
}


class NGOEducationApp extends StatefulWidget {
  const NGOEducationApp({super.key});

  @override
  State<NGOEducationApp> createState() => _NGOEducationAppState();
}

class _NGOEducationAppState extends State<NGOEducationApp> {
  final _authProvider = AppAuthProvider();
  final _dataProvider = DataProvider();
  final _themeProvider = ThemeProvider();

  @override
  void initState() {
    super.initState();
    // Auto-init DataProvider when auth state changes (e.g. session restore)
    _authProvider.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (_authProvider.isLoggedIn && _authProvider.user != null) {
      final zone = _authProvider.user?['zone'];
      // Only init once we have a real zone (or admin role which doesn't need one)
      if ((zone != null && zone.isNotEmpty) || _authProvider.role == 'admin') {
        _dataProvider.init(
          _authProvider.uid ?? '',
          _authProvider.role ?? 'teacher',
          zone,
          _authProvider.user?['centre'],
        );
      }
    } else if (!_authProvider.isLoggedIn) {
      _dataProvider.reset();
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    _authProvider.dispose();
    _dataProvider.dispose();
    _themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _dataProvider),
        ChangeNotifierProvider.value(value: _themeProvider),
      ],
      child: Consumer2<AppAuthProvider, ThemeProvider>(
        builder: (context, auth, theme, _) {
          final router = createRouter(auth);
          return MaterialApp.router(
            title: 'NGO Education Platform',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: theme.themeMode,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
