import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../../../models/proyecto.dart';
import '../../../providers/app_provider.dart';

class DialogoNuevoProyecto extends StatefulWidget {
  final Proyecto? proyectoExistente;
  const DialogoNuevoProyecto({super.key, this.proyectoExistente});

  @override
  State<DialogoNuevoProyecto> createState() => _DialogoNuevoProyectoState();
}

class _DialogoNuevoProyectoState extends State<DialogoNuevoProyecto> {
  final _formKey = GlobalKey<FormState>();
  String _nombre = '';
  String _descripcion = '';
  int _colorSeleccionado = AppColors.proyectoColors.first.toARGB32();
  String _iconoSeleccionado = 'folder';

  @override
  void initState() {
    super.initState();
    if (widget.proyectoExistente != null) {
      _nombre = widget.proyectoExistente!.nombre;
      _descripcion = widget.proyectoExistente!.descripcion;
      _colorSeleccionado = widget.proyectoExistente!.colorHex;
      _iconoSeleccionado = widget.proyectoExistente!.icono;
    }
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      if (widget.proyectoExistente != null) {
        final actualizado = widget.proyectoExistente!.copyWith(
          nombre: _nombre,
          descripcion: _descripcion,
          colorHex: _colorSeleccionado,
          icono: _iconoSeleccionado,
        );
        context.read<AppProvider>().actualizarProyecto(actualizado);
      } else {
        final nuevoProyecto = Proyecto(
          nombre: _nombre,
          descripcion: _descripcion,
          colorHex: _colorSeleccionado,
          icono: _iconoSeleccionado,
          creadoEn: DateTime.now(),
          estatus: 1, // 1 = Activo
        );
        context.read<AppProvider>().agregarProyecto(nuevoProyecto);
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.proyectoExistente != null ? 'Editar Apartado' : 'Nuevo Apartado',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
              const SizedBox(height: 24),
              // Nombre
              TextFormField(
                initialValue: _nombre,
                decoration: const InputDecoration(
                  labelText: 'Nombre del apartado (Ej. Coche)',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
                onSaved: (v) => _nombre = v!.trim(),
              ),
              const SizedBox(height: 16),
              // Descripción
              TextFormField(
                initialValue: _descripcion,
                decoration: const InputDecoration(
                  labelText: 'Descripción / Notas (Opcional)',
                ),
                onSaved: (v) => _descripcion = v?.trim() ?? '',
              ),
              const SizedBox(height: 32),
              // Selector de Color
              Text('Color identificador',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: AppColors.proyectoColors.map((color) {
                  final isSelected = _colorSeleccionado == color.toARGB32();
                  return GestureDetector(
                    onTap: () => setState(() => _colorSeleccionado = color.toARGB32()),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Selector de Icono
              Text('Icono', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: AppUtils.iconosDisponibles.entries.map((entry) {
                  final isSelected = _iconoSeleccionado == entry.key;
                  return GestureDetector(
                    onTap: () => setState(() => _iconoSeleccionado = entry.key),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Icon(entry.value, 
                          color: isSelected ? AppColors.primary : Theme.of(context).disabledColor),
                    ),
                  );
                }).toList(),
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
                    child: Text(widget.proyectoExistente != null ? 'Guardar' : 'Crear'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
