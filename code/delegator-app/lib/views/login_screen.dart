// lib/views/login_screen.dart

import '../models/auth_result.dart';
import 'package:flutter/material.dart';
import '../services/service_registry.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isLoginMode = true; // true = login, false = register
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLastUsername();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadLastUsername() async {
    final lastUsername = await ServiceRegistry().authService.getLastUsername();
    final rememberMe =
        await ServiceRegistry().authService.isRememberMeEnabled();

    if (lastUsername != null) {
      _usernameController.text = lastUsername;
    }

    setState(() {
      _rememberMe = rememberMe;
    });
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    AuthResult result;

    result = _isLoginMode ? await _performLogin() : await _performRegister();

    setState(() {
      _isLoading = false;
      if (!result.success) {
        _errorMessage = result.error;
      }
    });
  }

  Future<AuthResult> _performLogin() async {
    try {
      final result = await ServiceRegistry().authService.login(
            _usernameController.text.trim(),
            _passwordController.text,
            rememberMe: _rememberMe,
          );
      return result;
    } catch (e) {
      if (e.toString().contains("No active account found")) {
        return AuthResult.error("Invalid credentials");
      }
      return AuthResult.error(e.toString());
    }
  }

  Future<AuthResult> _performRegister() async {
    try {
      final result = await ServiceRegistry().authService.register(
            _usernameController.text.trim(),
            _passwordController.text,
            rememberMe: _rememberMe,
          );
      return result;
    } catch (e) {
      if (e.toString().contains("username already exists")) {
        return AuthResult.error("Username already taken");
      }
      return AuthResult.error(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo/App Name
                Icon(Icons.account_circle, size: 80, color: Colors.blue[600]),
                const SizedBox(height: 24),
                Text(
                  'Welcome to Delegator',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoginMode ? 'Sign in to continue' : 'Create your account',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Username Field
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'Enter your username',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your username';
                    }
                    if (!_isLoginMode && value.trim().length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (!_isLoginMode && value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Remember Me Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _rememberMe = !_rememberMe;
                        });
                      },
                      child: Text(
                        'Remember me',
                        style: TextStyle(color: Colors.grey[700], fontSize: 16),
                      ),
                    ),
                    const Spacer(),
                    if (_isLoginMode)
                      TextButton(
                        onPressed: () {
                          // TODO: Implement forgot password
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Forgot password feature coming soon!',
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.blue[600]),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Error Message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _isLoginMode ? 'Sign In' : 'Create Account',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Toggle Mode Button
                TextButton(
                  onPressed: _toggleMode,
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      children: [
                        TextSpan(
                          text: _isLoginMode
                              ? "Don't have an account? "
                              : "Already have an account? ",
                        ),
                        TextSpan(
                          text: _isLoginMode ? 'Sign Up' : 'Sign In',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Development/Debug Section
                if (const bool.fromEnvironment('dart.vm.product') == false) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Development Mode',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      _usernameController.text = 'test_user_2';
                      _passwordController.text = 'sml12345';
                      await _submit();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Quick Login (Dev)'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      await ServiceRegistry().authService.clearAllAuthData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All auth data cleared')),
                      );
                    },
                    child: Text(
                      'Clear All Auth Data',
                      style: TextStyle(color: Colors.red[600]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
