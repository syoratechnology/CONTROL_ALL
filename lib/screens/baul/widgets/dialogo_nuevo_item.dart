import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/baul_item.dart';
import '../../../providers/app_provider.dart';
import '../../../core/theme.dart';

class DialogoNuevoItem extends StatefulWidget {
  const DialogoNuevoItem({super.key});

  @override
  State<DialogoNuevoItem> createState() => _DialogoNuevoItemState();
}

class _DialogoNuevoItemState extends State<DialogoNuevoItem> {
  final _formKey = GlobalKey<FormState>();
  String _titulo = '';
  String _tipo = 'password';

  final List<TextEditingController> _labelControllers = [];
  final List<TextEditingController> _valueControllers = [];
  final List<bool> _isSecretList = [];

  @override
  void initState() {
    super.initState();
    _inicializarCampos();
  }

  void _inicializarCampos() {
    // Limpiar campos anteriores
    for (var c in _labelControllers) {
      c.dispose();
    }
    for (var c in _valueControllers) {
      c.dispose();
    }
    _labelControllers.clear();
    _valueControllers.clear();
    _isSecretList.clear();

    if (_tipo == 'password') {
      _addCampo(label: 'Usuario');
      _addCampo(label: 'Contraseña', secret: true);
    } else {
      _addCampo(label: 'Nota');
    }
  }

  void _addCampo({String label = '', bool secret = false}) {
    setState(() {
      _labelControllers.add(TextEditingController(text: label));
      _valueControllers.add(TextEditingController());
      _isSecretList.add(secret);
    });
  }

  void _removeCampo(int index) {
    if (_labelControllers.length > 1) {
      setState(() {
        _labelControllers[index].dispose();
        _valueControllers[index].dispose();
        _labelControllers.removeAt(index);
        _valueControllers.removeAt(index);
        _isSecretList.removeAt(index);
      });
    }
  }

  @override
  void dispose() {
    for (var c in _labelControllers) {
      c.dispose();
    }
    for (var c in _valueControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final nuevoItem = BaulItem(
        titulo: _titulo,
        tipo: _tipo,
        fechaCreacion: DateTime.now(),
      );

      final campos = <BaulCampo>[];
      for (int i = 0; i < _labelControllers.length; i++) {
        if (_valueControllers[i].text.isNotEmpty) {
          campos.add(
            BaulCampo(
              itemId: 0, // Se asigna en el provider
              etiqueta: _labelControllers[i].text.isEmpty
                  ? 'Nota'
                  : _labelControllers[i].text,
              valor: _valueControllers[i].text,
              esSecreto: _isSecretList[i],
            ),
          );
        }
      }

      context.read<AppProvider>().agregarBaulItem(nuevoItem, campos);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _tipo,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de entrada',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'password',
                      child: Text('Contraseñas'),
                    ),
                    DropdownMenuItem(value: 'nota', child: Text('Notas')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _tipo = v!;
                      _inicializarCampos();
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Título General',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  onSaved: (v) => _titulo = v!,
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Campos / Notas',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: AppColors.primary,
                      ),
                      onPressed: _addCampo,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(
                  _labelControllers.length,
                  (index) => _buildCampoRow(index),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _guardar, child: const Text('Guardar Todo')),
      ],
    );
  }

  Widget _buildCampoRow(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _labelControllers[index],
                  decoration: const InputDecoration(
                    hintText: 'Etiqueta (ej. Usuario)',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _isSecretList[index]
                      ? Icons.lock_rounded
                      : Icons.lock_open_rounded,
                  size: 20,
                  color: _isSecretList[index] ? Colors.orange : Colors.grey,
                ),
                onPressed: () => setState(
                  () => _isSecretList[index] = !_isSecretList[index],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => _removeCampo(index),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _valueControllers[index],
            obscureText: _isSecretList[index],
            decoration: const InputDecoration(
              hintText: 'Contenido / Nota / Clave',
              isDense: true,
            ),
            maxLines: _isSecretList[index] ? 1 : null,
            validator: (v) => index == 0 && (v == null || v.isEmpty)
                ? 'Al menos un valor'
                : null,
          ),
          const Divider(),
        ],
      ),
    );
  }
}
