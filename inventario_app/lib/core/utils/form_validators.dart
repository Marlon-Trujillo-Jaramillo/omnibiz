abstract final class FormValidators {
  static String? required(String? value, [String fieldName = 'Este campo']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    return null;
  }

  static String? positiveNumber(String? value, [String fieldName = 'El valor']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    final n = double.tryParse(value.trim());
    if (n == null) return '$fieldName debe ser un número válido';
    if (n <= 0) return '$fieldName debe ser mayor a 0';
    return null;
  }

  static String? nonNegativeInt(String? value, [String fieldName = 'El valor']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    final n = int.tryParse(value.trim());
    if (n == null) return '$fieldName debe ser un número entero';
    if (n < 0) return '$fieldName no puede ser negativo';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final digits = value.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) return 'Teléfono inválido';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final pattern = RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$');
    if (!pattern.hasMatch(value.trim())) return 'Correo electrónico inválido';
    return null;
  }

  static String? pin(String? value) {
    if (value == null || value.isEmpty) return 'PIN obligatorio';
    if (value.length != 4) return 'El PIN debe tener 4 dígitos';
    if (!RegExp(r'^\d{4}$').hasMatch(value)) return 'Solo se permiten dígitos';
    return null;
  }

  // Combina validators
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final v in validators) {
        final result = v(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}
