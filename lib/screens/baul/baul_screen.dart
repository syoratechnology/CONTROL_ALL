import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/baul_item.dart';
import '../../providers/app_provider.dart';
import '../../core/theme.dart';
import 'detalle_item_screen.dart';
import 'widgets/dialogo_nuevo_item.dart';

class BaulScreenContent extends StatefulWidget {
  final String searchQuery;
  const BaulScreenContent({super.key, required this.searchQuery});

  @override
  State<BaulScreenContent> createState() => _BaulScreenContentState();
}

class _BaulScreenContentState extends State<BaulScreenContent> {
  String? _filtroTipo; // null para 'Todos'

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    final itemsFiltrados = provider.baulItems.where((i) {
      // Filtro por búsqueda
      final cumpleBusqueda = i.titulo.toLowerCase().contains(widget.searchQuery.toLowerCase());
      
      // Filtro por tipo
      final cumpleTipo = _filtroTipo == null || i.tipo == _filtroTipo;
      
      return cumpleBusqueda && cumpleTipo;
    }).toList();

    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: itemsFiltrados.isEmpty 
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: itemsFiltrados.length,
                itemBuilder: (ctx, i) => _BaulItemCard(item: itemsFiltrados[i]),
              ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _FilterChip(
            label: 'Todos',
            isSelected: _filtroTipo == null,
            onTap: () => setState(() => _filtroTipo = null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Contraseñas',
            icon: Icons.password_rounded,
            isSelected: _filtroTipo == 'password',
            onTap: () => setState(() => _filtroTipo = 'password'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Notas',
            icon: Icons.note_alt_rounded,
            isSelected: _filtroTipo == 'nota',
            onTap: () => setState(() => _filtroTipo = 'nota'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: 80, color: Theme.of(context).disabledColor),
          const SizedBox(height: 16),
          Text(
            _filtroTipo == null ? 'El baúl está vacío' : 'No hay elementos de este tipo',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      avatar: icon != null ? Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.primary) : null,
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Theme.of(context).cardColor,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _BaulItemCard extends StatelessWidget {
  final BaulItem item;
  const _BaulItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (item.tipo) {
      case 'password':
        icon = Icons.password_rounded;
        color = Colors.orange;
        break;
      default:
        icon = Icons.note_alt_rounded;
        color = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(item.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.3)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(item.tipo.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: Theme.of(context).disabledColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (val) {
            if (val == 'edit') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleItemBaul(item: item)));
            } else if (val == 'delete') {
              _confirmarEliminacionItem(context, item);
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_rounded, size: 20), title: Text('Editar'), contentPadding: EdgeInsets.zero)),
            const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger), title: Text('Eliminar', style: TextStyle(color: AppColors.danger)), contentPadding: EdgeInsets.zero)),
          ],
        ),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleItemBaul(item: item)));
        },
      ),
    );
  }

  void _confirmarEliminacionItem(BuildContext context, BaulItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar de la Bóveda?'),
        content: Text('Se borrará "${item.titulo}" y todo su contenido de forma permanente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () {
              context.read<AppProvider>().eliminarBaulItem(item.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

void mostrarDialogoNuevoItemBaul(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => const DialogoNuevoItem(),
  );
}
