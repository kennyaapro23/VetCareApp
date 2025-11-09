import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_app/services/api_service.dart';
import 'package:vetcare_app/services/servicio_service.dart';
import 'package:vetcare_app/services/historial_medico_service.dart';
import 'package:vetcare_app/models/servicio.dart';
import 'package:vetcare_app/widgets/servicio_selector_widget.dart';

/// Pantalla para que el veterinario registre una consulta y los servicios
/// aplicados. Usa ServicioService para cargar servicios del backend.

class RegistrarConsultaScreen extends StatefulWidget {
  // Opcionales: mascotaId y citaId pueden ser pasados desde la navegación.
  final int? mascotaId;
  final int? citaId;

  const RegistrarConsultaScreen({Key? key, this.mascotaId, this.citaId}) : super(key: key);

  @override
  _RegistrarConsultaScreenState createState() => _RegistrarConsultaScreenState();
}

class _RegistrarConsultaScreenState extends State<RegistrarConsultaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosticoCtrl = TextEditingController();
  final _tratamientoCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();
  DateTime? _fecha;

  bool _loading = false;
  List<Servicio> _serviciosDisponibles = [];
  List<ServicioSeleccionado> _serviciosSeleccionados = [];

  @override
  void initState() {
    super.initState();
    _fecha = DateTime.now();
    _fetchServicios();
  }

  Future<void> _fetchServicios() async {
    setState(() => _loading = true);
    try {
      final apiService = context.read<ApiService>();
      final servicioService = ServicioService(apiService);

      final servicios = await servicioService.getServicios();

      setState(() {
        _serviciosDisponibles = servicios;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar servicios: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_serviciosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione al menos un servicio'))
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final apiService = context.read<ApiService>();
      final historialService = HistorialMedicoService(apiService);

      final serviciosData = _serviciosSeleccionados.map((s) => s.toJson()).toList();

      final historial = await historialService.crearHistorialConServicios(
        mascotaId: widget.mascotaId ?? 0,
        citaId: widget.citaId,
        tipo: 'consulta',
        diagnostico: _diagnosticoCtrl.text.trim(),
        tratamiento: _tratamientoCtrl.text.trim(),
        observaciones: _observacionesCtrl.text.trim(),
        servicios: serviciosData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Consulta registrada • Total servicios: S/. ${historial.totalServicios.toStringAsFixed(2)}')
          )
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear historial: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _diagnosticoCtrl.dispose();
    _tratamientoCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar consulta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _loading ? null : _submit,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Fecha: ${_fecha?.toLocal().toString().split('.').first ?? ''}'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _fecha ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_fecha ?? DateTime.now()));
                              if (time != null) {
                                setState(() {
                                  _fecha = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
                                });
                              }
                            }
                          },
                          child: const Text('Cambiar'),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _diagnosticoCtrl,
                      decoration: const InputDecoration(labelText: 'Diagnóstico'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese diagnóstico' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _tratamientoCtrl,
                      decoration: const InputDecoration(labelText: 'Tratamiento'),
                      minLines: 1,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _observacionesCtrl,
                      decoration: const InputDecoration(labelText: 'Observaciones'),
                      minLines: 1,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    ServicioSelectorWidget(
                      serviciosDisponibles: _serviciosDisponibles.map((s) => {
                        'id': s.id,
                        'nombre': s.nombre,
                        'precio': s.precio,
                        'tipo': s.tipo,
                      }).toList(),
                      onChanged: (seleccionados) {
                        _serviciosSeleccionados = seleccionados;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: const Icon(Icons.send),
                      label: const Text('Registrar consulta'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
