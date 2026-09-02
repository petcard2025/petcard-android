// ============================================================
// SERVICIOS CRUD PETCARD - Supabase Flutter
// ============================================================

import 'supabase_client.dart';
import 'models.dart';

// ─────────────────────────────────────────────────────────────
// USUARIO
// ─────────────────────────────────────────────────────────────
class UsuarioService {
  Future<List<Usuario>> getAll() async {
    final response = await supabase.from('usuario').select();
    return (response as List).map((e) => Usuario.fromJson(e)).toList();
  }

  Future<Usuario?> getById(int id) async {
    final response = await supabase.from('usuario').select().eq('ID_usuario', id).single();
    return response != null ? Usuario.fromJson(response) : null;
  }

  Future<Usuario?> getByCorreo(String correo) async {
    final response = await supabase.from('usuario').select().eq('Correo', correo).single();
    return response != null ? Usuario.fromJson(response) : null;
  }

  Future<void> insert(Usuario usuario) async {
    await supabase.from('usuario').insert(usuario.toJsonInsert());
  }

  Future<void> update(Usuario usuario) async {
    await supabase.from('usuario').update(usuario.toJsonInsert()).eq('ID_usuario', usuario.idUsuario);
  }

  Future<void> delete(int id) async {
    await supabase.from('usuario').delete().eq('ID_usuario', id);
  }
}

// ─────────────────────────────────────────────────────────────
// CLIENTE
// ─────────────────────────────────────────────────────────────
class ClienteService {
  Future<List<Cliente>> getAll() async {
    final response = await supabase.from('cliente').select();
    return (response as List).map((e) => Cliente.fromJson(e)).toList();
  }

  Future<Cliente?> getById(int id) async {
    final response = await supabase.from('cliente').select().eq('ID_cliente', id).single();
    return response != null ? Cliente.fromJson(response) : null;
  }

  Future<Cliente?> getByUsuario(int idUsuario) async {
    final response = await supabase.from('cliente').select().eq('ID_usuario', idUsuario).single();
    return response != null ? Cliente.fromJson(response) : null;
  }

  Future<void> insert(Cliente cliente) async {
    await supabase.from('cliente').insert(cliente.toJsonInsert());
  }

  Future<void> update(Cliente cliente) async {
    await supabase.from('cliente').update(cliente.toJsonInsert()).eq('ID_cliente', cliente.idCliente);
  }

  Future<void> delete(int id) async {
    await supabase.from('cliente').delete().eq('ID_cliente', id);
  }
}

// ─────────────────────────────────────────────────────────────
// MASCOTA
// ─────────────────────────────────────────────────────────────
class MascotaService {
  Future<List<Mascota>> getAll() async {
    final response = await supabase.from('mascota').select();
    return (response as List).map((e) => Mascota.fromJson(e)).toList();
  }

  Future<Mascota?> getById(int id) async {
    final response = await supabase.from('mascota').select().eq('ID_mascota', id).single();
    return response != null ? Mascota.fromJson(response) : null;
  }

  Future<List<Mascota>> getByCliente(int idCliente) async {
    final response = await supabase.from('mascota').select().eq('ID_cliente', idCliente);
    return (response as List).map((e) => Mascota.fromJson(e)).toList();
  }

  Future<void> insert(Mascota mascota) async {
    await supabase.from('mascota').insert(mascota.toJsonInsert());
  }

  Future<void> update(Mascota mascota) async {
    await supabase.from('mascota').update(mascota.toJsonInsert()).eq('ID_mascota', mascota.idMascota);
  }

  Future<void> delete(int id) async {
    await supabase.from('mascota').delete().eq('ID_mascota', id);
  }
}

// ─────────────────────────────────────────────────────────────
// CITA
// ─────────────────────────────────────────────────────────────
class CitaService {
  Future<List<Cita>> getAll() async {
    final response = await supabase.from('cita').select();
    return (response as List).map((e) => Cita.fromJson(e)).toList();
  }

