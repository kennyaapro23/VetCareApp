import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_app/providers/auth_provider.dart';
import 'package:vetcare_app/widgets/rounded_input.dart';
import 'package:vetcare_app/widgets/primary_button.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await auth.login(_emailC.text.trim(), _passC.text.trim());
    if (ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bienvenido a VetCareApp')));
      // Navegar a la pantalla principal de la app real.
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error ?? 'Error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 600;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 800 : 420),
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary]),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              'VetCare',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              RoundedInput(controller: _emailC, hintText: 'Correo electrónico', icon: Icons.email, keyboardType: TextInputType.emailAddress),
                              const SizedBox(height: 12),
                              RoundedInput(controller: _passC, hintText: 'Contraseña', icon: Icons.lock, obscureText: true),
                              const SizedBox(height: 18),
                              PrimaryButton(onPressed: () => _submit(auth), label: 'Iniciar sesión', loading: auth.isLoading),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(onPressed: () {}, child: const Text('¿Olvidaste tu contraseña?')),
                                  const SizedBox(width: 8),
                                  TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegisterScreen()));
                                      },
                                      child: const Text('Crear cuenta')),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(onPressed: () {}, icon: const Icon(Icons.apple)),
                                  IconButton(onPressed: () {}, icon: const Icon(Icons.facebook)),
                                  IconButton(onPressed: () {}, icon: const Icon(Icons.g_mobiledata)),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
