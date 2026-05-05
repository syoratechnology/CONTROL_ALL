import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/control_mensual.dart';
import '../../models/gasto_mes.dart';
import '../../models/tarjeta.dart';
import '../../providers/app_provider.dart';

class DetalleMesScreen extends StatefulWidget {
  final ControlMensual control;
  const DetalleMesScreen({super.key, required this.control});

  @override
  State<DetalleMesScreen> createState() => _DetalleMesScreenState();
}

class _DetalleMesScreenState extends State<DetalleMesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().cargarGastosMes(widget.control.id!);
    });
  }

  void _mostrarDialogoGastoMes(BuildContext context, [GastoMes? existente, String? metodoPagoInicial]) {
    showDialog(
      context: context,
      builder: (_) => DialogoGastoMes(
        controlId: widget.control.id!, 
        gastoExistente: existente,
        metodoPagoInicial: metodoPagoInicial,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final gastos = provider.gastosMesActual;

    final metodosBase = provider.metodosDePago;

    // Cálculos del mes
    final totalFijos = gastos.where((g) => g.esFijo == 1).fold<double>(0, (s, g) => s + g.monto);
    final totalExtras = gastos.where((g) => g.esFijo == 0).fold<double>(0, (s, g) => s + g.monto);
    final total = totalFijos + totalExtras;
    final totalPagado = gastos.where((g) => g.pagado == 1).fold<double>(0, (s, g) => s + g.monto);
    final pendiente = total - totalPagado;

    // Agrupación de gastos
    final Map<String, List<GastoMes>> gastosAgrupados = {};
    for (final m in metodosBase) {
      gastosAgrupados[m] = [];
    }
    for (final g in gastos) {
      if (gastosAgrupados.containsKey(g.metodoPago)) {
        gastosAgrupados[g.metodoPago]!.add(g);
      } else {
        gastosAgrupados.putIfAbsent(g.metodoPago, () => []).add(g);
      }
    }
    final secciones = gastosAgrupados.entries.where((e) => e.value.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Mes ${widget.control.mes} / ${widget.control.anio}'),
      ),
      body: provider.cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _ResumenMesPanel(
                  totalFijos: totalFijos,
                  totalExtras: totalExtras,
                  totalPagado: totalPagado,
                  pendiente: pendiente,
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: secciones.length,
                    itemBuilder: (context, index) {
                      final seccion = secciones[index];
                      return _BloqueMetodoPago(
                        metodo: seccion.key,
                        gastos: seccion.value,
                        control: widget.control,
                        tarjetas: provider.tarjetas,
                        onEdit: (g) => _mostrarDialogoGastoMes(context, g),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: _buildFAB(context),
    );
  }

  bool _showActions = false;

  Widget _buildFAB(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_showActions) ...[
          _SecondaryFab(
            label: 'Eliminar Mes',
            icon: Icons.delete_outline,
            heroTag: 'fab_delete_mes',
            backgroundColor: AppColors.danger.withValues(alpha: 0.1),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('¿Eliminar mes?'),
                  content: const Text('Se eliminará este control mensual y todos sus gastos. ¿Estás seguro?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
                      onPressed: () {
                        context.read<AppProvider>().eliminarControlMensual(widget.control.id!);
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: const Text('Sí, eliminar'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: 'fab_toggle_mes',
              backgroundColor: Theme.of(context).cardColor,
              onPressed: () => setState(() => _showActions = !_showActions),
              child: Icon(_showActions ? Icons.close : Icons.tune_rounded),
            ),
            const SizedBox(width: 12),
            FloatingActionButton.extended(
              heroTag: 'fab_add_gasto',
              onPressed: () => _mostrarDialogoGastoMes(context),
              icon: const Icon(Icons.add),
              label: const Text('Gasto Extra'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SecondaryFab extends StatelessWidget {
  final String label;
  final IconData icon;
  final String heroTag;
  final VoidCallback onTap;
  final Color? backgroundColor;

  const _SecondaryFab({
    required this.label,
    required this.icon,
    required this.heroTag,
    required this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          heroTag: heroTag,
          backgroundColor: backgroundColor ?? Theme.of(context).cardColor,
          onPressed: onTap,
          child: Icon(icon, size: 20, color: backgroundColor != null ? AppColors.danger : null),
        ),
      ],
    );
  }
}

class _ResumenMesPanel extends StatelessWidget {
  final double totalFijos;
  final double totalExtras;
  final double totalPagado;
  final double pendiente;

  const _ResumenMesPanel({
    required this.totalFijos,
    required this.totalExtras,
    required this.totalPagado,
    required this.pendiente,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total del mes'),
                  Text(AppUtils.formatMonto(totalFijos + totalExtras), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Pendiente', style: TextStyle(color: AppColors.danger)),
                  Text(AppUtils.formatMonto(pendiente), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.danger)),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniStat(label: 'Fijos', valor: totalFijos, icon: Icons.autorenew),
              _MiniStat(label: 'Extras', valor: totalExtras, icon: Icons.shopping_bag_outlined),
              _MiniStat(label: 'Pagado', valor: totalPagado, icon: Icons.check_circle_outline, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double valor;
  final IconData icon;
  final Color? color;

  const _MiniStat({required this.label, required this.valor, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color ?? Theme.of(context).textTheme.bodyMedium?.color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color ?? Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(AppUtils.formatMonto(valor), style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _GastoMesCard extends StatelessWidget {
  final GastoMes gasto;
  final VoidCallback onEdit;

  const _GastoMesCard({required this.gasto, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isPagado = gasto.pagado == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox para marcar como pagado
              Checkbox(
                value: isPagado,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  context.read<AppProvider>().actualizarGastoMes(gasto.copyWith(pagado: val == true ? 1 : 0));
                },
              ),
              CircleAvatar(
                backgroundColor: isPagado ? Theme.of(context).dividerColor.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.1),
                child: Icon(AppUtils.getIcono(gasto.icono), color: isPagado ? Theme.of(context).disabledColor : AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gasto.nombre,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        decoration: isPagado ? TextDecoration.lineThrough : null,
                        color: isPagado ? Theme.of(context).disabledColor : Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    Text(
                      '${AppUtils.formatFechaCorta(gasto.fecha)} • ${gasto.metodoPago}',
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppUtils.formatMonto(gasto.monto),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isPagado ? Theme.of(context).disabledColor : (gasto.esFijo == 1 ? AppColors.primary : AppColors.accent),
                    ),
                  ),
                  if (gasto.esFijo == 1)
                    const Text('Fijo', style: TextStyle(fontSize: 10, color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DialogoGastoMes extends StatefulWidget {
  final int controlId;
  final GastoMes? gastoExistente;
  final String? metodoPagoInicial;

  const DialogoGastoMes({super.key, required this.controlId, this.gastoExistente, this.metodoPagoInicial});

  @override
  State<DialogoGastoMes> createState() => _DialogoGastoMesState();
}

class _DialogoGastoMesState extends State<DialogoGastoMes> {
  final _formKey = GlobalKey<FormState>();
  String _nombre = '';
  double _monto = 0.0;
  DateTime _fecha = DateTime.now();
  String _metodoPago = 'Efectivo';
  String _iconoSeleccionado = 'shopping'; // Por defecto compras
  String _notas = '';
  int _pagado = 1;

  @override
  void initState() {
    super.initState();
    if (widget.metodoPagoInicial != null) {
      _metodoPago = widget.metodoPagoInicial!;
    }
    if (widget.gastoExistente != null) {
      _nombre = widget.gastoExistente!.nombre;
      _monto = widget.gastoExistente!.monto;
      _fecha = widget.gastoExistente!.fecha;
      _metodoPago = widget.gastoExistente!.metodoPago;
      _iconoSeleccionado = widget.gastoExistente!.icono;
      _notas = widget.gastoExistente!.notas;
      _pagado = widget.gastoExistente!.pagado;
    }
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final prov = context.read<AppProvider>();
      if (widget.gastoExistente != null) {
        prov.actualizarGastoMes(widget.gastoExistente!.copyWith(
          nombre: _nombre,
          monto: _monto,
          fecha: _fecha,
          metodoPago: _metodoPago,
          icono: _iconoSeleccionado,
          notas: _notas,
          pagado: _pagado,
        ));
      } else {
        prov.agregarGastoMes(GastoMes(
          controlId: widget.controlId,
          nombre: _nombre,
          monto: _monto,
          fecha: _fecha,
          metodoPago: _metodoPago,
          icono: _iconoSeleccionado,
          notas: _notas,
          esFijo: 0, // Es un extra manual
          pagado: _pagado,
        ));
      }
      Navigator.pop(context);
    }
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? seleccion = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (seleccion != null && seleccion != _fecha) {
      setState(() => _fecha = seleccion);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.gastoExistente != null ? 'Editar Gasto' : 'Nuevo Gasto Extra',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    if (widget.gastoExistente != null)
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.danger),
                        onPressed: () {
                          context.read<AppProvider>().eliminarGastoMes(widget.gastoExistente!.id!, widget.controlId);
                          Navigator.pop(context);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  initialValue: _nombre,
                  decoration: const InputDecoration(labelText: 'Concepto (Ej. Súper)'),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  onSaved: (v) => _nombre = v!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _monto == 0 ? '' : _monto.toString(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Monto'),
                  validator: (v) => double.tryParse(v ?? '') == null ? 'Inválido' : null,
                  onSaved: (v) => _monto = double.parse(v!),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _seleccionarFecha(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Fecha: ${AppUtils.formatFechaCorta(_fecha)}'),
                        const Icon(Icons.calendar_month),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (ctx) {
                    final metodos = ctx.watch<AppProvider>().metodosDePago.toList();
                    if (!metodos.contains(_metodoPago)) {
                      metodos.add(_metodoPago);
                    }
                    return DropdownButtonFormField<String>(
                      value: _metodoPago,
                      decoration: const InputDecoration(labelText: 'Método de pago'),
                      items: metodos.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (v) => setState(() => _metodoPago = v!),
                    );
                  }
                ),
                const SizedBox(height: 16),
                Text('Icono', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppUtils.iconosDisponibles.entries.map((e) {
                    final isSel = _iconoSeleccionado == e.key;
                    return GestureDetector(
                      onTap: () => setState(() => _iconoSeleccionado = e.key),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primary.withValues(alpha: 0.1) : null,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSel ? AppColors.primary : Theme.of(context).dividerColor),
                        ),
                        child: Icon(e.value, color: isSel ? AppColors.primary : Theme.of(context).disabledColor),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('¿Ya está pagado?'),
                  value: _pagado == 1,
                  activeTrackColor: AppColors.primary,
                  onChanged: (val) => setState(() => _pagado = val ? 1 : 0),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      onPressed: _guardar,
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BloqueMetodoPago extends StatelessWidget {
  final String metodo;
  final List<GastoMes> gastos;
  final ControlMensual control;
  final List<Tarjeta> tarjetas;
  final Function(GastoMes) onEdit;

  const _BloqueMetodoPago({
    required this.metodo,
    required this.gastos,
    required this.control,
    required this.tarjetas,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // Buscar si es tarjeta de crédito para fechas
    Tarjeta? tarjeta;
    try {
      tarjeta = tarjetas.firstWhere((t) => t.nombre == metodo && t.tipo == 'Crédito');
    } catch (_) {}

    String subtitulo = '';
    if (tarjeta != null && tarjeta.diaCorte != null && tarjeta.diaLimite != null) {
      const meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
      final mesActual = control.mes;
      final mesCorte = meses[mesActual - 1];
      final mesLimite = mesActual == 12 ? meses[0] : meses[mesActual];
      subtitulo = 'Corte: ${tarjeta.diaCorte} de $mesCorte • Límite: ${tarjeta.diaLimite} de $mesLimite';
    }

    final total = gastos.fold<double>(0, (s, g) => s + g.monto);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ExpansionTile(
          initiallyExpanded: true,
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          iconColor: AppColors.primary,
          collapsedIconColor: Theme.of(context).disabledColor,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          shape: const Border(),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metodo.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 1.1,
                      ),
                    ),
                    if (subtitulo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitulo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppUtils.formatMonto(total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Container(
              color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: gastos.map((g) => _GastoMesCard(gasto: g, onEdit: () => onEdit(g))).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
