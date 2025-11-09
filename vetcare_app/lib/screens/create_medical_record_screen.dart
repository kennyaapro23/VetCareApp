import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_app/models/pet_model.dart';
import 'package:vetcare_app/models/servicio.dart';
import 'package:vetcare_app/providers/auth_provider.dart';
import 'package:vetcare_app/services/historial_medico_service.dart';
import 'package:vetcare_app/services/servicio_service.dart';
import 'package:vetcare_app/theme/app_theme.dart';

/// Pantalla para crear historial médico (solo veterinarios)
class CreateMedicalRecordScreen extends StatefulWidget {
  final PetModel pet;
  final int? citaId;

  const CreateMedicalRecordScreen({
    super.key,
    required this.pet,
    this.citaId,
  });

  @override
  State<CreateMedicalRecordScreen> createState() => _CreateMedicalRecordScreenState();
}

class _CreateMedicalRecordScreenState extends State<CreateMedicalRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  final _diagnosticoController = TextEditingController();
  final _tratamientoController = TextEditingController();
  final _observacionesController = TextEditingController();
  
  // Estado
  String _tipoSeleccionado = 'consulta';
  List<Servicio> _serviciosDisponibles = [];
  List<ServicioSeleccionado> _serviciosSeleccionados = [];
  bool _loadingServicios = false;
  bool _saving = false;

  // Tipos de episodio
  final _tipos = const [
    {'value': 'consulta', 'label': 'Consulta General', 'icon': Icons.medical_services},
    {'value': 'vacuna', 'label': 'Vacunación', 'icon': Icons.vaccines},
    {'value': 'cirugia', 'label': 'Cirugía', 'icon': Icons.healing},
    {'value': 'emergencia', 'label': 'Emergencia', 'icon': Icons.emergency},
    {'value': 'control', 'label': 'Control', 'icon': Icons.check_circle},
    {'value': 'otro', 'label': 'Otro', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    _loadServicios();
  }

  @override
  void dispose() {
    _diagnosticoController.dispose();
    _tratamientoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _loadServicios() async {
    setState(() => _loadingServicios = true);
    try {
      final auth = context.read<AuthProvider>();
      final service = ServicioService(auth.api);
      final servicios = await service.getServicios();
      setState(() {
        _serviciosDisponibles = servicios;
        _loadingServicios = false;
      });
    } catch (e) {
      debugPrint('❌ Error cargando servicios: $e');
      setState(() => _loadingServicios = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar servicios: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _guardarHistorial() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar que haya al menos diagnóstico o tratamiento
    if (_diagnosticoController.text.trim().isEmpty &&
        _tratamientoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe ingresar al menos un diagnóstico o tratamiento'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final auth = context.read<AuthProvider>();
      final service = HistorialMedicoService(auth.api);

      // Preparar servicios
      final servicios = _serviciosSeleccionados.map((s) => {
        'servicio_id': s.servicio.id,
        'cantidad': s.cantidad,
        'precio_unitario': s.precioUnitario,
        'notas': s.notas ?? '',
      }).toList();

      await service.crearHistorialConServicios(
        mascotaId: int.parse(widget.pet.id),
        citaId: widget.citaId,
        tipo: _tipoSeleccionado,
        diagnostico: _diagnosticoController.text.trim(),
        tratamiento: _tratamientoController.text.trim(),
        observaciones: _observacionesController.text.trim(),
        servicios: servicios.isNotEmpty ? servicios : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Historial médico creado exitosamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true); // Retornar true para indicar éxito
      }
    } catch (e) {
      debugPrint('❌ Error guardando historial: $e');
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _agregarServicio() {
    if (_serviciosDisponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay servicios disponibles'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _ServicioPickerDialog(
        serviciosDisponibles: _serviciosDisponibles,
        onServicioSeleccionado: (servicio) {
          setState(() {
            _serviciosSeleccionados.add(ServicioSeleccionado(
              servicio: servicio,
              cantidad: 1,
              precioUnitario: servicio.precio,
            ));
          });
        },
      ),
    );
  }

  void _editarServicio(int index) {
    final item = _serviciosSeleccionados[index];
    showDialog(
      context: context,
      builder: (context) => _EditServicioDialog(
        item: item,
        onSave: (cantidad, precio, notas) {
          setState(() {
            _serviciosSeleccionados[index] = ServicioSeleccionado(
              servicio: item.servicio,
              cantidad: cantidad,
              precioUnitario: precio,
              notas: notas,
            );
          });
        },
      ),
    );
  }

  void _eliminarServicio(int index) {
    setState(() => _serviciosSeleccionados.removeAt(index));
  }

  double get _totalServicios {
    return _serviciosSeleccionados.fold(
      0.0,
      (sum, item) => sum + (item.cantidad * item.precioUnitario),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Historial Médico'),
        actions: [
          if (_saving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _guardarHistorial,
              tooltip: 'Guardar',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Información de la mascota
            _buildPetInfoCard(),
            const SizedBox(height: 20),

            // Tipo de episodio
            _buildTipoSelector(),
            const SizedBox(height: 20),

            // Diagnóstico
            _buildTextField(
              controller: _diagnosticoController,
              label: 'Diagnóstico',
              hint: 'Ingrese el diagnóstico del paciente',
              icon: Icons.description,
              maxLines: 3,
              required: false,
            ),
            const SizedBox(height: 16),

            // Tratamiento
            _buildTextField(
              controller: _tratamientoController,
              label: 'Tratamiento',
              hint: 'Indique el tratamiento prescrito',
              icon: Icons.medication,
              maxLines: 3,
              required: false,
            ),
            const SizedBox(height: 16),

            // Observaciones
            _buildTextField(
              controller: _observacionesController,
              label: 'Observaciones',
              hint: 'Observaciones adicionales (opcional)',
              icon: Icons.notes,
              maxLines: 3,
              required: false,
            ),
            const SizedBox(height: 24),

            // Servicios aplicados
            _buildServiciosSection(),
            const SizedBox(height: 24),

            // Botón guardar
            _buildGuardarButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPetInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.pets,
                size: 32,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.pet.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.pet.species} • ${widget.pet.breed}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (widget.pet.age != null)
                    Text(
                      '${widget.pet.age}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Episodio',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tipos.map((tipo) {
            final isSelected = _tipoSeleccionado == tipo['value'];
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tipo['icon'] as IconData,
                    size: 18,
                    color: isSelected ? Colors.white : AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(tipo['label'] as String),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _tipoSeleccionado = tipo['value'] as String);
                }
              },
              selectedColor: AppTheme.primaryColor,
              backgroundColor: Colors.grey[200],
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Este campo es requerido';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildServiciosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Servicios Aplicados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: _loadingServicios ? null : _agregarServicio,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Agregar'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_serviciosSeleccionados.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No hay servicios agregados',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadingServicios ? null : _agregarServicio,
                      child: const Text('Agregar servicio'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _serviciosSeleccionados.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _serviciosSeleccionados[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
                        child: Text(
                          '${item.cantidad}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                      ),
                      title: Text(item.servicio.nombre),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('S/. ${item.precioUnitario.toStringAsFixed(2)} c/u'),
                          if (item.notas != null && item.notas!.isNotEmpty)
                            Text(
                              item.notas!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'S/. ${(item.cantidad * item.precioUnitario).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: AppTheme.errorColor),
                                    SizedBox(width: 8),
                                    Text('Eliminar', style: TextStyle(color: AppTheme.errorColor)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editarServicio(index);
                              } else if (value == 'delete') {
                                _eliminarServicio(index);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'S/. ${_totalServicios.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildGuardarButton() {
    return ElevatedButton(
      onPressed: _saving ? null : _guardarHistorial,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _saving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save),
                SizedBox(width: 8),
                Text(
                  'Guardar Historial Médico',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
    );
  }
}

// Modelo auxiliar para servicios seleccionados
class ServicioSeleccionado {
  final Servicio servicio;
  final int cantidad;
  final double precioUnitario;
  final String? notas;

  ServicioSeleccionado({
    required this.servicio,
    required this.cantidad,
    required this.precioUnitario,
    this.notas,
  });
}

// Diálogo para seleccionar servicio
class _ServicioPickerDialog extends StatefulWidget {
  final List<Servicio> serviciosDisponibles;
  final Function(Servicio) onServicioSeleccionado;

  const _ServicioPickerDialog({
    required this.serviciosDisponibles,
    required this.onServicioSeleccionado,
  });

  @override
  State<_ServicioPickerDialog> createState() => _ServicioPickerDialogState();
}

class _ServicioPickerDialogState extends State<_ServicioPickerDialog> {
  String _searchQuery = '';
  String? _tipoFiltro;

  List<Servicio> get _serviciosFiltrados {
    var servicios = widget.serviciosDisponibles;
    
    if (_tipoFiltro != null) {
      servicios = servicios.where((s) => s.tipo == _tipoFiltro).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      servicios = servicios.where((s) =>
        s.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        s.codigo.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return servicios;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Seleccionar Servicio',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Search bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar servicio...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            
            // Lista de servicios
            Expanded(
              child: _serviciosFiltrados.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No se encontraron servicios',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _serviciosFiltrados.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final servicio = _serviciosFiltrados[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
                            child: Icon(
                              _getIconForTipo(servicio.tipo),
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                          title: Text(servicio.nombre),
                          subtitle: Text('${servicio.codigo} • ${servicio.tipo}'),
                          trailing: Text(
                            servicio.precioFormateado,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onTap: () {
                            widget.onServicioSeleccionado(servicio);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'consulta':
        return Icons.medical_services;
      case 'vacuna':
        return Icons.vaccines;
      case 'cirugia':
        return Icons.healing;
      case 'baño':
        return Icons.shower;
      case 'tratamiento':
        return Icons.medication;
      default:
        return Icons.more_horiz;
    }
  }
}

// Diálogo para editar cantidad y precio
class _EditServicioDialog extends StatefulWidget {
  final ServicioSeleccionado item;
  final Function(int cantidad, double precio, String? notas) onSave;

  const _EditServicioDialog({
    required this.item,
    required this.onSave,
  });

  @override
  State<_EditServicioDialog> createState() => _EditServicioDialogState();
}

class _EditServicioDialogState extends State<_EditServicioDialog> {
  late TextEditingController _cantidadController;
  late TextEditingController _precioController;
  late TextEditingController _notasController;

  @override
  void initState() {
    super.initState();
    _cantidadController = TextEditingController(text: widget.item.cantidad.toString());
    _precioController = TextEditingController(text: widget.item.precioUnitario.toString());
    _notasController = TextEditingController(text: widget.item.notas ?? '');
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _precioController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar: ${widget.item.servicio.nombre}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _cantidadController,
            decoration: const InputDecoration(
              labelText: 'Cantidad',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _precioController,
            decoration: const InputDecoration(
              labelText: 'Precio Unitario',
              border: OutlineInputBorder(),
              prefixText: 'S/. ',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notasController,
            decoration: const InputDecoration(
              labelText: 'Notas (opcional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final cantidad = int.tryParse(_cantidadController.text) ?? 1;
            final precio = double.tryParse(_precioController.text) ?? widget.item.precioUnitario;
            final notas = _notasController.text.trim();
            
            widget.onSave(
              cantidad,
              precio,
              notas.isEmpty ? null : notas,
            );
            Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
