import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/proyecto.dart';
import '../../models/control_mensual.dart';
import '../../models/deuda.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../services/backup_service.dart';
import '../detalle/detalle_screen.dart';
import '../mensual/detalle_mes_screen.dart';
import '../deudas/detalle_deuda_screen.dart';
import '../mensual/gastos_fijos_screen.dart';
import '../baul/baul_screen.dart';
import 'widgets/dialogo_nuevo_proyecto.dart';
import 'widgets/dialogo_nueva_deuda.dart';

enum ViewType { apartados, elMes, deudas, baul }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  ViewType _currentView = ViewType.apartados;
  bool _showActions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().inicializar();
    });
  }

  void _mostrarDialogoNuevoProyecto(BuildContext context) {
    showDialog(context: context, builder: (_) => const DialogoNuevoProyecto());
  }

  void _mostrarDialogoNuevaDeuda(BuildContext context) {
    showDialog(context: context, builder: (ctx) => const DialogoNuevaDeuda());
  }

  void _mostrarDialogoNuevoMes(BuildContext context) {
    final ahora = DateTime.now();
    final mes = ahora.month;
    final anio = ahora.year;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Crear Control del Mes'),
        content: const Text(
          'Se creará el mes actual y se inyectarán todas tus suscripciones automáticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AppProvider>().crearControlMensual(mes, anio);
              Navigator.pop(ctx);
            },
            child: const Text('Crear Mes'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoRespaldo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Respaldo de Datos'),
        content: const Text(
          'Puedes exportar tus datos para guardarlos en otro lugar o restaurar un respaldo previo.\n\n⚠️ Al restaurar, se borrarán los datos actuales.',
        ),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.upload_rounded, color: AppColors.primary),
                title: const Text('Exportar Respaldo'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await BackupService.exportarBackup();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Respaldo exportado con éxito'),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_rounded, color: Colors.orange),
                title: const Text('Restaurar Respaldo'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final exito = await BackupService.importarBackup();
                  if (exito && context.mounted) {
                    await context.read<AppProvider>().inicializar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('¡Datos restaurados con éxito!'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Finanzas'),
        actions: [
          IconButton(
            icon: Icon(
              provider.themeMode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: () => provider.toggleTheme(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings_backup_restore_rounded),
            onPressed: () => _mostrarDialogoRespaldo(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Barra de Búsqueda Global ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: _currentView == ViewType.apartados
                    ? 'Buscar apartado...'
                    : _currentView == ViewType.elMes
                    ? 'Buscar mes o nota...'
                    : _currentView == ViewType.deudas
                    ? 'Buscar deuda o persona...'
                    : 'Buscar en la bóveda...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── Contenido ──────────────────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildViewContent(provider),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: ViewType.values.indexOf(_currentView),
        onTap: (index) => setState(() {
          _currentView = ViewType.values[index];
          _showActions = false;
        }),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.folder_rounded), label: 'Apartados'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Mensual'),
          BottomNavigationBarItem(icon: Icon(Icons.handshake_rounded), label: 'Préstamos'),
          BottomNavigationBarItem(icon: Icon(Icons.lock_rounded), label: 'Bóveda'),
        ],
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildFAB(BuildContext context) {
    // Si estamos en Apartados o Bóveda, el FAB es simple y directo
    if (_currentView == ViewType.apartados || _currentView == ViewType.baul) {
      return FloatingActionButton.extended(
        heroTag: 'fab_simple',
        onPressed: () {
          if (_currentView == ViewType.apartados) {
            _mostrarDialogoNuevoProyecto(context);
          } else {
            mostrarDialogoNuevoItemBaul(context);
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_currentView == ViewType.apartados ? 'Nuevo Apartado' : 'Agregar'),
      );
    }

    // En Mensual y Préstamos, usamos el FAB expandible
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_showActions) ...[
          if (_currentView == ViewType.elMes) ...[
            _SecondaryFab(
              label: 'Crear Control Mes',
              icon: Icons.calendar_today_rounded,
              heroTag: 'fab_new_month',
              onTap: () {
                _mostrarDialogoNuevoMes(context);
                setState(() => _showActions = false);
              },
            ),
            const SizedBox(height: 12),
            _SecondaryFab(
              label: 'Configurar Suscripciones',
              icon: Icons.settings_suggest_rounded,
              heroTag: 'fab_settings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GastosFijosScreen()),
                );
                setState(() => _showActions = false);
              },
            ),
          ] else if (_currentView == ViewType.deudas) ...[
            _SecondaryFab(
              label: 'Nuevo Préstamo',
              icon: Icons.handshake_rounded,
              heroTag: 'fab_new_loan',
              onTap: () {
                _mostrarDialogoNuevaDeuda(context);
                setState(() => _showActions = false);
              },
            ),
          ],
          const SizedBox(height: 12),
        ],
        FloatingActionButton(
          heroTag: 'fab_main_dynamic',
          onPressed: () => setState(() => _showActions = !_showActions),
          child: Icon(_showActions ? Icons.close : Icons.more_vert),
        ),
      ],
    );
  }

  Widget _buildViewContent(AppProvider provider) {
    if (provider.cargando) return const Center(child: CircularProgressIndicator());

    final query = _searchQuery.toLowerCase();

    if (_currentView == ViewType.apartados) {
      final proyectosFiltrados = provider.proyectos.where((p) {
        return p.nombre.toLowerCase().contains(query) || p.descripcion.toLowerCase().contains(query);
      }).toList();

      if (proyectosFiltrados.isEmpty) return const _EmptyState(type: ViewType.apartados);
      return _ProyectosList(proyectos: proyectosFiltrados);
    } else if (_currentView == ViewType.elMes) {
      const meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
      final controlesFiltrados = provider.controlesMensuales.where((c) {
        final nombreMes = meses[c.mes - 1].toLowerCase();
        final nota = c.notas.toLowerCase();
        return nombreMes.contains(query) || nota.contains(query) || c.anio.toString().contains(query);
      }).toList();

      if (controlesFiltrados.isEmpty) return const _EmptyState(type: ViewType.elMes);
      return _ControlesList(controles: controlesFiltrados);
    } else if (_currentView == ViewType.deudas) {
      final deudasFiltradas = provider.deudas.where((d) {
        final persona = d.persona.toLowerCase();
        final notas = d.notas.toLowerCase();
        return persona.contains(query) || notas.contains(query);
      }).toList();

      if (deudasFiltradas.isEmpty) return const _EmptyState(type: ViewType.deudas);
      return _DeudasList(deudas: deudasFiltradas);
    } else {
      return BaulScreenContent(searchQuery: _searchQuery);
    }
  }
}

class _SecondaryFab extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String heroTag;

  const _SecondaryFab({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton(
          heroTag: heroTag,
          mini: true,
          onPressed: onTap,
          backgroundColor: AppColors.primary,
          child: Icon(icon, color: Colors.white),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ViewType type;
  const _EmptyState({required this.type});

  @override
  Widget build(BuildContext context) {
    final isApartados = type == ViewType.apartados;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isApartados
                ? Icons.folder_open_rounded
                : type == ViewType.elMes
                ? Icons.calendar_today_rounded
                : type == ViewType.deudas
                ? Icons.handshake_rounded
                : Icons.lock_outline_rounded,
            size: 80,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            isApartados
                ? 'Sin proyectos todavía'
                : type == ViewType.elMes
                ? 'Sin registros mensuales'
                : type == ViewType.deudas
                ? 'Sin préstamos todavía'
                : 'La bóveda está vacía',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              isApartados
                  ? 'Crea uno para empezar a registrar tus gastos.'
                  : type == ViewType.elMes
                  ? 'Crea tu primer mes para gestionar tus suscripciones.'
                  : type == ViewType.deudas
                  ? 'Registra tus préstamos o deudas para llevar el control.'
                  : 'Guarda notas, contraseñas o archivos importantes aquí.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProyectosList extends StatelessWidget {
  final List<Proyecto> proyectos;
  const _ProyectosList({required this.proyectos});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: proyectos.length,
      itemBuilder: (context, index) => _ProyectoCard(proyecto: proyectos[index]),
    );
  }
}

class _ProyectoCard extends StatelessWidget {
  final Proyecto proyecto;
  const _ProyectoCard({required this.proyecto});

  @override
  Widget build(BuildContext context) {
    final color = Color(proyecto.colorHex);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(AppUtils.getIcono(proyecto.icono), color: color),
        ),
        title: Text(
          proyecto.nombre,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            decoration: proyecto.isActivo ? null : TextDecoration.lineThrough,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          proyecto.descripcion.isNotEmpty
              ? proyecto.descripcion
              : 'Sin descripción',
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (val) {
            if (val == 'edit') {
              showDialog(
                context: context,
                builder: (_) => DialogoNuevoProyecto(proyectoExistente: proyecto),
              );
            } else if (val == 'delete') {
              _confirmarEliminacionProyecto(context, proyecto);
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_rounded, size: 20), title: Text('Editar'), contentPadding: EdgeInsets.zero)),
            const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger), title: Text('Eliminar', style: TextStyle(color: AppColors.danger)), contentPadding: EdgeInsets.zero)),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetalleScreen(proyecto: proyecto)),
        ),
      ),
    );
  }

  void _confirmarEliminacionProyecto(BuildContext context, Proyecto proyecto) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Apartado?'),
        content: Text('Se borrará "${proyecto.nombre}" y todos sus gastos asociados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () {
              context.read<AppProvider>().eliminarProyecto(proyecto.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _DeudasList extends StatelessWidget {
  final List<Deuda> deudas;
  const _DeudasList({required this.deudas});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: deudas.length,
      itemBuilder: (context, index) => _DeudaCard(deuda: deudas[index]),
    );
  }
}

