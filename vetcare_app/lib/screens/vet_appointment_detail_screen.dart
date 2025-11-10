import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_app/providers/auth_provider.dart';
import 'package:vetcare_app/services/appointment_service.dart';
import 'package:vetcare_app/services/pet_service.dart';
import 'package:vetcare_app/services/historial_medico_service.dart';
import 'package:vetcare_app/models/appointment_model.dart';
import 'package:vetcare_app/models/pet_model.dart';
import 'package:vetcare_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class VetAppointmentDetailScreen extends StatefulWidget {
  final AppointmentModel appointment;

  const VetAppointmentDetailScreen({super.key, required this.appointment});

  @override
  State<VetAppointmentDetailScreen> createState() => _VetAppointmentDetailScreenState();
}

class _VetAppointmentDetailScreenState extends State<VetAppointmentDetailScreen> {
  PetModel? _pet;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPetDetails();
  }

  Future<void> _loadPetDetails() async {
    try {
      final auth = context.read<AuthProvider>();
      final service = PetService(auth.api);
      final pet = await service.getPet(widget.appointment.petId);
      if (mounted) {
        setState(() {
          _pet = pet;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      final auth = context.read<AuthProvider>();
      final service = AppointmentService(auth.api);

      // Actualizar estado (el backend debe soportar esto)
      await service.cancelAppointment(widget.appointment.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado a: $newStatus'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<void> _startConsultation() async {
    // Navegar a pantalla de registrar consulta
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterConsultationScreen(
          appointment: widget.appointment,
          pet: _pet!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Cita'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'confirm', child: Text('Confirmar')),
              const PopupMenuItem(value: 'complete', child: Text('Completar')),
              const PopupMenuItem(value: 'cancel', child: Text('Cancelar')),
            ],
            onSelected: (value) {
              if (value == 'confirm') _updateStatus('confirmada');
              if (value == 'complete') _updateStatus('completada');
              if (value == 'cancel') _updateStatus('cancelada');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información de la Cita
                  _buildSection(
                    'Información de la Cita',
                    [
                      _buildInfoRow(
                        'Fecha',
                        widget.appointment.date != null
                            ? DateFormat('EEEE, d MMMM yyyy', 'es').format(widget.appointment.date!)
                            : 'Pendiente',
                      ),
                      _buildInfoRow(
                        'Hora',
                        widget.appointment.date != null
                            ? DateFormat('HH:mm').format(widget.appointment.date!)
                            : '--:--',
                      ),
                      _buildInfoRow('Estado', (widget.appointment.status ?? 'pendiente').toUpperCase()),
                      if (widget.appointment.reason != null)
                        _buildInfoRow('Motivo', widget.appointment.reason!),
                    ],
                    isDark,
                  ),

                  const SizedBox(height: 16),

                  // Información del Paciente
                  if (_pet != null)
                    _buildSection(
                      'Información del Paciente',
                      [
                        _buildInfoRow('Nombre', _pet!.name),
                        _buildInfoRow('Especie', _pet!.species),
                        _buildInfoRow('Raza', _pet!.breed),
                        if (_pet!.age != null) _buildInfoRow('Edad', '${_pet!.age} años'),
                        if (_pet!.weight != null) _buildInfoRow('Peso', '${_pet!.weight} kg'),
                      ],
                      isDark,
                    ),

                  const SizedBox(height: 24),

                  // Botones de Acción
                  if ((widget.appointment.status ?? 'pendiente').toLowerCase() == 'pendiente')
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _updateStatus('confirmada'),
                            icon: const Icon(Icons.check_circle),
                            label: const Text('CONFIRMAR CITA'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _updateStatus('cancelada'),
                            icon: const Icon(Icons.cancel),
                            label: const Text('CANCELAR CITA'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.errorColor,
                              side: const BorderSide(color: AppTheme.errorColor),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),

                  if ((widget.appointment.status ?? 'pendiente').toLowerCase() == 'confirmada' && _pet != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _startConsultation,
                        icon: const Icon(Icons.medical_services),
                        label: const Text('INICIAR CONSULTA'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }
}

class RegisterConsultationScreen extends StatefulWidget {
  final AppointmentModel appointment;
  final PetModel pet;

  const RegisterConsultationScreen({
    super.key,
    required this.appointment,
    required this.pet,
  });

  @override
  State<RegisterConsultationScreen> createState() => _RegisterConsultationScreenState();
}

class _RegisterConsultationScreenState extends State<RegisterConsultationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosticoController = TextEditingController();
  final _tratamientoController = TextEditingController();
  final _observacionesController = TextEditingController();
  String _tipo = 'consulta';
  bool _isLoading = false;

  @override
  void dispose() {
    _diagnosticoController.dispose();
    _tratamientoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _saveConsultation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final service = HistorialMedicoService(auth.api);

      await service.crearRegistro({
        'mascota_id': widget.pet.id,
        'veterinario_id': auth.user?.id,
        'tipo': _tipo,
        'diagnostico': _diagnosticoController.text.trim(),
        'tratamiento': _tratamientoController.text.trim(),
        'observaciones': _observacionesController.text.trim(),
        'fecha': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Consulta registrada exitosamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Registrar Consulta'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Paciente
            Text('Paciente: ${widget.pet.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),

            // Tipo
            DropdownButtonFormField<String>(
              value: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo de Consulta'),
              items: const [
                DropdownMenuItem(value: 'consulta', child: Text('Consulta General')),
                DropdownMenuItem(value: 'vacuna', child: Text('Vacunación')),
                DropdownMenuItem(value: 'cirugia', child: Text('Cirugía')),
                DropdownMenuItem(value: 'revision', child: Text('Revisión')),
              ],
              onChanged: (value) => setState(() => _tipo = value!),
            ),
            const SizedBox(height: 16),

            // Diagnóstico
            TextFormField(
              controller: _diagnosticoController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Diagnóstico *'),
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),

            // Tratamiento
            TextFormField(
              controller: _tratamientoController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Tratamiento *'),
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),

            // Observaciones
            TextFormField(
              controller: _observacionesController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Observaciones'),
            ),
            const SizedBox(height: 32),

            // Botón Guardar
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveConsultation,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('GUARDAR CONSULTA'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

