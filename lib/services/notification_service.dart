import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> inicializar() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Manejar click en notificación si es necesario
      },
    );
  }

  /// Programa una notificación mensual para un gasto fijo
  Future<void> programarRecordatorioMensual({
    required int id,
    required String titulo,
    required String cuerpo,
    required int diaMes,
    int hora = 9,
    int minuto = 0,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      titulo,
      cuerpo,
      _siguienteInstanciaDiaMes(diaMes, hora, minuto),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'recordatorios_gastos',
          'Recordatorios de Gastos',
          channelDescription: 'Notificaciones para pagos de suscripciones y préstamos',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime, // Se repite mensualmente
    );
  }

  /// Programa una notificación única para una fecha específica
  Future<void> programarNotificacionUnica({
    required int id,
    required String titulo,
    required String cuerpo,
    required DateTime fecha,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      titulo,
      cuerpo,
      tz.TZDateTime.from(fecha, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'recordatorios_unicos',
          'Recordatorios Únicos',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelarNotificacion(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  tz.TZDateTime _siguienteInstanciaDiaMes(int dia, int hora, int minuto) {
    final tz.TZDateTime ahora = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, ahora.year, ahora.month, dia, hora, minuto);
    
    if (scheduledDate.isBefore(ahora)) {
      scheduledDate = tz.TZDateTime(tz.local, ahora.year, ahora.month + 1, dia, hora, minuto);
    }
    return scheduledDate;
  }
}
