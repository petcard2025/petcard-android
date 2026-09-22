// ============================================================
// APP EVENTS - Bus de eventos muy simple entre pestañas
// ============================================================
//
// MainNavScreen mantiene todas las pestañas vivas al mismo tiempo
// (IndexedStack), así que cuando el usuario registra/edita/elimina una
// mascota desde "Mis Mascotas", las pestañas de "Citas", "Servicios" e
// "Inicio" ya están cargadas en memoria con los datos viejos y no se
// enteran del cambio por sí solas.
//
// Este objeto es un singleton global: cualquier pantalla puede avisar
// "las mascotas cambiaron" (notificarMascotasCambiaron) y cualquier
// otra pantalla puede suscribirse (mascotasCambiaron.addListener) para
// recargar sus datos apenas eso ocurra, sin que el usuario tenga que
// cambiar de pestaña ni cerrar sesión.
import 'package:flutter/foundation.dart';

class AppEvents {
  AppEvents._();
  static final AppEvents instance = AppEvents._();

  /// Cambia cada vez que se crea, edita o elimina una mascota.
  /// El valor en sí no importa, solo sirve para disparar a los listeners.
  final ValueNotifier<int> mascotasCambiaron = ValueNotifier<int>(0);

  void notificarMascotasCambiaron() {
    mascotasCambiaron.value++;
  }
}