class _DeudaCard extends StatelessWidget {
  final Deuda deuda;
  const _DeudaCard({required this.deuda});

  @override
  Widget build(BuildContext context) {
    final color = deuda.meDeben ? Colors.green : Colors.red;
    final saldo = deuda.montoTotal - deuda.montoPagado;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetalleDeudaScreen(deuda: deuda)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(
                  deuda.meDeben
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deuda.persona,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      deuda.meDeben ? 'Me debe' : 'Le debo',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppUtils.formatMonto(saldo),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_vert_rounded, size: 20),
                        onSelected: (val) {
                          if (val == 'edit') {
                            showDialog(
                              context: context,
                              builder: (_) => DialogoNuevaDeuda(deudaExistente: deuda),
                            );
                          } else if (val == 'delete') {
                            _confirmarEliminacionDeuda(context, deuda);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_rounded, size: 20), title: Text('Editar'), contentPadding: EdgeInsets.zero)),
                          const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger), title: Text('Eliminar', style: TextStyle(color: AppColors.danger)), contentPadding: EdgeInsets.zero)),
                        ],
                      ),
                    ],
                  ),
                  if (deuda.totalCuotas > 1)
                    Text(
                      '${deuda.totalCuotas} cuotas',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarEliminacionDeuda(BuildContext context, Deuda deuda) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Préstamo?'),
        content: Text('Se borrará el registro de "${deuda.persona}" permanentemente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () {
              context.read<AppProvider>().eliminarDeuda(deuda.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _ControlesList extends StatelessWidget {
  final List<ControlMensual> controles;
  const _ControlesList({required this.controles});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controles.length,
      itemBuilder: (context, index) => _ControlCard(control: controles[index]),
    );
  }
}

class _ControlCard extends StatelessWidget {
  final ControlMensual control;
  const _ControlCard({required this.control});

  @override
  Widget build(BuildContext context) {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    final nombreMes = meses[control.mes - 1];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(
            Icons.calendar_month_rounded,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          '$nombreMes ${control.anio}',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          control.notas.isNotEmpty
              ? control.notas
              : 'Control de gastos mensuales',
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (val) {
            if (val == 'edit') {
              _mostrarDialogoEditarMes(context, control);
            } else if (val == 'delete') {
              _confirmarEliminacionMes(context, control);
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_rounded, size: 20), title: Text('Editar'), contentPadding: EdgeInsets.zero)),
            const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger), title: Text('Eliminar', style: TextStyle(color: AppColors.danger)), contentPadding: EdgeInsets.zero)),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetalleMesScreen(control: control)),
        ),
      ),
    );
  }

  void _mostrarDialogoEditarMes(BuildContext context, ControlMensual control) {
    final controller = TextEditingController(text: control.notas);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Notas del Mes'),
        content: TextFormField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Notas / Descripción'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              context.read<AppProvider>().actualizarControlMensual(
                control.copyWith(notas: controller.text.trim()),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminacionMes(BuildContext context, ControlMensual control) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Control del Mes?'),
        content: const Text('Se borrarán todos los gastos registrados en este mes. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () {
              context.read<AppProvider>().eliminarControlMensual(control.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
