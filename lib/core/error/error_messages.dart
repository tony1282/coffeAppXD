// core/error/error_messages.dart

class ErrorMessages {
  static const String noInternet = 'Sin conexión a internet';

  static const String sessionExpired =
      'Tu sesión expiró. Por favor inicia sesión nuevamente';

  static const String forbidden =
      'No tienes permiso para realizar esta acción';

  static const String notFound =
      'El recurso solicitado no fue encontrado';

  static const String badRequest =
      'La solicitud no es válida';

  static const String tooManyRequests =
      'Demasiadas solicitudes. Intenta en un momento';

  static const String serverError =
      'Error en el servidor. Intenta más tarde';

  static const String unknown =
      'Ocurrió un error inesperado. Intenta de nuevo';

  static const String uploadFailed =
      'No se pudo subir la imagen. Intenta de nuevo';

  static const String imageTooLarge =
      'La imagen excede el tamaño máximo permitido (5 MB)';

  static const String imageInvalidType =
      'Tipo de archivo no permitido. Usa JPG, PNG o WebP';

  static const String timeout =
      'La solicitud tardó demasiado. Verifica tu conexión';

  static const String rateLimited =
      'Demasiadas solicitudes. Espera un momento';

  static const String invalidResponse =
      'Respuesta del servidor no válida';

  // AUTH
  static const String invalidCredentials =
      'Correo o contraseña incorrectos';

  static const String emailAlreadyInUse =
      'Este correo ya está registrado';

  static const String weakPassword =
      'La contraseña debe tener al menos 6 caracteres';

  static const String userDisabled =
      'Esta cuenta ha sido deshabilitada';

  static const String invalidEmail =
      'Correo electrónico inválido';

  static const String invalidName =
      'Nombre inválido';

  static const String invalidPhone =
      'Número telefónico inválido';

  static const String accountIncomplete =
      'La información de la cuenta está incompleta';

  static const String googleFailed =
      'No fue posible iniciar sesión con Google';

  static const String googleCancelled =
      'Inicio de sesión cancelado';
}