# Wall Taken (nombre provisional)

> **Estado: pausado** (noviembre de 2026). Este repositorio conserva la prueba de concepto y el diseño completo para poder retomar el proyecto sin empezar de cero.

## Qué es

App para **Android y Windows** que permite a un usuario cambiar el fondo de pantalla de sus amigos, **solo con su consentimiento**. Está inspirada en apps como Wallclaimer, pero debe tener nombre, marca, textos, iconos e interfaz propios (no copiar nada de la original).

Objetivos: que sea **estable y segura**, y que genere ingresos con anuncios.

## Flujo de la app

1. El usuario se registra (correo o Google).
2. Agrega amigos por código de invitación o nombre de usuario. **El amigo debe aceptar**; hasta entonces nadie puede tocar nada.
3. El emisor elige una imagen de su galería y un amigo. El fondo **lo elige el emisor**, no es aleatorio (lo aleatorio de la prueba es solo para probar).
4. El servidor valida el tipo real del archivo y su tamaño, quita los metadatos EXIF y modera la imagen.
5. Se avisa al receptor: notificación push de Firebase en Android, conexión en tiempo real en Windows.
6. El receptor **aprueba cada cambio** (modo por defecto). Puede activar la aprobación automática.
7. La app descarga la imagen, cambia el fondo y la imagen se **borra del servidor**.
8. El receptor puede revertir, pausar, bloquear o reportar en cualquier momento.

## Decisiones tomadas

| Tema | Decisión |
|---|---|
| Aprobación | Manual por defecto (`auto_apply = false`). La automática es una opción que activa el receptor |
| Imágenes | El servidor es un **puente**: la imagen se borra al aplicarse, al rechazarse o al caducar (propuesta: 48 h sin respuesta). En la base de datos solo queda la fila del cambio, sin imagen |
| Quién elige la imagen | El emisor, desde su galería |
| Revertir | El fondo anterior se guarda en el dispositivo del receptor, no en el servidor |
| Monetización | AdMob en Android. **AdMob no funciona en Windows**: allí, suscripción premium o compras dentro de la app (verificar políticas vigentes) |
| Multiplataforma | Flutter (un solo código) con código nativo solo donde hace falta |

## Arquitectura

| Capa | Herramienta |
|---|---|
| App cliente | Flutter (Android y Windows) |
| Cambio de fondo en Android | Plugin local en Kotlin (`packages/wall_changer`), usa `WallpaperManager` |
| Cambio de fondo en Windows | FFI desde Dart a `SystemParametersInfo` (paquetes `win32` y `ffi`) |
| Notificaciones en Android | Firebase Cloud Messaging, mensajes **solo de datos** con prioridad alta |
| Notificaciones en Windows | Conexión persistente desde una app de bandeja (Supabase Realtime) con consulta periódica de respaldo. *Pendiente de probar* |
| Backend | Supabase: Postgres con RLS, Auth, Storage, Realtime, Edge Functions |
| Imágenes | Storage privado con dos buckets: `quarantine` (subida del emisor) y `wallpapers` (solo escribe el servidor) |
| Moderación | Cloud Vision SafeSearch o AWS Rekognition, antes de entregar |
| Monitoreo | Sentry y Firebase Crashlytics |
| CI/CD | GitHub Actions |

## Qué se validó en la prueba de concepto

- Cambiar el fondo en **Windows** desde Flutter (FFI).
- Cambiar el fondo en **Android**, pantalla de inicio y de bloqueo.
- Un mensaje de datos de Firebase, enviado desde un script de Node, **llega con la app minimizada y con la app cerrada**.
- Con la app cerrada, el código de segundo plano descarga la imagen, **cambia el fondo** y borra el archivo descargado.

## Lecciones aprendidas

- **El registro del token de FCM puede fallar por red** (`FCM Registration failed!`). En un caso se resolvió reiniciando el wifi. La app real debe reintentar y escuchar `onTokenRefresh`.
- **Android 13 o superior** exige permiso del usuario para mostrar notificaciones. No afecta a los mensajes de solo datos, pero sí a cualquier prueba con notificación visible.
- **Fabricantes con ahorro de batería agresivo** (Xiaomi, HyperOS, etc.): hace falta activar inicio automático, batería sin restricciones y bloquear la app en recientes. La app real necesita una pantalla de guía para el usuario y un mecanismo de respaldo (recoger cambios pendientes al abrir, y consulta periódica con WorkManager).
- **El canal de Kotlin en `MainActivity` no existe con la app cerrada.** Por eso el cambio de fondo vive en un plugin local, que Flutter registra también en el motor de segundo plano.
- **`UNREGISTERED` / `NotRegistered`**: al desinstalar la app o borrar sus datos, el token cambia y el anterior muere. El servidor debe borrar esos tokens de `devices` y no reintentar.
- **Forzar detención** de una app desde Ajustes bloquea los mensajes hasta que se vuelva a abrir. Es una regla de Android.
- **Firebase Messaging no existe en Windows.**
- Un proyecto de Flutter trae su propio repositorio Git interno: hay que borrar `poc_wallpaper/.git` antes de añadirlo a un repositorio mayor.

