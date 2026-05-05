import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/gasto_fijo.dart';
import '../../providers/app_provider.dart';

class GastosFijosScreen extends StatelessWidget {
  const GastosFijosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fijos = context.watch<AppProvider>().gastosFijos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suscripciones'),
      ),
      body: fijos.isEmpty
          ? _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: fijos.length,
              itemBuilder: (context, index) {
                final fijo = fijos[index];
                return _GastoFijoCard(fijo: fijo);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoGastoFijo(context),
        icon: const Icon(Icons.add),
        label: const Text('Agregar Suscripción'),
      ),
    );
  }

  void _mostrarDialogoGastoFijo(BuildContext context, [GastoFijo? existente]) {
    showDialog(
      context: context,
      builder: (_) => DialogoGastoFijo(gastoExistente: existente),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.autorenew_rounded, size: 80, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Sin suscripciones',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Aquí puedes registrar tus pagos recurrentes\n(Netflix, Internet, Renta) para que se agreguen\nautomáticamente cada mes.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _GastoFijoCard extends StatelessWidget {
  final GastoFijo fijo;
  const _GastoFijoCard({required this.fijo});

  @override
  Widget build(BuildContext context) {
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: fijo.activo == 1 ? AppColors.primary.withValues(alpha: 0.1) : Theme.of(context).dividerColor.withValues(alpha: 0.5),
          child: Icon(AppUtils.getIcono(fijo.icono), color: fijo.activo == 1 ? AppColors.primary : Theme.of(context).disabledColor),
        ),
        title: Text(fijo.nombre, style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 0.5,
          color: fijo.activo == 1 ? Theme.of(context).textTheme.titleLarge?.color : Theme.of(context).disabledColor,
        )),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Día ${fijo.diaCobro} • ${fijo.metodoPago}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: fijo.activo == 1 ? Theme.of(context).textTheme.bodyMedium?.color : Theme.of(context).disabledColor,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: fijo.activo == 1 ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                AppUtils.formatMonto(fijo.monto), 
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: fijo.activo == 1 ? AppColors.primary : Theme.of(context).disabledColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: Theme.of(context).disabledColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'editar') {
                  showDialog(context: context, builder: (_) => DialogoGastoFijo(gastoExistente: fijo));
                } else if (val == 'toggle') {
                  context.read<AppProvider>().actualizarGastoFijo(fijo.copyWith(activo: fijo.activo == 1 ? 0 : 1));
                } else if (val == 'eliminar') {
                  context.read<AppProvider>().eliminarGastoFijo(fijo.id!);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'editar', child: Text('Editar')),
                PopupMenuItem(value: 'toggle', child: Text(fijo.activo == 1 ? 'Pausar' : 'Reactivar')),
                const PopupMenuItem(value: 'eliminar', child: Text('Eliminar', style: TextStyle(color: AppColors.danger))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DialogoGastoFijo extends StatefulWidget {
  final GastoFijo? gastoExistente;
  const DialogoGastoFijo({super.key, this.gastoExistente});

  @override
  State<DialogoGastoFijo> createState() => _DialogoGastoFijoState();
}

class _DialogoGastoFijoState extends State<DialogoGastoFijo> {
  final _formKey = GlobalKey<FormState>();
  String _nombre = '';
  double _monto = 0.0;
  int _diaCobro = 1;
  String _metodoPago = 'Efectivo';
  String _iconoSeleccionado = 'folder';

  @override
  void initState() {
    super.initState();
    if (widget.gastoExistente != null) {
      _nombre = widget.gastoExistente!.nombre;
      _monto = widget.gastoExistente!.monto;
      _diaCobro = widget.gastoExistente!.diaCobro;
      _metodoPago = widget.gastoExistente!.metodoPago;
      _iconoSeleccionado = widget.gastoExistente!.icono;
    }
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final prov = context.read<AppProvider>();
      final isNew = widget.gastoExistente == null;
      if (!isNew) {
        prov.actualizarGastoFijo(widget.gastoExistente!.copyWith(
          nombre: _nombre,
          monto: _monto,
          diaCobro: _diaCobro,
          metodoPago: _metodoPago,
          icono: _iconoSeleccionado,
        ));
      } else {
        prov.agregarGastoFijo(GastoFijo(
          nombre: _nombre,
          monto: _monto,
          diaCobro: _diaCobro,
          metodoPago: _metodoPago,
          icono: _iconoSeleccionado,
        ));
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isNew ? 'Suscripción guardada. Recordatorio programado.' : 'Suscripción actualizada.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.gastoExistente != null ? 'Editar Suscripción' : 'Nueva Suscripción',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 24),
                TextFormField(
                  initialValue: _nombre,
                  decoration: const InputDecoration(labelText: 'Nombre (Ej. Netflix)'),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  onSaved: (v) => _nombre = v!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _monto == 0 ? '' : _monto.toString(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Monto a pagar'),
                  validator: (v) => double.tryParse(v ?? '') == null ? 'Monto inválido' : null,
                  onSaved: (v) => _monto = double.parse(v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _diaCobro.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Día de cobro (1-31)'),
                  validator: (v) {
                    final d = int.tryParse(v ?? '');
                    if (d == null || d < 1 || d > 31) return 'Día inválido';
                    return null;
                  },
                  onSaved: (v) => _diaCobro = int.parse(v!),
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
                const SizedBox(height: 32),
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
