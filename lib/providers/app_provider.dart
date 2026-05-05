import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pago.dart';
import '../models/proyecto.dart';
import '../models/gasto_fijo.dart';
import '../models/control_mensual.dart';
import '../models/gasto_mes.dart';
import '../models/deuda.dart';
import '../models/abono_deuda.dart';
import '../models/baul_item.dart';
import '../models/baul_archivo.dart';
import '../models/tarjeta.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

/// Provider central de la app. Gestiona proyectos y pagos en memoria
/// (sincronizados con SQLite) y notifica a la UI cuando algo cambia.
class AppProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;

  // ─── Estado en memoria ────────────────────────────────────────────────────
  List<Proyecto> _proyectos = [];
  List<Pago> _pagosActuales = [];
  bool _cargando = false;

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  // ─── Módulo Mensual ───────────────────────────────────────────────────────
  List<GastoFijo> _gastosFijos = [];
  List<ControlMensual> _controlesMensuales = [];
  List<GastoMes> _gastosMesActual = [];
  
  List<Deuda> _deudas = [];
  List<AbonoDeuda> _abonosDeudaActual = [];

  // ─── Módulo El Baúl ────────────────────────────────────────────────────────
  List<BaulItem> _baulItems = [];
  List<BaulCampo> _camposItemActual = [];
  List<BaulArchivo> _archivosItemActual = [];

  // ─── Módulo Tarjetas ───────────────────────────────────────────────────────
  List<Tarjeta> _tarjetas = [];

  // ─── Getters ──────────────────────────────────────────────────────────────
  List<Proyecto> get proyectos   => _proyectos;
  List<Pago>    get pagosActuales => _pagosActuales;
  bool          get cargando     => _cargando;
  
  List<GastoFijo> get gastosFijos => _gastosFijos;
  List<ControlMensual> get controlesMensuales => _controlesMensuales;
  List<GastoMes> get gastosMesActual => _gastosMesActual;
  
  List<Deuda> get deudas => _deudas;
  List<AbonoDeuda> get abonosDeudaActual => _abonosDeudaActual;

  List<BaulItem> get baulItems => _baulItems;
  List<BaulCampo> get camposItemActual => _camposItemActual;
  List<BaulArchivo> get archivosItemActual => _archivosItemActual;

  List<Tarjeta> get tarjetas => _tarjetas;

  List<String> get metodosDePago {
    final metodosBase = ['Efectivo', 'Transferencia'];
    final nombresTarjetas = _tarjetas.map((t) => t.nombre).toList();
    return [...metodosBase, ...nombresTarjetas, 'Otro'];
  }

  // ─── Inicialización ───────────────────────────────────────────────────────

  /// Llama esto en el arranque de la app para cargar los proyectos.
  Future<void> inicializar() async {
    _cargando = true;
    notifyListeners();
    
    // Cargar Tema
    final prefs = await SharedPreferences.getInstance();
    final themeIdx = prefs.getInt('theme_mode') ?? 1; // 1 = Dark por defecto
    _themeMode = ThemeMode.values[themeIdx];

    _proyectos = await _db.obtenerProyectos();
    _gastosFijos = await _db.obtenerGastosFijos();
    _controlesMensuales = await _db.obtenerControlesMensuales();
    _deudas = await _db.obtenerDeudas();
    
    _baulItems = await _db.obtenerBaulItems();
    _tarjetas = await _db.obtenerTarjetas();
    
    _cargando = false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', _themeMode.index);
    notifyListeners();
  }

  // ─── Proyectos ────────────────────────────────────────────────────────────

  Future<void> agregarProyecto(Proyecto proyecto) async {
    final id = await _db.insertarProyecto(proyecto);
    _proyectos.insert(0, proyecto.copyWith(id: id));
    notifyListeners();
  }

  Future<void> actualizarProyecto(Proyecto proyecto) async {
    await _db.actualizarProyecto(proyecto);
    final idx = _proyectos.indexWhere((p) => p.id == proyecto.id);
    if (idx != -1) _proyectos[idx] = proyecto;
    notifyListeners();
  }

  Future<void> eliminarProyecto(int id) async {
    await _db.eliminarProyecto(id);
    _proyectos.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // ─── Pagos ────────────────────────────────────────────────────────────────

  /// Carga los pagos de un proyecto específico en memoria, opcionalmente filtrados.
  Future<void> cargarPagos(int proyectoId, {DateTime? desde, DateTime? hasta}) async {
    _cargando = true;
    notifyListeners();
    _pagosActuales = await _db.obtenerPagosFiltrados(
      proyectoId: proyectoId,
      desde: desde,
      hasta: hasta,
    );
    _cargando = false;
    notifyListeners();
  }

  Future<void> agregarPago(Pago pago) async {
    final id = await _db.insertarPago(pago);
    _pagosActuales.insert(0, pago.copyWith(id: id));
    notifyListeners();
  }

  Future<void> actualizarPago(Pago pago) async {
    await _db.actualizarPago(pago);
    final idx = _pagosActuales.indexWhere((p) => p.id == pago.id);
    if (idx != -1) {
      _pagosActuales[idx] = pago;
      // Re-ordenar por si cambió la fecha
      _pagosActuales.sort((a, b) => b.fecha.compareTo(a.fecha));
    }
    notifyListeners();
  }

  Future<void> eliminarPago(int id) async {
    await _db.eliminarPago(id);
    _pagosActuales.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // ─── Cálculos y Resúmenes ─────────────────────────────────────────────────

  /// Total de los pagos actualmente cargados en memoria.
  double get totalPagadoActual =>
      _pagosActuales.fold(0.0, (sum, p) => sum + p.monto);

  /// Total pagado en un proyecto en un rango de fechas (consulta BD directamente).
  Future<double> totalPorFechas({
    required int proyectoId,
    DateTime? desde,
    DateTime? hasta,
  }) =>
      _db.totalPagado(proyectoId: proyectoId, desde: desde, hasta: hasta);

  /// Pagos filtrados por mes y año del proyecto actual en memoria.
  List<Pago> pagosPorMes(int mes, int anio) {
    return _pagosActuales
        .where((p) => p.fecha.month == mes && p.fecha.year == anio)
        .toList();
  }

  // ─── Módulo Mensual: Gastos Fijos ──────────────────────────────────────────

  Future<void> agregarGastoFijo(GastoFijo fijo) async {
    final id = await _db.insertarGastoFijo(fijo);
    _gastosFijos = await _db.obtenerGastosFijos();
    
    // Programar notificación (ID: 1000 + db_id) sin bloquear la UI
    if (fijo.activo == 1) {
      NotificationService.instance.programarRecordatorioMensual(
        id: 1000 + id,
        titulo: 'Vencimiento de Suscripción',
        cuerpo: 'Mañana toca pagar ${fijo.monto} de ${fijo.nombre}',
        diaMes: fijo.diaCobro - 1 <= 0 ? 28 : fijo.diaCobro - 1, // Avisar 1 día antes
      ).catchError((e) => debugPrint('Error programando notificación: $e'));
    }
    
    notifyListeners();
  }

  Future<void> actualizarGastoFijo(GastoFijo fijo) async {
    await _db.actualizarGastoFijo(fijo);
    _gastosFijos = await _db.obtenerGastosFijos();
    
    final notifId = 1000 + fijo.id!;
    if (fijo.activo == 1) {
      NotificationService.instance.programarRecordatorioMensual(
        id: notifId,
        titulo: 'Vencimiento de Suscripción',
        cuerpo: 'Mañana toca pagar ${fijo.monto} de ${fijo.nombre}',
        diaMes: fijo.diaCobro - 1 <= 0 ? 28 : fijo.diaCobro - 1,
      ).catchError((e) => debugPrint('Error programando notificación: $e'));
    } else {
      NotificationService.instance.cancelarNotificacion(notifId)
        .catchError((e) => debugPrint('Error cancelando notificación: $e'));
    }
    
    notifyListeners();
  }

  Future<void> eliminarGastoFijo(int id) async {
    await _db.eliminarGastoFijo(id);
    _gastosFijos.removeWhere((g) => g.id == id);
    NotificationService.instance.cancelarNotificacion(1000 + id)
      .catchError((e) => debugPrint('Error cancelando notificación: $e'));
    notifyListeners();
  }

  // ─── Módulo Mensual: Control Mensual ────────────────────────────────────────

  /// Crea el control del mes e INYECTA todos los gastos fijos activos
  Future<void> crearControlMensual(int mes, int anio, {String notas = ''}) async {
    final control = ControlMensual(mes: mes, anio: anio, notas: notas, creadoEn: DateTime.now());
    final controlId = await _db.insertarControlMensual(control);

    // Inyectar gastos fijos activos
    final fijosActivos = _gastosFijos.where((g) => g.activo == 1).toList();
    for (var fijo in fijosActivos) {
      int dia = fijo.diaCobro;
      final ultimoDiaMes = DateTime(anio, mes + 1, 0).day;
      if (dia > ultimoDiaMes) dia = ultimoDiaMes;

      final gastoAuto = GastoMes(
        controlId: controlId,
        nombre: fijo.nombre,
        monto: fijo.monto,
        fecha: DateTime(anio, mes, dia),
        metodoPago: fijo.metodoPago,
        icono: fijo.icono,
        esFijo: 1, 
        pagado: 0, // Pendiente de pago al crearse
      );
      await _db.insertarGastoMes(gastoAuto);
    }

    _controlesMensuales = await _db.obtenerControlesMensuales();
    notifyListeners();
  }

  Future<void> actualizarControlMensual(ControlMensual control) async {
    await _db.actualizarControlMensual(control);
    final idx = _controlesMensuales.indexWhere((c) => c.id == control.id);
    if (idx != -1) _controlesMensuales[idx] = control;
    notifyListeners();
  }

  Future<void> eliminarControlMensual(int id) async {
    await _db.eliminarControlMensual(id);
    _controlesMensuales.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  // ─── Módulo Mensual: Gastos del Mes ───────────────────────────────────────

  Future<void> cargarGastosMes(int controlId) async {
    _cargando = true;
    notifyListeners();
    _gastosMesActual = await _db.obtenerGastosMes(controlId);
    _cargando = false;
    notifyListeners();
  }

  Future<void> agregarGastoMes(GastoMes gasto) async {
    await _db.insertarGastoMes(gasto);
    await cargarGastosMes(gasto.controlId);
  }

  Future<void> actualizarGastoMes(GastoMes gasto) async {
    await _db.actualizarGastoMes(gasto);
    await cargarGastosMes(gasto.controlId);
  }

  Future<void> eliminarGastoMes(int id, int controlId) async {
    await _db.eliminarGastoMes(id);
    await cargarGastosMes(controlId);
  }

  // ─── Módulo de Deudas ─────────────────────────────────────────────────────

  Future<void> agregarDeuda(Deuda deuda) async {
    final id = await _db.insertarDeuda(deuda);
    _deudas = await _db.obtenerDeudas();
    
    // Programar recordatorio si hay fecha límite (ID: 2000 + db_id)
    if (deuda.fechaLimite != null) {
      final limit = deuda.fechaLimite!.subtract(const Duration(days: 1));
      NotificationService.instance.programarNotificacionUnica(
        id: 2000 + id,
        titulo: 'Vencimiento de Préstamo',
        cuerpo: 'Mañana vence el plazo para el préstamo de ${deuda.persona}',
        fecha: DateTime(limit.year, limit.month, limit.day, 10, 0),
      ).catchError((e) => debugPrint('Error programando notificación: $e'));
    }
    
    notifyListeners();
  }

  Future<void> actualizarDeuda(Deuda deuda) async {
    await _db.actualizarDeuda(deuda);
    _deudas = await _db.obtenerDeudas();
    notifyListeners();
  }

  Future<void> eliminarDeuda(int id) async {
    await _db.eliminarDeuda(id);
    _deudas.removeWhere((d) => d.id == id);
    NotificationService.instance.cancelarNotificacion(2000 + id)
      .catchError((e) => debugPrint('Error cancelando notificación: $e'));
    notifyListeners();
  }

  Future<void> cargarAbonosDeuda(int deudaId) async {
    _cargando = true;
    notifyListeners();
    _abonosDeudaActual = await _db.obtenerAbonosPorDeuda(deudaId);
    _cargando = false;
    notifyListeners();
  }

  Future<void> agregarAbonoDeuda(AbonoDeuda abono) async {
    await _db.insertarAbonoDeuda(abono);
    _deudas = await _db.obtenerDeudas(); // Recargar deudas para ver saldo actualizado
    await cargarAbonosDeuda(abono.deudaId);
  }

  Future<void> eliminarAbonoDeuda(AbonoDeuda abono) async {
    await _db.eliminarAbonoDeuda(abono.id!, abono.deudaId, abono.monto);
    _deudas = await _db.obtenerDeudas();
    await cargarAbonosDeuda(abono.deudaId);
  }

  // ─── Resúmenes de Deudas ──────────────────────────────────────────────────

  double get totalMeDeben => _deudas.where((d) => d.meDeben && d.estatus == 0)
      .fold(0.0, (sum, d) => sum + (d.montoTotal - d.montoPagado));

  double get totalDebo => _deudas.where((d) => !d.meDeben && d.estatus == 0)
      .fold(0.0, (sum, d) => sum + (d.montoTotal - d.montoPagado));

  // ─── Módulo El Baúl ────────────────────────────────────────────────────────

  Future<void> cargarBaulItems() async {
    _baulItems = await _db.obtenerBaulItems();
    notifyListeners();
  }

  Future<void> agregarBaulItem(BaulItem item, List<BaulCampo> campos) async {
    final itemId = await _db.insertarBaulItem(item);
    for (var campo in campos) {
      await _db.insertarBaulCampo(campo.copyWith(itemId: itemId));
    }
    await cargarBaulItems();
  }

  Future<void> actualizarBaulItem(BaulItem item) async {
    await _db.actualizarBaulItem(item);
    await cargarBaulItems();
  }

  Future<void> eliminarBaulItem(int id) async {
    await _db.eliminarBaulItem(id);
    await cargarBaulItems();
  }

  Future<void> cargarDetalleItem(int itemId) async {
    _cargando = true;
    notifyListeners();
    _camposItemActual = await _db.obtenerCamposPorItem(itemId);
    _archivosItemActual = await _db.obtenerArchivosPorItem(itemId);
    _cargando = false;
    notifyListeners();
  }

  Future<void> agregarCampoBaul(BaulCampo campo) async {
    await _db.insertarBaulCampo(campo);
    await cargarDetalleItem(campo.itemId);
  }

  Future<void> actualizarCampoBaul(BaulCampo campo) async {
    await _db.actualizarBaulCampo(campo);
    await cargarDetalleItem(campo.itemId);
  }

  Future<void> eliminarCampoBaul(int id, int itemId) async {
    await _db.eliminarBaulCampo(id);
    await cargarDetalleItem(itemId);
  }

  Future<void> agregarArchivoBaul(BaulArchivo archivo) async {
    await _db.insertarBaulArchivo(archivo);
    await cargarDetalleItem(archivo.itemId);
  }

  Future<void> eliminarArchivoBaul(int id, int itemId) async {
    await _db.eliminarBaulArchivo(id);
    await cargarDetalleItem(itemId);
  }

  // ─── Módulo Tarjetas ───────────────────────────────────────────────────────

  Future<void> agregarTarjeta(Tarjeta tarjeta) async {
    final id = await _db.insertarTarjeta(tarjeta);
    _tarjetas = await _db.obtenerTarjetas();
    
    if (tarjeta.tipo == 'Crédito' && tarjeta.diaLimite != null) {
      int diaAviso = tarjeta.diaLimite! - 2;
      if (diaAviso <= 0) diaAviso = 28; // fallback
      
      NotificationService.instance.programarRecordatorioMensual(
        id: 2000 + id,
        titulo: 'Pago de Tarjeta',
        cuerpo: 'Faltan 2 días para tu fecha límite de pago de ${tarjeta.nombre}.',
        diaMes: diaAviso,
      ).catchError((e) => debugPrint('Error programando notificación: $e'));
    }
    
    notifyListeners();
  }

  Future<void> actualizarTarjeta(Tarjeta tarjeta) async {
    await _db.actualizarTarjeta(tarjeta);
    _tarjetas = await _db.obtenerTarjetas();
    
    final notifId = 2000 + tarjeta.id!;
    if (tarjeta.tipo == 'Crédito' && tarjeta.diaLimite != null) {
      int diaAviso = tarjeta.diaLimite! - 2;
      if (diaAviso <= 0) diaAviso = 28;
      
      NotificationService.instance.programarRecordatorioMensual(
        id: notifId,
        titulo: 'Pago de Tarjeta',
        cuerpo: 'Faltan 2 días para tu fecha límite de pago de ${tarjeta.nombre}.',
        diaMes: diaAviso,
      ).catchError((e) => debugPrint('Error programando notificación: $e'));
    } else {
      NotificationService.instance.cancelarNotificacion(notifId)
        .catchError((e) => debugPrint('Error cancelando notificación: $e'));
    }
    
    notifyListeners();
  }

  Future<void> eliminarTarjeta(int id) async {
    await _db.eliminarTarjeta(id);
    _tarjetas = await _db.obtenerTarjetas();
    NotificationService.instance.cancelarNotificacion(2000 + id)
      .catchError((e) => debugPrint('Error cancelando notificación: $e'));
    notifyListeners();
  }
}
