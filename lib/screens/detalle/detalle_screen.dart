import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/proyecto.dart';
import '../../providers/app_provider.dart';
import '../dashboard/widgets/dialogo_nuevo_proyecto.dart';
import 'widgets/dialogo_agregar_pago.dart';

/// Pantalla de detalle de un proyecto:
/// - Muestra el historial de pagos
/// - Muestra el total pagado
/// - Permite agregar nuevos pagos con notas
class DetalleScreen extends StatefulWidget {
  final Proyecto proyecto;
  const DetalleScreen({super.key, required this.proyecto});

  @override
  State<DetalleScreen> createState() => _DetalleScreenState();
}

class _DetalleScreenState extends State<DetalleScreen> {
  DateTimeRange? _rangoFechas;
  bool _showActions = false; // Estado para ocultar/mostrar botones secundarios

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarPagos();
    });
  }

  void _cargarPagos() {
    context.read<AppProvider>().cargarPagos(
      widget.proyecto.id!,
      desde: _rangoFechas?.start,
      hasta: _rangoFechas?.end,
    );
  }

  Future<void> _seleccionarFiltroFechas() async {
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _rangoFechas,
    );

    if (rango != null) {
      setState(() => _rangoFechas = rango);
      _cargarPagos();
    }
  }

  void _limpiarFiltro() {
    setState(() => _rangoFechas = null);
    _cargarPagos();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final color = Color(widget.proyecto.colorHex);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.proyecto.nombre),
      ),
      body: provider.cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Tarjeta de resumen total ──────────────────────────────
                _TotalCard(
                  total: provider.totalPagadoActual,
                  color: color,
                  cantidadPagos: provider.pagosActuales.length,
                ),
                const Divider(height: 1),
                // ── Lista de pagos ────────────────────────────────────────
                Expanded(
                  child: provider.pagosActuales.isEmpty
                      ? Center(
                          child: Text('Sin pagos registrados aún.',
                              style: Theme.of(context).textTheme.bodyMedium))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.pagosActuales.length,
                          itemBuilder: (ctx, i) {
                            final pago = provider.pagosActuales[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.attach_money_rounded, color: color, size: 24),
                                ),
                                title: Text(
                                  AppUtils.formatMonto(pago.monto),
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    '${pago.metodoPago} • ${pago.fecha.day}/${pago.fecha.month}/${pago.fecha.year}\n${pago.notas}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ),
                                isThreeLine: pago.notas.isNotEmpty,
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => DialogoAgregarPago(
                                      proyectoId: widget.proyecto.id!,
                                      pagoExistente: pago,
                                    ),
                                  );
                                },
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                                  onPressed: () => provider.eliminarPago(pago.id!),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: _buildFAB(context, color),
    );
  }

  Widget _buildFAB(BuildContext context, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_showActions) ...[
          if (_rangoFechas != null)
            _SecondaryFab(
              label: 'Limpiar Filtro',
              icon: Icons.filter_alt_off_rounded,
              heroTag: 'fab_clear_filter',
              backgroundColor: AppColors.accent,
              onTap: () {
                _limpiarFiltro();
                setState(() => _showActions = false);
              },
            ),
          const SizedBox(height: 8),
          _SecondaryFab(
            label: _rangoFechas == null ? 'Filtrar por Fecha' : 'Editar Filtro',
            icon: Icons.calendar_month_rounded,
            heroTag: 'fab_filter',
            onTap: () {
              _seleccionarFiltroFechas();
              setState(() => _showActions = false);
            },
          ),
          const SizedBox(height: 8),
          _SecondaryFab(
            label: widget.proyecto.isActivo ? 'Finalizar Apartado' : 'Reactivar Apartado',
            icon: widget.proyecto.isActivo ? Icons.check_circle_outline : Icons.replay_circle_filled,
            heroTag: 'fab_status',
            onTap: () {
              final nuevoEstatus = widget.proyecto.isActivo ? 0 : 1;
              final proyectoActualizado = widget.proyecto.copyWith(estatus: nuevoEstatus);
              context.read<AppProvider>().actualizarProyecto(proyectoActualizado);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
          _SecondaryFab(
            label: 'Editar Apartado',
            icon: Icons.edit_rounded,
            heroTag: 'fab_edit',
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => DialogoNuevoProyecto(proyectoExistente: widget.proyecto),
              ).then((_) => setState(() {
                    _showActions = false;
                  }));
            },
          ),
          const SizedBox(height: 8),
          _SecondaryFab(
            label: 'Eliminar Todo',
            icon: Icons.delete_forever_rounded,
            heroTag: 'fab_delete',
            backgroundColor: AppColors.danger.withValues(alpha: 0.1),
            onTap: () => _confirmarEliminacion(context),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: 'fab_toggle_detalle',
              backgroundColor: Theme.of(context).cardColor,
              onPressed: () => setState(() => _showActions = !_showActions),
              child: Icon(_showActions ? Icons.close : Icons.tune_rounded),
            ),
            const SizedBox(width: 12),
            if (widget.proyecto.isActivo)
              FloatingActionButton.extended(
                heroTag: 'fab_add_pago',
                backgroundColor: color,
                onPressed: () => _mostrarDialogoAgregarPago(context),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Agregar pago', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
      ],
    );
  }

  void _mostrarDialogoAgregarPago(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => DialogoAgregarPago(proyectoId: widget.proyecto.id!),
    );
  }

  void _confirmarEliminacion(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar apartado?'),
        content: const Text('Se eliminará este apartado y TODO su historial de pagos. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () {
              context.read<AppProvider>().eliminarProyecto(widget.proyecto.id!);
              Navigator.pop(ctx); // Cierra diálogo
              Navigator.pop(context); // Sale de la pantalla de detalle
            },
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
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

// ─── Widget de resumen total ──────────────────────────────────────────────────

class _TotalCard extends StatelessWidget {
  final double total;
  final Color color;
  final int cantidadPagos;

  const _TotalCard({
    required this.total,
    required this.color,
    required this.cantidadPagos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Total Pagado',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppUtils.formatMonto(total),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '$cantidadPagos pago${cantidadPagos != 1 ? 's' : ''} registrado${cantidadPagos != 1 ? 's' : ''}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
        ],
      ),
    );
  }
}
