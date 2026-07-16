# Coffee App

Aplicación Flutter para administración y venta de café.

## Requisitos

- Flutter >= 3.0.0
- Android SDK Platform 36
- Android SDK Build-Tools 36.x
- Android SDK Platform-Tools
- Dispositivo físico o emulador Android
- Xcode y CocoaPods solo si quieres compilar en iOS

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

## Archivo de requisitos

Revisa `requirements.txt` para ver las dependencias y herramientas necesarias.
