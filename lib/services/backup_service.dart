import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class BackupService {
  static const String dbName = 'control_gastos_v2.db';

  /// Exporta la base de datos compartiéndola a través del menú nativo.
  static Future<void> exportarBackup() async {
    try {
      final dbFolder = await getDatabasesPath();
      final dbPath = join(dbFolder, dbName);
      final file = File(dbPath);

      if (await file.exists()) {
        final tempDir = await getTemporaryDirectory();
        final backupPath = join(tempDir.path, 'backup_control_g_${DateTime.now().millisecondsSinceEpoch}.db');
        
        // Copiar a temp para compartir
        await file.copy(backupPath);

        await Share.shareXFiles(
          [XFile(backupPath)],
          subject: 'Backup de Control de Gastos',
          text: 'Aquí tienes tu respaldo de datos de Control G.',
        );
      }
    } catch (e) {
      print('Error al exportar backup: $e');
      rethrow;
    }
  }

  /// Importa una base de datos seleccionada por el usuario.
  /// ¡Atención!: Esto sobrescribe los datos actuales.
  static Future<bool> importarBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // SQLite no siempre tiene extensión reconocida
      );

      if (result != null && result.files.single.path != null) {
        final selectedPath = result.files.single.path!;
        
        // Validar que sea un archivo de base de datos (mínimo por extensión o nombre opcional)
        // Por ahora confiamos en el usuario o podemos checar la firma del archivo.

        final dbFolder = await getDatabasesPath();
        final dbPath = join(dbFolder, dbName);

        // 1. Cerrar conexión actual
        await DatabaseService.instance.closeDatabase();

        // 2. Sobrescribir archivo
        final selectedFile = File(selectedPath);
        await selectedFile.copy(dbPath);

        return true;
      }
      return false;
    } catch (e) {
      print('Error al importar backup: $e');
      rethrow;
    }
  }
}
