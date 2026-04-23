/// Form validation utilities.
class Validators {
  Validators._();

  static String? required(String? value, [String fieldName = 'Ce champ']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final regex = RegExp(r'^\+?[\d\s\-]{8,}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Numero de telephone invalide';
    }
    return null;
  }
}
