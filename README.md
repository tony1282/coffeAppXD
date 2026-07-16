# Coffee App

Aplicación Flutter para administración y venta de café.

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

## Archivo de requisitos

Revisa `requirements.txt` para ver las dependencias y herramientas necesarias.
