import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppUtils {
  AppUtils._();

  /// Formatea un double como moneda (ej. $1,250.00)
  static String formatMonto(double monto) {
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    return fmt.format(monto);
  }

  /// Formatea una fecha como "15 de Enero 2025"
  static String formatFechaLarga(DateTime fecha) {
    final fmt = DateFormat("d 'de' MMMM yyyy", 'es');
    return fmt.format(fecha);
  }

  /// Formatea una fecha corta "15 Ene"
  static String formatFechaCorta(DateTime fecha) {
    final fmt = DateFormat("d MMM", 'es');
    return fmt.format(fecha);
  }

  /// Retorna el nombre del mes actual en español
  static String mesActual() {
    return DateFormat('MMMM yyyy', 'es').format(DateTime.now());
  }

  // Mapa de iconos disponibles para los proyectos
  static const Map<String, IconData> iconosDisponibles = {
    'folder': Icons.folder_rounded,
    'car': Icons.directions_car_rounded,
    'home': Icons.home_rounded,
    'flight': Icons.flight_takeoff_rounded,
    'shopping': Icons.shopping_cart_rounded,
    'health': Icons.favorite_rounded,
    'education': Icons.school_rounded,
    'food': Icons.restaurant_rounded,
    'devices': Icons.devices_rounded,
    'card': Icons.credit_card_rounded,
    'savings': Icons.savings_rounded,
    'pets': Icons.pets_rounded,
  };


  /// Devuelve el icono correspondiente al string, o un folder por defecto
  static IconData getIcono(String nombre) {
    return iconosDisponibles[nombre] ?? Icons.folder_rounded;
  }
}
