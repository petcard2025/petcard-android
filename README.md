# 🐾 PETCARD

Aplicación móvil para la **gestión de mascotas y servicios veterinarios**. Permite a los usuarios administrar la información de sus mascotas, agendar citas, consultar el carnet de vacunas, revisar planes de alimentación y recibir notificaciones. También incluye un panel de administración y un panel para veterinarios.

---

##  Tabla de contenidos

- [Características](#-características)
- [Tecnologías](#-tecnologías)
- [Requisitos previos](#-requisitos-previos)
- [Instalación](#-instalación)
- [Configuración](#-configuración)
- [Estructura del proyecto](#-estructura-del-proyecto)
- [Roles de usuario](#-roles-de-usuario)
- [Autores](#-autores)
- [Licencia](#-licencia)

---

## Características

### Usuarios / Clientes

- Registro e inicio de sesión
- Gestión de mascotas (crear, editar y eliminar)
- Subida de foto de la mascota mediante cámara o galería
- Agendamiento de citas veterinarias
- Carnet digital de vacunas con exportación a PDF
- Planes de alimentación personalizados
- Notificaciones y recordatorios
- Gestión de perfil

### Administrador

- Panel de administración completo
- CRUD de usuarios, mascotas, citas, vacunas, servicios y planes de alimentación
- Gestión de notificaciones
- Control general del sistema

### Veterinario

- Dashboard con estadísticas de citas
- Confirmación de citas
- Registro de observaciones clínicas
- Creación de planes nutricionales para mascotas atendidas

---

## Tecnologías

| Tecnología | Uso |
|------------|-----|
| **Flutter** | Framework principal de la aplicación móvil |
| **Dart** | Lenguaje de programación |
| **Supabase** | Base de datos PostgreSQL en la nube |
| **Node.js + Express** | Backend con API REST |
| **MySQL/MariaDB** | Base de datos del backend |
| **SharedPreferences** | Almacenamiento local |
| **Flutter Secure Storage** | Almacenamiento seguro de tokens |
| **Image Picker** | Selección de imágenes mediante cámara o galería |
| **PDF & Printing** | Generación del carnet en PDF |
| **Google Fonts** | Tipografías personalizadas |

---

##  Requisitos previos

Antes de ejecutar el proyecto, asegúrate de tener instalado:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) versión 3.12.2 o superior
- [Android Studio](https://developer.android.com/studio) o [Visual Studio Code](https://code.visualstudio.com/)
- Un emulador de Android o un dispositivo físico
- [Git](https://git-scm.com/)
- Una cuenta en [Supabase](https://supabase.com/)

---

## Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/petcard-android.git
cd petcard-android
2. Instalar dependencias
flutter pub get
3. Configurar Supabase

Abre el archivo lib/main.dart y verifica que las credenciales de Supabase sean correctas:

await Supabase.initialize(
  url: 'https://TU_PROYECTO.supabase.co',
  publishableKey: 'TU_PUBLISHABLE_KEY',
);
4. Configurar el backend

En lib/services/api_service.dart, agrega la IP de tu backend Node.js:

static const List<String> _ipsConocidas = [
  'TU_IP_AQUI', // Ejemplo: 192.168.1.100
];
5. Ejecutar la aplicación
flutter run
🔧 Configuración
Estructura de la tabla usuario en Supabase

Asegúrate de que la tabla usuario tenga una estructura similar a la siguiente:

CREATE TABLE usuario (
    ID_usuario SERIAL PRIMARY KEY,
    Nombre VARCHAR(255) NOT NULL,
    Correo VARCHAR(255) UNIQUE NOT NULL,
    Telefono VARCHAR(50),
    Contrasena VARCHAR(255) NOT NULL,
    Rol VARCHAR(50) DEFAULT 'cliente'
);
Estructura de la tabla mascota en Supabase
CREATE TABLE mascota (
    ID_mascota SERIAL PRIMARY KEY,
    ID_cliente INT NOT NULL,
    Nombre VARCHAR(255),
    Especie VARCHAR(255),
    Raza VARCHAR(255),
    Sexo VARCHAR(50),
    Peso DECIMAL(5,2),
    Fecha_nacimiento DATE,
    Foto VARCHAR(500),
    Estado VARCHAR(50) DEFAULT 'activo'
);
Backend Node.js

El backend debe estar ejecutándose en el puerto 3001:

cd backend
npm install
node server.js
📁 Estructura del proyecto
lib/
├── admin_screens/          # Pantallas del panel de administración
│   ├── Admin_home_screen.dart
│   ├── Admin_citas_screen.dart
│   ├── Admin_mascotas_screen.dart
│   ├── Admin_vacunas_screen.dart
│   ├── Admin_alimentacion_screen.dart
│   ├── Admin_servicios_screen.dart
│   ├── Admin_notificaciones_screen.dart
│   └── Admin_usuarios_screen.dart
│
├── screens/                # Pantallas del usuario
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── landing_screen.dart
│   ├── main_nav_screen.dart
│   ├── inicio_screen.dart
│   ├── mis_mascotas_screen.dart
│   ├── citas_screen.dart
│   ├── alimentacion_screen.dart
│   ├── carnet_digital.dart
│   ├── notificaciones_screen.dart
│   ├── gestion_servicios.dart
│   └── perfil_screen.dart
│
├── vete_screens/           # Pantallas del veterinario
│   ├── vet_dashboard_screen.dart
│   ├── vet_citas_screen.dart
│   └── vet_alimentacion_screen.dart
│
├── services/               # Servicios de API y autenticación
│   ├── api_service.dart
│   └── auth_service.dart
│
├── theme/                  # Tema global de la aplicación
│   └── app_theme.dart
│
└── main.dart               # Punto de entrada de la aplicación

👥 Roles de usuario
Rol	Acceso
Cliente	Aplicación móvil completa: mascotas, citas, carnet, alimentación, etc.
Veterinario	Dashboard, citas asignadas y planes nutricionales
Administrador	Panel completo de administración


👨‍💻 Autores
Yuber Alexander Franco Cuetochambo
Diego Sebastian Guerrero Niño
Laura Valentina Marroquín Rodríguez
Carlos Ferney Mosquera Murillo 
Juan José Pinilla Marulanda

📞 Contacto

Si tienes preguntas o sugerencias, puedes escribirnos a:

📧 petcard@gmail.com

🙏 Agradecimientos
A nuestros profesores y compañeros por el apoyo durante el desarrollo.
A la comunidad de Flutter y Supabase por su documentación y recursos.


📝 Licencia

Este proyecto es de uso académico.

Todos los derechos reservados ©2026 PetCard