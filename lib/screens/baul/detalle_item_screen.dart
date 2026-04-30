import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/baul_item.dart';
import '../../models/baul_archivo.dart';
import '../../providers/app_provider.dart';
import '../../core/theme.dart';

class DetalleItemBaul extends StatefulWidget {
  final BaulItem item;
  const DetalleItemBaul({super.key, required this.item});

  @override
  State<DetalleItemBaul> createState() => _DetalleItemBaulState();
}

class _DetalleItemBaulState extends State<DetalleItemBaul> {
  final Set<int> _camposRevelados = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().cargarDetalleItem(widget.item.id!);
    });
  }

  Future<void> _adjuntarArchivo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      final pickedPath = result.files.single.path!;
      final nombre = result.files.single.name;
      final extension = p.extension(pickedPath);
      final tamano = result.files.single.size;

      final appDir = await getApplicationDocumentsDirectory();
      final vaultDir = Directory('${appDir.path}/vault_files');
      if (!await vaultDir.exists()) await vaultDir.create(recursive: true);
      
      final nuevaRuta = '${vaultDir.path}/${DateTime.now().millisecondsSinceEpoch}_$nombre';
      await File(pickedPath).copy(nuevaRuta);

      final nuevoArchivo = BaulArchivo(
        itemId: widget.item.id!,
        nombre: nombre,
        rutaLocal: nuevaRuta,
        extension: extension,
        tamano: tamano,
      );

      if (mounted) {
        await context.read<AppProvider>().agregarArchivoBaul(nuevoArchivo);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.titulo),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            onPressed: () => _confirmarEliminacion(context),
          ),
        ],
      ),
      body: provider.cargando 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Lista de Campos (Notas/Claves) ──────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Información Guardada', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: () => _mostrarDialogoNuevoCampo(context),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        label: const Text('Nuevo Campo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...provider.camposItemActual.map((campo) => _buildCampoCard(campo)),
                  
                  const SizedBox(height: 32),
                  
                  // ── Archivos Adjuntos ──────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Archivos y Documentos', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: _adjuntarArchivo,
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('Añadir'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (provider.archivosItemActual.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text('No hay archivos adjuntos.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ),
                    )
                  else
                    ...provider.archivosItemActual.map((archivo) => _buildArchivoCard(archivo, provider)),
                ],
              ),
            ),
    );
  }

  Widget _buildCampoCard(BaulCampo campo) {
    final revelado = !campo.esSecreto || _camposRevelados.contains(campo.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(campo.etiqueta, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                Row(
                  children: [
                    if (campo.esSecreto)
                      IconButton(
                        icon: Icon(revelado ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                        onPressed: () {
                          setState(() {
                            if (_camposRevelados.contains(campo.id)) {
                              _camposRevelados.remove(campo.id);
                            } else {
                              _camposRevelados.add(campo.id!);
                            }
                          });
                        },
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: campo.valor));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copiado: ${campo.etiqueta}'), duration: const Duration(seconds: 1)));
                      },
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                      onPressed: () => context.read<AppProvider>().eliminarCampoBaul(campo.id!, widget.item.id!),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              revelado ? campo.valor : '••••••••',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: campo.esSecreto ? 'monospace' : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivoCard(BaulArchivo archivo, AppProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _buildFileIcon(archivo.extension),
        title: Text(archivo.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
        subtitle: Text('${(archivo.tamano / 1024).toStringAsFixed(1)} KB', style: const TextStyle(fontSize: 11)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.share_rounded, size: 20),
              onPressed: () => Share.shareXFiles([XFile(archivo.rutaLocal)], text: archivo.nombre),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
              onPressed: () => provider.eliminarArchivoBaul(archivo.id!, widget.item.id!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileIcon(String ext) {
    IconData icon = Icons.insert_drive_file_rounded;
    Color color = Colors.grey;
    final e = ext.toLowerCase();
    if (e.contains('pdf')) { icon = Icons.picture_as_pdf_rounded; color = Colors.red; }
    else if (e.contains('jpg') || e.contains('png') || e.contains('jpeg')) { icon = Icons.image_rounded; color = Colors.green; }
    else if (e.contains('zip') || e.contains('rar')) { icon = Icons.folder_zip_rounded; color = Colors.orange; }
    return Icon(icon, color: color);
  }

  void _mostrarDialogoNuevoCampo(BuildContext context) {
    String etiqueta = '';
    String valor = '';
    bool esSecreto = widget.item.tipo == 'password';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Añadir Información'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Etiqueta (ej. Pin, Correo)'),
                onChanged: (v) => etiqueta = v,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(labelText: 'Valor / Contenido'),
                onChanged: (v) => valor = v,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('¿Es secreto?', style: TextStyle(fontSize: 14)),
                value: esSecreto,
                onChanged: (v) => setDialogState(() => esSecreto = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (valor.isNotEmpty) {
                  final nuevoCampo = BaulCampo(
                    itemId: widget.item.id!,
                    etiqueta: etiqueta.isEmpty ? 'Nota' : etiqueta,
                    valor: valor,
                    esSecreto: esSecreto,
                  );
                  context.read<AppProvider>().agregarCampoBaul(nuevoCampo);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminacion(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar este registro?'),
        content: const Text('Se borrarán todos los campos y archivos adjuntos permanentemente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () {
              context.read<AppProvider>().eliminarBaulItem(widget.item.id!);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
