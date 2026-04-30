import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../models/deuda.dart';
import '../../../providers/app_provider.dart';

class DialogoNuevaDeuda extends StatefulWidget {
  final Deuda? deudaExistente;

  const DialogoNuevaDeuda({super.key, this.deudaExistente});

  @override
  State<DialogoNuevaDeuda> createState() => _DialogoNuevaDeudaState();
}

class _DialogoNuevaDeudaState extends State<DialogoNuevaDeuda> {
  final _formKey = GlobalKey<FormState>();
  late String _persona;
  late double _montoTotal;
  late int _tipo; // 0: Debo, 1: Me deben
  late String _notas;
  late int _totalCuotas;

  @override
  void initState() {
    super.initState();
    _persona = widget.deudaExistente?.persona ?? '';
    _montoTotal = widget.deudaExistente?.montoTotal ?? 0.0;
    _tipo = widget.deudaExistente?.tipo ?? 0;
    _notas = widget.deudaExistente?.notas ?? '';
    _totalCuotas = widget.deudaExistente?.totalCuotas ?? 1;
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final prov = context.read<AppProvider>();

      if (widget.deudaExistente != null) {
        prov.actualizarDeuda(widget.deudaExistente!.copyWith(
          persona: _persona,
          montoTotal: _montoTotal,
          tipo: _tipo,
          notas: _notas,
          totalCuotas: _totalCuotas,
        ));
      } else {
        prov.agregarDeuda(Deuda(
          persona: _persona,
          montoTotal: _montoTotal,
          tipo: _tipo,
          fecha: DateTime.now(),
          notas: _notas,
          totalCuotas: _totalCuotas,
        ));
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
                Text(
                  widget.deudaExistente != null ? 'Editar Préstamo' : 'Nuevo Préstamo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 24),
                
                // Selector de Tipo (Debo / Me deben)
                Row(
                  children: [
                    Expanded(
                      child: _ChoiceChip(
                        label: 'Le debo a...',
                        isSelected: _tipo == 0,
                        color: Colors.red,
                        onSelected: () => setState(() => _tipo = 0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ChoiceChip(
                        label: 'Me debe...',
                        isSelected: _tipo == 1,
                        color: Colors.green,
                        onSelected: () => setState(() => _tipo = 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  initialValue: _persona,
                  decoration: const InputDecoration(labelText: 'Nombre de la persona'),
                  validator: (v) => v!.isEmpty ? 'Ingresa un nombre' : null,
                  onSaved: (v) => _persona = v!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _montoTotal == 0 ? '' : _montoTotal.toString(),
                  decoration: const InputDecoration(labelText: 'Monto Total'),
                  keyboardType: TextInputType.number,
                  validator: (v) => double.tryParse(v ?? '') == null ? 'Monto inválido' : null,
                  onSaved: (v) => _montoTotal = double.parse(v!),
                ),
                const SizedBox(height: 16),
                
                // Campo de cuotas (para el ejemplo del reloj)
                TextFormField(
                  initialValue: _totalCuotas.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Número de pagos (cuotas)',
                    hintText: '1 para un solo pago',
                  ),
                  keyboardType: TextInputType.number,
                  onSaved: (v) => _totalCuotas = int.tryParse(v ?? '1') ?? 1,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  initialValue: _notas,
                  decoration: const InputDecoration(labelText: 'Notas / Concepto (Ej. Compra de reloj)'),
                  maxLines: 2,
                  onSaved: (v) => _notas = v!,
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

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onSelected;

  const _ChoiceChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.transparent),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
