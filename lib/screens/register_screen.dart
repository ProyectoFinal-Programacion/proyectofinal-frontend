import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'worker_onboarding_screen.dart';

class RegisterScreen extends StatefulWidget {
  static const route = '/register';
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'Client';
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
                      const Text('Crear cuenta', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (v) => v == null || v.isEmpty ? 'Ingresa tu nombre' : null,
                      ),
                      const SizedBox(height: 12),
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
                        validator: (v) => v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _role,
                        items: const [
                          DropdownMenuItem(value: 'Client', child: Text('Cliente')),
                          DropdownMenuItem(value: 'Worker', child: Text('Trabajador')),
                        ],
                        onChanged: (v) => setState(() => _role = v ?? 'Client'),
                        decoration: const InputDecoration(labelText: 'Rol'),
                      ),
                      const SizedBox(height: 12),
                      if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: auth.busy ? null : () async {
                          if (!_formKey.currentState!.validate()) return;
                          try {
                            await context.read<AuthProvider>().register(_name.text.trim(), _email.text.trim(), _password.text, _role);
                            if (mounted) {
                              if (_role == 'Worker') {
                                await Navigator.pushNamed(context, WorkerOnboardingScreen.route);
                                Navigator.pushReplacementNamed(context, HomeScreen.route);
                              } else {
                                Navigator.pushReplacementNamed(context, HomeScreen.route);
                              }
                            }
                          } catch (e) {
                            setState(() => _error = e.toString());
                          }
                        },
                        child: auth.busy ? const CircularProgressIndicator() : const Text('Registrarme'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, LoginScreen.route),
                        child: const Text('Ya tengo cuenta'),
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
