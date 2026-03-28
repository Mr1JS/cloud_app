class Validators {
  static String? email(String? input) {
    if (input == null || input.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(input) ? null : 'Invalid email';
  }

  static String? password(String? input, {bool isLogin = false}) {
    if (input == null || input.isEmpty) return 'Password is required';
    if (isLogin) return null;
    if (input.length < 6) {
      return 'Password must have upper & lower case, min 6 chars';
    }
    final hasUpper = RegExp(r'[A-Z]').hasMatch(input);
    final hasLower = RegExp(r'[a-z]').hasMatch(input);
    return (hasUpper && hasLower)
        ? null
        : 'Password must have upper & lower case, min 6 chars';
  }
}
