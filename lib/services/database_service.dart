import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/pago.dart';
import '../models/proyecto.dart';
import '../models/gasto_fijo.dart';
import '../models/control_mensual.dart';
import '../models/gasto_mes.dart';
import '../models/deuda.dart';
import '../models/abono_deuda.dart';
import '../models/baul_item.dart';
import '../models/baul_archivo.dart';

/// Singleton que gestiona toda la base de datos SQLite local de la app.
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  // ─── Inicialización ───────────────────────────────────────────────────────

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<void> closeDatabase() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'control_gastos_v2.db');

    return openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla de Proyectos (bolsillos)
    await db.execute('''
      CREATE TABLE proyectos (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre      TEXT    NOT NULL,
        descripcion TEXT    NOT NULL DEFAULT '',
        color_hex   INTEGER NOT NULL,
        icono       TEXT    NOT NULL,
        estatus     INTEGER NOT NULL DEFAULT 1,
        creado_en   TEXT    NOT NULL
      )
    ''');

    // Tabla de Pagos (movimientos de dinero)
    await db.execute('''
      CREATE TABLE pagos (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        proyecto_id INTEGER NOT NULL,
        monto       REAL    NOT NULL,
        fecha       TEXT    NOT NULL,
        metodo_pago TEXT    NOT NULL,
        notas       TEXT    NOT NULL DEFAULT '',
        creado_en   TEXT    NOT NULL,
        FOREIGN KEY (proyecto_id) REFERENCES proyectos (id) ON DELETE CASCADE
      )
    ''');

    await _crearTablasMensuales(db);
    await _crearTablasDeudas(db);
    await _crearTablasBaul(db);
  }

  Future<void> _crearTablasBaul(Database db) async {
    // Eliminar tablas anteriores si existen para reiniciar el diseño del baúl
    await db.execute('DROP TABLE IF EXISTS baul_categorias');
    await db.execute('DROP TABLE IF EXISTS baul_campos');
    await db.execute('DROP TABLE IF EXISTS baul_archivos');
    await db.execute('DROP TABLE IF EXISTS baul_items');

    await db.execute('''
      CREATE TABLE baul_items (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo         TEXT    NOT NULL,
        tipo           TEXT    NOT NULL,
        fecha_creacion TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE baul_campos (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id     INTEGER NOT NULL,
        etiqueta    TEXT    NOT NULL,
        valor       TEXT    NOT NULL,
        es_secreto  INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (item_id) REFERENCES baul_items (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE baul_archivos (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id    INTEGER NOT NULL,
        nombre     TEXT    NOT NULL,
        ruta_local TEXT    NOT NULL,
        extension  TEXT    NOT NULL,
        tamano     INTEGER NOT NULL,
        FOREIGN KEY (item_id) REFERENCES baul_items (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _crearTablasDeudas(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS deudas (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        persona       TEXT    NOT NULL,
        monto_total   REAL    NOT NULL,
        monto_pagado  REAL    NOT NULL DEFAULT 0.0,
        tipo          INTEGER NOT NULL,
        fecha         TEXT    NOT NULL,
        fecha_limite  TEXT,
        notas         TEXT    DEFAULT '',
        estatus       INTEGER NOT NULL DEFAULT 0,
        total_cuotas  INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS abonos_deudas (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        deuda_id  INTEGER NOT NULL,
        monto     REAL    NOT NULL,
        fecha     TEXT    NOT NULL,
        nota      TEXT    DEFAULT '',
        FOREIGN KEY (deuda_id) REFERENCES deudas (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _crearTablasMensuales(Database db) async {
    await db.execute('''
      CREATE TABLE gastos_fijos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        monto REAL NOT NULL,
        diaCobro INTEGER NOT NULL,
        metodoPago TEXT NOT NULL,
        icono TEXT NOT NULL,
        activo INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE controles_mensuales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mes INTEGER NOT NULL,
        anio INTEGER NOT NULL,
        notas TEXT,
        creadoEn TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE gastos_mes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        controlId INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL,
        metodoPago TEXT NOT NULL,
        icono TEXT NOT NULL,
        notas TEXT,
        esFijo INTEGER NOT NULL,
        pagado INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (controlId) REFERENCES controles_mensuales (id) ON DELETE CASCADE
      )
    ''');
  }
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _crearTablasMensuales(db);
    }
    if (oldVersion < 3) {
      await _crearTablasDeudas(db);
    }
    if (oldVersion < 5) {
      // Re-intentar creación por seguridad
      await _crearTablasBaul(db);
    }
    if (oldVersion < 6) {
      // Forzar reconstrucción del baúl al nuevo diseño sin carpetas
      await _crearTablasBaul(db);
    }
  }

  // ─── CRUD Proyectos ───────────────────────────────────────────────────────

  Future<int> insertarProyecto(Proyecto proyecto) async {
    final db = await database;
    return db.insert('proyectos', proyecto.toMap());
  }

  Future<List<Proyecto>> obtenerProyectos() async {
    final db = await database;
    final maps = await db.query('proyectos', orderBy: 'creado_en DESC');
    return maps.map(Proyecto.fromMap).toList();
  }

  Future<int> actualizarProyecto(Proyecto proyecto) async {
    final db = await database;
    return db.update(
      'proyectos',
      proyecto.toMap(),
      where: 'id = ?',
      whereArgs: [proyecto.id],
    );
  }

  Future<int> eliminarProyecto(int id) async {
    final db = await database;
    // Los pagos asociados se eliminan automáticamente (ON DELETE CASCADE)
    return db.delete('proyectos', where: 'id = ?', whereArgs: [id]);
  }

  // ─── CRUD Pagos ───────────────────────────────────────────────────────────

  Future<int> insertarPago(Pago pago) async {
    final db = await database;
    return db.insert('pagos', pago.toMap());
  }

  /// Obtiene todos los pagos de un proyecto, ordenados por fecha más reciente.
  Future<List<Pago>> obtenerPagosPorProyecto(int proyectoId) async {
    final db = await database;
    final maps = await db.query(
      'pagos',
      where: 'proyecto_id = ?',
      whereArgs: [proyectoId],
      orderBy: 'fecha DESC',
    );
    return maps.map(Pago.fromMap).toList();
  }

  /// Obtiene pagos de un proyecto filtrados por rango de fechas (para reportes).
  Future<List<Pago>> obtenerPagosFiltrados({
    required int proyectoId,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final db = await database;
    String where = 'proyecto_id = ?';
    final args = <dynamic>[proyectoId];

    if (desde != null) {
      where += ' AND fecha >= ?';
      args.add(desde.toIso8601String());
    }
    if (hasta != null) {
      where += ' AND fecha <= ?';
      args.add(hasta.toIso8601String());
    }

    final maps = await db.query(
      'pagos',
      where: where,
      whereArgs: args,
      orderBy: 'fecha DESC',
    );
    return maps.map(Pago.fromMap).toList();
  }

  Future<int> actualizarPago(Pago pago) async {
    final db = await database;
    return db.update(
      'pagos',
      pago.toMap(),
      where: 'id = ?',
      whereArgs: [pago.id],
    );
  }

  /// Calcula el total pagado en un proyecto (opcionalmente filtrado por fechas).
  Future<double> totalPagado({
    required int proyectoId,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final pagos = await obtenerPagosFiltrados(
      proyectoId: proyectoId,
      desde: desde,
      hasta: hasta,
    );
    return pagos.fold<double>(0.0, (sum, p) => sum + p.monto);
  }

  Future<int> eliminarPago(int id) async {
    final db = await database;
    return db.delete('pagos', where: 'id = ?', whereArgs: [id]);
  }

  // ─── CRUD Gastos Fijos (Plantillas) ─────────────────────────────────────────

  Future<int> insertarGastoFijo(GastoFijo fijo) async {
    final db = await database;
    return db.insert('gastos_fijos', fijo.toMap());
  }

  Future<List<GastoFijo>> obtenerGastosFijos() async {
    final db = await database;
    final maps = await db.query('gastos_fijos', orderBy: 'diaCobro ASC');
    return maps.map(GastoFijo.fromMap).toList();
  }

  Future<int> actualizarGastoFijo(GastoFijo fijo) async {
    final db = await database;
    return db.update('gastos_fijos', fijo.toMap(), where: 'id = ?', whereArgs: [fijo.id]);
  }

  Future<int> eliminarGastoFijo(int id) async {
    final db = await database;
    return db.delete('gastos_fijos', where: 'id = ?', whereArgs: [id]);
  }

  // ─── CRUD Control Mensual ───────────────────────────────────────────────────

  Future<int> insertarControlMensual(ControlMensual control) async {
    final db = await database;
    return db.insert('controles_mensuales', control.toMap());
  }

  Future<List<ControlMensual>> obtenerControlesMensuales() async {
    final db = await database;
    final maps = await db.query('controles_mensuales', orderBy: 'anio DESC, mes DESC');
    return maps.map(ControlMensual.fromMap).toList();
  }

  Future<int> actualizarControlMensual(ControlMensual control) async {
    final db = await database;
    return db.update('controles_mensuales', control.toMap(), where: 'id = ?', whereArgs: [control.id]);
  }

  Future<int> eliminarControlMensual(int id) async {
    final db = await database;
    // Los gastos_mes se eliminan en cascada
    return db.delete('controles_mensuales', where: 'id = ?', whereArgs: [id]);
  }

  // ─── CRUD Gastos Mes ────────────────────────────────────────────────────────

  Future<int> insertarGastoMes(GastoMes gasto) async {
    final db = await database;
    return db.insert('gastos_mes', gasto.toMap());
  }

  Future<List<GastoMes>> obtenerGastosMes(int controlId) async {
    final db = await database;
    final maps = await db.query(
      'gastos_mes',
      where: 'controlId = ?',
      whereArgs: [controlId],
      orderBy: 'fecha ASC',
    );
    return maps.map(GastoMes.fromMap).toList();
  }

  Future<int> actualizarGastoMes(GastoMes gasto) async {
    final db = await database;
    return db.update('gastos_mes', gasto.toMap(), where: 'id = ?', whereArgs: [gasto.id]);
  }

  Future<int> eliminarGastoMes(int id) async {
    final db = await database;
    return db.delete('gastos_mes', where: 'id = ?', whereArgs: [id]);
  }

  // ─── CRUD Deudas ──────────────────────────────────────────────────────────

  Future<int> insertarDeuda(Deuda deuda) async {
    final db = await database;
    return db.insert('deudas', deuda.toMap());
  }

  Future<List<Deuda>> obtenerDeudas() async {
    final db = await database;
    final maps = await db.query('deudas', orderBy: 'estatus ASC, fecha DESC');
    return maps.map(Deuda.fromMap).toList();
  }

  Future<int> actualizarDeuda(Deuda deuda) async {
    final db = await database;
    return db.update('deudas', deuda.toMap(), where: 'id = ?', whereArgs: [deuda.id]);
  }

  Future<int> eliminarDeuda(int id) async {
    final db = await database;
    return db.delete('deudas', where: 'id = ?', whereArgs: [id]);
  }

  // ─── CRUD Abonos Deudas ────────────────────────────────────────────────────

  Future<int> insertarAbonoDeuda(AbonoDeuda abono) async {
    final db = await database;
    final id = await db.insert('abonos_deudas', abono.toMap());
    
    // Actualizar el monto pagado en la deuda principal
    await db.execute('''
      UPDATE deudas 
      SET monto_pagado = monto_pagado + ?,
          estatus = CASE WHEN monto_pagado + ? >= monto_total THEN 1 ELSE 0 END
      WHERE id = ?
    ''', [abono.monto, abono.monto, abono.deudaId]);
    
    return id;
  }

  Future<List<AbonoDeuda>> obtenerAbonosPorDeuda(int deudaId) async {
    final db = await database;
    final maps = await db.query(
      'abonos_deudas',
      where: 'deuda_id = ?',
      whereArgs: [deudaId],
      orderBy: 'fecha DESC',
    );
    return maps.map(AbonoDeuda.fromMap).toList();
  }

  Future<void> eliminarAbonoDeuda(int id, int deudaId, double monto) async {
    final db = await database;
    await db.delete('abonos_deudas', where: 'id = ?', whereArgs: [id]);
    
    // Revertir el monto pagado
    await db.execute('''
      UPDATE deudas 
      SET monto_pagado = monto_pagado - ?,
          estatus = 0
      WHERE id = ?
    ''', [monto, deudaId]);
  }

  // ─── CRUD Baúl ─────────────────────────────────────────────────────────────

  Future<int> insertarBaulItem(BaulItem item) async {
    final db = await database;
    return db.insert('baul_items', item.toMap());
  }

  Future<List<BaulItem>> obtenerBaulItems() async {
    final db = await database;
    final maps = await db.query('baul_items', orderBy: 'fecha_creacion DESC');
    return maps.map(BaulItem.fromMap).toList();
  }

  Future<int> actualizarBaulItem(BaulItem item) async {
    final db = await database;
    return db.update('baul_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> eliminarBaulItem(int id) async {
    final db = await database;
    return db.delete('baul_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertarBaulArchivo(BaulArchivo archivo) async {
    final db = await database;
    return db.insert('baul_archivos', archivo.toMap());
  }

  Future<List<BaulArchivo>> obtenerArchivosPorItem(int itemId) async {
    final db = await database;
    final maps = await db.query('baul_archivos', where: 'item_id = ?', whereArgs: [itemId]);
    return maps.map(BaulArchivo.fromMap).toList();
  }

  Future<int> eliminarBaulArchivo(int id) async {
    final db = await database;
    return db.delete('baul_archivos', where: 'id = ?', whereArgs: [id]);
  }

  // ─── CRUD Campos Baúl ──────────────────────────────────────────────────────

  Future<int> insertarBaulCampo(BaulCampo campo) async {
    final db = await database;
    return db.insert('baul_campos', campo.toMap());
  }

  Future<List<BaulCampo>> obtenerCamposPorItem(int itemId) async {
    final db = await database;
    final maps = await db.query('baul_campos', where: 'item_id = ?', whereArgs: [itemId]);
    return maps.map(BaulCampo.fromMap).toList();
  }

  Future<int> actualizarBaulCampo(BaulCampo campo) async {
    final db = await database;
    return db.update('baul_campos', campo.toMap(), where: 'id = ?', whereArgs: [campo.id]);
  }

  Future<int> eliminarBaulCampo(int id) async {
    final db = await database;
    return db.delete('baul_campos', where: 'id = ?', whereArgs: [id]);
  }
}
