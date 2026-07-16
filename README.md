# Coffee App

Aplicación Flutter para administración y venta de café.

## Resumen general

Esta app está organizada con una arquitectura simple pero bastante clara:

- La capa de datos maneja modelos, repositorios, servicios y fuentes de datos.
- La capa de dominio define los contratos y la lógica de negocio.
- La capa de presentación contiene pantallas, widgets y providers.

El punto de entrada principal es la app en `lib/main.dart`, donde se inicializan Firebase, Hive y los providers globales.

## Estructura del proyecto

- `lib/core`: constantes, tema, utilidades, manejo de errores y configuración general.
- `lib/data`: modelos, repositorios, datasources, servicios de Firebase/API y persistencia local.
- `lib/domain`: contratos de repositorios y lógica de negocio.
- `lib/presentation`: pantallas, widgets y providers que alimentan la UI.
- `assets/`: imágenes y recursos estáticos.

## Cómo funciona la app

1. Al arrancar, `main.dart` inicializa los servicios base.
2. Se monta `MultiProvider` para compartir estado global entre pantallas.
3. `_AuthGate` escucha el estado de autenticación y decide si mostrar login, home o admin.
4. Cada pantalla usa providers para cargar datos, actualizar estado y mostrar errores.

## Providers principales

Los providers son el corazón del estado de la app. Cada uno se encarga de un dominio concreto y notifica a la UI cuando cambia algo.

- `AuthProvider`: maneja autenticación, login con email/Google, registro, logout y carga del perfil del usuario.
- `ProductProvider`: administra productos, carga la lista, crea/actualiza/elimina productos y valida datos.
- `CartProvider`: controla el carrito, guarda items, valida cantidades y sincroniza con backend/local.
- `OrderProvider`: administra pedidos, cambia estados, procesa reembolsos y gestiona la lista de pedidos activos.
- `PaymentProvider`: gestiona pagos, preferencias de Mercado Pago, validaciones de monto y bloqueo de operaciones duplicadas.
- `SaleProvider`: consulta información de ventas y genera reportes por periodo (día, semana, mes).
- `AdminProvider`: está pensado para administración de pedidos y panel de admin, aunque conviene revisar si realmente se está usando.

### Importante sobre los providers

- Se registran en `MultiProvider` desde `lib/main.dart`.
- Las pantallas consumen el estado con `context.watch`, `context.read` o `context.select` según el caso.
- Cuando un provider cambia, la UI se reconstruye automáticamente.

## Flujo típico de la app

- Login/registro: `AuthProvider`
- Ver productos y agregar al carrito: `ProductProvider` + `CartProvider`
- Crear pedido y pagar: `PaymentProvider` + `OrderProvider`
- Panel administrativo: `OrderProvider` + `ProductProvider` + `SaleProvider`

## Requisitos

- Flutter >= 3.0.0
- Android SDK Platform 36
- Android SDK Build-Tools 36.x
- Android SDK Platform-Tools
- Java JDK 11 o superior
- Dispositivo físico o emulador Android
- Xcode y CocoaPods solo si quieres compilar en iOS

## Verificar que todo esté bien

Antes de ejecutar, revisa que el entorno esté completo:

- Ejecuta `flutter doctor` y corrige las advertencias o errores.
- Asegúrate de tener conectada una prueba con un teléfono real o un emulador funcional.
- Para un teléfono real, activa las opciones de desarrollador y el modo de depuración USB.
- Comprueba que todos los módulos necesarios estén instalados:
  - `flutter pub get` para paquetes Dart/Flutter.
  - Android SDK platform tools y build tools.
  - Si compilas iOS, instala CocoaPods y ejecuta `pod install` en `ios/`.
- Verifica las configuraciones de Firebase y los archivos de configuración en Android e iOS.

## Dependencias

Todas las dependencias están definidas en `pubspec.yaml`.

## Configuración inicial

1. Clona el repositorio.
2. Instala Flutter y agrega `flutter` al PATH.
3. Asegúrate de tener Android SDK y un emulador o dispositivo conectado.
4. Copia los archivos de Firebase:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
5. Ejecuta:

```bash
flutter pub get
```

6. Si usas Hive con código generado:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Para ejecutar

```bash
flutter run
```

## Para compilar release

```bash
flutter build appbundle
```

## Notas

- Asegúrate de configurar un `applicationId` válido en `android/app/build.gradle.kts`.
- Si el proyecto usa Firebase, revisa que tus claves estén correctamente importadas.
- Si tienes problemas con Gradle, actualiza `android/gradle/wrapper/gradle-wrapper.properties`.

## Lo que falta arreglar antes de subir

### Package name

Hoy tienes `com.example.coffe_app`.
Para Google Play necesitas un identificador único tipo `com.tuempresa.coffeapp`.
Esto también debe coincidir con `applicationId` en `build.gradle.kts`.

### Firma de la app

Para publicar necesitas un release firmado con tu propio keystore.
El build de debug no es válido para Play Store.

### Permisos y políticas de Android

Tienes permisos sensibles como `WRITE_EXTERNAL_STORAGE`, `READ_EXTERNAL_STORAGE`, `CAMERA`.
En Android 13 ya no se usan igual, y Play revisa el uso de permisos.
Revisa si realmente necesitas todos esos permisos y si pides permiso en tiempo de ejecución.

### Pruebas de flujo

Hay que validar casos reales:
- usuario sin internet
- login fallido
- token expirado / sesión cerrada
- errores de pago
- formularios incompletos

Si hay algún null o excepción no manejada, un usuario puede hacer que la app se caiga.

### UI/UX y datos

Asegúrate de validar entradas de usuario en formularios (correo, contraseña, cantidades, teléfono, etc.).
Verifica que el número telefónico sea válido y no acepte formatos inválidos o muy largos.
Si no validas bien, el usuario puede “romperla” con datos inesperados.

### ¿Puede un usuario romper la app?

Sí, puede si hay rutas no manejadas, servicios que fallan o datos inválidos.
Para evitarlo necesitas:
- manejar errores de red/excepciones
- usar validaciones en formularios
- hacer tests en escenarios fallidos
- cerrar sesiones correctamente

### Recomendación inmediata

Antes de publicar, haz esto:

- Cambia `com.example.coffe_app` por un package único
- Configura el keystore de release
- Prueba `flutter build appbundle --release`
- Revisa permisos en `AndroidManifest.xml`
- Prueba el app bundle en un dispositivo real
- Haz un test completo de los flujos clave

### Pendientes técnicos que conviene revisar

- `AdminProvider` existe pero no aparece registrado en `MultiProvider`.
- `CartProvider.init()` existe, pero no parece invocarse en el arranque de la app.
- Conviene revisar si el carrito debe inicializarse tras iniciar sesión o al entrar a home.
- Falta una capa más clara de tests para auth, carrito, pedidos y pagos.
- Sería bueno documentar mejor los endpoints y los contratos de respuesta de la API.

## Archivo de requisitos

Revisa `requirements.txt` para ver las dependencias y herramientas necesarias.
