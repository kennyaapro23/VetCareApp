import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vetcare_app/providers/auth_provider.dart';
import 'package:vetcare_app/services/client_service.dart';
import 'package:vetcare_app/theme/app_theme.dart';

/// Pantalla para registro rápido de clientes walk-in (sin cuenta de usuario)
/// Usado por recepcionistas para clientes que vienen sin cita previa
class QuickRegisterScreen extends StatefulWidget {
  const QuickRegisterScreen({super.key});

  @override
  State<QuickRegisterScreen> createState() => _QuickRegisterScreenState();
}

class _QuickRegisterScreenState extends State<QuickRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Datos del cliente
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _clientAddressController = TextEditingController();

  // Datos de la mascota
  final _petNameController = TextEditingController();
  final _petSpeciesController = TextEditingController();
  final _petBreedController = TextEditingController();
  final _petAgeController = TextEditingController();
  final _petWeightController = TextEditingController();
  final _petColorController = TextEditingController();
  String _petSexo = 'macho';

  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _clientEmailController.dispose();
    _clientAddressController.dispose();
    _petNameController.dispose();
    _petSpeciesController.dispose();
    _petBreedController.dispose();
    _petAgeController.dispose();
    _petWeightController.dispose();
    _petColorController.dispose();
    super.dispose();
  }

  Future<void> _registerQuick() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final clientService = ClientService(auth.api);

      // Llamar al endpoint de registro rápido del backend
      debugPrint('📝 Registrando cliente walk-in usando endpoint /registro-rapido');
      final response = await clientService.registroRapido(
        // Datos del cliente (requeridos)
        nombreCliente: _clientNameController.text.trim(),
        telefonoCliente: _clientPhoneController.text.trim(),
        // Datos del cliente (opcionales)
        emailCliente: _clientEmailController.text.trim().isEmpty
            ? null
            : _clientEmailController.text.trim(),
        direccionCliente: _clientAddressController.text.trim().isEmpty
            ? null
            : _clientAddressController.text.trim(),
        // Datos de la mascota (requeridos)
        nombreMascota: _petNameController.text.trim(),
        especieMascota: _petSpeciesController.text.trim(),
        sexoMascota: _petSexo,
        // Datos de la mascota (opcionales)
        razaMascota: _petBreedController.text.trim().isEmpty
            ? null
            : _petBreedController.text.trim(),
        colorMascota: _petColorController.text.trim().isEmpty
            ? null
            : _petColorController.text.trim(),
        pesoMascota: _petWeightController.text.isEmpty
            ? null
            : double.tryParse(_petWeightController.text),
        edadMascota: _petAgeController.text.isEmpty
            ? null
            : int.tryParse(_petAgeController.text),
      );

      if (mounted) {
        setState(() => _isLoading = false);

        // Mostrar dialog con QR code
        await _showSuccessDialog(response);

        // Cerrar pantalla y notificar éxito
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _showSuccessDialog(Map<String, dynamic> response) async {
    final cliente = response['cliente'];
    final mascota = response['mascota'];
    final qrCode = response['qr_code'];
    final qrUrl = response['qr_url'];

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.successColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '¡Registro Exitoso!',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Datos del cliente
              const Text(
                'Cliente Registrado:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.person,
                label: 'Nombre',
                value: cliente['nombre'] ?? '',
              ),
              _InfoRow(
                icon: Icons.phone,
                label: 'Teléfono',
                value: cliente['telefono'] ?? '',
              ),
              if (cliente['email'] != null && cliente['email'].toString().isNotEmpty)
                _InfoRow(
                  icon: Icons.email,
                  label: 'Email',
                  value: cliente['email'],
                ),
              const SizedBox(height: 16),

              // Datos de la mascota
              const Text(
                'Mascota Registrada:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.pets,
                label: 'Nombre',
                value: mascota['nombre'] ?? '',
              ),
              _InfoRow(
                icon: Icons.category,
                label: 'Especie',
                value: mascota['especie'] ?? '',
              ),
              if (mascota['raza'] != null && mascota['raza'].toString().isNotEmpty)
                _InfoRow(
                  icon: Icons.info,
                  label: 'Raza',
                  value: mascota['raza'],
                ),
              const SizedBox(height: 20),

              // QR Code
              const Text(
                'Código QR de la Mascota:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: qrCode ?? '',
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                qrCode ?? '',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              // TODO: Implementar impresión de QR
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función de impresión en desarrollo'),
                ),
              );
            },
            icon: const Icon(Icons.print),
            label: const Text('Imprimir QR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registro Rápido', style: TextStyle(fontSize: 18)),
            Text(
              'Cliente Walk-in (sin cuenta)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep == 0) {
              // Validar datos del cliente
              if (_clientNameController.text.trim().isEmpty ||
                  _clientPhoneController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Complete nombre y teléfono del cliente'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
                return;
              }
              setState(() => _currentStep = 1);
            } else {
              // Validar datos de mascota
              if (_petNameController.text.trim().isEmpty ||
                  _petSpeciesController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Complete nombre y especie de la mascota'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
                return;
              }
              // Registrar todo
              _registerQuick();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep -= 1);
            } else {
              Navigator.pop(context);
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(_currentStep == 0 ? Icons.arrow_forward : Icons.check_circle),
                      label: Text(
                        _currentStep == 0 ? 'Siguiente' : 'Registrar Cliente y Mascota',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _isLoading ? null : details.onStepCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_currentStep == 0 ? 'Cancelar' : 'Atrás'),
                  ),
                ],
              ),
            );
          },
          steps: [
            // Step 1: Datos del Cliente
            Step(
              title: const Text('Datos del Cliente', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Información básica del dueño'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Icono informativo destacado
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.withValues(alpha: 0.15),
                          Colors.orange.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.directions_walk,
                            color: Colors.orange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Registro sin cuenta (Walk-in)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Este cliente NO tendrá acceso a la app. '
                                'Solo nombre + teléfono + mascota son obligatorios.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Campos obligatorios
                  const Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Campos Obligatorios',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Nombre del cliente
                  TextFormField(
                    controller: _clientNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Nombre del Cliente *',
                      prefixIcon: const Icon(Icons.person_outline),
                      hintText: 'Ej: Juan Pérez',
                      filled: true,
                      fillColor: isDark
                          ? AppTheme.darkCard
                          : Colors.orange.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),

                  // Teléfono
                  TextFormField(
                    controller: _clientPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Teléfono *',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      hintText: 'Ej: +34611222333 o 611222333',
                      filled: true,
                      fillColor: isDark
                          ? AppTheme.darkCard
                          : Colors.orange.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      if (v.replaceAll(RegExp(r'[^\d]'), '').length < 9) {
                        return 'Mínimo 9 dígitos';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Campos opcionales
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Campos Opcionales',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Email (opcional)
                  TextFormField(
                    controller: _clientEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email (opcional)',
                      prefixIcon: const Icon(Icons.email_outlined),
                      hintText: 'Ej: cliente@ejemplo.com',
                      filled: true,
                      fillColor: isDark ? AppTheme.darkCard : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dirección (opcional)
                  TextFormField(
                    controller: _clientAddressController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Dirección (opcional)',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      hintText: 'Ej: Calle Principal 123',
                      filled: true,
                      fillColor: isDark ? AppTheme.darkCard : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Step 2: Datos de la Mascota
            Step(
              title: const Text('Datos de la Mascota', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Información del paciente'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Banner de mascota
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.secondaryColor.withValues(alpha: 0.1),
                          AppTheme.secondaryColor.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pets, color: AppTheme.secondaryColor, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Se generará automáticamente un código QR para la mascota',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Campos obligatorios
                  const Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Campos Obligatorios',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Nombre de la mascota
                  TextFormField(
                    controller: _petNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Nombre de la Mascota *',
                      prefixIcon: const Icon(Icons.pets),
                      hintText: 'Ej: Max, Luna, Rocky',
                      filled: true,
                      fillColor: isDark
                          ? AppTheme.darkCard
                          : AppTheme.secondaryColor.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),

                  // Especie
                  TextFormField(
                    controller: _petSpeciesController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Especie *',
                      prefixIcon: const Icon(Icons.category),
                      hintText: 'Ej: Perro, Gato',
                      filled: true,
                      fillColor: isDark
                          ? AppTheme.darkCard
                          : AppTheme.secondaryColor.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),

                  // Sexo con chips
                  const Text(
                    'Sexo *',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.male, size: 18),
                              SizedBox(width: 8),
                              Text('Macho'),
                            ],
                          ),
                          selected: _petSexo == 'macho',
                          onSelected: (selected) {
                            if (selected) setState(() => _petSexo = 'macho');
                          },
                          selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.female, size: 18),
                              SizedBox(width: 8),
                              Text('Hembra'),
                            ],
                          ),
                          selected: _petSexo == 'hembra',
                          onSelected: (selected) {
                            if (selected) setState(() => _petSexo = 'hembra');
                          },
                          selectedColor: Colors.pink.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Datos opcionales
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Datos Opcionales',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Raza
                  TextFormField(
                    controller: _petBreedController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Raza (opcional)',
                      prefixIcon: const Icon(Icons.info_outline),
                      hintText: 'Ej: Labrador, Criollo',
                      filled: true,
                      fillColor: isDark ? AppTheme.darkCard : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Color
                  TextFormField(
                    controller: _petColorController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Color (opcional)',
                      prefixIcon: const Icon(Icons.palette_outlined),
                      hintText: 'Ej: Marrón, Negro',
                      filled: true,
                      fillColor: isDark ? AppTheme.darkCard : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _petAgeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Edad (años)',
                            prefixIcon: const Icon(Icons.calendar_today),
                            hintText: 'Ej: 2',
                            filled: true,
                            fillColor: isDark ? AppTheme.darkCard : Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _petWeightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Peso (kg)',
                            prefixIcon: const Icon(Icons.monitor_weight),
                            hintText: 'Ej: 15.5',
                            filled: true,
                            fillColor: isDark ? AppTheme.darkCard : Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget helper para mostrar información en el dialog
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }
}