## Estructura del repositorio

```
poc_wallpaper/        App de Flutter de la prueba (Android y Windows)
packages/wall_changer Plugin local de Android para cambiar el fondo
tools/send-test/      Script de Node que envía un mensaje de datos por FCM
supabase/             Migraciones (si se llegó a crear)
```

`tools/send-test/service-account.json` **no está en el repositorio** (está en el `.gitignore`). Es una credencial de administrador de Firebase: nunca se sube.

`poc_wallpaper/android/app/google-services.json` y `poc_wallpaper/lib/firebase_options.dart` corresponden al proyecto de Firebase original, que puede haber sido borrado. Para retomar, crea un proyecto nuevo y ejecuta `flutterfire configure` (solo Android).

## Cómo retomar el entorno de desarrollo

1. **Git**, **VS Code** con las extensiones de Flutter y Dart, y **Node.js**.
2. **Visual Studio Community** con la carga de trabajo "Desarrollo para el escritorio con C++" (necesaria para compilar en Windows).
3. **Android Studio**. En el SDK Manager: la plataforma de Android más reciente, **Command-line Tools** y **Platform-Tools**. Si Gradle lo pide, instalar el NDK a mano (en la prueba fue la versión 28.2.13676358).
4. **Flutter SDK**: desde VS Code (*Flutter: New Project → Download SDK*) o manualmente en una ruta corta sin espacios, y añadir su carpeta `bin` al PATH.
5. Activar el **Modo de desarrollador** de Windows.
6. `flutter doctor -v` hasta que no muestre problemas.
7. Para el teléfono: activar opciones de desarrollador y depuración USB (en Xiaomi, también "Instalar mediante USB").
8. Firebase: `npm install -g firebase-tools`, `firebase login`, `dart pub global activate flutterfire_cli` y `flutterfire configure` dentro de `poc_wallpaper`. Generar una clave de servicio nueva y guardarla como `tools/send-test/service-account.json`.
9. Dentro de `tools/send-test`: `npm install`.
10. Obtener el token de la app: `adb logcat -d flutter:I *:S | Select-String "FCM token"`, y enviar con `node send.js "<TOKEN>"`.

Versiones con las que se probó: Flutter 3.47.6 (stable), Dart 3.13.5, Gradle 9.3.1, Android 16 en el teléfono de pruebas.

## Modelo de datos y seguridad

Principio central: **los clientes solo leen. Toda escritura delicada pasa por Edge Functions o funciones RPC** con `security definer`, que comprueban las reglas en el servidor.

| Tabla | Para qué sirve |
|---|---|
| `profiles` | Perfil público: usuario, nombre, avatar |
| `profile_private` | Datos privados (fecha de nacimiento), nunca expuestos junto al perfil |
| `devices` | Dispositivos y tokens de notificación (cada usuario ve solo los suyos) |
| `friendships` | Una fila por pareja (`user_a < user_b`), estado `pending` o `accepted` |
| `blocks` | Bloqueos |
| `wallpaper_settings` | Controles del receptor: aceptar cambios, aprobación automática, pausa, límite por hora |
| `wallpaper_changes` | Cada cambio: emisor, receptor, estado, ruta temporal de la imagen |
| `reports` | Reportes de contenido |

| Amenaza | Defensa |
|---|---|
| Alguien cambia el fondo de un desconocido | Solo amistades aceptadas, comprobado en el servidor |
| Acoso repetido | Límite por hora, bloqueo, pausa, reportes |
| Imágenes ofensivas o ilegales | Cuarentena, moderación automática antes de entregar, reportes |
| Manipular la app para saltarse reglas | Los clientes no tienen permiso de escritura en las tablas críticas |
| Filtración de datos | RLS en todas las tablas, URLs firmadas de corta duración |
| Archivos maliciosos | Validar el tipo por los bytes, límite de tamaño, reprocesar la imagen |
| Ubicación en los metadatos | Se elimina el EXIF |

El mensaje push de la app real **no debe llevar la URL de la imagen**, solo el identificador del cambio. La app pide al servidor una URL firmada de corta duración y nunca descarga de una dirección arbitraria.

## Pendientes legales y de tiendas

