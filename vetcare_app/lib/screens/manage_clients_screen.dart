import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_app/models/client_model.dart';
import 'package:vetcare_app/models/pet_model.dart';
import 'package:vetcare_app/services/api_service.dart';
import 'package:vetcare_app/services/client_service.dart';
import 'package:vetcare_app/theme/app_theme.dart';
import 'create_user_screen.dart';
import 'crear_factura_historiales_screen.dart'; // ⭐ NUEVO

class ManageClientsScreen extends StatefulWidget {
  const ManageClientsScreen({super.key});

  @override
  State<ManageClientsScreen> createState() => _ManageClientsScreenState();
}

class _ManageClientsScreenState extends State<ManageClientsScreen> {
  List<ClientModel> _clients = [];
  List<ClientModel> _filteredClients = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);
    try {
      final apiService = context.read<ApiService>();
      final clientService = ClientService(apiService);
      final clients = await clientService.getClients();
      setState(() {
        _clients = clients;
        _filteredClients = clients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar clientes: $e')),
        );
      }
    }
  }

  void _filterClients(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredClients = _clients;
      } else {
        _filteredClients = _clients.where((client) {
          final nameLower = client.name.toLowerCase();
          final phoneLower = client.phone?.toLowerCase() ?? '';
          final emailLower = client.email?.toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return nameLower.contains(searchLower) ||
              phoneLower.contains(searchLower) ||
              emailLower.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _deleteClient(ClientModel client) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar a ${client.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final apiService = context.read<ApiService>();
        final clientService = ClientService(apiService);
        await clientService.deleteClient(client.id);
        _loadClients();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cliente eliminado exitosamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar cliente: $e')),
          );
        }
      }
    }
  }

  void _showClientDetails(ClientModel client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ClientDetailsSheet(client: client),
    );
  }

  void _showClientForm({ClientModel? client}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ClientFormScreen(client: client),
      ),
    );
    if (result == true) {
      _loadClients();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Clientes'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'create_user',
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    const Text('Crear Usuario del Sistema'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: const [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Actualizar Lista'),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'create_user') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateUserScreen()),
                );
                if (result == true) _loadClients();
              } else if (value == 'refresh') {
                _loadClients();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterClients,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, teléfono o email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterClients('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredClients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty ? 'No hay clientes registrados' : 'No se encontraron clientes',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadClients,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredClients.length,
                          itemBuilder: (context, index) {
                            final client = _filteredClients[index];
                            return _ClientCard(
                              client: client,
                              isDark: isDark,
                              onTap: () => _showClientDetails(client),
                              onEdit: () => _showClientForm(client: client),
                              onDelete: () => _deleteClient(client),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showClientForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Cliente'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final ClientModel client;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClientCard({
    required this.client,
    required this.isDark,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      client.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(client.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      if (client.phone != null)
                        Row(
                          children: [
                            Icon(Icons.phone, size: 14, color: isDark ? AppTheme.textSecondary : AppTheme.textLight),
                            const SizedBox(width: 4),
                            Text(client.phone!, style: TextStyle(fontSize: 13, color: isDark ? AppTheme.textSecondary : AppTheme.textLight)),
                          ],
                        ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.pets, size: 14, color: isDark ? AppTheme.textSecondary : AppTheme.textLight),
                          const SizedBox(width: 4),
                          Text('${client.pets.length} mascota(s)', style: TextStyle(fontSize: 13, color: isDark ? AppTheme.textSecondary : AppTheme.textLight)),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'factura',
                      child: Row(children: const [
                        Icon(Icons.receipt_long, size: 20, color: AppTheme.primaryColor),
                        SizedBox(width: 12),
                        Text('Crear Factura', style: TextStyle(color: AppTheme.primaryColor))
                      ]),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(children: const [Icon(Icons.edit, size: 20), SizedBox(width: 12), Text('Editar')]),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(children: [Icon(Icons.delete, size: 20, color: AppTheme.errorColor), const SizedBox(width: 12), Text('Eliminar', style: TextStyle(color: AppTheme.errorColor))]),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'factura') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CrearFacturaHistorialesScreen(clienteInicial: client),
                        ),
                      );
                    } else if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClientDetailsSheet extends StatelessWidget {
  final ClientModel client;

  const _ClientDetailsSheet({required this.client});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(color: isDark ? AppTheme.darkCard : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Center(child: Text(client.name.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primaryColor))),
                      ),
                      const SizedBox(height: 16),
                      Text(client.name, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text('Información de Contacto', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (client.phone != null) _InfoRow(icon: Icons.phone, label: 'Teléfono', value: client.phone!, isDark: isDark),
                if (client.email != null) _InfoRow(icon: Icons.email, label: 'Email', value: client.email!, isDark: isDark),
                if (client.address != null) _InfoRow(icon: Icons.location_on, label: 'Dirección', value: client.address!, isDark: isDark),
                const SizedBox(height: 24),
                Text('Mascotas (${client.pets.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (client.pets.isEmpty)
                  Center(child: Text('No hay mascotas registradas', style: TextStyle(color: isDark ? AppTheme.textSecondary : AppTheme.textLight)))
                else
                  ...client.pets.map((pet) => _PetCard(pet: pet, isDark: isDark)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({required this.icon, required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 20, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textSecondary : AppTheme.textLight)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final PetModel pet;
  final bool isDark;

  const _PetCard({required this.pet, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.secondaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(pet.species.toLowerCase() == 'perro' ? Icons.pets : Icons.catching_pokemon, color: AppTheme.secondaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pet.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text('${pet.species} • ${pet.breed}', style: TextStyle(fontSize: 13, color: isDark ? AppTheme.textSecondary : AppTheme.textLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientFormScreen extends StatefulWidget {
  final ClientModel? client;

  const _ClientFormScreen({this.client});

  @override
  State<_ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<_ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client?.name);
    _phoneController = TextEditingController(text: widget.client?.phone);
    _emailController = TextEditingController(text: widget.client?.email);
    _addressController = TextEditingController(text: widget.client?.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiService = context.read<ApiService>();
      final clientService = ClientService(apiService);

      final data = {
        'nombre': _nameController.text.trim(),
        'telefono': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'direccion': _addressController.text.trim(),
      };

      if (widget.client == null) {
        await clientService.createClient(data);
      } else {
        await clientService.updateClient(widget.client!.id, data);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.client == null ? 'Cliente creado exitosamente' : 'Cliente actualizado exitosamente')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.client == null ? 'Nuevo Cliente' : 'Editar Cliente')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nombre completo *', prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'El nombre es requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Teléfono *', prefixIcon: const Icon(Icons.phone), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              keyboardType: TextInputType.phone,
              validator: (value) => (value == null || value.trim().isEmpty) ? 'El teléfono es requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(labelText: 'Dirección', prefixIcon: const Icon(Icons.location_on), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveClient,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                    : Text(widget.client == null ? 'Crear Cliente' : 'Guardar Cambios', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

