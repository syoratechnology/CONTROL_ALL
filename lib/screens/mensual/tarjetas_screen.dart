import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/tarjeta.dart';
import '../../providers/app_provider.dart';

class TarjetasScreenContent extends StatelessWidget {
  final List<Tarjeta> tarjetas;
  const TarjetasScreenContent({super.key, required this.tarjetas});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tarjetas.length,
      itemBuilder: (context, index) {
        final tarjeta = tarjetas[index];
        return _TarjetaCard(tarjeta: tarjeta);
      },
    );
  }
}

// Se quitó _EmptyState porque el Dashboard lo maneja.

class _TarjetaCard extends StatelessWidget {
  final Tarjeta tarjeta;
  const _TarjetaCard({required this.tarjeta});

  @override
  Widget build(BuildContext context) {
    final isCredito = tarjeta.tipo == 'Crédito';
    // Colores basados en el tipo de tarjeta
    final gradientColors = isCredito
        ? [const Color(0xFF6A11CB), const Color(0xFF2575FC)]
        : [const Color(0xFF11998E), const Color(0xFF38EF7D)];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tarjeta.tipo.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 12,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
                    onSelected: (val) {
                      if (val == 'editar') {
                        showDialog(
                          context: context,
                          builder: (_) => DialogoTarjeta(tarjetaExistente: tarjeta),
                        );
                      } else if (val == 'eliminar') {
                        context.read<AppProvider>().eliminarTarjeta(tarjeta.id!);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'editar', child: Text('Editar')),
                      const PopupMenuItem(
                          value: 'eliminar',
                          child: Text('Eliminar', style: TextStyle(color: AppColors.danger))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                tarjeta.nombre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              if (isCredito && tarjeta.diaCorte != null && tarjeta.diaLimite != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _InfoDato(label: 'CORTE', valor: 'Día ${tarjeta.diaCorte}'),
                    _InfoDato(label: 'LÍMITE PAGO', valor: 'Día ${tarjeta.diaLimite}'),
                  ],
                )
              else if (!isCredito)
                const _InfoDato(label: 'USO', valor: 'Fondos Propios'),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoDato extends StatelessWidget {
  final String label;
  final String valor;
  const _InfoDato({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class DialogoTarjeta extends StatefulWidget {
  final Tarjeta? tarjetaExistente;
  const DialogoTarjeta({super.key, this.tarjetaExistente});

  @override
  State<DialogoTarjeta> createState() => _DialogoTarjetaState();
}

class _DialogoTarjetaState extends State<DialogoTarjeta> {
  final _formKey = GlobalKey<FormState>();
  String _nombre = '';
  String _tipo = 'Débito';
  String _diaCorteStr = '';
  String _diaLimiteStr = '';

  final _tipos = ['Débito', 'Crédito'];

  @override
  void initState() {
    super.initState();
    if (widget.tarjetaExistente != null) {
      _nombre = widget.tarjetaExistente!.nombre;
      _tipo = widget.tarjetaExistente!.tipo;
      if (widget.tarjetaExistente!.diaCorte != null) {
        _diaCorteStr = widget.tarjetaExistente!.diaCorte.toString();
      }
      if (widget.tarjetaExistente!.diaLimite != null) {
        _diaLimiteStr = widget.tarjetaExistente!.diaLimite.toString();
      }
    }
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      int? corte = _tipo == 'Crédito' ? int.tryParse(_diaCorteStr) : null;
      int? limite = _tipo == 'Crédito' ? int.tryParse(_diaLimiteStr) : null;

      final tarjeta = Tarjeta(
        id: widget.tarjetaExistente?.id,
        nombre: _nombre,
        tipo: _tipo,
        diaCorte: corte,
        diaLimite: limite,
      );

      final prov = context.read<AppProvider>();
      if (widget.tarjetaExistente != null) {
        prov.actualizarTarjeta(tarjeta);
      } else {
        prov.agregarTarjeta(tarjeta);
      }
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
                Text(
                  widget.tarjetaExistente != null ? 'Editar Tarjeta' : 'Nueva Tarjeta',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  initialValue: _nombre,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nombre (Ej. Crédito Nu, BBVA)'),
                  validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                  onSaved: (v) => _nombre = v!.trim(),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _tipo,
                  decoration: const InputDecoration(labelText: 'Tipo de Tarjeta'),
                  items: _tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) {
                    setState(() {
                      _tipo = v!;
                      if (_tipo == 'Débito') {
                        _diaCorteStr = '';
                        _diaLimiteStr = '';
                      }
                    });
                  },
                ),
                if (_tipo == 'Crédito') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _diaCorteStr,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Día de corte'),
                          validator: (v) {
                            if (_tipo == 'Crédito') {
                              final d = int.tryParse(v ?? '');
                              if (d == null || d < 1 || d > 31) return 'Inválido';
                            }
                            return null;
                          },
                          onSaved: (v) => _diaCorteStr = v ?? '',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          initialValue: _diaLimiteStr,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Día límite'),
                          validator: (v) {
                            if (_tipo == 'Crédito') {
                              final d = int.tryParse(v ?? '');
                              if (d == null || d < 1 || d > 31) return 'Inválido';
                            }
                            return null;
                          },
                          onSaved: (v) => _diaLimiteStr = v ?? '',
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
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
