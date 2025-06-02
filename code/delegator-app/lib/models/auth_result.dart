import 'user.dart';

class AuthResult {
  final bool success;
  final User? user;
  final String? error;

  AuthResult.success(this.user)
      : success = true,
        error = null;
  AuthResult.error(this.error)
      : success = false,
        user = null;
}
