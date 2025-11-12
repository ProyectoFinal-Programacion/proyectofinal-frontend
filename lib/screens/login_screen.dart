import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  static const route = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _error;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('ManoVecina', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Inicia sesión para continuar'),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) => v == null || v.isEmpty ? 'Ingresa tu email' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        decoration: const InputDecoration(labelText: 'Contraseña'),
                        obscureText: true,
                        validator: (v) => v == null || v.isEmpty ? 'Ingresa tu contraseña' : null,
                      ),
                      const SizedBox(height: 12),
                      if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: auth.busy ? null : () async {
                          if (!_formKey.currentState!.validate()) return;
                          try {
                            await context.read<AuthProvider>().login(_email.text.trim(), _password.text);
                            if (mounted) Navigator.pushReplacementNamed(context, HomeScreen.route);
                          } catch (e) {
                            setState(() => _error = e.toString());
                          }
                        },
                        child: auth.busy ? const CircularProgressIndicator() : const Text('Ingresar'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, RegisterScreen.route),
                        child: const Text('Crear cuenta'),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