  Future<Cita?> getById(int id) async {
    final response = await supabase.from('cita').select().eq('ID_cita', id).single();
    return response != null ? Cita.fromJson(response) : null;
  }

  Future<List<Cita>> getByCliente(int idCliente) async {
    final response = await supabase.from('cita').select().eq('ID_cliente', idCliente);
    return (response as List).map((e) => Cita.fromJson(e)).toList();
  }

  Future<List<Cita>> getByMascota(int idMascota) async {
    final response = await supabase.from('cita').select().eq('ID_mascota', idMascota);
    return (response as List).map((e) => Cita.fromJson(e)).toList();
  }

  Future<void> insert(Cita cita) async {
    await supabase.from('cita').insert(cita.toJsonInsert());
  }

  Future<void> update(Cita cita) async {
    await supabase.from('cita').update(cita.toJsonInsert()).eq('ID_cita', cita.idCita);
  }

  Future<void> delete(int id) async {
    await supabase.from('cita').delete().eq('ID_cita', id);
  }
}

// ─────────────────────────────────────────────────────────────
// SERVICIO
// ─────────────────────────────────────────────────────────────
class ServicioService {
  Future<List<Servicio>> getAll() async {
    final response = await supabase.from('servicio').select();
    return (response as List).map((e) => Servicio.fromJson(e)).toList();
  }

  Future<Servicio?> getById(int id) async {
    final response = await supabase.from('servicio').select().eq('ID_servicio', id).single();
    return response != null ? Servicio.fromJson(response) : null;
  }

  Future<void> insert(Servicio servicio) async {
    await supabase.from('servicio').insert(servicio.toJsonInsert());
  }

  Future<void> update(Servicio servicio) async {
    await supabase.from('servicio').update(servicio.toJsonInsert()).eq('ID_servicio', servicio.idServicio);
  }

  Future<void> delete(int id) async {
    await supabase.from('servicio').delete().eq('ID_servicio', id);
  }
}

// ─────────────────────────────────────────────────────────────
// PLAN ALIMENTACIÓN
// ─────────────────────────────────────────────────────────────
class PlanAlimentacionService {
  Future<List<PlanAlimentacion>> getAll() async {
    final response = await supabase.from('planalimentacion').select();
    return (response as List).map((e) => PlanAlimentacion.fromJson(e)).toList();
  }

  Future<PlanAlimentacion?> getById(int id) async {
    final response = await supabase.from('planalimentacion').select().eq('ID_planAlimentacion', id).single();
    return response != null ? PlanAlimentacion.fromJson(response) : null;
  }

  Future<List<PlanAlimentacion>> getByMascota(int idMascota) async {
    final response = await supabase.from('planalimentacion').select().eq('ID_mascota', idMascota);
    return (response as List).map((e) => PlanAlimentacion.fromJson(e)).toList();
  }

  Future<void> insert(PlanAlimentacion plan) async {
    await supabase.from('planalimentacion').insert(plan.toJsonInsert());
  }

  Future<void> update(PlanAlimentacion plan) async {
    await supabase.from('planalimentacion').update(plan.toJsonInsert()).eq('ID_planAlimentacion', plan.idPlanAlimentacion);
  }