- Política de privacidad y términos de uso.
- Edad mínima y consentimiento de anuncios (SDK UMP de AdMob).
- Google Play: función de **eliminar cuenta y datos**, reporte y bloqueo de usuarios dentro de la app, formulario de seguridad de datos.
- Colombia: Ley 1581 de 2012 (protección de datos personales).
- Contenido de abuso infantil: existen obligaciones legales de conservación y reporte que varían por país. Consultarlas antes de lanzar. Lo que la moderación marque como grave debe aislarse para revisión, no borrarse automáticamente.
- Windows: firmar el ejecutable o publicar en Microsoft Store para evitar la alerta de SmartScreen.
- Restringir la clave de API de Firebase a la app (nombre de paquete y huella de firma).

## Hoja de ruta

| Fase | Estado |
|---|---|
| Validación y legal | Pendiente |
| Diseño y modelo de datos | Hecho (ver apéndice) |
| Prueba de concepto de cambio de fondo | **Hecha** (Windows y Android, incluido segundo plano) |
| Backend en Supabase | Esquema diseñado, sin aplicar |
| Edge Function `send-wallpaper` (validar, moderar, subir, avisar) | Pendiente |
| Escucha en segundo plano en Windows | Pendiente |
| Prueba prolongada en Android (sin cable, de noche, versión de producción) | Pendiente |
| Moderación, reportes y bloqueo | Pendiente |
| Monetización | Pendiente |
| Pruebas cerradas y lanzamiento | Pendiente |

## Deuda técnica conocida

- En `poc_wallpaper/lib/wallpaper_service.dart`, la comprobación de error de Windows (`ok == 0`) compara tipos distintos y nunca detectaría un fallo. Corregir con la versión actual del paquete `win32`.
- El código de segundo plano debe pasar a **WorkManager** para imágenes grandes o redes lentas.
- La política `profiles_read` deja listar todos los perfiles; sustituirla por una búsqueda por nombre de usuario exacto.
- Faltan por crear: función de alta de perfil con límite de edad, buckets de Storage, función `send-wallpaper` y tarea programada de limpieza.
- Si la imagen ya se borró, el receptor no puede reportarla con evidencia: permitir reportar mientras está pendiente de aprobación y adjuntar la imagen desde su dispositivo.
- Varios dispositivos por usuario: la imagen debe seguir en el servidor hasta que todos la descarguen o caduque (o pasar a una tabla de entregas por dispositivo).

---

## Apéndice: esquema SQL propuesto

El esquema se diseñó pero puede que no se haya aplicado. Va como una migración (`supabase/migrations/`).

<details>
<summary>Migración 1: tablas, RLS y permisos</summary>

