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

    // Solicitar permisos de notificaciones para Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
        
    // Solicitar permisos de alarmas exactas (Android 14+)
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
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
    int mes = ahora.month;
    int anio = ahora.year;

    // Ajustar el día si el mes actual tiene menos días (ej. febrero 30 -> febrero 28)
    int ultimoDiaDelMes = DateTime(anio, mes + 1, 0).day;
    int diaReal = dia > ultimoDiaDelMes ? ultimoDiaDelMes : dia;

    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, anio, mes, diaReal, hora, minuto);
    
    // Si ya pasó esa fecha/hora este mes, programar para el mes siguiente
    if (scheduledDate.isBefore(ahora)) {
      mes += 1;
      if (mes > 12) {
        mes = 1;
        anio += 1;
      }
      int ultimoDiaProximoMes = DateTime(anio, mes + 1, 0).day;
      int diaRealProximo = dia > ultimoDiaProximoMes ? ultimoDiaProximoMes : dia;
      
      scheduledDate = tz.TZDateTime(tz.local, anio, mes, diaRealProximo, hora, minuto);
    }
    return scheduledDate;
  }

  /// Envía una notificación de prueba en 5 segundos
  Future<void> mostrarNotificacionPrueba() async {
    await _notificationsPlugin.zonedSchedule(
      9999, // ID fijo para la prueba
      '¡Prueba Exitosa!',
      'El sistema de notificaciones está funcionando perfectamente.',
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'canal_pruebas',
          'Pruebas del Sistema',
          channelDescription: 'Canal usado para probar que las notificaciones lleguen',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
