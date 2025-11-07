import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_app/providers/auth_provider.dart';
import 'package:vetcare_app/models/appointment_model.dart';
import 'package:vetcare_app/services/appointment_service.dart';
import 'package:intl/intl.dart';

class CitasScreen extends StatefulWidget {
  const CitasScreen({super.key});

  @override
  State<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends State<CitasScreen> {
  String _filterStatus = 'todas';
  List<AppointmentModel> _appointments = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      final service = AppointmentService(auth.api);
      final status = _filterStatus == 'todas' ? null : _filterStatus;
      final data = await service.getAppointments(status: status);
      setState(() => _appointments = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _createAppointment() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _CreateAppointmentDialog(),
    );
    if (result != null) {
      setState(() => _loading = true);
      try {
        final auth = context.read<AuthProvider>();
        final service = AppointmentService(auth.api);
        await service.createAppointment(result);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cita creada exitosamente'), backgroundColor: Colors.green),
        );
        _loadAppointments();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _cancelAppointment(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar cita'),
        content: const Text('¿Estás seguro de cancelar esta cita?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí, cancelar')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final auth = context.read<AuthProvider>();
        final service = AppointmentService(auth.api);
        await service.cancelAppointment(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cita cancelada'), backgroundColor: Colors.orange),
        );
        _loadAppointments();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Citas'),
        actions: [
          IconButton(onPressed: _loadAppointments, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _appointments.isEmpty
                    ? const Center(child: Text('No hay citas'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _appointments.length,
                        itemBuilder: (context, i) => _AppointmentCard(
                          appointment: _appointments[i],
                          onCancel: () => _cancelAppointment(_appointments[i].id),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createAppointment,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Cita'),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip('Todas', 'todas'),
            _FilterChip('Pendiente', 'pendiente'),
            _FilterChip('Confirmada', 'confirmada'),
            _FilterChip('Atendida', 'atendida'),
            _FilterChip('Cancelada', 'cancelada'),
          ],
        ),
      ),
    );
  }

  Widget _FilterChip(String label, String value) {
    final selected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (val) {
          setState(() => _filterStatus = value);
          _loadAppointments();
        },
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onCancel;

  const _AppointmentCard({required this.appointment, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = appointment.date != null ? DateFormat('dd/MM/yyyy HH:mm').format(appointment.date!) : 'Sin fecha';

    Color statusColor = Colors.grey;
    if (appointment.status == 'pendiente') statusColor = Colors.orange;
    if (appointment.status == 'confirmada') statusColor = Colors.blue;
    if (appointment.status == 'atendida') statusColor = Colors.green;
    if (appointment.status == 'cancelada') statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const Spacer(),
                if (appointment.status == 'pendiente' || appointment.status == 'confirmada')
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    onPressed: onCancel,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(appointment.reason ?? 'Sin motivo', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(dateStr, style: theme.textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateAppointmentDialog extends StatefulWidget {
  const _CreateAppointmentDialog();

  @override
  State<_CreateAppointmentDialog> createState() => _CreateAppointmentDialogState();
}

class _CreateAppointmentDialogState extends State<_CreateAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _petIdC = TextEditingController();
  final _vetIdC = TextEditingController();
  final _reasonC = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _petIdC.dispose();
    _vetIdC.dispose();
    _reasonC.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null) setState(() => _selectedTime = time);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona fecha y hora')));
      return;
    }
    final dateTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute);
    Navigator.pop(context, {
      'mascota_id': _petIdC.text.trim(),
      'veterinario_id': _vetIdC.text.trim(),
      'motivo': _reasonC.text.trim(),
      'fecha': dateTime.toIso8601String(),
      'estado': 'pendiente',
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _selectedDate != null ? DateFormat('dd/MM/yyyy').format(_selectedDate!) : 'Seleccionar';
    final timeStr = _selectedTime != null ? _selectedTime!.format(context) : 'Seleccionar';

    return AlertDialog(
      title: const Text('Nueva Cita'),
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
              TextFormField(
                controller: _vetIdC,
                decoration: const InputDecoration(labelText: 'ID Veterinario'),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonC,
                decoration: const InputDecoration(labelText: 'Motivo'),
                maxLines: 2,
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(dateStr),
                onTap: _pickDate,
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(timeStr),
                onTap: _pickTime,
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

