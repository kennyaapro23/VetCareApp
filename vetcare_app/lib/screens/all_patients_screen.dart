import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_app/providers/auth_provider.dart';
import 'package:vetcare_app/services/pet_service.dart';
import 'package:vetcare_app/models/pet_model.dart';
import 'package:vetcare_app/theme/app_theme.dart';
import 'pet_detail_screen.dart';

class AllPatientsScreen extends StatefulWidget {
  const AllPatientsScreen({super.key});

  @override
  State<AllPatientsScreen> createState() => _AllPatientsScreenState();
}

class _AllPatientsScreenState extends State<AllPatientsScreen> {
  List<PetModel> _pets = [];
  List<PetModel> _filteredPets = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _filterSpecies = 'todas';

  @override
  void initState() {
    super.initState();
    _loadPets();
    _searchController.addListener(_filterPets);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPets() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final service = PetService(auth.api);
      final pets = await service.getPets();
      if (mounted) {
        setState(() {
          _pets = pets;
          _filteredPets = pets;
          _isLoading = false;
        });
        _filterPets();
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

  void _filterPets() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPets = _pets.where((pet) {
        final matchesSearch = pet.name.toLowerCase().contains(query) ||
            pet.species.toLowerCase().contains(query) ||
            pet.breed.toLowerCase().contains(query);

        final matchesSpecies = _filterSpecies == 'todas' ||
            pet.species.toLowerCase().contains(_filterSpecies.toLowerCase());

        return matchesSearch && matchesSpecies;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pacientes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Buscador
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, especie o raza...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterPets();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? AppTheme.darkCard : Colors.white,
                  ),
                ),
              ),
              // Filtros por especie
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildSpeciesFilter('Todas', 'todas', isDark),
                    _buildSpeciesFilter('Perros', 'perro', isDark),
                    _buildSpeciesFilter('Gatos', 'gato', isDark),
                    _buildSpeciesFilter('Otros', 'otros', isDark),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _filteredPets.isEmpty
              ? _buildEmptyState(isDark)
              : RefreshIndicator(
                  onRefresh: _loadPets,
                  color: AppTheme.primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredPets.length,
                    itemBuilder: (context, index) {
                      final pet = _filteredPets[index];
                      return _PatientCard(
                        pet: pet,
                        isDark: isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PetDetailScreen(pet: pet),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildSpeciesFilter(String label, String value, bool isDark) {
    final isSelected = _filterSpecies == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterSpecies = value;
          });
          _filterPets();
        },
        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
        checkmarkColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : null,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets, size: 80, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            _pets.isEmpty ? 'No hay pacientes' : 'No se encontraron pacientes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _pets.isEmpty
                ? 'Aún no hay mascotas registradas'
                : 'Intenta con otro término de búsqueda',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                ),
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final PetModel pet;
  final bool isDark;
  final VoidCallback onTap;

  const _PatientCard({
    required this.pet,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono de mascota
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    pet.species.toLowerCase().contains('perro')
                        ? Icons.pets
                        : Icons.catching_pokemon,
                    size: 30,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${pet.species} • ${pet.breed}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                        ),
                      ),
                      if (pet.age != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${pet.age} años${pet.weight != null ? " • ${pet.weight} kg" : ""}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Flecha
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

