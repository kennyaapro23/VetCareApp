import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_app/providers/auth_provider.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> with SingleTickerProviderStateMixin {
  File? _imageFile;
  late AnimationController _animController;
  bool _editing = false;
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameC.text = user.name;
      _emailC.text = user.email;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameC.dispose();
    _emailC.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _imageFile = File(image.path));
    }
  }

  void _toggleEdit() {
    setState(() => _editing = !_editing);
    if (_editing) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const Scaffold(body: Center(child: Text('Sin sesión')));

    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            actions: [
              IconButton(onPressed: _toggleEdit, icon: Icon(_editing ? Icons.check : Icons.edit)),
              IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Hero(
                      tag: 'profile_avatar',
                      child: GestureDetector(
                        onTap: _editing ? _pickImage : null,
                        child: Stack(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: _editing ? 130 : 120,
                              height: _editing ? 130 : 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, spreadRadius: 2),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                                child: _imageFile == null
                                    ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold))
                                    : null,
                              ),
                            ),
                            if (_editing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: theme.colorScheme.secondary,
                                  child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(user.role, style: const TextStyle(fontSize: 16, color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatsRow(),
                  const SizedBox(height: 24),
                  if (_editing) ...[
                    TextField(
                      controller: _nameC,
                      decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailC,
                      decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cambios guardados (función por implementar)'), backgroundColor: Colors.green),
                        );
                        _toggleEdit();
                      },
                      child: const Text('Guardar cambios'),
                    ),
                  ] else ...[
                    _InfoCard(title: 'Información Personal', children: [
                      _InfoTile(Icons.email, 'Correo', user.email),
                      _InfoTile(Icons.badge, 'Rol', user.role),
                      _InfoTile(Icons.fingerprint, 'ID', user.id),
                    ]),
                    const SizedBox(height: 16),
                    _InfoCard(title: 'Configuración', children: [
                      ListTile(
                        leading: const Icon(Icons.lock),
                        title: const Text('Cambiar contraseña'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                      ListTile(
                        leading: const Icon(Icons.notifications),
                        title: const Text('Notificaciones'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                      ListTile(
                        leading: const Icon(Icons.help),
                        title: const Text('Ayuda y soporte'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                    ]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatItem('12', 'Citas'),
        _StatItem('3', 'Mascotas'),
        _StatItem('8', 'Servicios'),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

