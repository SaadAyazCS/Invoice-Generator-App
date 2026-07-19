import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'services/database_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InvoiceApp());
}

class InvoiceApp extends StatefulWidget {
  const InvoiceApp({super.key});

  @override
  State<InvoiceApp> createState() => _InvoiceAppState();
}

class _InvoiceAppState extends State<InvoiceApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final settings = await DatabaseService().getAppSettings();
    setState(() {
      _isDarkMode = settings.isDarkMode;
    });
  }

  void _toggleTheme() async {
    final settings = await DatabaseService().getAppSettings();
    setState(() {
      _isDarkMode = settings.isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invoice Generator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: DashboardScreen(onThemeChanged: _toggleTheme),
    );
  }
}
