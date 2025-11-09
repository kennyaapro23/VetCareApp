import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_app/providers/auth_provider.dart';
import 'package:vetcare_app/models/service_model.dart';
import 'package:vetcare_app/models/appointment_model.dart';
import 'package:vetcare_app/services/vet_service_service.dart';
import 'package:vetcare_app/services/appointment_service.dart';
import 'package:vetcare_app/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class ServiciosScreen extends StatefulWidget {
  const ServiciosScreen({super.key});

  @override
  State<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends State<ServiciosScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<ServiceModel> _services = [];
  List<AppointmentModel> _appointments = [];
  bool _loadingServices = false;
  bool _loadingAppointments = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadServices();
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    setState(() => _loadingServices = true);
    try {
      final auth = context.read<AuthProvider>();
      final service = VetServiceService(auth.api);
      final data = await service.getServices();
      if (mounted) setState(() => _services = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando servicios: $e')));
    } finally {
      if (mounted) setState(() => _loadingServices = false);
    }
  }

  Future<void> _loadAppointments() async {
    setState(() => _loadingAppointments = true);
    try {
      final auth = context.read<AuthProvider>();
      final service = AppointmentService(auth.api);
      final data = await service.getAppointments();
      if (mounted) setState(() => _appointments = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando citas: $e')));
    } finally {
      if (mounted) setState(() => _loadingAppointments = false);
    }
  }

  Future<void> _createService() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _CreateServiceDialog(),
    );
    if (result != null) {
      setState(() => _loadingServices = true);
      try {
        final auth = context.read<AuthProvider>();
        final service = VetServiceService(auth.api);
        await service.createService(result);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Servicio creado exitosamente'), backgroundColor: Colors.green),
        );
        _loadServices();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _loadingServices = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios y Citas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.medical_services), text: 'Servicios'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Mis Citas'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              if (_tabController.index == 0) {
                _loadServices();
              } else {
                _loadAppointments();
              }
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Servicios Disponibles
          _buildServicesTab(),
          // Tab 2: Mis Citas
          _buildAppointmentsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _createService,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Servicio'),
            )
          : null,
    );
  }

  Widget _buildServicesTab() {
    if (_loadingServices) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_services.isEmpty) {
      return const Center(child: Text('No hay servicios registrados'));
    }
    return RefreshIndicator(
      onRefresh: _loadServices,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _services.length,
        itemBuilder: (context, i) => _ServiceCard(service: _services[i]),
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    if (_loadingAppointments) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }
    if (_appointments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 80, color: AppTheme.textSecondary),
            SizedBox(height: 16),
            Text('No tienes citas programadas', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAppointments,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _appointments.length,
        itemBuilder: (context, i) => _AppointmentCard(appointment: _appointments[i]),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;

  const _ServiceCard({required this.service});

  IconData _getIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('vacun')) return Icons.vaccines;
    if (t.contains('baño') || t.contains('bath')) return Icons.shower;
    if (t.contains('cort') || t.contains('groom')) return Icons.cut;
    if (t.contains('consult') || t.contains('control')) return Icons.medical_services;
    return Icons.pets;
  }

  Color _getColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('vacun')) return Colors.blue;
    if (t.contains('baño') || t.contains('bath')) return Colors.cyan;
    if (t.contains('cort') || t.contains('groom')) return Colors.purple;
    if (t.contains('consult') || t.contains('control')) return Colors.green;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = service.date != null ? DateFormat('dd/MM/yyyy').format(service.date!) : 'Sin fecha';
    final color = _getColor(service.type);
    final icon = _getIcon(service.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.type, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  if (service.description != null && service.description!.isNotEmpty)
                    Text(service.description!, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(dateStr, style: theme.textTheme.bodySmall),
                      if (service.cost != null) ...[
                        const SizedBox(width: 16),
                        const Icon(Icons.attach_money, size: 14, color: Colors.grey),
                        Text('\$${service.cost!.toStringAsFixed(2)}', style: theme.textTheme.bodySmall),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;

  const _AppointmentCard({required this.appointment});

  void _navigateToPetProfile(BuildContext context) {
    if (appointment.petId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede abrir el perfil: ID de mascota no disponible'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    // Navegar al perfil de la mascota usando GoRouter
    context.go('/pet-detail/${appointment.petId}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateStr = appointment.date != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(appointment.date!)
        : 'Sin fecha';

    Color statusColor = AppTheme.textSecondary;
    if (appointment.status == 'pendiente') statusColor = AppTheme.warningColor;
    if (appointment.status == 'confirmada') statusColor = AppTheme.primaryColor;
    if (appointment.status == 'atendida') statusColor = AppTheme.successColor;
    if (appointment.status == 'cancelada') statusColor = AppTheme.errorColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToPetProfile(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        appointment.status ?? 'Sin estado',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      dateStr,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (appointment.reason != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          appointment.reason!,
                          style: TextStyle(
                            color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.touch_app, size: 14, color: AppTheme.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      'Toca para ver perfil de la mascota',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateServiceDialog extends StatefulWidget {
  const _CreateServiceDialog();

  @override
  State<_CreateServiceDialog> createState() => _CreateServiceDialogState();
}

class _CreateServiceDialogState extends State<_CreateServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _petIdC = TextEditingController();
  final _descC = TextEditingController();
  final _costC = TextEditingController();
  String _serviceType = 'Vacunación';
  DateTime? _selectedDate;

  @override
  void dispose() {
    _petIdC.dispose();
    _descC.dispose();
    _costC.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona la fecha del servicio')));
      return;
    }
    Navigator.pop(context, {
      'mascota_id': _petIdC.text.trim(),
      'tipo_servicio': _serviceType,
      'descripcion': _descC.text.trim(),
      'fecha': _selectedDate!.toIso8601String(),
      'costo': double.tryParse(_costC.text.trim()) ?? 0.0,
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _selectedDate != null ? DateFormat('dd/MM/yyyy').format(_selectedDate!) : 'Seleccionar';

    return AlertDialog(
      title: const Text('Nuevo Servicio'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _petIdC,
                decoration: const InputDecoration(labelText: 'ID Mascota'),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _serviceType,
                items: const [
                  DropdownMenuItem(value: 'Vacunación', child: Text('Vacunación')),
                  DropdownMenuItem(value: 'Baño', child: Text('Baño')),
                  DropdownMenuItem(value: 'Corte de pelo', child: Text('Corte de pelo')),
                  DropdownMenuItem(value: 'Control general', child: Text('Control general')),
                  DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                ],
                onChanged: (v) => setState(() => _serviceType = v ?? 'Vacunación'),
                decoration: const InputDecoration(labelText: 'Tipo de servicio'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descC,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _costC,
                decoration: const InputDecoration(labelText: 'Costo'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(dateStr),
                onTap: _pickDate,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _submit, child: const Text('Crear')),
      ],
    );
  }
}

