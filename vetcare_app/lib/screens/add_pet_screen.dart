import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_app/providers/auth_provider.dart';
import 'package:vetcare_app/services/pet_service.dart';
import 'package:vetcare_app/models/pet_model.dart';
import 'package:vetcare_app/theme/app_theme.dart';

class AddPetScreen extends StatefulWidget {
  final PetModel? pet;

  const AddPetScreen({super.key, this.pet});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  String _sexo = 'macho'; // Valor por defecto en minúscula

  bool _isLoading = false;
  bool get _isEditing => widget.pet != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.pet!.name;
      _speciesController.text = widget.pet!.species;
      _breedController.text = widget.pet!.breed;
      _ageController.text = widget.pet!.age?.toString() ?? '';
      _weightController.text = widget.pet!.weight?.toString() ?? '';
      _sexo = widget.pet!.sexo?.toLowerCase() ?? 'macho';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final service = PetService(auth.api);

      final data = {
        'nombre': _nameController.text.trim(),
        'especie': _speciesController.text.trim(),
        'raza': _breedController.text.trim(),
        'sexo': _sexo,
        'edad': _ageController.text.isEmpty ? null : int.parse(_ageController.text),
        'peso': _weightController.text.isEmpty ? null : double.parse(_weightController.text),
      };

      // Solo enviar cliente_id al crear (no al editar)
      if (!_isEditing) {
        data['cliente_id'] = int.parse(auth.user!.id);
      }

      if (_isEditing) {
        await service.updatePet(widget.pet!.id, data);
      } else {
        await service.createPet(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? '✅ Mascota actualizada' : '✅ Mascota agregada'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
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
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(_isEditing ? 'Editar Mascota' : 'Agregar Mascota'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Icono de mascota
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pets, size: 50, color: AppTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 32),

            // Nombre
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                prefixIcon: Icon(Icons.pets),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Ingresa el nombre' : null,
            ),
            const SizedBox(height: 16),

            // Especie
            TextFormField(
              controller: _speciesController,
              decoration: const InputDecoration(
                labelText: 'Especie *',
                hintText: 'Ej: Perro, Gato',
                prefixIcon: Icon(Icons.category),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Ingresa la especie' : null,
            ),
            const SizedBox(height: 16),

            // Raza
            TextFormField(
              controller: _breedController,
              decoration: const InputDecoration(
                labelText: 'Raza *',
                hintText: 'Ej: Labrador, Siamés',
                prefixIcon: Icon(Icons.info_outline),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Ingresa la raza' : null,
            ),
            const SizedBox(height: 16),

            // Edad
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Edad (años)',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              validator: (v) {
                if (v != null && v.isNotEmpty) {
                  final age = int.tryParse(v);
                  if (age == null || age < 0) return 'Edad inválida';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Peso
            TextFormField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Peso (kg)',
                prefixIcon: Icon(Icons.monitor_weight),
              ),
              validator: (v) {
                if (v != null && v.isNotEmpty) {
                  final weight = double.tryParse(v);
                  if (weight == null || weight <= 0) return 'Peso inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Sexo
            DropdownButtonFormField<String>(
              initialValue: _sexo,
              decoration: const InputDecoration(
                labelText: 'Sexo',
                prefixIcon: Icon(Icons.transgender),
              ),
              items: const [
                DropdownMenuItem(value: 'macho', child: Text('Macho')),
                DropdownMenuItem(value: 'hembra', child: Text('Hembra')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _sexo = value;
                  });
                }
              },
            ),
            const SizedBox(height: 32),

            // Botón guardar
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePet,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'ACTUALIZAR' : 'AGREGAR'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
