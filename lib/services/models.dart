// ============================================================
// MODELOS PETCARD - Generados desde el esquema PostgreSQL
// ============================================================

class Usuario {
  final int idUsuario;
  final String nombre;
  final String correo;
  final String? telefono;
  final String contrasena;
  final String rol;

  Usuario({
    required this.idUsuario,
    required this.nombre,
    required this.correo,
    this.telefono,
    required this.contrasena,
    required this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    idUsuario: json['ID_usuario'],
    nombre: json['Nombre'],
    correo: json['Correo'],
    telefono: json['Telefono'],
    contrasena: json['Contrasena'],
    rol: json['Rol'],
  );

  Map<String, dynamic> toJson() => {
    'ID_usuario': idUsuario,
    'Nombre': nombre,
    'Correo': correo,
    'Telefono': telefono,
    'Contrasena': contrasena,
    'Rol': rol,
  };

  Map<String, dynamic> toJsonInsert() => {
    'Nombre': nombre,
    'Correo': correo,
    'Telefono': telefono,
    'Contrasena': contrasena,
    'Rol': rol,
  };
}

class Cliente {
  final int idCliente;
  final String? direccion;
  final int idUsuario;

  Cliente({
    required this.idCliente,
    this.direccion,
    required this.idUsuario,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
    idCliente: json['ID_cliente'],
    direccion: json['Direccion'],
    idUsuario: json['ID_usuario'],
  );

  Map<String, dynamic> toJson() => {
    'ID_cliente': idCliente,
    'Direccion': direccion,
    'ID_usuario': idUsuario,
  };

  Map<String, dynamic> toJsonInsert() => {
    'Direccion': direccion,
    'ID_usuario': idUsuario,
  };
}

class Mascota {
  final int idMascota;
  final int idCliente;
  final String? fechaNacimiento;
  final String? nombre;
  final String? especie;
  final String? sexo;
  final String? foto;
  final String? raza;
  final double? peso;
  final String estado;

  Mascota({
    required this.idMascota,
    required this.idCliente,
    this.fechaNacimiento,
    this.nombre,
    this.especie,
    this.sexo,
    this.foto,
    this.raza,
    this.peso,
    this.estado = 'activo',
  });

  factory Mascota.fromJson(Map<String, dynamic> json) => Mascota(
    idMascota: json['ID_mascota'],
    idCliente: json['ID_cliente'],
    fechaNacimiento: json['Fecha_nacimiento'],
    nombre: json['Nombre'],
    especie: json['Especie'],
    sexo: json['Sexo'],
    foto: json['Foto'],
    raza: json['Raza'],
    peso: json['Peso'] != null ? (json['Peso'] as num).toDouble() : null,
    estado: json['Estado'] ?? 'activo',
  );

  Map<String, dynamic> toJson() => {
    'ID_mascota': idMascota,
    'ID_cliente': idCliente,
    'Fecha_nacimiento': fechaNacimiento,
    'Nombre': nombre,
    'Especie': especie,
    'Sexo': sexo,
    'Foto': foto,
    'Raza': raza,
    'Peso': peso,
    'Estado': estado,
  };

  Map<String, dynamic> toJsonInsert() => {
    'ID_cliente': idCliente,
    'Fecha_nacimiento': fechaNacimiento,
    'Nombre': nombre,
    'Especie': especie,
    'Sexo': sexo,
    'Foto': foto,
    'Raza': raza,
    'Peso': peso,
    'Estado': estado,
  };
}

class Cita {
  final int idCita;
  final int idCliente;
  final int idMascota;
  final int idServicio;
  final int idVeterinario;
  final String? fecha;
  final String? hora;
  final String? motivo;
  final String? observaciones;
  final String estado;
  final String? googleEventId;

  Cita({
    required this.idCita,
    required this.idCliente,
    required this.idMascota,
    required this.idServicio,
    required this.idVeterinario,
    this.fecha,
    this.hora,
    this.motivo,
    this.observaciones,
    this.estado = 'Pendiente',
    this.googleEventId,
  });

  factory Cita.fromJson(Map<String, dynamic> json) => Cita(
    idCita: json['ID_cita'],
    idCliente: json['ID_cliente'],
    idMascota: json['ID_mascota'],
    idServicio: json['ID_servicio'],
    idVeterinario: json['ID_veterinario'],
    fecha: json['Fecha'],
    hora: json['Hora'],
    motivo: json['Motivo'],
    observaciones: json['Observaciones'],
    estado: json['Estado'] ?? 'Pendiente',
    googleEventId: json['Google_Event_ID'],
  );

  Map<String, dynamic> toJson() => {
    'ID_cita': idCita,
    'ID_cliente': idCliente,
    'ID_mascota': idMascota,
    'ID_servicio': idServicio,
    'ID_veterinario': idVeterinario,
    'Fecha': fecha,
    'Hora': hora,
    'Motivo': motivo,
    'Observaciones': observaciones,
    'Estado': estado,
    'Google_Event_ID': googleEventId,
  };

