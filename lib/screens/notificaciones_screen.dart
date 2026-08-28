import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  static const Color kBlue = Color(0xFF2563EB);

  List<Map<String, dynamic>> _notificaciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final lista = await NotificationService().getHistorial();
    if (!mounted) return;
    setState(() {
      _notificaciones = lista;
      _isLoading = false;
    });
  }

  String _formatoFecha(String iso) {
    try {
      final fecha = DateTime.parse(iso);
      final mes = [
        '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      final h = fecha.hour > 12 ? fecha.hour - 12 : fecha.hour;
      final ampm = fecha.hour >= 12 ? 'PM' : 'AM';
      final min = fecha.minute.toString().padLeft(2, '0');
      return '${fecha.day} ${mes[fecha.month]} ${fecha.year}, ${h == 0 ? 12 : h}:$min $ampm';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: kBlue,
        elevation: 0,
        title: const Text(
          'PETCARD',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_notificaciones.isNotEmpty) ...[
            TextButton(
              onPressed: () async {
                await NotificationService().marcarTodasLeidas();
                await _cargar();
              },
              child: const Text(
                'Leer todas',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white70),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Limpiar historial'),
                    content: const Text(
                        'Eliminar todas las notificaciones y recordatorios programados?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Eliminar',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await NotificationService().limpiarHistorial();
                  await _cargar();
                }
              },
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kBlue))
          : _notificaciones.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Sin notificaciones',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Se mostraran aqui cuando crees\ncitas o planes de alimentacion',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: kBlue,
                  onRefresh: _cargar,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notificaciones.length,
                    itemBuilder: (context, index) {
                      final notif = _notificaciones[index];
                      final leida = notif['leida'] == true;
                      final titulo = notif['titulo'] ?? 'Notificacion';
                      final mensaje = notif['mensaje'] ?? '';
                      final fecha = notif['fecha'] ?? '';

                      IconData icono = Icons.notifications;
                      Color iconoColor = kBlue;
                      if (titulo.toLowerCase().contains('cita')) {
                        icono = Icons.event;
                        iconoColor = const Color(0xFF10B981);
                      } else if (titulo.toLowerCase().contains('alimentacion') ||
                          titulo.toLowerCase().contains('dieta')) {
                        icono = Icons.restaurant;
                        iconoColor = const Color(0xFFF59E0B);
                      } else if (titulo.toLowerCase().contains('vacuna')) {
                        icono = Icons.vaccines;
                        iconoColor = const Color(0xFF8B5CF6);
                      }

                      return Dismissible(
                        key: Key('notif_$index'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.redAccent,
                          child: const Icon(Icons.delete,
                              color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          final lista =
                              await NotificationService().getHistorial();
                          if (index < lista.length) {
                            lista.removeAt(index);
                            final prefs =
                                await SharedPreferences.getInstance();
                            await prefs.setString(
                              'petcard_notificaciones_historial',
                              jsonEncode(lista),
                            );
                          }
                          await _cargar();
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          elevation: leida ? 0 : 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: leida
                                ? BorderSide.none
                                : const BorderSide(
                                    color: kBlue, width: 0.5),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  iconoColor.withOpacity(0.1),
                              child: Icon(icono, color: iconoColor, size: 22),
                            ),
                            title: Text(
                              titulo,
                              style: TextStyle(
                                fontWeight: leida
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              mensaje,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!leida)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: kBlue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatoFecha(fecha),
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                            onTap: () async {
                              if (!leida) {
                                await NotificationService()
                                    .marcarLeida(index);
                                await _cargar();
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
