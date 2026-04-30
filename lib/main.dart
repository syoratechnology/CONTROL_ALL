import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/app_provider.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar formatos de fecha en español
  await initializeDateFormatting('es', null);

  // Solo orientación vertical en Android
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Inicializar notificaciones
  await NotificationService.instance.inicializar();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const ControlGastosApp(),
    ),
  );
}

class ControlGastosApp extends StatelessWidget {
  const ControlGastosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return MaterialApp(
      title: 'Control de Gastos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: provider.themeMode,
      home: const DashboardScreen(),
    );
  }
}
