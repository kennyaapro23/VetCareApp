import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_app/providers/auth_provider.dart';
import 'package:vetcare_app/services/historial_medico_service.dart';
import 'package:vetcare_app/services/appointment_service.dart';
import 'package:vetcare_app/models/pet_model.dart';
import 'package:vetcare_app/models/historial_medico.dart';
import 'package:vetcare_app/models/appointment_model.dart';
import 'package:vetcare_app/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'add_pet_screen.dart';

class PetDetailScreen extends StatefulWidget {
  final PetModel pet;

  const PetDetailScreen({super.key, required this.pet});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<HistorialMedico> _historial = [];
  List<AppointmentModel> _citas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();

      // Cargar historial médico
      final historialService = HistorialMedicoService(auth.api);
      final historial = await historialService.getHistorial(
        mascotaId: int.tryParse(widget.pet.id),
      );

      // Cargar citas
      final citasService = AppointmentService(auth.api);
      final todasCitas = await citasService.getAppointments();
      final citasPet = todasCitas.where((c) => c.petId == widget.pet.id).toList();

      if (mounted) {
        setState(() {
          _historial = historial;
          _citas = citasPet;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pet.name),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'qr',
                child: Row(
                  children: [
                    Icon(Icons.qr_code),
                    SizedBox(width: 8),
                    Text('Ver QR'),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'edit') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddPetScreen(pet: widget.pet),
                  ),
                );
                _loadData();
              } else if (value == 'qr') {
                _showQrDialog();
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: isDark ? AppTheme.textSecondary : AppTheme.textLight,
          tabs: const [
            Tab(text: 'Info'),
            Tab(text: 'Historial'),
            Tab(text: 'Citas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(isDark),
          _buildHistorialTab(isDark),
          _buildCitasTab(isDark),
        ],
      ),
    );
  }

  void _showQrDialog() {
    if (widget.pet.qrCode == null || widget.pet.qrCode!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta mascota no tiene código QR'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Código QR de ${widget.pet.name}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: widget.pet.qrCode!,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.pet.qrCode!,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto grande
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pets, size: 60, color: AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 24),

          // Información básica
          _buildSection('Información Básica', [
            _buildInfoRow('Nombre', widget.pet.name),
            _buildInfoRow('Especie', widget.pet.species),
            _buildInfoRow('Raza', widget.pet.breed),
            if (widget.pet.age != null)
              _buildInfoRow('Edad', '${widget.pet.age} años'),
            if (widget.pet.weight != null)
              _buildInfoRow('Peso', '${widget.pet.weight} kg'),
          ], isDark),

          const SizedBox(height: 16),

          // Código QR
          if (widget.pet.qrCode != null)
            _buildSection('Identificación', [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: widget.pet.qrCode!,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _showQrDialog,
                  icon: const Icon(Icons.fullscreen),
                  label: const Text('Ver en pantalla completa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            ], isDark),
        ],
      ),
    );
  }

  Widget _buildHistorialTab(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (_historial.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_information_outlined, size: 80, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text('Sin historial médico', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _historial.length,
      itemBuilder: (context, index) {
        final registro = _historial[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
              Row(
                children: [
                  Icon(_getIconForTipo(registro.tipo), size: 20, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    registro.tipo?.toUpperCase() ?? 'CONSULTA',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('dd/MM/yyyy').format(registro.fecha),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                    ),
                  ),
                ],
              ),
              if (registro.diagnostico != null) ...[
                const SizedBox(height: 8),
                Text(
                  registro.diagnostico!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
              if (registro.tratamiento != null) ...[
                const SizedBox(height: 4),
                Text(
                  registro.tratamiento!,
                  style: TextStyle(
                    color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCitasTab(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (_citas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 80, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text('Sin citas programadas', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _citas.length,
      itemBuilder: (context, index) {
        final cita = _citas[index];
        final status = cita.status ?? 'pendiente';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getColorForEstado(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: _getColorForEstado(status),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cita.date != null
                          ? DateFormat('EEEE, d MMMM yyyy', 'es').format(cita.date!)
                          : 'Fecha pendiente',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getColorForEstado(status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
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
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  IconData _getIconForTipo(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'vacuna':
        return Icons.vaccines;
      case 'cirugia':
        return Icons.healing;
      case 'revision':
        return Icons.fact_check;
      default:
        return Icons.medical_services;
    }
  }

  Color _getColorForEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'confirmada':
        return AppTheme.successColor;
      case 'pendiente':
        return AppTheme.warningColor;
      case 'cancelada':
        return AppTheme.errorColor;
      default:
        return AppTheme.primaryColor;
    }
  }
}
