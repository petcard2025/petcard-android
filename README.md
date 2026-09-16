# 🐾 PETCARD

Aplicación móvil para la **gestión de mascotas y servicios veterinarios**. Permite a los usuarios administrar la información de sus mascotas, agendar citas, consultar el carnet de vacunas, revisar planes de alimentación y recibir notificaciones. También incluye un panel de administración y un panel para veterinarios.

---

## Tabla de contenidos

- [Características]
- [Tecnologías]
- [Arquitectura]
- [Requisitos previos]
- [Instalación]
- [Configuración]
- [Estructura del proyecto]
- [Roles de usuario] 
- [Módulos]
- [Capturas de pantalla]
- [Autores]

---

##  Características

###  Usuarios / Clientes
- Registro e inicio de sesión con JWT
- Gestión de mascotas (crear, editar, eliminar)
- Subida de foto de la mascota (cámara o galería)
- Agendamiento de citas veterinarias
- Carnet digital de vacunas con exportación a PDF
- Planes de alimentación personalizados
- Notificaciones y recordatorios
- Gestión de perfil

###  Administrador
- Panel de administración completo
- CRUD de usuarios, mascotas, citas, vacunas, servicios y planes de alimentación
- Gestión de notificaciones
- Envío de SMS (Twilio)
- Control total del sistema

###  Veterinario
- Dashboard con estadísticas de citas
- Confirmación de citas y registro de observaciones clínicas
- Creación de planes nutricionales para mascotas atendidas

---

##  Tecnologías

### Frontend (App móvil)
| Tecnología | Uso |
|------------|-----|
| **Flutter** | Framework principal |
| **Dart** | Lenguaje de programación |
| **Material Design** | Sistema de diseño |
| **http** | Peticiones HTTP al backend |
| **flutter_secure_storage** | Almacenamiento seguro del JWT |
| **shared_preferences** | Almacenamiento local |
| **image_picker** | Selección de imágenes |
| **pdf & printing** | Generación de carnet en PDF |
| **google_fonts** | Tipografías personalizadas |

### Backend
| Tecnología | Uso |
|------------|-----|
| **Node.js** | Runtime de JavaScript |
| **Express** | Framework del servidor REST |
| **PostgreSQL** | Base de datos (Supabase) |
| **bcrypt** | Encriptación de contraseñas |
| **jsonwebtoken** | Autenticación con JWT |
| **express-rate-limit** | Protección contra fuerza bruta |
| **Nodemailer** | Envío de correos (recuperación) |
| **Twilio** | Envío de SMS |
| **Google Calendar API** | Creación de eventos de citas |
| **Supabase** | Base de datos en la nube |

---

##  Arquitectura
┌─────────────────────────────────────────────┐
│  APP FLUTTER (Móvil) │
│ Vistas → Servicios → ApiService │
└─────────────────────────────────────────────┘
↓
HTTP (con SSL en dev)
↓
┌─────────────────────────────────────────────┐
│  BACKEND Node.js (puerto 3001) │
│ server.js + controllers + middleware │
└─────────────────────────────────────────────┘
↓
┌─────────────────────────────────────────────┐
│  Supabase (PostgreSQL) │
│ usuario, mascota, cita, vacuna, etc. │
└─────────────────────────────────────────────┘
↓
┌─────────────────────────────────────────────┐
│  Nodemailer +  Twilio +  Google │
│ Servicios externos (correos, SMS, cal.) │
└─────────────────────────────────────────────┘
**La app móvil NO se conecta directamente a Supabase.** Todo pasa por el backend de Node.js.

---