  Future<void> delete(int id) async {
    await supabase.from('planalimentacion').delete().eq('ID_planAlimentacion', id);
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFICACIÓN
// ─────────────────────────────────────────────────────────────
class NotificacionService {
  Future<List<Notificacion>> getAll() async {
    final response = await supabase.from('notificacion').select();
    return (response as List).map((e) => Notificacion.fromJson(e)).toList();
  }

  Future<Notificacion?> getById(int id) async {
    final response = await supabase.from('notificacion').select().eq('ID_notificacion', id).single();
    return response != null ? Notificacion.fromJson(response) : null;
  }

  Future<List<Notificacion>> getByUsuario(int idUsuario) async {
    final response = await supabase.from('notificacion').select().eq('ID_usuario', idUsuario);
    return (response as List).map((e) => Notificacion.fromJson(e)).toList();
  }

  Future<List<Notificacion>> getNoLeidas(int idUsuario) async {
    final response = await supabase.from('notificacion').select().eq('ID_usuario', idUsuario).eq('Leida', 0);
    return (response as List).map((e) => Notificacion.fromJson(e)).toList();
  }

  Future<void> insert(Notificacion notificacion) async {
    await supabase.from('notificacion').insert(notificacion.toJsonInsert());
  }

  Future<void> marcarLeida(int id, String fechaLectura) async {
    await supabase.from('notificacion').update({
      'Leida': 1,
      'Fecha_lectura': fechaLectura,
    }).eq('ID_notificacion', id);
  }

  Future<void> delete(int id) async {
    await supabase.from('notificacion').delete().eq('ID_notificacion', id);
  }
}

// ─────────────────────────────────────────────────────────────
// CARNET VACUNAS
// ─────────────────────────────────────────────────────────────
class CarnetVacunasService {
  Future<List<CarnetVacunas>> getAll() async {
    final response = await supabase.from('carnetvacunas').select();
    return (response as List).map((e) => CarnetVacunas.fromJson(e)).toList();
  }

  Future<CarnetVacunas?> getById(int id) async {
    final response = await supabase.from('carnetvacunas').select().eq('ID_carnetVacunas', id).single();
    return response != null ? CarnetVacunas.fromJson(response) : null;
  }

  Future<List<CarnetVacunas>> getByMascota(int idMascota) async {
    final response = await supabase.from('carnetvacunas').select().eq('ID_mascota', idMascota);
    return (response as List).map((e) => CarnetVacunas.fromJson(e)).toList();
  }

  Future<void> insert(CarnetVacunas cv) async {
    await supabase.from('carnetvacunas').insert(cv.toJsonInsert());
  }

  Future<void> update(CarnetVacunas cv) async {
    await supabase.from('carnetvacunas').update(cv.toJsonInsert()).eq('ID_carnetVacunas', cv.idCarnetVacunas);
  }

  Future<void> delete(int id) async {
    await supabase.from('carnetvacunas').delete().eq('ID_carnetVacunas', id);
  }
}

// ─────────────────────────────────────────────────────────────
// VETERINARIO
// ─────────────────────────────────────────────────────────────
class VeterinarioService {
  Future<List<Veterinario>> getAll() async {
    final response = await supabase.from('veterinario').select();
    return (response as List).map((e) => Veterinario.fromJson(e)).toList();
  }

  Future<Veterinario?> getById(int id) async {
    final response = await supabase.from('veterinario').select().eq('ID_veterinario', id).single();
    return response != null ? Veterinario.fromJson(response) : null;
  }

  Future<void> insert(Veterinario vet) async {
    await supabase.from('veterinario').insert(vet.toJsonInsert());
  }

  Future<void> update(Veterinario vet) async {
    await supabase.from('veterinario').update(vet.toJsonInsert()).eq('ID_veterinario', vet.idVeterinario);
  }

  Future<void> delete(int id) async {
    await supabase.from('veterinario').delete().eq('ID_veterinario', id);
  }
}

// ─────────────────────────────────────────────────────────────
// ADMINISTRADOR
// ─────────────────────────────────────────────────────────────
class AdministradorService {
  Future<List<Administrador>> getAll() async {
    final response = await supabase.from('administrador').select();
    return (response as List).map((e) => Administrador.fromJson(e)).toList();
  }

  Future<Administrador?> getById(int id) async {
    final response = await supabase.from('administrador').select().eq('ID_administrador', id).single();
    return response != null ? Administrador.fromJson(response) : null;
  }

  Future<void> insert(Administrador admin) async {
    await supabase.from('administrador').insert(admin.toJsonInsert());
  }

  Future<void> update(Administrador admin) async {
    await supabase.from('administrador').update(admin.toJsonInsert()).eq('ID_administrador', admin.idAdministrador);
  }

  Future<void> delete(int id) async {
    await supabase.from('administrador').delete().eq('ID_administrador', id);
  }
}