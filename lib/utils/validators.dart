class Validators {
  static String? requiredField(String? value, [String fieldName = 'Field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional if empty, but if filled must be valid
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? number(String? value, [String fieldName = 'Value']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final numValue = double.tryParse(value.trim());
    if (numValue == null || numValue < 0) {
      return 'Enter a valid positive number';
    }
    return null;
  }

  static String? integer(String? value, [String fieldName = 'Quantity']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final intValue = int.tryParse(value.trim());
    if (intValue == null || intValue <= 0) {
      return 'Enter a valid quantity (> 0)';
    }
    return null;
  }
}