##  Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versión 3.12.2 o superior)
- [Node.js](https://nodejs.org/) (versión 18 o superior)
- [Android Studio](https://developer.android.com/studio) o [VS Code](https://code.visualstudio.com/)
- Un emulador de Android o un dispositivo físico
- Cuenta en [Supabase](https://supabase.com/)
- Cuenta de Gmail con **contraseña de aplicación** (para Nodemailer)
- Cuenta en [Twilio](https://www.twilio.com/) (opcional, para SMS)

---

##  Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/petcard-android.git
cd petcard-android
2. Instalar dependencias del backend
bash
cd backend
npm install
3. Instalar dependencias de la app Flutter
bash
cd ..
flutter pub get
  Configuración
Backend (backend/.env)
Crea un archivo .env en la carpeta backend/ con estas variables:

env
# ============================================================
# BASE DE DATOS (Supabase - PostgreSQL)
# ============================================================
DATABASE_URL=postgresql://postgres.tu-proyecto:tu-password@aws-0-us-east-1.pooler.supabase.com:5432/postgres

# ============================================================
# JWT (Autenticación)
# ============================================================
JWT_SECRET=tu_clave_secreta_muy_larga_y_segura
JWT_EXPIRES_IN=24h

# ============================================================
# NODEMAILER (Correos)
# ============================================================
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=tucorreo@gmail.com
SMTP_PASS=tu_contraseña_de_aplicacion_de_16_digitos

# ============================================================
# TWILIO (SMS)
# ============================================================
TWILIO_ACCOUNT_SID=tu_account_sid
TWILIO_AUTH_TOKEN=tu_auth_token
TWILIO_PHONE_NUMBER=+1234567890

# ============================================================
# GOOGLE CALENDAR
# ============================================================
GOOGLE_CALENDAR_ID=tucorreo@gmail.com
GOOGLE_CREDENTIALS_PATH=./google-credentials.json

# ============================================================
# SERVIDOR
# ============================================================
PORT=3001
NODE_ENV=development
⚠️ Agrega .env a .gitignore para que no se suba al repositorio.

App Flutter (lib/services/api_service.dart)
Cambia la IP por la de tu PC donde corre el backend:

dart
static const List<String> _ipsConocidas = [
  '192.168.80.25',   // ← Cambia esto por tu IP (ver ipconfig)
];

static String get baseUrl => 'http://$_ipActual:3001/api';
Cómo obtener tu IP:

Windows: ipconfig en CMD → busca "Dirección IPv4"

Mac/Linux: ifconfig en Terminal

▶ Ejecución
1. Iniciar el backend
En una terminal:

bash
cd backend
npm run certs 
node server.js
Debe mostrar:

text
✅ Servidor SMTP listo para enviar correos
✓ Conectado a Supabase (PostgreSQL) correctamente
🌐 Servidor HTTP corriendo en http://localhost:3001
🌐 Accesible desde la red en http://192.168.80.25:3001
⚠️ NO cierres esta terminal. El backend debe quedarse corriendo.

2. Ejecutar la app Flutter
En otra terminal:

bash
flutter run
 Estructura del proyecto
text
petcard/
├── android/                      # Configuración Android
├── ios/                          # Configuración iOS
├── assets/                       # Recursos (imágenes, iconos)
│   └── icon/
│       └── logo.png
│
├── lib/                          # Código Dart (toda la app)
│   ├── admin_screens/            # Pantallas del panel admin
│   │   ├── Admin_home_screen.dart
│   │   ├── Admin_citas_screen.dart
│   │   ├── Admin_mascotas_screen.dart
│   │   ├── Admin_vacunas_screen.dart
│   │   ├── Admin_alimentacion_screen.dart
│   │   ├── Admin_servicios_screen.dart
│   │   ├── Admin_notificaciones_screen.dart
│   │   └── Admin_usuarios_screen.dart
│   │
│   ├── screens/                  # Pantallas de usuario
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── reset_password_screen.dart
│   │   ├── landing_screen.dart
│   │   ├── main_nav_screen.dart
│   │   ├── inicio_screen.dart
│   │   ├── mis_mascotas_screen.dart
│   │   ├── citas_screen.dart
│   │   ├── alimentacion_screen.dart
│   │   ├── carnet_digital.dart
│   │   ├── notificaciones_screen.dart
│   │   ├── gestion_servicios.dart
│   │   └── perfil_screen.dart
│   │
│   ├── vete_screens/             # Pantallas de veterinario
│   │   ├── vet_dashboard_screen.dart
│   │   ├── vet_citas_screen.dart
│   │   └── vet_alimentacion_screen.dart
│   │
│   ├── services/                 # Servicios (API, auth)
│   │   ├── api_service.dart      # Peticiones HTTP al backend
│   │   └── auth_service.dart     # Login/registro
│   │
│   ├── theme/                    # Tema global
│   │   └── app_theme.dart
│   │
│   └── main.dart                 # Punto de entrada
│
├── backend/                      # Backend Node.js
│   ├── src/
│   │   ├── config/
│   │   │   └── database.js       # Conexión a Supabase
│   │   ├── controllers/
│   │   │   └── auth.controller.js
│   │   ├── middlewares/
│   │   ├── routes/
│   │   └── services/
│   │
│   ├── certs/                    # Certificados SSL (legado)
│   ├── .env                      # Variables de entorno (NO subir a Git)
│   ├── mailer.js                 # Configuración Nodemailer
│   ├── server.js                 # Servidor Express
│   └── package.json
│
├── pubspec.yaml                  # Dependencias Flutter
├── pubspec.lock                  # Versiones exactas
└── README.md                     # Este archivo


  Endpoints principales
🐾 Autenticación
Método	Endpoint	Descripción
POST	/api/auth/login	Login
POST	/api/auth/login-admin	Login admin/vet
POST	/api/auth/forgot-password	Solicitar recuperación
POST	/api/auth/reset-password	Restablecer con código

🐾 Mascotas
Método	Endpoint	Descripción
GET	/api/mascotas	Listar todas (admin)
GET	/api/mascotas/cliente/:id	Mascotas de un cliente
POST	/api/mascotas	Crear mascota
PUT	/api/mascotas/:id	Actualizar mascota
DELETE	/api/mascotas/:id	Desactivar mascota
Carnet de Vacunas
Método	Endpoint	Descripción
GET	/api/vacunas	Listar todas
GET	/api/vacunas/mascota/:id	Vacunas de una mascota
POST	/api/vacunas	Registrar vacuna
PUT	/api/vacunas/:id	Actualizar vacuna
DELETE	/api/vacunas/:id	Eliminar vacuna
Citas
Método	Endpoint	Descripción
GET	/api/citas	Listar citas
POST	/api/citas	Crear cita
PUT	/api/citas/:id	Actualizar cita
PATCH	/api/citas/:id	Cambiar estado
DELETE	/api/citas/:id	Eliminar cita
Otros módulos
Usuarios: /api/usuarios

Clientes: /api/clientes

Servicios: /api/servicios

Alimentación: /api/alimentacion

Notificaciones: /api/notificaciones

Veterinarios: /api/veterinarios

Administradores: /api/administradores

SMS: /api/sms

 Roles de usuario
Rol	Acceso
Cliente	App móvil completa (mascotas, citas, carnet, perfil)
Veterinario	Dashboard, citas asignadas, planes nutricionales
Administrador	Panel completo de administración
El rol se determina por el campo Rol del JWT tras el login:

'cliente' → navega a /home

'veterinario' → navega a VetDashboardScreen

'administrador' → navega a /admin

 Módulos
 Mascotas
CRUD completo (crear, listar, editar, eliminar)

Filtro por especie y búsqueda por nombre/dueño

Soft delete (cambia Estado a inactivo)

Validaciones: nombre sin números, peso máximo 150 kg, fecha de nacimiento no futura

 Carnet de Vacunas
Registrar vacunas con fecha, lote, próxima dosis

Cálculo automático de edad desde fecha de nacimiento

Generación de carnet en PDF

Notificación automática al dueño al registrar vacuna

 Citas
Agendar citas con veterinario, servicio y mascota

Validación de disponibilidad (sin doble cita en la misma hora)

Creación automática de evento en Google Calendar

Cambio de estado: Pendiente → Confirmada → Completada

SMS de confirmación al cliente

 Alimentación
Planes nutricionales por mascota

Filtros por tipo de dieta y estado

Validación: solo el veterinario que atendió a la mascota puede crear planes

 Notificaciones
Notificaciones automáticas de citas y vacunas

Marcado como leída/no leída

Envío por SMS (Twilio)

Estadísticas de lectura

 Usuarios
Registro con Supabase

Login con JWT

Recuperación de contraseña por correo con código de 6 dígitos

Recuperación válida por 5 minutos

 Autores
Yuber Alexander Franco Cuetochambo 
Diego Sebastián Guerrero Niño
Laura Valentina Marroquín Rodríguez
Carlos Ferney Mosquera Murillo 
Juan José Pinilla Marulanda

 Contacto
Si tienes preguntas o sugerencias:

 petcard@ejemplo.com

 Licencia
Este proyecto es de uso académico. Todos los derechos reservados © 2026 PetCard.
