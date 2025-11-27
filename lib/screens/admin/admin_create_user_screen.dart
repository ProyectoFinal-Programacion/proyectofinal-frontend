import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/enums.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/premium_cards.dart';
import '../../widgets/common/premium_inputs.dart';

class AdminCreateUserScreen extends StatefulWidget {
  const AdminCreateUserScreen({super.key});

  @override
  State<AdminCreateUserScreen> createState() => _AdminCreateUserScreenState();
}

class _AdminCreateUserScreenState extends State<AdminCreateUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  UserRole _role = UserRole.client;
  bool _saving = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final api = context.read<ApiClient>();
      final auth = AuthService(api);

      await auth.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        role: _role,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario creado correctamente')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear usuario: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Nuevo Usuario',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    PremiumCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Información del Usuario",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 20),
                          PremiumTextField(
                            controller: _nameCtrl,
                            labelText: "Nombre Completo",
                            prefixIcon: Icons.person,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Ingrese un nombre'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          PremiumTextField(
                            controller: _emailCtrl,
                            labelText: "Correo Electrónico",
                            prefixIcon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Ingrese un email';
                              }
                              if (!v.contains('@')) return 'Email inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          PremiumTextField(
                            controller: _phoneCtrl,
                            labelText: "Teléfono (Opcional)",
                            prefixIcon: Icons.phone,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<UserRole>(
                            value: _role,
                            items: const [
                              DropdownMenuItem(
                                value: UserRole.client,
                                child: Text('Cliente'),
                              ),
                              DropdownMenuItem(
                                value: UserRole.worker,
                                child: Text('Trabajador'),
                              ),
                              DropdownMenuItem(
                                value: UserRole.admin,
                                child: Text('Administrador'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Rol',
                              prefixIcon: const Icon(Icons.badge),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                            ),
                            onChanged: (value) {
                              if (value != null) setState(() => _role = value);
                            },
                          ),
                          const SizedBox(height: 16),
                          PremiumTextField(
                            controller: _passwordCtrl,
                            labelText: "Contraseña",
                            prefixIcon: Icons.lock,
                            obscureText: true,
                            validator: (v) => v == null || v.length < 6
                                ? 'Mínimo 6 caracteres'
                                : null,
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 24),
                    PremiumButton(
                      onPressed: _submit,
                      isLoading: _saving,
                      icon: Icons.person_add,
                      child: const Text("Crear Usuario"),
                    ).animate().scale(delay: 200.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