```sql
create extension if not exists citext with schema extensions;

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username citext unique not null check (username ~ '^[a-z0-9_]{3,20}$'),
  display_name text not null check (char_length(display_name) <= 40),
  avatar_url text,
  created_at timestamptz not null default now()
);

create table profile_private (
  user_id uuid primary key references profiles(id) on delete cascade,
  birth_date date not null
);

create table devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  platform text not null check (platform in ('android','windows')),
  push_token text,
  last_seen_at timestamptz not null default now(),
  unique (user_id, push_token)
);

create type friendship_status as enum ('pending','accepted');

create table friendships (
  user_a uuid not null references profiles(id) on delete cascade,
  user_b uuid not null references profiles(id) on delete cascade,
  requester_id uuid not null references profiles(id),
  status friendship_status not null default 'pending',
  created_at timestamptz not null default now(),
  primary key (user_a, user_b),
  check (user_a < user_b),
  check (requester_id in (user_a, user_b))
);
create index on friendships (user_b);

create table blocks (
  blocker_id uuid references profiles(id) on delete cascade,
  blocked_id uuid references profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

create table wallpaper_settings (
  user_id uuid primary key references profiles(id) on delete cascade,
  accept_changes boolean not null default true,
  auto_apply boolean not null default false,
  paused_until timestamptz,
  max_per_hour int not null default 5 check (max_per_hour between 1 and 30)
);

create type change_status as enum
  ('processing','rejected','pending_approval','delivered','applied','reverted','expired');

create table wallpaper_changes (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references profiles(id) on delete cascade,
  receiver_id uuid not null references profiles(id) on delete cascade,
  storage_path text,
  status change_status not null default 'processing',
  reject_reason text,
  image_deleted_at timestamptz,
  created_at timestamptz not null default now(),
  applied_at timestamptz,
  check (sender_id <> receiver_id)
);
create index on wallpaper_changes (receiver_id, created_at desc);
create index on wallpaper_changes (sender_id, created_at desc);

create table reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references profiles(id) on delete cascade,
  reported_user_id uuid not null references profiles(id) on delete cascade,
  change_id uuid references wallpaper_changes(id) on delete set null,
  reason text not null check (reason in ('sexual','violence','harassment','spam','other')),
  details text check (char_length(details) <= 500),
  status text not null default 'open',
  created_at timestamptz not null default now()
);

create function handle_new_profile() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into wallpaper_settings (user_id) values (new.id);
  return new;
end $$;

create trigger on_profile_created
  after insert on profiles
  for each row execute function handle_new_profile();

alter table profiles           enable row level security;
alter table profile_private    enable row level security;
alter table devices            enable row level security;
alter table friendships        enable row level security;
alter table blocks             enable row level security;
alter table wallpaper_settings enable row level security;
alter table wallpaper_changes  enable row level security;
alter table reports            enable row level security;

create policy profiles_read on profiles for select to authenticated using (true);
create policy profiles_update_own on profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

create policy private_read_own on profile_private for select to authenticated
  using (user_id = auth.uid());

create policy devices_own on devices for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy settings_read_own on wallpaper_settings for select to authenticated
  using (user_id = auth.uid());
create policy settings_update_own on wallpaper_settings for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy blocks_own on blocks for all to authenticated
  using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());

create policy friendships_read on friendships for select to authenticated
  using (auth.uid() in (user_a, user_b));

create policy changes_read on wallpaper_changes for select to authenticated
  using (auth.uid() in (sender_id, receiver_id));

create policy reports_insert on reports for insert to authenticated
  with check (reporter_id = auth.uid());

revoke all on profiles, profile_private, devices, friendships, blocks,
  wallpaper_settings, wallpaper_changes, reports from anon;

grant select, update on profiles to authenticated;
grant select on profile_private to authenticated;
grant select, insert, update, delete on devices to authenticated;
grant select on friendships to authenticated;
grant select, insert, delete on blocks to authenticated;
grant select, update on wallpaper_settings to authenticated;
grant select on wallpaper_changes to authenticated;
grant insert on reports to authenticated;

alter publication supabase_realtime add table wallpaper_changes;
```

</details>

<details>
<summary>Migración 2 (pendiente): reglas de negocio en el servidor</summary>

```sql
-- Decide si un emisor puede enviar a un receptor. Solo la llama el servidor.
create or replace function check_send_allowed(p_sender uuid, p_receiver uuid)
returns text language plpgsql security definer set search_path = public as $$
declare
  s wallpaper_settings%rowtype;
  a uuid := least(p_sender, p_receiver);
  b uuid := greatest(p_sender, p_receiver);
begin
  if not exists (select 1 from friendships
                 where user_a = a and user_b = b and status = 'accepted') then
    return 'not_friends';
  end if;

  if exists (select 1 from blocks
             where (blocker_id = p_receiver and blocked_id = p_sender)
                or (blocker_id = p_sender and blocked_id = p_receiver)) then
    return 'blocked';
  end if;

  select * into s from wallpaper_settings where user_id = p_receiver;
  if not found then return 'no_settings'; end if;
  if not s.accept_changes then return 'receiver_disabled'; end if;
  if s.paused_until is not null and s.paused_until > now() then
    return 'receiver_paused';
  end if;

  if (select count(*) from wallpaper_changes
      where sender_id = p_sender and receiver_id = p_receiver
        and created_at > now() - interval '1 hour') >= s.max_per_hour then
    return 'rate_limited';
  end if;

  return 'ok';
end $$;

revoke execute on function check_send_allowed(uuid, uuid) from public, anon, authenticated;

-- El receptor acepta o rechaza un cambio pendiente de aprobación.
create or replace function respond_to_change(p_change uuid, p_accept boolean)
returns change_status language plpgsql security definer set search_path = public as $$
declare
  new_status change_status;
begin
  update wallpaper_changes
     set status = case when p_accept then 'delivered'::change_status
                       else 'rejected'::change_status end,
         reject_reason = case when p_accept then null else 'declined_by_receiver' end
   where id = p_change
     and receiver_id = auth.uid()
     and status = 'pending_approval'
  returning status into new_status;

  if new_status is null then
    raise exception 'change_not_found_or_not_pending';
  end if;
  return new_status;
end $$;

revoke execute on function respond_to_change(uuid, boolean) from public, anon;
grant  execute on function respond_to_change(uuid, boolean) to authenticated;
```

Faltan por diseñar: alta de perfil con comprobación de edad, buckets de Storage con sus políticas, Edge Function `send-wallpaper` y la tarea programada que caduca cambios y borra imágenes con la API de Storage (no con SQL).

</details>