  Map<String, dynamic> toJsonInsert() => {
    'ID_cliente': idCliente,
    'ID_mascota': idMascota,
    'ID_servicio': idServicio,
    'ID_veterinario': idVeterinario,
    'Fecha': fecha,
    'Hora': hora,
    'Motivo': motivo,
    'Observaciones': observaciones,
    'Estado': estado,
    'Google_Event_ID': googleEventId,
  };
}

class Servicio {
  final int idServicio;
  final String? nombre;
  final String? descripcion;
  final String? categoria;
  final double? precio;

  Servicio({
    required this.idServicio,
    this.nombre,
    this.descripcion,
    this.categoria,
    this.precio,
  });

  factory Servicio.fromJson(Map<String, dynamic> json) => Servicio(
    idServicio: json['ID_servicio'],
    nombre: json['Nombre'],
    descripcion: json['Descripcion'],
    categoria: json['Categoria'],
    precio: json['Precio'] != null ? (json['Precio'] as num).toDouble() : null,
  );

  Map<String, dynamic> toJson() => {
    'ID_servicio': idServicio,
    'Nombre': nombre,
    'Descripcion': descripcion,
    'Categoria': categoria,
    'Precio': precio,
  };

  Map<String, dynamic> toJsonInsert() => {
    'Nombre': nombre,
    'Descripcion': descripcion,
    'Categoria': categoria,
    'Precio': precio,
  };
}

class PlanAlimentacion {
  final int idPlanAlimentacion;
  final int idMascota;
  final int idServicio;
  final String? tipoDieta;
  final String? frecuencia;
  final String? alergias;
  final String? horario;
  final int? calorias;
  final String? suplementos;
  final String? comidas;
  final String? fechaInicio;
  final String? fechaFin;
  final String? observaciones;
  final String? diagnostico;
  final String? revisionNutricional;

  PlanAlimentacion({
    required this.idPlanAlimentacion,
    required this.idMascota,
    required this.idServicio,
    this.tipoDieta,
    this.frecuencia,
    this.alergias,
    this.horario,
    this.calorias,
    this.suplementos,
    this.comidas,
    this.fechaInicio,
    this.fechaFin,
    this.observaciones,
    this.diagnostico,
    this.revisionNutricional,
  });

  factory PlanAlimentacion.fromJson(Map<String, dynamic> json) => PlanAlimentacion(
    idPlanAlimentacion: json['ID_planAlimentacion'],
    idMascota: json['ID_mascota'],
    idServicio: json['ID_servicio'],
    tipoDieta: json['Tipo_dieta'],
    frecuencia: json['Frecuencia'],
    alergias: json['Alergias'],
    horario: json['Horario'],
    calorias: json['Calorias'],
    suplementos: json['Suplementos'],
    comidas: json['Comidas'],
    fechaInicio: json['Fecha_inicio'],
    fechaFin: json['Fecha_fin'],
    observaciones: json['Observaciones'],
    diagnostico: json['Diagnostico'],
    revisionNutricional: json['Revision_nutricional'],
  );

  Map<String, dynamic> toJson() => {
    'ID_planAlimentacion': idPlanAlimentacion,
    'ID_mascota': idMascota,
    'ID_servicio': idServicio,
    'Tipo_dieta': tipoDieta,
    'Frecuencia': frecuencia,
    'Alergias': alergias,
    'Horario': horario,
    'Calorias': calorias,
    'Suplementos': suplementos,
    'Comidas': comidas,
    'Fecha_inicio': fechaInicio,
    'Fecha_fin': fechaFin,
    'Observaciones': observaciones,
    'Diagnostico': diagnostico,
    'Revision_nutricional': revisionNutricional,
  };

  Map<String, dynamic> toJsonInsert() => {
    'ID_mascota': idMascota,
    'ID_servicio': idServicio,
    'Tipo_dieta': tipoDieta,
    'Frecuencia': frecuencia,
    'Alergias': alergias,
    'Horario': horario,
    'Calorias': calorias,
    'Suplementos': suplementos,
    'Comidas': comidas,
    'Fecha_inicio': fechaInicio,
    'Fecha_fin': fechaFin,
    'Observaciones': observaciones,
    'Diagnostico': diagnostico,
    'Revision_nutricional': revisionNutricional,
  };
}

class Notificacion {
  final int idNotificacion;
  final int idUsuario;
  final int idSistemaCorreo;
  final String? mensaje;
  final String? tipo;
  final String? canal;
  final String? fechaEnvio;
  final int leida;
  final String? fechaLectura;

