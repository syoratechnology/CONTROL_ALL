import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../../../models/deuda.dart';
import '../../../models/abono_deuda.dart';
import '../../../providers/app_provider.dart';

class DetalleDeudaScreen extends StatefulWidget {
  final Deuda deuda;
  const DetalleDeudaScreen({super.key, required this.deuda});

  @override
  State<DetalleDeudaScreen> createState() => _DetalleDeudaScreenState();
}

class _DetalleDeudaScreenState extends State<DetalleDeudaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().cargarAbonosDeuda(widget.deuda.id!);
    });
  }

  void _mostrarDialogoAbono(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _DialogoAbonoDeuda(deuda: widget.deuda),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    // Buscar la deuda actualizada en la lista del provider
    final deudaActualizada = provider.deudas.firstWhere((d) => d.id == widget.deuda.id, orElse: () => widget.deuda);
    
    final saldo = deudaActualizada.montoTotal - deudaActualizada.montoPagado;
    final progreso = deudaActualizada.montoPagado / deudaActualizada.montoTotal;
    final color = deudaActualizada.meDeben ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text(deudaActualizada.persona),
      ),
      body: provider.cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Panel de Resumen ──────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
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
                      Text(deudaActualizada.meDeben ? 'Saldo por cobrar' : 'Saldo por pagar', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Text(
                        AppUtils.formatMonto(saldo),
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatItem(label: 'Total', value: AppUtils.formatMonto(deudaActualizada.montoTotal)),
                          _StatItem(label: 'Pagado', value: AppUtils.formatMonto(deudaActualizada.montoPagado), color: Colors.blue),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progreso,
                          minHeight: 10,
                          backgroundColor: color.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      if (deudaActualizada.totalCuotas > 1) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Plan de ${deudaActualizada.totalCuotas} pagos',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('HISTORIAL DE PAGOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                  ),
                ),

                // ── Lista de Abonos ───────────────────────────────────────────
                Expanded(
                  child: provider.abonosDeudaActual.isEmpty
                      ? Center(child: Text('No hay abonos registrados aún.', style: Theme.of(context).textTheme.bodyMedium))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: provider.abonosDeudaActual.length,
                          itemBuilder: (ctx, i) {
                            final abono = provider.abonosDeudaActual[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withValues(alpha: 0.1),
                                child: Icon(Icons.payment_rounded, color: color, size: 20),
                              ),
                              title: Text(AppUtils.formatMonto(abono.monto), style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${AppUtils.formatFechaCorta(abono.fecha)} ${abono.fecha.hour.toString().padLeft(2, '0')}:${abono.fecha.minute.toString().padLeft(2, '0')}${abono.nota.isNotEmpty ? ' • ${abono.nota}' : ''}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                                onPressed: () => provider.eliminarAbonoDeuda(abono),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: saldo > 0 
          ? FloatingActionButton.extended(
              onPressed: () => _mostrarDialogoAbono(context),
              icon: const Icon(Icons.add),
              label: const Text('Registrar Abono'),
            )
          : null,
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _DialogoAbonoDeuda extends StatefulWidget {
  final Deuda deuda;
  const _DialogoAbonoDeuda({required this.deuda});

  @override
  State<_DialogoAbonoDeuda> createState() => _DialogoAbonoDeudaState();
}

class _DialogoAbonoDeudaState extends State<_DialogoAbonoDeuda> {
  final _controller = TextEditingController();
  final _notaController = TextEditingController();
  DateTime _fechaSeleccionada = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Sugerir el monto de la cuota si hay cuotas pendientes
    final saldo = widget.deuda.montoTotal - widget.deuda.montoPagado;
    if (widget.deuda.totalCuotas > 1) {
      final cuota = widget.deuda.montoTotal / widget.deuda.totalCuotas;
      _controller.text = cuota.toStringAsFixed(2);
    } else {
      _controller.text = saldo.toStringAsFixed(2);
    }
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_fechaSeleccionada),
      );
      if (time != null) {
        setState(() {
          _fechaSeleccionada = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar Abono'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Monto del pago'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            // Botón selector de fecha/hora
            InkWell(
              onTap: () => _seleccionarFecha(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${AppUtils.formatFechaCorta(_fechaSeleccionada)} ${TimeOfDay.fromDateTime(_fechaSeleccionada).format(context)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notaController,
              decoration: const InputDecoration(labelText: 'Nota (opcional)'),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            final monto = double.tryParse(_controller.text);
            if (monto != null && monto > 0) {
              context.read<AppProvider>().agregarAbonoDeuda(AbonoDeuda(
                deudaId: widget.deuda.id!,
                monto: monto,
                fecha: _fechaSeleccionada,
                nota: _notaController.text,
              ));
              Navigator.pop(context);
            }
          },
          child: const Text('Registrar'),
        ),
      ],
    );
  }
}
