// core/utils/validators.dart

class Validators {
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'El correo es obligatorio';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Correo inválido';
    }
    return null;
  }
  
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (password.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }
  
  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }
    return null;
  }
  
  static String? validatePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return null; // Opcional
    }
    final phoneRegex = RegExp(r'^[0-9+\-\s()]+$');
    if (!phoneRegex.hasMatch(phone.trim())) {
      return 'Teléfono inválido';
    }
    return null;
  }
  
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email.trim());
  }
  
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }
  
  static bool isValidName(String name) {
    return name.trim().isNotEmpty;
  }
  
  static bool isValidPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return true;
    final phoneRegex = RegExp(r'^[0-9+\-\s()]+$');
    return phoneRegex.hasMatch(phone.trim());
  }
}