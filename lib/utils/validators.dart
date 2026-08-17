class Validators {
  Validators._();

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Mobile number is required';
    final clean = value.replaceAll(RegExp(r'\D'), '');
    final effective = clean.length > 10 && clean.startsWith('91') ? clean.substring(2) : clean;

    if (effective.length != 10) return 'Enter a valid 10-digit mobile number';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(effective)) {
      return 'Mobile number must start with 6, 7, 8, or 9';
    }
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter OTP';
    if (value.trim().length < 4) return 'Enter the OTP code';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full Name is required';
    if (value.trim().length < 3) return 'Name must be at least 3 characters';
    if (!RegExp(r"^[a-zA-Z\s\.]+$").hasMatch(value.trim())) {
      return 'Name should only contain letters and spaces';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional
    final regex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? notEmpty(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }
}