  Notificacion({
    required this.idNotificacion,
    required this.idUsuario,
    required this.idSistemaCorreo,
    this.mensaje,
    this.tipo,
    this.canal,
    this.fechaEnvio,
    this.leida = 0,
    this.fechaLectura,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) => Notificacion(
    idNotificacion: json['ID_notificacion'],
    idUsuario: json['ID_usuario'],
    idSistemaCorreo: json['ID_sistemaCorreo'],
    mensaje: json['Mensaje'],
    tipo: json['Tipo'],
    canal: json['Canal'],
    fechaEnvio: json['Fecha_envio'],
    leida: json['Leida'] ?? 0,
    fechaLectura: json['Fecha_lectura'],
  );

  Map<String, dynamic> toJson() => {
    'ID_notificacion': idNotificacion,
    'ID_usuario': idUsuario,
    'ID_sistemaCorreo': idSistemaCorreo,
    'Mensaje': mensaje,
    'Tipo': tipo,
    'Canal': canal,
    'Fecha_envio': fechaEnvio,
    'Leida': leida,
    'Fecha_lectura': fechaLectura,
  };

  Map<String, dynamic> toJsonInsert() => {
    'ID_usuario': idUsuario,
    'ID_sistemaCorreo': idSistemaCorreo,
    'Mensaje': mensaje,
    'Tipo': tipo,
    'Canal': canal,
    'Fecha_envio': fechaEnvio,
    'Leida': leida,
    'Fecha_lectura': fechaLectura,
  };
}

class CarnetVacunas {
  final int idCarnetVacunas;
  final int idMascota;
  final int idServicio;
  final String? nombreVacuna;
  final String? laboratorio;
  final String? lote;
  final String? fechaAplicacion;
  final String? proximaDosis;
  final String? reacciones;
  final String? estado;
  final String? observaciones;

  CarnetVacunas({
    required this.idCarnetVacunas,
    required this.idMascota,
    required this.idServicio,
    this.nombreVacuna,
    this.laboratorio,
    this.lote,
    this.fechaAplicacion,
    this.proximaDosis,
    this.reacciones,
    this.estado,
    this.observaciones,
  });

  factory CarnetVacunas.fromJson(Map<String, dynamic> json) => CarnetVacunas(
    idCarnetVacunas: json['ID_carnetVacunas'],
    idMascota: json['ID_mascota'],
    idServicio: json['ID_servicio'],
    nombreVacuna: json['Nombre_vacuna'],
    laboratorio: json['Laboratorio'],
    lote: json['Lote'],
    fechaAplicacion: json['Fecha_aplicacion'],
    proximaDosis: json['Proxima_dosis'],
    reacciones: json['Reacciones'],
    estado: json['Estado'],
    observaciones: json['Observaciones'],
  );

  Map<String, dynamic> toJson() => {
    'ID_carnetVacunas': idCarnetVacunas,
    'ID_mascota': idMascota,
    'ID_servicio': idServicio,
    'Nombre_vacuna': nombreVacuna,
    'Laboratorio': laboratorio,
    'Lote': lote,
    'Fecha_aplicacion': fechaAplicacion,
    'Proxima_dosis': proximaDosis,
    'Reacciones': reacciones,
    'Estado': estado,
    'Observaciones': observaciones,
  };

  Map<String, dynamic> toJsonInsert() => {
    'ID_mascota': idMascota,
    'ID_servicio': idServicio,
    'Nombre_vacuna': nombreVacuna,
    'Laboratorio': laboratorio,
    'Lote': lote,
    'Fecha_aplicacion': fechaAplicacion,
    'Proxima_dosis': proximaDosis,
    'Reacciones': reacciones,
    'Estado': estado,
    'Observaciones': observaciones,
  };
}

class Veterinario {
  final int idVeterinario;
  final String? cargo;
  final String? especialidad;
  final int idUsuario;

  Veterinario({
    required this.idVeterinario,
    this.cargo,
    this.especialidad,
    required this.idUsuario,
  });

  factory Veterinario.fromJson(Map<String, dynamic> json) => Veterinario(
    idVeterinario: json['ID_veterinario'],
    cargo: json['Cargo'],
    especialidad: json['Especialidad'],
    idUsuario: json['ID_usuario'],
  );

  Map<String, dynamic> toJson() => {
    'ID_veterinario': idVeterinario,
    'Cargo': cargo,
    'Especialidad': especialidad,
    'ID_usuario': idUsuario,
  };

  Map<String, dynamic> toJsonInsert() => {
    'Cargo': cargo,
    'Especialidad': especialidad,
    'ID_usuario': idUsuario,
  };
}

class Administrador {
  final int idAdministrador;
  final String? cargo;
  final String? area;
  final String? permisos;
  final int idUsuario;

  Administrador({
    required this.idAdministrador,
    this.cargo,
    this.area,
    this.permisos,
    required this.idUsuario,
  });

  factory Administrador.fromJson(Map<String, dynamic> json) => Administrador(
    idAdministrador: json['ID_administrador'],
    cargo: json['Cargo'],
    area: json['Area'],
    permisos: json['Permisos'],
    idUsuario: json['ID_usuario'],
  );

  Map<String, dynamic> toJson() => {
    'ID_administrador': idAdministrador,
    'Cargo': cargo,
    'Area': area,
    'Permisos': permisos,
    'ID_usuario': idUsuario,
  };

  Map<String, dynamic> toJsonInsert() => {
    'Cargo': cargo,
    'Area': area,
    'Permisos': permisos,
    'ID_usuario': idUsuario,
  };
}