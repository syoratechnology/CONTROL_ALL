import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../../../models/pago.dart';
import '../../../providers/app_provider.dart';

class DialogoAgregarPago extends StatefulWidget {
  final int proyectoId;
  final Pago? pagoExistente;
  const DialogoAgregarPago({super.key, required this.proyectoId, this.pagoExistente});

  @override
  State<DialogoAgregarPago> createState() => _DialogoAgregarPagoState();
}

class _DialogoAgregarPagoState extends State<DialogoAgregarPago> {
  final _formKey = GlobalKey<FormState>();
  
  double _monto = 0.0;
  String _notas = '';
  DateTime _fechaSeleccionada = DateTime.now();
  String _metodoPago = 'Efectivo';
  
  final List<String> _metodos = ['Efectivo', 'Tarjeta de Débito', 'Tarjeta de Crédito', 'Transferencia', 'Otro'];

  @override
  void initState() {
    super.initState();
    if (widget.pagoExistente != null) {
      _monto = widget.pagoExistente!.monto;
      _notas = widget.pagoExistente!.notas;
      _fechaSeleccionada = widget.pagoExistente!.fecha;
      _metodoPago = widget.pagoExistente!.metodoPago;
    }
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? seleccion = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (seleccion != null) {
      final TimeOfDay? horaSeleccionada = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_fechaSeleccionada),
      );
      if (horaSeleccionada != null) {
        setState(() {
          _fechaSeleccionada = DateTime(
            seleccion.year,
            seleccion.month,
            seleccion.day,
            horaSeleccionada.hour,
            horaSeleccionada.minute,
          );
        });
      }
    }
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      if (widget.pagoExistente != null) {
        final actualizado = widget.pagoExistente!.copyWith(
          monto: _monto,
          fecha: _fechaSeleccionada,
          metodoPago: _metodoPago,
          notas: _notas,
        );
        context.read<AppProvider>().actualizarPago(actualizado);
      } else {
        final nuevoPago = Pago(
          proyectoId: widget.proyectoId,
          monto: _monto,
          fecha: _fechaSeleccionada,
          metodoPago: _metodoPago,
          notas: _notas,
          creadoEn: DateTime.now(),
        );
        context.read<AppProvider>().agregarPago(nuevoPago);
      }
      Navigator.pop(context);
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
                Text(widget.pagoExistente != null ? 'Editar Abono' : 'Abonar / Agregar Pago',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                const SizedBox(height: 24),
                
                // Monto
                TextFormField(
                  initialValue: _monto == 0.0 ? '' : _monto.toString(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monto (\$)',
                    prefixText: '\$ ',
                    prefixStyle: TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa un monto';
                    if (double.tryParse(v) == null) return 'Monto inválido';
                    return null;
                  },
                  onSaved: (v) => _monto = double.parse(v!),
                ),
                const SizedBox(height: 24),

                // Fecha Picker
                GestureDetector(
                  onTap: () => _seleccionarFecha(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fecha de pago', style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 4),
                            Text(
                              '${AppUtils.formatFechaLarga(_fechaSeleccionada)} ${TimeOfDay.fromDateTime(_fechaSeleccionada).format(context)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Método de Pago
                DropdownButtonFormField<String>(
                  initialValue: _metodoPago,
                  decoration: const InputDecoration(
                    labelText: 'Método de pago',
                  ),
                  items: _metodos.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setState(() => _metodoPago = v!),
                ),
                const SizedBox(height: 16),

                // Notas
                TextFormField(
                  initialValue: _notas,
                  decoration: const InputDecoration(
                    labelText: 'Notas adicionales (Opcional)',
                  ),
                  onSaved: (v) => _notas = v?.trim() ?? '',
                ),
                const SizedBox(height: 32),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _guardar,
                      child: Text(widget.pagoExistente != null ? 'Guardar Cambios' : 'Guardar Abono'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
